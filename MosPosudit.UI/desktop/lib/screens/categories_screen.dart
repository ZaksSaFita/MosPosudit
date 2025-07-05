import 'package:flutter/material.dart';

class CategoriesManagementPage extends StatelessWidget {
  const CategoriesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upravljanje kategorijama',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.category, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Funkcionalnost u razvoju', style: TextStyle(fontSize: 18)),
                  Text('CRUD operacije za kategorije će biti implementirane', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 