# OYC Connect – Notification Workflows (Complete Logic)

This document describes **how every notification is sent** in your app: from trigger to device.

---

## Overview

All push notifications go through **OneSignal**. Your app uses:

| Source | Who gets it | How it’s triggered |
|--------|-------------|---------------------|
| **Prayer times & Jummah** | All users | pg_cron every minute → SQL function → OneSignal API |
| **Events** | All users | DB trigger on `events` INSERT → OneSignal API |
| **Announcements** | All users | DB trigger on `announcements` INSERT → OneSignal API |
| **Donations** | Admins only | DB trigger on `payments` INSERT → Edge Function → OneSignal API (by user id) |

---

## 1. How devices receive notifications (Flutter + OneSignal)

1. **App start**  
   `main.dart` calls `OneSignal.initialize("4428e176-...")` and `OneSignal.Notifications.requestPermission(true)`.

2. **Registration**  
   OneSignal SDK registers the device with your OneSignal app and subscribes it to the “All” segment (or segments you define).

3. **Login**  
   When the user signs in, `AuthController` / `AuthRepository` calls `OneSignal.login(userId)`. OneSignal links this device to that user’s **external_id** (Supabase user id). That is how “admin-only” notifications can target specific users.

4. **Delivery**  
   When your backend calls the OneSignal API (see below), OneSignal delivers the push to:
   - **Segment “All”** → all subscribed devices for that app, or  
   - **Include aliases (external_id)** → only devices that called `OneSignal.login(that_id)`.

So: **backend decides what to send and to whom; OneSignal delivers to the right devices.**

---

## 2. Prayer times & Jummah notifications

**Goal:** Send “30 min before Adhan” and “Iqamah now” for each prayer (and Jummah on Friday), **once per day per slot**, at the **exact minute** (no 1–2 s drift).

### Flow (step by step)

```
pg_cron (every minute)
    → check_prayer_times()
    → for each prayer (and Jummah on Friday):
        → if “30 min before” minute and first 10s of that minute:
            → try_send_prayer_notification(..., slot e.g. 'fajr_30')
        → if “on time” minute and first 10s of that minute:
            → try_send_prayer_notification(..., slot e.g. 'fajr_on')
    → try_send_prayer_notification():
        → if (notify_date, slot) already in prayer_notification_sent → skip
        → send_onesignal_notification_manual(title, body)
        → insert (notify_date, slot) into prayer_notification_sent
    → send_onesignal_notification_manual(title, body):
        → pg_net: HTTP POST to OneSignal API
        → body: app_id, headings.en=title, contents.en=body, included_segments=["All"]
```

### Where it lives

- **Schedule:** `cron.schedule('prayer-check-job', '* * * * *', 'select public.check_prayer_times()')`  
  → runs every minute.
- **Logic:** `public.check_prayer_times()` in `fix_prayer_jummah_notifications.sql`:
  - Reads **current time** in `Australia/Melbourne`.
  - Loads **today’s row** from `prayer_times`.
  - For Fajr, Dhuhr, Asr, Maghrib, Isha:
    - Parses time from DB with `parse_prayer_time()` (supports "5:30 AM", "12:15 PM", "17:30").
    - **30 min before:** only if current minute = (prayer_time − 30 min) and `second < 10`.
    - **On time:** only if current minute = prayer_time and `second < 10`.
  - On **Friday**, same for Jummah using `jummah_configurations.khutbah_time`.
- **Deduplication:** `try_send_prayer_notification` checks/inserts `prayer_notification_sent(notify_date, slot)` so each slot is sent at most once per day.
- **Sending:** `send_onesignal_notification_manual(title, body)` uses **pg_net** to POST to `https://onesignal.com/api/v1/notifications` with your app_id and REST API key; `included_segments: ["All"]` so **all app users** get it.

So: **cron → exact-minute + first-10s check → dedup table → OneSignal API → all users.**

---

## 3. Events notifications

**Goal:** When an admin inserts a row into `events`, every user gets a push.

### Flow

```
Admin (or app) INSERT into public.events
    → AFTER INSERT trigger: trigger_notify_event
    → send_onesignal_notification() (trigger function)
        → TG_NAME = 'trigger_notify_event'
        → title = 'New Event: ' || NEW.title
        → body = 'Check the app for details.' (or similar)
        → pg_net: HTTP POST to OneSignal API, included_segments: ["All"]
```

### Where it lives

- **Trigger:** `trigger_notify_event` on `public.events`, calls `public.send_onesignal_notification()` (from `sql_deploy_onesignal.sql` or your deployed version).
- **Sending:** Same OneSignal app_id and API key; segment **All** → all users.

So: **INSERT events → trigger → OneSignal API → all users.**

---

## 4. Announcements notifications

**Goal:** When an admin inserts a row into `announcements`, every user gets a push.

### Flow

```
Admin (or app) INSERT into public.announcements
    → AFTER INSERT trigger: trigger_notify_announcement
    → send_onesignal_notification() (trigger function)
        → TG_NAME = 'trigger_notify_announcement'
        → title = NEW.title, body = NEW.body
        → pg_net: HTTP POST to OneSignal API, included_segments: ["All"]
```

### Where it lives

- **Trigger:** `trigger_notify_announcement` on `public.announcements`, same `send_onesignal_notification()`.
- **Sending:** OneSignal with segment **All** → all users.

So: **INSERT announcements → trigger → OneSignal API → all users.**

---

## 5. Donation notifications (admins only)

**Goal:** When someone donates (INSERT into `payments`), only **admins** get a push with donor and amount.

### Flow

```
User completes payment → app/server INSERT into public.payments
    → AFTER INSERT trigger: on_new_donation
    → handle_new_donation() (trigger function)
        → pg_net: HTTP POST to Supabase Edge Function:
            URL = project’s /functions/v1/notify-admins
            body = { record: NEW row }
    → Edge Function: notify-admins (Deno)
        → Reads record (payment row).
        → Gets donor name from profiles (if user_id set).
        → Selects all profiles where role = 'admin' → list of admin user ids.
        → OneSignal API: POST with include_aliases.external_id = admin ids
            (so only devices that did OneSignal.login(admin_id) get it)
        → title/body e.g. "New Donation", "Talha just donated $50 AUD"
```

### Where it lives

- **Trigger:** `on_new_donation` on `public.payments`, calls `public.handle_new_donation()` (in `notifications_trigger.sql`).  
  **Note:** The URL in that file is hardcoded to one project; for another project you must change it to that project’s `/functions/v1/notify-admins`.
- **Edge Function:** `supabase/functions/notify-admins/index.ts` – uses OneSignal **REST API** with `include_aliases: { external_id: adminIds }` so only admins receive it.

So: **INSERT payments → trigger → HTTP to notify-admins → OneSignal by external_id → admins only.**

---

## 6. End-to-end: from “event” to device

1. **Something happens:**  
   Time hits prayer minute, or INSERT into `events` / `announcements` / `payments`.

2. **Your backend decides:**  
   - Prayer/Jummah: `check_prayer_times()` (cron).  
   - Events/Announcements: DB trigger `send_onesignal_notification()`.  
   - Donations: DB trigger → Edge Function `notify-admins`.

3. **Backend calls OneSignal:**  
   - Prayer, events, announcements: POST to `https://onesignal.com/api/v1/notifications` with `app_id`, `headings`, `contents`, and either `included_segments: ["All"]` or (donations) `include_aliases: { external_id: [...] }`.

4. **OneSignal delivers:**  
   - Segments → all subscribed devices for that app (or the segment).  
   - Aliases (external_id) → only devices that called `OneSignal.login(that_id)`.

5. **Device shows the notification** using the OS (FCM on Android, APNs on iOS, etc.), which OneSignal talks to.

---

## 7. Summary table

| Notification type      | Triggered by              | Who sends to OneSignal        | OneSignal target   |
|------------------------|---------------------------|--------------------------------|--------------------|
| Prayer 30 min before   | pg_cron every minute      | `check_prayer_times` → `send_onesignal_notification_manual` | Segment “All”      |
| Prayer on time (Iqamah)| pg_cron every minute      | Same                           | Segment “All”      |
| Jummah 30 min / on time | pg_cron (Friday only)    | Same                           | Segment “All”      |
| New event              | INSERT `events`           | Trigger `send_onesignal_notification` | Segment “All”      |
| New announcement       | INSERT `announcements`    | Same trigger                   | Segment “All”      |
| New donation           | INSERT `payments`         | Trigger → Edge Function `notify-admins` | Admins (external_id) |

All use the **same OneSignal app** (4428e176-...) so the Flutter app (which initializes that app_id) receives every push that targets “All” or its logged-in user id.
