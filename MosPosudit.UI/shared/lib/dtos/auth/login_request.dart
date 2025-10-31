class LoginRequestDto {
  final String username;
  final String password;

  LoginRequestDto({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username, // Backend koristi camelCase
        'password': password,
      };
}

