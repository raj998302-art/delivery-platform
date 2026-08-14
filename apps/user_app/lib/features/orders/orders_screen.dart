import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      ('DP-DEMO001', 'MG Road → Brigade Road', 'Delivered', '₹139', Colors.green),
      ('DP-DEMO002', 'Indiranagar → Koramangala', 'In Transit', '₹220', Colors.blue),
      ('DP-DEMO003', 'Whitefield → Marathahalli', 'Cancelled', '₹0', Colors.red),
      ('DP-DEMO004', 'HSR Layout → Bellandur', 'Completed', '₹89', Colors.green),
      ('DP-DEMO005', 'Jayanagar → JP Nagar', 'Delivered', '₹165', Colors.green),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = orders[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: o.$5.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_rounded, color: o.$5, size: 22),
              ),
              title: Text(o.$1, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(o.$2, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(o.$3, style: TextStyle(fontSize: 11, color: o.$5, fontWeight: FontWeight.w600)),
                ],
              ),
              trailing: Text(o.$4, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
