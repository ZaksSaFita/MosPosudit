import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/services/message_service.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/category.dart';
import 'package:mosposudit_shared/core/config.dart';
import 'core/constants.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/cart_screen.dart';

void main() {
  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Handle errors from async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack trace: $stack');
    return true;
  };

  AppConfig.instance = AppConfig(apiBaseUrl: apiBaseUrl); // apiBaseUrl from constants.dart
  runApp(const MosPosuditMobileApp());
}

class MosPosuditMobileApp extends StatelessWidget {
  const MosPosuditMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MosPosudit',
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final user = prefs.getString('user');
      
      if (mounted) {
        setState(() {
          _isLoggedIn = token != null && user != null;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error checking auth status: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    try {
      return _isLoggedIn 
          ? const ClientHomeScreen() 
          : const LoginScreen();
    } catch (e, stackTrace) {
      print('Error building AuthWrapper: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading app'),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _checkAuthStatus();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
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
        Uri.parse('${AppConfig.instance.apiBaseUrl}/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Username': _usernameController.text,
          'Password': _passwordController.text,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login data: $data');
        
        final prefs = await SharedPreferences.getInstance();
        
        // Check if token exists in response
        if (data['token'] == null && data['Token'] == null) {
          throw Exception('Token not found in response');
        }
        
        await prefs.setString('token', data['token'] ?? data['Token']);
        
        // Save credentials if remember me is checked
        if (_rememberMe) {
          await prefs.setString('saved_username', _usernameController.text);
          await prefs.setString('saved_password', _passwordController.text);
          await prefs.setBool('remember_me', true);
        } else {
          // Clear saved credentials if remember me is unchecked
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }
        
        // Get complete user data including role from /User/me endpoint
        final userResponse = await http.get(
          Uri.parse('${AppConfig.instance.apiBaseUrl}/User/me'),
          headers: {
            'Authorization': 'Bearer ${data['token']}',
          },
        );
        
        if (userResponse.statusCode == 200) {
          await prefs.setString('user', userResponse.body);
        } else {
          // Fallback: remove user data if we can't fetch it
          await prefs.remove('user');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged in!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      } else {
        String errorMessage = 'Login error';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message if parsing fails
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}\n\nAPI URL: ${AppConfig.instance.apiBaseUrl}/Auth/login'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.build,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'MosPosudit',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rent tools in a few steps',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                            border: const OutlineInputBorder(),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Log in',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegistrationScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Test credentials: user / test',
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
      ),
    );
  }
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0; // Back to HomeScreen
  int? _selectedCategoryId;
  int _unreadMessageCount = 0;
  int _cartItemCount = 0;
  Timer? _messageCountTimer;
  final _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _loadUnreadMessageCount();
    _loadCartCount();
    // Refresh message count every 5 seconds
    _messageCountTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadUnreadMessageCount();
        _loadCartCount();
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
      final messageService = MessageService();
      final count = await messageService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread message count: $e');
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await _cartService.getCartItemCount();
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  void _navigateToToolsWithCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedIndex = 1; // Switch to ToolsPage
    });
  }

  void _navigateToToolsWithTool(int? toolId, int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedIndex = 1; // Switch to ToolsPage
    });
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  List<Widget> get _pages => [
    HomeScreen(
      onCategoryTap: _navigateToToolsWithCategory,
      onToolTap: _navigateToToolsWithTool,
      onProfileTap: _navigateToProfile,
    ),
    ToolsPage(key: ValueKey(_selectedCategoryId), initialCategoryId: _selectedCategoryId),
    const MyRentalsPage(),
    ChatScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Use same colors as desktop (Colors.blue)
    const primaryBlue = Colors.blue;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: primaryBlue,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Reload message count when navigating to chat
            if (index == 3) {
              _loadUnreadMessageCount();
            }
            // Reload cart count when navigating to cart
            if (index == 4) {
              _loadCartCount();
            }
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedIndex == 0 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                ),
                child: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 1 ? Icons.build : Icons.build_outlined,
                size: 24,
              ),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 2 ? Icons.assignment : Icons.assignment_outlined,
                size: 24,
              ),
              label: 'My Rentals',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(
                    _selectedIndex == 3 ? Icons.chat : Icons.chat_outlined,
                    size: 24,
                  ),
                  if (_unreadMessageCount > 0)
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
                          _unreadMessageCount > 9 ? '9+' : '$_unreadMessageCount',
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
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(
                    _selectedIndex == 4 ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                    size: 24,
                  ),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _cartItemCount > 9 ? '9+' : '$_cartItemCount',
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
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}

class ToolsPage extends StatefulWidget {
  final int? initialCategoryId;
  
  const ToolsPage({super.key, this.initialCategoryId});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final _toolService = ToolService();
  final _cartService = CartService();
  List<ToolModel> _tools = [];
  List<CategoryModel> _categories = [];
  Set<int> _toolsInCart = {}; // Track which tools are in cart
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart status when page becomes visible (e.g., returning from cart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCartStatus();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _toolService.fetchTools(),
        _toolService.fetchCategories(),
        _cartService.getCartItems(),
      ]);

      final cartItems = results[2] as List;
      final toolsInCart = cartItems.map<int>((item) => item.toolId as int).toSet();

      setState(() {
        _tools = results[0] as List<ToolModel>;
        _categories = results[1] as List<CategoryModel>;
        _toolsInCart = toolsInCart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCartStatus() async {
    try {
      final cartItems = await _cartService.getCartItems();
      final toolsInCart = cartItems.map<int>((item) => item.toolId as int).toSet();
      if (mounted) {
        setState(() {
          _toolsInCart = toolsInCart;
        });
      }
    } catch (e) {
      print('Error refreshing cart status: $e');
    }
  }

  List<ToolModel> get _filteredTools {
    if (_selectedCategoryId == null) return _tools;
    return _tools.where((tool) => tool.categoryId == _selectedCategoryId).toList();
  }

  String? _getCategoryName(int? categoryId) {
    if (categoryId == null) return null;
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: 0),
    );
    return category.id != 0 ? category.name : null;
  }


  Widget _buildToolImage(ToolModel tool, {double? width, double? height}) {
    final imgWidth = width ?? 120.0;
    final imgHeight = height ?? 120.0;
    
    // Priority: base64 > asset filename (generated from name) > default icon
    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(tool.imageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: imgWidth,
            height: imgHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading base64 image: $error');
              return _defaultIcon(width: imgWidth, height: imgHeight);
            },
          ),
        );
      } catch (e) {
        print('Exception loading base64 image: $e');
        return _defaultIcon(width: imgWidth, height: imgHeight);
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      print('ToolsPage: Tool name="${tool.name}", Generated fileName="$fileName"');
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        print('ToolsPage: Attempting to load asset: $assetPath for tool: ${tool.name}');
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            assetPath,
            width: imgWidth,
            height: imgHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('ToolsPage: Error loading asset image: $assetPath, error: $error');
              return _defaultIcon(width: imgWidth, height: imgHeight);
            },
          ),
        );
      } else {
        print('ToolsPage: Generated fileName is empty for tool: ${tool.name}');
      }
    }
    print('No image for tool: ${tool.name}, imageBase64: ${tool.imageBase64 != null ? "exists" : "null"}');
    return _defaultIcon(width: imgWidth, height: imgHeight);
  }

  Widget _defaultIcon({double? width, double? height}) {
    return Container(
      width: width ?? 120.0,
      height: height ?? 120.0,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.build, size: 48, color: Colors.blue.shade700),
    );
  }

  Future<void> _addToCart(ToolModel tool) async {
    try {
      final toolId = tool.id ?? 0;
      
      // Check if item already exists in cart
      final existingItem = await _cartService.findItemByToolId(toolId);
      
      if (existingItem != null) {
        // Item already exists, automatically increase quantity
        final success = await _cartService.updateCartItemQuantity(
          existingItem.id,
          existingItem.quantity + 1,
        );

        if (success && mounted) {
          await _refreshCartStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quantity increased to ${existingItem.quantity + 1}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Item doesn't exist, add new item
      final success = await _cartService.addToCart(
        toolId: toolId,
        quantity: 1,
        dailyRate: tool.dailyRate ?? 0,
      );

      if (success && mounted) {
        await _refreshCartStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _refreshCartStatus();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Tools',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Category filter chips
                  if (_categories.isNotEmpty)
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategoryId == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategoryId = null);
                                }
                              },
                            ),
                          ),
                          ..._categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(category.name ?? 'Unknown'),
                              selected: _selectedCategoryId == category.id,
                              onSelected: (selected) {
                                setState(() => _selectedCategoryId = selected ? category.id : null);
                              },
                            ),
                          )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredTools.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No available tools', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = _filteredTools[index];
                    final categoryName = _getCategoryName(tool.categoryId);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image on the left
                            _buildToolImage(tool, width: 120, height: 120),
                            const SizedBox(width: 12),
                            // Content on the right
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tool name
                                  Text(
                                    tool.name ?? 'Unknown tool',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Category
                                  if (categoryName != null)
                                    Text(
                                      categoryName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  // Description
                                  if (tool.description != null && tool.description!.isNotEmpty)
                                    Text(
                                      tool.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  // Price
                                  Text(
                                    '€${tool.dailyRate?.toStringAsFixed(2) ?? '0.00'} / day',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                    const SizedBox(height: 8),
                                    // Add to cart button - disabled if already in cart
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _toolsInCart.contains(tool.id)
                                            ? null
                                            : () => _addToCart(tool),
                                        icon: Icon(
                                          _toolsInCart.contains(tool.id)
                                              ? Icons.check_circle
                                              : Icons.shopping_cart,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _toolsInCart.contains(tool.id)
                                              ? 'In cart'
                                              : 'Add to cart',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _toolsInCart.contains(tool.id)
                                              ? Colors.grey
                                              : Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          disabledBackgroundColor: Colors.grey.shade400,
                                          disabledForegroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _filteredTools.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MyRentalsPage extends StatelessWidget {
  const MyRentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Rentals',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active rentals',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rent a tool to see it here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUploading = false;
  File? _selectedFile;
  Uint8List? _pictureBytes;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      userData = user;
      if (user != null && user['picture'] != null) {
        try {
          _pictureBytes = base64Decode(user['picture']);
        } catch (e) {
          _pictureBytes = null;
        }
      } else {
        _pictureBytes = null;
      }
      isLoading = false;
    });
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      
      if (filePath != null) {
        try {
          final file = File(filePath);
          final bytes = await file.readAsBytes();
          
          setState(() {
            _pictureBytes = bytes;
            _selectedFile = file;
          });
          
          // Automatically upload the image
          await uploadImage();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error reading image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> uploadImage() async {
    if (_selectedFile == null || userData == null || userData!['id'] == null) {
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = userData!['id'];
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.instance.apiBaseUrl}/User/$userId/upload-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Update local user data
        final userResp = jsonDecode(responseString);
        await prefs.setString('user', jsonEncode(userResp));
        
        // Reload user data to show updated picture
        await loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image successfully updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error uploading image: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          _selectedFile = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return const Center(child: Text('Error loading data'));
    }

    final fullName = '${userData!['firstName']} ${userData!['lastName']}';
    final email = userData!['email'] ?? 'N/A';
    final phoneNumber = userData!['phoneNumber'] ?? 'N/A';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _pictureBytes != null
                          ? MemoryImage(_pictureBytes!)
                          : null,
                      backgroundColor: Colors.blue,
                      child: _pictureBytes == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    if (isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
                if (phoneNumber != 'N/A') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tel: $phoneNumber',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          onProfileUpdated: loadUserData,
                        ),
                      ),
                    );
                    if (result == true) {
                      loadUserData();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement password change
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature in development'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: const Text('Rental History'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement rental history
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature in development'),
                      ),
                    );
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // Clear stored data
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('token');
                      await prefs.remove('user');
                      await prefs.remove('saved_username');
                      await prefs.remove('saved_password');
                      await prefs.remove('remember_me');

                      // Navigate to login screen
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthWrapper(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
