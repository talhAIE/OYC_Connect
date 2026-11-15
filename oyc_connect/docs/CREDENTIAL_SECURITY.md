# OneSignal credential incident and environment handling

## Status on 24 October 2026

- Current working-tree source contains no detected private OneSignal, Stripe, or Supabase credential. Previous SQL literals were removed; live notification SQL reads the provider credential from protected Supabase Vault.
- Git history contains **two distinct OneSignal app keys in six historical file versions**. Changing commits include `15c7a28`, `889c7cc`, and `1d75919`. Fingerprints (SHA-256 prefixes, not credentials) are `255f1d34c3e4` and `a727996b83c8`.
- The user elected to rotate/revoke provider keys in OneSignal. **Provider revocation and replacement installation have not been verified by this work.** Do not mark the incident contained merely because current source is clean.
- A sanitized mirror at repository-root `.security/sanitized-history.git` contains rewritten history with no detected keys. It removes the two tracked environment files across history and excludes local Codex snapshot refs. Original active history and GitHub have **not** been rewritten. All uncommitted work remains in the active checkout.
- Remote heads were compared with locally known refs: **10 of 11 branches require rewritten commit IDs**; no remote tags were advertised. The exact expected old hashes and cleaned hashes are recorded in ignored `.security/history-publish-plan.json`. No force-push was performed.

## Rotate/revoke first

In OneSignal, rotate/revoke every exposed app key, including the older key if it belongs to a previous app. Use the app's Settings / Keys & IDs and verify the old keys are invalidated. Merely creating another key does not revoke an old one. Key-management API operations require an Organization API credential; none was supplied to this session. Do not paste keys in chat, issue comments, commit messages, or terminal command arguments.

After obtaining the replacement for the current OYC app, run from `oyc_connect` in PowerShell 7:

```powershell
pwsh -File tools/security/set-onesignal-secret.ps1
```

The helper reads the APP REST key using a hidden secure prompt and:

1. Saves only the OneSignal app ID/key to ignored `supabase/.env.local`, restricted to the current Windows account with inherited ACLs removed.
2. Updates the existing `oyc_onesignal_api_key` and `oyc_onesignal_app_id` Vault records used by SQL cron/triggers.
3. Synchronizes only those two fields to Supabase Edge secrets for optional server endpoints.
4. Removes its private temporary SQL file and never prints secret values or places them in process arguments. CLI diagnostic output is captured because SQL errors might contain query text.

The helper does not rotate or revoke anything in OneSignal. It must be run with an already issued replacement and an authenticated Supabase CLI. The `.env.local` file is dedicated to these two fields and is managed by the helper. Local ACLs reduce access but are not encryption and do not isolate processes running as the same Windows account.

Verify successful secret import and revoke the old credentials in OneSignal. Any needed delivery test should use a controlled test subscriber rather than broadcast to the community. No push is sent by this helper.

## Client and server environment separation

`assets/.env` is a Flutter asset: its contents are public in a shipped app regardless of `.gitignore`. It may contain only public configuration such as Supabase URL/anon key, OneSignal app ID, Stripe publishable key and Sentry DSN. Use `assets/.env.example` to rebuild local client configuration.

OneSignal REST keys, Stripe secret keys, and Supabase service credentials belong only in Vault, server environment secrets, or ignored server-local files. **Never put them in assets/.env or add supabase/.env.local to pubspec assets.** Both local client env files were untracked while retaining working copies. Local env files now have current-user-only Windows ACLs; the server file is a template until the replacement is entered.

Client startup checks reject private fields, recognized private-key prefixes, and service-role JWTs even when mislabeled. CI and Codemagic scan before packaging. A runtime check alone cannot undo a leak in an already distributed asset: build-time checks are essential.

## History cleanup requires a coordinated publication

The sanitized mirror is a **prepared cleanup copy**, not proof that GitHub or existing clones are clean. Publishing the rewrite changes commit IDs on affected branches. Preserve/transfer the active uncommitted application changes, inspect the sanitized branch tips, recheck remote hashes, and obtain approval before replacing shared GitHub history. Use per-branch force-with-lease against the captured original hashes; never blindly `push --mirror` from this tool's mirror, which also contains local tracking refs.

After publishing, collaborators must re-clone or carefully reset to cleaned history, remove contaminated refs/reflogs in old clones, and avoid merging old history back. GitHub PR refs, forks, caches, old clones, release artifacts and backups may retain old material. Coordinate provider revocation and any necessary GitHub sensitive-data-removal request; Git rewriting cannot replace credential revocation. Deleting this task's isolated mirror does not remove the active repository's original exposed history.

The historical cleanup copy has sanitized placeholders where secrets were present; it does not include the current uncommitted feature/security changes. Do not deploy its old application tree as a replacement for the active working files.

## Repeatable scans

From repository root:

```powershell
python oyc_connect/tools/security/scan_secrets.py
python oyc_connect/tools/security/scan_secrets.py --history
python -m unittest discover -s oyc_connect/tools/security -p test_security_scan.py
```

Scans print paths, object IDs and fingerprints, never matched credentials. History scanning covers locally known refs and reflogs; it does not claim to inspect unknown GitHub forks, caches, or other clones. Current-source scan passes. Original-history scan intentionally fails until shared/active history is cleaned. The new GitHub history check will also fail while the old credential-bearing ancestors remain reachable.

To inspect the prepared copy:

```powershell
python oyc_connect/tools/security/scan_secrets.py --repo .security/sanitized-history.git --history
```

Reference: [OneSignal API-key management](https://github.com/OneSignal/onesignal-node-api/blob/main/DefaultApi.md#createapikey).
