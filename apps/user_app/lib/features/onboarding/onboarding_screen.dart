import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              _Feature(
                icon: Icons.local_shipping_rounded,
                title: 'Parcel Delivery',
                subtitle: 'Documents, packages, gifts — picked up and delivered in minutes.',
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 28),
              _Feature(
                icon: Icons.restaurant_rounded,
                title: 'Food & Grocery',
                subtitle: 'Order from your favourite stores with live tracking.',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 28),
              _Feature(
                icon: Icons.two_wheeler_rounded,
                title: 'Bike & Auto',
                subtitle: 'Quick rides across the city at transparent fares.',
                color: const Color(0xFFF59E0B),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go(RoutePaths.home),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _Feature({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
