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
      'birthday': birthday.toIso8601String(),
      'weight': weight,
      'imageUrl': imageUrl,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      gender: map['gender'],
      birthday: DateTime.parse(map['birthday']),
      weight: map['weight'].toDouble(),
      imageUrl: map['imageUrl'],
    );
  }
}
