-- Apple App Store Requirement (Guideline 5.1.1)
-- Run this SQL in your Supabase Dashboard -> SQL Editor
-- It allows a logged-in user to securely delete their own account from the database.

create or replace function delete_user()
returns void
language plpgsql
security definer
as $$
begin
  -- Manually cascade delete dependent data first to guarantee no Foreign Key violations!
  delete from public.payments where user_id = auth.uid();
  delete from public.profiles where id = auth.uid();
  
  -- Finally delete the core authentication record
  delete from auth.users where id = auth.uid();
end;
$$;
