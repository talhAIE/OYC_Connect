-- FIX: Correct Timezone Logic
create or replace function public.check_prayer_times()
returns void as $$
declare
  -- TARGET TIMEZONE (Melbourne)
  target_timezone text := 'Australia/Melbourne';
  
  -- Correctly get "Wall Clock" time in Melbourne
  -- now() is UTC. 'at time zone' converts it to local wall clock time.
  cur_time time := (now() at time zone target_timezone)::time;
  today_date date := (now() at time zone target_timezone)::date;
  
  rec record;
  p_time time;
  check_name text;
begin
  -- Get today's schedule
  select * into rec from public.prayer_times where date = today_date;
  if rec is null then return; end if;

  foreach check_name in array array['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
  loop
      -- Reset p_time
      p_time := null;
      
      -- Parsing Logic (Assumes '05:30 PM' or '17:30' format)
      begin
        if check_name = 'fajr' then p_time := to_timestamp(rec.fajr, 'HH:MI PM')::time; end if;
        if check_name = 'dhuhr' then p_time := to_timestamp(rec.dhuhr, 'HH:MI PM')::time; end if;
        if check_name = 'asr' then p_time := to_timestamp(rec.asr, 'HH:MI PM')::time; end if;
        if check_name = 'maghrib' then p_time := to_timestamp(rec.maghrib, 'HH:MI PM')::time; end if;
        if check_name = 'isha' then p_time := to_timestamp(rec.isha, 'HH:MI PM')::time; end if;
      exception when others then
         -- Skip if format is invalid
         continue;
      end;

      if p_time is not null then
          -- Check "Exact Time" (Window: 0 to +1 min)
          if cur_time >= p_time and cur_time < (p_time + interval '1 minute') then
             perform public.send_onesignal_notification_manual(
                'Time for ' || initcap(check_name), 
                'Iqamah starts shortly.'
             );
          end if;

          -- Check "30 Mins Before"
          if cur_time >= (p_time - interval '30 minutes') and cur_time < ((p_time - interval '30 minutes') + interval '1 minute') then
             perform public.send_onesignal_notification_manual(
                initcap(check_name) || ' in 30 mins', 
                'Prepare for prayer.'
             );
          end if;
      end if;
  end loop;
end;
$$ language plpgsql;

-- Verification Query: Run this to confirm correct Melbourne Time
-- It should return the current "Wall Click" time (e.g., 2026-01-23 14:00:00)
SELECT now() at time zone 'Australia/Melbourne' as correct_melbourne_time;
