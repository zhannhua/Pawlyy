class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final DateTime birthday;
  final double weight;
  final String imageUrl;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthday,
    required this.weight,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'birth_date': birthday.toIso8601String().split('T').first,
      'weight': weight,
      'image_url': imageUrl,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String? ?? 'Dog',
      breed: map['breed'] as String? ?? 'Mixed breed',
      gender: map['gender'] as String? ?? 'Unknown',
      birthday:
          DateTime.tryParse(
            (map['birth_date'] ?? map['birthday'] ?? '').toString(),
          ) ??
          DateTime.now(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      imageUrl: (map['image_url'] ?? map['imageUrl'] ?? '') as String,
    );
  }
}
