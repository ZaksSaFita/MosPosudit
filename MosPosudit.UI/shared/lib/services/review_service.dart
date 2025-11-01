import 'dart:convert';
import '../api/api_client.dart';
import '../models/review.dart';
import '../dtos/review/review_insert_request.dart';
import '../dtos/review/review_update_request.dart';
import 'auth_service.dart';

class ReviewService {
  final ApiClient _api;
  ReviewService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ReviewModel>> getReviews({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Review', query: query, auth: false);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Backend vraća PagedResult<T> sa items i totalCount
        final List<dynamic> data;
        if (decoded is Map && decoded.containsKey('items')) {
          data = decoded['items'] as List<dynamic>;
        } else if (decoded is List) {
          data = decoded;
        } else {
          throw Exception('Unexpected response format: $decoded');
        }
        return data.map((e) => ReviewModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch reviews: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in getReviews: $e');
      rethrow;
    }
  }

  Future<ReviewModel?> getById(int id) async {
    try {
      final res = await _api.get('/Review/$id', auth: false);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return ReviewModel.fromJson(decoded);
      }
      
      return null;
    } catch (e) {
      print('Error in getById: $e');
      return null;
    }
  }

  Future<List<ReviewModel>> getByToolId(int toolId) async {
    try {
      final res = await _api.get('/Review/tool/$toolId', auth: false);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Backend vraća direktno listu za tool/{toolId} endpoint
        final List<dynamic> data = decoded is List 
            ? decoded 
            : [];
        return data.map((e) => ReviewModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch reviews by tool: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in getByToolId: $e');
      rethrow;
    }
  }

  Future<ReviewModel> createReview(ReviewInsertRequestDto request) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final body = request.toJson();
      body['userId'] = userId; // Backend će override-ati sa authenticated user ID

      final res = await _api.post('/Review', body: body);
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return ReviewModel.fromJson(decoded);
      }
      
      throw Exception('Failed to create review: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in createReview: $e');
      rethrow;
    }
  }

  Future<ReviewModel> updateReview(int id, ReviewUpdateRequestDto request) async {
    try {
      final res = await _api.put('/Review/$id', body: request.toJson());
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return ReviewModel.fromJson(decoded);
      }
      
      throw Exception('Failed to update review: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in updateReview: $e');
      rethrow;
    }
  }

  Future<bool> deleteReview(int id) async {
    try {
      final res = await _api.delete('/Review/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print('Error in deleteReview: $e');
      return false;
    }
  }
}

