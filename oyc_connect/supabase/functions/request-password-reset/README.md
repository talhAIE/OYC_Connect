# request-password-reset Edge Function

Sends a password-reset email **only if** the email is registered in `auth.users`. Used by the app (Forgot Password) and the web reset page.

## Behavior

1. Receives `{ email, redirectTo? }`.
2. Calls RPC `auth_user_exists_by_email(email)` (checks `auth.users`).
3. If no user: returns 400 with `"No account found with this email. Please sign up first."`.
4. If user exists: calls Supabase Auth `/auth/v1/recover` to send the reset email, then returns 200.

## Required setup

1. **Run the migration** that creates `auth_user_exists_by_email`:
   - `supabase/migrations/20250215000000_add_check_user_exists_for_reset.sql`

2. **Set Edge Function secret** in Supabase Dashboard:
   - Project → Edge Functions → request-password-reset → Secrets (or Project Settings → Edge Functions → Secrets)
   - Add: **`SUPABASE_ANON_KEY`** = your project’s anon (public) key (same as in the app and web page).

   `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are usually set automatically; the anon key is needed to call the Auth recover endpoint.

## Deploy

```bash
supabase functions deploy request-password-reset
```

## Invoke from client

- **Flutter:** `supabase.functions.invoke('request-password-reset', body: { email, redirectTo })`
- **Web:** `fetch(SUPABASE_URL + '/functions/v1/request-password-reset', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + SUPABASE_ANON_KEY }, body: JSON.stringify({ email, redirectTo }) })`
