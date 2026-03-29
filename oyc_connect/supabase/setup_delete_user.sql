-- Apple App Store Requirement (Guideline 5.1.1)
-- Run this SQL in your Supabase Dashboard -> SQL Editor
-- It allows a logged-in user to securely delete their own account from the database.

create or replace function delete_user()
returns void
language plpgsql
security definer
as $$
begin
  -- This securely deletes the user executing the function from the Supabase auth.users table.
  -- Supabase will automatically log them out and cascade delete their public profile if foreign keys are setup.
  delete from auth.users where id = auth.uid();
end;
$$;
