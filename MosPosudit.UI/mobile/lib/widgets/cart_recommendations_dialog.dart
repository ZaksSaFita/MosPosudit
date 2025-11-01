import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'dart:convert';
import 'package:mosposudit_shared/services/utility_service.dart';
import '../screens/cart_screen.dart';

class CartRecommendationsDialog extends StatefulWidget {
  final List<ToolModel> recommendations;
  final VoidCallback onCartUpdated;

  const CartRecommendationsDialog({
    super.key,
    required this.recommendations,
    required this.onCartUpdated,
  });

  @override
  State<CartRecommendationsDialog> createState() => _CartRecommendationsDialogState();
}

class _CartRecommendationsDialogState extends State<CartRecommendationsDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _closeDialog() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToCart() {
    _closeDialog();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended For You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: widget.recommendations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No recommendations available'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.recommendations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tool = widget.recommendations[index];
                        return _RecommendationItem(
                          tool: tool,
                          onAddToCart: () async {
                            await _addToCart(context, tool);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeDialog,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, ToolModel tool) async {
    try {
      final cartService = CartService();
      final toolId = tool.id ?? 0;
      
      // Check if already in cart
      final existingItem = await cartService.findItemByToolId(toolId);
      if (existingItem != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item already in cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final success = await cartService.addToCart(
        toolId: toolId,
        quantity: 1,
        dailyRate: tool.dailyRate ?? 0,
      );

      if (success && context.mounted) {
        widget.onCartUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Close dialog and navigate to cart screen
        _navigateToCart();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RecommendationItem extends StatelessWidget {
  final ToolModel tool;
  final VoidCallback onAddToCart;

  const _RecommendationItem({
    required this.tool,
    required this.onAddToCart,
  });

  Widget _buildToolImage(ToolModel tool) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildToolImage(tool),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name ?? 'Unknown tool',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${tool.dailyRate?.toStringAsFixed(2) ?? '0.00'} / day',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
            onPressed: tool.isAvailable == true && (tool.quantity ?? 0) > 0
                ? onAddToCart
                : null,
            tooltip: 'Add to cart',
          ),
        ],
      ),
    );
  }
}

