import 'dart:convert';
import '../api/api_client.dart';

class DashboardService {
  final ApiClient _api;
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<int> fetchToolsCount() async {
    final response = await _api.get('/Tool');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Handle PagedResult or direct list
      if (decoded is Map && decoded.containsKey('items')) {
        return (decoded['items'] as List).length;
      } else if (decoded is Map && decoded.containsKey('totalCount')) {
        return decoded['totalCount'] as int;
      } else if (decoded is List) {
        return decoded.length;
      }
      return 0;
    }
    throw Exception('Failed to fetch tools count');
  }

  Future<int> fetchUsersCount() async {
    final response = await _api.get('/User');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Handle PagedResult or direct list
      if (decoded is Map && decoded.containsKey('items')) {
        return (decoded['items'] as List).length;
      } else if (decoded is Map && decoded.containsKey('totalCount')) {
        return decoded['totalCount'] as int;
      } else if (decoded is List) {
        return decoded.length;
      }
      return 0;
    }
    throw Exception('Failed to fetch users count');
  }

  Future<int> fetchActiveRentalsCount() async {
    final response = await _api.get('/Order', query: {'isReturned': 'false'});
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Handle PagedResult or direct list
      if (decoded is Map && decoded.containsKey('items')) {
        return (decoded['items'] as List).length;
      } else if (decoded is Map && decoded.containsKey('totalCount')) {
        return decoded['totalCount'] as int;
      } else if (decoded is List) {
        return decoded.length;
      }
      return 0;
    }
    throw Exception('Failed to fetch active rentals count');
  }

  Future<List<Map<String, dynamic>>> fetchRecentOrders({int limit = 5}) async {
    final response = await _api.get('/Order', query: {'pageSize': limit.toString(), 'page': '1'});
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> orders;
      if (decoded is Map && decoded.containsKey('items')) {
        orders = decoded['items'] as List;
      } else if (decoded is List) {
        orders = decoded;
      } else {
        return [];
      }
      // Sort by creation date descending and take first 'limit' items
      return orders
          .cast<Map<String, dynamic>>()
          .take(limit)
          .toList();
    }
    throw Exception('Failed to fetch recent orders');
  }

  Future<List<Map<String, dynamic>>> fetchRecentPayments({int limit = 5}) async {
    final response = await _api.get('/Payment', query: {'pageSize': limit.toString(), 'page': '1'});
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> payments;
      if (decoded is Map && decoded.containsKey('items')) {
        payments = decoded['items'] as List;
      } else if (decoded is List) {
        payments = decoded;
      } else {
        return [];
      }
      // Sort by payment date descending and take first 'limit' items
      return payments
          .cast<Map<String, dynamic>>()
          .take(limit)
          .toList();
    }
    throw Exception('Failed to fetch recent payments');
  }
}

