import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/widgets/floating_nav.dart';
import '../../core/widgets/location_permission.dart';
import '../drawer/floating_drawer.dart';

final servicesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ApiService.instance.getServices();
});

final nearbyPartnersProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  // Salt Lake Sector V center — will be replaced with user's actual location
  return await ApiService.instance.getNearbyPartners(
    lat: 22.5803,
    lng: 88.4284,
    radiusKm: 5,
  );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  bool _drawerOpen = false;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoad();
  }

  Future<void> _checkLocationAndLoad() async {
    final pos = await LocationPermissionHelper.getCurrentLocation(context);
    if (pos != null && mounted) {
      setState(() => _userLocation = pos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);
    final partnersAsync = ref.watch(nearbyPartnersProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: () async {
                ref.refresh(servicesProvider);
                ref.refresh(nearbyPartnersProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar with menu + greeting + notifications
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _drawerOpen = true),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good evening 👋',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              const Text(
                                'Deliver anything',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                const Center(child: Icon(Icons.notifications_outlined, color: Color(0xFF1E293B))),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    // Hero booking card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PARCEL',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.local_shipping_rounded, color: Colors.white70, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Where do you want to send?',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20),
                          _LocationField(
                            label: 'Pickup location',
                            icon: Icons.radio_button_checked,
                            color: Colors.greenAccent,
                            onTap: () => context.go(RoutePaths.booking),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 11),
                            height: 24,
                            child: VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          _LocationField(
                            label: 'Drop location',
                            icon: Icons.location_on,
                            color: Colors.redAccent,
                            onTap: () => context.go(RoutePaths.booking),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go(RoutePaths.booking),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366F1),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Book Parcel'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.05, end: 0, duration: 500.ms)
                        .shimmer(delay: 600.ms, duration: 2000.ms, color: Colors.white12),

                    const SizedBox(height: 28),

                    // Services grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        servicesAsync.isLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                '${servicesAsync.value?['services']?.length ?? 0} available',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    servicesAsync.when(
                      loading: () => GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: List.generate(8, (_) => ShimmerContainer()),
                      ),
                      error: (err, _) => _ErrorCard(message: '$err'),
                      data: (data) {
                        final services = (data['services'] as List?) ?? [];
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

                    // Nearby partners info
                    partnersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (data) {
                        final count = (data['count'] as num?)?.toInt() ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF10B981)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count partners nearby',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    const Text(
                                      'Avg arrival: 2 min',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF10B981)),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0);
                      },
                    ),

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
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    _RecentOrdersSection(),
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
                  case 0: break; // already home
                  case 1: context.go(RoutePaths.orders); break;
                  case 2: context.go(RoutePaths.tracking); break;
                  case 3: context.go(RoutePaths.profile); break;
                }
              },
              items: const [
                FloatingNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
                FloatingNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
                FloatingNavItem(icon: Icons.navigation_outlined, activeIcon: Icons.navigation_rounded, label: 'Track'),
                FloatingNavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
              ],
            ),

            // Floating drawer
            if (_drawerOpen)
              FloatingDrawer(
                onClose: () => setState(() => _drawerOpen = false),
                userName: 'Welcome',
                userPhone: 'Guest mode',
              ),
          ],
        ),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
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
      'PARCEL': Color(0xFF6366F1),
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label.length > 10 ? '${label.substring(0, 9)}…' : label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .scale(duration: 300.ms, curve: Curves.easeOutBack);
  }
}

class ShimmerContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text('Cannot reach backend', style: TextStyle(fontWeight: FontWeight.w600)),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final res = await ApiService.instance.getMyOrders(page: 1, pageSize: 5);
      setState(() {
        _orders = res['orders'] as List?;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _orders = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_orders == null || _orders!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 12),
            const Text('No orders yet', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Book your first delivery to get started', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.05, end: 0);
    }
    return Column(
      children: _orders!.take(3).map<Widget>((o) {
        final code = o['code'] as String? ?? '';
        final status = o['state'] as String? ?? 'UNKNOWN';
        final amount = (o['totalAmount'] as num?)?.toInt() ?? 0;
        final colorMap = <String, Color>{
          'COMPLETED': const Color(0xFF10B981),
          'DELIVERED': const Color(0xFF10B981),
          'IN_TRANSIT': const Color(0xFF3B82F6),
          'CANCELLED': const Color(0xFFEF4444),
          'SEARCHING_PARTNER': const Color(0xFF8B5CF6),
        };
        final color = colorMap[status] ?? Colors.grey;
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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2, color: color, size: 20),
            ),
            title: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text(status.replaceAll('_', ' ').toLowerCase(), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            trailing: Text(
              '${AppConstants.currencySymbol}$amount',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ).animate().fadeIn().slideX(begin: 0.05, end: 0);
      }).toList(),
    );
  }
}
