import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../screens/edit_profile_screen.dart';
import '../main.dart' show AuthWrapper;
import '../services/auth_service.dart';

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
      width: 220,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: pictureBytes != null
                    ? MemoryImage(pictureBytes!)
                    : const NetworkImage('https://randomuser.me/api/portraits/lego/1.jpg'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => EditProfileScreen(
                        onProfileUpdated: () {
                          // Reload user data when profile is updated
                          loadUser();
                        },
                      )),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit, size: 18, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(role ?? 'User', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            selected: widget.selectedIndex == 0,
            onTap: () => widget.onItemSelected(0),
          ),
          _SidebarItem(
            icon: Icons.build,
            label: 'Tools',
            selected: widget.selectedIndex == 1,
            onTap: () => widget.onItemSelected(1),
          ),
          _SidebarItem(
            icon: Icons.category,
            label: 'Categories',
            selected: widget.selectedIndex == 2,
            onTap: () => widget.onItemSelected(2),
          ),
          _SidebarItem(
            icon: Icons.people,
            label: 'Users',
            selected: widget.selectedIndex == 3,
            onTap: () => widget.onItemSelected(3),
          ),
          _SidebarItem(
            icon: Icons.assignment,
            label: 'Reservations',
            selected: widget.selectedIndex == 4,
            onTap: () => widget.onItemSelected(4),
          ),
          _SidebarItem(
            icon: Icons.assessment,
            label: 'Reports',
            selected: widget.selectedIndex == 5,
            onTap: () => widget.onItemSelected(5),
          ),
          const Spacer(),
          const SizedBox(height: 24),
          _SidebarItem(
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
          const SizedBox(height: 24),
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
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.blue[50] : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.blue : Colors.black54),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.blue : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 