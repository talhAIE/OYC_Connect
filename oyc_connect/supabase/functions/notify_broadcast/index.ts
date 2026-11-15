import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { serverOnly } from '../_shared/server-auth.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve((req) => serverOnly(req, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'), async () => {
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

    // Use the same protected preference-aware pipeline as scheduled prayers.
    const client = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const { error } = await client.rpc('send_onesignal_notification_manual', {
      title, body,
    });
    if (error) return new Response('Could not queue notification', { status: 502 });
    return new Response(JSON.stringify({ queued: true }), { headers: { "Content-Type": "application/json" } });
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Could not send notification.' }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}));
