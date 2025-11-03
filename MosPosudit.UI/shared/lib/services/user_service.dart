import 'dart:convert';
import '../api/api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserService {
  final ApiClient _api;
  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<UserModel?> me() async {
    final res = await _api.get('/User/me');
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<UserModel?> getById(int id) async {
    final res = await _api.get('/User/$id');
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<List<UserModel>> fetchUsers() async {
    final res = await _api.get('/User');
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
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch users');
  }

  Future<List<UserModel>> fetchNonAdminUsers() async {
    final res = await _api.get('/User/non-admins');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch non-admin users');
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phoneNumber,
    String? picture,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (picture != null) body['picture'] = picture;

    final res = await _api.post('/User/update-profile', body: body);
    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', res.body);
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final body = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      final res = await _api.post('/User/$userId/change-password', body: body);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final res = await _api.get('/User/check-username/$username');
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final res = await _api.get('/User/check-email/$email');
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getUserDetails(int id) async {
    try {
      final res = await _api.get('/User/$id/details');
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/User', body: data);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return UserModel.fromJson(decoded);
    }
    throw Exception('Failed to create user: ${res.statusCode} - ${res.body}');
  }

  Future<UserModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/User/$id', body: data);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return UserModel.fromJson(decoded);
    }
    throw Exception('Failed to update user: ${res.statusCode} - ${res.body}');
  }

  Future<bool> deleteUser(int id) async {
    final res = await _api.delete('/User/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }
}

