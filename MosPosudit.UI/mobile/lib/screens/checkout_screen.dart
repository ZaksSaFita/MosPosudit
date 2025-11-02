import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'package:mosposudit_shared/services/order_service.dart';
import 'package:mosposudit_shared/services/payment_service.dart';
import 'package:mosposudit_shared/services/auth_service.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/models/cart.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/tool_availability.dart';
import 'package:mosposudit_shared/widgets/availability_calendar.dart';
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
  ToolAvailabilityModel? _combinedAvailability;
  bool _isLoadingAvailability = false;
  
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
          // Set default dates from first item or use current date
          _selectedStartDate = items.first.startDate;
          _selectedEndDate = items.first.endDate;
        }
        _isLoading = false;
      });
      
      // Load combined availability for all tools in cart
      await _loadCombinedAvailability();
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadCombinedAvailability() async {
    if (_cartItems.isEmpty || _tools.isEmpty) return;
    
    setState(() {
      _isLoadingAvailability = true;
    });
    
    try {
      final now = DateTime.now();
      final startDate = _selectedStartDate.isBefore(now) ? now : _selectedStartDate;
      final endDate = _selectedEndDate.add(const Duration(days: 90)); // Load 90 days ahead
      
      // Load availability for all tools
      final availabilityList = <ToolAvailabilityModel>[];
      for (var cartItem in _cartItems) {
        final tool = _tools[cartItem.toolId];
        if (tool != null) {
          final availability = await _toolService.getAvailability(
            tool.id,
            startDate,
            endDate,
          );
          if (availability != null) {
            availabilityList.add(availability);
          }
        }
      }
      
      if (availabilityList.isEmpty) {
        setState(() {
          _combinedAvailability = null;
          _isLoadingAvailability = false;
        });
        return;
      }
      
      // Combine availability - take minimum available quantity for each day
      final firstAvailability = availabilityList.first;
      final combinedDailyAvailability = <String, int>{};
      
      // Get all date keys from the first availability
      for (var dateKey in firstAvailability.dailyAvailability.keys) {
        int minAvailable = firstAvailability.getAvailableQuantityForDateString(dateKey) ?? 0;
        
        // Find minimum across all tools for this date
        for (var availability in availabilityList) {
          final available = availability.getAvailableQuantityForDateString(dateKey) ?? 0;
          if (available < minAvailable) {
            minAvailable = available;
          }
        }
        
        combinedDailyAvailability[dateKey] = minAvailable;
      }
      
      // Total quantity is sum of all tool quantities
      int totalQuantity = 0;
      for (var cartItem in _cartItems) {
        final tool = _tools[cartItem.toolId];
        if (tool != null) {
          totalQuantity += (tool.quantity ?? 0);
        }
      }
      
      setState(() {
        _combinedAvailability = ToolAvailabilityModel(
          toolId: 0, // Combined availability for multiple tools
          totalQuantity: totalQuantity,
          dailyAvailability: combinedDailyAvailability,
        );
        _isLoadingAvailability = false;
      });
    } catch (e) {
      print('Error loading combined availability: $e');
      setState(() {
        _combinedAvailability = null;
        _isLoadingAvailability = false;
      });
    }
  }
  
  void _onDateRangeSelected(DateTime startDate, DateTime endDate) {
    setState(() {
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
    });
    // Reload availability for new date range
    _loadCombinedAvailability();
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
                  '2. Late Returns:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Late returns will incur additional charges. A fee equivalent to 1.5x the daily rental rate will be applied for each day beyond the agreed return date.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '3. Tool Condition:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tools must be returned in the same condition as received. Normal wear and tear is expected, but excessive damage will result in additional charges.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '4. Insurance:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You are responsible for ensuring the tools are used safely and appropriately. We recommend obtaining appropriate insurance coverage for valuable items.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '5. Payment:',
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

      // Create order items from cart
      final orderItems = _cartItems.map((item) => 
        OrderItemInsertRequest(
          toolId: item.toolId,
          quantity: item.quantity,
        )
      ).toList();

      // Prepare order data (but don't create in database yet)
      final orderRequest = OrderInsertRequest(
        userId: userId,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        termsAccepted: _termsAccepted,
        orderItems: orderItems,
      );

      // Reset processing state before navigation to prevent loading loop
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Navigate to PayPal payment - Order will be created AFTER successful payment
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PayPalPaymentScreen(orderData: orderRequest),
          ),
        );
      }
    } catch (e) {
      print('Error during checkout: $e');
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
                          // Date selection
                          const Text(
                            'Select Rental Period',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Calendar with availability
                          if (_isLoadingAvailability)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_combinedAvailability == null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('Loading availability...'),
                              ),
                            )
                          else
                            AvailabilityCalendar(
                              availability: _combinedAvailability!,
                              startDate: _selectedStartDate,
                              endDate: _selectedEndDate,
                              onDateRangeSelected: _onDateRangeSelected,
                              allowSelection: true,
                            ),
                          const SizedBox(height: 24),
                          
                          // Selected dates
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Start Date:'),
                                      Text(
                                        '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('End Date:'),
                                      Text(
                                        '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Days:'),
                                      Text(
                                        '${_selectedEndDate.difference(_selectedStartDate).inDays + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Order items summary
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
                              child: ListTile(
                                title: Text(tool?.name ?? 'Unknown tool'),
                                subtitle: Text('Quantity: ${item.quantity} x €${item.dailyRate.toStringAsFixed(2)}/day x $days days'),
                                trailing: Text(
                                  '€${itemTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          
                          // Total amount
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
                          
                          // Terms and conditions
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
                  
                  // Checkout button
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
                        onPressed: (_isProcessing || !_termsAccepted) ? null : _handleCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_termsAccepted && !_isProcessing) ? Colors.blue : Colors.grey,
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

