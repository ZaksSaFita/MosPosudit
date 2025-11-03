import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/dashboard_service.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  int toolsCount = 0;
  int usersCount = 0;
  int rentalsCount = 0;
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> recentPayments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        _dashboardService.fetchToolsCount(),
        _dashboardService.fetchUsersCount(),
        _dashboardService.fetchActiveRentalsCount(),
        _dashboardService.fetchRecentOrders(limit: 5),
        _dashboardService.fetchRecentPayments(limit: 5),
      ]);

      setState(() {
        toolsCount = results[0] as int;
        usersCount = results[1] as int;
        rentalsCount = results[2] as int;
        recentOrders = results[3] as List<Map<String, dynamic>>;
        recentPayments = results[4] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatCurrency(num amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: fetchData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: fetchData,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Tools',
                              value: toolsCount.toString(),
                              icon: Icons.build,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Registered Users',
                              value: usersCount.toString(),
                              icon: Icons.people,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Active Rentals',
                              value: rentalsCount.toString(),
                              icon: Icons.assignment,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Revenue (Last 7 Days)',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(Icons.trending_up, color: Colors.green.shade700),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 200,
                                      child: _RevenueChart(payments: recentPayments),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Recent Reservations',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: recentOrders.isEmpty
                                          ? Center(
                                              child: Text(
                                                'No reservations',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: recentOrders.length,
                                              itemBuilder: (context, index) {
                                                final order = recentOrders[index];
                                                final createdAt = order['createdAt'] != null
                                                    ? DateTime.tryParse(order['createdAt'].toString())
                                                    : null;
                                                return _OrderListItem(
                                                  orderId: order['id'] ?? order['Id'] ?? 0,
                                                  user: order['userFullName'] ?? order['UserFullName'] ?? 'N/A',
                                                  amount: order['totalAmount'] ?? order['TotalAmount'] ?? 0,
                                                  date: createdAt,
                                                  isReturned: order['isReturned'] ?? order['IsReturned'] ?? false,
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Recent Payments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                recentPayments.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Center(
                                          child: Text(
                                            'No payments',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('ID')),
                                          DataColumn(label: Text('Order ID')),
                                          DataColumn(label: Text('Amount')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Transaction ID')),
                                        ],
                                        rows: recentPayments.map((payment) {
                                          final paymentDate = payment['paymentDate'] != null
                                              ? DateTime.tryParse(payment['paymentDate'].toString())
                                              : null;
                                          return DataRow(
                                            cells: [
                                              DataCell(Text('#${payment['id'] ?? payment['Id'] ?? 'N/A'}')),
                                              DataCell(Text('#${payment['orderId'] ?? payment['OrderId'] ?? 'N/A'}')),
                                              DataCell(Text(
                                                _formatCurrency(
                                                  payment['amount'] ?? payment['Amount'] ?? 0,
                                                ),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              )),
                                              DataCell(
                                                Chip(
                                                  label: Text(
                                                    (payment['isCompleted'] ?? payment['IsCompleted'] ?? false)
                                                        ? 'Completed'
                                                        : 'Pending',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  backgroundColor: (payment['isCompleted'] ?? payment['IsCompleted'] ?? false)
                                                      ? Colors.green.shade100
                                                      : Colors.orange.shade100,
                                                ),
                                              ),
                                              DataCell(Text(_formatDate(paymentDate))),
                                              DataCell(
                                                Text(
                                                  payment['transactionId'] ?? payment['TransactionId'] ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                              ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.shade50,
              color.shade100,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> payments;

  const _RevenueChart({required this.payments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailyRevenue = <DateTime, num>{};
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      dailyRevenue[DateTime(date.year, date.month, date.day)] = 0;
    }

    for (var payment in payments) {
      final paymentDate = payment['paymentDate'] != null
          ? DateTime.tryParse(payment['paymentDate'].toString())
          : null;
      if (paymentDate != null && 
          (payment['isCompleted'] ?? payment['IsCompleted'] ?? false)) {
        final dateKey = DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
        if (dailyRevenue.containsKey(dateKey)) {
          dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + (payment['amount'] ?? payment['Amount'] ?? 0);
        }
      }
    }

    final sortedDates = dailyRevenue.keys.toList()..sort();
    final maxRevenue = dailyRevenue.values.isEmpty ? 1.0 : dailyRevenue.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sortedDates.map((date) {
        final revenue = dailyRevenue[date] ?? 0;
        final height = maxRevenue > 0 ? (revenue / maxRevenue) * 160 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  revenue.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: height.clamp(0, 160),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final int orderId;
  final String user;
  final num amount;
  final DateTime? date;
  final bool isReturned;

  const _OrderListItem({
    required this.orderId,
    required this.user,
    required this.amount,
    required this.date,
    required this.isReturned,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isReturned ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReturned ? Icons.check_circle : Icons.pending,
              color: isReturned ? Colors.green.shade700 : Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation #$orderId - $user',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null ? DateFormat('dd.MM.yyyy HH:mm').format(date!) : 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
