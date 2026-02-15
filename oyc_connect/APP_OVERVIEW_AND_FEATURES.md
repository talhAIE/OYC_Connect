# OYC Connect – Complete App Overview & Feature Analysis

This document provides a full analysis of the **OYC Connect** Flutter app: what it is, how it’s built, and what each part does.

---

## 1. What the app is

**OYC Connect** is a **community and mosque companion app** for **1881 Musalla** (Mickleham, VIC, Australia). It helps users:

- See **prayer times** (Adhan & Iqamah) and **Jummah** details
- Browse **events** and **announcements**
- **Donate** via Stripe (Apple Pay / card)
- View **weekly and Qur’an class schedules**
- Manage **profile**, notifications, and password

**Admins** (users with `role == 'admin'` in `profiles`) get an **Admin Console** to manage prayer times, events, announcements, Jummah settings, classes, teachers, khateebs, and donation history.

**Tagline (from login):** *"Your spiritual journey, digitized."*

---

## 2. Tech stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter (Dart SDK ^3.10.7) |
| **State** | Riverpod (flutter_riverpod, riverpod_annotation, riverpod_generator) |
| **Routing** | go_router (StatefulShellRoute for bottom nav) |
| **Backend** | Supabase (Auth, Postgres, Realtime, Storage, Edge Functions) |
| **Payments** | Stripe via flutter_stripe + Supabase Edge Function `stripe-payment-intent` |
| **Push** | OneSignal (onesignal_flutter) |
| **Models** | freezed + json_serializable |
| **Env** | flutter_dotenv (assets/.env for Stripe key; Supabase/OneSignal still in code) |
| **Time** | timezone, intl, ntp (Melbourne TZ, NTP sync for clock) |
| **UI** | Material 3, custom palette (app_theme.dart, app_pallete.dart) |

---

## 3. Project structure (lib/)

```
lib/
├── main.dart                          # Entry: Supabase, Stripe, OneSignal, tz, router
├── core/
│   ├── constants/
│   │   └── supabase_constants.dart     # Supabase URL/anon key, default image URLs
│   ├── presentation/
│   │   └── main_scaffold.dart         # Bottom nav shell (Home, Community, Donate, Classes, Profile)
│   ├── router/
│   │   └── router.dart                # GoRouter, auth redirect, all routes + admin sub-routes
│   ├── theme/
│   │   ├── app_pallete.dart
│   │   └── app_theme.dart
│   └── utils/
│       └── snackbar_utils.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart   # signUp, signIn, signOut, OneSignal login/logout
│   │   ├── presentation/
│   │   │   ├── pages/                 # login_page, register_page
│   │   │   ├── providers/             # auth_provider (authController, authState)
│   │   │   └── widgets/               # auth_wrapper, auth_button, custom_field
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_page.dart     # Prayer card, next prayer countdown, today's times, Jummah row
│   │       └── widgets/
│   │           └── jummah_detail_dialog.dart
│   ├── prayer_times/
│   │   ├── data/
│   │   │   ├── models/                # prayer_time_model, jummah_config, khateeb_model
│   │   │   └── repositories/          # prayer_times_repository, jummah_repository, khateeb_repository
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── prayer_calendar_page.dart  # Monthly list, scroll to today
│   │       └── providers/
│   │           └── prayer_times_provider.dart # todayPrayerTime (stream), jummahConfig (stream)
│   ├── community/
│   │   ├── data/
│   │   │   ├── models/                # event_model, announcement_model
│   │   │   └── repositories/
│   │   │       └── community_repository.dart # events, announcements CRUD + image upload
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── community_page.dart       # Tabs: Events | Notices (announcements)
│   │       └── providers/
│   │           └── community_providers.dart  # eventsProvider, announcementsProvider
│   ├── donation/
│   │   ├── presentation/
│   │   │   └── pages/
│   │   │       └── donation_page.dart # Amount chips + custom, Stripe payment sheet
│   │   └── services/
│   │       └── stripe_service.dart   # createPaymentIntent, presentPaymentSheet, save to payments
│   ├── classes/
│   │   ├── data/
│   │   │   ├── models/                # class_model, teacher_model, weekly_schedule_model
│   │   │   └── repositories/           # classes_repository, teachers_repository, schedule_repository
│   │   └── presentation/
│   │       ├── pages/                 # classes_schedule_page, manage_schedule_page,
│   │       │                          # manage_classes_page, manage_teachers_page
│   │       └── providers/
│   │           └── classes_providers.dart     # weeklySchedulesProvider, quranSchedulesProvider
│   ├── profile/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── profile_model.dart # id, fullName, email, role, notificationsEnabled
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   └── presentation/
│   │       ├── pages/                 # profile_page, edit_profile_page, change_password_page
│   │       └── providers/
│   │           └── profile_provider.dart
│   └── admin/
│       └── presentation/
│           ├── pages/
│           │   ├── admin_dashboard_page.dart  # Tiles to each manage page
│           │   ├── manage_prayer_times_page.dart
│           │   ├── manage_events_page.dart
│           │   ├── manage_announcements_page.dart
│           │   ├── jummah_settings_page.dart
│           │   ├── donation_history_page.dart
│           │   ├── manage_khateebs_page.dart
│           │   └── (schedule/classes/teachers via classes feature)
│           └── (no separate admin data layer; uses community, prayer_times, classes repos)
```

---

## 4. Features (by area)

### 4.1 Authentication

- **Login:** Email + password; Supabase Auth; success snackbar; router redirects to `/home`.
- **Register:** Full name, email, phone, password, confirm password; creates user + profile; redirects to `/login`.
- **Auth flow:** `AuthWrapper` at `/` reads auth state; if session exists → `/home`, else → `/login`. Router `redirect` also sends unauthenticated users to `/login` and authenticated from `/login` or `/register` to `/home`.
- **OneSignal:** `OneSignal.login(userId)` on sign-in/sign-up, `OneSignal.logout()` on sign-out (in AuthRepository).
- **Note:** Forgot password is not implemented (TODO in login_page). Admin routes are not guarded by role (any logged-in user can open `/profile/admin`).

### 4.2 Home

- **Header:** “1881 MUSALLA” with mosque icon.
- **Next prayer card:** Shows next prayer (or Iqamah) name, time, and countdown; Melbourne time with NTP offset; “CALENDAR” button → `/home/prayer-calendar`.
- **Today’s times list:** Fajr, Dhuhr/Jummah (Friday), Asr, Maghrib, Isha with Adhan and Iqamah; current prayer highlighted.
- **Jummah (Friday):** Special row; tap opens `JummahDetailDialog` (khutbah time, khateeb, address, reminders).
- **Pull-to-refresh:** Invalidates prayer times, jummah config, events, announcements, and class schedules.

### 4.3 Prayer times & calendar

- **Data:** `prayer_times` table (per-day: fajr, dhuhr, asr, maghrib, isha + iqama fields; optional jumuah); `jummah_configurations` (khutbah_time, jummah_time, address, khateeb_name). Realtime subscriptions for today’s prayer times and jummah config.
- **Home:** Uses `todayPrayerTimeProvider` (stream) and `jummahConfigProvider` (stream).
- **Prayer calendar:** `/home/prayer-calendar` – current month list via `monthlyPrayerTimesProvider`; scrollable list with “today” highlighted; each card shows Fajr, Dhuhr, Asr, Maghrib, Isha, Jumuah (if Friday).
- **Timezone:** Australia/Melbourne; NTP used for clock on home.

### 4.4 Community (Discover Hub)

- **Tabs:** “EVENTS” and “NOTICES” (announcements).
- **Events:** List from `events` table; cards with image (or default), title, date, time; tap → dialog with full description and image. Optional `is_featured` badge.
- **Notices:** List from `announcements` table; cards with title, date, content preview; optional `is_urgent` and image; tap → “VIEW DETAIL” dialog with full content and image.
- **Images:** Events and announcements can have `image_url`; uploads go to Supabase Storage bucket `app_assets`; default images from `SupabaseConstants`.

### 4.5 Donate

- **Amount:** Preset chips ($20, $50, $100) or custom amount.
- **Payment:** Stripe Payment Sheet (Apple Pay / card). Flow: Edge Function `stripe-payment-intent` → client secret → `Stripe.instance.initPaymentSheet` → `presentPaymentSheet` → on success, insert into `payments` (user_id, amount, currency, status, payment_intent_id).
- **Success:** “Jazak Allah Khair!” dialog; form reset. Failure/cancel: snackbar.

### 4.6 Classes

- **Public schedule:** `/classes` – “Weekly Classes” and “Qur’an Classes” sections; data from schedule repository (joined class + teacher); grouped by class/teacher/time with days (e.g. “Mon–Wed”, “Tue & Thu”); note: “Between Maghrib & Isha unless stated.”
- **Data:** `classes`, `teachers`, `schedules` (e.g. weekly_schedule with day_of_week, class_id, teacher_id, start_time, end_time, schedule_type).

### 4.7 Profile

- **Display:** User card (avatar initial, full name, email) from `profileProvider` (profiles table).
- **Admin:** If `profile.role == 'admin'`, “Admin Console” tile → `/profile/admin`.
- **Settings:** Personal Information → `/profile/edit` (update full name); Notifications toggle (notifications_enabled); Change Password → `/profile/change-password`; Help & Support (bottom sheet with address “1881 Mickleham Rd, Mickleham VIC 3064” and email “ouryouthcenter1881@gmail.com”).
- **Sign out:** Calls `AuthRepository.signOut()`; router/auth state sends user to login.

### 4.8 Admin console

- **Entry:** Profile → Admin Console → `AdminDashboardPage` with tiles:
  - Manage Prayer Times
  - Manage Events
  - Manage Announcements
  - Manage Jummah Settings
  - Manage Weekly Classes (→ schedule page with Manage Classes / Manage Teachers)
  - Donation History
- **Khateebs:** Route `/profile/admin/khateebs` exists and is implemented (`ManageKhateebsPage`), but there is **no tile** for it on the admin dashboard (user must navigate manually or add a tile).
- **Typical admin actions:** CRUD for events (with image upload), announcements (with image), prayer times, jummah config, classes, teachers, schedules, khateebs; view donation history.

---

## 5. Data models & backend (summary)

| Table / Concept | Purpose |
|-----------------|--------|
| **Supabase Auth** | Users (email, password; user_metadata: full_name, phone) |
| **profiles** | id, full_name, email, role, notifications_enabled (synced with auth) |
| **prayer_times** | Per-day rows: date, fajr, dhuhr, asr, maghrib, isha + iqama fields, jumuah |
| **jummah_configurations** | khutbah_time, jummah_time, address, khateeb_name |
| **events** | title, description, event_date, location, image_url, is_featured |
| **announcements** | title, body (content), created_at, is_urgent, image_url |
| **payments** | user_id, amount, currency, status, payment_intent_id |
| **classes** | Class names/categories |
| **teachers** | Teacher names |
| **schedules** | day_of_week, class_id, teacher_id, start_time, end_time, schedule_type (e.g. weekly, quran) |
| **khateebs** | id, name (used in Jummah) |

- **Realtime:** Used for prayer_times (today) and jummah_config so the app updates when admins change data.
- **Storage:** `app_assets` for event and announcement images; default images referenced in `supabase_constants.dart`.
- **Edge functions:** `stripe-payment-intent` for creating Stripe Payment Intents.
- **Cron/notifications:** Supabase + OneSignal for prayer/Jummah reminders (see `PRAYER_NOTIFICATIONS_README.md` and `fix_prayer_jummah_notifications.sql`).

---

## 6. Navigation & routing

- **Root:** `/` → `AuthWrapper` (redirect to `/home` or `/login`).
- **Auth:** `/login`, `/register` (standalone; no shell).
- **Main shell (bottom nav):** StatefulShellRoute with 5 branches:
  - **0** `/home` → HomePage; child `/home/prayer-calendar` → PrayerCalendarPage
  - **1** `/community` → CommunityPage
  - **2** `/donate` → DonationPage
  - **3** `/classes` → ClassesSchedulePage
  - **4** `/profile` → ProfilePage; children: `/profile/edit`, `/profile/change-password`, `/profile/admin` (+ admin sub-routes)
- **Admin sub-routes (under `/profile/admin`):** prayer-times, events, announcements, jummah-settings, schedule, classes, teachers, donations, khateebs.

Redirect logic: not logged in → `/login` (except login/register); logged in and on `/`, `/login`, or `/register` → `/home`. No role-based redirect for admin paths.

---

## 7. File-by-file summary (lib/)

| File | Role |
|------|------|
| **main.dart** | Init: timezone, dotenv, Stripe key, Supabase, OneSignal; ProviderScope; MaterialApp.router |
| **core/constants/supabase_constants.dart** | Supabase URL & anon key; default event/announcement image URLs |
| **core/presentation/main_scaffold.dart** | Bottom nav (Home, Community, Donate, Classes, Profile); green accent |
| **core/router/router.dart** | GoRouter, auth redirect, all routes + StatefulShellRoute |
| **core/theme/app_theme.dart** | Material 3 light theme |
| **core/theme/app_pallete.dart** | Colors (primary, background, etc.) |
| **core/utils/snackbar_utils.dart** | Custom snackbar helper |
| **features/auth/data/auth_repository.dart** | signUp, signIn, signOut; OneSignal login/logout |
| **features/auth/presentation/pages/login_page.dart** | Email/password form; authControllerProvider; go to register |
| **features/auth/presentation/pages/register_page.dart** | Full name, email, phone, password, confirm; signUp; go to login on success |
| **features/auth/presentation/providers/auth_provider.dart** | authRepositoryProvider, authControllerProvider, authStateProvider |
| **features/auth/presentation/widgets/auth_wrapper.dart** | Watches auth state; redirects to /home or /login |
| **features/home/presentation/pages/home_page.dart** | Header, next prayer card, today’s times, Jummah row; refresh |
| **features/home/presentation/widgets/jummah_detail_dialog.dart** | Dialog: khutbah time, khateeb, address, reminders |
| **features/prayer_times/** | Models (PrayerTime, JummahConfig, Khateeb), repos (prayer_times, jummah, khateeb), providers (today stream, jummah stream, monthly), PrayerCalendarPage |
| **features/community/** | Event & Announcement models; CommunityRepository (CRUD + upload); eventsProvider, announcementsProvider; CommunityPage (Events | Notices tabs) |
| **features/donation/presentation/pages/donation_page.dart** | Amount chips + custom; Stripe payment; success/error UI |
| **features/donation/services/stripe_service.dart** | createPaymentIntent (Edge Fn), init/present Payment Sheet, save to payments |
| **features/classes/** | Class, Teacher, WeeklySchedule models; repos; weeklySchedulesProvider, quranSchedulesProvider; ClassesSchedulePage; admin: ManageSchedulePage, ManageClassesPage, ManageTeachersPage |
| **features/profile/** | ProfileModel; profileProvider; ProfilePage, EditProfilePage, ChangePasswordPage; notifications toggle; Help & Support sheet |
| **features/admin/presentation/pages/** | AdminDashboardPage (tiles); ManagePrayerTimesPage, ManageEventsPage, ManageAnnouncementsPage, JummahSettingsPage, DonationHistoryPage, ManageKhateebsPage; schedule/classes/teachers from classes feature |

---

## 8. Notable implementation details

- **Melbourne time:** All prayer and clock logic uses `Australia/Melbourne`; NTP offset applied for display clock.
- **Iqamah vs Adhan:** Home shows “NEXT PRAYER” or “IQAMAH” and countdown; list shows both Adhan and Iqamah per prayer.
- **Realtime:** Today’s prayer times and jummah config use Supabase Realtime so changes from admin appear without refresh.
- **Images:** Events/announcements use optional `image_url`; upload to `app_assets`; fallback to `SupabaseConstants.defaultEventImageUrl` / `defaultAnnouncementImageUrl`.
- **Payments:** Payment Intent ID is derived from client secret (`split('_secret')[0]`); status stored as `succeeded` after successful sheet present.
- **Profile role:** Only `role == 'admin'` sees Admin Console; router does not enforce admin-only access to admin routes.

---

## 9. Existing analysis and improvements

The repo already includes **APP_ANALYSIS.md** with concrete issues and fixes (auth navigation, admin guard, secrets, tests, confirm password, Stripe error handling, OneSignal duplication, logging, etc.). Use that for a prioritized list of improvements.

This document is a **product and architecture overview**; for “what’s wrong and how to fix it,” see **APP_ANALYSIS.md**.
