-- 1. Enable pg_cron (Required for scheduling)
create extension if not exists pg_cron;

-- 2. Create the Checker Function
create or replace function public.check_prayer_times()
returns void as $$
declare
  -- Setup Timezone (Change this if needed!)
  target_timezone text := 'Australia/Melbourne';
  
  -- Current values
  current_time_in_zone time := ((now() at time zone 'utc') at time zone target_timezone)::time;
  today_date date := ((now() at time zone 'utc') at time zone target_timezone)::date;
  
  -- Database loop variables
  p_record record;
  prayer_name text;
  prayer_time time;
  notify_time time;
  is_30_min_prior boolean;
begin
  -- Get today's prayer times
  select * into p_record from public.prayer_times where date = today_date;
  
  -- If no data for today, exit
  if p_record is null then
    return;
  end if;

  -- List of prayers to check
  -- We loop manually for simplicity
  foreach prayer_name in array array['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Jumuah']
  loop
    -- Extract time string based on name
    begin
        if prayer_name = 'Fajr' then prayer_time := to_timestamp(p_record.fajr, 'HH:MI AM')::time;
        elsif prayer_name = 'Dhuhr' then prayer_time := to_timestamp(p_record.dhuhr, 'HH:MI PM')::time;
        elsif prayer_name = 'Asr' then prayer_time := to_timestamp(p_record.asr, 'HH:MI PM')::time;
        elsif prayer_name = 'Maghrib' then prayer_time := to_timestamp(p_record.maghrib, 'HH:MI PM')::time;
        elsif prayer_name = 'Isha' then prayer_time := to_timestamp(p_record.isha, 'HH:MI PM')::time;
        elsif prayer_name = 'Jumuah' and p_record.jumuah is not null then prayer_time := to_timestamp(p_record.jumuah, 'HH:MI PM')::time;
        else continue; 
        end if;
    exception when others then
        -- Handle parse errors (e.g. if format is 24h instead of AM/PM)
        -- Fallback: Try casting directly if it's already 24h format
        continue;
    end;

    -- CHECK 1: Is it EXACTLY prayer time? (Allow 1 min buffer)
    if current_time_in_zone between prayer_time and (prayer_time + interval '59 seconds') then
        perform public.send_onesignal_notification_manual(
            'It is time for ' || prayer_name, 
            'Iqamah is shortly.'
        );
    end if;

    -- CHECK 2: Is it 30 MINS BEFORE?
    notify_time := prayer_time - interval '30 minutes';
    if current_time_in_zone between notify_time and (notify_time + interval '59 seconds') then
        perform public.send_onesignal_notification_manual(
            prayer_name || ' is in 30 minutes', 
            'Prepare yourself for prayer.'
        );
    end if;
    
  end loop;
end;
$$ language plpgsql;

-- 3. Helper Function for Manual Calls (Reuses logic)
create or replace function public.send_onesignal_notification_manual(title text, body text)
returns void as $$
declare
  os_app_id text := '1841c7be-1c1b-4ef4-96ec-17b15b252126';
  os_api_key text := 'os_v2_app_dba4ppq4dnhpjfxmc6yvwjjbezkxhogy6ivuud5q5bxhbkzopnojspymhbylfsom5vrpyciq3ogpi7seotmbx3k5uh6ki3hyzqr545i';
begin
  perform net.http_post(
      url:='https://onesignal.com/api/v1/notifications',
      headers:=jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Basic ' || os_api_key
      ),
      body:=jsonb_build_object(
          'app_id', os_app_id,
          'headings', jsonb_build_object('en', title),
          'contents', jsonb_build_object('en', body),
          'included_segments', jsonb_build_array('All'),
          'android_channel_id', 'prayer_channel_id' -- Optional: specific sound channel
      )
  );
end;
$$ language plpgsql;

-- 4. Create the Cron Job (Runs every minute)
-- NOTE: Requires pg_cron to be active (User must enable in Dashboard > Extensions)
select cron.schedule(
    'check-prayer-every-min',
    '* * * * *',
    $$ select public.check_prayer_times() $$
);
