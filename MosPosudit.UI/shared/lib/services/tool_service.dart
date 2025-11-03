import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/tool.dart';
import '../models/category.dart';
import '../models/tool_availability.dart';

class ToolService {
  final ApiClient _api;
  ToolService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ToolModel>> fetchTools({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Tool', query: query, auth: false);
      
      if (res.statusCode == 200) {
        try {
          final decoded = jsonDecode(res.body);
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
              return ToolModel.fromJson(e);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } catch (e, stackTrace) {
          rethrow;
        }
      }
      throw Exception('Failed to fetch tools: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<ToolModel?> getById(int id) async {
    final res = await _api.get('/Tool/$id', auth: false);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return ToolModel.fromJson(decoded);
    }
    return null;
  }

  Future<ToolModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/Tool', body: data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return ToolModel.fromJson(decoded);
    }
    throw Exception('Failed to create tool: ${res.statusCode} - ${res.body}');
  }

  Future<ToolModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/Tool/$id', body: data);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return ToolModel.fromJson(decoded);
    }
    throw Exception('Failed to update tool: ${res.statusCode} - ${res.body}');
  }

  Future<bool> delete(int id) async {
    final res = await _api.delete('/Tool/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final res = await _api.get('/Category', auth: false);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> data;
      if (decoded is Map && decoded.containsKey('items')) {
        data = decoded['items'] as List<dynamic>;
      } else if (decoded is List) {
        data = decoded;
      } else {
        throw Exception('Unexpected response format: $decoded');
      }
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch categories');
  }

  Future<ToolAvailabilityModel?> getAvailability(
    int toolId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final queryParams = {
        'startDate': startDateStr,
        'endDate': endDateStr,
      };

      final res = await _api.get('/Tool/$toolId/availability', query: queryParams, auth: false);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return ToolAvailabilityModel.fromJson(decoded);
      } else if (res.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch availability: ${res.statusCode} - ${res.body}');
    } catch (e) {
      rethrow;
    }
  }
}

