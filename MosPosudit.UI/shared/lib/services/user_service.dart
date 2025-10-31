import 'dart:convert';
import '../api/api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch users');
  }

  Future<List<UserModel>> fetchNonAdminUsers() async {
    final res = await _api.get('/User/non-admins');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
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
}

