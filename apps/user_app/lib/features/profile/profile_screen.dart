import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  child: const Icon(Icons.person, size: 44, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 12),
                const Text('Aarav Mehta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('+91 99000 00001', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Account',
            items: [
              _Item(icon: Icons.person_outline, label: 'Personal info', onTap: () {}),
              _Item(icon: Icons.location_on_outlined, label: 'Saved addresses', onTap: () {}),
              _Item(icon: Icons.account_balance_wallet_outlined, label: 'Wallet · ₹500', onTap: () {}),
              _Item(icon: Icons.discount_outlined, label: 'Coupons & offers', onTap: () {}),
            ],
          ),
          _Section(
            title: 'App',
            items: [
              _Item(icon: Icons.language, label: 'Language · English', onTap: () {}),
              _Item(icon: Icons.dark_mode_outlined, label: 'Theme · Light', onTap: () {}),
              _Item(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
            ],
          ),
          _Section(
            title: 'Support',
            items: [
              _Item(icon: Icons.help_outline, label: 'Help & support', onTap: () {}),
              _Item(icon: Icons.description_outlined, label: 'Terms & privacy', onTap: () {}),
              _Item(icon: Icons.logout, label: 'Logout', color: Colors.red, onTap: () {}),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('Delivery Platform v0.1.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1) const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade700, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }
}
