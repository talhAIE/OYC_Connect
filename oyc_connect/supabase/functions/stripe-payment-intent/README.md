# stripe-payment-intent

Supabase Edge Function that creates a Stripe Payment Intent for donations. The Flutter app calls this function when the user taps "Donate"; it returns a `clientSecret` used to show the Stripe Payment Sheet.

## Deploy (required)

The function must be deployed to your Supabase project or the app will get **404 Not Found** when donating.

**Run all commands from the `oyc_connect` folder** (where `supabase/` lives), not the repo root.

1. **Install Supabase CLI** (if not already): https://supabase.com/docs/guides/cli

2. **From `oyc_connect`, log in and link your project:**
   ```bash
   cd oyc_connect
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   (`YOUR_PROJECT_REF` is in Supabase Dashboard → Project Settings → General → Reference ID.)

3. **Set your Stripe secret key** (Dashboard → Project Settings → Edge Functions → Secrets, or CLI):
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_live_...   # or sk_test_... for testing
   ```

4. **From `oyc_connect`, deploy the function:**
   ```bash
   cd oyc_connect
   supabase functions deploy stripe-payment-intent
   ```

After deployment, the donation flow will use this function to create payment intents. Ensure your Flutter app uses the same Supabase project (URL in `supabase_constants.dart`).
