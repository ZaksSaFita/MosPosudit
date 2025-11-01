import 'dart:convert';
import '../api/api_client.dart';
import '../models/order.dart';
import '../dtos/order/order_insert_request.dart';
import '../dtos/order/order_update_request.dart';

class OrderService {
  final ApiClient _api;
  OrderService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<OrderModel>> fetchOrders({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Order', query: query);
      
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
        
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
      throw Exception('Failed to fetch orders: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in fetchOrders: $e');
      rethrow;
    }
  }

  Future<OrderModel?> getById(int id) async {
    final res = await _api.get('/Order/$id');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return OrderModel.fromJson(decoded);
    }
    return null;
  }

  Future<OrderModel> create(OrderInsertRequest request) async {
    final res = await _api.post('/Order', body: request.toJson());
    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      return OrderModel.fromJson(decoded);
    }
    throw Exception('Failed to create order: ${res.statusCode} - ${res.body}');
  }

  Future<OrderModel?> update(int id, OrderUpdateRequest request) async {
    final res = await _api.put('/Order/$id', body: request.toJson());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return OrderModel.fromJson(decoded);
    }
    return null;
  }

  Future<bool> delete(int id) async {
    final res = await _api.delete('/Order/$id');
    return res.statusCode == 200;
  }

  Future<List<OrderModel>> fetchUserOrders(int userId) async {
    return fetchOrders(query: {'userId': userId});
  }
}

