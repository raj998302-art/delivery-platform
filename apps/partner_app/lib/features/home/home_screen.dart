import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../core/widgets/floating_nav.dart';
import '../../core/widgets/incoming_order_overlay.dart';
import '../../core/widgets/location_permission.dart';
import '../drawer/floating_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _online = false;
  int _navIndex = 0;
  bool _drawerOpen = false;
  bool _showOrderOverlay = false;
  Timer? _refreshTimer;
  int _onlinePartnersCount = 0;
  int _activeDeliveries = 0;
  bool _loadingStats = true;
  Position? _userLocation;

  // Demo order for the overlay
  final _demoOrder = {
    'pickup': 'DN-21, Salt Lake Sector V',
    'drop': 'Webel Crossing, Sector V',
    'distance': '0.8',
    'eta': '5',
    'package': 'Small',
    'earnings': '89',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkLocation();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    final pos = await LocationPermissionHelper.getCurrentLocation(context);
    if (pos != null && mounted) {
      setState(() => _userLocation = pos);
    }
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService.instance.getOnlinePartners();
      setState(() {
        _onlinePartnersCount = (res['onlinePartners'] as List?)?.length ?? 0;
        _activeDeliveries = (res['sessions'] as List?)?.length ?? 0;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  void _toggleOnline() {
    setState(() => _online = !_online);
    if (_online) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadStats());
      // Simulate incoming order after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted || !_online) return;
        setState(() => _showOrderOverlay = true);
      });
    } else {
      _refreshTimer?.cancel();
      setState(() => _showOrderOverlay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _drawerOpen = true),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]),
                            child: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              const Text('Let\'s deliver', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]),
                            child: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    // Online/offline status card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _online
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFF64748B), const Color(0xFF475569)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_online ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(_online ? Icons.bolt_rounded : Icons.nightlight_round, color: Colors.white, size: 40)
                              .animate(target: _online ? 1 : 0)
                              .shake(duration: 500.ms),
                          const SizedBox(height: 12),
                          Text(
                            _online ? 'You\'re Online' : 'You\'re Offline',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _online
                                ? '$_onlinePartnersCount partners online · $_activeDeliveries active'
                                : 'Go online to receive delivery requests',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _toggleOnline,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _online ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              ),
                              child: Text(_online ? 'Go Offline' : 'Go Online'),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Today', value: '₹1,250', icon: Icons.account_balance_wallet, color: const Color(0xFF10B981))),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Trips', value: '8', icon: Icons.inventory_2, color: const Color(0xFF0F766E))),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Online', value: _onlinePartnersCount.toString(), icon: Icons.people, color: const Color(0xFFF59E0B))),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // Recent trips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        TextButton(onPressed: () => context.go('/orders'), child: const Text('See all')),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    _TripItem(code: 'DP-DEMO001', from: 'DN-21', to: 'Webel Crossing', amount: 89),
                    _TripItem(code: 'DP-DEMO002', from: 'College More', to: 'Karunamoyee', amount: 147),
                    _TripItem(code: 'DP-DEMO003', from: 'Nayapatti', to: 'Chingrighata', amount: 89),
                  ],
                ),
              ),
            ),

            // Floating bottom nav
            FloatingNav(
              currentIndex: _navIndex,
              onTap: (i) {
                setState(() => _navIndex = i);
                switch (i) {
                  case 0: break;
                  case 1: context.go('/orders'); break;
                  case 2: context.go('/earnings'); break;
                  case 3: context.go('/profile'); break;
                }
              },
              items: const [
                FloatingNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
                FloatingNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
                FloatingNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Earnings'),
                FloatingNavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
              ],
            ),

            // Floating drawer
            if (_drawerOpen)
              FloatingDrawer(
                onClose: () => setState(() => _drawerOpen = false),
                partnerName: 'Delivery Partner',
                partnerPhone: 'Login to continue',
              ),

            // Full-screen incoming order overlay
            if (_showOrderOverlay)
              IncomingOrderOverlay(
                order: _demoOrder,
                onAccept: () {
                  setState(() => _showOrderOverlay = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order accepted! Navigate to pickup.'), backgroundColor: Color(0xFF10B981)),
                  );
                  context.go('/tracking');
                },
                onReject: () {
                  setState(() => _showOrderOverlay = false);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  final String code, from, to;
  final int amount;
  const _TripItem({required this.code, required this.from, required this.to, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
        ),
        title: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text('$from → $to', style: const TextStyle(fontSize: 12)),
        trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF10B981))),
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}
