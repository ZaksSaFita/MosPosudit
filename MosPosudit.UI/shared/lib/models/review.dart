class ReviewModel {
  final int id;
  final int userId;
  final String? userName;
  final int toolId;
  final String? toolName;
  final int rentalId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.toolId,
    this.toolName,
    required this.rentalId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
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

    return ReviewModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'],
      toolId: json['toolId'] as int,
      toolName: json['toolName'],
      rentalId: json['rentalId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'],
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'toolId': toolId,
        'toolName': toolName,
        'rentalId': rentalId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

