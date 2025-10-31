class NotificationModel {
  final int id;
  final int userId;
  final String? title;
  final String? message;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.title,
    this.message,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
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

    return NotificationModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['isRead'] ?? false,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}

