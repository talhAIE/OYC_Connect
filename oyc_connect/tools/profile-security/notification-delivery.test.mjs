import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
const read = name => readFile(new URL('../../supabase/migrations/' + name, import.meta.url), 'utf8');
let db;
before(async () => {
  db = await PGlite.create();
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema oyc_private; create schema vault; create schema net;
    grant usage on schema public,oyc_private to authenticated,service_role;
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create function oyc_private.current_user_is_admin() returns boolean language sql as $$ select false $$;
    create table vault.secrets(id uuid default gen_random_uuid(),name text unique,secret text,description text);
    create view vault.decrypted_secrets as select name,secret as decrypted_secret from vault.secrets;
    create function vault.create_secret(s text,n text,d text) returns uuid language sql as $$ insert into vault.secrets(secret,name,description) values(s,n,d) returning id $$;
    create table public.test_push_queue(id bigint generated always as identity,url text,headers jsonb,body jsonb);
    create function net.http_post(url text,headers jsonb,body jsonb) returns bigint language sql as $$ insert into public.test_push_queue(url,headers,body) values(url,headers,body) returning id $$;
    create table net._http_response(id bigint,status_code int,timed_out boolean,error_msg text,content text);
    create table public.events(id bigint generated always as identity,title text,event_date timestamptz);
    create table public.announcements(id bigint generated always as identity,title text,body text);
    create table public.profiles(id uuid primary key,notifications_enabled boolean);
    insert into public.profiles values('00000000-0000-0000-0000-000000000001',true),('00000000-0000-0000-0000-000000000002',false),('00000000-0000-0000-0000-000000000003',null);
    create table public.prayer_times(id bigint generated always as identity,date date,fajr text,fajr_iqama text,dhuhr text,dhuhr_iqama text,asr text,asr_iqama text,maghrib text,maghrib_iqama text,isha text,isha_iqama text);
    create table public.jummah_configurations(id int,khutbah_time text,jummah_time text);
    create table public.prayer_notification_sent(notify_date date,slot text,prayer_time time);
    create function public.send_onesignal_notification_manual(title text,body text) returns void language plpgsql security definer as $$
      declare os_api_key text := 'fixture-only'; os_app_id text := 'fixture-app'; begin null; end; $$;
  `);
  await db.exec(await read('20261024010000_restrict_notification_senders.sql'));
  await db.exec(await read('20261024020000_notification_delivery_pipeline.sql'));
  await db.exec(await read('20261024020000_notification_delivery_pipeline.sql'));
  await db.exec(await read('20261024030000_enforce_notification_preferences.sql'));
  await db.exec(await read('20261024030000_enforce_notification_preferences.sql'));
});
after(async () => { await db?.close(); });
async function transaction(callback) { await db.exec('begin'); try { await callback(); } finally { await db.exec('rollback'); } }
async function due(at) { return (await db.query('select * from oyc_private.due_prayer_notifications($1::timestamptz)', [at])).rows; }

test('Adhan and Iqamah use different fields and accurate messages', async () => transaction(async () => {
  await db.exec("insert into public.prayer_times(date,fajr,fajr_iqama) values('2026-10-24','4:50 AM','5:30 AM')");
  const adhan = await due('2026-10-24T04:50:20+11:00');
  assert.equal(adhan[0].slot,'fajr_on'); assert.match(adhan[0].body,/Adhan/);
  const iqamah = await due('2026-10-24T05:30:20+11:00');
  assert.equal(iqamah[0].slot,'fajr_iqamah'); assert.match(iqamah[0].body,/Iqamah/);
  assert.equal((await due('2026-10-24T05:33:00+11:00')).length,0);
}));
test('Friday reminder works without any daily prayer row', async () => transaction(async () => {
  await db.exec("insert into public.jummah_configurations values(1,'1:30 PM','2:00 PM')");
  assert.equal((await due('2026-10-23T13:00:15+11:00'))[0].slot,'jummah_30');
  assert.equal((await due('2026-10-23T14:00:15+11:00'))[0].slot,'jummah_iqamah');
  assert.equal((await due('2026-10-24T13:30:15+11:00')).length,0);
}));
test('cross-midnight reminder and DST use Melbourne calendar time', async () => transaction(async () => {
  await db.exec("insert into public.prayer_times(date,fajr) values('2026-10-25','12:15 AM'),('2026-10-04','5:00 AM')");
  assert.equal((await due('2026-10-24T23:45:30+11:00'))[0].slot,'fajr_30');
  assert.equal((await due('2026-10-03T18:00:30Z'))[0].slot,'fajr_on');
}));
test('malformed time values are skipped instead of aborting other prayers', async () => transaction(async () => {
  await db.exec("insert into public.prayer_times(date,fajr,asr) values('2026-10-24','invalid','4:48 PM')");
  assert.equal((await due('2026-10-24T16:48:30+11:00'))[0].slot,'asr_on');
}));
test('atomic prayer claim queues only once and sets prayer routing metadata', async () => transaction(async () => {
  await db.exec("select public.try_send_prayer_notification('2026-10-24','fajr_on','04:50','Fajr','Adhan'); select public.try_send_prayer_notification('2026-10-24','fajr_on','04:50','Fajr','Adhan')");
  const rows=(await db.query('select body from public.test_push_queue')).rows;
  assert.equal(rows.length,1); assert.equal(rows[0].body.data.type,'prayer'); assert.ok(rows[0].body.idempotency_key);
}));
test('provider acceptance is recorded separately from queuing', async () => transaction(async () => {
  await db.exec("select public.send_onesignal_notification_manual('Title','Body')");
  assert.equal((await db.query('select status from oyc_private.notification_delivery')).rows[0].status,'queued');
  await db.exec(`insert into net._http_response select http_request_id,200,false,null,'{"id":"provider-message"}' from oyc_private.notification_delivery`);
  await db.exec('select oyc_private.collect_notification_results()');
  const row=(await db.query('select status,provider_message_id from oyc_private.notification_delivery')).rows[0];
  assert.deepEqual(row,{status:'accepted',provider_message_id:'provider-message'});
}));

test('prayers and broadcasts only target explicitly opted-in profile aliases', async () => transaction(async () => {
  await db.exec("select public.send_onesignal_notification_manual('Title','Body'); select public.try_send_prayer_notification('2026-10-24','fajr_on','04:50','Fajr','Adhan')");
  const rows=(await db.query('select body from public.test_push_queue')).rows;
  assert.equal(rows.length,2);
  for (const {body} of rows) {
    assert.deepEqual(body.include_aliases.external_id,['00000000-0000-0000-0000-000000000001']);
    assert.equal(body.included_segments,undefined);
    assert.equal(body.target_channel,'push');
  }
}));

test('opting out before a retry prevents any further provider request', async () => transaction(async () => {
  await db.exec("select public.send_onesignal_notification_manual('Title','Body')");
  await db.exec(`insert into net._http_response select http_request_id,503,false,null,'{}' from oyc_private.notification_delivery`);
  await db.exec('select oyc_private.collect_notification_results(); update public.profiles set notifications_enabled=false; update oyc_private.notification_delivery set next_attempt_at=now(); select oyc_private.collect_notification_results()');
  assert.equal((await db.query('select count(*)::int as n from public.test_push_queue')).rows[0].n,1);
  const row=(await db.query('select status,retryable,last_error from oyc_private.notification_delivery')).rows[0];
  assert.equal(row.status,'failed'); assert.equal(row.retryable,false); assert.match(row.last_error,/No opted-in/);
}));

test('no recipients never falls back to broadcasting to everyone', async () => transaction(async () => {
  await db.exec("update public.profiles set notifications_enabled=false; select public.send_onesignal_notification_manual('Title','Body')");
  assert.equal((await db.query('select count(*)::int as n from public.test_push_queue')).rows[0].n,0);
}));

test('turning notifications back on restores eligibility for the next notification', async () => transaction(async () => {
  await db.exec("update public.profiles set notifications_enabled=true where id='00000000-0000-0000-0000-000000000002'; select public.send_onesignal_notification_manual('Title','Body')");
  const {body}=(await db.query('select body from public.test_push_queue')).rows[0];
  assert.deepEqual(body.include_aliases.external_id,['00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002']);
}));
test('empty success response / unsubscribed recipients is recorded as a failure', async () => transaction(async () => {
  await db.exec("select public.send_onesignal_notification_manual('Title','Body')");
  await db.exec(`insert into net._http_response select http_request_id,200,false,null,'{"id":"","errors":["No subscribed users"]}' from oyc_private.notification_delivery`);
  await db.exec('select oyc_private.collect_notification_results()');
  const row=(await db.query('select status,retryable,last_error from oyc_private.notification_delivery')).rows[0];
  assert.equal(row.status,'failed'); assert.equal(row.retryable,false); assert.match(row.last_error,/No subscribed/);
}));
test('transient retry reuses the same OneSignal idempotency key', async () => transaction(async () => {
  await db.exec("select public.send_onesignal_notification_manual('Title','Body')");
  await db.exec(`insert into net._http_response select http_request_id,503,false,null,'{}' from oyc_private.notification_delivery`);
  await db.exec('select oyc_private.collect_notification_results(); update oyc_private.notification_delivery set next_attempt_at=now(); select oyc_private.collect_notification_results()');
  const rows=(await db.query('select body from public.test_push_queue order by id')).rows;
  assert.equal(rows.length,2); assert.equal(rows[0].body.idempotency_key,rows[1].body.idempotency_key);
}));
test('unauthorized roles cannot read the ledger or enqueue sends', async () => transaction(async () => {
  await db.exec('set local role authenticated; savepoint denied');
  await assert.rejects(db.exec("select oyc_private.enqueue_notification('attack','T','B','{}')"), e=>e.code==='42501');
  await db.exec('rollback to savepoint denied');
  await assert.rejects(db.exec('select * from oyc_private.notification_delivery'),e=>e.code==='42501');
}));
