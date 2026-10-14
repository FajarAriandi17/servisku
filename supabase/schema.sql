-- =====================================================================
-- ServisKu - Supabase schema
-- Jalankan sekali di: Supabase Dashboard -> SQL Editor -> New query -> Run
-- =====================================================================

-- Profil pengguna
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text default '',
  email text default '',
  phone text default '',
  avatar_url text default '',
  provider text default '',
  updated_at timestamptz default now()
);

-- Kendaraan
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  brand text default '',
  plate text default '',
  year int,
  type text default 'motor',
  current_km int default 0,
  avg_km_per_day int default 30,
  km_updated_at timestamptz default now(),
  color bigint,
  created_at timestamptz default now()
);

-- Pengingat servis (per bulan / per KM / keduanya)
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  title text not null,
  category text default 'servis',
  mode text default 'month',
  interval_months int default 3,
  interval_km int default 2000,
  last_service_date timestamptz default now(),
  last_service_km int default 0,
  notify_days_before int default 7,
  notify_km_before int default 200,
  active boolean default true,
  notes text default '',
  created_at timestamptz default now()
);

-- Riwayat servis
create table if not exists public.records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  reminder_id uuid references public.reminders(id) on delete set null,
  title text not null,
  category text default 'servis',
  date timestamptz default now(),
  km int default 0,
  cost bigint default 0,
  workshop text default '',
  notes text default '',
  created_at timestamptz default now()
);

create index if not exists vehicles_user_idx on public.vehicles(user_id);
create index if not exists reminders_user_idx on public.reminders(user_id);
create index if not exists records_user_idx on public.records(user_id);

-- Row Level Security: setiap pengguna hanya bisa mengakses datanya sendiri
alter table public.profiles  enable row level security;
alter table public.vehicles  enable row level security;
alter table public.reminders enable row level security;
alter table public.records   enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "own vehicles" on public.vehicles;
create policy "own vehicles" on public.vehicles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own reminders" on public.reminders;
create policy "own reminders" on public.reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own records" on public.records;
create policy "own records" on public.records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profiles, public.vehicles, public.reminders, public.records to authenticated;

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
