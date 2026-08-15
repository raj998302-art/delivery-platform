import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';

/// Floating sidebar drawer for partner app.
class FloatingDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final String partnerName;
  final String partnerPhone;
  final double rating;
  final int totalDeliveries;

  const FloatingDrawer({
    super.key,
    required this.onClose,
    this.partnerName = 'Partner',
    this.partnerPhone = 'Login to continue',
    this.rating = 5.0,
    this.totalDeliveries = 0,
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
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
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
                              child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.partnerName,
                                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.partnerPhone,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatChip(icon: Icons.star, value: widget.rating.toStringAsFixed(1), label: 'Rating'),
                            const SizedBox(width: 12),
                            _StatChip(icon: Icons.inventory_2, value: '${widget.totalDeliveries}', label: 'Trips'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _DrawerItem(icon: Icons.home_rounded, label: 'Home', onTap: () { widget.onClose(); context.go('/home'); }),
                        _DrawerItem(icon: Icons.receipt_long_rounded, label: 'My Orders', onTap: () { widget.onClose(); context.go('/orders'); }),
                        _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: 'Earnings', onTap: () { widget.onClose(); context.go('/earnings'); }),
                        _DrawerItem(icon: Icons.navigation_rounded, label: 'Navigate', onTap: () { widget.onClose(); context.go('/tracking'); }),
                        const Divider(indent: 24, endIndent: 24),
                        _DrawerItem(icon: Icons.support_agent_rounded, label: 'Help & Support', onTap: () { widget.onClose(); }),
                        _DrawerItem(icon: Icons.settings_rounded, label: 'Settings', onTap: () { widget.onClose(); context.go('/profile'); }),
                      ],
                    ),
                  ),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Partner App v0.2.0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                ],
              ),
            ),
          ).animate().slideX(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

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
                child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
