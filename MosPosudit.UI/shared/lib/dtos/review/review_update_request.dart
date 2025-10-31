class ReviewUpdateRequestDto {
  final int rating;
  final String? comment;

  ReviewUpdateRequestDto({
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
      };
}

