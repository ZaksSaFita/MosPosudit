import 'dart:convert';
import '../api/api_client.dart';
import '../models/category.dart';

class CategoryService {
  final ApiClient _api;
  CategoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<CategoryModel>> fetchCategories({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Category', query: query, auth: false);
      
      if (res.statusCode == 200) {
        try {
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
          
          return data.map((e) {
            try {
              return CategoryModel.fromJson(e);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } catch (e, stackTrace) {
          rethrow;
        }
      }
      throw Exception('Failed to fetch categories: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<CategoryModel?> getById(int id) async {
    final res = await _api.get('/Category/$id', auth: false);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return CategoryModel.fromJson(decoded);
    }
    return null;
  }

  Future<CategoryModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/Category', body: data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return CategoryModel.fromJson(decoded);
    }
    throw Exception('Failed to create category: ${res.statusCode} - ${res.body}');
  }

  Future<CategoryModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/Category/$id', body: data);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return CategoryModel.fromJson(decoded);
    }
    throw Exception('Failed to update category: ${res.statusCode} - ${res.body}');
  }

  Future<bool> delete(int id) async {
    final res = await _api.delete('/Category/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }
}

