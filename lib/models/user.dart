enum UserType { blind, volunteer }

class User {
  final String id;
  final String name;
  final String email;
  final UserType userType;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
    );
  }

  // For Firestore serialization/deserialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isBlind': userType == UserType.blind,
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: map['isBlind'] == true ? UserType.blind : UserType.volunteer,
    );
  }
}
