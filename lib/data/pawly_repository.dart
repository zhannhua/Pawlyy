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
          'service_type, '
          'provider:service_providers(name, city, rating, is_verified)',
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
        .select('id, starts_at, capacity')
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
}
