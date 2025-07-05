class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? birthdate;
  final String? picture;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.birthdate,
    this.picture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      birthdate: json['birthdate'],
      picture: json['picture'],
    );
  }
} 