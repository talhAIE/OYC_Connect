# OYC Connect — implemented features and current state

Reviewed **27 October 2026**, against the current working tree, including modified and untracked source. Version: **1.0.2+8**.

## Assessment

OYC Connect is a substantial Flutter community application for Our Youth Center / 1881 Musalla. It already implements the principal member experience and an in-app administration console. Most screens have real Supabase queries and mutations behind them. The strongest implemented areas are prayer information, community publishing, class scheduling, authentication, and administrative content management.

The project is beyond a UI prototype. However, implemented source is not the same as verified production behavior. Native payments require stronger server reconciliation, some date/session/error handling needs attention, and device-dependent behavior has not been exercised in this review. No overall completion percentage is assigned because no agreed product specification exists.

This review adds documentation only. Application code, credentials, database state, and deployment configuration were not intentionally changed. Flutter checks may refresh local tool/build metadata. No live accounts, payments, notifications, deployments, or production queries were performed. Historical live-service observations in existing documents were treated as historical claims, not current verification.

## Project and architecture

- **88 Dart files:** 64 handwritten and 24 generated, across eight feature folders: auth, home, prayer_times, community, classes, donation, profile, admin.
- **Flutter / Dart**, Material 3, Riverpod providers, GoRouter, and Freezed / JSON code generation.
- **Supabase:** authentication, Postgres tables, row-level security, realtime streams, Storage, Edge Functions, SQL triggers and cron.
- **External integrations:** OneSignal push, Stripe native Android checkout, Sentry error reporting, NTP time synchronization, AthanPlus prayer timetable import, location/compass and reverse geocoding, external browser donation flow.
- **Navigation:** five persistent branches — Home, Community, Donate on Android / Website elsewhere, Classes, Profile. Nested member settings and admin screens are defined in `oyc_connect/lib/core/router/router.dart`.
- **Backend data:** profiles, prayer_times, jummah_configurations, khateebs, events, announcements, classes, teachers, weekly_schedules, payments, prayer_notification_sent, and a private notification delivery ledger. Images use the `app_assets` Storage bucket.
- **Platforms:** Android, iOS, web, Windows, macOS and Linux folders exist. The feature implementation is mobile-oriented; platform folders alone do not demonstrate full cross-platform support. Push explicitly supports Android/iOS, and native checkout explicitly supports Android.

Typical flow: page → Riverpod provider/controller → repository → Supabase. Some screens/services call Supabase directly, including donation history, account deletion and Stripe history recording. Prayer, Jummah and khateeb data have stream implementations. Community and class screens primarily use one-time fetches with provider invalidation.

## Feature inventory

### 1. Authentication and account access — implemented

- Email/password registration collects full name and phone in signup metadata.
- Registration signs the user out afterward, requiring a subsequent login.
- Email/password login with loading/error states and friendly credential errors.
- Restored Supabase sessions drive navigation and notification identity synchronization.
- Protected app routes redirect unauthenticated users to Login.
- Forgot-password screen invokes the `request-password-reset` Edge Function.
- The function checks whether the email exists and requests a Supabase recovery email.
- Custom `oycconnect://reset-password` handling supports incoming and initial links; recovery sends users to Set New Password.
- New-password submission updates credentials and signs out afterward.
- Signed-in password changes reauthenticate using the old password.
- Logout is connected to Supabase authentication.
- A separate `web/reset-password.html` recovery page exists. The current mobile redirect constant uses the app scheme, so the browser page is a separate deployment/configuration path.

Limits: no social login, MFA or phone OTP flow was found. Phone collection does not establish phone verification. Recovery email delivery, allowed redirect settings, and native deep-link behavior were not tested against deployed services. Router and separate AppLinkHandler code overlap, adding maintenance complexity.

Evidence: `lib/features/auth/`, `lib/core/router/router.dart`, `supabase/functions/request-password-reset/index.ts`.

### 2. Home and daily prayers — implemented, with date-handling gaps

- Branded 1881 Musalla home screen.
- Melbourne timezone clock, with an NTP offset used by the home prayer clock/countdown.
- Daily Fajr, Dhuhr, Asr, Maghrib and Isha timetable and separate Iqamah fields.
- Next-prayer selection/countdown and Friday-aware Jummah presentation.
- Initial REST fetch plus realtime subscription to today's prayer row; Jummah configuration also has REST/stream access.
- Pull-to-refresh invalidates prayer/Jummah, community and class providers.
- Current-month prayer calendar highlights and initially scrolls to today.
- Home shortcut opens Qibla.

Limits: the prayer stream calculates its Melbourne date when it starts and does not automatically rotate at midnight. App-resume code refreshes profile/push state, not the prayer date. After the last prayer, the home countdown derives tomorrow's Fajr from today's time plus a day rather than loading tomorrow's row. Manual refresh mitigates some stale data but does not solve automatic rollover. Calendar month switching is not implemented.

Evidence: `lib/features/home/presentation/pages/home_page.dart`, `lib/features/prayer_times/presentation/providers/prayer_times_provider.dart`, `lib/features/prayer_times/presentation/pages/prayer_calendar_page.dart`.

### 3. Qibla — implemented, device validation outstanding

- Requests location permissions and reads current position.
- Reverse geocodes a locality label.
- Subscribes to compass/Qibla direction updates.
- Draws a custom compass interface, indicates alignment and provides haptic feedback.
- Shows a next-prayer name/time using the center's Melbourne timetable, even though the locality label comes from the device location.
- Includes loading, permission-denied and compass-error states.

Limits: it does not calculate a location-specific prayer timetable. If prayer data is missing, the screen starts with a hardcoded Fajar / 04:33 AM display. Permission logic groups `enabled && always || whileInUse`, so service-enabled status is not required for the while-in-use branch. Async permission/geocoding callbacks lack mounted checks. Sensor availability, disabled GPS, permanent denial, calibration, and leaving the screen during an async request need physical-device coverage.

Evidence: `lib/features/prayer_times/presentation/pages/qibla_page.dart`.

### 4. Jummah and khateebs — implemented with limited editing

- Reads Friday configuration containing Khutbah time, Jummah time, address and khateeb name.
- Home detail dialog displays Friday information and the configured speaker/address.
- Admins edit Khutbah time, address and selected khateeb.
- Admins can add and delete khateeb records, with a realtime list and selection flow.

Limits: the Jummah settings form preserves the existing `jummah_time`; it does not expose that field for editing. The form expects an existing configuration and does not create the first configuration. Khateeb renaming is not implemented, and the selected speaker is stored by name rather than a relational ID.

Evidence: `lib/features/admin/presentation/pages/jummah_settings_page.dart`, `manage_khateebs_page.dart`, `lib/features/prayer_times/data/repositories/khateeb_repository.dart`.

### 5. Community events and announcements — implemented

- Separate Events and Notices tabs.
- Event cards/details show title, description, date, time, location and image.
- Announcement cards/details show title, body, image and urgent emphasis.
- Image rendering has fallback presentation.
- Admin event creation, editing, deletion and detail viewing.
- Admin announcement creation, editing, deletion and urgent flag.
- Gallery image selection and upload to Supabase Storage; configured default images can be used.
- New event/announcement INSERT triggers can enqueue push notifications through the supplied SQL setup.

Limits: each list is capped at 50 records without pagination. Events are ordered oldest first without an upcoming-date filter, so old records can crowd out future events. Publishing edits does not trigger another creation notification. The event model/UI support `is_featured`, but the write map excludes that field and the editor does not provide a complete featured-event workflow. No RSVP, tickets, comments, chat, member posting or attendance was found.

Evidence: `lib/features/community/`, `lib/features/admin/presentation/pages/manage_events_page.dart`, `manage_announcements_page.dart`.

### 6. Classes, teachers and schedules — implemented

- Member view separates weekly activities and Qur'an classes.
- Schedules associate a weekday, class and optional teacher, with optional start/end times.
- Presentation supports the center's default between-Maghrib-and-Isha convention.
- Pull-to-refresh reloads both schedule categories.
- Admin class creation/edit/delete, including description.
- Admin teacher creation/edit/delete, including bio.
- Admin schedule creation/edit/delete, type selection, class/teacher assignment and time pickers.
- Multi-day schedule creation is supported in the admin dialog.
- Management links connect schedules to class and teacher screens.

Limits: this is a schedule publication system; student enrollment, attendance, progress tracking, fee collection, capacity limits and teacher accounts are not implemented. Schedule repository updates omit null values, preventing some previously set optional fields from being cleared. Class/teacher/schedule repositories sign out the user on selected expired-JWT errors before retrying, which can unexpectedly send members back to Login.

Evidence: `lib/features/classes/`, especially `schedule_repository.dart` and `manage_schedule_page.dart`.

### 7. Donations — implemented differently by platform, backend incomplete

**Android native flow:**

- Preset and custom AUD amounts, default AUD 50.
- UI/service validation: AUD 1–10,000, up to two decimal places.
- Supabase Edge Function creates a Stripe PaymentIntent.
- Stripe PaymentSheet supports cards and Google Pay configuration.
- Service requires a logged-in user and a public Stripe key.
- Duplicate checkout taps are blocked while paying.
- Cancellation allows retry; uncertain confirmation prevents immediate repeat payment.
- Retrieves the intent after checkout and attempts to save a successful payment record.
- Distinguishes a successful charge with failed history recording from a failed charge.

**iOS and other platforms:**

- Website screen opens the external donation website, with opening/error states.
- Bottom navigation reads Website instead of Donate.

**Admin:** donation history requests payments with donor name/email and date, plus manual refresh. An optional server-authenticated function can notify opted-in admins about donation records.

Limits: no verified Stripe webhook/reconciliation implementation was found. The supplied payment policy lets a member insert their own amount/status/intent ID, so the payment table is not an authoritative receipt ledger. `stripe-payment-intent` has `verify_jwt = false` in local config and no in-handler user authentication, per-user idempotency, or rate limit. The app's login check does not protect direct calls to that endpoint. Client/server amount rules differ: the server accepts any positive amount up to 10,000 and rounds minor units. External website donations have no demonstrated synchronization into the app's history.

The history query embeds `profiles:user_id(...)`, but the supplied payments schema declares `user_id` as a foreign key to `auth.users`, not `public.profiles`. Its required PostgREST relationship needs verification against the deployed schema. The history view also does not visibly distinguish pending/failed records or display the fetched currency.

Evidence: `lib/features/donation/`, `supabase/functions/stripe-payment-intent/index.ts`, `supabase/payments_setup.sql`, `lib/features/admin/presentation/pages/donation_history_page.dart`.

### 8. Profile and support — implemented

- Displays name/email, and an Admin Console entry for an admin profile.
- Personal information editor updates full name.
- Notification preference switch synchronizes native opt-in/out and persists the setting, with rollback on failure.
- Change password, logout and confirmed account deletion.
- Account deletion calls `delete_user`, whose supplied SQL deletes the caller's payments, profile and auth user.
- Help & Support sheet displays center contact information.

Limits: no email/phone/avatar editing was found. `updateName` stores failures through `AsyncValue.guard` instead of rethrowing, while the edit page shows success after awaiting it; a failed save can therefore look successful. Profile fetch errors are converted to null, which can hide operational problems. The push service has device-status and subscription-ID getters, but the Profile screen does not render them; existing documentation says that diagnostic card was removed at the user's request.

Evidence: `lib/features/profile/`, `supabase/setup_delete_user.sql`.

### 9. Notification pipeline — substantial implementation, deployment/device dependent

- Mobile-only OneSignal initialization and central auth/profile synchronization.
- Restored-session binding, logout, persistent opt-in/out, permission requests and serialized synchronization that discards stale queued work.
- Foreground notification suppression when preferences are disabled.
- Cold-start notification tap buffering until navigation is ready.
- Prayer/Jummah taps → Home; event taps → Events; notices → Notices; donation-type taps → admin donation history.
- SQL selects separate Adhan-minus-30-minute, Adhan-time and actual Iqamah-time alerts.
- Friday alerts can be selected even when no daily prayer row exists.
- Melbourne calendar/timezone handling, bounded two-minute catch-up, and atomic prayer deduplication.
- Private delivery ledger records queued/accepted/failed states, attempts, provider IDs and sanitized errors.
- Stable provider idempotency key, up to three attempts, expiry and transient-error retries.
- Latest preference migration resolves only opted-in profile aliases on every attempt, including retry; no-recipient and over-limit cases fail instead of broadcasting to everyone.
- Admin delivery screen reads a protected status RPC and explains that provider acceptance does not prove visible phone receipt.
- Server sender credentials use Vault/environment, with restricted SQL execution and exact server-credential checks on optional Edge senders.
- iOS development/production APNs entitlement files and remote-notification background configuration exist.

Limits: SQL prerequisites, migration order, extensions, Vault secrets, cron and trigger installation must match the deployed service. Earlier setup scripts and newer migrations coexist; inspect final applied definitions, not just filenames. Historical deployment notes report some checks, but this review did not independently recheck those services. No notification inbox, per-category preference settings, or admin compose/send screen was found. Optional donation sender does not use the same durable ledger and lacks the donation routing metadata used by the client, so that path is less integrated. iPhone signing/APNs and Android/iPhone foreground/background/terminated delivery require device testing.

Evidence: `lib/core/notifications/push_notification_service.dart`, `lib/main.dart`, `supabase/migrations/20261024010000_restrict_notification_senders.sql`, `20261024020000_notification_delivery_pipeline.sql`, `20261024030000_enforce_notification_preferences.sql`.

### 10. Admin access and security support — implemented in source

- Route and profile checks restrict the in-app admin console.
- Admin management covers prayers, events, announcements, Jummah, khateebs, schedules, classes, teachers, donation history and notification delivery.
- Profile-role migration fixes member role assignment at signup, limits profile reads to self/admin, limits normal updates to name/preferences, and protects role changes with privileges, policies and a trigger.
- Role assignment RPC is reserved for trusted server code. There is no in-app user/role management console.
- Notification migrations restrict direct and indirect sending and protect content mutations with admin policies.
- Client environment validation rejects known private credential names, private key prefixes and service-role JWTs.
- Secret scanning covers current source/client environment assets, with optional reachable Git history checks.
- GitHub workflow runs scanner tests and source/history scans.

These are repository protections, not proof that every production migration has been applied or that previously exposed credentials have been revoked.

## Builds, configuration and operational state

- `pubspec.yaml` declares `assets/.env`; it is intentionally excluded from version control and an example exists. Fresh checkouts need a local/generated public client environment file. The bootstrap tolerates a load failure, but Supabase still requires its URL/key.
- Codemagic now validates and writes the public Supabase/OneSignal configuration and runs the credential scanner before building an IPA. This supersedes the older review's missing-Supabase-variable finding.
- Codemagic's Apple app ID and notification recipient still contain placeholders.
- Android has release signing support, code/resource shrinking and a FlutterFragmentActivity for native Stripe. If signing configuration is absent, the build script falls back to debug signing.
- Sentry is initialized when configured; tracing is set to 1.0.
- The README remains a starter document and does not describe actual feature/configuration/deployment requirements.
- There are no broad app-test/analyzer CI gates in the supplied GitHub workflow; it is focused on credential checks. Codemagic builds but does not run the Flutter suite in its supplied script.

## Verification performed in this review

1. **Flutter static analysis:** 30 findings: **0 errors, 1 warning, 29 informational lints**. Exit code 1. Warning: unused `currency` in donation history. Most lints involve async BuildContext use, missing type annotations or deprecated APIs.
2. **Full Flutter tests:** **23 passed, 1 failed**. The failure is the obsolete `Counter increments smoke test` in `test/widget_test.dart`: it builds `MyApp` without ProviderScope and expects the starter counter UI. Passing tests cover environment validation, push state/routing, donation platform behavior, amount validation, repeated taps, cancellation, uncertain payment and history-save failure, using fakes rather than live providers.
3. **Node / embedded Postgres tests:** **43 passed, 0 failed**, via `node --test --test-concurrency=1` in `tools/profile-security`. Covers role escalation defenses, grants/RLS, sender authentication, notification timing and delivery/preference behavior. Network/Vault/provider behavior is stubbed; these are not live delivery tests.
4. **Credential scanner unit tests:** **4 passed**, after pointing TMP/TEMP to an authorized writable test directory. The first attempt had two environment-related failures because sandbox temp-folder Git initialization/cleanup was denied.
5. **Current source/client-asset credential scan:** no findings and no tracked environment files reported. Git history was not scanned in this review; this does not establish prior credential rotation or absence of historical exposure.

Normal Flutter launcher attempts stalled under the restricted SDK-cache access. Checks completed using the installed Flutter tool snapshot with SDK access. No APK/IPA/release build or physical-device test was performed in this review.

## Recommended next work, in order

1. **Make donation records trustworthy:** verified provider webhook/reconciliation, authenticated and bounded intent creation, server-owned payment status, and a valid donor relationship for the admin query.
2. **Fix prayer-day rollover:** one Melbourne business-date source, refresh on midnight/resume, and load actual tomorrow data for the next Fajr.
3. **Restore a reliable verification baseline:** replace the stale starter test with an initialized auth/navigation smoke test; add analyzer and meaningful app/backend tests to CI. Preserve the existing passing coverage.
4. **Test updated signed mobile builds:** login/recovery, permission denied/granted, Qibla sensors, controlled targeted push delivery, tap navigation and opt-outs; verify deployment prerequisites without all-member test broadcasts.
5. **Correct small functional gaps:** surface profile-save errors; allow clearing optional schedule fields; expose Jummah prayer-time editing if required; add event pagination/upcoming filtering.
6. **Finish release configuration/documentation:** actual store identifiers, signing validation, canonical SQL bootstrap/migration sequence, client environment instructions and an up-to-date README.

## Capabilities not found in the current implementation

Event registration/RSVP or ticketing; class enrollment/attendance/student progress; community chat or member-generated posts; recurring native donations; verified receipt/refund management; member donation-history screen; member directory or admin user-management interface; offline-first storage/synchronization; localization controls; theme switching; notification inbox/category controls; complete event search/pagination; calendar export. These are inventory observations, not assumed requirements.

