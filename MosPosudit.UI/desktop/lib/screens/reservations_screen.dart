import 'package:flutter/material.dart';

class RentalsManagementPage extends StatelessWidget {
  const RentalsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upravljanje pozajmicama',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.purple),
                  SizedBox(height: 16),
                  Text('Funkcionalnost u razvoju', style: TextStyle(fontSize: 18)),
                  Text('Upravljanje pozajmicama će biti implementirano', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 