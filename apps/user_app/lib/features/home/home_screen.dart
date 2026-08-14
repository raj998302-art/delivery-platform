import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    _LocationField(label: 'Pickup', icon: Icons.radio_button_checked, color: Colors.greenAccent),
                    const Divider(color: Colors.white24, height: 24),
                    _LocationField(label: 'Drop location', icon: Icons.location_on, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
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
              // Services grid
              const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: const [
                  _ServiceTile(icon: Icons.inventory_2_outlined, label: 'Parcel', color: Color(0xFF2563EB)),
                  _ServiceTile(icon: Icons.restaurant_outlined, label: 'Food', color: Color(0xFF10B981)),
                  _ServiceTile(icon: Icons.shopping_cart_outlined, label: 'Grocery', color: Color(0xFFF59E0B)),
                  _ServiceTile(icon: Icons.medical_services_outlined, label: 'Medicine', color: Color(0xFFEF4444)),
                  _ServiceTile(icon: Icons.two_wheeler_outlined, label: 'Bike', color: Color(0xFF8B5CF6)),
                  _ServiceTile(icon: Icons.directions_car_outlined, label: 'Auto', color: Color(0xFF06B6D4)),
                  _ServiceTile(icon: Icons.local_shipping_outlined, label: 'Mini Truck', color: Color(0xFFEC4899)),
                  _ServiceTile(icon: Icons.more_horiz, label: 'More', color: Color(0xFF64748B)),
                ],
              ),
              const SizedBox(height: 28),
              // Recent orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
              const SizedBox(height: 8),
              _RecentOrder(code: 'DP-DEMO001', status: 'Delivered', amount: 139),
              _RecentOrder(code: 'DP-DEMO002', status: 'In Transit', amount: 220),
              _RecentOrder(code: 'DP-DEMO003', status: 'Cancelled', amount: 0),
            ],
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
        onTap: (i) {},
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _LocationField({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RecentOrder extends StatelessWidget {
  final String code;
  final String status;
  final int amount;
  const _RecentOrder({required this.code, required this.status, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      'Delivered': Colors.green,
      'In Transit': Colors.blue,
      'Cancelled': Colors.red,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (colorMap[status] ?? Colors.grey).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2, color: colorMap[status] ?? Colors.grey, size: 20),
        ),
        title: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(status, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${AppConstants.currencySymbol}$amount',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}
