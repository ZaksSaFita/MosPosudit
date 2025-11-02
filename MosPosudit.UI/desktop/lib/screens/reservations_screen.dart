import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/order_service.dart';
import 'package:mosposudit_shared/models/order.dart';
import 'package:intl/intl.dart';
import '../core/snackbar_helper.dart';

class ReservationsManagementPage extends StatefulWidget {
  const ReservationsManagementPage({super.key});

  @override
  State<ReservationsManagementPage> createState() => _ReservationsManagementPageState();
}

enum ViewMode { card, table }

class _ReservationsManagementPageState extends State<ReservationsManagementPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.card;
  
  // Pagination for table view
  int _currentPage = 1;
  int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _orderService.fetchOrders();
      setState(() {
        _orders = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<OrderModel> get _filteredOrders {
    var filtered = _orders;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final userName = (order.userFullName ?? '').toLowerCase();
        final userEmail = (order.userEmail ?? '').toLowerCase();
        final toolNames = order.orderItems.map((item) => (item.toolName ?? '').toLowerCase()).join(' ');
        final query = _searchQuery.toLowerCase();
        return userName.contains(query) || 
               userEmail.contains(query) || 
               toolNames.contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  List<OrderModel> get _paginatedOrders {
    if (_viewMode != ViewMode.table) {
      return _filteredOrders;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredOrders.sublist(
      startIndex,
      endIndex > _filteredOrders.length ? _filteredOrders.length : endIndex,
    );
  }
  
  int get _totalPages {
    if (_viewMode != ViewMode.table) return 1;
    return (_filteredOrders.length / _itemsPerPage).ceil();
  }

  String _formatCurrency(num? value) {
    if (value == null) return '\$0.00';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  Future<void> _deleteOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Delete',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this reservation?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.userFullName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat('MMM dd, yyyy').format(order.startDate)} - ${DateFormat('MMM dd, yyyy').format(order.endDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _orderService.delete(order.id);
        SnackbarHelper.showSuccess(context, 'Reservation deleted successfully');
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reservations Management',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _viewMode = ViewMode.card;
                                _currentPage = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _viewMode == ViewMode.card ? Colors.blue : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                              ),
                              child: Icon(
                                Icons.view_module,
                                color: _viewMode == ViewMode.card ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _viewMode = ViewMode.table;
                                _currentPage = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _viewMode == ViewMode.table ? Colors.blue : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                              ),
                              child: Icon(
                                Icons.table_rows,
                                color: _viewMode == ViewMode.table ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1; // Reset pagination on search
                });
              },
              decoration: InputDecoration(
                hintText: 'Search reservations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No reservations match your search'
                                        : 'No reservations available',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : _viewMode == ViewMode.card
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _filteredOrders.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final order = _filteredOrders[index];
                                          return _ReservationListCard(
                                            order: order,
                                            index: index,
                                            onDelete: () => _deleteOrder(order),
                                            formatCurrency: _formatCurrency,
                                            calculateDays: _calculateDays,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _ReservationsTableView(
                                        orders: _paginatedOrders,
                                        allOrders: _filteredOrders,
                                        currentPage: _currentPage,
                                        itemsPerPage: _itemsPerPage,
                                        totalPages: _totalPages,
                                        onPageChanged: (page) {
                                          setState(() {
                                            _currentPage = page;
                                          });
                                        },
                                        onDelete: (order) => _deleteOrder(order),
                                        formatCurrency: _formatCurrency,
                                        calculateDays: _calculateDays,
                                      ),
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

class _ReservationListCard extends StatelessWidget {
  final OrderModel order;
  final int index;
  final VoidCallback onDelete;
  final String Function(num?) formatCurrency;
  final int Function(DateTime, DateTime) calculateDays;

  const _ReservationListCard({
    required this.order,
    required this.index,
    required this.onDelete,
    required this.formatCurrency,
    required this.calculateDays,
  });

  String get _toolNames {
    if (order.orderItems.isEmpty) return 'No tools';
    if (order.orderItems.length == 1) {
      return order.orderItems.first.toolName ?? 'Unknown Tool';
    }
    return '${order.orderItems.length} tools';
  }

  @override
  Widget build(BuildContext context) {
    final days = calculateDays(order.startDate, order.endDate);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sequential number
            Container(
              width: 40,
              alignment: Alignment.topCenter,
              child: Text(
                '${(index + 1).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment,
                size: 30,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 20),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.userFullName ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tools
                  Row(
                    children: [
                      Icon(Icons.build_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _toolNames,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Dates
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(order.startDate)} - ${DateFormat('MMM dd, yyyy').format(order.endDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          '$days day${days != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total amount and status
                  Row(
                    children: [
                      Icon(Icons.attach_money_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formatCurrency(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.isReturned ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: order.isReturned ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              order.isReturned ? Icons.check_circle_outline : Icons.pending_outlined,
                              size: 14,
                              color: order.isReturned ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.isReturned ? 'Returned' : 'Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: order.isReturned ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action button
            SizedBox(
              width: 140,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

class _ReservationsTableView extends StatelessWidget {
  final List<OrderModel> orders;
  final List<OrderModel> allOrders;
  final int currentPage;
  final int itemsPerPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<OrderModel> onDelete;
  final String Function(num?) formatCurrency;
  final int Function(DateTime, DateTime) calculateDays;

  const _ReservationsTableView({
    required this.orders,
    required this.allOrders,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onDelete,
    required this.formatCurrency,
    required this.calculateDays,
  });

  String _getToolNames(OrderModel order) {
    if (order.orderItems.isEmpty) return 'No tools';
    if (order.orderItems.length == 1) {
      return order.orderItems.first.toolName ?? 'Unknown';
    }
    return '${order.orderItems.length} tools';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 60,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 120,
                  columnSpacing: 24,
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                  columns: const [
                    DataColumn(
                      label: Text(
                        '#',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'User',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tools',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Start Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'End Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Duration',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: orders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final order = entry.value;
                    final globalIndex = (currentPage - 1) * itemsPerPage + index;
                    final days = calculateDays(order.startDate, order.endDate);

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${globalIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  order.userFullName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              _getToolNames(order),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('MMM dd, yyyy').format(order.startDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('MMM dd, yyyy').format(order.endDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '$days day${days != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency(order.totalAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.isReturned ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: order.isReturned ? Colors.green.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.isReturned ? Icons.check_circle_outline : Icons.pending_outlined,
                                  size: 14,
                                  color: order.isReturned ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.isReturned ? 'Returned' : 'Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: order.isReturned ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          OutlinedButton.icon(
                            onPressed: () => onDelete(order),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        // Pagination controls
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  tooltip: 'Previous',
                ),
                const SizedBox(width: 16),
                Text(
                  'Page $currentPage of $totalPages (${allOrders.length} total)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  tooltip: 'Next',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

