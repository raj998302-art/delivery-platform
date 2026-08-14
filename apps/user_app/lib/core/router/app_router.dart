import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/tracking/tracking_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RoutePaths.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: RoutePaths.booking, builder: (_, __) => const BookingScreen()),
      GoRoute(path: RoutePaths.tracking, builder: (_, __) => const TrackingScreen()),
      GoRoute(path: RoutePaths.orders, builder: (_, __) => const OrdersScreen()),
      GoRoute(path: RoutePaths.profile, builder: (_, __) => const ProfileScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
