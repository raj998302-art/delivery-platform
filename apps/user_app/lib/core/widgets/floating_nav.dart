import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Floating glassmorphism bottom navigation bar.
/// Sits above the content with a blur backdrop, rounded corners,
/// and smooth animation on tab switch.
class FloatingNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                children: List.generate(widget.items.length, (i) {
                  final item = widget.items[i];
                  final active = i == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await HapticFeedback.light();
                        widget.onTap(i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (active)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ).animate(target: active ? 1 : 0).scale(
                                        duration: 300.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                Icon(
                                  active ? item.activeIcon : item.icon,
                                  color: active ? Colors.white : const Color(0xFF64748B),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
