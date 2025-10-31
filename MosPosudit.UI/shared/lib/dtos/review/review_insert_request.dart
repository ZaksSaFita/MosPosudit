class ReviewInsertRequestDto {
  final int toolId;
  final int rentalId;
  final int rating;
  final String? comment;

  ReviewInsertRequestDto({
    required this.toolId,
    required this.rentalId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'rentalId': rentalId,
        'rating': rating,
        'comment': comment,
      };
}

