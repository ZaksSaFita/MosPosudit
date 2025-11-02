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
      // Always load availability from today to 90 days ahead, regardless of selected dates
      // This ensures all dates in the calendar view have availability data
      final now = DateTime.now();
      final startDate = now; // Always start from today
      // Load 90 days ahead to ensure calendar has full availability data
      final endDate = now.add(const Duration(days: 90));
      
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

    // Don't reload availability - we already have data from today to 90 days ahead
    // Availability data is sufficient for all dates in the calendar view
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.tool.name ?? 'Tool',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
              AvailabilityCalendar(
                availability: _availability!,
                startDate: _selectedStartDate ?? DateTime.now(),
                endDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 90)),
                onDateRangeSelected: null, // No date selection in availability dialog
                allowSelection: false, // Disable date selection - only viewing availability
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}

