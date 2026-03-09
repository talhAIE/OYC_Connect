import "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno'

const VALID_CURRENCIES = new Set([
  'aud', 'usd', 'eur', 'gbp', 'cad', 'nzd', 'sgd', 'hkd', 'jpy', 'inr',
  'myr', 'php', 'idr', 'thb', 'vnd', 'krw', 'brl', 'mxn', 'zar',
]);

Deno.serve(async (req) => {
  try {
    const { amount, currency } = await req.json();

    // Input validation
    if (typeof amount !== 'number' || !isFinite(amount) || amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'Amount must be a positive number.' }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    if (amount > 10000) {
      return new Response(
        JSON.stringify({ error: 'Amount cannot exceed $10,000.' }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const normalizedCurrency = (currency || '').toString().toLowerCase().trim();
    if (!normalizedCurrency || normalizedCurrency.length !== 3 || !VALID_CURRENCIES.has(normalizedCurrency)) {
      return new Response(
        JSON.stringify({ error: `Invalid currency: "${currency}". Use a valid 3-letter ISO currency code.` }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY'), {
      apiVersion: '2022-11-15',
      httpClient: Stripe.createFetchHttpClient(),
    });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: normalizedCurrency,
      automatic_payment_methods: { enabled: true },
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }
});
