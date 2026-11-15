begin;

-- Resolve recipients at each attempt so retries honor newly saved opt-outs.
create or replace function oyc_private.attempt_notification(delivery_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare d oyc_private.notification_delivery; app_id text; api_key text; request_id bigint; recipients jsonb;
begin
  perform oyc_private.assert_notification_sender();
  select * into d from oyc_private.notification_delivery where id=delivery_id for update;
  if not found or d.status='accepted' or d.attempts>=3 then return; end if;
  if d.expires_at<=now() then
    update oyc_private.notification_delivery set status='failed',retryable=false,last_error='Notification expired before delivery' where id=d.id;
    return;
  end if;
  select coalesce(jsonb_agg(id::text order by id),'[]'::jsonb) into recipients
    from public.profiles where notifications_enabled is true;
  if jsonb_array_length(recipients)=0 then
    update oyc_private.notification_delivery set status='failed',retryable=false,last_error='No opted-in profiles to notify' where id=d.id;
    return;
  end if;
  -- OneSignal accepts up to 20,000 aliases per request. Never fall back to All.
  if jsonb_array_length(recipients)>20000 then
    update oyc_private.notification_delivery set status='failed',retryable=false,last_error='Recipient limit exceeded; split delivery into batches' where id=d.id;
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
        'include_aliases',jsonb_build_object('external_id',recipients),'data',d.data,
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
revoke all on function oyc_private.attempt_notification(uuid) from public, anon, authenticated;
grant execute on function oyc_private.attempt_notification(uuid) to service_role;

commit;
