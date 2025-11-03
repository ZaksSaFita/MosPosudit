import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/models/cart.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'checkout_screen.dart';
import '../utils/snackbar_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _toolService = ToolService();
  List<CartItemModel> _cartItems = [];
  Map<int, ToolModel> _tools = {};
  bool _isLoading = true;
  num _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _cartService.getCartItems();
      final total = await _cartService.getTotalPrice();
      
      final toolIds = items.map((item) => item.toolId).toSet();
      final tools = await _toolService.fetchTools();
      
      final toolsMap = <int, ToolModel>{};
      for (var tool in tools) {
        if (toolIds.contains(tool.id)) {
          toolsMap[tool.id] = tool;
        }
      }

      setState(() {
        _cartItems = items;
        _tools = toolsMap;
        _totalPrice = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(int itemId) async {
    final success = await _cartService.removeFromCart(itemId);
    if (success) {
      _loadCart();
      if (mounted) {
        context.showTopSnackBar(
          message: 'Item removed from cart',
          backgroundColor: Colors.green,
        );
      }
    }
  }

  Future<void> _updateQuantity(int itemId, int quantity, int? toolId) async {
    if (quantity < 1) {
      return;
    }

    final success = await _cartService.updateCartItemQuantity(itemId, quantity);
    if (success) {
      setState(() {
        final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          final item = _cartItems[itemIndex];
          _cartItems[itemIndex] = CartItemModel(
            id: item.id,
            cartId: item.cartId,
            toolId: item.toolId,
            quantity: quantity,
            startDate: item.startDate,
            endDate: item.endDate,
            dailyRate: item.dailyRate,
            notes: item.notes,
          );
        }
        num total = 0;
        for (var item in _cartItems) {
          var days = item.endDate.difference(item.startDate).inDays;
          if (days <= 0) days = 1;
          total += item.dailyRate * item.quantity * days;
        }
        _totalPrice = total;
      });
    }
  }

  Future<void> _increaseQuantity(CartItemModel item, ToolModel? tool) async {
    if (tool == null) {
      if (mounted) {
        context.showTopSnackBar(
          message: 'Tool information not available',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    final maxQuantity = tool.quantity ?? 0;
    if (maxQuantity <= 0) {
      if (mounted) {
        context.showTopSnackBar(
          message: 'Tool is out of stock',
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    final newQuantity = item.quantity + 1;
    if (newQuantity > maxQuantity) {
      if (mounted) {
        context.showTopSnackBar(
          message: 'Maximum quantity: $maxQuantity',
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    await _updateQuantity(item.id, newQuantity, item.toolId);
  }

  Future<void> _decreaseQuantity(CartItemModel item, ToolModel? tool) async {
    if (item.quantity > 1) {
      await _updateQuantity(item.id, item.quantity - 1, item.toolId);
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _cartService.clearCart();
      if (success) {
        _loadCart();
        if (mounted) {
          context.showTopSnackBar(
            message: 'Cart cleared',
            backgroundColor: Colors.green,
          );
        }
      }
    }
  }

  Widget _buildToolImage(ToolModel? tool) {
    if (tool == null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.build, size: 40, color: Colors.blue.shade700),
      );
    }

    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(tool.imageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultIcon(),
          ),
        );
      } catch (e) {
        return _defaultIcon();
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            assetPath,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultIcon(),
          ),
        );
      }
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.build, size: 40, color: Colors.blue.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCart,
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Cart is empty',
                        style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add tools to cart',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final tool = _tools[item.toolId];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildToolImage(tool),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tool?.name ?? 'Unknown tool',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '€${(item.dailyRate * item.quantity).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            const Text(
                                              ' / day',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text(
                                              'Quantity: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.blue),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove, size: 18),
                                                    padding: const EdgeInsets.all(4),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    onPressed: item.quantity > 1
                                                        ? () => _decreaseQuantity(item, tool)
                                                        : null,
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add, size: 18),
                                                    padding: const EdgeInsets.all(4),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    onPressed: (tool?.quantity != null && item.quantity >= tool!.quantity!)
                                                        ? null
                                                        : () => _increaseQuantity(item, tool),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeItem(item.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '€${_totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Text(
                                    ' / day',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _cartItems.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const CheckoutScreen(),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Proceed to Checkout',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

