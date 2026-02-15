# Password Reset & Supabase Configuration

## Overview

OYC Connect supports **forgot password** via email. The user requests a reset link, clicks it in their email, and is taken to the app to set a new password. No duplicate accounts can be created with the same email (Supabase enforces this; the app shows a clear message).

---

## Why you might see a blank page when clicking the reset link

If the reset link opens in a **browser** (e.g. Gmail opening the link in Chrome, or clicking on a PC), the link points to the app’s URL scheme (`oycconnect://...`). Browsers can’t open that, so you get a **blank or “Untitled” page**.

**Fix:** Use a **web fallback page** so the link opens a real webpage first. That page then redirects to the app on phones where the app is installed, and shows instructions otherwise. Steps are below.

---

## 1. Supabase Dashboard – Redirect URL

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project.
2. Go to **Authentication** → **URL Configuration**.
3. Under **Redirect URLs**, add **both**:
   - `oycconnect://reset-password` (so the app can open when the web page redirects)
   - Your **web fallback URL** (e.g. `https://yoursite.com/reset-password.html`) – see next section.
4. Save.

---

## 2. Web fallback page (stops the blank page)

A fallback page is in the project: **`web/reset-password.html`**.

**What it does:** When the user clicks the reset link, Supabase sends them to this page (with the token in the URL). The page then tries to open the app (`oycconnect://reset-password#...`). On a phone with the app installed, the app opens. If not, the page shows: *“Open in app”* and instructions.

**Setup:**

1. **Host the page** somewhere HTTPS, for example:
   - **GitHub Pages:** Create a repo, push `web/reset-password.html` (e.g. as `docs/reset-password.html` or in root), enable Pages. URL will be like `https://yourusername.github.io/your-repo/reset-password.html`.
   - **Netlify / Vercel / your own server:** Upload the file so it’s available at e.g. `https://yourdomain.com/reset-password.html`.

2. **Add that URL in Supabase** under **Redirect URLs** (see section 1).

3. **Tell the app to use it:** In `lib/core/constants/supabase_constants.dart`, set:
   ```dart
   static const String? passwordResetRedirectUrl = 'https://your-actual-url.com/reset-password.html';
   ```
   (Use your real URL. If you leave it `null`, the app keeps using `oycconnect://` and the email link can still open a blank page in the browser.)

4. **Test:** Request a reset from the app, then click the link in the email. You should see the web page (and on a phone with the app, the app should open).

---

## 3. Email Templates (optional)

To customize the reset email text:

1. **Authentication** → **Email Templates**.
2. Select **Reset Password**.
3. Edit the template. The link is `{{ .ConfirmationURL }}`. Supabase will use the **Redirect URL** you configured so that this URL can be `oycconnect://reset-password#...` when the user opens it on a device with the app installed.

---

## 4. App Flow

1. **Forgot password**  
   User taps “Forgot Password?” on the login screen → **Forgot Password** page → enters email → taps “Send Reset Link”.  
   App calls `Supabase.auth.resetPasswordForEmail(email, redirectTo: 'oycconnect://reset-password')`.

2. **Email**  
   User receives the email and taps the link.

3. **Open app**  
   Link opens the app (Android/iOS deep link `oycconnect://reset-password` with tokens in the fragment).  
   `AppLinkHandler` receives the link, calls `getSessionFromUrl(uri)`, and sets `recoveryPendingProvider = true`.  
   Router redirects to **Set New Password**.

4. **Set new password**  
   User enters new password and confirm → “Update Password”.  
   App calls `updateUser({ password })`, then signs the user out and navigates to login with a success message.

---

## 5. Duplicate Email (Registration)

Supabase Auth allows only one account per email. If someone tries to register with an email that already exists:

- The API returns an error.
- The app maps it to: *“An account with this email already exists. Please log in or use Forgot password.”*

No extra backend setup is required; the app uses Supabase’s built-in uniqueness.

---

## 6. Platform Deep Link Setup

- **Android:** `android/app/src/main/AndroidManifest.xml` – intent-filter with `oycconnect` scheme and `reset-password` host.
- **iOS:** `ios/Runner/Info.plist` – `CFBundleURLTypes` with scheme `oycconnect`.

Already configured in this project.

---

## 7. Testing

1. Run the app and go to **Login** → **Forgot Password**.
2. Enter a **real email** that exists in your Supabase Auth users.
3. Check the inbox; use the link in the email (on a device/emulator where the app is installed).
4. App should open and show **Set New Password**; set a new password and confirm you can log in with it.

If the link opens in a browser and you see a blank page, set up the web fallback (section 2) and use it as the redirect URL.
