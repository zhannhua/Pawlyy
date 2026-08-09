-- Pawly Phase 1: secure customer and merchant workflows.
-- This migration is safe to apply to the existing pilot catalogue.

-- Support the service categories and care reminders promised in the Phase 1 plan.
alter table public.provider_services
  drop constraint if exists provider_services_service_type_check;
alter table public.provider_services
  add constraint provider_services_service_type_check
  check (service_type in ('grooming', 'boarding', 'veterinary'));

update public.provider_services
set service_type = 'veterinary'
where lower(name) like '%vet%'
  or lower(name) like '%klinik%';

alter table public.care_tasks
  drop constraint if exists care_tasks_category_check;
alter table public.care_tasks
  add constraint care_tasks_category_check
  check (category in ('meal', 'walk', 'medication', 'vaccination', 'care'));

alter table public.bookings
  drop constraint if exists bookings_status_check;
alter table public.bookings
  add constraint bookings_status_check
  check (status in ('requested', 'confirmed', 'completed', 'cancelled', 'declined'));

alter table public.service_providers
  add column if not exists description text not null default '',
  add column if not exists cover_url text not null default '',
  add column if not exists is_active boolean not null default true;

create index if not exists bookings_pet_id_idx on public.bookings(pet_id);
create index if not exists bookings_service_id_idx on public.bookings(service_id);
create index if not exists bookings_slot_id_idx on public.bookings(slot_id);
create index if not exists care_tasks_pet_id_idx on public.care_tasks(pet_id);
create index if not exists reviews_reviewer_id_idx on public.reviews(reviewer_id);
create index if not exists service_providers_merchant_id_idx on public.service_providers(merchant_id);

-- Private functions keep privileged work outside the public Data API schema.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;
grant usage on schema app_private to authenticated;

-- A new account always receives its own profile. This trigger is never callable
-- through the public API.
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
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
revoke all on function app_private.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_user();

-- Reviews always use the reviewer's verified Pawly profile name.
drop trigger if exists reviews_set_reviewer_name on public.reviews;
drop function if exists public.set_review_reviewer_name();
create or replace function app_private.set_review_reviewer_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.reviewer_name := coalesce(
    (select display_name from public.profiles where id = new.reviewer_id),
    'Verified pet parent'
  );
  return new;
end;
$$;
revoke all on function app_private.set_review_reviewer_name() from public, anon, authenticated;
create trigger reviews_set_reviewer_name
  before insert on public.reviews
  for each row execute function app_private.set_review_reviewer_name();

-- The locked implementation prevents double-booking, validates pet ownership,
-- and only permits active, verified partners to receive bookings.
create or replace function app_private.create_booking_internal(
  p_pet_id uuid,
  p_slot_id uuid,
  p_notes text default null,
  p_payment_method text default 'pay_at_venue'
)
returns public.bookings
language plpgsql
security definer
set search_path = ''
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
  join public.service_providers as providers on providers.id = services.provider_id
  where slots.id = p_slot_id
    and slots.is_active = true
    and slots.starts_at > now()
    and services.is_active = true
    and providers.is_active = true
    and providers.is_verified = true
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
revoke all on function app_private.create_booking_internal(uuid, uuid, text, text)
  from public, anon;
grant execute on function app_private.create_booking_internal(uuid, uuid, text, text)
  to authenticated;

create or replace function public.create_booking(
  p_pet_id uuid,
  p_slot_id uuid,
  p_notes text default null,
  p_payment_method text default 'pay_at_venue'
)
returns public.bookings
language sql
security invoker
set search_path = ''
as $$
  select app_private.create_booking_internal(
    p_pet_id,
    p_slot_id,
    p_notes,
    p_payment_method
  );
$$;
revoke all on function public.create_booking(uuid, uuid, text, text)
  from public, anon;
grant execute on function public.create_booking(uuid, uuid, text, text)
  to authenticated;

-- Customers can only cancel their own uncompleted booking. Status transitions
-- belong to dedicated database functions, never a browser-side table update.
create or replace function app_private.cancel_my_booking_internal(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_booking public.bookings;
begin
  update public.bookings
  set status = 'cancelled'
  where id = p_booking_id
    and owner_id = auth.uid()
    and status in ('requested', 'confirmed')
  returning * into v_booking;

  if not found then
    raise exception 'This booking can no longer be cancelled.';
  end if;
  return v_booking;
end;
$$;
revoke all on function app_private.cancel_my_booking_internal(uuid) from public, anon;
grant execute on function app_private.cancel_my_booking_internal(uuid) to authenticated;

create or replace function public.cancel_my_booking(p_booking_id uuid)
returns public.bookings
language sql
security invoker
set search_path = ''
as $$ select app_private.cancel_my_booking_internal(p_booking_id); $$;
revoke all on function public.cancel_my_booking(uuid) from public, anon;
grant execute on function public.cancel_my_booking(uuid) to authenticated;

-- Merchant status transitions are checked against the merchant-linked provider.
create or replace function app_private.update_provider_booking_internal(
  p_booking_id uuid,
  p_status text
)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current_status text;
  v_booking public.bookings;
begin
  select bookings.status into v_current_status
  from public.bookings
  join public.provider_services on provider_services.id = bookings.service_id
  join public.service_providers on service_providers.id = provider_services.provider_id
  where bookings.id = p_booking_id
    and service_providers.merchant_id = auth.uid()
  for update of bookings;

  if not found then
    raise exception 'This booking is not assigned to your provider.';
  end if;

  if not (
    (v_current_status = 'requested' and p_status in ('confirmed', 'declined'))
    or (v_current_status = 'confirmed' and p_status = 'completed')
  ) then
    raise exception 'That booking status change is not allowed.';
  end if;

  update public.bookings
  set status = p_status
  where id = p_booking_id
  returning * into v_booking;
  return v_booking;
end;
$$;
revoke all on function app_private.update_provider_booking_internal(uuid, text)
  from public, anon;
grant execute on function app_private.update_provider_booking_internal(uuid, text)
  to authenticated;

create or replace function public.update_provider_booking(
  p_booking_id uuid,
  p_status text
)
returns public.bookings
language sql
security invoker
set search_path = ''
as $$ select app_private.update_provider_booking_internal(p_booking_id, p_status); $$;
revoke all on function public.update_provider_booking(uuid, text) from public, anon;
grant execute on function public.update_provider_booking(uuid, text) to authenticated;

-- Merchant profile updates deliberately exclude verification status and the
-- merchant identity, which remain Pawly operations controls.
create or replace function app_private.update_my_provider_profile_internal(
  p_name text,
  p_city text,
  p_address text,
  p_phone text,
  p_description text,
  p_cover_url text
)
returns public.service_providers
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_provider public.service_providers;
begin
  update public.service_providers
  set name = nullif(trim(p_name), ''),
      city = nullif(trim(p_city), ''),
      address = nullif(trim(p_address), ''),
      phone = nullif(trim(p_phone), ''),
      description = coalesce(trim(p_description), ''),
      cover_url = coalesce(trim(p_cover_url), '')
  where merchant_id = auth.uid()
  returning * into v_provider;

  if not found then
    raise exception 'No merchant provider is linked to this account.';
  end if;
  return v_provider;
end;
$$;
revoke all on function app_private.update_my_provider_profile_internal(text, text, text, text, text, text)
  from public, anon;
grant execute on function app_private.update_my_provider_profile_internal(text, text, text, text, text, text)
  to authenticated;

create or replace function public.update_my_provider_profile(
  p_name text,
  p_city text,
  p_address text,
  p_phone text,
  p_description text,
  p_cover_url text
)
returns public.service_providers
language sql
security invoker
set search_path = ''
as $$
  select app_private.update_my_provider_profile_internal(
    p_name, p_city, p_address, p_phone, p_description, p_cover_url
  );
$$;
revoke all on function public.update_my_provider_profile(text, text, text, text, text, text)
  from public, anon;
grant execute on function public.update_my_provider_profile(text, text, text, text, text, text)
  to authenticated;

-- Public discovery shows only active, verified Pawly partners. Merchants keep
-- access to their own unpublished records for operational work.
drop policy if exists "public providers" on public.service_providers;
drop policy if exists "public verified active providers" on public.service_providers;
create policy "public verified active providers"
  on public.service_providers for select to anon, authenticated
  using (is_verified = true and is_active = true);
drop policy if exists "merchant read own provider" on public.service_providers;
create policy "merchant read own provider"
  on public.service_providers for select to authenticated
  using ((select auth.uid()) = merchant_id);

drop policy if exists "public active services" on public.provider_services;
create policy "public active services"
  on public.provider_services for select to anon, authenticated
  using (
    is_active = true
    and exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.is_verified = true
        and service_providers.is_active = true
    )
  );
drop policy if exists "merchant read own services" on public.provider_services;
create policy "merchant read own services"
  on public.provider_services for select to authenticated
  using (
    exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant add own services" on public.provider_services;
create policy "merchant add own services"
  on public.provider_services for insert to authenticated
  with check (
    exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant update own services" on public.provider_services;
create policy "merchant update own services"
  on public.provider_services for update to authenticated
  using (
    exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant delete own services" on public.provider_services;
create policy "merchant delete own services"
  on public.provider_services for delete to authenticated
  using (
    exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );

drop policy if exists "public future service slots" on public.service_slots;
create policy "public future service slots"
  on public.service_slots for select to anon, authenticated
  using (
    is_active = true
    and starts_at > now()
    and exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and provider_services.is_active = true
        and service_providers.is_verified = true
        and service_providers.is_active = true
    )
  );
drop policy if exists "merchant read own slots" on public.service_slots;
create policy "merchant read own slots"
  on public.service_slots for select to authenticated
  using (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant add own slots" on public.service_slots;
create policy "merchant add own slots"
  on public.service_slots for insert to authenticated
  with check (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant update own slots" on public.service_slots;
create policy "merchant update own slots"
  on public.service_slots for update to authenticated
  using (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
drop policy if exists "merchant delete own slots" on public.service_slots;
create policy "merchant delete own slots"
  on public.service_slots for delete to authenticated
  using (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );

-- Booking rows are read by their customer and the assigned provider only.
-- All changes happen through the narrow functions above.
drop policy if exists "manage own bookings" on public.bookings;
drop policy if exists "customer read own bookings" on public.bookings;
create policy "customer read own bookings"
  on public.bookings for select to authenticated
  using ((select auth.uid()) = owner_id);
drop policy if exists "merchant read assigned bookings" on public.bookings;
create policy "merchant read assigned bookings"
  on public.bookings for select to authenticated
  using (
    exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = bookings.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );

revoke insert, update, delete on public.bookings from authenticated;
grant select on public.bookings to authenticated;
grant select, insert, update, delete on public.provider_services,
  public.service_slots to authenticated;
