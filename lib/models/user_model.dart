class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      profileImage: map['profileImage'],
    );
  }
}
