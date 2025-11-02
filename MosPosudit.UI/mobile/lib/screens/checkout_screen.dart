import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'package:mosposudit_shared/services/order_service.dart';
import 'package:mosposudit_shared/services/payment_service.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/models/cart.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/tool_availability.dart';
import 'package:mosposudit_shared/dtos/order/order_insert_request.dart';
import 'paypal_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartService = CartService();
  final _orderService = OrderService();
  final _toolService = ToolService();
  final _formKey = GlobalKey<FormState>();
  
  List<CartItemModel> _cartItems = [];
  Map<int, ToolModel> _tools = {};
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _termsAccepted = false;
  
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 1));
  bool _datesSelected = false;
  bool _isValidatingAvailability = false;
  
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
        if (items.isNotEmpty) {
          _selectedStartDate = items.first.startDate;
          _selectedEndDate = items.first.endDate;
          _datesSelected = true;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Validates availability for all tools in cart for selected date range
  Future<bool> _validateAvailabilityForSelectedPeriod() async {
    if (_cartItems.isEmpty || _tools.isEmpty) {
      return false;
    }

    setState(() {
      _isValidatingAvailability = true;
    });

    try {
      final now = DateTime.now();
      final startDate = _selectedStartDate.isBefore(now) ? now : _selectedStartDate;
      
      final unavailableTools = <Map<String, dynamic>>[];
      
      for (var cartItem in _cartItems) {
        final tool = _tools[cartItem.toolId];
        if (tool == null) continue;

        final availability = await _toolService.getAvailability(
          tool.id,
          startDate,
          _selectedEndDate,
        );

        if (availability == null) continue;

        var currentDate = startDate;
        while (currentDate.isBefore(_selectedEndDate) || currentDate.isAtSameMomentAs(_selectedEndDate)) {
          final dateKey = '${currentDate.year.toString().padLeft(4, '0')}-'
              '${currentDate.month.toString().padLeft(2, '0')}-'
              '${currentDate.day.toString().padLeft(2, '0')}';
          
          final available = availability.getAvailableQuantityForDateString(dateKey) ?? 0;
          
          if (available < cartItem.quantity) {
            unavailableTools.add({
              'tool': tool,
              'cartItem': cartItem,
              'date': currentDate,
              'available': available,
              'totalQuantity': availability.totalQuantity,
            });
            break;
          }

          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      
      setState(() {
        _isValidatingAvailability = false;
      });

      if (unavailableTools.isNotEmpty && mounted) {
        _showUnavailableDevicesDialog(unavailableTools);
        return false;
      }
      
      return true;
    } catch (e) {
      setState(() {
        _isValidatingAvailability = false;
      });
      return false;
    }
  }

  /// Shows dialog with list of unavailable devices
  void _showUnavailableDevicesDialog(List<Map<String, dynamic>> unavailableTools) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Devices Not Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following devices cannot be rented for the selected period:',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...unavailableTools.map((item) {
                final tool = item['tool'] as ToolModel;
                final cartItem = item['cartItem'] as CartItemModel;
                final date = item['date'] as DateTime;
                final available = item['available'] as int;
                final totalQuantity = item['totalQuantity'] as int;
                final dateStr = '${date.day}.${date.month}.${date.year}';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name ?? 'Unknown tool',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date: $dateStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requested',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.orange.shade200,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$available/$totalQuantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        if (_selectedStartDate.isAfter(_selectedEndDate)) {
          _selectedEndDate = _selectedStartDate.add(const Duration(days: 1));
        }
        _datesSelected = false;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _datesSelected = true;
      });
      
      await _validateAvailabilityForSelectedPeriod();
    }
  }
  
  num get _totalAmount {
    num total = 0;
    final days = _selectedEndDate.difference(_selectedStartDate).inDays + 1;
    for (var item in _cartItems) {
      total += item.dailyRate * item.quantity * days;
    }
    return total;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms and Conditions of Use'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'By renting tools from MosPosudit, you agree to the following terms:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Damage Responsibility:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You are responsible for any damage, loss, or theft of the rented tools. Damages will be charged based on repair costs or replacement value.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '2. Return Time:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All tools must be returned by 12:00 PM (noon) on the return date. Returns after this time may be considered late and subject to additional charges.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '3. Late Returns:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Late returns will incur additional charges. A fee equivalent to 1.5x the daily rental rate will be applied for each day beyond the agreed return date.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '4. Tool Condition:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tools must be returned in the same condition as received. Normal wear and tear is expected, but excessive damage will result in additional charges.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '5. Insurance:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You are responsible for ensuring the tools are used safely and appropriately. We recommend obtaining appropriate insurance coverage for valuable items.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '6. Payment:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Payment must be completed before tools are collected. All charges, including damage fees and late return fees, must be settled promptly.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final now = DateTime.now();
      final startDate = _selectedStartDate.isBefore(now) ? now : _selectedStartDate;
      
      final unavailableTools = <Map<String, dynamic>>[];
      
      for (var cartItem in _cartItems) {
        final tool = _tools[cartItem.toolId];
        if (tool == null) {
          continue;
        }

        final availability = await _toolService.getAvailability(
          tool.id,
          startDate,
          _selectedEndDate,
        );

        if (availability == null) {
          continue;
        }

        var currentDate = startDate;
        while (currentDate.isBefore(_selectedEndDate) || currentDate.isAtSameMomentAs(_selectedEndDate)) {
          final dateKey = '${currentDate.year.toString().padLeft(4, '0')}-'
              '${currentDate.month.toString().padLeft(2, '0')}-'
              '${currentDate.day.toString().padLeft(2, '0')}';
          
          final available = availability.getAvailableQuantityForDateString(dateKey) ?? 0;
          
          if (available < cartItem.quantity) {
            unavailableTools.add({
              'tool': tool,
              'cartItem': cartItem,
              'date': currentDate,
              'available': available,
              'totalQuantity': availability.totalQuantity,
            });
            break;
          }

          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      
      if (unavailableTools.isNotEmpty) {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          _showUnavailableDevicesDialog(unavailableTools);
        }
        return;
      }

      final orderItems = _cartItems.map((item) => 
        OrderItemInsertRequest(
          toolId: item.toolId,
          quantity: item.quantity,
        )
      ).toList();

      final orderRequest = OrderInsertRequest(
        userId: userId,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        termsAccepted: _termsAccepted,
        orderItems: orderItems,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PayPalPaymentScreen(orderData: orderRequest),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Rental Period',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Start Date'),
                              subtitle: Text(
                                '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _selectStartDate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.event),
                              title: const Text('End Date'),
                              subtitle: Text(
                                '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: _isValidatingAvailability
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _selectEndDate,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._cartItems.map((item) {
                            final tool = _tools[item.toolId];
                            final days = _selectedEndDate.difference(_selectedStartDate).inDays + 1;
                            final itemTotal = item.dailyRate * item.quantity * days;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
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
                                          Text(
                                            _datesSelected
                                                ? '€${item.dailyRate.toStringAsFixed(2)}/day x $days days'
                                                : '€${item.dailyRate.toStringAsFixed(2)}/day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _datesSelected
                                              ? '€${itemTotal.toStringAsFixed(2)}'
                                              : '€${(item.dailyRate * item.quantity).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          
                          if (_datesSelected)
                            Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '€${_totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          Card(
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const Text('I accept the '),
                                      GestureDetector(
                                        onTap: _showTermsDialog,
                                        child: Text(
                                          'terms and conditions',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: _termsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAccepted = value ?? false;
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                                if (!_termsAccepted)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                    child: Text(
                                      'Please accept the terms and conditions to proceed',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isProcessing || !_termsAccepted || !_datesSelected) ? null : _handleCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_termsAccepted && !_isProcessing && _datesSelected) ? Colors.blue : Colors.grey,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Proceed to Payment',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

