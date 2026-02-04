import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno'

console.log("Hello from Stripe Payment Intent Function!")

serve(async (req) => {
  const { amount, currency } = await req.json()

  // Retrieve stripe key from secrets
  // Ideally, use Deno.env.get('STRIPE_SECRET_KEY')
  // We will assume the user sets this secret in Supabase Dashboard or CLI
  const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
    apiVersion: '2022-11-15',
    httpClient: Stripe.createFetchHttpClient(),
  })

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Stripe expects amounts in smallest currency unit (e.g., cents)
      currency: currency,
      automatic_payment_methods: { enabled: true },
    })

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (error) {
     return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    )
  }
})
