# Notification diagnosis and implementation plan

Snapshot: 24 October 2026. Covers Android, iPhone, prayer/Jummah schedules and community publishing. Provider reads are diagnostic; no test broadcast was sent.

## Implementation status

- **Implemented in source:** centralized mobile SDK/session/preference reconciliation; Profile permission/subscription/token status with test subscription ID; notification-type navigation; iOS Debug/Release APNs entitlements and capability; an admin delivery-status screen; CI generation of the public Supabase config required for the iPhone app to start.
- **Deployed to the linked database:** `20261024020000_notification_delivery_pipeline.sql`. Separate Adhan and Iqamah events, Melbourne/DST/cross-midnight selection, independent Jummah checks, atomic deduplication, a private provider-result ledger, stable retry idempotency keys, bounded retries/expiry, and routing metadata. Existing PUBLIC/normal-user sender restrictions remain verified.
- **Verified:** 22 targeted Flutter tests and 39 PostgreSQL/security/Edge-auth tests passed; Android debug compilation succeeded; live cron remains active and recent runs succeed; live sender-negative tests pass. A pre-existing router ProviderRef deprecation remains informational. iOS entitlement XML and build-setting references can be checked here, but the final iOS signature cannot.
- **Still required:** deploy/install the updated mobile builds and perform a targeted visible receipt test on the user's physical Android and iPhone. The phone-specific cause cannot be declared proven or resolved solely from these aggregate records.

## What the live evidence proves

The backend is not globally inactive. The minute cron succeeds, today's prayer rows exist, event/announcement INSERT triggers are enabled, and recent OneSignal requests returned HTTP 200 with message IDs. OneSignal reports 52 successful platform handoffs (51 Android, 1 iOS) for recent prayers, with zero failed/errored recipients. A community event also has a prior accepted message. These are aggregate provider results: they do not prove a banner appeared on the user's phone. The `received = 0` counter alone does not prove non-delivery; receipt reporting depends on platform/SDK capabilities.

The app and server use the same OneSignal App ID. The connected Android emulator has notification permission granted. The currently deployed server credential was accepted by a read-only OneSignal request; provider key revocation/replacement remains a separate incident task.

## Confirmed code/configuration gaps

1. Identity is bound only in explicit login/signup methods. Restored sessions do not explicitly reconcile OneSignal identity or the saved notification preference. Preferences call native opt-in/out without awaiting them; a failed database save can leave device and database state inconsistent.
2. Profile UI displays a database boolean as notification status, even when OS permission, subscription ID or device token is missing. Users cannot see the failing registration step.
3. The tracked iOS project has remote-notification background mode but no APNs entitlement/code-signing entitlement configuration. The installed iPhone build's signature/provisioning and OneSignal APNs settings still require device/account verification.
4. Every notification tap opens Notices, including prayer/event messages; current SQL payloads have no routing metadata.
5. The cron sends an Iqamah-labelled alert using the Adhan column, ignores separate Iqamah fields, and skips Jummah if the daily prayer row is absent.
6. Sends are marked in the old deduplication table when HTTP is queued. Provider rejection/timeout has no durable delivery status, retry visibility, or operator trail. Exact-minute matching has no bounded catch-up.
7. Community pushes fire on creation, not edits. Existing updates are not proof of a broken trigger. Optional notification Edge Functions are not deployed; the active notification path is SQL → pg_net → OneSignal.

## Implementation sequence

### A. Device registration and user feedback

Create one notification service that initializes only on supported mobile platforms, reconciles restored/authenticated sessions with OneSignal login/logout, applies the persisted preference, observes OS/subscription changes, and shows permission/opt-in/token/registration status. Await preference operations, request permission only when appropriate, and recover cleanly when the save fails. Keep native notification failures from making a successful Supabase login appear to fail.

Acceptance: tests cover restored login, logout, preference changes, denied permission and native errors; both platforms expose a safe subscription ID for a targeted test without exposing an FCM/APNs token or server credential.

### B. Native platform and routing fixes

Add iOS debug/production APNs entitlements to the Runner build settings and push capability. Preserve the existing background mode. Route prayer/Jummah taps to Home and all community taps (events and announcements) to Notices. Keep the tap pending until startup and normal-login checks finish. Allow the SDK's normal foreground display only when the profile preference is enabled; suppress it immediately on opt-out without adding duplicate display calls.

Acceptance: Android APK compiles; iOS entitlement files/project references validate. A Mac-signed iPhone build must show the expected APNs entitlement and a registered APNs subscription. No Windows-only check can establish the final iOS signature or APNs credentials.

### C. Server semantics and visibility

Keep the established trusted-caller/ACL protections. Separate Adhan reminders, Adhan time and actual Iqamah alerts using Melbourne time. Keep existing `_30` and `_on` identities to avoid replaying already queued alerts when deploying; add a distinct Iqamah identity only when its field is present. Make Jummah independent of a missing daily prayer row. Add routing metadata and a server-only delivery ledger with HTTP request/provider result correlation, stable idempotency keys, bounded retry behavior and recent-only catch-up. Do not replay old community posts or hours of missed prayer alerts on deployment.

Acceptance: deterministic SQL tests cover time boundaries, Friday, missing data, repeated/concurrent claims, provider errors, and retry state; unauthorized users remain unable to call senders or cause indirect sends. Verify live permissions and cron state without broadcasting test content.

### D. End-to-end device verification

Install the updated Android build and inspect its registration status. Install a signed updated iPhone build and inspect the same status. Use the displayed subscription IDs for a test targeted exclusively to those devices. Check background, foreground, terminated-app taps, opt-out and resume. Check OS channels/Focus/battery policy if the provider accepts but a device still shows no banner. An emulator result cannot certify the physical phone.

Acceptance: each target phone visibly receives a controlled test and opens the correct screen. This step needs an actual test subscription/device; do not substitute an all-member broadcast.

### E. Operational closeout

Replace stale setup documentation that says the undeployed Edge Functions are active. Keep secrets only in Vault/server environment. Include a short runbook for subscription diagnostics, durable provider failures, cron health and controlled test sends. Finish provider key rotation independently; do not weaken sender restrictions to make tests pass.

## Scope limits

The root cause for a particular phone remains unproven until its subscription and visible receipt are checked. FCM/APNs account credentials, provisioning profiles, device Focus/notification-channel settings, and the installed App Store build cannot be inferred from repository files or aggregate delivery counts. Record these as required validation, not a claim that all users already receive alerts.

## Operator runbook

1. Install the updated app, sign in, and enable **Profile → Notifications**. If permission is blocked, enable it in system settings. The diagnostic status card was removed from the profile at the user's request. If registration is pending, check network and the app's FCM/APNs setup; a database preference alone is insufficient.
2. Find the signed-in user's external ID and device subscription in the OneSignal dashboard for a controlled test to that device. Never share REST keys or device push tokens. Verify a visible banner and a correct tap destination with the app foregrounded, backgrounded and closed. No all-member test is necessary.
3. Admins can inspect **Admin Console → Notification delivery** after creating a new announcement/event or a scheduled prayer. `queued` means a provider request is pending; `accepted` means OneSignal returned a message ID, not device confirmation; `failed` includes a sanitized provider/configuration error. The minute scheduler collects results, so status can lag by one cycle.
4. Community creation triggers one push. Editing an existing post does not send another push. Old accepted messages were not backfilled into the new ledger and old community posts are not replayed.
5. Retries use the same OneSignal idempotency key, at most three transport attempts, with short prayer expiry. Permanent errors such as no subscribed users or invalid credentials need correction, not an unlimited retry loop.
6. For iPhone: enable Push Notifications on the Apple App ID, refresh an APNs-capable provisioning profile, configure the matching APNs key/bundle ID in OneSignal, build with the new entitlements, install it on the physical phone, then check its subscription. A new TestFlight/App Store build is required; source edits do not alter an installed app.
7. Codemagic's `oyc_ios_secrets` group must include the **public** SUPABASE_URL, SUPABASE_ANON_KEY and ONESIGNAL_APP_ID. Server REST keys stay in Vault/Edge secrets. The workflow now validates these client variables and runs the credential scan before packaging.
8. Migration `20261024030000` removes `All` segment targeting from the active SQL pipeline. Every attempt resolves only profiles with `notifications_enabled IS TRUE`, targeting their OneSignal external IDs. Anonymous subscriptions are excluded. The optional broadcast Edge Function uses that pipeline; the optional admin sender also filters the preference. These two Edge Functions are not deployed in the linked project.
9. Opt-out regression checks: turn the switch off, publish a new controlled announcement, verify no alert on that account, reopen the app and repeat; then turn it back on and verify the next notification. Already handed-off pushes can still arrive after a switch change. The updated app additionally suppresses foreground display immediately. Automated coverage includes opt-out, retry eligibility, no-recipient behavior, re-enabling, and sender permissions; physical phone behavior still requires this check.
