import 'dart:convert';
import '../api/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _api;
  NotificationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<NotificationModel>> fetchNotifications({int? limit}) async {
    try {
      final res = await _api.get('/Notification');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        
        // Backend vraća PagedResult<T> sa items i totalCount
        final List<dynamic> data;
        if (decoded is Map && decoded.containsKey('items')) {
          data = decoded['items'] as List<dynamic>;
        } else if (decoded is List) {
          data = decoded;
        } else {
          throw Exception('Unexpected response format: $decoded');
        }
        
        final notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
        
        // Sort by createdAt descending (newest first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Apply limit if provided
        if (limit != null && limit > 0) {
          return notifications.take(limit).toList();
        }
        
        return notifications;
      }
      
      throw Exception('Failed to fetch notifications: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in fetchNotifications: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _api.get('/Notification/unread');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['unreadCount'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('Error in getUnreadCount: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final res = await _api.put('/Notification/$id/read');
      return res.statusCode == 200;
    } catch (e) {
      print('Error in markAsRead: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final res = await _api.put('/Notification/read-all');
      return res.statusCode == 200;
    } catch (e) {
      print('Error in markAllAsRead: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final res = await _api.delete('/Notification/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print('Error in deleteNotification: $e');
      return false;
    }
  }
}

