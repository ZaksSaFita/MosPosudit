import 'package:flutter/material.dart';
import 'tools_screen.dart';
import 'categories_screen.dart';

class ToolManagementPage extends StatefulWidget {
  const ToolManagementPage({super.key});

  @override
  State<ToolManagementPage> createState() => _ToolManagementPageState();
}

class _ToolManagementPageState extends State<ToolManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tool Management',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.build_outlined),
                    text: 'Tools',
                  ),
                  Tab(
                    icon: Icon(Icons.category_outlined),
                    text: 'Categories',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ToolsManagementPage(),
              CategoriesManagementPage(),
            ],
          ),
        ),
      ],
    );
  }
}

