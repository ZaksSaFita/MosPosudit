import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../models/tool_availability.dart';
import '../services/tool_service.dart';
import 'availability_calendar.dart';

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

  static Future<void> show(
    BuildContext context,
    ToolModel tool, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
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
    final now = DateTime.now();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    _loadAvailability();
  }
  

  Future<void> _loadAvailability({DateTime? customStartDate, DateTime? customEndDate}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final startDate = now;
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
    final daysDifference = endDate.difference(startDate).inDays;
    final validEndDate = daysDifference < 1 
        ? startDate.add(const Duration(days: 1)) 
        : endDate;
    
    setState(() {
      _selectedStartDate = startDate;
      _selectedEndDate = validEndDate;
    });
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
                onDateRangeSelected: null,
                allowSelection: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}

