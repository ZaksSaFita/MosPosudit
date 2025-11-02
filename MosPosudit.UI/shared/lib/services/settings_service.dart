import 'dart:convert';
import '../api/api_client.dart';
import '../models/recommendation_settings.dart';

class SettingsService {
  final ApiClient _api;
  SettingsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// Gets the current recommendation settings
  Future<RecommendationSettingsModel> getRecommendationSettings() async {
    try {
      final res = await _api.get('/Settings/recommendations');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        print('Settings response: $decoded'); // Debug log
        return RecommendationSettingsModel.fromJson(decoded);
      }
      
      final errorBody = res.body;
      print('Settings error: ${res.statusCode} - $errorBody'); // Debug log
      throw Exception('Failed to fetch recommendation settings: ${res.statusCode} - $errorBody');
    } catch (e) {
      print('Settings service error: $e'); // Debug log
      rethrow;
    }
  }

  /// Updates the recommendation settings
  /// Only sends the weight parameters, not the full model
  Future<RecommendationSettingsModel> updateRecommendationSettings({
    required double homePopularWeight,
    required double homeContentBasedWeight,
    required double homeTopRatedWeight,
    required double cartFrequentlyBoughtWeight,
    required double cartSimilarToolsWeight,
  }) async {
    try {
      final body = {
        'homePopularWeight': homePopularWeight,
        'homeContentBasedWeight': homeContentBasedWeight,
        'homeTopRatedWeight': homeTopRatedWeight,
        'cartFrequentlyBoughtWeight': cartFrequentlyBoughtWeight,
        'cartSimilarToolsWeight': cartSimilarToolsWeight,
      };
      
      final res = await _api.put('/Settings/recommendations', body: body);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return RecommendationSettingsModel.fromJson(decoded);
      }
      
      // Try to parse error message
      String errorMessage = 'Failed to update recommendation settings: ${res.statusCode}';
      try {
        final error = jsonDecode(res.body);
        if (error is Map && error.containsKey('message')) {
          errorMessage = error['message'] as String;
        }
      } catch (_) {
        errorMessage = '${errorMessage} - ${res.body}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }
}

