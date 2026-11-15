-- Run as the database owner after the role-protection migration.
-- Uses existing users only inside a transaction; ALL writes are rolled back.
begin;
select set_config('oyc.test_member_id', (select id::text from public.profiles where role = 'member' order by id limit 1), true);
select set_config('oyc.test_admin_id', (select id::text from public.profiles where role = 'admin' order by id limit 1), true);
do $$
begin
  if nullif(current_setting('oyc.test_member_id'), '') is null
     or nullif(current_setting('oyc.test_admin_id'), '') is null then
    raise exception 'Verification requires an existing member and admin';
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', current_setting('oyc.test_member_id'), true);
select set_config('request.jwt.claims', jsonb_build_object('sub', current_setting('oyc.test_member_id'), 'role', 'authenticated')::text, true);
set local role authenticated;
do $$
declare affected bigint;
begin
  if current_user <> 'authenticated' then raise exception 'Test is not impersonating a client'; end if;
  begin
    update public.profiles set role = 'admin' where id = auth.uid();
    raise exception 'SECURITY FAILURE: member self-promotion succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set full_name = 'Security test', role = 'admin' where id = auth.uid();
    raise exception 'SECURITY FAILURE: mixed role/name update succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.set_profile_role(auth.uid(), 'admin');
    raise exception 'SECURITY FAILURE: client role RPC succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.profiles(id, role) values(auth.uid(), 'admin')
      on conflict(id) do update set role = excluded.role;
    raise exception 'SECURITY FAILURE: client role UPSERT succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set email = 'security-test@example.invalid' where id = auth.uid();
    raise exception 'SECURITY FAILURE: client email update succeeded';
  exception when insufficient_privilege then null;
  end;

  update public.profiles set full_name = full_name, notifications_enabled = notifications_enabled where id = auth.uid();
  get diagnostics affected = row_count;
  if affected <> 1 then raise exception 'Permitted own-profile update failed'; end if;
  update public.profiles set full_name = 'Security test' where id = current_setting('oyc.test_admin_id')::uuid;
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'SECURITY FAILURE: cross-user update succeeded'; end if;
  if (select count(*) from public.profiles) <> 1 then raise exception 'SECURITY FAILURE: member can read other profiles'; end if;
end;
$$;

reset role;
select set_config('request.jwt.claim.sub', current_setting('oyc.test_admin_id'), true);
select set_config('request.jwt.claims', jsonb_build_object('sub', current_setting('oyc.test_admin_id'), 'role', 'authenticated')::text, true);
set local role authenticated;
do $$
begin
  begin
    update public.profiles set role = 'member' where id = auth.uid();
    raise exception 'SECURITY FAILURE: client admin changed role';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.set_profile_role(current_setting('oyc.test_member_id')::uuid, 'admin');
    raise exception 'SECURITY FAILURE: admin client role RPC succeeded';
  exception when insufficient_privilege then null;
  end;
  if (select count(*) from public.profiles) < 2 then raise exception 'Admin donor-profile reads failed'; end if;
end;
$$;

reset role;
set local role anon;
do $$
begin
  begin
    perform public.set_profile_role(current_setting('oyc.test_member_id')::uuid, 'admin');
    raise exception 'SECURITY FAILURE: anonymous role RPC succeeded';
  exception when insufficient_privilege then null;
  end;
end;
$$;

reset role;
set local role service_role;
do $$
declare member_id uuid := current_setting('oyc.test_member_id')::uuid;
begin
  perform public.set_profile_role(member_id, 'admin');
  if (select role from public.profiles where id = member_id) <> 'admin' then
    raise exception 'Trusted server promotion failed';
  end if;
  perform public.set_profile_role(member_id, 'member');
end;
$$;

reset role;
rollback;
select 'PASS: member/admin/anonymous role changes denied; permitted self updates and trusted server role management succeeded; all test writes rolled back' as result;
