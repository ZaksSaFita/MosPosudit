import 'dart:convert';
import '../api/api_client.dart';
import '../models/tool.dart';
import 'auth_service.dart';

class RecommendationService {
  final ApiClient _api;
  
  RecommendationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ToolModel>> getHomeRecommendations({int count = 6}) async{
    try {
      final res = await _api.get('/Recommendation/home', query: {'count': count});
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((e) => ToolModel.fromJson(e)).toList();
        }
      }
      
      throw Exception('Failed to fetch home recommendations: ${res.statusCode}');
    } catch (e) {
      return [];
    }
  }

  Future<List<ToolModel>> getCartRecommendations(int toolId, {int count = 3}) async {
    try {
      final res = await _api.get('/Recommendation/cart/$toolId', query: {'count': count});
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((e) => ToolModel.fromJson(e)).toList();
        }
      }
      
      throw Exception('Failed to fetch cart recommendations: ${res.statusCode}');
    } catch (e) {
      return [];
    }
  }

}

