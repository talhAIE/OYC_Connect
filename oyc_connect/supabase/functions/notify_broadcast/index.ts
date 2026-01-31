import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ONE_SIGNAL_APP_ID = "1841c7be-1c1b-4ef4-96ec-17b15b252126";
// Note: In production, store this in Deno.env.get("ONESIGNAL_API_KEY")
const ONE_SIGNAL_API_KEY = "os_v2_app_dba4ppq4dnhpjfxmc6yvwjjbezkxhogy6ivuud5q5bxhbkzopnojspymhbylfsom5vrpyciq3ogpi7seotmbx3k5uh6ki3hyzqr545i";

serve(async (req) => {
  try {
    const { record } = await req.json(); // Payload from Database Webhook

    // Customized message based on table
    let title = "New Update";
    let body = "Check the app for details.";

    // Logic to determine message content based on table fields
    if (record.title && record.body) {
       // Likely an Announcement
       title = record.title;
       body = record.body;
    } else if (record.title && record.event_date) {
       // Likely an Event
       title = "New Event: " + record.title;
       body = record.description || "Join us for this event!";
    }

    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONE_SIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONE_SIGNAL_APP_ID,
        headings: { en: title },
        contents: { en: body },
        included_segments: ["All"], // Sends to every user
      }),
    });

    const result = await response.json();
    return new Response(JSON.stringify(result), { headers: { "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
