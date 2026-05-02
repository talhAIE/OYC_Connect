# Password Reset & Supabase Configuration

## Overview

OYC Connect supports **forgot password** via email. The user requests a reset link, clicks it in their email, and is taken to the app to set a new password. No duplicate accounts can be created with the same email (Supabase enforces this; the app shows a clear message).

---

## Why you might see a blank page when clicking the reset link

If the reset link opens in a **browser** (e.g. Gmail opening the link in Chrome, or clicking on a PC), the link points to the app’s URL scheme (`oycconnect://...`). Browsers can’t open that, so you get a **blank or “Untitled” page**.

**Fix:** Use the **web reset page** so the link opens a real webpage. The user can then set a new password directly in the browser. Steps are below.

---

## 1. Supabase Dashboard – Redirect URL

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project.
2. Go to **Authentication** → **URL Configuration**.
3. Under **Redirect URLs**, add **both**:
   - `oycconnect://reset-password` (so the app can open when the web page redirects)
   - Your **web reset page URL** (e.g. `https://yoursite.com/reset-password.html`) – see next section.
4. Save.

---

## 2. Web reset page (reset password in the browser)

A reset page is in the project: **`web/reset-password.html`**.

**What it does:** When the user clicks the reset link in the email, Supabase sends them to this page (with the token in the URL). The page recovers the session and shows a **form to set a new password** (new password + confirm). The user submits the form; the page updates the password via Supabase and shows success. They can then open the OYC Connect app and log in with the new password. Everything happens on the web page—no app redirect. *“Open in app”*
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

4. **Supabase URL and key:** The page uses your Supabase project URL and anon key (same as in the app). They are set in the `<script>` at the top of `web/reset-password.html` (`SUPABASE_URL` and `SUPABASE_ANON_KEY`). If you use a different project, replace them there.

5. **Test:** Request a reset from the app, then click the link in the email. You should see the web page, enter a new password, and get a success message. Then log in to the app with the new password.

---

## 3. Only registered emails get a reset link

The app and web page call the **request-password-reset** Edge Function instead of Supabase Auth directly. The function checks that the email exists in `auth.users` before sending the reset email.

- **If the email is not registered:** The user sees *"No account found with this email. Please sign up first."* (app) or the same message on the web page. No email is sent.
- **If the email is registered:** The reset email is sent as usual.

**Setup:**

1. Run the migration that creates the RPC used by the Edge Function:
   - `supabase/migrations/20250215000000_add_check_user_exists_for_reset.sql`  
   (Apply via Supabase Dashboard → SQL Editor, or `supabase db push`.)

2. Deploy the Edge Function:
   - `supabase functions deploy request-password-reset`

3. Add the **anon key** as a secret for the Edge Function (Dashboard → Edge Functions → request-password-reset → Secrets):
   - Name: **`SUPABASE_ANON_KEY`**  
   - Value: your project’s anon (public) key (same as in the app).

See `supabase/functions/request-password-reset/README.md` for details.

---

## 4. Email Templates (optional)

To customize the reset email text:

1. **Authentication** → **Email Templates**.
2. Select **Reset Password**.
3. Edit the template. The link is `{{ .ConfirmationURL }}`. Supabase will use the **Redirect URL** you configured so that this URL can be `oycconnect://reset-password#...` when the user opens it on a device with the app installed.

---

## 5. App Flow

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

## 6. Duplicate Email (Registration)

Supabase Auth allows only one account per email. If someone tries to register with an email that already exists:

- The API returns an error.
- The app maps it to: *“An account with this email already exists. Please log in or use Forgot password.”*

No extra backend setup is required; the app uses Supabase’s built-in uniqueness.

---

## 7. Platform Deep Link Setup

- **Android:** `android/app/src/main/AndroidManifest.xml` – intent-filter with `oycconnect` scheme and `reset-password` host.
- **iOS:** `ios/Runner/Info.plist` – `CFBundleURLTypes` with scheme `oycconnect`.

Already configured in this project.

---

## 8. Testing

1. Run the app and go to **Login** → **Forgot Password**.
2. Enter a **real email** that exists in your Supabase Auth users.
3. Check the inbox; use the link in the email (on a device/emulator where the app is installed).
4. App should open and show **Set New Password**; set a new password and confirm you can log in with it.

If the link opens in a browser and you see a blank page, set up the web fallback (section 2) and use it as the redirect URL.
