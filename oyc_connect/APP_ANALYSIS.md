# OYC Connect – App Analysis (Issues & Fixes)

## Summary

The app is well-structured (Riverpod, go_router, Supabase, feature-based layout). Below are **issues found** and **recommended fixes**, ordered by impact.

---

## Critical (fix soon)

### 1. Auth navigation – `_debugLocked` / setState after dispose

**Issue:** Login and Register pages both:
- Call `context.go('/home')` or `Navigator.pop(context)` inside `ref.listen` **and** the router already redirects on auth change → double navigation and possible `!_debugLocked` / setState-after-dispose.
- Use `Navigator.push(MaterialPageRoute(...))` for Login ↔ Register instead of go_router.

**Fix:**
- In **login_page.dart**: In the listener, only show the snackbar on success; **remove** `context.go('/home')`. Let the router redirect.
- In **register_page.dart**: On success, use `context.go('/login')` instead of `Navigator.pop(context)`; for "Already have an account? Login" use `context.go('/login')` instead of `Navigator.push`.
- In **login_page.dart**: For "Create Account" use `context.go('/register')` instead of `Navigator.push`.

### 2. No admin route guard

**Issue:** Any logged-in user can open `/profile/admin` and admin sub-routes. Router does not check `profiles.role == 'admin'`.

**Fix:** In `router.dart` `redirect`, if `state.uri.path.startsWith('/profile/admin')`, resolve the current user’s profile (e.g. from a cached provider or one-shot Supabase read). If role != 'admin', return `'/profile'` or `'/home'`.

### 3. Secrets in source code

**Issue:** Supabase URL/anon key in `supabase_constants.dart`, OneSignal App ID hardcoded in `main.dart`. Not safe for multiple clients or if repo is shared.

**Fix:** Move to `assets/.env` (e.g. `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ONESIGNAL_APP_ID`). Load with `dotenv` and use in `main.dart` / Supabase init. Add `.env.example` with placeholders. Keep `.env` gitignored.

### 4. Widget test does not match app

**Issue:** `test/widget_test.dart` still has the default counter test (finds "0", "1", Icons.add). The app has no counter, so the test is misleading and will fail when run.

**Fix:** Replace with a smoke test that pumps `MyApp` and checks for a widget that exists (e.g. a key or text from the first screen), or remove the counter assertions and only verify the app builds.

---

## High (important for correctness & security)

### 5. Confirm password not validated

**Issue:** In `register_page.dart`, the confirm-password validator only checks `value!.isEmpty`, not that it matches the password field.

**Fix:** In the validator, compare `value` with `_passwordController.text` and return an error string if they differ.

### 6. Stripe Edge Function response not checked

**Issue:** `stripe_service.dart` uses `return response.data` from `functions.invoke` without checking `response.status` or `response.error`. Backend errors (e.g. missing `STRIPE_SECRET_KEY`) can surface as null `clientSecret` or confusing exceptions.

**Fix:** After `invoke`, if `response.status != 200` or `response.error != null`, throw with a clear message (or map error to user message). Then read `clientSecret` from `response.data`.

### 7. Payment save errors swallowed

**Issue:** `_savePaymentToSupabase` catches all errors and only `print(...)`. User can see “payment succeeded” while the DB insert failed.

**Fix:** Rethrow after logging, or call `onResult(false)` and optionally show a message that the payment may need to be verified. Prefer not to silently ignore.

### 8. Payment intent ID parsing fragile

**Issue:** `paymentIntentId.split('_secret')[0]` assumes a specific client-secret format. If Stripe changes format, this can break or store wrong ID.

**Fix:** Prefer using the Payment Intent ID returned by the Edge Function (if you add it to the response). Otherwise keep the split but add a null/empty check and fallback (e.g. store raw and handle in backend).

### 9. Duplicate OneSignal login/logout

**Issue:** `OneSignal.login` is called in both `AuthRepository.signIn`/`signUp` and `AuthController.signIn`. `OneSignal.logout` is in both `AuthRepository.signOut` and `AuthController.signOut`. Redundant and can make behavior harder to reason about.

**Fix:** Keep OneSignal calls only in one place (e.g. only in `AuthRepository`), and remove them from `AuthController`.

---

## Medium (quality & consistency)

### 10. `print()` instead of proper logging

**Issue:** Multiple files use `print()` for errors (e.g. prayer_times providers/repos, stripe_service, community_repository). No log levels; can leak into release.

**Fix:** Use `debugPrint` for dev-only messages, or add a small logger (e.g. `logger` package) and use it everywhere. Avoid logging sensitive data.

### 11. `.env` load can crash

**Issue:** `dotenv.load(fileName: "assets/.env")` is called without try/catch. If the file is missing (e.g. new clone), the app crashes at startup.

**Fix:** Wrap in try/catch; if load fails, show a clear error (e.g. runApp of an error widget) or use safe defaults in debug, and document that `.env` is required.

### 12. Form key null assertion

**Issue:** Several pages use `_formKey.currentState!.validate()` without checking that `currentState != null` (e.g. login, register, edit_profile, change_password, jummah_settings). Rare but can theoretically throw.

**Fix:** Use `_formKey.currentState?.validate() ?? false` or guard with `if (_formKey.currentState == null) return;` before validate.

### 13. Register validator uses `value!`

**Issue:** Confirm password validator uses `value!.isEmpty`; if validator is ever called with null, it throws.

**Fix:** Use `value == null || value.isEmpty` (and then compare with password).

### 14. Navigator.pop vs go_router in dialogs/sheets

**Issue:** Many admin/community/classes pages use `Navigator.pop(context)` to close dialogs or bottom sheets. That’s correct for overlay routes; no change needed for dialogs. Only Login/Register should use go_router for **page** navigation (see #1).

---

## Low (nice to have)

### 15. StripeService as global singleton

**Issue:** `StripeService.instance` makes testing and multi-tenant config harder.

**Fix:** Provide via Riverpod (e.g. `stripeServiceProvider`) and inject where needed.

### 16. Inconsistent mounted checks

**Issue:** Some async callbacks use `mounted`, others `context.mounted`. Both are valid; consistency improves readability.

**Fix:** Prefer `if (!context.mounted) return;` after async gaps in widgets; use `mounted` in State classes. Apply consistently in new code.

### 17. No unit or integration tests

**Issue:** Only one widget test (and it’s the wrong one). No tests for auth, Stripe, or repositories.

**Fix:** Add unit tests for AuthRepository, StripeService (mocked Supabase), and key providers. Add a simple integration test for login → home (or donation flow) if time allows.

---

## Quick reference – files to touch

| Priority | Area            | Files |
|----------|-----------------|-------|
| Critical | Auth navigation | `login_page.dart`, `register_page.dart` |
| Critical | Admin guard     | `router.dart` |
| Critical | Secrets         | `main.dart`, `supabase_constants.dart`, `assets/.env`, `.env.example` |
| Critical | Test            | `test/widget_test.dart` |
| High     | Register        | `register_page.dart` (confirm password validator) |
| High     | Stripe          | `lib/features/donation/services/stripe_service.dart` |
| High     | OneSignal       | `auth_repository.dart`, `auth_provider.dart` |
| Medium   | Logging         | Multiple (prayer_times, stripe, community) |
| Medium   | Startup         | `main.dart` (dotenv try/catch) |
| Medium   | Form keys       | login, register, edit_profile, change_password, jummah_settings |

---

*Generated from codebase analysis. Re-run analysis after major changes.*
