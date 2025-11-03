enum RecommendationEngine {
  ruleBased(0),
  machineLearning(1),
  hybrid(2);

  final int value;
  const RecommendationEngine(this.value);

  static RecommendationEngine fromInt(int value) {
    switch (value) {
      case 0:
        return RecommendationEngine.ruleBased;
      case 1:
        return RecommendationEngine.machineLearning;
      case 2:
        return RecommendationEngine.hybrid;
      default:
        return RecommendationEngine.ruleBased;
    }
  }

  String get displayName {
    switch (this) {
      case RecommendationEngine.ruleBased:
        return 'Rule-Based';
      case RecommendationEngine.machineLearning:
        return 'Machine Learning';
      case RecommendationEngine.hybrid:
        return 'Hybrid (ML + Fallback)';
    }
  }
}

class RecommendationSettingsModel {
  final int id;
  final RecommendationEngine engine;
  final int trainingIntervalDays;
  final DateTime? lastTrainingDate;
  final double homePopularWeight;
  final double homeContentBasedWeight;
  final double homeTopRatedWeight;
  final double cartFrequentlyBoughtWeight;
  final double cartSimilarToolsWeight;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecommendationSettingsModel({
    required this.id,
    required this.engine,
    required this.trainingIntervalDays,
    this.lastTrainingDate,
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
        engine: RecommendationEngine.fromInt(json['engine'] ?? json['Engine'] ?? 0),
        trainingIntervalDays: json['trainingIntervalDays'] ?? json['TrainingIntervalDays'] ?? 7,
        lastTrainingDate: json['lastTrainingDate'] != null || json['LastTrainingDate'] != null
            ? DateTime.parse((json['lastTrainingDate'] ?? json['LastTrainingDate']) as String)
            : null,
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
      return RecommendationSettingsModel(
        id: 0,
        engine: RecommendationEngine.ruleBased,
        trainingIntervalDays: 7,
        lastTrainingDate: null,
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
      'engine': engine.value,
      'trainingIntervalDays': trainingIntervalDays,
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

