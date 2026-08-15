import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';

// Provider for fetching services from backend
final servicesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ApiService.instance.getServices();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(servicesProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      child: const Icon(Icons.person, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good evening,', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Welcome 👋', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Booking card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where do you want to send?',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      _LocationField(
                        label: 'Pickup location',
                        icon: Icons.radio_button_checked,
                        color: Colors.greenAccent,
                        onTap: () => context.go(RoutePaths.booking),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      _LocationField(
                        label: 'Drop location',
                        icon: Icons.location_on,
                        color: Colors.redAccent,
                        onTap: () => context.go(RoutePaths.booking),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go(RoutePaths.booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                          ),
                          child: const Text('Book Parcel'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Services grid (live from backend)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    servicesAsync.isLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('${servicesAsync.value?['services']?.length ?? 0} available',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                servicesAsync.when(
                  loading: () => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: List.generate(8, (_) => Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                    )),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.red.shade700),
                        const SizedBox(height: 8),
                        Text('Cannot reach backend', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('$err', style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  data: (data) {
                    final services = (data['services'] as List?) ?? [];
                    if (services.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No services available')),
                      );
                    }
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: services.map<Widget>((s) {
                        return _ServiceTile.fromService(s, onTap: () => context.go(RoutePaths.booking));
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Recent orders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.orders),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Real orders fetched from /api/orders/me
                _RecentOrdersSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (i) {
          switch (i) {
            case 1: context.go(RoutePaths.orders); break;
            case 3: context.go(RoutePaths.profile); break;
          }
        },
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LocationField({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.label, required this.color, required this.onTap});

  factory _ServiceTile.fromService(Map<String, dynamic> service, {required VoidCallback onTap}) {
    final type = service['type'] as String? ?? 'OTHER';
    final name = service['name'] as String? ?? type;
    // Map service types to icons + colors
    const iconMap = <String, IconData>{
      'PARCEL': Icons.inventory_2_outlined,
      'FOOD': Icons.restaurant_outlined,
      'GROCERY': Icons.shopping_cart_outlined,
      'MEDICINE': Icons.medical_services_outlined,
      'BIKE': Icons.two_wheeler_outlined,
      'AUTO': Icons.directions_car_outlined,
      'MINI_TRUCK': Icons.local_shipping_outlined,
      'TRUCK': Icons.local_shipping_outlined,
    };
    const colorMap = <String, Color>{
      'PARCEL': Color(0xFF2563EB),
      'FOOD': Color(0xFF10B981),
      'GROCERY': Color(0xFFF59E0B),
      'MEDICINE': Color(0xFFEF4444),
      'BIKE': Color(0xFF8B5CF6),
      'AUTO': Color(0xFF06B6D4),
      'MINI_TRUCK': Color(0xFFEC4899),
      'TRUCK': Color(0xFFEC4899),
    };
    return _ServiceTile(
      icon: iconMap[type] ?? Icons.more_horiz,
      label: name,
      color: colorMap[type] ?? const Color(0xFF64748B),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label.length > 10 ? '${label.substring(0, 9)}…' : label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecentOrdersSection> createState() => _RecentOrdersSectionState();
}

class _RecentOrdersSectionState extends ConsumerState<_RecentOrdersSection> {
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
      final res = await ApiService.instance.getMyOrders(page: 1, pageSize: 5);
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
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.login, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text('Login to see your orders', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    if (_orders == null || _orders!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 8),
            Text('No orders yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Book your first delivery to get started', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      );
    }
    return Column(
      children: _orders!.take(5).map<Widget>((o) {
        final code = o['code'] as String? ?? '';
        final status = o['state'] as String? ?? 'UNKNOWN';
        final amount = o['totalAmount'] as num? ?? 0;
        final colorMap = <String, Color>{
          'COMPLETED': Colors.green,
          'DELIVERED': Colors.green,
          'IN_TRANSIT': Colors.blue,
          'CANCELLED': Colors.red,
          'SEARCHING_PARTNER': Colors.purple,
        };
        final color = colorMap[status] ?? Colors.grey;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory_2, color: color, size: 20),
            ),
            title: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)),
            trailing: Text(
              '${AppConstants.currencySymbol}${amount.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }
}
