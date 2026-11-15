# Notification caller restrictions

## Applied protection

Migration `20261024010000_restrict_notification_senders.sql` was applied to linked OYC Connect (`jbjtrppxzbgwbqzcpcib`) on 24 October 2026.

- Removes PUBLIC, anon, and authenticated EXECUTE on all deployed overloads of `send_onesignal_notification_manual`, `try_send_prayer_notification`, `check_prayer_times`, and notification trigger helpers. Trigger functions do not need direct API EXECUTE, even for service_role.
- Grants direct sender/scheduler execution only to `service_role`; database owners retain administrative access and the existing postgres-owned cron remains active.
- Adds a second caller check at the provider boundary. Signed-in admins cannot call sending RPCs directly. Only approved admin content writes may invoke the server-owned trigger path.
- Enables admin-only writes on events, announcements, prayer times and Jummah configurations to prevent indirect push sending or schedule tampering. Public reads remain; members cannot write these tables. Restrictive policies retain the admin requirement if a later permissive policy is added.
- Removes client access to the prayer notification deduplication table and client CREATE access on public. Legacy SQL bodies get a fixed search path with pg_temp last.
- Moves the existing OneSignal app ID and REST credential into Vault, without returning the secret or copying it into local files. Sender code reads `oyc_onesignal_app_id` and `oyc_onesignal_api_key`. Live authenticated clients have neither Vault schema usage nor secret SELECT access.

Existing notification timing/content is preserved. This change does not revise retries, prayer/Iqamah semantics, or payment verification.

## Edge Functions

`notify_broadcast` and `notify-admins` are **not deployed** in the linked project. Their source now wraps the handler in `serverOnly` before parsing payloads, querying profiles, or calling OneSignal. It requires POST and an exact bearer match to the server's `SUPABASE_SERVICE_ROLE_KEY`. Missing configuration fails closed. A decoded token's role claim is insufficient. Gateway JWT verification is also enabled.

No new Edge endpoint was deployed. If these optional endpoints are deployed later, invoke them from trusted server code with its service credential; do not forward a user's Authorization header or use an anon key. Never put service credentials in Flutter assets or browser code. A server exposing its own API must separately authorize callers.

The optional donation trigger script now ignores client-originated history inserts and uses a vaulted server credential instead of forwarding user tokens. It was not installed. Enable it only with a verified server-side payment source, configured secrets, and a guarded deployed endpoint.

## Tests and verification

From `tools/profile-security`, run `npm ci --ignore-scripts` then `npm test` with Node 25 (native TypeScript stripping loads the shared Edge-auth module).

PostgreSQL tests use PGlite and a mocked `net.http_post` queue; no provider requests leave the runtime. They cover anonymous/member/admin-client denial, both prayer-helper overloads, indirect writes, accidental regrant defense, Vault migration, trusted cron/service execution, and approved admin triggers. Shared Edge-auth tests reject missing/public/user/forged/incorrect credentials before entering a mocked handler and accept only the exact server credential. Profile-role regressions run too.

Rerun the deployed authorization checks as the database owner:

```powershell
supabase db query --linked --file supabase/tests/notification_sender_security.sql
```

The script impersonates anon/member/admin-client roles, checks sender ACLs, tests forbidden direct/indirect requests, and rolls back all writes. No positive push is sent. Positive dispatch is tested locally with mocks, not real recipients. This tests PostgreSQL authorization rather than mobile login or provider delivery.

Live verification confirmed active cron, denied client sender grants, retained service-role execution, and no provider-key literals in public function definitions. Existing users/roles were not changed. Record this migration after successful live verification with `supabase migration repair 20261024010000 --status applied --linked` when SQL is applied directly.

## Credential rotation remains required

The previously committed OneSignal REST credential was moved, **not rotated**. Rotate/revoke the old credential in OneSignal, then update the Vault value with the new key. Moving a credential cannot revoke copies from Git history or elsewhere. This change closes application/database sending entrypoints; it cannot prevent direct provider API use with an already exposed valid provider credential. Historical literals were removed from the current working tree, but remain in Git history.

For a new environment, provision `oyc_onesignal_api_key` and `oyc_onesignal_app_id` in Vault before this migration. On the existing installation, bootstrap transferred them internally from the old function. The migration is authoritative: do not reinstall old repair scripts afterward.

References: [Supabase function privileges](https://supabase.com/docs/guides/database/functions), [Edge Function authentication](https://supabase.com/docs/guides/functions/auth).
