class ApiConstants {
  ApiConstants._();
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
  static const Duration requestTimeout = Duration(seconds: 30);
}

class RoutePaths {
  RoutePaths._();
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const orders = '/orders';
  static const tracking = '/tracking';
  static const earnings = '/earnings';
  static const profile = '/profile';
}
