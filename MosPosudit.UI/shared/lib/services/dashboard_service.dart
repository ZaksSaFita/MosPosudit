import 'dart:convert';
import '../api/api_client.dart';

class DashboardService {
  final ApiClient _api;
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<int> fetchToolsCount() async {
    final response = await _api.get('/Tool');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.length;
    }
    throw Exception('Failed to fetch tools count');
  }

  Future<int> fetchUsersCount() async {
    final response = await _api.get('/User');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.length;
    }
    throw Exception('Failed to fetch users count');
  }

  Future<int> fetchActiveRentalsCount() async {
    final response = await _api.get('/Rental', query: {'isActive': true});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.length;
    }
    throw Exception('Failed to fetch rentals count');
  }
}

