class LoginResponseDto {
  final String token;
  final int? userId;

  LoginResponseDto({
    required this.token,
    this.userId,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(
        token: json['token'] as String,
        userId: json['userId'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
      };
}

