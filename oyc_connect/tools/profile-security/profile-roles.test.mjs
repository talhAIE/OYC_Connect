import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

const member = '00000000-0000-0000-0000-000000000001';
const admin = '00000000-0000-0000-0000-000000000002';
const outsider = '00000000-0000-0000-0000-000000000003';
const migration = await readFile(new URL('../../supabase/migrations/20261024000000_protect_profile_roles.sql', import.meta.url), 'utf8');
let db;

const fixture = `
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  grant usage on schema public, auth to anon, authenticated, service_role;
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb default '{}');
  create table public.profiles (
    id uuid primary key references auth.users,
    email text, full_name text, role text default 'member',
    created_at timestamptz not null default now()
  );
  alter table public.profiles enable row level security;
  grant all on public.profiles to authenticated, anon, service_role;
  grant update(role, email), insert(role) on public.profiles to public, authenticated, anon;
  create policy legacy_read on public.profiles for select using (true);
  create policy legacy_update on public.profiles for update using (auth.uid() = id);
  create policy legacy_insert on public.profiles for insert with check (auth.uid() = id);
  -- Include an alternate broad policy, not just the name in the setup guide.
  create policy legacy_admin_all on public.profiles for all using (true) with check (true);
  create function public.handle_new_user() returns trigger language plpgsql security definer as $$
  begin
    insert into public.profiles(id, email, full_name, role)
    values(new.id, new.email, new.raw_user_meta_data->>'full_name', 'member');
    return new;
  end; $$;
  create trigger on_auth_user_created after insert on auth.users
    for each row execute function public.handle_new_user();
  insert into auth.users(id, email, raw_user_meta_data) values
    ('${member}', 'member@example.test', '{"full_name":"Member"}'),
    ('${admin}', 'admin@example.test', '{"full_name":"Administrator"}');
  update public.profiles set role = 'admin' where id = '${admin}';
`;

async function asRole(role, userId, callback) {
  await db.exec(`begin; set local role ${role};`);
  await db.query("select set_config('request.jwt.claim.sub', $1, true)", [userId ?? '']);
  try {
    return await callback();
  } finally {
    await db.exec('rollback');
  }
}

async function denied(sql, code = '42501') {
  await db.exec('savepoint denied_request');
  try {
    await assert.rejects(db.exec(sql), error => error.code === code);
  } finally {
    await db.exec('rollback to savepoint denied_request');
  }
}

before(async () => {
  db = await PGlite.create();
  await db.exec(fixture);
  // Reproduce the original vulnerability before hardening, and roll it back.
  await asRole('authenticated', member, async () => {
    await db.exec(`update public.profiles set role = 'admin' where id = '${member}'`);
    const { rows } = await db.query(`select role from public.profiles where id = '${member}'`);
    assert.equal(rows[0].role, 'admin');
  });
  await db.exec(migration);
  await db.exec(migration); // Redeployment must preserve protections and users.
});

after(async () => { await db?.close(); });

test('normal member cannot self-promote by direct UPDATE or mixed name/role payload', async () => {
  await asRole('authenticated', member, async () => {
    await denied(`update public.profiles set role = 'admin' where id = '${member}'`);
    await denied(`update public.profiles set full_name = 'New Name', role = 'admin' where id = '${member}'`);
    const { rows } = await db.query(`select role, full_name from public.profiles where id = '${member}'`);
    assert.deepEqual(rows[0], { role: 'member', full_name: 'Member' });
  });
});

test('member can update only their own name and notification preference', async () => {
  await asRole('authenticated', member, async () => {
    await db.exec(`update public.profiles set full_name = 'Permitted Name', notifications_enabled = false where id = '${member}'`);
    const { rows } = await db.query(`select full_name, notifications_enabled, role from public.profiles where id = '${member}'`);
    assert.deepEqual(rows[0], { full_name: 'Permitted Name', notifications_enabled: false, role: 'member' });
    const other = await db.query(`update public.profiles set full_name = 'Attacked' where id = '${admin}' returning id`);
    assert.equal(other.rows.length, 0);
    await denied(`update public.profiles set email = 'attacker@example.test' where id = '${member}'`);
    await denied(`update public.profiles set id = '${outsider}' where id = '${member}'`);
    await denied(`update public.profiles set created_at = now() where id = '${member}'`);
  });
});

test('INSERT, UPSERT, DELETE and TRUNCATE cannot replace a profile with an admin row', async () => {
  await asRole('authenticated', member, async () => {
    await denied(`insert into public.profiles(id, role) values ('${member}', 'admin')`);
    await denied(`insert into public.profiles(id, role) values ('${member}', 'admin') on conflict(id) do update set role = excluded.role`);
    await denied(`delete from public.profiles where id = '${member}'`);
    await denied('truncate public.profiles cascade');
  });
});

test('a logged-in admin also cannot change roles or edit another profile', async () => {
  await asRole('authenticated', admin, async () => {
    await denied(`update public.profiles set role = 'admin' where id = '${member}'`);
    await denied(`update public.profiles set role = 'member' where id = '${admin}'`);
    const other = await db.query(`update public.profiles set full_name = 'Attacked' where id = '${member}' returning id`);
    assert.equal(other.rows.length, 0);
    await denied(`select public.set_profile_role('${member}', 'admin')`);
  });
});

test('anonymous and ordinary authenticated callers cannot execute role management', async () => {
  for (const role of ['anon', 'authenticated']) {
    await asRole(role, member, async () => {
      await denied(`select public.set_profile_role('${member}', 'admin')`);
      await denied(`update public.profiles set role = 'admin' where id = '${member}'`);
    });
  }
});

test('trusted service_role can promote and demote; invalid roles and missing users fail', async () => {
  await asRole('service_role', null, async () => {
    await db.exec(`select public.set_profile_role('${member}', 'admin')`);
    assert.equal((await db.query(`select role from public.profiles where id = '${member}'`)).rows[0].role, 'admin');
    await db.exec(`select public.set_profile_role('${member}', 'member')`);
    assert.equal((await db.query(`select role from public.profiles where id = '${member}'`)).rows[0].role, 'member');
    await denied(`select public.set_profile_role('${member}', 'superadmin')`, '22023');
    await denied(`select public.set_profile_role('${member}', null)`, '22023');
    await denied(`select public.set_profile_role('${outsider}', 'admin')`, 'P0002');
  });
});

test('signup ignores malicious user metadata and creates a member', async () => {
  await db.exec('begin');
  try {
    await db.exec(`insert into auth.users(id, email, raw_user_meta_data) values
      ('${outsider}', 'signup@example.test', '{"role":"admin","full_name":"New Member","phone":"test-phone"}')`);
    const { rows } = await db.query(`select role, full_name, phone from public.profiles where id = '${outsider}'`);
    assert.deepEqual(rows[0], { role: 'member', full_name: 'New Member', phone: 'test-phone' });
  } finally { await db.exec('rollback'); }
});

test('legacy table and column write grants are removed, including PUBLIC inheritance', async () => {
  for (const role of ['anon', 'authenticated']) {
    const { rows } = await db.query(`select
      has_column_privilege($1, 'public.profiles', 'role', 'UPDATE') as role_update,
      has_column_privilege($1, 'public.profiles', 'email', 'UPDATE') as email_update,
      has_column_privilege($1, 'public.profiles', 'role', 'INSERT') as role_insert,
      has_function_privilege($1, 'public.set_profile_role(uuid,text)', 'EXECUTE') as role_rpc`, [role]);
    assert.deepEqual(rows[0], { role_update: false, email_update: false, role_insert: false, role_rpc: false });
  }
  assert.equal((await db.query(`select role from public.profiles where id = '${admin}'`)).rows[0].role, 'admin');
});

test('trigger still blocks promotion if a future migration accidentally restores UPDATE(role)', async () => {
  await db.exec('grant update(role) on public.profiles to authenticated');
  try {
    await asRole('authenticated', member, async () => {
      await denied(`update public.profiles set role = 'admin' where id = '${member}'`);
    });
  } finally { await db.exec('revoke update(role) on public.profiles from authenticated'); }
});

test('a client-callable definer RPC cannot bypass the role trigger', async () => {
  await db.exec(`create function public.test_unsafe_role_rpc(target uuid) returns void
    language sql security definer set search_path = '' as
    $$ update public.profiles set role = 'admin' where id = target $$;
    grant execute on function public.test_unsafe_role_rpc(uuid) to authenticated;`);
  try {
    await asRole('authenticated', member, async () => {
      await denied(`select public.test_unsafe_role_rpc('${member}')`);
    });
  } finally { await db.exec('drop function public.test_unsafe_role_rpc(uuid)'); }
});

test('future permissive policies cannot override the restrictive owner guard', async () => {
  await db.exec('create policy test_future_broad_update on public.profiles for update to authenticated using(true) with check(true)');
  try {
    await asRole('authenticated', member, async () => {
      const { rows } = await db.query(`update public.profiles set full_name = 'Attacked' where id = '${admin}' returning id`);
      assert.equal(rows.length, 0);
    });
  } finally { await db.exec('drop policy test_future_broad_update on public.profiles'); }
});

test('members read only their own profile; admins retain donor profile reads; anonymous reads fail', async () => {
  await asRole('authenticated', member, async () => {
    const { rows } = await db.query('select id from public.profiles');
    assert.deepEqual(rows, [{ id: member }]);
  });
  await asRole('authenticated', admin, async () => {
    assert.equal((await db.query('select id from public.profiles')).rows.length, 2);
  });
  await asRole('anon', null, async () => {
    await denied('select * from public.profiles');
  });
});

test('JWT-style role metadata does not turn an authenticated database caller into service_role', async () => {
  await asRole('authenticated', member, async () => {
    await db.query("select set_config('request.jwt.claim.role', 'service_role', true)");
    await denied(`select public.set_profile_role('${member}', 'admin')`);
  });
});

test('the deployable verification script passes and rolls back all profile changes', async () => {
  const sql = await readFile(new URL('../../supabase/tests/profile_role_protection.sql', import.meta.url), 'utf8');
  const result = await db.exec(sql);
  assert.match(result.at(-1).rows[0].result, /^PASS:/);
  assert.equal((await db.query(`select role from public.profiles where id = '${member}'`)).rows[0].role, 'member');
  assert.equal((await db.query(`select role from public.profiles where id = '${admin}'`)).rows[0].role, 'admin');
});
