class ChangePasswordRequestDto {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

