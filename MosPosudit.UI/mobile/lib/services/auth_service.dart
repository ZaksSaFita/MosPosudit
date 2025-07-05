import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

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

  static Future<String?> getFullName() async {
    final user = await getCurrentUser();
    if (user != null) {
      return '${user['firstName']} ${user['lastName']}';
    }
    return null;
  }

  static Future<bool> fetchAndStoreCurrentUser() async {
    final token = await getToken();
    if (token == null) return false;
    
    final response = await http.get(
      Uri.parse('$apiBaseUrl/User/me'),
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