# iOS Push Notifications Setup Guide — OYC Connect

Complete step-by-step guide to set up push notifications on iOS using OneSignal.

---

## What's Already Done ✅

Your Flutter code is **fully ready** — no code changes needed:

| Component | Status | Where |
|---|---|---|
| OneSignal SDK init | ✅ | `main.dart` — `OneSignal.initialize()` + `requestPermission()` |
| User login/logout | ✅ | `auth_repository.dart` — `OneSignal.login(userId)` / `OneSignal.logout()` |
| Opt-in/out toggle | ✅ | `profile_provider.dart` — `pushSubscription.optIn()` / `optOut()` |
| Background mode | ✅ | `Info.plist` — `remote-notification` in `UIBackgroundModes` |
| Server-side push | ✅ | `notify-admins` + `notify_broadcast` Edge Functions |
| `.env` config | ✅ | `ONESIGNAL_APP_ID` already configured |

**All you need to do is configure the Apple side + OneSignal Dashboard.**

---

## Step 1: Create an APNs Key (Apple Push Notification service)

This is the key that lets OneSignal send notifications to iPhones.

1. Go to **[Apple Developer Console](https://developer.apple.com/account)**
2. Sign in with your **Apple Developer Account** ($99/year program)
3. Navigate to: **Certificates, Identifiers & Profiles** → **Keys**
4. Click the **+** button to create a new key
5. Fill in:
   - **Key Name**: `OYC Connect Push Key`
   - ✅ Check **Apple Push Notifications service (APNs)**
6. Click **Continue** → **Register**
7. **IMPORTANT**: Download the `.p8` file immediately — **Apple only lets you download it ONCE**
8. Note down:
   - **Key ID** (shown on the page, e.g., `ABC123DEFG`)
   - **Team ID** (found at top-right of the developer portal, or in Membership page)

> ⚠️ Save the `.p8` file somewhere safe. If you lose it, you'll have to create a new key.

---

## Step 2: Register Your App ID with Push Notifications

1. In **Apple Developer Console** → **Certificates, Identifiers & Profiles** → **Identifiers**
2. Find or create your App ID: `com.ouryouthcenter1881.oycconnect`
3. Click on it → scroll to **Push Notifications**
4. Make sure it's ✅ **Enabled**
5. Click **Save**

---

## Step 3: Configure OneSignal Dashboard

1. Go to **[OneSignal Dashboard](https://app.onesignal.com)** → Your OYC Connect App
2. Navigate to: **Settings** → **Platforms** → **Apple iOS (APNs)**
3. Select **".p8" Authentication Token (Recommended)**
4. Upload/fill in:

| Field | Value |
|---|---|
| **APNs Authentication Key (.p8)** | Upload the `.p8` file from Step 1 |
| **Key ID** | The Key ID from Step 1 (e.g., `ABC123DEFG`) |
| **Team ID** | Your Apple Team ID |
| **Bundle ID** | `com.ouryouthcenter1881.oycconnect` |

5. Click **Save**

---

## Step 4: Add Push Notification Capability in Xcode

On your **Mac**, open the project in Xcode:

```bash
cd oyc_connect/ios
open Runner.xcworkspace
```

Then:

1. Click **Runner** in the left sidebar
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** (top-left)
5. Add these two capabilities:

| Capability | Purpose |
|---|---|
| **Push Notifications** | Enables the app to receive push notifications |
| **Background Modes** | Already in Info.plist, but must also be enabled in Xcode |

6. Under **Background Modes**, ensure ✅ **Remote notifications** is checked

> This step generates the proper entitlements file that iOS requires.

---

## Step 5: Install CocoaPods Dependencies

```bash
cd oyc_connect

# Get Flutter dependencies
flutter pub get

# Install iOS pods (OneSignal has native iOS dependencies)
cd ios
pod install
cd ..
```

If `pod install` fails, try:
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

---

## Step 6: Build & Test

### Test on Physical iPhone (Recommended)

Push notifications **do NOT work on the iOS Simulator**. You must test on a real device.

```bash
# Connect your iPhone via USB, then:
flutter run -d <your-iphone-device-id>

# Or just:
flutter run
```

When the app launches:
1. You should see the **"Allow Notifications"** prompt (from `OneSignal.Notifications.requestPermission(true)` in `main.dart`)
2. Tap **Allow**
3. Log in to the app (this calls `OneSignal.login(userId)`)

### Verify in OneSignal Dashboard

1. Go to **OneSignal Dashboard** → **Audience** → **All Users**
2. You should see your device listed with platform = **iOS**
3. The **External User ID** should match your Supabase user ID

### Send a Test Notification

1. In OneSignal Dashboard → **Messages** → **Push** → **New Push**
2. Audience: **Send to All Subscribers** (or filter to your test device)
3. Title: `Test Notification`
4. Message: `Hello from OYC Connect!`
5. Click **Send**
6. Your iPhone should receive the notification 🎉

---

## Step 7: Verify All Notification Workflows

Your app has 3 notification triggers — verify each one:

### 1. Prayer Time Notifications
- **Trigger**: `pg_cron` checks every minute via `check_prayer_times()` in PostgreSQL
- **Sends**: 30 min before prayer + at prayer time
- **Target**: All subscribers (`included_segments: All`)
- **Test**: Wait for a prayer time, or temporarily modify a prayer time in Supabase to be a few minutes from now

### 2. Community Notifications (Events/Announcements)
- **Trigger**: Supabase DB Webhook on INSERT into `events` or `announcements` table
- **Calls**: `notify_broadcast` Edge Function
- **Target**: All subscribers
- **Test**: Create a new event or announcement in the admin panel

### 3. Donation Notifications (Admin-only)
- **Trigger**: Supabase DB Webhook on INSERT into `payments` table
- **Calls**: `notify-admins` Edge Function
- **Target**: Only admin users (by `external_id`)
- **Test**: Make a test donation through the app

---

## Troubleshooting

| Issue | Fix |
|---|---|
| **No notification prompt on launch** | Check `ONESIGNAL_APP_ID` in `.env` is correct |
| **Device not showing in OneSignal** | Make sure you tapped "Allow" on the permission prompt. Check that `OneSignal.login()` was called after sign-in |
| **Notifications not arriving** | Verify APNs key is correctly uploaded in OneSignal Dashboard. Check Key ID and Team ID match |
| **"No valid 'aps-environment' entitlement"** | You forgot Step 4 — add Push Notifications capability in Xcode |
| **`pod install` fails** | Run `sudo gem install cocoapods` then `pod install --repo-update` |
| **Notifications work in debug but not release** | Make sure the APNs key is for **Production** (`.p8` keys work for both sandbox and production) |

---

## Summary Checklist

| # | Task | Status |
|---|---|---|
| 1 | Create APNs Key (.p8) in Apple Developer Console | ⬜ |
| 2 | Enable Push Notifications on App ID | ⬜ |
| 3 | Upload .p8 key to OneSignal Dashboard | ⬜ |
| 4 | Add Push Notifications capability in Xcode | ⬜ |
| 5 | `pod install` to get native dependencies | ⬜ |
| 6 | Build & run on physical iPhone | ⬜ |
| 7 | Verify "Allow Notifications" prompt appears | ⬜ |
| 8 | Verify device shows in OneSignal Dashboard | ⬜ |
| 9 | Send test notification from OneSignal | ⬜ |
| 10 | Test prayer / community / donation notifications | ⬜ |
