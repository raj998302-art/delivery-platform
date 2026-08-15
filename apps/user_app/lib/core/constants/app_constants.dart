class AppConstants {
  AppConstants._();
  static const appName = 'Delivery';
  static const appNameFull = 'Delivery Platform';
  static const currency = 'INR';
  static const currencySymbol = '₹';
  static const defaultCountry = 'India';
  static const defaultLanguage = 'en';
}

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
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const orders = '/orders';
  static const activity = '/activity';
  static const profile = '/profile';
  static const booking = '/booking';
  static const tracking = '/tracking';
  static const wallet = '/wallet';
  static const support = '/support';
  static const rating = '/rating';
}
