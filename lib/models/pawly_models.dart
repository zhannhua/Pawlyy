class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.city,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String phone;
  final String city;
  final String? avatarUrl;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    displayName: (map['display_name'] ?? '') as String,
    phone: (map['phone'] ?? '') as String,
    city: (map['city'] ?? 'Kuala Lumpur') as String,
    avatarUrl: map['avatar_url'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'display_name': displayName,
    'phone': phone,
    'city': city,
    'avatar_url': avatarUrl,
  };
}

class CareTask {
  const CareTask({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    required this.dueAt,
    required this.isCompleted,
  });

  final String id;
  final String petId;
  final String title;
  final String category;
  final DateTime dueAt;
  final bool isCompleted;

  factory CareTask.fromMap(Map<String, dynamic> map) => CareTask(
    id: map['id'] as String,
    petId: map['pet_id'] as String,
    title: map['title'] as String,
    category: (map['category'] ?? 'care') as String,
    dueAt: DateTime.parse(map['due_at'] as String).toLocal(),
    isCompleted: (map['is_completed'] ?? false) as bool,
  );
}

class ServiceListing {
  const ServiceListing({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.price,
    required this.durationMinutes,
    required this.providerName,
    required this.city,
    required this.rating,
    required this.isVerified,
  });

  final String id;
  final String name;
  final String description;
  final String serviceType;
  final num price;
  final int durationMinutes;
  final String providerName;
  final String city;
  final num rating;
  final bool isVerified;

  factory ServiceListing.fromMap(Map<String, dynamic> map) {
    final rawProvider = map['provider'] ?? map['service_providers'];
    final provider = rawProvider is Map
        ? Map<String, dynamic>.from(rawProvider)
        : const <String, dynamic>{};
    return ServiceListing(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] ?? '') as String,
      serviceType: (map['service_type'] ?? 'grooming') as String,
      price: (map['price'] as num?) ?? 0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 60,
      providerName: (provider['name'] ?? 'Pawly partner') as String,
      city: (provider['city'] ?? 'Kuala Lumpur') as String,
      rating: (provider['rating'] as num?) ?? 0,
      isVerified: (provider['is_verified'] ?? false) as bool,
    );
  }
}

class ServiceSlot {
  const ServiceSlot({
    required this.id,
    required this.startsAt,
    required this.capacity,
  });

  final String id;
  final DateTime startsAt;
  final int capacity;

  factory ServiceSlot.fromMap(Map<String, dynamic> map) => ServiceSlot(
    id: map['id'] as String,
    startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
    capacity: (map['capacity'] as num?)?.toInt() ?? 1,
  );
}

class ServiceReview {
  const ServiceReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime createdAt;

  factory ServiceReview.fromMap(Map<String, dynamic> map) => ServiceReview(
    id: map['id'] as String,
    rating: (map['rating'] as num).toInt(),
    comment: (map['comment'] ?? '') as String,
    reviewerName: (map['reviewer_name'] ?? 'Verified pet parent') as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class PawlyBooking {
  const PawlyBooking({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.providerName,
    required this.startsAt,
    required this.status,
    required this.paymentStatus,
    required this.hasReview,
  });

  final String id;
  final String serviceId;
  final String serviceName;
  final String providerName;
  final DateTime startsAt;
  final String status;
  final String paymentStatus;
  final bool hasReview;

  factory PawlyBooking.fromMap(Map<String, dynamic> map) {
    final rawService = map['service'] ?? map['provider_services'];
    final service = rawService is Map
        ? Map<String, dynamic>.from(rawService)
        : const <String, dynamic>{};
    final rawProvider = service['provider'] ?? service['service_providers'];
    final provider = rawProvider is Map
        ? Map<String, dynamic>.from(rawProvider)
        : const <String, dynamic>{};
    final rawReviews = map['reviews'];
    final hasReview = rawReviews is List
        ? rawReviews.isNotEmpty
        : rawReviews is Map;
    return PawlyBooking(
      id: map['id'] as String,
      serviceId: map['service_id'] as String,
      serviceName: (service['name'] ?? 'Pawly service') as String,
      providerName: (provider['name'] ?? 'Pawly partner') as String,
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
      status: (map['status'] ?? 'requested') as String,
      paymentStatus: (map['payment_status'] ?? 'unpaid') as String,
      hasReview: hasReview,
    );
  }
}
