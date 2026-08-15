import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic>? _orders;
  int _total = 0;
  String? _error;
  bool _loading = true;
  String _stateFilter = 'ALL';

  final _states = [
    ('ALL', 'All'),
    ('SEARCHING_PARTNER', 'Searching'),
    ('PARTNER_ASSIGNED', 'Assigned'),
    ('PICKED_UP', 'Picked up'),
    ('IN_TRANSIT', 'In transit'),
    ('DELIVERED', 'Delivered'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

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
        _total = (res['total'] as num?)?.toInt() ?? 0;
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
    final filtered = _orders?.where((o) {
      if (_stateFilter == 'ALL') return true;
      return o['state'] == _stateFilter;
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // State filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _states.length,
              itemBuilder: (_, i) {
                final s = _states[i];
                final selected = _stateFilter == s.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => _stateFilter = s.$1),
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                                  Text('Login required', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text('You need to login to see your orders', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => context.go('/login'),
                                    child: const Text('Login'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : filtered.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 48),
                                      const SizedBox(height: 12),
                                      Text('No orders found', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text('Book your first delivery to get started', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final o = filtered[i];
                                final code = o['code'] as String? ?? '';
                                final status = o['state'] as String? ?? 'UNKNOWN';
                                final amount = (o['totalAmount'] as num?)?.toInt() ?? 0;
                                final pickup = o['pickupAddress'] as String? ?? '';
                                final drop = o['dropAddress'] as String? ?? '';
                                final partner = o['partner'] as Map<String, dynamic>?;
                                final service = o['service'] as Map<String, dynamic>?;

                                final colorMap = <String, Color>{
                                  'COMPLETED': Colors.green,
                                  'DELIVERED': Colors.green,
                                  'IN_TRANSIT': Colors.blue,
                                  'PICKED_UP': Colors.orange,
                                  'PARTNER_ASSIGNED': Colors.indigo,
                                  'SEARCHING_PARTNER': Colors.purple,
                                  'CONFIRMED': Colors.blue,
                                  'CANCELLED': Colors.red,
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
                                        const SizedBox(height: 8),
                                        if (service != null)
                                          Text(service['name'] as String? ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.circle, color: Colors.green.shade600, size: 8),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(pickup, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Container(width: 1.5, height: 12, color: Colors.grey.shade400),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.circle, color: Colors.red.shade600, size: 8),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(drop, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (partner != null)
                                              Row(
                                                children: [
                                                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${partner['firstName']} ${partner['lastName']}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                ],
                                              )
                                            else
                                              const SizedBox(),
                                            Text(
                                              '${AppConstants.currencySymbol}$amount',
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/booking'),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }
}
