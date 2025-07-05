import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/constants.dart';

class UserService {
  static const String _endpoint = '/User';

  Future<List<User>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Niste prijavljeni.');
    }
    final response = await http.get(
      Uri.parse('$apiBaseUrl$_endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Greška: ${response.statusCode}');
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phoneNumber,
    String? picture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Niste prijavljeni.');
    }
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (picture != null) body['picture'] = picture;
    
    final response = await http.post(
      Uri.parse('$apiBaseUrl$_endpoint/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      // Update local user data with response
      final userData = jsonDecode(response.body);
      await prefs.setString('user', jsonEncode(userData));
    }
    
    return response.statusCode == 200;
  }

  Future<List<User>> fetchNonAdminUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Niste prijavljeni.');
    }
    final response = await http.get(
      Uri.parse('$apiBaseUrl$_endpoint/non-admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Greška: ${response.statusCode}');
    }
  }
} 