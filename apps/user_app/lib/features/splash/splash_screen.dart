import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),  // indigo-500
              Color(0xFF7C3AED),  // violet-600
              Color(0xFFA855F7),  // purple-500
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating orbs background
              Positioned(
                top: 80,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ).animate().fadeIn(duration: 800.ms).move(
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                  builder: (context, anim) {
                    return Offset(anim * 20, anim * 30);
                  },
                ),
              ),
              Positioned(
                bottom: 100,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with glassmorphism
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing ring
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ).animate(onPlay: (c) => c.repeat()).scale(
                            duration: 1500.ms,
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.4, 1.4),
                          ).then().fade(duration: 500.ms),
                          // Truck icon
                          const Icon(
                            Icons.local_shipping_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.easeOutBack)
                        .then()
                        .shimmer(duration: 1500.ms, color: Colors.white70),

                    const SizedBox(height: 32),

                    // App name
                    const Text(
                      'Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Deliver anything. Anywhere.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms),

                    const SizedBox(height: 60),

                    // Loading indicator
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.7)),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 400.ms),
                  ],
                ),
              ),

              // Version at bottom
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'v0.3.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1500.ms, duration: 500.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
