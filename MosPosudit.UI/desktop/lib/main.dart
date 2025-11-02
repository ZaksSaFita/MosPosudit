import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/users_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:mosposudit_shared/core/config.dart';
import 'package:mosposudit_shared/services/message_service.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'widgets/sidebar.dart';
import 'core/constants.dart';
import 'core/snackbar_helper.dart';

void main() {
  AppConfig.instance = AppConfig(apiBaseUrl: apiBaseUrl);
  runApp(const MosPosuditDesktopApp());
}

class MosPosuditDesktopApp extends StatelessWidget {
  const MosPosuditDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName - Administration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final user = prefs.getString('user');
    
    // Validate that user is admin
    if (token != null && user != null) {
      try {
        final userData = jsonDecode(user);
        final roleName = userData['roleName'] ?? '';
        final isAdmin = roleName.toString().toLowerCase() == 'admin';
        
        if (!isAdmin) {
          // Clear invalid session - user is not admin
          await prefs.remove('token');
          await prefs.remove('user');
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // If parsing fails, clear session
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }
    }
    
    setState(() {
      _isLoggedIn = token != null && user != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return _isLoggedIn ? const AdminDashboard() : const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (rememberMe && savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        
        // Dohvati podatke o korisniku preko /User/me
        final userResponse = await http.get(
          Uri.parse('$apiBaseUrl/User/me'),
          headers: {
            'Authorization': 'Bearer ${data['token']}',
          },
        );
        if (userResponse.statusCode == 200) {
          final userDataFromDb = jsonDecode(userResponse.body);
          
          // Check if user has admin role
          final roleName = userDataFromDb['roleName'] ?? '';
          final isAdmin = roleName.toString().toLowerCase() == 'admin';
          
          if (!isAdmin) {
            // Clear token and show error - only admins can access desktop app
            await prefs.remove('token');
            await prefs.remove('user');
            if (mounted) {
              SnackbarHelper.showError(
                context,
                'Only admin users can access the desktop application.',
              );
              setState(() {
                _isLoading = false;
              });
            }
            return;
          }
          
          // User is admin - proceed with login
          await prefs.setString('user', jsonEncode(userDataFromDb));
          
          // Save credentials if remember me is checked
          if (_rememberMe) {
            await prefs.setString('saved_username', _usernameController.text);
            await prefs.setString('saved_password', _passwordController.text);
            await prefs.setBool('remember_me', true);
          } else {
            await prefs.remove('saved_username');
            await prefs.remove('saved_password');
            await prefs.setBool('remember_me', false);
          }
          
          if (mounted) {
            SnackbarHelper.showSuccess(
              context,
              'Successfully logged in!',
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        } else {
          // fallback: obrisi user podatke ako ne možeš dohvatiti
          await prefs.remove('token');
          await prefs.remove('user');
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'Failed to retrieve user information.',
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          String userMessage = 'Login error. Please check your credentials and try again.';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData is Map && errorData['errors'] != null) {
              final errors = errorData['errors'];
              if (errors is Map && errors.values.isNotEmpty) {
                userMessage = errors.values.first is List && errors.values.first.isNotEmpty
                  ? errors.values.first[0].toString()
                  : userMessage;
              }
            } else if (errorData is Map && errorData['title'] != null) {
              userMessage = errorData['title'].toString();
            } else if (response.statusCode == 401 || response.statusCode == 403) {
              userMessage = 'Incorrect username or password.';
            }
          } catch (_) {
            if (response.statusCode == 401 || response.statusCode == 403) {
              userMessage = 'Incorrect username or password.';
            }
          }
          SnackbarHelper.showError(context, userMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '$networkErrorMessage: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.lightBlue, Colors.blueAccent],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                                              const Text(
                          'MosPosudit Admin',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Administrative panel',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Test credentials: samo-moze-admin / test',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  int _lastUnreadCount = 0;
  Timer? _notificationTimer;
  final MessageService _messageService = MessageService();

  final List<Widget> _pages = [
    const DashboardPage(), // Dashboard
    const ToolsManagementPage(), // All Tools
    const CategoriesManagementPage(), // Categories
    const ToolsManagementPage(), // Reviews (temporary)
    const UsersManagementPage(), // All Users
    const UsersManagementPage(), // Add User (temporary, should be Add User page)
    const ReportsPage(), // Reports
    const ChatScreen(), // Chat
    const SettingsPage(), // Settings
  ];

  @override
  void initState() {
    super.initState();
    _checkForNewMessages();
    // Check for new messages every 5 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _checkForNewMessages();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForNewMessages() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) return;
      
      final userId = currentUser['id'];
      final userRole = currentUser['roleName'] ?? currentUser['role'] ?? '';
      final isAdmin = userRole.toString().toLowerCase() == 'admin';
      
      int currentUnreadCount = 0;
      
      if (isAdmin) {
        final messages = await _messageService.getPendingMessages();
        final allMessages = await _messageService.getUserMessages();
        
        int pendingCount = messages.length;
        int unreadActiveCount = allMessages.where((m) => 
          m.isActive && 
          m.toUserId == userId && 
          !m.isRead && 
          m.fromUserId != userId
        ).length;
        
        currentUnreadCount = pendingCount + unreadActiveCount;
      } else {
        final allMessages = await _messageService.getUserMessages();
        
        currentUnreadCount = allMessages.where((m) => 
          m.toUserId == userId && 
          !m.isRead && 
          m.fromUserId != userId
        ).length;
      }
      
      // Show notification if new messages arrived and user is not on chat screen
      if (mounted && currentUnreadCount > _lastUnreadCount && _selectedIndex != 7) {
        final newMessagesCount = currentUnreadCount - _lastUnreadCount;
        SnackbarHelper.showInfo(
          context,
          newMessagesCount == 1
              ? 'Nova poruka je stigla'
              : '$newMessagesCount nove poruke su stigle',
          duration: const Duration(seconds: 5),
        );
      }
      
      if (mounted) {
        setState(() {
          _lastUnreadCount = currentUnreadCount;
        });
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (int index) {
              setState(() => _selectedIndex = index);
              // Refresh notification check when navigating
              if (index == 7) {
                _checkForNewMessages();
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// DashboardPage is now imported from screens/dashboard_screen.dart

// ToolsManagementPage is now imported from screens/tools_screen.dart
// CategoriesManagementPage is now imported from screens/categories_screen.dart
// RentalsManagementPage is now imported from screens/reservations_screen.dart

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.assessment, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Feature in development', style: TextStyle(fontSize: 18)),
                  Text('Reports will be implemented', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.settings, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Feature in development', style: TextStyle(fontSize: 18)),
                  Text('Settings will be implemented', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
