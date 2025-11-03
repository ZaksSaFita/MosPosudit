class UserUpdateRequestDto {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? picture;
  final String? password;
  final int? roleId;

  UserUpdateRequestDto({
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phoneNumber,
    this.picture,
    this.password,
    this.roleId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (username != null) json['username'] = username;
    if (email != null) json['email'] = email;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (picture != null) json['picture'] = picture;
    if (password != null) json['password'] = password;
    if (roleId != null) json['roleId'] = roleId;
    return json;
  }
}

