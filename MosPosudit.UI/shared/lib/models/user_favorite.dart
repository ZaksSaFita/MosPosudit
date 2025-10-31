class UserFavoriteModel {
  final int id;
  final int userId;
  final int toolId;
  final String? toolName;
  final String? toolDescription;
  final num? toolDailyRate;
  final String? toolImageBase64;
  final DateTime createdAt;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.toolId,
    this.toolName,
    this.toolDescription,
    this.toolDailyRate,
    this.toolImageBase64,
    required this.createdAt,
  });

  factory UserFavoriteModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return UserFavoriteModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      toolId: json['toolId'] as int,
      toolName: json['toolName'],
      toolDescription: json['toolDescription'],
      toolDailyRate: json['toolDailyRate'] != null ? (json['toolDailyRate'] as num) : null,
      toolImageBase64: json['toolImageBase64'],
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'toolId': toolId,
        'toolName': toolName,
        'toolDescription': toolDescription,
        'toolDailyRate': toolDailyRate,
        'toolImageBase64': toolImageBase64,
        'createdAt': createdAt.toIso8601String(),
      };
}

