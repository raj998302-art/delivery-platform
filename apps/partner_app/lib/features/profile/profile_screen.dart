import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Color(0xFF0F766E),
                  child: Icon(Icons.person, size: 44, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text('Ramesh Kumar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('+91 98000 00001', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('4.8 · 248 deliveries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Account', items: [
            _Item(icon: Icons.person_outline, label: 'Personal info', onTap: () {}),
            _Item(icon: Icons.badge_outlined, label: 'KYC & documents', onTap: () => context.go('/kyc')),
            _Item(icon: Icons.two_wheeler_outlined, label: 'Vehicle details', onTap: () {}),
            _Item(icon: Icons.account_balance_outlined, label: 'Bank account', onTap: () {}),
          ]),
          _Section(title: 'Support', items: [
            _Item(icon: Icons.help_outline, label: 'Help & support', onTap: () => context.go('/support')),
            _Item(icon: Icons.description_outlined, label: 'Terms & privacy', onTap: () {}),
            _Item(icon: Icons.logout, label: 'Logout', color: Colors.red, onTap: () {}),
          ]),
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
