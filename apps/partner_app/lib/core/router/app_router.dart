import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/earnings/earnings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: RoutePaths.orders, builder: (_, __) => const OrdersScreen()),
      GoRoute(path: RoutePaths.tracking, builder: (_, __) => const TrackingScreen()),
      GoRoute(path: RoutePaths.earnings, builder: (_, __) => const EarningsScreen()),
      GoRoute(path: RoutePaths.profile, builder: (_, __) => const ProfileScreen()),
    ],
  );
});
