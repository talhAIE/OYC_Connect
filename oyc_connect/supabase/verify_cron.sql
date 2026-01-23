-- 1. Check if the Timer is running
-- You should see a new row here every minute with status "succeeded"
select * from cron.job_run_details 
order by start_time desc 
limit 5;

-- 2. Check the Database Time
-- Run this to see exactly what time the Server thinks it is in Melbourne.
-- Use this time to plan your test.
select (now() at time zone 'utc') at time zone 'Australia/Melbourne' as current_melbourne_time;
