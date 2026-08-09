-- Keep the Phase 1 RLS rules fast by using one read policy per table/role.
-- The access conditions remain the same as the preceding security migration.

drop policy if exists "public verified active providers" on public.service_providers;
drop policy if exists "merchant read own provider" on public.service_providers;
create policy "read public providers and merchant own"
  on public.service_providers for select to anon, authenticated
  using (
    (is_verified = true and is_active = true)
    or ((select auth.uid()) = merchant_id)
  );

drop policy if exists "public active services" on public.provider_services;
drop policy if exists "merchant read own services" on public.provider_services;
create policy "read public services and merchant own"
  on public.provider_services for select to anon, authenticated
  using (
    (
      is_active = true
      and exists (
        select 1 from public.service_providers
        where service_providers.id = provider_services.provider_id
          and service_providers.is_verified = true
          and service_providers.is_active = true
      )
    )
    or exists (
      select 1 from public.service_providers
      where service_providers.id = provider_services.provider_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );

drop policy if exists "public future service slots" on public.service_slots;
drop policy if exists "merchant read own slots" on public.service_slots;
create policy "read public slots and merchant own"
  on public.service_slots for select to anon, authenticated
  using (
    (
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
    )
    or exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = service_slots.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );

drop policy if exists "customer read own bookings" on public.bookings;
drop policy if exists "merchant read assigned bookings" on public.bookings;
create policy "read customer or merchant booking"
  on public.bookings for select to authenticated
  using (
    (select auth.uid()) = owner_id
    or exists (
      select 1
      from public.provider_services
      join public.service_providers
        on service_providers.id = provider_services.provider_id
      where provider_services.id = bookings.service_id
        and service_providers.merchant_id = (select auth.uid())
    )
  );
