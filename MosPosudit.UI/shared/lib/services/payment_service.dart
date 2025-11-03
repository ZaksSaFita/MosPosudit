import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/payment.dart';
import '../dtos/payment/paypal_create_order_request.dart';
import '../dtos/payment/paypal_order_response.dart';
import '../dtos/payment/paypal_capture_response.dart';
import '../dtos/order/order_insert_request.dart';

class PaymentService {
  final ApiClient _api;
  PaymentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<PaymentModel>> fetchPayments({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Payment', query: query);
      
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
        
        return data.map((e) => PaymentModel.fromJson(e)).toList();
      }
      throw Exception('Failed to fetch payments: ${res.statusCode} - ${res.body}');
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentModel?> getById(int id) async {
    final res = await _api.get('/Payment/$id');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return PaymentModel.fromJson(decoded);
    }
    return null;
  }

  Future<PayPalOrderResponse> createPayPalOrder(OrderInsertRequest orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        throw Exception('You must be logged in to make a payment. Please login first.');
      }
      
      final request = PayPalCreateOrderRequest(orderData: orderData);
      final res = await _api.post('/Payment/paypal/create', body: request.toJson(), auth: true);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return PayPalOrderResponse.fromJson(decoded);
      }
      
      if (res.statusCode == 401) {
        await prefs.remove('token');
        throw Exception('Your session has expired. Please login again.');
      }
      
      String errorMessage = 'Failed to create PayPal order: ${res.statusCode}';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        } else {
          errorMessage = 'Failed to create PayPal order: ${res.statusCode} - ${res.body}';
        }
      } catch (e) {
        errorMessage = 'Failed to create PayPal order: ${res.statusCode} - ${res.body}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> openPayPalPayment(String approvalUrl) async {
    try {
      final uri = Uri.parse(approvalUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> handlePayPalReturn(String token) async {
    try {
      final res = await _api.get('/Payment/paypal/return', query: {'token': token}, auth: false);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded as Map<String, dynamic>;
      }
      
      String errorMessage = 'Payment was not completed';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        } else {
          errorMessage = 'Failed to process payment: ${res.statusCode} - ${res.body}';
        }
      } catch (e) {
        errorMessage = 'Failed to process payment: ${res.statusCode} - ${res.body}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }
}

