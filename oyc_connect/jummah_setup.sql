-- Create Jummah Configurations Table
create table public.jummah_configurations (
  id uuid primary key default gen_random_uuid(),
  khutbah_time text not null, -- e.g., "1:30 PM"
  jummah_time text not null, -- e.g., "2:00 PM"
  address text not null, -- e.g., "Address - 229 Grand Boulevard..."
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Enable RLS
alter table public.jummah_configurations enable row level security;

-- Policies
create policy "Jummah configs are viewable by everyone."
  on jummah_configurations for select
  using ( true );

create policy "Only admins can manage jummah configs."
  on jummah_configurations for all
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Insert initial default row (to ensure there's always one config to edit)
insert into public.jummah_configurations (khutbah_time, jummah_time, address)
values ('1:15 PM', '2:00 PM', '229 Grand Boulevard, Craigieburn 3064 - at the Clubhouse');
