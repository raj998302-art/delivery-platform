import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _online = false;
  int _secondsLeft = 15;
  Timer? _orderTimer;
  bool _showOrderRequest = false;

  // Live stats from backend
  int _onlinePartnersCount = 0;
  int _activeDeliveries = 0;
  bool _loadingStats = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Refresh stats every 15 seconds while online
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_online) _loadStats();
    });
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
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
      // Simulate an incoming order request after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_online) return;
        setState(() {
          _showOrderRequest = true;
          _secondsLeft = 15;
        });
        _orderTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _secondsLeft--);
          if (_secondsLeft <= 0) {
            t.cancel();
            setState(() => _showOrderRequest = false);
          }
        });
      });
    } else {
      _orderTimer?.cancel();
      setState(() => _showOrderRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _online
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF64748B), const Color(0xFF475569)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _online ? Icons.bolt : Icons.nightlight_round,
                        color: Colors.white,
                        size: 36,
                      ).animate(target: _online ? 1 : 0).shake(duration: 500.ms),
                      const SizedBox(height: 12),
                      Text(
                        _online ? 'You\'re online' : 'You\'re offline',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _online
                            ? '$_onlinePartnersCount partners online · $_activeDeliveries active deliveries'
                            : 'Go online to start receiving orders',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
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
                ),
                const SizedBox(height: 24),
                // Today stats (mock for now — backend doesn't expose per-partner stats yet)
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Earnings', value: '₹1,250', icon: Icons.account_balance_wallet, color: const Color(0xFF10B981))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Trips', value: '8', icon: Icons.inventory_2, color: const Color(0xFF0F766E))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Online', value: _onlinePartnersCount.toString(), icon: Icons.people, color: const Color(0xFFF59E0B))),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent trips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            _TripItem(code: 'DP-DEMO001', from: 'MG Road', to: 'Brigade Road', amount: 89),
                            _TripItem(code: 'DP-DEMO002', from: 'Indiranagar', to: 'Koramangala', amount: 220),
                            _TripItem(code: 'DP-DEMO003', from: 'HSR Layout', to: 'Bellandur', amount: 89),
                          ],
                        ),
                ),
              ],
            ),
          ),
          // Incoming order modal
          if (_showOrderRequest)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _IncomingOrderCard(
                secondsLeft: _secondsLeft,
                onAccept: () {
                  _orderTimer?.cancel();
                  setState(() => _showOrderRequest = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order accepted! Navigate to pickup.')),
                  );
                  context.go('/tracking');
                },
                onReject: () {
                  _orderTimer?.cancel();
                  setState(() => _showOrderRequest = false);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (i) {
          switch (i) {
            case 1: context.go('/orders'); break;
            case 2: context.go('/earnings'); break;
            case 3: context.go('/profile'); break;
          }
        },
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('$from → $to', style: const TextStyle(fontSize: 12)),
        trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF10B981))),
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onAccept, onReject;
  const _IncomingOrderCard({required this.secondsLeft, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Delivery Request', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: secondsLeft / 15,
                          color: secondsLeft <= 5 ? Colors.red : const Color(0xFF0F766E),
                          strokeWidth: 3,
                        ),
                      ),
                      Text('$secondsLeft', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _route('Pickup', 'MG Road, Bengaluru', Colors.green),
              const Padding(
                padding: EdgeInsets.only(left: 11),
                child: SizedBox(height: 24, child: VerticalDivider(color: Colors.grey)),
              ),
              _route('Drop', 'Brigade Road, Bengaluru', Colors.red),
              const SizedBox(height: 16),
              Row(
                children: [
                  _info('Distance', '8.4 km'),
                  const SizedBox(width: 24),
                  _info('Earnings', '₹89'),
                  const SizedBox(width: 24),
                  _info('Package', 'Small'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _route(String label, String address, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
