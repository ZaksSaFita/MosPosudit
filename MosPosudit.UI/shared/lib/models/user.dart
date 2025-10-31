class UserModel {
  final int id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? roleName;
  final int roleId;
  final String? pictureBase64;
  final String? birthdate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.roleName,
    required this.roleId,
    this.pictureBase64,
    this.birthdate,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return UserModel(
      id: json['id'] as int,
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      roleName: json['roleName'] ?? json['role'],
      roleId: json['roleId'] as int? ?? 0,
      pictureBase64: json['picture'],
      birthdate: json['birthdate'],
      isActive: json['isActive'] ?? true,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastLogin: parseDateTime(json['lastLogin']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'roleName': roleName,
        'roleId': roleId,
        'picture': pictureBase64,
        'birthdate': birthdate,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };
}

