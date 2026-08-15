import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';

/// Floating sidebar drawer — slides over the content (not pushing it).
/// Uses glassmorphism + blur backdrop.
class FloatingDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final String userName;
  final String userPhone;

  const FloatingDrawer({
    super.key,
    required this.onClose,
    this.userName = 'Guest User',
    this.userPhone = 'Login to continue',
  });

  @override
  State<FloatingDrawer> createState() => _FloatingDrawerState();
}

class _FloatingDrawerState extends State<FloatingDrawer> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await ApiService.instance.logout();
    if (!mounted) return;
    widget.onClose();
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop with blur
        GestureDetector(
          onTap: widget.onClose,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Drawer panel
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.userPhone,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _DrawerItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          onTap: () { widget.onClose(); context.go(RoutePaths.home); },
                        ),
                        _DrawerItem(
                          icon: Icons.receipt_long_rounded,
                          label: 'My Orders',
                          onTap: () { widget.onClose(); context.go(RoutePaths.orders); },
                        ),
                        _DrawerItem(
                          icon: Icons.book_online_rounded,
                          label: 'Book Parcel',
                          onTap: () { widget.onClose(); context.go(RoutePaths.booking); },
                        ),
                        _DrawerItem(
                          icon: Icons.local_shipping_rounded,
                          label: 'Track Order',
                          onTap: () { widget.onClose(); context.go(RoutePaths.tracking); },
                        ),
                        _DrawerItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Wallet',
                          badge: '₹500',
                          onTap: () { widget.onClose(); context.go(RoutePaths.profile); },
                        ),
                        _DrawerItem(
                          icon: Icons.discount_rounded,
                          label: 'Offers & Coupons',
                          onTap: () { widget.onClose(); },
                        ),
                        const Divider(indent: 24, endIndent: 24),
                        _DrawerItem(
                          icon: Icons.support_agent_rounded,
                          label: 'Help & Support',
                          onTap: () { widget.onClose(); context.go(RoutePaths.profile); },
                        ),
                        _DrawerItem(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () { widget.onClose(); context.go(RoutePaths.profile); },
                        ),
                        _DrawerItem(
                          icon: Icons.description_outlined,
                          label: 'Terms & Privacy',
                          onTap: () { widget.onClose(); },
                        ),
                      ],
                    ),
                  ),
                  // Logout
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: _loggingOut
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                            : const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                        title: Text(
                          _loggingOut ? 'Logging out...' : 'Logout',
                          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                        ),
                        onTap: _loggingOut ? null : _logout,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${AppConstants.appNameFull} v0.2.0',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideX(
                begin: -1,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),
                ),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
