import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/message_service.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;
  int? _conversationUserId;
  String? _adminName;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadMessages();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUserId = user['id'];
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageService.getUserMessages();
      
      if (mounted) {
        final activeMessage = messages.firstWhere(
          (m) => m.isActive && m.startedByAdminId != null,
          orElse: () => MessageModel(
            id: 0,
            fromUserId: 0,
            content: '',
            sentAt: DateTime.now(),
            isRead: false,
            isActive: false,
          ),
        );
        
        bool hasActiveChat = activeMessage.isActive && activeMessage.startedByAdminId != null;
        
        final unreadMessages = messages.where((m) => 
          !m.isRead && 
          m.toUserId == _currentUserId &&
          m.fromUserId != _currentUserId
        ).toList();
        
        for (var msg in unreadMessages) {
          try {
            await _messageService.markAsRead(msg.id);
          } catch (e) {
          }
        }
        
        List<MessageModel> messagesToShow = List.from(messages);
        if (messages.isNotEmpty && !hasActiveChat) {
          bool hasSystemMessage = messagesToShow.any((m) => m.id == -1);
          if (!hasSystemMessage) {
            messagesToShow.add(MessageModel(
              id: -1,
              fromUserId: 0,
              fromUserName: 'System',
              content: 'Odgovorićemo vam što prije.',
              sentAt: DateTime.now(),
              isRead: false,
              isActive: false,
            ));
          }
        }
        
        setState(() {
          _messages = messagesToShow;
          
          if (hasActiveChat) {
            _conversationUserId = activeMessage.startedByAdminId;
            _adminName = activeMessage.startedByAdminName;
          } else {
            _conversationUserId = null;
            _adminName = null;
          }
          
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      bool hasActiveChat = _conversationUserId != null && _messages.any((m) => m.isActive && m.id != -1);
      
      if (hasActiveChat) {
        await _messageService.sendReply(content, _conversationUserId!);
      } else {
        await _messageService.sendMessage(content);
      }
      
      await _loadMessages();
      
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Chat';
    if (_adminName != null) {
      appBarTitle = 'Chat with $_adminName';
    } else if (_messages.any((m) => !m.isActive)) {
      appBarTitle = 'Chat with Admin';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Send a message to an administrator',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message.fromUserId == _currentUserId;
                          return _buildMessageBubble(message, isUser);
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isUser) {
    final isSystem = message.id == -1 || message.fromUserId == 0;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSystem 
              ? Colors.blue.shade50 
              : (isUser ? Colors.blue : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.fromUserName != null && !isSystem)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.fromUserName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isSystem 
                    ? Colors.blue.shade900 
                    : (isUser ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isSystem 
                    ? Colors.blue.shade700 
                    : (isUser ? Colors.white70 : Colors.grey.shade600),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
