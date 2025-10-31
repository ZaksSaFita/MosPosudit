import '../../models/user.dart';

class UserResponseDto {
  final UserModel user;

  UserResponseDto({required this.user});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      UserResponseDto(user: UserModel.fromJson(json));
}

