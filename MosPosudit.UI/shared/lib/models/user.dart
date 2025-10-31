class UserModel {
  final int id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? roleName;
  final int? roleId;
  final String? pictureBase64;
  final String? birthdate;

  UserModel({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.roleName,
    this.roleId,
    this.pictureBase64,
    this.birthdate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      roleName: json['roleName'] ?? json['role'],
      roleId: json['roleId'],
      pictureBase64: json['picture'],
      birthdate: json['birthdate'],
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
      };
}

