import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = "4428e176-2a7f-4d7f-9c28-4ebec13b5001";
const ONESIGNAL_API_KEY = "av72yvfclu2jexb3dw457asdf";

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record; // The new payment record

    // 1. Initialize Supabase Client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 2. Fetch Donor Name (if user_id exists)
    let donorName = "Someone";
    if (record.user_id) {
      const { data: profile } = await supabaseClient
        .from('profiles')
        .select('full_name')
        .eq('id', record.user_id)
        .single();

      if (profile?.full_name) {
        donorName = profile.full_name;
      }
    }

    // 3. Fetch All Admins
    const { data: admins, error: adminError } = await supabaseClient
      .from('profiles')
      .select('id')
      .eq('role', 'admin');

    if (adminError || !admins || admins.length === 0) {
      console.log("No admins found to notify.");
      return new Response(JSON.stringify({ message: "No admins found" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const adminIds = admins.map(a => a.id);
    const amount = record.amount;
    const currency = (record.currency || 'AUD').toUpperCase();

    // 4. Send Notification via OneSignal
    const notificationBody = {
      app_id: ONESIGNAL_APP_ID,
      target_channel: "push",
      include_aliases: { "external_id": adminIds },
      headings: { "en": "New Donation Received! 💰" },
      contents: { "en": `${donorName} just donated $${amount} ${currency}.` },
    };

    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify(notificationBody),
    });

    const result = await response.json();
    console.log("OneSignal Result:", result);

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
