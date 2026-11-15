-- Read-only aggregate health check. Does not enqueue messages or expose keys,
-- notification content, push tokens, member identities or webhook headers.
select jsonb_build_object(
  'checked_at', now(),
  'venue_timezone', 'Australia/Melbourne',
  'venue_date', (now() at time zone 'Australia/Melbourne')::date,
  'extensions', (select jsonb_agg(extname) from pg_extension where extname in ('pg_cron','pg_net','supabase_vault')),
  'prayer_cron', (select jsonb_agg(jsonb_build_object('schedule',schedule,'active',active)) from cron.job where command like '%check_prayer_times%'),
  'recent_cron_runs', (select jsonb_agg(jsonb_build_object('status',status,'start_time',start_time)) from (select status,start_time from cron.job_run_details where jobid in (select jobid from cron.job where command like '%check_prayer_times%') order by start_time desc limit 5) r),
  'content_triggers', (select jsonb_agg(jsonb_build_object('table',c.relname,'enabled',t.tgenabled,'function',p.proname)) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_proc p on p.oid=t.tgfoid where not t.tgisinternal and c.relnamespace='public'::regnamespace and c.relname in ('events','announcements')),
  'today_prayer_rows', (select count(*) from public.prayer_times where date=(now() at time zone 'Australia/Melbourne')::date),
  'jummah_config_rows', (select count(*) from public.jummah_configurations),
  'opted_in_profiles', (select count(*) from public.profiles where notifications_enabled is true),
  'push_secret_present', (select exists(select 1 from vault.decrypted_secrets where name='oyc_onesignal_api_key' and nullif(decrypted_secret,'') is not null)),
  'sender_uses_preference_aliases', (select position('include_aliases' in prosrc)>0 and position('notifications_enabled' in prosrc)>0 from pg_proc where oid=to_regprocedure('oyc_private.attempt_notification(uuid)')),
  'client_sender_execute_grants', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('send_onesignal_notification_manual','check_prayer_times','try_send_prayer_notification') and (has_function_privilege('anon',p.oid,'execute') or has_function_privilege('authenticated',p.oid,'execute'))),
  'delivery_24h', (select jsonb_agg(jsonb_build_object('type',kind,'status',status,'count',n,'latest',latest)) from (select coalesce(data->>'type','unknown') kind,status,count(*) n,max(created_at) latest from oyc_private.notification_delivery where created_at>now()-interval '24 hours' group by 1,2) d)
) as notification_health;
