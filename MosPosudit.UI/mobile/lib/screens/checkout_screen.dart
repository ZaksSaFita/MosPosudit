import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mosposudit_shared/models/cart.dart';
import 'package:mosposudit_shared/services/rental_service.dart';
import 'package:mosposudit_shared/services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final RentalService _rentalService = RentalService();
  final CartService _cartService = CartService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;
  Set<DateTime> _bookedDates = {};
  bool _isLoadingBookedDates = true;
  bool _isCreatingRental = false;

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    setState(() {
      _isLoadingBookedDates = true;
    });

    try {
      // Get all tool IDs from cart
      final toolIds = widget.cartItems.map((item) => item.toolId).toSet().toList();
      
      // Get booked dates for all tools from API
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 365));
      
      final bookedDatesList = await _rentalService.getAllBookedDatesForTools(
        toolIds: toolIds,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (mounted) {
        setState(() {
          _bookedDates = bookedDatesList.toSet();
          _isLoadingBookedDates = false;
        });
      }
    } catch (e) {
      print('Error loading booked dates: $e');
      if (mounted) {
        setState(() {
          _isLoadingBookedDates = false;
        });
      }
    }
  }

  bool _isDateBooked(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _bookedDates.contains(normalizedDate);
  }

  bool _isDateSelectable(DateTime date) {
    // Don't allow dates in the past
    final today = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    if (normalizedDate.isBefore(normalizedToday)) {
      return false;
    }
    
    // Don't allow booked dates
    if (_isDateBooked(date)) {
      return false;
    }
    
    return true;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isDateSelectable(selectedDay)) {
      return;
    }

    setState(() {
      _focusedDay = focusedDay;
      
      if (_selectedStartDate == _selectedEndDate || _selectedEndDate == null) {
        // Starting new selection
        _selectedStartDate = selectedDay;
        _selectedEndDate = null;
      } else if (selectedDay.isBefore(_selectedStartDate)) {
        // Selected date is before start date, make it new start
        _selectedStartDate = selectedDay;
        _selectedEndDate = null;
      } else {
        // Selected date is after start date, make it end date
        _selectedEndDate = selectedDay;
      }
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    if (start == null) {
      setState(() {
        _selectedStartDate = DateTime.now();
        _selectedEndDate = null;
        _focusedDay = focusedDay;
      });
      return;
    }

    // Validate that all dates in range are selectable
    if (end != null) {
      DateTime current = start;
      bool allSelectable = true;
      
      // Check all dates from start to end (inclusive)
      while (current.isBefore(end) || isSameDay(current, end)) {
        if (!_isDateSelectable(current)) {
          allSelectable = false;
          break;
        }
        if (isSameDay(current, end)) break;
        current = current.add(const Duration(days: 1));
      }

      if (allSelectable) {
        setState(() {
          _selectedStartDate = start;
          _selectedEndDate = end;
          _focusedDay = focusedDay;
        });
      }
    } else {
      // Only start date selected, validate it
      if (_isDateSelectable(start)) {
        setState(() {
          _selectedStartDate = start;
          _selectedEndDate = null;
          _focusedDay = focusedDay;
        });
      }
    }
  }

  int _calculateDays() {
    if (_selectedEndDate == null) return 0;
    return _selectedEndDate!.difference(_selectedStartDate).inDays + 1;
  }

  num _calculateTotal() {
    if (_selectedEndDate == null) return 0;
    final days = _calculateDays();
    num total = 0;
    for (var item in widget.cartItems) {
      total += item.dailyRate * item.quantity * days;
    }
    return total;
  }

  Future<void> _createRental() async {
    if (_selectedEndDate == null) return;

    setState(() {
      _isCreatingRental = true;
    });

    try {
      // Prepare items for rental creation
      final items = widget.cartItems.map((cartItem) => {
        'toolId': cartItem.toolId,
        'quantity': cartItem.quantity,
        'dailyRate': cartItem.dailyRate,
      }).toList();

      // Create rental via API
      final rental = await _rentalService.createRental(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate!,
        items: items,
      );

      // Clear cart after successful rental creation
      await _cartService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home/cart screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error creating rental: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create rental: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCreatingRental = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Rental Dates'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLoadingBookedDates)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedStartDate, day) ||
                              (_selectedEndDate != null && 
                               isSameDay(_selectedEndDate, day));
                        },
                        rangeStartDay: _selectedStartDate,
                        rangeEndDay: _selectedEndDate,
                        rangeSelectionMode: RangeSelectionMode.enforced,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableGestures: AvailableGestures.all,
                        onDaySelected: _onDaySelected,
                        onRangeSelected: _onRangeSelected,
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        enabledDayPredicate: _isDateSelectable,
                        calendarStyle: CalendarStyle(
                          // Style for selected range
                          rangeStartDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          withinRangeDecoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          // Style for booked dates (red) - these are disabled
                          disabledDecoration: BoxDecoration(
                            color: Colors.red.shade300,
                            shape: BoxShape.circle,
                          ),
                          disabledTextStyle: TextStyle(
                            color: Colors.red.shade900,
                            decoration: TextDecoration.lineThrough,
                          ),
                          // Style for available dates - green background
                          defaultDecoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.shade400, width: 2),
                          ),
                          weekendDecoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(
                            color: Colors.black87,
                          ),
                          weekendTextStyle: TextStyle(
                            color: Colors.black87,
                          ),
                          todayTextStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          outsideDaysVisible: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, date, events) {
                            final normalizedDate = DateTime(date.year, date.month, date.day);
                            final isBooked = _isDateBooked(normalizedDate);
                            final isSelectable = _isDateSelectable(normalizedDate);
                            
                            if (!isSelectable && !isBooked) {
                              // Past dates that are not booked
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            return null; // Use default styling
                          },
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.black87),
                          weekendStyle: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  // Legend
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(Colors.green.shade50, 'Available'),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.red.shade300, 'Booked'),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.blue, 'Selected'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Summary and proceed button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            margin: const EdgeInsets.only(bottom: 16),
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
                if (_selectedEndDate != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rental Period:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year} - '
                        '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Days:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${_calculateDays()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '€${_calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_selectedEndDate != null && !_isCreatingRental)
                        ? () => _createRental()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isCreatingRental
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _selectedEndDate != null
                                ? 'Confirm Reservation'
                                : 'Select End Date',
                            style: const TextStyle(fontSize: 16),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

