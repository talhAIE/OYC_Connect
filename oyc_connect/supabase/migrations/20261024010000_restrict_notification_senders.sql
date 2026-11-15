-- Keep scheduled/admin-originated notifications; deny direct client sending.
begin;

-- Internal helpers use public objects, so clients must not create/shadow them.
revoke create on schema public from public, anon, authenticated;

-- Move the existing provider configuration into Vault entirely within Postgres.
-- Never return the credential or send it through client code/migration output.
do $$
declare
  old_source text;
  secret_value text;
begin
  select prosrc into old_source from pg_proc
    where oid = to_regprocedure('public.send_onesignal_notification_manual(text,text)');
  if not exists (select 1 from vault.secrets where name = 'oyc_onesignal_api_key') then
    secret_value := (regexp_match(old_source, 'os_api_key\s+text\s*:=\s*''([^'']+)''', 'i'))[1];
    if secret_value is null or secret_value = '' then
      raise exception 'Configure oyc_onesignal_api_key in Vault before applying this migration';
    end if;
    perform vault.create_secret(secret_value, 'oyc_onesignal_api_key', 'Server-only push provider credential');
  end if;
  if not exists (select 1 from vault.secrets where name = 'oyc_onesignal_app_id') then
    secret_value := (regexp_match(old_source, 'os_app_id\s+text\s*:=\s*''([^'']+)''', 'i'))[1];
    if secret_value is null or secret_value = '' then
      raise exception 'Configure oyc_onesignal_app_id in Vault before applying this migration';
    end if;
    perform vault.create_secret(secret_value, 'oyc_onesignal_app_id', 'Push provider application ID');
  end if;
end;
$$;

create or replace function oyc_private.assert_notification_sender()
returns void language plpgsql security invoker set search_path = '' as $$
declare request_role text := coalesce(current_setting('role', true), 'none');
begin
  if request_role in ('anon', 'authenticated') then
    -- A verified admin content write may invoke a database-owned trigger.
    -- A logged-in admin still cannot invoke the sending RPC directly.
    if request_role = 'authenticated' and pg_trigger_depth() > 0
       and oyc_private.current_user_is_admin() then
      return;
    end if;
    raise exception 'Notifications require a trusted server caller' using errcode = '42501';
  end if;
  if current_user not in ('postgres', 'supabase_admin', 'service_role') then
    raise exception 'Notifications require a trusted server caller' using errcode = '42501';
  end if;
end;
$$;
revoke all on function oyc_private.assert_notification_sender() from public, anon, authenticated;

create or replace function public.send_onesignal_notification_manual(title text, body text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  os_app_id text;
  os_api_key text;
begin
  perform oyc_private.assert_notification_sender();
  select decrypted_secret into os_app_id from vault.decrypted_secrets where name = 'oyc_onesignal_app_id';
  select decrypted_secret into os_api_key from vault.decrypted_secrets where name = 'oyc_onesignal_api_key';
  if os_app_id is null or os_api_key is null then
    raise exception 'Server push configuration is missing';
  end if;
  perform net.http_post(
    url := 'https://onesignal.com/api/v1/notifications',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Basic ' || os_api_key),
    body := jsonb_build_object('app_id', os_app_id,
      'headings', jsonb_build_object('en', title),
      'contents', jsonb_build_object('en', body),
      'included_segments', jsonb_build_array('All'))
  );
end;
$$;

create or replace function public.send_onesignal_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare notification_title text; notification_body text;
begin
  perform oyc_private.assert_notification_sender();
  if tg_table_schema <> 'public' or tg_table_name not in ('events', 'announcements') or tg_op <> 'INSERT' then
    raise exception 'Unsupported notification trigger source' using errcode = '42501';
  end if;
  if tg_table_name = 'events' then
    notification_title := 'New Event: ' || new.title;
    notification_body := 'Check the app for details.';
  else
    notification_title := new.title;
    notification_body := coalesce(nullif(trim(new.body), ''), 'New announcement.') || ' Tap for more details.';
  end if;
  perform public.send_onesignal_notification_manual(notification_title, notification_body);
  return new;
end;
$$;

-- Restrict EVERY overload, including the older four-argument prayer helper.
-- Trigger functions need no direct API execution privilege even for service_role.
do $$
declare f record;
begin
  for f in select p.oid::regprocedure as signature, p.prorettype
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in (
      'send_onesignal_notification_manual', 'send_onesignal_notification',
      'try_send_prayer_notification', 'check_prayer_times', 'handle_new_donation')
  loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f.signature);
    if f.prorettype <> 'trigger'::regtype then
      execute format('grant execute on function %s to service_role', f.signature);
    end if;
    -- Legacy bodies contain unqualified table references. Public is not client
    -- writable, and pg_temp is explicitly last to prevent temporary shadowing.
    execute format('alter function %s set search_path = pg_catalog, public, pg_temp', f.signature);
  end loop;
end;
$$;

-- Prevent indirect sending by inserting announcements/events or tampering with
-- the schedule consumed by cron. Admins can still publish through the app.
do $$
declare tbl text; pol record; columns_sql text;
begin
  foreach tbl in array array['events','announcements','prayer_times','jummah_configurations'] loop
    if to_regclass('public.' || tbl) is null then continue; end if;
    execute format('alter table public.%I enable row level security', tbl);
    for pol in select policyname from pg_policies where schemaname = 'public' and tablename = tbl loop
      execute format('drop policy %I on public.%I', pol.policyname, tbl);
    end loop;
    select string_agg(quote_ident(attname), ', ') into columns_sql from pg_attribute
      where attrelid = to_regclass('public.' || tbl) and attnum > 0 and not attisdropped;
    execute format('revoke insert (%s), update (%s), references (%s) on public.%I from public, anon, authenticated', columns_sql, columns_sql, columns_sql, tbl);
    execute format('revoke all on public.%I from public, anon, authenticated', tbl);
    execute format('grant select on public.%I to anon, authenticated', tbl);
    execute format('grant insert, update, delete on public.%I to authenticated', tbl);
    execute format('grant select, insert, update, delete on public.%I to service_role', tbl);
    execute format('create policy notification_content_read on public.%I for select using (true)', tbl);
    execute format('create policy notification_content_admin on public.%I for all to authenticated using ((select oyc_private.current_user_is_admin())) with check ((select oyc_private.current_user_is_admin()))', tbl);
    -- Keep the admin requirement even if a permissive policy is later added.
    execute format('create policy notification_insert_guard on public.%I as restrictive for insert to authenticated with check ((select oyc_private.current_user_is_admin()))', tbl);
    execute format('create policy notification_update_guard on public.%I as restrictive for update to authenticated using ((select oyc_private.current_user_is_admin())) with check ((select oyc_private.current_user_is_admin()))', tbl);
    execute format('create policy notification_delete_guard on public.%I as restrictive for delete to authenticated using ((select oyc_private.current_user_is_admin()))', tbl);
  end loop;
  if to_regclass('public.prayer_notification_sent') is not null then
    alter table public.prayer_notification_sent enable row level security;
    revoke all on public.prayer_notification_sent from public, anon, authenticated;
    grant select, insert, update, delete on public.prayer_notification_sent to service_role;
  end if;
end;
$$;

commit;
