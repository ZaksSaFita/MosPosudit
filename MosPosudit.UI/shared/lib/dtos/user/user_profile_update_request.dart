class UserProfileUpdateRequestDto {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? picture;

  UserProfileUpdateRequestDto({
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phoneNumber,
    this.picture,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (username != null) json['username'] = username;
    if (email != null) json['email'] = email;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (picture != null) json['picture'] = picture;
    return json;
  }
}

