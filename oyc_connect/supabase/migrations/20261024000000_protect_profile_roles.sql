-- Profile roles are server-owned. Apply as the database owner, not a client.
begin;

alter table public.profiles enable row level security;
alter table public.profiles add column if not exists notifications_enabled boolean not null default true;
alter table public.profiles add column if not exists phone text;
alter table public.profiles alter column role set default 'member';
alter table public.profiles alter column role set not null;

-- Fail rather than silently rewriting existing unexpected roles.
alter table public.profiles drop constraint if exists profiles_role_allowed;
alter table public.profiles add constraint profiles_role_allowed
  check (role in ('member', 'admin'));

-- Replace legacy policies, including FOR ALL policies that may authorize
-- admins to edit roles. Reads remain available to the owner and admins.
do $$
declare
  policy_name text;
  column_names text;
begin
  for policy_name in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
  loop
    execute format('drop policy %I on public.profiles', policy_name);
  end loop;

  -- Table and column privileges are additive: remove BOTH kinds of grants.
  select string_agg(quote_ident(attname), ', ' order by attnum)
    into column_names
  from pg_attribute
  where attrelid = 'public.profiles'::regclass and attnum > 0 and not attisdropped;

  execute format('revoke insert (%s), update (%s), references (%s) on public.profiles from public, anon, authenticated',
    column_names, column_names, column_names);
end;
$$;

revoke all
  on table public.profiles from public, anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (full_name, notifications_enabled)
  on table public.profiles to authenticated;
grant select, insert, update, delete on table public.profiles to service_role;

-- Read the caller's server-owned role without recursive profiles RLS.
-- This private helper accepts no user-controlled ID or role.
create schema if not exists oyc_private;
revoke all on schema oyc_private from public, anon, authenticated;
grant usage on schema oyc_private to authenticated;
create or replace function oyc_private.current_user_is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles where id = (select auth.uid()) and role = 'admin'
  );
$$;
revoke all on function oyc_private.current_user_is_admin() from public, anon, authenticated;
grant execute on function oyc_private.current_user_is_admin() to authenticated;

create policy profiles_read_self_or_admin on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id or (select oyc_private.current_user_is_admin()));

create policy profiles_update_self on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- A restrictive policy keeps ownership mandatory even if a later migration
-- accidentally adds another permissive UPDATE/ALL policy.
create policy profiles_update_owner_guard on public.profiles
  as restrictive for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (tg_op = 'INSERT' and new.role is distinct from 'member')
     or (tg_op = 'UPDATE' and new.role is distinct from old.role) then
    -- current_user is the real database execution role, not editable user
    -- metadata. Check SET ROLE too, so a definer RPC called by a client cannot
    -- accidentally turn that client into a trusted role-changing caller.
    if current_user not in ('service_role', 'postgres', 'supabase_admin')
       or coalesce(current_setting('role', true), 'none') in ('anon', 'authenticated') then
      raise exception 'Profile roles may only be changed by trusted server code'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.protect_profile_role() from public, anon, authenticated;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
  before insert or update on public.profiles
  for each row execute function public.protect_profile_role();

-- Signup metadata must never determine the authorization role.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, role, phone)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', 'member',
    new.raw_user_meta_data->>'phone');
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- No SECURITY DEFINER escalation is needed: the server's service_role already
-- has the required privileges. Never expose its key to the Flutter application.
create or replace function public.set_profile_role(target_user_id uuid, new_role text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin')
     or coalesce(current_setting('role', true), 'none') in ('anon', 'authenticated') then
    raise exception 'Only trusted server code may assign roles' using errcode = '42501';
  end if;
  if new_role is null or new_role not in ('member', 'admin') then
    raise exception 'Invalid profile role' using errcode = '22023';
  end if;
  update public.profiles set role = new_role where id = target_user_id;
  if not found then
    raise exception 'Profile does not exist' using errcode = 'P0002';
  end if;
end;
$$;
revoke all on function public.set_profile_role(uuid, text) from public, anon, authenticated;
grant execute on function public.set_profile_role(uuid, text) to service_role;

commit;
