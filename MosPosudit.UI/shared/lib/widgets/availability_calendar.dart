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
    // Only update selected dates if widget dates changed externally (not from user selection)
    // Don't reset focused day or selection state - keep user's current view
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      // Only update if user hasn't made a selection yet, or if dates changed from outside
      // Preserve user's selection if they've already selected dates
      if (_selectedStartDate == oldWidget.startDate && _selectedEndDate == oldWidget.endDate) {
        // User hasn't made a custom selection, use widget dates
        setState(() {
          _selectedStartDate = widget.startDate;
          _selectedEndDate = widget.endDate;
          // Don't reset _focusedDay - keep current calendar view
          // Don't reset _isSelectingStart - preserve user's selection state
        });
      }
      // If user has made a selection, don't override it with widget dates
    }
  }

  /// Get color for a day based on availability
  /// Green if no devices reserved, Orange if at least one reserved (but not all), Dark red if all reserved
  Color? _getDayColor(DateTime day) {
    final dateKey = _formatDate(day);
    final available = widget.availability.getAvailableQuantityForDateString(dateKey);
    
    if (available == null) {
      return Colors.grey.shade300; // Date not in range
    }

    final total = widget.availability.totalQuantity;
    if (total == 0) return Colors.red.shade800;

    // Three color scheme:
    if (available == total) {
      return Colors.green.shade600; // No devices reserved
    } else if (available == 0) {
      return Colors.red.shade800; // All devices reserved (dark red)
    } else {
      return Colors.orange.shade600; // At least one reserved (but not all) - beautiful orange
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
        color: Colors.yellow.shade200,
        border: Border.all(color: Colors.yellow.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      );
    } else if (isInRange) {
      return BoxDecoration(
        color: Colors.yellow.shade100,
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
        // First click (or third, fifth, etc.) - set start date and automatically set end date to same day
        // This allows 1-day rental with single click
        _selectedStartDate = selectedDay;
        _selectedEndDate = selectedDay; // Automatically set end date to same day (1-day rental by default)
        _isSelectingStart = false; // Next click will be for end date (optional)
        
        // Immediately notify callback with 1-day rental (start and end same day)
        if (widget.onDateRangeSelected != null) {
          widget.onDateRangeSelected!(_selectedStartDate!, _selectedEndDate!);
        }
      } else {
        // Second click (or fourth, sixth, etc.) - optionally set end date for multi-day rental
        // If user clicks same day again, keeps 1-day rental
        // If user clicks different day, sets end date to that day for multi-day rental
        if (selectedDay.isBefore(_selectedStartDate!)) {
          // If selected date is before start, don't allow it - keep end same as start (1 day rental)
          _selectedEndDate = _selectedStartDate!;
        } else {
          // Selected date is same as or after start - use selected day as end date
          // If same day: stays 1-day rental
          // If later day: becomes multi-day rental
          _selectedEndDate = selectedDay;
        }
        _isSelectingStart = true; // Next click will be for new start date (cycle repeats)
        
        // Notify callback after setting end date
        if (widget.onDateRangeSelected != null && 
            _selectedStartDate != null && 
            _selectedEndDate != null) {
          widget.onDateRangeSelected!(_selectedStartDate!, _selectedEndDate!);
        }
      }
      
      // Don't change focused day - keep current calendar view
      // Only update if focusedDay is in a different month
      final currentMonth = DateTime(_focusedDay.year, _focusedDay.month);
      final selectedMonth = DateTime(focusedDay.year, focusedDay.month);
      if (currentMonth != selectedMonth) {
        _focusedDay = focusedDay;
      }
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
            // Don't use selectedDayPredicate - we'll handle selection visually in defaultBuilder
            return false;
          },
          // Don't use TableCalendar's range selection - we'll handle it manually with custom builders
          rangeSelectionMode: RangeSelectionMode.disabled,
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
            // Disable default styling for selected days - we'll use custom builders
            selectedDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            todayDecoration: BoxDecoration(
              color: Colors.transparent, // Let todayBuilder handle it
              borderRadius: BorderRadius.circular(8),
            ),
            // Disable default range styling - we'll use custom builders
            rangeStartDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            rangeEndDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            withinRangeDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            // Disable default styling - use defaultBuilder for all dates
            defaultDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            defaultTextStyle: const TextStyle(color: Colors.black87),
            weekendTextStyle: const TextStyle(color: Colors.black87),
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, events) {
              final dateKey = _formatDate(date);
              final available = widget.availability.getAvailableQuantityForDateString(dateKey);
              
              // If selection is disabled, don't show yellow highlight for selected range
              // Only show availability colors (green/red)
              if (!widget.allowSelection) {
                // For dates outside range, show availability if available
                if (available == null) {
                  // Date not in availability range - show with grey color
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                // Date has availability - show original colors (green/red)
                final color = _getDayColor(date);
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color?.withOpacity(0.3),
                    border: Border.all(color: color ?? Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color ?? Colors.black87,
                        ),
                      ),
                      Text(
                        '$available/${widget.availability.totalQuantity}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: color ?? Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Selection enabled - check if date is part of selected range
              final isStart = _selectedStartDate != null && 
                            isSameDay(_selectedStartDate!, date);
              final isEnd = _selectedEndDate != null && 
                          isSameDay(_selectedEndDate!, date);
              final isInRange = _selectedStartDate != null && 
                              _selectedEndDate != null &&
                              date.isAfter(_selectedStartDate!) &&
                              date.isBefore(_selectedEndDate!);

              // If date is in range, show yellow background
              if (isStart || isEnd || isInRange) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade200,
                    border: Border.all(color: Colors.yellow.shade700, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (available != null)
                        Text(
                          '$available/${widget.availability.totalQuantity}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                );
              }

              // For dates outside range, show availability if available
              if (available == null) {
                // Date not in availability range - show with grey color
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }

              // Date outside range but has availability - show original colors
              final color = _getDayColor(date);
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.3),
                  border: Border.all(color: color ?? Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color ?? Colors.black87,
                      ),
                    ),
                    Text(
                      '$available/${widget.availability.totalQuantity}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: color ?? Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
            selectedBuilder: (context, date, events) {
              // This will be called for dates matching selectedDayPredicate
              // We'll handle them in defaultBuilder, so return null here
              return null;
            },
            todayBuilder: (context, date, events) {
              // Handle today like any other date - use same logic as defaultBuilder
              final dateKey = _formatDate(date);
              final available = widget.availability.getAvailableQuantityForDateString(dateKey);
              
              if (available == null) {
                return null;
              }

              final color = _getDayColor(date);

              // If selection is disabled, don't show yellow highlight
              if (!widget.allowSelection) {
                // Just show availability colors with blue border for today
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color?.withOpacity(0.3),
                    border: Border.all(color: Colors.blue.shade700, width: 2), // Blue border for today
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color ?? Colors.black87,
                        ),
                      ),
                      Text(
                        '$available/${widget.availability.totalQuantity}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: color ?? Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Selection enabled - check if date is part of selected range
              final isStart = _selectedStartDate != null && 
                            isSameDay(_selectedStartDate!, date);
              final isEnd = _selectedEndDate != null && 
                          isSameDay(_selectedEndDate!, date);
              final isInRange = _selectedStartDate != null && 
                              _selectedEndDate != null &&
                              date.isAfter(_selectedStartDate!) &&
                              date.isBefore(_selectedEndDate!);

              // Determine decoration based on whether date is in range
              BoxDecoration decoration;
              if (isStart || isEnd || isInRange) {
                // Start, end, or dates within range - all yellow background
                decoration = BoxDecoration(
                  color: Colors.yellow.shade200,
                  border: Border.all(color: Colors.yellow.shade700, width: 2),
                  borderRadius: BorderRadius.circular(8),
                );
              } else {
                // Outside range - original availability colors with blue highlight for today
                decoration = BoxDecoration(
                  color: color?.withOpacity(0.3),
                  border: Border.all(color: Colors.blue.shade700, width: 2), // Blue border for today
                  borderRadius: BorderRadius.circular(8),
                );
              }

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: decoration,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (isStart || isEnd || isInRange) ? Colors.black87 : (color ?? Colors.black87),
                      ),
                    ),
                    Text(
                      '$available/${widget.availability.totalQuantity}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: (isStart || isEnd || isInRange) ? Colors.black87 : (color ?? Colors.black87),
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

