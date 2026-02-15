-- 1. Enable the Network Extension
create extension if not exists pg_net;

-- 2. Create the Function to Send Notification
create or replace function public.send_onesignal_notification()
returns trigger as $$
declare
  -- MUST match Flutter app (main.dart) and send_onesignal_notification_manual – same OneSignal app
  os_app_id text := '4428e176-2a7f-4d7f-9c28-4ebec13b5001';
  os_api_key text := 'os_v2_app_iquoc5rkp5gx7hbij27mco2qahav72yvfclu2jexb3dw457asdftzhf4vtf5e45ozbln6ruhu5g3j6wcw6ilapalnnjk4by6x6mn4ca';
  
  -- Variables
  notification_title text;
  notification_body text;
  api_response_id bigint;
begin
  -- Determine Content based on Table
  if TG_NAME = 'trigger_notify_event' then
      notification_title := 'New Event: ' || NEW.title;
      notification_body := 'Check the app for details.'; -- Customize as needed
  elsif TG_NAME = 'trigger_notify_announcement' then
      notification_title := NEW.title;
      notification_body := coalesce(trim(NEW.body), 'New announcement.') || ' Tap for more details.';
  else
      notification_title := 'Update';
      notification_body := 'New content available.';
  end if;

  -- Call OneSignal API Directly
  perform net.http_post(
      url:='https://onesignal.com/api/v1/notifications',
      headers:=jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Basic ' || os_api_key
      ),
      body:=jsonb_build_object(
          'app_id', os_app_id,
          'headings', jsonb_build_object('en', notification_title),
          'contents', jsonb_build_object('en', notification_body),
          'included_segments', jsonb_build_array('All') -- Sends to Everyone
      )
  );

  return NEW;
end;
$$ language plpgsql security definer;

-- 3. Create Trigger for EVENTS Table
drop trigger if exists trigger_notify_event on public.events;
create trigger trigger_notify_event
after insert on public.events
for each row execute function public.send_onesignal_notification();

-- 4. Create Trigger for ANNOUNCEMENTS Table
drop trigger if exists trigger_notify_announcement on public.announcements;
create trigger trigger_notify_announcement
after insert on public.announcements
for each row execute function public.send_onesignal_notification();
