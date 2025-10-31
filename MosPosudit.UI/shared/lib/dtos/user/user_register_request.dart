class UserRegisterRequestDto {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String username;
  final String password;

  UserRegisterRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'username': username,
        'password': password,
      };
}

