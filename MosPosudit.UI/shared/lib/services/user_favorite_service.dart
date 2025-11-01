import 'dart:convert';
import '../api/api_client.dart';
import '../models/user_favorite.dart';
import '../dtos/user_favorite/user_favorite_insert_request.dart';
import 'auth_service.dart';

class UserFavoriteService {
  final ApiClient _api;
  UserFavoriteService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<UserFavoriteModel>> getFavorites({Map<String, dynamic>? query}) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Backend će automatski koristiti authenticated user ID
      final res = await _api.get('/UserFavorite', query: query);
      
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
        return data.map((e) => UserFavoriteModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch favorites: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in getFavorites: $e');
      rethrow;
    }
  }

  Future<UserFavoriteModel?> getById(int id) async {
    try {
      final res = await _api.get('/UserFavorite/$id');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return UserFavoriteModel.fromJson(decoded);
      }
      
      return null;
    } catch (e) {
      print('Error in getById: $e');
      return null;
    }
  }

  Future<bool> isFavorite(int toolId) async {
    try {
      final res = await _api.get('/UserFavorite/check/$toolId');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['isFavorite'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error in isFavorite: $e');
      return false;
    }
  }

  Future<UserFavoriteModel> addFavorite(UserFavoriteInsertRequestDto request) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final body = request.toJson();
      body['userId'] = userId; // Backend će override-ati sa authenticated user ID

      final res = await _api.post('/UserFavorite', body: body);
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return UserFavoriteModel.fromJson(decoded);
      }
      
      throw Exception('Failed to add favorite: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in addFavorite: $e');
      rethrow;
    }
  }

  Future<bool> removeFavorite(int toolId) async {
    try {
      final res = await _api.delete('/UserFavorite/tool/$toolId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print('Error in removeFavorite: $e');
      return false;
    }
  }
}

