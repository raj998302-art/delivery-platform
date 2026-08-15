import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Env vars passed via --dart-define at build time, read via String.fromEnvironment.
  ApiService.instance.init();
  runApp(const ProviderScope(child: DeliveryApp()));
}

class DeliveryApp extends ConsumerWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Delivery Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
