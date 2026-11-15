import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { serverOnly } from '../../supabase/functions/_shared/server-auth.ts';

const member = '00000000-0000-0000-0000-000000000001';
const admin = '00000000-0000-0000-0000-000000000002';
const load = path => readFile(new URL(path, import.meta.url), 'utf8');
const migration = await load('../../supabase/migrations/20261024010000_restrict_notification_senders.sql');
let db;

before(async () => {
  db = await PGlite.create();
  await db.exec(`
    create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
    create schema auth; grant usage on schema public,auth to anon,authenticated,service_role;
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb default '{}');
    create table public.profiles(id uuid primary key references auth.users,email text,full_name text,role text default 'member',created_at timestamptz default now());
    insert into auth.users(id) values('${member}'),('${admin}');
    insert into public.profiles(id,role) values('${member}','member'),('${admin}','admin');
    create schema vault;
    create table vault.secrets(id uuid primary key default gen_random_uuid(),name text unique,secret text,description text);
    create view vault.decrypted_secrets as select id,name,secret as decrypted_secret from vault.secrets;
    create function vault.create_secret(new_secret text,new_name text,new_description text) returns uuid language sql as $$
      insert into vault.secrets(secret,name,description) values(new_secret,new_name,new_description) returning id $$;
    create schema net;
    create table public.test_push_queue(id bigint generated always as identity, url text,headers jsonb,body jsonb);
    create function net.http_post(url text, headers jsonb, body jsonb) returns bigint language sql as $$
      insert into public.test_push_queue(url,headers,body) values(url,headers,body) returning id $$;
    create table public.events(id bigint generated always as identity,title text,event_date timestamptz);
    create table public.announcements(id bigint generated always as identity,title text,body text);
    create table public.prayer_times(id bigint generated always as identity,date date,fajr text);
    create table public.jummah_configurations(id bigint generated always as identity,khutbah_time text);
    create table public.prayer_notification_sent(notify_date date,slot text,prayer_time time);
    grant all on all tables in schema public to anon,authenticated,service_role;
    grant usage,select on all sequences in schema public to anon,authenticated,service_role;
    create function public.send_onesignal_notification_manual(title text,body text) returns void language plpgsql security definer as $$
    declare os_api_key text := 'fixture-provider-key'; os_app_id text := 'fixture-app-id';
    begin perform net.http_post('fixture', '{}', '{}'); end; $$;
    create function public.try_send_prayer_notification(date,text,text,text) returns boolean language plpgsql security definer as $$
      begin perform public.send_onesignal_notification_manual($3,$4); return true; end; $$;
    create function public.try_send_prayer_notification(date,text,time,text,text) returns boolean language plpgsql security definer as $$
      begin perform public.send_onesignal_notification_manual($4,$5); return true; end; $$;
    create function public.check_prayer_times() returns void language sql security definer as $$ select public.send_onesignal_notification_manual('scheduled','body') $$;
  `);
  await db.exec(await load('../../supabase/migrations/20261024000000_protect_profile_roles.sql'));
  await db.exec(migration);
  await db.exec(migration);
  await db.exec(`create trigger trigger_notify_event after insert on public.events for each row execute function public.send_onesignal_notification();
    create trigger trigger_notify_announcement after insert on public.announcements for each row execute function public.send_onesignal_notification();`);
});
after(async () => { await db?.close(); });

async function asRole(role,userId,callback) {
  await db.exec(`begin; set local role ${role}`);
  await db.query("select set_config('request.jwt.claim.sub',$1,true)",[userId ?? '']);
  try { await callback(); } finally { await db.exec('rollback'); }
}
async function denied(sql) {
  await db.exec('savepoint denied_request');
  try { await assert.rejects(db.exec(sql), error => error.code === '42501'); }
  finally { await db.exec('rollback to savepoint denied_request'); }
}
const rpcCalls = [
  "select public.send_onesignal_notification_manual('attack','body')",
  "select public.try_send_prayer_notification(current_date,'attack','title','body')",
  "select public.try_send_prayer_notification(current_date,'attack','12:00'::time,'title','body')",
  'select public.check_prayer_times()',
];

for (const [role,userId,label] of [['anon',null,'anonymous'],['authenticated',member,'member'],['authenticated',admin,'logged-in admin']]) {
  test(`${label} cannot call any push RPC or overload`, async () => {
    await asRole(role,userId,async () => { for (const sql of rpcCalls) await denied(sql); });
    assert.equal((await db.query('select count(*)::int as n from public.test_push_queue')).rows[0].n,0);
  });
}

test('members cannot cause indirect pushes through events, notices or schedule writes', async () => {
  await asRole('authenticated',member,async () => {
    await denied("insert into public.events(title) values('unauthorized')");
    await denied("insert into public.announcements(title,body) values('unauthorized','body')");
    await denied("insert into public.prayer_times(date,fajr) values(current_date,'12:00')");
    await denied("insert into public.jummah_configurations(khutbah_time) values('12:00')");
    await denied("insert into public.prayer_notification_sent(notify_date,slot) values(current_date,'fake')");
    await denied('truncate public.events');
  });
  assert.equal((await db.query('select count(*)::int as n from public.test_push_queue')).rows[0].n,0);
});

test('verified admin content triggers still enqueue pushes; rollback prevents sending', async () => {
  await db.exec('begin');
  try {
    await db.exec('set local role authenticated');
    await db.query("select set_config('request.jwt.claim.sub',$1,true)",[admin]);
    await db.exec("insert into public.events(title) values('Admin event'); insert into public.announcements(title,body) values('Admin notice','Body')");
    await db.exec('reset role');
    const { rows } = await db.query('select body from public.test_push_queue order by id');
    assert.equal(rows.length,2);
    assert.equal(rows[0].body.headings.en,'New Event: Admin event');
    assert.equal(rows[1].body.headings.en,'Admin notice');
  } finally { await db.exec('rollback'); }
});

test('service_role and the cron database owner can still send', async () => {
  await asRole('service_role',null,async () => { for (const sql of rpcCalls) await db.exec(sql); });
  await db.exec('begin');
  try { await db.exec('select public.check_prayer_times()'); }
  finally { await db.exec('rollback'); }
});

test('restoring an accidental sender grant still cannot bypass the server guard', async () => {
  await db.exec('grant execute on function public.send_onesignal_notification_manual(text,text) to authenticated');
  try {
    await asRole('authenticated',member,async () => { await denied(rpcCalls[0]); });
    await asRole('authenticated',admin,async () => { await denied(rpcCalls[0]); });
  } finally { await db.exec('revoke execute on function public.send_onesignal_notification_manual(text,text) from authenticated'); }
});

test('notification sender source contains no provider credential after Vault migration', async () => {
  const { rows } = await db.query("select prosrc from pg_proc where oid = 'public.send_onesignal_notification_manual(text,text)'::regprocedure");
  assert.ok(!rows[0].prosrc.includes('fixture-provider-key'));
  assert.ok(rows[0].prosrc.includes('vault.decrypted_secrets'));
});

for (const [label,header] of [
  ['missing token',null], ['anon key','Bearer fixture-anon-key'],
  ['user JWT','Bearer fixture-user-jwt'],
  ['forged service-role claim','Bearer eyJhbGciOiJub25lIn0.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.'],
  ['wrong key','Bearer wrong-server-key'],
]) {
  test(`Edge authentication rejects ${label} before running the sender`, async () => {
    let calls=0;
    const req = new Request('https://example.test/notify',{method:'POST',headers:header ? {Authorization:header} : {}});
    const response = await serverOnly(req,'fixture-server-key',async () => { calls++; return new Response('sent'); });
    assert.equal(response.status,401); assert.equal(calls,0);
  });
}
test('Edge authentication accepts only the exact server credential', async () => {
  let calls=0;
  const response=await serverOnly(new Request('https://example.test/notify',{method:'POST',headers:{Authorization:'Bearer fixture-server-key'}}),'fixture-server-key',async()=>{calls++;return new Response('mocked');});
  assert.equal(response.status,200); assert.equal(calls,1);
});
test('Edge authentication fails closed on missing configuration and invalid methods', async () => {
  let calls=0; const handler=async()=>{calls++;return new Response('mocked');};
  assert.equal((await serverOnly(new Request('https://example.test',{method:'POST'}),undefined,handler)).status,503);
  assert.equal((await serverOnly(new Request('https://example.test'),'fixture-server-key',handler)).status,405);
  assert.equal(calls,0);
});

test('the same rollback-only notification verification script passes locally', async () => {
  const results = await db.exec(await load('../../supabase/tests/notification_sender_security.sql'));
  assert.match(results.at(-1).rows[0].result, /^PASS:/);
  assert.equal((await db.query('select count(*)::int as n from public.test_push_queue')).rows[0].n, 0);
});
