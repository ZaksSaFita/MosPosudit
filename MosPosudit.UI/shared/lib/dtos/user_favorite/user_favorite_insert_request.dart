class UserFavoriteInsertRequestDto {
  final int toolId;

  UserFavoriteInsertRequestDto({
    required this.toolId,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
      };
}

