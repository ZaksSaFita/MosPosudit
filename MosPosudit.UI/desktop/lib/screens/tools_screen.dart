import 'package:flutter/material.dart';

class ToolsManagementPage extends StatelessWidget {
  const ToolsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upravljanje alatima',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.build, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Funkcionalnost u razvoju', style: TextStyle(fontSize: 18)),
                  Text('CRUD operacije za alate će biti implementirane', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 