import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      ('DP-DEMO001', 'MG Road → Brigade Road', 'Completed', '₹89'),
      ('DP-DEMO002', 'Indiranagar → Koramangala', 'In Transit', '₹220'),
      ('DP-DEMO003', 'HSR Layout → Bellandur', 'Completed', '₹89'),
      ('DP-DEMO004', 'Whitefield → Marathahalli', 'Cancelled', '₹0'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = orders[i];
          final colorMap = {'Completed': Colors.green, 'In Transit': Colors.blue, 'Cancelled': Colors.red};
          return Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2, color: colorMap[o.$3]),
              title: Text(o.$1, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(o.$2, style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(o.$4, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(o.$3, style: TextStyle(fontSize: 11, color: colorMap[o.$3])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
