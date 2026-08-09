-- Merchant accounts need a deliberately narrow operational view of the
-- bookings assigned to their own provider. Customer profiles stay private.

create or replace function app_private.merchant_booking_details_internal()
returns table(
  id uuid,
  starts_at timestamptz,
  status text,
  notes text,
  customer_name text,
  pet_name text,
  pet_species text,
  service_name text
)
language sql
security definer
set search_path = ''
as $$
  select
    bookings.id,
    bookings.starts_at,
    bookings.status,
    coalesce(bookings.notes, ''),
    coalesce(profiles.display_name, 'Pet parent'),
    pets.name,
    pets.species,
    provider_services.name
  from public.bookings
  join public.provider_services on provider_services.id = bookings.service_id
  join public.service_providers
    on service_providers.id = provider_services.provider_id
  join public.pets on pets.id = bookings.pet_id
  left join public.profiles on profiles.id = bookings.owner_id
  where service_providers.merchant_id = auth.uid()
  order by bookings.starts_at;
$$;
revoke all on function app_private.merchant_booking_details_internal()
  from public, anon;
grant execute on function app_private.merchant_booking_details_internal()
  to authenticated;

create or replace function public.get_merchant_bookings()
returns table(
  id uuid,
  starts_at timestamptz,
  status text,
  notes text,
  customer_name text,
  pet_name text,
  pet_species text,
  service_name text
)
language sql
security invoker
set search_path = ''
as $$
  select * from app_private.merchant_booking_details_internal();
$$;
revoke all on function public.get_merchant_bookings() from public, anon;
grant execute on function public.get_merchant_bookings() to authenticated;
