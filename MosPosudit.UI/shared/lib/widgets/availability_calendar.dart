import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/tool_availability.dart';

/// Color-coded calendar widget showing tool availability per day
class AvailabilityCalendar extends StatefulWidget {
  final ToolAvailabilityModel availability;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime startDate, DateTime endDate)? onDateRangeSelected;
  final bool allowSelection;

  const AvailabilityCalendar({
    super.key,
    required this.availability,
    required this.startDate,
    required this.endDate,
    this.onDateRangeSelected,
    this.allowSelection = true,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isSelectingStart = true; // Track whether we're selecting start or end date

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.startDate;
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    _isSelectingStart = true; // Start with selecting start date
  }
  
  @override
  void didUpdateWidget(AvailabilityCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected dates if widget dates changed
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      setState(() {
        _selectedStartDate = widget.startDate;
        _selectedEndDate = widget.endDate;
        _focusedDay = widget.startDate;
        _isSelectingStart = true; // Reset to selecting start date
      });
    }
  }

  /// Get color for a day based on availability
  Color? _getDayColor(DateTime day) {
    final dateKey = _formatDate(day);
    final available = widget.availability.getAvailableQuantityForDateString(dateKey);
    
    if (available == null) {
      return Colors.grey.shade300; // Date not in range
    }

    final total = widget.availability.totalQuantity;
    if (total == 0) return Colors.red.shade700;

    final percentage = available / total;

    if (available == 0) {
      return Colors.red.shade700; // Unavailable
    } else if (percentage <= 0.25) {
      return Colors.orange.shade600; // Low availability (1-25%)
    } else if (percentage <= 0.50) {
      return Colors.yellow.shade600; // Medium availability (25-50%)
    } else {
      return Colors.green.shade600; // High availability (>50%)
    }
  }

  /// Get decoration for a day
  BoxDecoration? _getDayDecoration(DateTime day) {
    final color = _getDayColor(day);
    final dateKey = _formatDate(day);
    final available = widget.availability.getAvailableQuantityForDateString(dateKey);

    if (available == null || !widget.allowSelection) {
      return null;
    }

    // Selected day range
    final isStart = _selectedStartDate != null && 
                    isSameDay(_selectedStartDate!, day);
    final isEnd = _selectedEndDate != null && 
                  isSameDay(_selectedEndDate!, day);
    final isInRange = _selectedStartDate != null && 
                      _selectedEndDate != null &&
                      day.isAfter(_selectedStartDate!) &&
                      day.isBefore(_selectedEndDate!);

    if (isStart || isEnd) {
      return BoxDecoration(
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      );
    } else if (isInRange) {
      return BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      );
    }

    // Default decoration with availability color
    return BoxDecoration(
      color: color?.withOpacity(0.3),
      border: Border.all(color: color ?? Colors.grey, width: 1),
      borderRadius: BorderRadius.circular(8),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!widget.allowSelection) return;

    setState(() {
      if (_isSelectingStart) {
        // First click (or third, fifth, etc.) - set start date
        _selectedStartDate = selectedDay;
        _selectedEndDate = selectedDay;
        _isSelectingStart = false; // Next click will be for end date
      } else {
        // Second click (or fourth, sixth, etc.) - set end date
        // Ensure minimum 1 day difference
        if (selectedDay.isBefore(_selectedStartDate!) || 
            isSameDay(_selectedStartDate!, selectedDay)) {
          // If selected date is before or same as start, set end to start + 1 day
          _selectedEndDate = _selectedStartDate!.add(const Duration(days: 1));
        } else {
          _selectedEndDate = selectedDay;
        }
        _isSelectingStart = true; // Next click will be for new start date (cycle repeats)
        
        // Notify callback if we have valid date range (minimum 1 day)
        if (widget.onDateRangeSelected != null && 
            _selectedStartDate != null && 
            _selectedEndDate != null &&
            _selectedEndDate!.difference(_selectedStartDate!).inDays >= 1) {
          widget.onDateRangeSelected!(_selectedStartDate!, _selectedEndDate!);
        }
      }
      
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)), // Allow viewing up to 1 year ahead
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month, // Always show month format
          selectedDayPredicate: (day) {
            if (!widget.allowSelection) return false;
            return (_selectedStartDate != null && isSameDay(_selectedStartDate!, day)) ||
                   (_selectedEndDate != null && isSameDay(_selectedEndDate!, day));
          },
          rangeStartDay: _selectedStartDate,
          rangeEndDay: _selectedEndDate,
          rangeSelectionMode: widget.allowSelection ? RangeSelectionMode.enforced : RangeSelectionMode.disabled,
          onDaySelected: _onDaySelected,
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          // Remove onFormatChanged to prevent format changes
          headerStyle: HeaderStyle(
            formatButtonVisible: false, // Hide format button (month/week)
            titleCentered: true,
            formatButtonShowsNext: false,
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue.shade200,
              shape: BoxShape.circle,
            ),
            rangeStartDecoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            rangeEndDecoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            withinRangeDecoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, events) {
              final dateKey = _formatDate(date);
              final available = widget.availability.getAvailableQuantityForDateString(dateKey);
              
              if (available == null) {
                return null; // Use default styling for dates outside range
              }

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: _getDayDecoration(date),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getDayColor(date),
                      ),
                    ),
                    if (available != null)
                      Text(
                        '$available/${widget.availability.totalQuantity}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: _getDayColor(date),
                        ),
                      ),
                  ],
                ),
              );
            },
            todayBuilder: (context, date, events) {
              final dateKey = _formatDate(date);
              final available = widget.availability.getAvailableQuantityForDateString(dateKey);
              
              if (available == null) {
                return null;
              }

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: _getDayDecoration(date),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getDayColor(date),
                      ),
                    ),
                    Text(
                      '$available/${widget.availability.totalQuantity}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _getDayColor(date),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

