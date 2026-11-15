# OYC Connect project review

Reviewed 24 October 2026. Scope: the current working tree, including uncommitted changes. This is a repository-wide source and configuration assessment, not certification of the deployed service. No application source, database, credentials, or deployment configuration was changed.

## Assessment

OYC Connect implements a substantial community application. Its feature folders, repository classes, Riverpod state, Freezed models, and GoRouter navigation form a reasonable foundation. The most urgent problems are backend authorization, secret handling, release configuration, and lack of meaningful automated tests. I would not approve a new production release from the repository as supplied until the critical findings and startup configuration are resolved.

Two findings are critical **if the supplied setup policies/functions are deployed as written**: members can grant themselves admin privileges, and privileged push functions may be callable by client roles. A OneSignal REST credential is present in tracked SQL regardless of deployment state; treat it as exposed. Its validity was not tested.

## Scope and evidence

- 83 Dart files under `lib`, including 59 handwritten files and 24 generated files. Handwritten files contain 9,932 nonblank lines using PowerShell `Measure-Object -Line`.
- Eight feature areas: authentication, home, prayer times, community, classes, donation, profile, admin.
- Four Supabase Edge Function entrypoints: `notify_broadcast`, `notify-admins`, `request-password-reset`, `stripe-payment-intent`.
- Android, iOS, web, Windows, macOS, and Linux platform folders exist. Their presence does not establish runtime support.
- 44 Git status entries were present during inspection. Existing modifications and untracked files were preserved.
- Source review covered application bootstrap/routing, models/providers/repositories, principal screens and mutation flows, SQL/setup documentation, Edge Functions, native manifests, build configuration, CI, and test setup. Generated serializers/platform boilerplate were inspected as supporting configuration rather than reviewed line by line.
- No live Supabase queries, production endpoint probes, payment attempts, push sends, account operations, or deployments were performed.

## Architecture and actual behavior

The bootstrap loads bundled `assets/.env`, initializes timezone data and Sentry, then initializes Supabase and optionally OneSignal. A Riverpod `ProviderScope` hosts the application. GoRouter listens to authentication changes and uses an indexed shell for Home, Community, Website, Classes, and Profile. Admin pages sit under `/profile/admin`.

Presentation widgets consume Riverpod providers, which call repositories using the global Supabase client. Some screens bypass repositories, notably donation history and account deletion. Most models use Freezed/JSON generation; khateebs use a handwritten model. The project follows feature-oriented organization, but it does not consistently separate business rules from widgets.

Data dependencies include `profiles`, `prayer_times`, `jummah_configurations`, `khateebs`, `events`, `announcements`, `classes`, `teachers`, `weekly_schedules`, and legacy `payments`. Storage uploads use `app_assets`. Prayer and Jummah data use realtime streams; events, announcements, and class schedules primarily use one-shot requests and provider invalidation.

### Feature coverage

- Authentication: email/password signup and login, reset email via an Edge Function, custom-scheme recovery, change password, logout. Signup explicitly signs out afterward.
- Home/prayer: Melbourne time, NTP-adjusted clock/countdown, Adhan/Iqamah display, Friday configuration, monthly calendar, Qibla screen. Admins can edit prayer times and import a month from AthanPlus HTML.
- Community: event and announcement lists, details, images, urgent notices, and admin create/edit/delete flows.
- Classes: weekly and Quran schedules, classes and teachers, optional times, admin management.
- Donation: **the current client opens an external donation website**. It no longer runs an in-app Stripe checkout. Stripe/payment-table/admin-history code remains in the backend and admin UI.
- Profile: name editing, notification preference, password change, account deletion via SQL RPC, support information, admin entry.
- Notifications: overlapping SQL-trigger, cron, webhook, and Edge Function paths. Deployment choice determines which paths actually run.

## Critical and high-priority findings

### F01 — Critical: supplied profile policies allow self-promotion to admin

Evidence: `oyc_connect/supabase_connect.md:37`, especially lines 41 and 53–59. Profiles contain `role`; users may insert/update their own row with only `auth.uid() = id`. No supplied column restrictions or role-protection trigger prevents changing `role`. Other policies authorize management by checking that same field, for example `supabase/classes_setup.sql:22`.

Impact: if deployed as documented with client update privileges, a member can change their own role through the database API and acquire administrative write access. Restricting the Flutter update map or hiding admin navigation does not protect direct API calls.

Action: enforce role changes on the server, revoke broad client table updates and grant only explicitly editable columns, protect inserts, and test member-to-admin escalation against a disposable database. Verify actual grants, policies, and any protections already installed in production before declaring production vulnerable or fixed.

### F02 — Critical deployment risk: privileged notification RPCs lack explicit access restrictions

Evidence: `supabase/migrations/fix_prayer_jummah_notifications.sql:53`, `:110`, `:140`. `send_onesignal_notification_manual(title, body)` and related helpers are `SECURITY DEFINER` functions in `public`; no corresponding execute revocations appear in the supplied scripts. Several definer functions also omit a fixed safe `search_path`.

Impact: under default PostgreSQL/Supabase function privileges, API clients may invoke privileged broadcasts with arbitrary text. The deduplication helper also accepts caller-supplied date/slot values. Actual exposure depends on deployed ACLs and API schema settings.

Action: explicitly revoke execution from PUBLIC/anon/authenticated for internal helpers, grant only the trusted execution role, consider a private schema, fix the search path, and verify anonymous/member calls fail. PostgreSQL grants PUBLIC execute on new functions by default; granting another role does not remove PUBLIC access. Sources: [PostgreSQL CREATE FUNCTION](https://www.postgresql.org/docs/current/sql-createfunction.html), [Supabase database functions](https://supabase.com/docs/guides/database/functions).

### F03 — High: OneSignal REST credential committed in SQL

Evidence: `supabase/sql_deploy_onesignal.sql:10` and `supabase/migrations/fix_prayer_jummah_notifications.sql:58` contain a literal OneSignal REST API credential. It is intentionally omitted from this report.

Impact: anyone with repository/history access can obtain it. Removing the current text alone cannot revoke previously copied credentials.

Action: rotate/revoke the credential with the service owner, move it to protected server secrets or a suitable vault, remove literals, and scan history. Public Supabase anon keys, OneSignal app IDs, Stripe publishable keys, and public signing certificates are not equivalent to private service credentials.

### F04 — High: documented profile SELECT policy exposes member information

Evidence: `supabase_connect.md:49` allows SELECT using true on profiles containing email/full name/role.

Impact: if deployed unchanged and SELECT is granted, client API callers including anonymous users can enumerate profile information.

Action: restrict private profile reads to the owner and authorized admins; expose only necessary public fields through a separate view or table. Check deployed policies before determining actual exposure.

### F05 — High: Codemagic overwrites required Supabase startup configuration

Evidence: `codemagic.yaml:38` recreates `assets/.env` with only `ONESIGNAL_APP_ID` and `SENTRY_DSN`. `lib/core/constants/supabase_constants.dart:4` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` exclusively from dotenv and defaults to empty strings. `lib/main.dart:34` initializes Supabase from those values.

Impact: an IPA built by this workflow can lack the URL/key required to initialize the app. Adding environment variables to a Codemagic group does not help unless the script writes them or the application reads them another way. The numeric App Store ID is also still `0000000000`, and the notification email is a placeholder.

Action: validate required variables and write them into the generated client config; distinguish public client configuration from backend secrets; replace placeholders and run a release startup smoke test.

### F06 — High: exposed legacy payment paths do not establish trustworthy payment records

Evidence: `supabase/payments_setup.sql:20` permits users to insert their own payments, including arbitrary amount/currency/status/intent ID. `functions/notify-admins/index.ts:9` trusts caller-supplied payment records and uses a service-role client; JWT verification alone does not prove webhook provenance. `functions/stripe-payment-intent/index.ts` is configured with `verify_jwt = false` and no application rate limiting or idempotency.

Impact: if these paths remain deployed, users may fabricate donation records or notifications and unauthenticated callers may create unwanted payment intents. The current external donation client does not require these endpoints. No Stripe verification webhook is present in the supplied function set.

Action: retire obsolete deployed endpoints/tables/UI if unused. If payment reconciliation is required, accept authoritative payment status only from verified provider events, reject client status writes, and add idempotency and abuse controls. Do not assume the external donation website populates this app's payments table; no such integration appears here.

## Functional and reliability findings

### F07 — High: today's prayer stream remains bound to the previous date

Evidence: `lib/features/prayer_times/presentation/providers/prayer_times_provider.dart:25` computes Melbourne's date once when its stream starts. The indexed shell preserves screens. No midnight timer or app-resume invalidation is present. `home_page.dart:309` derives tomorrow's Fajr by adding a day to today's time instead of fetching tomorrow's row.

Impact: an open session can continue displaying yesterday's schedule after Melbourne midnight; after Isha, tomorrow's countdown can be inaccurate even when tomorrow's database schedule differs. Adding a fixed 24 hours also needs care across DST transitions.

Action: centralize a Melbourne business-date provider, refresh it on midnight/resume, and fetch actual next-day data. Use timezone-aware calendar construction rather than assuming every local day has 24 hours.

### F08 — Medium: prayer notifications use Adhan fields while claiming Iqamah

Evidence: notification migration lines 164–171 parse `fajr`, `dhuhr`, etc.; lines 188–196 send “Iqamah will start Shortly” at those parsed times. The client model separately exposes `*_iqama` fields. The cron also returns early if no daily prayer row is found, before its otherwise independent Jummah check.

Action: explicitly define the desired Adhan/Iqamah/reminder contract, schedule each from its actual column, and allow Friday configuration to work independently of missing daily data when appropriate.

### F09 — Medium: notification deduplication and delivery recovery are incomplete

Evidence: notification migration lines 119–128 check existence, enqueue an HTTP request, then insert the deduplication row. The insert's conflict handling happens after enqueueing. `net.http_post` response success is not checked here. The check matches only the exact current minute.

Impact: concurrent calls can enqueue duplicates; a provider failure may still leave the slot marked sent; a delayed/missed cron run has no catch-up. SQL-trigger and webhook implementations can also duplicate broadcasts if both are installed.

Action: use an atomic claim/outbox, delivery status and bounded retries, provider idempotency where available, a deliberate catch-up window, and one authoritative notification pipeline. Protect the deduplication table with suitable grants/RLS; its creation script does not enable RLS.

### F10 — Medium: recovery routing accepts failed or loosely matched reset links

Evidence: `lib/core/router/router.dart:239` and `:250` use substring matching for `reset-password`; session recovery errors are swallowed and recovery state is set anyway. A stricter `AppLinkHandler` exists but is not mounted in `main.dart` or the router tree. Router/listenable creation has no `ref.onDispose` registration.

Impact: invalid/expired links can lead to a password form without a usable recovery session. Multiple competing implementations complicate diagnosis. Existing Supabase SDK deep-link handling adds another path to verify.

Action: consolidate link handling; validate scheme/host/path, establish recovery only after success, show invalid-link feedback, and dispose router/listener resources. Test cold/warm app links, expired links, logout, and password completion. This finding does not establish an authentication bypass.

### F11 — Medium: error masking produces misleading profile and edit states

Evidence: `profile_provider.dart:29` converts every profile failure to null. `updateName` wraps failures with `AsyncValue.guard` rather than rethrowing; `edit_profile_page.dart:34` awaits it and then reports success without checking provider error state. Prayer/Jummah providers also swallow several initial/stream failures despite repositories rethrowing them.

Impact: connectivity/permission/schema failures can appear as a missing profile, absent admin permissions, stale prayer data, a loading state, or successful edits.

Action: represent missing data separately from request failure, propagate mutation results to the submitting screen, and provide retry/diagnostic states. Preserve useful cached data while visibly reporting stale status.

### F12 — Medium: events can disappear behind old records and use inconsistent timezones

Evidence: `community_repository.dart:13` sorts events ascending and limits to 50 without a future-date filter or pagination. Admin event creation uses device-local `DateTime`; its ISO value is sent to a timestamptz column without explicit Melbourne interpretation/UTC normalization. Event display uses `DateFormat` without a consistent Melbourne conversion.

Impact: 50 historical events can exclude upcoming events. Admins/members in different timezones may create or see unintended event times.

Action: define upcoming/archive behavior, filter and paginate accordingly, and normalize venue-local event input to an unambiguous instant. Display with an explicit venue or user timezone label.

### F13 — Medium: schedule edits cannot clear nullable fields

Evidence: `schedule_repository.dart:151` only includes `teacher_id`, `start_time`, `end_time`, and `notes` when non-null. The editor passes null for cleared optional selections.

Impact: “clear teacher/time” can leave the previous value in the database. The editor also accepts multiple selected days but update uses only `selectedDays.first`; its callback is not awaited before the dialog closes.

Action: distinguish omitted fields from explicit null, define single-day versus multi-day edit behavior, and await mutations with saving/error feedback.

### F14 — Medium: Qibla permission and widget lifecycle edge cases

Evidence: `qibla_page.dart:34` uses `enabled && always || whileInUse`, so while-in-use permission passes even if location services are disabled. Permission/geocoding paths call `setState` after awaits without mounted checks. No supported-sensor check is present; permission exceptions can leave the spinner. The no-data next-prayer fallback displays a real-looking hardcoded `04:33 AM`.

Impact: leaving the page during a request can trigger lifecycle errors; disabled location services or missing sensors have weak recovery; absent prayer data can be misrepresented. Haptic feedback is triggered directly during stream builds whenever aligned, potentially repeatedly.

Action: group permission conditions, check services and sensor support separately, handle denied-forever/settings, guard asynchronous updates, show unavailable data honestly, and trigger haptics on alignment transitions.

### F15 — Medium: class reads force a global logout on an expired token

Evidence: `_safeExecute` in classes/teachers/schedule repositories signs out and retries anonymously on expired JWT errors.

Impact: a transient token refresh issue while reading public data can end the user's session and redirect the app, bypassing the repository's normal OneSignal logout coordination.

Action: coordinate refresh/retry centrally, preserve valid sessions, and report expired authentication explicitly when refresh fails.

### F16 — Medium: reset endpoint reveals account membership

Evidence: `request-password-reset/index.ts:57` returns a different status/message for an unregistered email. The accompanying email-existence RPC grants service_role execution but never revokes PUBLIC/default client execution.

Impact: callers can distinguish registered emails; the supposedly internal RPC may also expose that lookup under default ACLs. Endpoint throttling is left to upstream configuration.

Action: return a uniform response, revoke client execution of the internal lookup, and verify upstream/app-level abuse controls. Enforce the intended redirect allowlist on the server and in Supabase configuration.

### F17 — Medium: notification preference and identity are not fully reconciled

Evidence: profile preference updates call local OneSignal opt-in/out plus a database update. A database failure reverts Riverpod state without reversing the SDK change. Login/session restoration does not explicitly restore the stored preference; identity binding occurs only in explicit signup/signin methods. All click payloads route to Community Notices (`main.dart:70`), including prayer/event/admin donation alerts.

Action: reconcile identity and subscription preference from authenticated state, coordinate failed updates, and route by validated notification type and entity. Verify behavior on multiple devices and persisted sessions.

## Database reproducibility and deployment

The base schema is embedded in `supabase_connect.md`, while other tables and functions live in manually executed SQL files outside the migration directory. A fresh migration replay therefore cannot reproduce the application's complete backend. The core setup lacks fields the client writes or expects, including profile notification preferences and prayer Iqamah columns. Some models supply defaults for absent JSON fields, but writes still require actual columns. Storage bucket/policy creation and realtime publication settings are not captured as a complete repeatable setup.

`migrations/fix_prayer_jummah_notifications.sql` also lacks the timestamp-prefixed naming used by the other migrations. Multiple scripts replace the same cron function with different implementations, including older timezone conversion logic. Deployment order changes behavior. The donation trigger targets a different Supabase project hostname from the reset page/default images; the intended destination must be confirmed.

Action: export and review the actual schema/grants/policies, convert the authoritative setup into ordered migrations, keep historical repair scripts out of the deployment path, and test a clean disposable database reset. Include grants, column restrictions, storage policies, realtime configuration, cron jobs, and function permissions.

## Build, platform, observability, and maintenance

- **iOS push configuration is incomplete in source:** remote-notification background mode is present, but no iOS entitlements file or `CODE_SIGN_ENTITLEMENTS` setting appears in the tracked project. Verify the signed artifact's APNs entitlement, provisioning, device delivery, and any OneSignal extension requirements on macOS. Source alone cannot establish working push.
- **Android releases silently fall back to debug signing** when `key.properties` is missing (`android/app/build.gradle.kts:80`). Fail release builds instead. Public PEM upload certificates are not private keystores.
- **Other platforms are scaffolds rather than verified products:** mobile OneSignal/Qibla calls are not platform-gated. The macOS release entitlement lacks network-client access; web metadata remains Flutter template content. No web/desktop runtime or native release build was verified.
- **Sentry samples traces at 100%** (`main.dart:30`), but DSN configuration is optional. Define release/environment tags, sampling and privacy settings, and ensure swallowed backend errors are captured where actionable. No crash-delivery test was run.
- **Configuration hygiene:** both `assets/.env` and `assets/env` are tracked, even though `.env` now appears in `.gitignore`. Ignoring a file does not untrack it. The inspected environment key names correspond to client configuration; do not misclassify all bundled public keys as secrets. Add a sanitized example and consolidate configuration.
- **Maintainability:** prayer parsing and next-prayer calculations are duplicated across widgets/SQL; large screens include Home (949 lines), Community (872), and Qibla (676). Extract pure time logic, typed schedule mutations, and reusable display components. Avoid introducing a heavy architectural framework solely to reduce file size.
- **UI/accessibility review needed:** fixed compass dimensions, floating navigation, immersive system UI, hardcoded colors and text, and missing font assets for the declared Inter font merit testing on small screens, landscape, large text, keyboard and screen readers. These are source-level concerns, not visually verified failures.
- **Prayer HTML import is fragile:** fixed CSS selectors, no explicit HTTP timeout, sequential per-day writes, assumed AM/PM defaults, no response-month validation, and no atomic preview/commit. A markup change may yield a misleading “0 days” success or partial import. Validate a complete parsed batch before persisting; fixtures should cover real source variants.
- **Image lifecycle:** uploads can leave orphaned storage objects when saving fails or content is deleted; no cleanup mechanism is present. Server-side size/MIME/write policies need verification.
- **Legacy Stripe helper:** still multiplies all currencies by 100, including JPY/KRW/VND. If retained, use the payment provider's currency minor-unit rules and amount limits; otherwise remove this obsolete deployed surface. No transaction was attempted.
- **Documentation drift:** README is mostly template text; `plan.md` contains outdated checkboxes; existing `APP_ANALYSIS.md` discusses removed Stripe client files and issues already changed. Treat this review as a dated snapshot and rewrite onboarding from actual configuration.
- **CI:** the supplied workflow has no analyzer/test gate, uses moving Flutter stable/Xcode latest, and supplies only an iOS publishing path. Pin a verified toolchain and add checks before signing/publishing. Dependency vulnerability/advisory scanning was not performed; no claim of vulnerability-free dependencies is made.

## Checks actually executed

The normal Flutter batch launcher stalled in the restricted environment. Running the cached Flutter tool directly first identified denied SDK-cache lock access. With the required SDK access, the test runner executed successfully and reported the project test failure below. Dart analysis also completed. The original stalled launchers were interrupted.

- Dart SDK: 3.12.2 stable, Windows x64.
- Static analysis: `dart analyze --format machine` using the installed SDK. **0 errors, 1 warning, 29 informational diagnostics; exit 1.** The warning is unused `currency` in donation history. Informational findings include 15 async BuildContext diagnostics, 8 missing type annotations, 5 deprecations and 1 empty catch. Existing `analyze_out.txt` is stale and was not used as the current result.
- Flutter tests: cached `flutter_tools.snapshot test --no-pub`. **0 passed, 1 failed.** The test is the original “Counter increments smoke test”; it mounts `MyApp` without `ProviderScope`, raises `Bad state: No ProviderScope found`, and expects counter UI that the app does not have. This proves the test suite is invalid, not that all application features fail.
- No new tests were added and no tests were changed for this analysis.
- Not executed: Android/iOS release compilation, UI/emulator/device testing, Deno typechecks (Deno is unavailable), SQL migration replay, live RLS/ACL tests, service configuration verification, or dependency advisory audit.

## Recommended sequence and acceptance criteria

1. **Secure the backend:** rotate the exposed REST credential, validate role protection and profile privacy, revoke inappropriate RPC access, retire unused payment endpoints. Acceptance: anonymous/member negative permission tests pass and no usable server credential remains in source.
2. **Make deployment reproducible:** capture the actual schema and complete migrations, fix CI dotenv generation/placeholders, enforce release signing, verify iOS push entitlements. Acceptance: a fresh environment boots and passes a signed-device smoke test.
3. **Fix core correctness:** midnight/resume refresh, actual tomorrow prayer data, Adhan/Iqamah notifications, recovery errors, profile mutation reporting, upcoming events, schedule null handling and Qibla lifecycle. Acceptance: targeted tests reproduce each failure and pass after its correction.
4. **Install a meaningful regression suite:** auth routing and recovery, member/admin authorization, pure prayer logic (midnight/Friday/DST/Adhan/Iqamah), event ordering/timezones, schedule clearing, imports, and notification delivery/idempotency. Add CI gates and remove the counter test.
5. **Consolidate and simplify:** one notification path, clear donation ownership/integration, shared time services, current onboarding docs, platform support declarations and accessibility checks.

The existing feature structure can be retained. Focused fixes and a reproducible backend are more valuable than a wholesale rewrite.
