import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/message_service.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'package:mosposudit_shared/services/user_service.dart';
import 'package:mosposudit_shared/models/user.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'package:mosposudit_shared/core/config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  List<MessageModel> _pendingMessages = [];
  Map<int, List<MessageModel>> _activeChats = {}; // userId -> messages
  List<int> _activeUserIds = [];
  int? _selectedUserId;
  int? _currentAdminId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadPendingMessages();
    _loadActiveChats();
    _markMessagesAsRead();
    
    // Auto-refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadPendingMessages();
        if (_selectedUserId != null) {
          _loadChatMessages(_selectedUserId!);
        }
        _markMessagesAsRead();
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      if (_currentAdminId == null) return;
      
      // Get all messages
      final allMessages = await _messageService.getUserMessages();
      
      // Mark unread messages in active chats as read (for both admin and users)
      final unreadMessages = allMessages.where((m) => 
        m.isActive && 
        m.toUserId == _currentAdminId && 
        !m.isRead && 
        m.fromUserId != _currentAdminId
      ).toList();
      
      for (var msg in unreadMessages) {
        try {
          await _messageService.markAsRead(msg.id);
        } catch (e) {
          print('Error marking message as read: $e');
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentAdminId = user['id'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadPendingMessages() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;
      
      final userRole = user['roleName'] ?? user['role'] ?? '';
      final isAdmin = userRole.toString().toLowerCase() == 'admin';
      
      // Only load pending messages if user is admin
      if (isAdmin) {
        final messages = await _messageService.getPendingMessages();
        
        if (mounted) {
          setState(() {
            _pendingMessages = messages;
            _isLoading = false;
          });
        }
      } else {
        // For regular users, no pending messages to load
        if (mounted) {
          setState(() {
            _pendingMessages = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading pending messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadActiveChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return;
      
      // Get all messages for admin
      final response = await http.get(
        Uri.parse('${AppConfig.instance.apiBaseUrl}/Message/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['value'] ?? []);
        final allMessages = data.map((e) => MessageModel.fromJson(e)).toList();
        
        // Group by user - include all active messages where admin is involved
        final Map<int, List<MessageModel>> chats = {};
        for (var msg in allMessages) {
          // Include all active messages where admin is either sender or receiver
          // This includes all messages from conversations started by this admin
          if (msg.isActive && (msg.fromUserId == _currentAdminId || msg.toUserId == _currentAdminId)) {
            final userId = msg.fromUserId == _currentAdminId ? msg.toUserId : msg.fromUserId;
            // Only include if it's a conversation with another user (not admin-to-admin)
            if (userId != null && userId != _currentAdminId) {
              if (!chats.containsKey(userId)) {
                chats[userId] = [];
              }
              chats[userId]!.add(msg);
            }
          }
        }
        
        // Sort messages by sentAt for each user
        for (var userId in chats.keys) {
          chats[userId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        }
        
        if (mounted) {
          setState(() {
            _activeChats = chats;
            _activeUserIds = chats.keys.toList();
          });
        }
      }
    } catch (e) {
      print('Error loading active chats: $e');
    }
  }

  Future<void> _loadChatMessages(int userId) async {
    try {
      await _loadActiveChats();
      
      // Ensure messages for this user are loaded
      if (mounted && _activeChats.containsKey(userId)) {
        setState(() {
          // Messages already loaded in _activeChats
        });
        _scrollToBottom();
      } else if (mounted) {
        // If messages not found, reload active chats
        await _loadActiveChats();
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat messages: $e');
    }
  }

  Future<void> _startChat(int messageId) async {
    try {
      // Find the user from the message before starting chat
      int? userId;
      try {
        final message = _pendingMessages.firstWhere((m) => m.id == messageId);
        userId = message.fromUserId;
      } catch (e) {
        print('Message not found in pending list: $e');
      }
      
      final success = await _messageService.startChat(messageId);
      
      if (success && userId != null) {
        // Reload chats and messages
        await _loadPendingMessages();
        await _loadActiveChats();
        
        // Select the user and load their messages
        setState(() {
          _selectedUserId = userId;
        });
        await _loadChatMessages(userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error starting chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showNewChatDialog() async {
    try {
      // Load non-admin users
      final users = await _userService.fetchNonAdminUsers();
      
      if (!mounted) return;
      
      // Filter out users that already have active chats
      final usersWithoutActiveChats = users.where((user) => 
        !_activeUserIds.contains(user.id)
      ).toList();
      
      if (usersWithoutActiveChats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All users already have active chats'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Show dialog
      final selectedUser = await showDialog<UserModel>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Start New Chat'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: usersWithoutActiveChats.length,
                itemBuilder: (context, index) {
                  final user = usersWithoutActiveChats[index];
                  final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
                  final displayName = fullName.isNotEmpty ? fullName : user.username ?? 'User ${user.id}';
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: user.email != null ? Text(user.email!) : null,
                    onTap: () {
                      Navigator.of(context).pop(user);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      
      if (selectedUser != null) {
        await _startChatWithUser(selectedUser.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChatWithUser(int userId) async {
    try {
      print('Starting chat with user ID: $userId');
      final success = await _messageService.startChatWithUser(userId);
      print('Chat started result: $success');
      
      if (success) {
        // Reload chats and messages
        await _loadPendingMessages();
        await _loadActiveChats();
        
        // Select the user and load their messages
        setState(() {
          _selectedUserId = userId;
        });
        await _loadChatMessages(userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error in _startChatWithUser: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending || _selectedUserId == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendReply(content, _selectedUserId!);
      
      // Immediately reload messages to show the sent message
      await _loadChatMessages(_selectedUserId!);
      
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<String?> _getUserName(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${AppConfig.instance.apiBaseUrl}/User/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        return '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'User $userId';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left sidebar - List of pending messages and active chats
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chat Messages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showNewChatDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    // Pending messages section
                    if (_pendingMessages.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Pending Messages',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      // Group pending messages by user
                      ...(_pendingMessages.map((m) => m.fromUserId).toSet().map((userId) {
                        final userMessages = _pendingMessages
                            .where((m) => m.fromUserId == userId)
                            .toList()
                          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
                        final lastMessage = userMessages.last;
                        
                        // All pending messages are unread by definition
                        final unreadCount = userMessages.length;
                        
                        return FutureBuilder<String?>(
                          future: _getUserName(userId),
                          builder: (context, snapshot) {
                            final userName = snapshot.data ?? 'User $userId';
                            return ListTile(
                              selected: _selectedUserId == userId && _selectedUserId != null && !_activeChats.containsKey(_selectedUserId!),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(userName),
                              subtitle: Text(
                                userMessages.length > 1
                                    ? '${userMessages.length} poruke'
                                    : (lastMessage.content.length > 30 
                                        ? '${lastMessage.content.substring(0, 30)}...'
                                        : lastMessage.content),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                // Show message details in chat area
                                setState(() {
                                  _selectedUserId = userId;
                                });
                                // Reload pending messages to ensure we have the latest
                                await _loadPendingMessages();
                              },
                              trailing: ElevatedButton(
                                onPressed: () => _startChat(lastMessage.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Start Chat'),
                              ),
                              isThreeLine: false,
                            );
                          },
                        );
                      })),
                      const Divider(),
                    ],
                    // Active chats section
                    if (_activeUserIds.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Active Chats',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      ..._activeUserIds.map((userId) {
                        return FutureBuilder<String?>(
                          future: _getUserName(userId),
                          builder: (context, snapshot) {
                            final userName = snapshot.data ?? 'User $userId';
                            final messages = _activeChats[userId] ?? [];
                            final lastMessage = messages.isNotEmpty ? messages.last : null;
                            
                            // Count unread messages for this user
                            final unreadCount = messages.where((m) => 
                              m.toUserId == _currentAdminId && 
                              !m.isRead && 
                              m.fromUserId != _currentAdminId
                            ).length;
                            
                            return ListTile(
                              selected: _selectedUserId == userId,
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: const Icon(Icons.chat, color: Colors.white),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(userName),
                              subtitle: lastMessage != null
                                  ? Text(
                                      lastMessage.content.length > 30
                                          ? '${lastMessage.content.substring(0, 30)}...'
                                          : lastMessage.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedUserId = userId;
                                });
                                _loadChatMessages(userId);
                              },
                            );
                          },
                        );
                      }),
                    ],
                    if (_pendingMessages.isEmpty && _activeUserIds.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No messages',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right side - Chat view
        Expanded(
          child: _selectedUserId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Select a conversation to start chatting',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<String?>(
                  future: _getUserName(_selectedUserId!),
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? 'User $_selectedUserId';
                    final isActiveChat = _activeChats.containsKey(_selectedUserId!);
                    final messages = _activeChats[_selectedUserId!] ?? [];
                    final pendingMessagesForUser = _pendingMessages
                        .where((m) => m.fromUserId == _selectedUserId)
                        .toList()
                      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
                    final allMessages = isActiveChat ? messages : pendingMessagesForUser;
                    
                    return Column(
                      children: [
                        // Chat header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActiveChat ? Colors.blue.shade50 : Colors.orange.shade50,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isActiveChat ? Colors.green : Colors.orange,
                                child: Icon(
                                  isActiveChat ? Icons.chat : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isActiveChat ? 'Chat with $userName' : 'Pending message from $userName',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (!isActiveChat && pendingMessagesForUser.isNotEmpty)
                                      Text(
                                        'Click "Start Chat" to begin conversation',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isActiveChat && pendingMessagesForUser.isNotEmpty)
                                ElevatedButton(
                                  onPressed: () => _startChat(pendingMessagesForUser.first.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Start Chat'),
                                ),
                            ],
                          ),
                        ),
                        // Messages
                        Expanded(
                          child: allMessages.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No messages yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: allMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = allMessages[index];
                                    final isAdmin = message.fromUserId == _currentAdminId;
                                    return _buildMessageBubble(message, isAdmin);
                                  },
                                ),
                        ),
                        // Message input (only for active chats)
                        if (isActiveChat)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(top: BorderSide(color: Colors.grey.shade300)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _sendMessage(),
                                    enabled: !_isSending,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: _isSending
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.send, color: Colors.white),
                                          onPressed: _sendMessage,
                                        ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isAdmin) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isAdmin ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isAdmin ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

