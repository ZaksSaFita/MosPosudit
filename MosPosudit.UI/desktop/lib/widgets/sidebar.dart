import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import '../screens/edit_profile_screen.dart';
import '../main.dart' show AuthWrapper;
import 'package:mosposudit_shared/services/auth_service.dart';
import 'package:mosposudit_shared/services/message_service.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  const Sidebar({super.key, required this.selectedIndex, required this.onItemSelected});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? name;
  String? role;
  Uint8List? pictureBytes;
  int _unreadMessageCount = 0;
  Timer? _messageCountTimer;
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadUnreadMessageCount();
    _messageCountTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadUnreadMessageCount();
      }
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        loadUser();
      }
    });
  }

  @override
  void dispose() {
    _messageCountTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _unreadMessageCount = 0;
          });
        }
        return;
      }
      
      final userId = currentUser['id'];
      final userRole = currentUser['roleName'] ?? currentUser['role'] ?? '';
      final isAdmin = userRole.toString().toLowerCase() == 'admin';
      
      if (isAdmin) {
        // For admin, count unread messages where admin is the receiver
        final messages = await _messageService.getPendingMessages();
        final allMessages = await _messageService.getUserMessages();
        
        // Count: pending messages + unread messages in active chats where admin is receiver
        int pendingCount = messages.length;
        int unreadActiveCount = allMessages.where((m) => 
          m.isActive && 
          m.toUserId == userId && 
          !m.isRead && 
          m.fromUserId != userId
        ).length;
        
        if (mounted) {
          setState(() {
            _unreadMessageCount = pendingCount + unreadActiveCount;
          });
        }
      } else {
        // For regular users, count unread messages where user is the receiver
        final allMessages = await _messageService.getUserMessages();
        
        // Count unread messages where current user is receiver
        int unreadCount = allMessages.where((m) => 
          m.toUserId == userId && 
          !m.isRead && 
          m.fromUserId != userId
        ).length;
        
        if (mounted) {
          setState(() {
            _unreadMessageCount = unreadCount;
          });
        }
      }
    } catch (e) {
      // Error loading unread message count - silently fail
    }
  }

  Future<void> loadUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      
      if (user != null) {
        setState(() {
          name = '${user['username']}'.trim();
          role = user['roleName'] ?? user['role'] ?? 'User';
          if (user['picture'] != null) {
            pictureBytes = base64Decode(user['picture']);
          } else {
            pictureBytes = null;
          }
        });
      } else {
        setState(() {
          name = 'User';
          role = 'User';
          pictureBytes = null;
        });
      }
    } catch (e) {
      setState(() {
        name = 'User';
        role = 'User';
        pictureBytes = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.grey[50],
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'MošPosudit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // User Profile
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: pictureBytes != null
                    ? MemoryImage(pictureBytes!)
                    : const NetworkImage('https://randomuser.me/api/portraits/women/65.jpg'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name ?? 'User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          Text(
            role ?? 'User',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: widget.selectedIndex == 0,
                  onTap: () => widget.onItemSelected(0),
                ),
                _ExpandableSidebarItem(
                  icon: Icons.build,
                  label: 'Tool Management',
                  selected: widget.selectedIndex >= 1 && widget.selectedIndex <= 2,
                  children: [
                    _SidebarItem(
                      icon: Icons.build_outlined,
                      label: 'Tool Management',
                      selected: widget.selectedIndex == 1,
                      onTap: () => widget.onItemSelected(1),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.category_outlined,
                      label: 'Category Management',
                      selected: widget.selectedIndex == 2,
                      onTap: () => widget.onItemSelected(2),
                      isSubItem: true,
                    ),
                  ],
                ),
                _SidebarItem(
                  icon: Icons.people,
                  label: 'Users',
                  selected: widget.selectedIndex == 4,
                  onTap: () => widget.onItemSelected(4),
                ),
                _SidebarItem(
                  icon: Icons.star,
                  label: 'Reviews',
                  selected: widget.selectedIndex == 5,
                  onTap: () => widget.onItemSelected(5),
                ),
                _SidebarItem(
                  icon: Icons.assignment,
                  label: 'Reservations',
                  selected: widget.selectedIndex == 6,
                  onTap: () => widget.onItemSelected(6),
                ),
                _SidebarItem(
                  icon: Icons.chat,
                  label: 'Chat',
                  selected: widget.selectedIndex == 7,
                  onTap: () {
                    widget.onItemSelected(7);
                    _loadUnreadMessageCount(); // Refresh count when navigating to chat
                  },
                  badgeCount: _unreadMessageCount > 0 ? _unreadMessageCount : null,
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Recommendations Settings',
                  selected: widget.selectedIndex == 8,
                  onTap: () => widget.onItemSelected(8),
                ),
              ],
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _SidebarItem(
              icon: Icons.logout,
              label: 'Logout',
              selected: false,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isSubItem;
  final int? badgeCount;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isSubItem = false,
    this.badgeCount,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.blue[50] : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSubItem ? 32 : 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (isSubItem) const SizedBox(width: 24),
              Stack(
                children: [
                  Icon(
                    icon,
                    size: isSubItem ? 18 : 20,
                    color: selected ? Colors.blue[700] : Colors.black54,
                  ),
                  if (badgeCount != null && badgeCount! > 0)
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
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount! > 9 ? '9+' : '$badgeCount',
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.blue[700] : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isSubItem ? 14 : 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final List<Widget> children;

  const _ExpandableSidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.children,
  });

  @override
  State<_ExpandableSidebarItem> createState() => _ExpandableSidebarItemState();
}

class _ExpandableSidebarItemState extends State<_ExpandableSidebarItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: widget.selected ? Colors.blue[50] : Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.selected ? Colors.blue[700] : Colors.black54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.selected ? Colors.blue[700] : Colors.black87,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
} 