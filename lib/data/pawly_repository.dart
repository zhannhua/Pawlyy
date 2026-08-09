import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pawly_models.dart';
import '../models/pet_model.dart';

class PawlyRepository {
  PawlyRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Please sign in again.');
    return id;
  }

  Future<UserProfile?> getProfile() async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .maybeSingle();
    return result == null ? null : UserProfile.fromMap(result);
  }

  Future<void> saveProfile(UserProfile profile) =>
      _client.from('profiles').upsert(profile.toMap());

  Future<List<Pet>> getPets() async {
    final result = await _client
        .from('pets')
        .select()
        .eq('owner_id', _userId)
        .order('created_at');
    return (result as List)
        .map((row) => Pet.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Pet> addPet(Pet pet) async {
    final payload = pet.toMap()
      ..remove('id')
      ..['owner_id'] = _userId;
    final result = await _client.from('pets').insert(payload).select().single();
    return Pet.fromMap(result);
  }

  Future<Pet> updatePet(Pet pet) async {
    final result = await _client
        .from('pets')
        .update(pet.toMap()..remove('owner_id'))
        .eq('id', pet.id)
        .eq('owner_id', _userId)
        .select()
        .single();
    return Pet.fromMap(result);
  }

  Future<void> deletePet(String petId) =>
      _client.from('pets').delete().eq('id', petId).eq('owner_id', _userId);

  Future<List<CareTask>> getTodaysTasks() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final result = await _client
        .from('care_tasks')
        .select()
        .eq('owner_id', _userId)
        .gte('due_at', start.toUtc().toIso8601String())
        .lt('due_at', end.toUtc().toIso8601String())
        .order('due_at');
    return (result as List)
        .map((row) => CareTask.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> addCareTask({
    required String petId,
    required String title,
    required String category,
    required DateTime dueAt,
  }) {
    return _client.from('care_tasks').insert({
      'owner_id': _userId,
      'pet_id': petId,
      'title': title.trim(),
      'category': category,
      'due_at': dueAt.toUtc().toIso8601String(),
    });
  }

  Future<void> setTaskCompleted(String taskId, bool isCompleted) {
    return _client
        .from('care_tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId)
        .eq('owner_id', _userId);
  }

  Future<List<ServiceListing>> getServices() async {
    final result = await _client
        .from('provider_services')
        .select(
          'id, name, description, price, duration_minutes, '
          'service_type, provider_id, '
          'provider:service_providers(name, city, address, rating, is_verified, '
          'description, cover_url)',
        )
        .order('name');
    return (result as List)
        .map(
          (row) =>
              ServiceListing.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> createBooking({
    required String petId,
    required String slotId,
    String? notes,
    String paymentMethod = 'pay_at_venue',
  }) {
    return _client.rpc(
      'create_booking',
      params: {
        'p_pet_id': petId,
        'p_slot_id': slotId,
        'p_notes': notes?.trim(),
        'p_payment_method': paymentMethod,
      },
    );
  }

  Future<void> cancelBooking(String bookingId) =>
      _client.rpc('cancel_my_booking', params: {'p_booking_id': bookingId});

  Future<List<PawlyBooking>> getBookings() async {
    final result = await _client
        .from('bookings')
        .select(
          'id, service_id, starts_at, status, payment_status, '
          'service:provider_services(name, provider:service_providers(name)), '
          'reviews(id)',
        )
        .eq('owner_id', _userId)
        .order('starts_at', ascending: false)
        .limit(8);
    return (result as List)
        .map(
          (row) => PawlyBooking.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<ServiceSlot>> getAvailableSlots(String serviceId) async {
    final result = await _client
        .from('service_slots')
        .select('id, starts_at, capacity, is_active')
        .eq('service_id', serviceId)
        .eq('is_active', true)
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(90);
    return (result as List)
        .map(
          (row) => ServiceSlot.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<ServiceReview>> getServiceReviews(String serviceId) async {
    final result = await _client
        .from('reviews')
        .select('id, rating, comment, reviewer_name, created_at')
        .eq('service_id', serviceId)
        .order('created_at', ascending: false)
        .limit(5);
    return (result as List)
        .map(
          (row) => ServiceReview.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> submitReview({
    required String bookingId,
    required String serviceId,
    required int rating,
    required String comment,
  }) {
    return _client.from('reviews').insert({
      'booking_id': bookingId,
      'service_id': serviceId,
      'reviewer_id': _userId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  Future<ProviderProfile?> getMerchantProvider() async {
    final result = await _client
        .from('service_providers')
        .select(
          'id, name, city, address, phone, rating, is_verified, is_active, '
          'description, cover_url',
        )
        .eq('merchant_id', _userId)
        .maybeSingle();
    return result == null ? null : ProviderProfile.fromMap(result);
  }

  Future<List<ServiceListing>> getMerchantServices(String providerId) async {
    final result = await _client
        .from('provider_services')
        .select(
          'id, name, description, price, duration_minutes, service_type, '
          'provider_id, is_active, '
          'provider:service_providers(name, city, address, rating, is_verified, '
          'description, cover_url)',
        )
        .eq('provider_id', providerId)
        .order('name');
    return (result as List)
        .map(
          (row) =>
              ServiceListing.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> saveMerchantService({
    String? id,
    required String providerId,
    required String name,
    required String description,
    required String serviceType,
    required num price,
    required int durationMinutes,
    required bool isActive,
  }) async {
    final payload = {
      'provider_id': providerId,
      'name': name.trim(),
      'description': description.trim(),
      'service_type': serviceType,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('provider_services').insert(payload);
    } else {
      await _client.from('provider_services').update(payload).eq('id', id);
    }
  }

  Future<void> deleteMerchantService(String serviceId) =>
      _client.from('provider_services').delete().eq('id', serviceId);

  Future<List<ServiceSlot>> getMerchantSlots(String serviceId) async {
    final result = await _client
        .from('service_slots')
        .select('id, starts_at, capacity, is_active')
        .eq('service_id', serviceId)
        .order('starts_at')
        .limit(100);
    return (result as List)
        .map(
          (row) => ServiceSlot.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> addMerchantSlot({
    required String serviceId,
    required DateTime startsAt,
    required int capacity,
  }) => _client.from('service_slots').insert({
    'service_id': serviceId,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'capacity': capacity,
    'is_active': true,
  });

  Future<void> setMerchantSlotActive(String slotId, bool isActive) => _client
      .from('service_slots')
      .update({'is_active': isActive})
      .eq('id', slotId);

  Future<List<MerchantBooking>> getMerchantBookings() async {
    final result = await _client.rpc('get_merchant_bookings');
    return (result as List)
        .map(
          (row) =>
              MerchantBooking.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> updateMerchantBooking({
    required String bookingId,
    required String status,
  }) => _client.rpc(
    'update_provider_booking',
    params: {'p_booking_id': bookingId, 'p_status': status},
  );

  Future<void> updateMerchantProvider({
    required String name,
    required String city,
    required String address,
    required String phone,
    required String description,
    required String coverUrl,
  }) => _client.rpc(
    'update_my_provider_profile',
    params: {
      'p_name': name,
      'p_city': city,
      'p_address': address,
      'p_phone': phone,
      'p_description': description,
      'p_cover_url': coverUrl,
    },
  );
}
