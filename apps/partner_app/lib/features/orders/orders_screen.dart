import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic>? _orders;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.getMyOrders(page: 1, pageSize: 50);
      setState(() {
        _orders = res['orders'] as List?;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _orders = [];
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.login, color: Colors.grey.shade500, size: 48),
                            const SizedBox(height: 12),
                            const Text('Login required', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : (_orders == null || _orders!.isEmpty)
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 48),
                                const SizedBox(height: 12),
                                const Text('No orders yet', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                const Text('Go online to start receiving orders', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final o = _orders![i];
                          final code = o['code'] as String? ?? '';
                          final status = o['state'] as String? ?? 'UNKNOWN';
                          final amount = (o['totalAmount'] as num?)?.toInt() ?? 0;
                          final pickup = o['pickupAddress'] as String? ?? '';
                          final drop = o['dropAddress'] as String? ?? '';
                          final colorMap = {
                            'COMPLETED': Colors.green,
                            'DELIVERED': Colors.green,
                            'IN_TRANSIT': Colors.blue,
                            'PICKED_UP': Colors.orange,
                            'CANCELLED': Colors.red,
                            'SEARCHING_PARTNER': Colors.purple,
                          };
                          final color = colorMap[status] ?? Colors.grey;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, color: Colors.green.shade600, size: 8),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(pickup, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, color: Colors.red.shade600, size: 8),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(drop, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹$amount',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.05, end: 0);
                        },
                      ),
      ),
    );
  }
}
