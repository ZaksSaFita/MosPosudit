import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/user_favorite_service.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'package:mosposudit_shared/models/user_favorite.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/widgets/tool_availability_dialog.dart';
import '../utils/snackbar_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoriteService = UserFavoriteService();
  final _toolService = ToolService();
  final _cartService = CartService();
  
  List<UserFavoriteModel> _favorites = [];
  Map<int, ToolModel> _tools = {};
  Set<int> _toolsInCart = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await _favoriteService.getFavorites();
      final toolIds = favorites.map((f) => f.toolId).toList();
      
      final tools = await _toolService.fetchTools();
      final toolsMap = <int, ToolModel>{};
      for (var tool in tools) {
        if (toolIds.contains(tool.id)) {
          toolsMap[tool.id] = tool;
        }
      }

      final cartItems = await _cartService.getCartItems();
      final toolsInCart = cartItems.map<int>((item) => item.toolId).toSet();

      if (mounted) {
        setState(() {
          _favorites = favorites;
          _tools = toolsMap;
          _toolsInCart = toolsInCart;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(int toolId) async {
    try {
      final success = await _favoriteService.removeFavorite(toolId);
      if (success && mounted) {
        context.showTopSnackBar(
          message: 'Removed from favorites',
          backgroundColor: Colors.green,
        );
        await _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        context.showTopSnackBar(
          message: 'Error removing favorite: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _addToCart(ToolModel tool) async {
    try {
      final toolId = tool.id;
      
      final existingItem = await _cartService.findItemByToolId(toolId);
      
      if (existingItem != null) {
        final newQuantity = existingItem.quantity + 1;
        final success = await _cartService.updateCartItemQuantity(
          existingItem.id,
          newQuantity,
        );

        if (success && mounted) {
          await _loadFavorites();
          context.showTopSnackBar(
            message: 'Quantity increased to $newQuantity',
            backgroundColor: Colors.green,
          );
        }
        return;
      }

      final success = await _cartService.addToCart(
        toolId: toolId,
        quantity: 1,
        dailyRate: tool.dailyRate ?? 0,
      );

      if (success && mounted) {
        await _loadFavorites();
        context.showTopSnackBar(
          message: 'Added to cart',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showTopSnackBar(
          message: 'Error: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Widget _buildToolImage(ToolModel tool, {double? width, double? height}) {
    final imgWidth = width ?? 120.0;
    final imgHeight = height ?? 120.0;
    
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
              return _defaultIcon(width: imgWidth, height: imgHeight);
            },
          ),
        );
      } catch (e) {
        return _defaultIcon(width: imgWidth, height: imgHeight);
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            assetPath,
            width: imgWidth,
            height: imgHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _defaultIcon(width: imgWidth, height: imgHeight);
            },
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading favorites',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadFavorites,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add tools to favorites to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = _favorites[index];
                          final tool = _tools[favorite.toolId];
                          
                          if (tool == null) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            color: Colors.white,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildToolImage(tool, width: 120, height: 120),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              tool.name ?? 'Unknown tool',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '€${tool.dailyRate?.toStringAsFixed(2) ?? '0.00'} / day',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {
                                                      ToolAvailabilityDialog.show(
                                                        context,
                                                        tool,
                                                      );
                                                    },
                                                    icon: const Icon(Icons.date_range, size: 16),
                                                    label: const Text(
                                                      'Availability',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange.shade600,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      elevation: 2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: (_toolsInCart.contains(tool.id))
                                                        ? null
                                                        : () => _addToCart(tool),
                                                    icon: Icon(
                                                      _toolsInCart.contains(tool.id)
                                                          ? Icons.check_circle
                                                          : Icons.shopping_cart,
                                                      size: 16,
                                                    ),
                                                    label: Text(
                                                      _toolsInCart.contains(tool.id)
                                                          ? 'In cart'
                                                          : 'Add to cart',
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _toolsInCart.contains(tool.id)
                                                          ? Colors.grey
                                                          : Colors.blue,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      disabledBackgroundColor: Colors.grey.shade400,
                                                      disabledForegroundColor: Colors.white,
                                                      elevation: 2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeFavorite(tool.id),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

