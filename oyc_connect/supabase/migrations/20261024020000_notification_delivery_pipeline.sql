begin;

create table if not exists oyc_private.notification_delivery (
  id uuid primary key default gen_random_uuid(),
  event_key text unique not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}',
  status text not null default 'queued' check(status in ('queued','accepted','failed')),
  attempts integer not null default 0,
  http_request_id bigint,
  provider_message_id text,
  last_error text,
  retryable boolean not null default false,
  next_attempt_at timestamptz,
  last_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
alter table oyc_private.notification_delivery enable row level security;
revoke all on oyc_private.notification_delivery from public, anon, authenticated;
grant usage on schema oyc_private to service_role;
grant select, insert, update, delete on oyc_private.notification_delivery to service_role;

create or replace function oyc_private.attempt_notification(delivery_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare d oyc_private.notification_delivery; app_id text; api_key text; request_id bigint;
begin
  perform oyc_private.assert_notification_sender();
  select * into d from oyc_private.notification_delivery where id=delivery_id for update;
  if not found or d.status='accepted' or d.attempts>=3 then return; end if;
  if d.expires_at<=now() then
    update oyc_private.notification_delivery set status='failed',retryable=false,last_error='Notification expired before delivery' where id=d.id;
    return;
  end if;
  select decrypted_secret into app_id from vault.decrypted_secrets where name='oyc_onesignal_app_id';
  select decrypted_secret into api_key from vault.decrypted_secrets where name='oyc_onesignal_api_key';
  if app_id is null or api_key is null then
    update oyc_private.notification_delivery set status='failed',retryable=false,last_error='Server push configuration is missing' where id=d.id;
    return;
  end if;
  begin
    request_id:=net.http_post(
      url:='https://api.onesignal.com/notifications',
      headers:=jsonb_build_object('Content-Type','application/json','Authorization','Key '||api_key),
      body:=jsonb_build_object('app_id',app_id,'target_channel','push',
        'headings',jsonb_build_object('en',d.title),'contents',jsonb_build_object('en',d.body),
        'included_segments',jsonb_build_array('All'),'data',d.data,
        'idempotency_key',d.id,'priority',10,'ios_sound','default',
        'ttl',case when d.data->>'type' in ('prayer','jummah') then 300 else 86400 end));
    update oyc_private.notification_delivery set status='queued',attempts=attempts+1,
      http_request_id=request_id,last_attempt_at=now(),retryable=false,last_error=null where id=d.id;
  exception when others then
    update oyc_private.notification_delivery set status='failed',attempts=attempts+1,
      last_attempt_at=now(),last_error='Could not enqueue provider request',retryable=true,
      next_attempt_at=now()+interval '1 minute' where id=d.id;
  end;
end;
$$;

create or replace function oyc_private.enqueue_notification(p_key text,p_title text,p_body text,p_data jsonb)
returns uuid language plpgsql security definer set search_path='' as $$
declare delivery_id uuid;
begin
  perform oyc_private.assert_notification_sender();
  insert into oyc_private.notification_delivery(event_key,title,body,data,expires_at)
  values(p_key,p_title,p_body,p_data,now()+case when p_data->>'type' in ('prayer','jummah') then interval '5 minutes' else interval '6 hours' end)
  on conflict(event_key) do nothing returning id into delivery_id;
  if delivery_id is not null then perform oyc_private.attempt_notification(delivery_id); end if;
  return delivery_id;
end;
$$;

create or replace function oyc_private.collect_notification_results()
returns void language plpgsql security definer set search_path='' as $$
declare d record; response record; result jsonb; transient boolean;
begin
  perform oyc_private.assert_notification_sender();
  for d in select * from oyc_private.notification_delivery where status='queued' and http_request_id is not null for update skip locked loop
    select * into response from net._http_response where id=d.http_request_id;
    if not found then
      if d.last_attempt_at<now()-interval '2 minutes' then
        update oyc_private.notification_delivery set status='failed',retryable=true,
          last_error='Provider response unavailable',next_attempt_at=now() where id=d.id;
      end if;
      continue;
    end if;
    begin result:=response.content::jsonb; exception when others then result:='{}'; end;
    if response.status_code between 200 and 299 and nullif(result->>'id','') is not null then
      update oyc_private.notification_delivery set status='accepted',provider_message_id=result->>'id',retryable=false,last_error=null where id=d.id;
    else
      transient:=coalesce(response.timed_out,false) or response.status_code is null or response.status_code=429 or response.status_code>=500;
      -- Persist only provider errors/status, never request headers or credentials.
      update oyc_private.notification_delivery set status='failed',retryable=transient,
        last_error=left(coalesce((result->'errors')::text,response.error_msg,'HTTP '||response.status_code::text,'Unknown provider failure'),1000),
        next_attempt_at=now()+interval '1 minute'*greatest(d.attempts,1) where id=d.id;
    end if;
  end loop;
  for d in select id from oyc_private.notification_delivery where status='failed' and retryable
    and attempts<3 and next_attempt_at<=now() and expires_at>now() for update skip locked loop
    perform oyc_private.attempt_notification(d.id);
  end loop;
  update oyc_private.notification_delivery set status='failed',retryable=false,last_error=coalesce(last_error,'Notification expired before confirmed provider acceptance')
    where status<>'accepted' and expires_at<=now();
end;
$$;

create or replace function public.send_onesignal_notification_manual(title text,body text)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform oyc_private.enqueue_notification('manual:'||gen_random_uuid()::text,title,body,jsonb_build_object('type','announcement'));
end;
$$;

create or replace function public.send_onesignal_notification()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  perform oyc_private.assert_notification_sender();
  if tg_table_schema<>'public' or tg_op<>'INSERT' or tg_table_name not in ('events','announcements') then
    raise exception 'Unsupported notification source' using errcode='42501';
  end if;
  if tg_table_name='events' then
    perform oyc_private.enqueue_notification('event:'||new.id::text,'New Event: '||new.title,'Check the app for details.',
      jsonb_build_object('type','event','id',new.id));
  else
    perform oyc_private.enqueue_notification('announcement:'||new.id::text,new.title,
      coalesce(nullif(trim(new.body),''),'New announcement.')||' Tap for more details.',jsonb_build_object('type','announcement','id',new.id));
  end if;
  return new;
end;
$$;

create or replace function public.parse_prayer_time(ts text)
returns time language plpgsql immutable set search_path='' as $$
begin
  if ts is null or trim(ts)='' then return null; end if;
  return trim(ts)::time;
exception when others then return null;
end;
$$;

-- Pure time selection: two-minute bounded catch-up, including cross-midnight
-- reminders, calendar dates and DST in the venue's Melbourne timezone.
create or replace function oyc_private.due_prayer_notifications(at_time timestamptz)
returns table(prayer_date date,slot text,prayer_time time,title text,body text,kind text)
language plpgsql stable set search_path='' as $$
declare rec record; p text; details jsonb; adhan time; iqamah time; scheduled timestamptz;
  local_date date:=(at_time at time zone 'Australia/Melbourne')::date; cfg jsonb; day date; alert record;
begin
  for rec in select * from public.prayer_times where date between local_date-1 and local_date+1 loop
    details:=to_jsonb(rec);
    foreach p in array array['fajr','dhuhr','asr','maghrib','isha'] loop
      adhan:=public.parse_prayer_time(details->>p);
      iqamah:=public.parse_prayer_time(details->>(p||'_iqama'));
      for alert in select * from (values
        (p||'_30',adhan,interval '-30 minutes','Adhan in 30 minutes.'),
        (p||'_on',adhan,interval '0 minutes','It is time for Adhan.'),
        (p||'_iqamah',iqamah,interval '0 minutes','It is time for Iqamah.')) a(alert_slot,t,offset_by,message)
      loop
        if alert.t is null then continue; end if;
        scheduled:=((rec.date+alert.t)+alert.offset_by) at time zone 'Australia/Melbourne';
        if scheduled<=at_time and scheduled>at_time-interval '2 minutes' then
          prayer_date:=rec.date; slot:=alert.alert_slot; prayer_time:=alert.t;
          title:=initcap(p); body:=alert.message; kind:='prayer'; return next;
        end if;
      end loop;
    end loop;
  end loop;
  select to_jsonb(j) into cfg from public.jummah_configurations j order by id limit 1;
  if cfg is null then return; end if;
  foreach day in array array[local_date-1,local_date,local_date+1] loop
    if extract(isodow from day)<>5 then continue; end if;
    for alert in select * from (values
      ('jummah_30',public.parse_prayer_time(cfg->>'khutbah_time'),interval '-30 minutes','Khutbah in 30 minutes.'),
      ('jummah_on',public.parse_prayer_time(cfg->>'khutbah_time'),interval '0 minutes','Khutbah has started.'),
      ('jummah_iqamah',public.parse_prayer_time(cfg->>'jummah_time'),interval '0 minutes','It is time for Jummah Iqamah.')) a(alert_slot,t,offset_by,message)
    loop
      if alert.t is null then continue; end if;
      scheduled:=((day+alert.t)+alert.offset_by) at time zone 'Australia/Melbourne';
      if scheduled<=at_time and scheduled>at_time-interval '2 minutes' then
        prayer_date:=day; slot:=alert.alert_slot; prayer_time:=alert.t;
        title:='Jummah'; body:=alert.message; kind:='jummah'; return next;
      end if;
    end loop;
  end loop;
end;
$$;

create unique index if not exists prayer_notification_delivery_slot on public.prayer_notification_sent(notify_date,slot,prayer_time);
create or replace function public.try_send_prayer_notification(p_date date,p_slot text,p_prayer_time time,p_title text,p_body text)
returns boolean language plpgsql security definer set search_path='' as $$
declare claimed boolean;
begin
  perform oyc_private.assert_notification_sender();
  insert into public.prayer_notification_sent(notify_date,slot,prayer_time) values(p_date,p_slot,p_prayer_time)
    on conflict(notify_date,slot,prayer_time) do nothing;
  claimed:=found;
  if not claimed then return false; end if;
  perform oyc_private.enqueue_notification('prayer:'||p_date::text||':'||p_slot||':'||p_prayer_time::text,p_title,p_body,
    jsonb_build_object('type',case when p_slot like 'jummah_%' then 'jummah' else 'prayer' end,'slot',p_slot,'date',p_date));
  return true;
end;
$$;

create or replace function public.check_prayer_times()
returns void language plpgsql security definer set search_path='' as $$
declare alert record;
begin
  perform oyc_private.assert_notification_sender();
  if not pg_try_advisory_xact_lock(hashtext('oyc-notification-dispatch')) then return; end if;
  perform oyc_private.collect_notification_results();
  for alert in select * from oyc_private.due_prayer_notifications(now()) loop
    perform public.try_send_prayer_notification(alert.prayer_date,alert.slot,alert.prayer_time,alert.title,alert.body);
  end loop;
end;
$$;

-- Compatibility for old trusted callers; this overload has no actual time,
-- so use a stable per-day sentinel instead of violating the time NOT NULL key.
create or replace function public.try_send_prayer_notification(p_date date,p_slot text,p_title text,p_body text)
returns boolean language plpgsql security definer set search_path='' as $$
begin
  perform oyc_private.assert_notification_sender();
  return public.try_send_prayer_notification(p_date,p_slot,'00:00'::time,p_title,p_body);
end;
$$;

create or replace function public.notification_delivery_status(max_rows integer default 30)
returns table(created_at timestamptz,title text,status text,attempts integer,provider_message_id text,last_error text)
language plpgsql security definer set search_path='' as $$
begin
  if not oyc_private.current_user_is_admin() then
    raise exception 'Only administrators may inspect delivery status' using errcode='42501';
  end if;
  return query select d.created_at,d.title,d.status,d.attempts,d.provider_message_id,d.last_error
    from oyc_private.notification_delivery d order by d.created_at desc limit greatest(1,least(coalesce(max_rows,30),100));
end;
$$;
revoke all on function public.notification_delivery_status(integer) from public,anon,authenticated;
grant execute on function public.notification_delivery_status(integer) to authenticated;

-- New internal functions are never client RPCs. Preserve existing public ACLs.
revoke all on function oyc_private.attempt_notification(uuid),oyc_private.enqueue_notification(text,text,text,jsonb),
  oyc_private.collect_notification_results(),oyc_private.due_prayer_notifications(timestamptz) from public,anon,authenticated;
grant execute on function oyc_private.collect_notification_results() to service_role;
revoke all on function public.send_onesignal_notification_manual(text,text),public.send_onesignal_notification(),
  public.check_prayer_times(),public.try_send_prayer_notification(date,text,time,text,text),
  public.try_send_prayer_notification(date,text,text,text) from public,anon,authenticated;
grant execute on function public.send_onesignal_notification_manual(text,text),public.check_prayer_times(),
  public.try_send_prayer_notification(date,text,time,text,text),public.try_send_prayer_notification(date,text,text,text) to service_role;

commit;
