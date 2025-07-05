import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

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
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final t = await _dashboardService.fetchToolsCount();
      final u = await _dashboardService.fetchUsersCount();
      final r = await _dashboardService.fetchActiveRentalsCount();
      setState(() {
        toolsCount = t;
        usersCount = u;
        rentalsCount = r;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.build, size: 48, color: Colors.blue),
                                  const SizedBox(height: 16),
                                  const Text('Ukupno alata', style: TextStyle(fontSize: 18)),
                                  Text(toolsCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.people, size: 48, color: Colors.green),
                                  const SizedBox(height: 16),
                                  const Text('Registrovani korisnici', style: TextStyle(fontSize: 18)),
                                  Text(usersCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.assignment, size: 48, color: Colors.orange),
                                  const SizedBox(height: 16),
                                  const Text('Aktivne pozajmice', style: TextStyle(fontSize: 18)),
                                  Text(rentalsCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
} 