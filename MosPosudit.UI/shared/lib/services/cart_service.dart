import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool.dart';
import '../models/cart.dart';

class CartService {
  static const String _cartItemsKey = 'cart_items';
  static const String _cartKey = 'cart';

  Future<List<CartItemModel>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList(_cartItemsKey) ?? [];
    return cartItemsJson.map((json) => CartItemModel.fromJson(jsonDecode(json))).toList();
  }

  Future<bool> addToCart({
    required int toolId,
    required int quantity,
    required num dailyRate,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = prefs.getStringList(_cartItemsKey) ?? [];
      
      final newItem = CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch,
        cartId: 0,
        toolId: toolId,
        quantity: quantity,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now().add(const Duration(days: 1)),
        dailyRate: dailyRate,
      );
      
      cartItemsJson.add(jsonEncode(newItem.toJson()));
      await prefs.setStringList(_cartItemsKey, cartItemsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromCart(int itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = prefs.getStringList(_cartItemsKey) ?? [];
      
      cartItemsJson.removeWhere((json) {
        final item = CartItemModel.fromJson(jsonDecode(json));
        return item.id == itemId;
      });
      
      await prefs.setStringList(_cartItemsKey, cartItemsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCartItemQuantity(int itemId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = prefs.getStringList(_cartItemsKey) ?? [];
      
      final updatedItems = cartItemsJson.map((json) {
        final item = CartItemModel.fromJson(jsonDecode(json));
        if (item.id == itemId) {
          final updatedItem = CartItemModel(
            id: item.id,
            cartId: item.cartId,
            toolId: item.toolId,
            quantity: quantity,
            startDate: item.startDate,
            endDate: item.endDate,
            dailyRate: item.dailyRate,
            notes: item.notes,
          );
          return jsonEncode(updatedItem.toJson());
        }
        return json;
      }).toList();
      
      await prefs.setStringList(_cartItemsKey, updatedItems);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartItemsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CartItemModel?> findItemByToolId(int toolId) async {
    final items = await getCartItems();
    try {
      return items.firstWhere(
        (item) => item.toolId == toolId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int> getCartItemCount() async {
    final items = await getCartItems();
    return items.length;
  }

  Future<num> getTotalPrice() async {
    final items = await getCartItems();
    num total = 0;
    for (var item in items) {
      var days = item.endDate.difference(item.startDate).inDays;
      if (days <= 0) days = 1;
      total += item.dailyRate * item.quantity * days;
    }
    return total;
  }
}

