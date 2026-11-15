# Profile role protection

## Enforced database contract

`supabase/migrations/20261024000000_protect_profile_roles.sql` enables profiles RLS, replaces legacy policies, removes broad table and column write grants, and grants `authenticated` users UPDATE only on `full_name` and `notifications_enabled`. RLS further limits those updates to the caller's own profile. Identity, email, phone, timestamps, and authorization roles are server-owned. Clients cannot insert, upsert, delete, or truncate profile rows. The existing account-deletion RPC remains the separate server-owned path for account deletion.

Members can read only their own profile. Admins can read profiles needed for donor history, but a logged-in admin is still an `authenticated` database caller: they cannot edit anyone else's profile or change any role. A private, fixed-search-path helper reads the caller's stored role without recursive RLS or trusting editable metadata.

The role trigger rejects untrusted role changes even if a future migration accidentally grants UPDATE(role), or an accidentally exposed SECURITY DEFINER RPC attempts the update. It checks both the actual database execution role and the request's active SET ROLE. Only the server `service_role` and trusted database administration roles can assign roles. Existing role assignments are preserved. Signup always sets `member`, ignores role metadata, and preserves name/phone creation.

## Trusted server role changes

Use a server-only Supabase client with the service-role credential and no forwarded end-user Authorization header:

```ts
const { error } = await supabaseAdmin.rpc('set_profile_role', {
  target_user_id: userId,
  new_role: 'admin', // or 'member'
});
if (error) throw error;
```

Keep the service credential out of Flutter assets, browser code, logs, and Git. If a server endpoint calls this RPC, it must separately authorize the requesting operator; do not expose a public role-changing endpoint. No such endpoint or client role-management UI is added here. Invalid roles and nonexistent targets are rejected.

## Deployment and verification

Apply only the reviewed migration as the database owner. Do not blindly replay the repository's unrelated legacy setup/repair scripts.

```powershell
supabase db query --linked --file supabase/migrations/20261024000000_protect_profile_roles.sql
supabase db query --linked --file supabase/tests/profile_role_protection.sql
```

The verification script requires an existing member and admin. It impersonates `authenticated`, `anon`, and `service_role`, asserts forbidden requests fail, verifies permitted self updates and trusted role assignment, and rolls back **all test writes**. It fails if the test users are unavailable. It does not print member identity or profile contents. This verifies the live database authorization layer, not an end-to-end app login or HTTP request.

After applying SQL directly, record this exact migration in migration history if it is not already recorded:

```powershell
supabase migration repair 20261024000000 --status applied --linked
```

The migration is rerunnable and fails rather than silently replacing unknown existing role values. Review any failure before changing existing users or roles.

## Repeatable local regression tests

From `oyc_connect/tools/profile-security`:

```powershell
npm ci --ignore-scripts
npm test
```

These tests execute actual SQL in PGlite's embedded PostgreSQL engine, with isolated Supabase-style roles, `auth.uid()`, signup fixtures, legacy table/column grants, and deliberately permissive old policies. They first reproduce self-promotion before applying the migration, then test direct/mixed UPDATE, INSERT/UPSERT, admin and anonymous callers, private field editing, cross-user editing, server-only RPCs, metadata injection, signup, repeated deployment, accidental future grants/policies, and the same rollback-only verification SQL used on the linked database. They need neither production credentials nor Docker. PGlite does not reproduce PostgREST or the complete Supabase infrastructure.

## Verified deployment on 24 October 2026

Applied to the linked **OYC Connect** project (`jbjtrppxzbgwbqzcpcib`). Before the change, profiles RLS was disabled and client roles had broad writes. The live rollback-only checks passed afterward. Final checks confirmed RLS enabled, authenticated role UPDATE/RPC denied, permitted name UPDATE granted, and service-role RPC granted. Existing role counts remained **4 admins and 96 members**. No existing user's role was changed by deployment or retained test writes.

This closes the reviewed role-editing path; it does not retroactively determine whether any existing admin assignment was legitimate. Review existing administrators separately if compromise is suspected. Unrelated backend functions and tables were not audited or modified in this change.

Design reference: [Supabase column-level security](https://supabase.com/docs/guides/database/postgres/column-level-security). Both table-level and column-level grants must be considered because privileges are additive.
