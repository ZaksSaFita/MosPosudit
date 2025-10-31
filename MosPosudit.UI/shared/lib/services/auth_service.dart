import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  static Future<String?> getRole() async {
    final user = await getCurrentUser();
    return user?['roleName'] ?? user?['role'];
  }

  static Future<int?> getUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }

  static Future<bool> fetchAndStoreCurrentUser() async {
    final token = await getToken();
    if (token == null) return false;
    final baseUrl = AppConfig.instance.apiBaseUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/User/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', response.body);
      return true;
    }
    return false;
  }
}

