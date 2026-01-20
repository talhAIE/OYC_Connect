# OYC Connect - Implementation Plan

## Project Overview
- **App Name:** OYC Connect
- **Platforms:** Android, iOS, Web (Admin)
- **Tech Stack:** Flutter, Supabase, Riverpod, Stripe
- **Architecture:** MVVM (Model-View-ViewModel)

## Phase 1: Foundation & Authentication
**Goal:** Initialize the app, set up architecture, and handle user authentication.

### 1.1 Project Setup
- [ ] **Dependencies:**
  - `supabase_flutter`: Backend interaction.
  - `flutter_riverpod`, `riverpod_annotation`: State management.
  - `go_router`: Navigation.
  - `freezed_annotation`, `json_annotation`: Data modeling.
  - `flutter_launcher_icons`: App icon generation.
- [ ] **Structure:**
  - `lib/core/`: Constants, Themes, Utils.
  - `lib/features/auth/`: Login, Register, Auth Logic.
  - `lib/features/home/`: Main user interface.
  - `lib/shared/`: Shared widgets and providers.

### 1.2 Supabase & Backend
- [ ] Configure Supabase project (URL & Key).
- [ ] Create `profiles` table linked to `auth.users`.
- [ ] Setup defined Row Level Security (RLS) policies.

### 1.3 Authentication
- [ ] Implement `AuthRepository` (Sign In, Sign Up, Sign Out).
- [ ] Implement `AuthController` (State Management).
- [ ] **UI Implementation:**
  - Splash Screen (Auth State Check).
  - Login Screen.
  - Registration Screen.
- [ ] **Verification:** Successful user sign-up via app reflects in Supabase dashboard.

---

## Phase 2: Core Community Features
**Goal:** Implement the primary features for community members (Prayer times, Events, Donations).

### 2.1 Database Schema
- [ ] **Tables:**
  - `prayer_times`: Daily prayer schedules.
  - `events`: Community gatherings and lectures.
  - `announcements`: News and notices.
- [ ] **Models:** Generate Dart data classes using `freezed`.

### 2.2 Prayer Times (Realtime)
- [ ] Implement `PrayerTimesRepository` with Realtime subscription.
- [ ] **UI:** Home Screen displaying live prayer times.
- [ ] **Verification:** Updates in database instantly reflect on UI.

### 2.3 Events & Notice Board
- [ ] Implement `EventsRepository`.
- [ ] **UI:** 
  - Events Calendar View.
  - Digital Notice Board List.

### 2.4 Donations (Client Side)
- [ ] Design Donation UI.
- [ ] Setup Stripe SDK basic integration.

---

## Phase 3: Admin Panel, Notifications & Payments
**Goal:** Empower admin capabilities and finalize external integrations.

### 3.1 Admin Features
- [ ] **Role-Based Access:** Add 'admin' role to profiles; secure admin routes.
- [ ] **Admin Dashboard:**
  - Edit/Update Prayer Times.
  - Create/Delete Events & Announcements.
  - View Donation Logs.

### 3.2 Advanced Integrations
- [ ] **Stripe Production:** Implement backend Edge Functions for secure payments.
- [ ] **Notifications:** Integrate OneSignal or FCM for push alerts (Adhan, Emergency).
- [ ] **SMS (Optional):** Integration with Twilio for critical alerts.

### 3.3 Deployment
- [ ] Final Testing (Unit & UI Tests).
- [ ] Build & Release (Play Store, App Store).
