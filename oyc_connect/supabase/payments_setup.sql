-- Create Payments Table
create table public.payments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  amount numeric not null,
  currency text not null,
  status text not null, -- 'succeeded', 'pending', 'failed'
  payment_intent_id text unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.payments enable row level security;

-- Policies
create policy "Users can view their own payments."
  on payments for select
  using ( auth.uid() = user_id );

    create policy "Users can insert their own payments."
  on payments for insert
  with check ( auth.uid() = user_id );

-- Only admins should be able to view all payments (if needed later)
create policy "Admins can view all payments."
  on payments for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );
