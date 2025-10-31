import 'dart:convert';
import '../api/api_client.dart';
import 'auth_service.dart';

class MessageService {
  final ApiClient _api;
  MessageService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<MessageModel>> getUserMessages() async {
    try {
      final res = await _api.get('/Message/user');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['value'] ?? []);
        return data.map((e) => MessageModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch messages: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in getUserMessages: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<MessageModel> sendMessage(String content) async {
    try {
      final res = await _api.post('/Message/send', body: {'content': content}); // Backend koristi camelCase
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return MessageModel.fromJson(decoded);
      }
      
      throw Exception('Failed to send message: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in sendMessage: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<MessageModel> sendReply(String content, int conversationUserId) async {
    try {
      final res = await _api.post('/Message/reply?conversationUserId=$conversationUserId', 
        body: {'content': content} // Backend koristi camelCase
      );
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return MessageModel.fromJson(decoded);
      }
      
      throw Exception('Failed to send reply: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in sendReply: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final res = await _api.put('/Message/$id/read');
      return res.statusCode == 200;
    } catch (e) {
      print('Error in markAsRead: $e');
      return false;
    }
  }

  // Admin methods
  Future<List<MessageModel>> getPendingMessages() async {
    try {
      final res = await _api.get('/Message/pending');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['value'] ?? []);
        return data.map((e) => MessageModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch pending messages: ${res.statusCode} - ${res.body}');
    } catch (e, stackTrace) {
      print('Error in getPendingMessages: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> startChat(int messageId) async {
    try {
      final res = await _api.post('/Message/$messageId/start');
      return res.statusCode == 200;
    } catch (e) {
      print('Error in startChat: $e');
      return false;
    }
  }


  Future<int> getUnreadMessageCount() async {
    try {
      final messages = await getUserMessages();
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) return 0;
      
      final userId = currentUser['id'];
      
      // Count unread messages where current user is the receiver
      return messages.where((m) => 
        m.toUserId == userId && 
        !m.isRead && 
        m.fromUserId != userId
      ).length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }
}

class MessageModel {
  final int id;
  final int fromUserId;
  final String? fromUserName;
  final int? toUserId;
  final String? toUserName;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;
  final bool isActive;
  final int? startedByAdminId;
  final String? startedByAdminName;

  MessageModel({
    required this.id,
    required this.fromUserId,
    this.fromUserName,
    this.toUserId,
    this.toUserName,
    required this.content,
    required this.sentAt,
    this.readAt,
    required this.isRead,
    required this.isActive,
    this.startedByAdminId,
    this.startedByAdminName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      fromUserId: json['fromUserId'] ?? 0,
      fromUserName: json['fromUserName'],
      toUserId: json['toUserId'],
      toUserName: json['toUserName'],
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null 
          ? DateTime.parse(json['sentAt'].toString()).toLocal()
          : DateTime.now(),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'].toString()).toLocal()
          : null,
      isRead: json['isRead'] ?? false,
      isActive: json['isActive'] ?? false,
      startedByAdminId: json['startedByAdminId'],
      startedByAdminName: json['startedByAdminName'],
    );
  }
}

