class RecommendationSettingsModel {
  final int id;
  final double homePopularWeight;
  final double homeContentBasedWeight;
  final double homeTopRatedWeight;
  final double cartFrequentlyBoughtWeight;
  final double cartSimilarToolsWeight;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecommendationSettingsModel({
    required this.id,
    required this.homePopularWeight,
    required this.homeContentBasedWeight,
    required this.homeTopRatedWeight,
    required this.cartFrequentlyBoughtWeight,
    required this.cartSimilarToolsWeight,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecommendationSettingsModel.fromJson(Map<String, dynamic> json) {
    try {
      return RecommendationSettingsModel(
        id: json['id'] as int? ?? 0,
        homePopularWeight: (json['homePopularWeight'] ?? json['HomePopularWeight'] ?? 40.0) is num
            ? ((json['homePopularWeight'] ?? json['HomePopularWeight']) as num).toDouble()
            : 40.0,
        homeContentBasedWeight: (json['homeContentBasedWeight'] ?? json['HomeContentBasedWeight'] ?? 30.0) is num
            ? ((json['homeContentBasedWeight'] ?? json['HomeContentBasedWeight']) as num).toDouble()
            : 30.0,
        homeTopRatedWeight: (json['homeTopRatedWeight'] ?? json['HomeTopRatedWeight'] ?? 30.0) is num
            ? ((json['homeTopRatedWeight'] ?? json['HomeTopRatedWeight']) as num).toDouble()
            : 30.0,
        cartFrequentlyBoughtWeight: (json['cartFrequentlyBoughtWeight'] ?? json['CartFrequentlyBoughtWeight'] ?? 60.0) is num
            ? ((json['cartFrequentlyBoughtWeight'] ?? json['CartFrequentlyBoughtWeight']) as num).toDouble()
            : 60.0,
        cartSimilarToolsWeight: (json['cartSimilarToolsWeight'] ?? json['CartSimilarToolsWeight'] ?? 40.0) is num
            ? ((json['cartSimilarToolsWeight'] ?? json['CartSimilarToolsWeight']) as num).toDouble()
            : 40.0,
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.parse((json['createdAt'] as DateTime).toIso8601String()))
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? (json['updatedAt'] is String
                ? DateTime.parse(json['updatedAt'] as String)
                : DateTime.parse((json['updatedAt'] as DateTime).toIso8601String()))
            : DateTime.now(),
      );
    } catch (e) {
      // Return default settings if parsing fails
      return RecommendationSettingsModel(
        id: 0,
        homePopularWeight: 40.0,
        homeContentBasedWeight: 30.0,
        homeTopRatedWeight: 30.0,
        cartFrequentlyBoughtWeight: 60.0,
        cartSimilarToolsWeight: 40.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homePopularWeight': homePopularWeight,
      'homeContentBasedWeight': homeContentBasedWeight,
      'homeTopRatedWeight': homeTopRatedWeight,
      'cartFrequentlyBoughtWeight': cartFrequentlyBoughtWeight,
      'cartSimilarToolsWeight': cartSimilarToolsWeight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

