import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../screens/edit_profile_screen.dart';
import '../main.dart' show AuthWrapper;
import 'package:mosposudit_shared/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    loadUser();
    // Dodajemo i delayed load da se osiguramo da se podaci učitaju
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        loadUser();
      }
    });
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
                  label: 'Tools',
                  selected: widget.selectedIndex >= 1 && widget.selectedIndex <= 3,
                  children: [
                    _SidebarItem(
                      icon: Icons.list,
                      label: 'All Tools',
                      selected: widget.selectedIndex == 1,
                      onTap: () => widget.onItemSelected(1),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.add,
                      label: 'Add Tools',
                      selected: widget.selectedIndex == 2,
                      onTap: () => widget.onItemSelected(2),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.star,
                      label: 'Reviews',
                      selected: widget.selectedIndex == 3,
                      onTap: () => widget.onItemSelected(3),
                      isSubItem: true,
                    ),
                  ],
                ),
                _ExpandableSidebarItem(
                  icon: Icons.people,
                  label: 'Users',
                  selected: widget.selectedIndex >= 4 && widget.selectedIndex <= 5,
                  children: [
                    _SidebarItem(
                      icon: Icons.list,
                      label: 'All Users',
                      selected: widget.selectedIndex == 4,
                      onTap: () => widget.onItemSelected(4),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.add,
                      label: 'Add User',
                      selected: widget.selectedIndex == 5,
                      onTap: () => widget.onItemSelected(5),
                      isSubItem: true,
                    ),
                  ],
                ),
                _ExpandableSidebarItem(
                  icon: Icons.calendar_today,
                  label: 'Reservations',
                  selected: widget.selectedIndex >= 6 && widget.selectedIndex <= 8,
                  children: [
                    _SidebarItem(
                      icon: Icons.play_circle_outline,
                      label: 'Active',
                      selected: widget.selectedIndex == 6,
                      onTap: () => widget.onItemSelected(6),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.history,
                      label: 'History',
                      selected: widget.selectedIndex == 7,
                      onTap: () => widget.onItemSelected(7),
                      isSubItem: true,
                    ),
                    _SidebarItem(
                      icon: Icons.description,
                      label: 'Reports',
                      selected: widget.selectedIndex == 8,
                      onTap: () => widget.onItemSelected(8),
                      isSubItem: true,
                    ),
                  ],
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  selected: widget.selectedIndex == 9,
                  onTap: () => widget.onItemSelected(9),
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
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isSubItem = false,
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
              Icon(
                icon,
                size: isSubItem ? 18 : 20,
                color: selected ? Colors.blue[700] : Colors.black54,
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