class ReviewInsertRequestDto {
  final int toolId;
  final int rating;
  final String? comment;

  ReviewInsertRequestDto({
    required this.toolId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'rating': rating,
        'comment': comment,
      };
}

