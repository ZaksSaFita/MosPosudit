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
        // Backend returns PagedResult<T> with items and totalCount
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
      return null;
    }
  }

  Future<List<ReviewModel>> getByToolId(int toolId) async {
    try {
      final res = await _api.get('/Review/tool/$toolId', auth: false);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Backend returns list directly for tool/{toolId} endpoint
        final List<dynamic> data = decoded is List 
            ? decoded 
            : [];
        return data.map((e) => ReviewModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch reviews by tool: ${res.statusCode} - ${res.body}');
    } catch (e) {
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
      body['userId'] = userId;

      final res = await _api.post('/Review', body: body);
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return ReviewModel.fromJson(decoded);
      }
      
      // Try to extract error message from response body
      String errorMessage = 'Failed to create review';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        } else if (decoded is Map && decoded.containsKey('error')) {
          errorMessage = decoded['error'].toString();
        } else if (decoded is String) {
          errorMessage = decoded;
        } else {
          errorMessage = res.body.isNotEmpty ? res.body : errorMessage;
        }
      } catch (_) {
        // If parsing fails, use body as is
        errorMessage = res.body.isNotEmpty ? res.body : errorMessage;
      }
      
      throw Exception(errorMessage);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<bool> deleteReview(int id) async {
    try {
      final res = await _api.delete('/Review/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}

