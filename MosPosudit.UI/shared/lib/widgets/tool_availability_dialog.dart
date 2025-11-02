import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../models/tool_availability.dart';
import '../services/tool_service.dart';
import 'availability_calendar.dart';

/// Dialog showing tool availability with color-coded calendar
class ToolAvailabilityDialog extends StatefulWidget {
  final ToolModel tool;
  final DateTime startDate;
  final DateTime endDate;

  const ToolAvailabilityDialog({
    super.key,
    required this.tool,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<ToolAvailabilityDialog> createState() => _ToolAvailabilityDialogState();

  /// Show the availability dialog
  static Future<void> show(
    BuildContext context,
    ToolModel tool, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    // Default: today as start, tomorrow as end (minimum 1 day)
    return showDialog(
      context: context,
      builder: (context) => ToolAvailabilityDialog(
        tool: tool,
        startDate: startDate ?? now,
        endDate: endDate ?? now.add(const Duration(days: 1)),
      ),
    );
  }
}

class _ToolAvailabilityDialogState extends State<ToolAvailabilityDialog> {
  final ToolService _toolService = ToolService();
  ToolAvailabilityModel? _availability;
  bool _isLoading = true;
  String? _error;
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // Initialize with today as start and tomorrow as end (minimum 1 day)
    final now = DateTime.now();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    // Load availability for next 3 months by default
    _loadAvailability();
  }
  

  Future<void> _loadAvailability({DateTime? customStartDate, DateTime? customEndDate}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use custom dates if provided, otherwise use selected dates or default to next 3 months
      final now = DateTime.now();
      final startDate = customStartDate ?? _selectedStartDate ?? now;
      // For end date, if we have selected dates, use them; otherwise load 90 days ahead
      final selectedEndDate = customEndDate ?? _selectedEndDate;
      final endDate = selectedEndDate ?? (customStartDate != null 
          ? customStartDate.add(const Duration(days: 90))
          : now.add(const Duration(days: 90)));
      
      final availability = await _toolService.getAvailability(
        widget.tool.id,
        startDate,
        endDate,
      );

      if (mounted) {
        setState(() {
          _availability = availability;
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

  void _onDateRangeSelected(DateTime startDate, DateTime endDate) {
    // Ensure minimum 1 day difference
    final daysDifference = endDate.difference(startDate).inDays;
    final validEndDate = daysDifference < 1 
        ? startDate.add(const Duration(days: 1)) 
        : endDate;
    
    setState(() {
      _selectedStartDate = startDate;
      _selectedEndDate = validEndDate;
    });

    // Reload availability for the selected date range
    _loadAvailability(customStartDate: startDate, customEndDate: validEndDate);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.tool.name ?? 'Tool',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading availability',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadAvailability,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_availability == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No availability data available'),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: AvailabilityCalendar(
                    availability: _availability!,
                    startDate: _selectedStartDate ?? DateTime.now(),
                    endDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 90)),
                    onDateRangeSelected: _onDateRangeSelected,
                    allowSelection: true,
                  ),
                ),
              ),
            
            // Selected dates info
            if (_selectedStartDate != null && _selectedEndDate != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Period:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - '
                          '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_availability != null)
                      Builder(
                        builder: (context) {
                          final days = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
                          // Get minimum available quantity across the selected period
                          int minAvailable = _availability!.totalQuantity;
                          var currentDate = _selectedStartDate!;
                          while (currentDate.isBefore(_selectedEndDate!) || 
                                 currentDate.isAtSameMomentAs(_selectedEndDate!)) {
                            final dateKey = '${currentDate.year.toString().padLeft(4, '0')}-'
                                '${currentDate.month.toString().padLeft(2, '0')}-'
                                '${currentDate.day.toString().padLeft(2, '0')}';
                            final available = _availability!.getAvailableQuantityForDateString(dateKey) ?? 0;
                            if (available < minAvailable) {
                              minAvailable = available;
                            }
                            currentDate = currentDate.add(const Duration(days: 1));
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Available:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '$minAvailable units',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: minAvailable > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

