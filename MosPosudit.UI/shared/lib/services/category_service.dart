import 'dart:convert';
import '../api/api_client.dart';
import '../models/category.dart';

class CategoryService {
  final ApiClient _api;
  CategoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<CategoryModel>> fetchCategories({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Category', query: query);
      print('Category API Response Status: ${res.statusCode}');
      print('Category API Response Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
      
      if (res.statusCode == 200) {
        try {
          final decoded = jsonDecode(res.body);
          // Handle both array and object with "value" property
          final List<dynamic> data;
          if (decoded is List) {
            data = decoded;
          } else if (decoded is Map && decoded.containsKey('value')) {
            data = decoded['value'] as List<dynamic>;
          } else {
            throw Exception('Unexpected response format: $decoded');
          }
          
          print('Parsed ${data.length} categories');
          final categories = data.map((e) {
            try {
              return CategoryModel.fromJson(e);
            } catch (e) {
              print('Error parsing single category: $e');
              print('Category JSON: $e');
              rethrow;
            }
          }).toList();
          return categories;
        } catch (e, stackTrace) {
          print('Error parsing categories JSON: $e');
          print('Stack trace: $stackTrace');
          print('Response body: ${res.body}');
          rethrow;
        }
      }
      throw Exception('Failed to fetch categories: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in fetchCategories: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<CategoryModel?> getById(int id) async {
    final res = await _api.get('/Category/$id');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      // Handle both object and object wrapped in "value"
      if (decoded is Map && decoded.containsKey('value')) {
        return CategoryModel.fromJson(decoded['value']);
      }
      return CategoryModel.fromJson(decoded);
    }
    return null;
  }

  Future<CategoryModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/Category', body: data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('value')) {
        return CategoryModel.fromJson(decoded['value']);
      }
      return CategoryModel.fromJson(decoded);
    }
    throw Exception('Failed to create category: ${res.statusCode} - ${res.body}');
  }

  Future<CategoryModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/Category/$id', body: data);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('value')) {
        return CategoryModel.fromJson(decoded['value']);
      }
      return CategoryModel.fromJson(decoded);
    }
    throw Exception('Failed to update category: ${res.statusCode} - ${res.body}');
  }

  Future<bool> delete(int id) async {
    final res = await _api.delete('/Category/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }
}

