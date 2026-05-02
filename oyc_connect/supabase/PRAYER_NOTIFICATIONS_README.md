# Prayer & Jummah Notifications – Fix

## What was wrong

1. **Wrong OneSignal app**  
   The function that sends prayer/Jummah notifications used a **different OneSignal App ID** (`1841c7be-...`) than your Flutter app and events trigger (`4428e176-...`). Push was going to the other app, so devices never got prayer notifications.

2. **Time parsing**  
   The DB stores times like `"5:30 AM"` or `"12:15 PM"`. The old SQL used a single format and could fail silently, so no notification was sent.

3. **No deduplication**  
   The cron runs every minute. Without tracking, the same “30 min before” or “on time” notification could be sent many times. Now each slot is sent **once per day**.

## What the fix does

- **Same OneSignal app**  
  `send_onesignal_notification_manual` now uses the same app_id and API key as your events/announcements trigger (`4428e176-2a7f-4d7f-9c28-4ebec13b5001`).

- **Robust time parsing**  
  New helper `parse_prayer_time(text)` supports:
  - `"5:30 AM"` / `"12:15 PM"` (12h)
  - `"05:30"` / `"17:30"` (24h)

- **Deduplication**  
  Table `prayer_notification_sent` stores `(date, slot)` so we send:
  - **Once** “30 min before” per prayer per day (e.g. `fajr_30`, `dhuhr_30`, `jummah_30`).
  - **Once** “on time” per prayer per day (e.g. `fajr_on`, `dhuhr_on`, `jummah_on`).

- **Jummah**  
  On Fridays, Jummah times come from `jummah_configurations.khutbah_time`; 30 min before and on-time notifications are sent once per day.

## How to apply

1. In **Supabase Dashboard** → your project → **SQL Editor**.
2. Open `supabase/migrations/fix_prayer_jummah_notifications.sql` and copy its full contents.
3. Paste into a new query and click **Run**.
4. Ensure **pg_cron** (and **pg_net**) are enabled: **Database** → **Extensions** → enable `pg_cron` and `pg_net` if needed.

## Check that it works

1. **Prayer times for today**  
   In Table Editor, open `prayer_times` and confirm there is a row for **today’s date** with times like `5:30 AM`, `12:15 PM`, etc. (or 24h like `05:30`, `17:30`).

2. **Jummah (Fridays)**  
   In `jummah_configurations`, ensure `khutbah_time` is set (e.g. `1:00 PM`).

3. **OneSignal**  
   In your Flutter app, the OneSignal App ID must be **4428e176-2a7f-4d7f-9c28-4ebec13b5001** (same as in the SQL). Check `lib/main.dart`:  
   `OneSignal.initialize("4428e176-2a7f-4d7f-9c28-4ebec13b5001");`

4. **Test parsing (optional)**  
   In SQL Editor run:
   ```sql
   select public.parse_prayer_time('5:30 AM') as t1,
          public.parse_prayer_time('12:15 PM') as t2,
          public.parse_prayer_time('17:30') as t3;
   ```
   You should see three time values.

5. **Cron**  
   Cron runs every minute. To see if the job is there:
   ```sql
   select * from cron.job where command like '%check_prayer_times%';
   ```

6. **Sent log**  
   After a notification is sent, you’ll see a row in `prayer_notification_sent` for that date and slot (e.g. `fajr_30`, `dhuhr_on`).

## If you use a different OneSignal app

If your **client** uses a different OneSignal App ID and REST API key, change them in the SQL **before** running:

- In `send_onesignal_notification_manual`: set `os_app_id` and `os_api_key` to that client’s values.
- Keep them the same as in your Flutter app and events trigger so prayer, events, and announcements all go to the same app.
