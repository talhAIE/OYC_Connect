-- No positive send calls. Every attempted client write/send is rolled back.
begin;
select set_config('oyc.test_member_id', (select id::text from public.profiles where role='member' order by id limit 1), true);
select set_config('oyc.test_admin_id', (select id::text from public.profiles where role='admin' order by id limit 1), true);

do $$
declare f record;
begin
  if nullif(current_setting('oyc.test_member_id'), '') is null or nullif(current_setting('oyc.test_admin_id'), '') is null then
    raise exception 'Verification requires existing member and admin profiles';
  end if;
  for f in select p.oid, p.oid::regprocedure::text as signature, p.prorettype from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'
    and p.proname in ('send_onesignal_notification_manual','send_onesignal_notification','try_send_prayer_notification','check_prayer_times','handle_new_donation')
  loop
    if has_function_privilege('anon',f.oid,'EXECUTE') or has_function_privilege('authenticated',f.oid,'EXECUTE') then
      raise exception 'SECURITY FAILURE: client EXECUTE remains on %',f.signature;
    end if;
    if f.prorettype <> 'trigger'::regtype and not has_function_privilege('service_role',f.oid,'EXECUTE') then
      raise exception 'Trusted server permission missing on %',f.signature;
    end if;
  end loop;
end;
$$;

set local role anon;
do $$
begin
  begin
    perform public.send_onesignal_notification_manual('Unauthorized security test','Must never be sent');
    raise exception 'SECURITY FAILURE: anonymous push RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    perform public.check_prayer_times();
    raise exception 'SECURITY FAILURE: anonymous scheduler RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.events(title,event_date) values('Unauthorized security test',now());
    raise exception 'SECURITY FAILURE: anonymous event insert succeeded';
  exception when insufficient_privilege then null; end;
end;
$$;
reset role;

select set_config('request.jwt.claim.sub',current_setting('oyc.test_member_id'),true);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('oyc.test_member_id'),'role','authenticated')::text,true);
set local role authenticated;
do $$
begin
  begin
    perform public.send_onesignal_notification_manual('Unauthorized security test','Must never be sent');
    raise exception 'SECURITY FAILURE: member push RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    perform public.try_send_prayer_notification(current_date,'security_test','title','body');
    raise exception 'SECURITY FAILURE: member old helper RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    perform public.try_send_prayer_notification(current_date,'security_test','12:00'::time,'title','body');
    raise exception 'SECURITY FAILURE: member new helper RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    perform public.check_prayer_times();
    raise exception 'SECURITY FAILURE: member scheduler RPC succeeded';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.events(title,event_date) values('Unauthorized security test',now());
    raise exception 'SECURITY FAILURE: member event insert succeeded';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.announcements(title,body) values('Unauthorized security test','Must never be sent');
    raise exception 'SECURITY FAILURE: member announcement insert succeeded';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.prayer_notification_sent(notify_date,slot,prayer_time) values(current_date,'security_test','12:00');
    raise exception 'SECURITY FAILURE: member deduplication insert succeeded';
  exception when insufficient_privilege then null; end;
end;
$$;
reset role;

select set_config('request.jwt.claim.sub',current_setting('oyc.test_admin_id'),true);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('oyc.test_admin_id'),'role','authenticated')::text,true);
set local role authenticated;
do $$
begin
  begin
    perform public.send_onesignal_notification_manual('Unauthorized security test','Must never be sent');
    raise exception 'SECURITY FAILURE: admin client directly invoked push RPC';
  exception when insufficient_privilege then null; end;
end;
$$;
reset role;
rollback;
select 'PASS: anonymous/member/admin-client direct sends denied, both prayer helper overloads denied, unauthorized content-trigger sends denied; all test writes rolled back' as result;
