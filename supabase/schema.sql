-- Pawly's initial Supabase schema. Run this once in Supabase SQL Editor.
-- The policies below keep each pet parent's data private by auth.uid().

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pet parent',
  phone text not null default '',
  city text not null default 'Kuala Lumpur',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  species text not null default 'Dog',
  breed text not null default 'Mixed breed',
  gender text not null default 'Unknown',
  birth_date date,
  weight numeric(6,2) not null default 0 check (weight >= 0),
  image_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.care_tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  category text not null default 'care' check (category in ('meal', 'walk', 'medication', 'care')),
  due_at timestamptz not null default now(),
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_providers (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid references auth.users(id) on delete set null,
  name text not null unique,
  city text not null,
  address text,
  phone text,
  rating numeric(2,1) not null default 0 check (rating between 0 and 5),
  is_verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.provider_services (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.service_providers(id) on delete cascade,
  name text not null,
  description text not null default '',
  service_type text not null default 'grooming' check (service_type in ('grooming', 'boarding')),
  price numeric(10,2) not null check (price >= 0),
  duration_minutes integer not null default 60 check (duration_minutes between 15 and 1440),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.service_slots (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.provider_services(id) on delete cascade,
  starts_at timestamptz not null,
  capacity integer not null default 1 check (capacity between 1 and 20),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(service_id, starts_at)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete restrict,
  service_id uuid not null references public.provider_services(id) on delete restrict,
  slot_id uuid references public.service_slots(id) on delete set null,
  starts_at timestamptz not null,
  status text not null default 'requested' check (status in ('requested', 'confirmed', 'completed', 'cancelled')),
  payment_method text not null default 'pay_at_venue' check (payment_method in ('pay_at_venue', 'online')),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'pending', 'paid', 'refunded')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  service_id uuid not null references public.provider_services(id) on delete cascade,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  reviewer_name text not null default 'Verified pet parent',
  rating integer not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  created_at timestamptz not null default now()
);

-- Safe to rerun when moving from the earlier Pawly starter schema.
alter table public.service_providers add column if not exists merchant_id uuid references auth.users(id) on delete set null;
alter table public.provider_services add column if not exists service_type text not null default 'grooming' check (service_type in ('grooming', 'boarding'));
alter table public.bookings add column if not exists slot_id uuid references public.service_slots(id) on delete set null;
alter table public.bookings add column if not exists payment_method text not null default 'pay_at_venue' check (payment_method in ('pay_at_venue', 'online'));
alter table public.bookings add column if not exists payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'pending', 'paid', 'refunded'));

create index if not exists pets_owner_id_idx on public.pets(owner_id);
create index if not exists care_tasks_owner_due_idx on public.care_tasks(owner_id, due_at);
create index if not exists bookings_owner_starts_idx on public.bookings(owner_id, starts_at);
create index if not exists provider_services_provider_id_idx on public.provider_services(provider_id);
create index if not exists service_slots_service_starts_idx on public.service_slots(service_id, starts_at);
create index if not exists reviews_service_id_idx on public.reviews(service_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists pets_updated_at on public.pets;
create trigger pets_updated_at before update on public.pets for each row execute function public.set_updated_at();
drop trigger if exists care_tasks_updated_at on public.care_tasks;
create trigger care_tasks_updated_at before update on public.care_tasks for each row execute function public.set_updated_at();
drop trigger if exists bookings_updated_at on public.bookings;
create trigger bookings_updated_at before update on public.bookings for each row execute function public.set_updated_at();

-- Every new email/password account gets a profile. The function runs inside
-- PostgreSQL so a user never needs an elevated key from the app.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), 'Pet parent'),
    coalesce(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Reviews always show a display name derived from the verified account rather
-- than trusting a name supplied by the browser.
create or replace function public.set_review_reviewer_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.reviewer_name := coalesce(
    (select display_name from public.profiles where id = new.reviewer_id),
    'Verified pet parent'
  );
  return new;
end;
$$;

drop trigger if exists reviews_set_reviewer_name on public.reviews;
create trigger reviews_set_reviewer_name
  before insert on public.reviews
  for each row execute function public.set_review_reviewer_name();

-- A slot is locked inside the database before creating a booking, preventing
-- two pet parents from taking the final slot at the same time.
create or replace function public.create_booking(
  p_pet_id uuid,
  p_slot_id uuid,
  p_notes text default null,
  p_payment_method text default 'pay_at_venue'
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_service_id uuid;
  v_starts_at timestamptz;
  v_capacity integer;
  v_booked_count integer;
  v_booking public.bookings;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to book.';
  end if;

  if not exists (
    select 1 from public.pets
    where id = p_pet_id and owner_id = auth.uid()
  ) then
    raise exception 'You can only book for one of your own pets.';
  end if;

  if p_payment_method not in ('pay_at_venue', 'online') then
    raise exception 'Unsupported payment method.';
  end if;

  select slots.service_id, slots.starts_at, slots.capacity
  into v_service_id, v_starts_at, v_capacity
  from public.service_slots as slots
  join public.provider_services as services on services.id = slots.service_id
  where slots.id = p_slot_id
    and slots.is_active = true
    and slots.starts_at > now()
    and services.is_active = true
  for update of slots;

  if not found then
    raise exception 'That time slot is no longer available.';
  end if;

  select count(*) into v_booked_count
  from public.bookings
  where slot_id = p_slot_id
    and status in ('requested', 'confirmed', 'completed');

  if v_booked_count >= v_capacity then
    raise exception 'That time slot has just been taken. Please choose another.';
  end if;

  insert into public.bookings (
    owner_id, pet_id, service_id, slot_id, starts_at, status,
    payment_method, payment_status, notes
  ) values (
    auth.uid(), p_pet_id, v_service_id, p_slot_id, v_starts_at, 'requested',
    p_payment_method,
    case when p_payment_method = 'online' then 'pending' else 'unpaid' end,
    nullif(trim(coalesce(p_notes, '')), '')
  ) returning * into v_booking;

  return v_booking;
end;
$$;

revoke all on function public.create_booking(uuid, uuid, text, text) from public;
grant execute on function public.create_booking(uuid, uuid, text, text) to authenticated;

alter table public.profiles enable row level security;
alter table public.pets enable row level security;
alter table public.care_tasks enable row level security;
alter table public.service_providers enable row level security;
alter table public.provider_services enable row level security;
alter table public.service_slots enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using ((select auth.uid()) = id);
drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile" on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "manage own pets" on public.pets;
create policy "manage own pets" on public.pets for all to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
drop policy if exists "manage own care tasks" on public.care_tasks;
create policy "manage own care tasks" on public.care_tasks for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check (
    (select auth.uid()) = owner_id
    and exists (
      select 1 from public.pets
      where pets.id = care_tasks.pet_id and pets.owner_id = (select auth.uid())
    )
  );
drop policy if exists "public providers" on public.service_providers;
create policy "public providers" on public.service_providers for select to anon, authenticated using (true);
drop policy if exists "public active services" on public.provider_services;
create policy "public active services" on public.provider_services for select to anon, authenticated using (is_active = true);
drop policy if exists "public future service slots" on public.service_slots;
create policy "public future service slots" on public.service_slots for select to anon, authenticated using (is_active = true and starts_at > now());
drop policy if exists "manage own bookings" on public.bookings;
create policy "manage own bookings" on public.bookings for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check (
    (select auth.uid()) = owner_id
    and exists (
      select 1 from public.pets
      where pets.id = bookings.pet_id and pets.owner_id = (select auth.uid())
    )
    and exists (
      select 1 from public.provider_services
      where provider_services.id = bookings.service_id and provider_services.is_active = true
    )
  );
drop policy if exists "public reviews" on public.reviews;
create policy "public reviews" on public.reviews for select to anon, authenticated using (true);
drop policy if exists "review completed own booking" on public.reviews;
create policy "review completed own booking" on public.reviews for insert to authenticated
  with check (
    reviewer_id = (select auth.uid())
    and exists (
      select 1 from public.bookings
      where bookings.id = reviews.booking_id
        and bookings.owner_id = (select auth.uid())
        and bookings.service_id = reviews.service_id
        and bookings.status = 'completed'
    )
  );

-- Data API permissions are separate from RLS. Keep access narrowly scoped;
-- the policies above still decide which rows each caller can see or change.
grant usage on schema public to anon, authenticated;
grant select on public.service_providers, public.provider_services,
  public.service_slots, public.reviews to anon, authenticated;
grant select, insert, update, delete on public.profiles, public.pets,
  public.care_tasks, public.bookings to authenticated;
grant insert on public.reviews to authenticated;

-- Development catalogue for the Services tab. Replace or extend with verified partners.
insert into public.service_providers (id, name, city, address, phone, rating, is_verified)
values
  ('b2a14c19-9388-4b33-872e-7ea5fd8c6b31', 'Happy Paw Grooming', 'Petaling Jaya', 'SS2, Petaling Jaya', '+60 12-345 6789', 4.8, true),
  ('d3b25f20-a499-4e44-983f-8fb6ae9d7c42', 'Klinik Haiwan Damai', 'Kuala Lumpur', 'Taman Tun Dr Ismail, Kuala Lumpur', '+60 3-7722 8811', 4.7, true),
  ('e4c36a31-b5aa-4f55-a940-9ac7bf0e8d53', 'Paws & Rest Boarding', 'Shah Alam', 'Seksyen 13, Shah Alam', '+60 11-2040 5588', 4.6, true)
on conflict (id) do update set name = excluded.name, city = excluded.city, rating = excluded.rating, is_verified = excluded.is_verified;

insert into public.provider_services (id, provider_id, name, description, service_type, price, duration_minutes)
values
  ('76d317a2-80a3-45cd-9ac7-050b52f0f384', 'b2a14c19-9388-4b33-872e-7ea5fd8c6b31', 'Full grooming', 'Bath, coat trim, nail care and ear cleaning.', 'grooming', 80.00, 90),
  ('87e428b3-91b4-46de-abd8-161c6301a495', 'b2a14c19-9388-4b33-872e-7ea5fd8c6b31', 'Bath & brush', 'A gentle freshen-up for dogs and cats.', 'grooming', 45.00, 45),
  ('98f539c4-a2c5-47ef-bce9-272d7412b5a6', 'd3b25f20-a499-4e44-983f-8fb6ae9d7c42', 'Vet consultation', 'General wellness consultation with a registered vet.', 'grooming', 65.00, 30),
  ('a9064ad5-b3d6-48f0-cdfa-383e8523c6b7', 'e4c36a31-b5aa-4f55-a940-9ac7bf0e8d53', 'Overnight boarding', 'Cosy overnight stay with daily updates.', 'boarding', 95.00, 1440)
on conflict (id) do update set name = excluded.name, description = excluded.description, service_type = excluded.service_type, price = excluded.price, duration_minutes = excluded.duration_minutes;

insert into public.service_slots (service_id, starts_at, capacity)
select services.id,
       ((current_date + offsets.days_from_today + slots.time_of_day) at time zone 'Asia/Kuala_Lumpur'),
       1
from public.provider_services as services
cross join generate_series(1, 14) as offsets(days_from_today)
cross join (values (time '10:00'), (time '12:00'), (time '15:00'), (time '17:00')) as slots(time_of_day)
where services.is_active = true
  and extract(isodow from current_date + offsets.days_from_today) < 7
on conflict (service_id, starts_at) do nothing;
