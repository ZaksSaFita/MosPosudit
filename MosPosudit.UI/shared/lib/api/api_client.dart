import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.instance.apiBaseUrl;

  Future<Map<String, String>> _defaultHeaders({bool withAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    // Ensure path starts with / if it doesn't already
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final headers = await _defaultHeaders(withAuth: auth);
    return http.get(_uri(path, query), headers: headers);
  }

  Future<http.Response> post(String path, {Object? body, Map<String, dynamic>? query, bool auth = true}) async {
    final headers = await _defaultHeaders(withAuth: auth);
    return http.post(_uri(path, query), headers: headers, body: body is String ? body : jsonEncode(body));
  }

  Future<http.Response> put(String path, {Object? body, bool auth = true}) async {
    final headers = await _defaultHeaders(withAuth: auth);
    return http.put(_uri(path), headers: headers, body: body is String ? body : jsonEncode(body));
  }

  Future<http.Response> patch(String path, {Object? body, bool auth = true}) async {
    final headers = await _defaultHeaders(withAuth: auth);
    return http.patch(_uri(path), headers: headers, body: body is String ? body : jsonEncode(body));
  }

  Future<http.Response> delete(String path, {Object? body, bool auth = true}) async {
    final headers = await _defaultHeaders(withAuth: auth);
    return http.delete(_uri(path), headers: headers, body: body is String ? body : jsonEncode(body));
  }
}

