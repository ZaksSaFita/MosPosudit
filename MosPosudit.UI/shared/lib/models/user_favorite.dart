class UserFavoriteModel {
  final int id;
  final int userId;
  final int toolId;
  final DateTime createdAt;
  final String? notes;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.toolId,
    required this.createdAt,
    this.notes,
  });

  factory UserFavoriteModel.fromJson(Map<String, dynamic> json) => UserFavoriteModel(
        id: json['id'],
        userId: json['userId'],
        toolId: json['toolId'],
        createdAt: DateTime.parse(json['createdAt']),
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'toolId': toolId,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };
}

