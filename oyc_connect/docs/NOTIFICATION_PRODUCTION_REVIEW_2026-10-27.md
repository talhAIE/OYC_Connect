# Notification production review — 27 October 2026

## Fixes implemented

- Namaz/prayer and Jummah taps open Home/dashboard. All community types, including events, open Community → Notices.
- Pending tap destinations survive startup checks and normal login. Password recovery remains protected.
- Notices uses a query parameter and a fresh page key. A repeated tap reopens Notices even after the member manually switched the cached page to Events.
- Taps refresh prayer/Jummah/community data. Older untyped prayer messages have a limited title-based fallback; explicitly typed announcements about prayer still open Notices.
- Reloading a profile preserves the same account's last confirmed notification preference instead of briefly opting out. Switching accounts cannot inherit the previous account's preference.
- Recovery sessions do not bind OneSignal as ordinary app logins.
- Release tasks require release signing configuration instead of silently using debug signing.

## Live backend checks

Read-only checks of the linked OYC backend on 27 October 2026 established:

- pg_cron, pg_net and Vault are installed. Prayer cron runs every minute; its five most recent checked runs succeeded.
- Today's prayer row and one Jummah configuration exist.
- 100 profiles have notifications enabled. The sender uses preference-aware account aliases with no country restriction.
- Checked privileged sender functions have zero execute grants for ordinary API clients.
- Events and announcements have enabled INSERT notification triggers.
- 15 prayer requests in the preceding 24 hours were accepted by OneSignal. This is provider acceptance, not proof of visible receipt on each phone.
- The second check found no pending provider requests. All seven-day delivery payloads had a notification type. The latest community delivery record was 24 October.
- Production Vault and the release client use the same public OneSignal app ID. Firebase's Android package matches the app.

No notifications were sent, no community content was published, and no production schema/data was changed. `supabase/tests/notification_production_health.sql` provides a repeatable aggregate check without returning secrets, push tokens, member identities or message bodies.

## Worldwide delivery and manual timetables

Recipients are selected by opted-in account alias, wherever their supported mobile subscriptions are located. There is no Australian-only country filter. Users must open the app, sign in, grant permission and enable notifications; installation alone does not establish a reachable subscription.

Prayer and Jummah alerts follow the **1881 Musalla Melbourne timetable**, including Melbourne daylight saving. Overseas recipients receive the center's alert at the corresponding instant in their timezone. Per-city prayer calculations and matching local wall-clock alerts worldwide are not implemented.

**Timetable synchronization remains manual by the admin**, as requested. Prayer rows currently extend through **31 October 2026**. Import November before that coverage ends; the existing scheduler will then consume those rows without a code release or scheduler change. Jummah uses its separate configuration and can run without a daily prayer row.

Prayer pushes intentionally have a short TTL to prevent stale prayer alerts after long offline periods. Community pushes use a longer TTL. The present sender supports up to 20,000 opted-in aliases per request and fails visibly beyond that cap; batching must be added before reaching that audience size. Current audience: 100.

Permission, notification channels, Focus/Do Not Disturb, battery restrictions, Android Force Stop and connectivity to FCM/APNs can prevent or delay delivery. No verified Huawei-specific credential/configuration path is present. An AAB cannot guarantee receipt on every device or network worldwide.

References: [Flutter setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup), [delivery troubleshooting](https://documentation.onesignal.com/docs/en/notifications-show-successful-but-are-not-being-shown), [alias targeting limits](https://documentation.onesignal.com/reference/create-message), [Huawei setup](https://documentation.onesignal.com/docs/en/huawei-sdk-setup).

## Verification and artifact

- **51 targeted Flutter tests passed**, including actual-router widget coverage of cold startup, login continuation, repeated Notices opening, prayer/Jummah navigation and recovery isolation.
- **43 backend/security tests passed**, covering prayer/Friday/DST selection, opt-outs, retries, atomic deduplication and sender authorization with a stubbed provider.
- Static analysis of changed notification/routing/main Dart files and related tests: no issues.
- Current-source/client-asset credential scan: no findings.
- **Signed, optimized release AAB built successfully**, with arm64-v8a, armeabi-v7a and x86_64.
- Signature verified; signer is not Android Debug. Release manifest contains the push/internet/boot permissions and OneSignal FCM receiver.
- Artifact: `build/app/outputs/bundle/release/app-release.aab`, 73.2 MiB. Not uploaded to Play. Version/build number unchanged.

The first simultaneous build/test attempt exhausted host memory. Tests subsequently passed with one worker; a standalone release build then succeeded.

## Physical-device validation still required

Install the new release through Play internal testing. Use a notification targeted only to a controlled subscription to verify foreground/background/terminated delivery, Home versus Notices routing, repeated taps and opt-out/re-enable. No all-member test was sent. A signed iPhone/TestFlight build and APNs device test are separate; Windows build verification does not establish iOS receipt.
