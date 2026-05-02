-- FIXED CRON JOB FOR JUMMAH NOTIFICATIONS
-- Problem: Previous cron used prayer_times.jumuah column (which might be null/unused).
-- Fix: We now fetch the Khutbah time from 'jummah_configurations' table.

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

  -- Jummah specific
  is_friday boolean;
  jummah_khutbah_str text;
begin
  -- Get today's prayer times
  select * into p_record from public.prayer_times where date = today_date;
  
  -- If no data for today, exit
  if p_record is null then
    return;
  end if;

  -- Check if today is Friday (0=Sunday, 5=Friday, 6=Saturday in some systems, check Postgres 'isodow')
  -- Postgres ISODOW: Monday(1) to Sunday(7). Friday is 5.
  is_friday := extract(isodow from (now() at time zone 'utc') at time zone target_timezone) = 5;

  -- List of prayers to check
  foreach prayer_name in array array['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Jumuah']
  loop
    -- Extract time string based on name
    begin
        prayer_time := null; -- Reset

        if prayer_name = 'Fajr' then prayer_time := to_timestamp(p_record.fajr, 'HH:MI AM')::time;
        elsif prayer_name = 'Dhuhr' then prayer_time := to_timestamp(p_record.dhuhr, 'HH:MI PM')::time;
        elsif prayer_name = 'Asr' then prayer_time := to_timestamp(p_record.asr, 'HH:MI PM')::time;
        elsif prayer_name = 'Maghrib' then prayer_time := to_timestamp(p_record.maghrib, 'HH:MI PM')::time;
        elsif prayer_name = 'Isha' then prayer_time := to_timestamp(p_record.isha, 'HH:MI PM')::time;
        
        -- SPECIAL JUMMAH HANDLING
        elsif prayer_name = 'Jumuah' and is_friday then
            -- Fetch From jummah_configurations
            select khutbah_time into jummah_khutbah_str from public.jummah_configurations limit 1;
            
            if jummah_khutbah_str is not null then
                 prayer_time := to_timestamp(jummah_khutbah_str, 'HH:MI PM')::time;
            else
                 -- Fallback to prayer_times table if config is missing
                 if p_record.jumuah is not null then
                    prayer_time := to_timestamp(p_record.jumuah, 'HH:MI PM')::time;
                 end if;
            end if;
        end if;

        -- If undefined (e.g. not Friday for Jumuah, or parse error), skip
        if prayer_time is null then continue; end if;

    exception when others then
        -- Handle parse errors
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
