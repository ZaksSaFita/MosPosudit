import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class UserService {
  static const String _endpoint = '/User';

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
      throw Exception('You are not logged in.');
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
      return true;
    } else {
      // Parse error message from response
      String errorMessage = 'Error updating profile';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      } catch (e) {
        // Use default error message if parsing fails
      }
      throw Exception(errorMessage);
    }
  }
} 