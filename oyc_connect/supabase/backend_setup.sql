-- INSTRUCTIONS FOR SETUP
-- You cannot run this file directly to set up Webhooks. 
-- You must go to the Supabase Dashboard -> Database -> Webhooks.

/*
1. Create Webhook for ANNOUNCEMENTS
   - Name: notify-announcements
   - Table: public.announcements
   - Events: INSERT
   - Type: HTTP Request
   - Method: POST
   - URL: https://<project-ref>.supabase.co/functions/v1/notify_broadcast
   - Headers: Authorization: Bearer <anon-key>

2. Create Webhook for EVENTS
   - Name: notify-events
   - Table: public.events
   - Events: INSERT
   - Type: HTTP Request
   - Method: POST
   - URL: https://<project-ref>.supabase.co/functions/v1/notify_broadcast
   - Headers: Authorization: Bearer <anon-key>
*/

-- OPTIONAL: IF YOU WANT TO SCHEDULE PRAYER TIMES
-- You need to enable the pg_cron extension in Dashboard -> Database -> Extensions.
-- Then run:
/*
select cron.schedule(
  'check-prayer-times',
  '* * * * *', -- Every minute
  $$
    select
      net.http_post(
          url:='https://<project-ref>.supabase.co/functions/v1/notify_broadcast',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer <anon-key>"}',
          body:='{"record": {"title": "Prayer Alert", "body": "It is prayer time"}}'
      ) as request_id;
  $$
);
*/
