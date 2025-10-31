import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/tool.dart';
import '../models/category.dart';

class ToolService {
  final ApiClient _api;
  ToolService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ToolModel>> fetchTools({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Tool', query: query);
      print('Tool API Response Status: ${res.statusCode}');
      print('Tool API Response Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
      
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
          
          print('Parsed ${data.length} tools');
          final tools = data.map((e) {
            try {
              return ToolModel.fromJson(e);
            } catch (e) {
              print('Error parsing single tool: $e');
              print('Tool JSON: $e');
              rethrow;
            }
          }).toList();
          return tools;
        } catch (e, stackTrace) {
          print('Error parsing tools JSON: $e');
          print('Stack trace: $stackTrace');
          print('Response body: ${res.body}');
          rethrow;
        }
      }
      throw Exception('Failed to fetch tools: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in fetchTools: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ToolModel?> getById(int id) async {
    final res = await _api.get('/Tool/$id');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      // Handle both object and object wrapped in "value"
      if (decoded is Map && decoded.containsKey('value')) {
        return ToolModel.fromJson(decoded['value']);
      }
      return ToolModel.fromJson(decoded);
    }
    return null;
  }

  Future<ToolModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/Tool', body: data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('value')) {
        return ToolModel.fromJson(decoded['value']);
      }
      return ToolModel.fromJson(decoded);
    }
    throw Exception('Failed to create tool: ${res.statusCode} - ${res.body}');
  }

  Future<ToolModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/Tool/$id', body: data);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('value')) {
        return ToolModel.fromJson(decoded['value']);
      }
      return ToolModel.fromJson(decoded);
    }
    throw Exception('Failed to update tool: ${res.statusCode} - ${res.body}');
  }

  Future<bool> delete(int id) async {
    final res = await _api.delete('/Tool/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final res = await _api.get('/Category');
    if (res.statusCode == 200) {
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
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch categories');
  }
}

