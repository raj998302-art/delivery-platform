/// API service for the user app.
/// All endpoints are documented in apps/admin_panel/README.md.
///
/// Usage:
///   final api = ApiService.instance;
///   await api.sendOtp('+919900000001');
///   final verify = await api.verifyOtp('+919900000001', '123456');
///   await api.saveTokens(verify.tokens.access, verify.tokens.refresh);
///   final orders = await api.getMyOrders();

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';

class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  String? _accessToken;

  String? get accessToken => _accessToken;
  Dio get dio => _dio;

  void init({String? baseUrl, String? apiKey}) async {
    final base = baseUrl ?? ApiConstants.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: ApiConstants.requestTimeout,
        receiveTimeout: ApiConstants.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (apiKey != null && apiKey.isNotEmpty) 'X-API-Key': apiKey,
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }

    // Load stored access token on init
    _accessToken = await _storage.read(key: 'access_token');
    if (_accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  // ---- Auth ----

  Future<Map<String, dynamic>> sendOtp(String phone, {String channel = 'sms'}) async {
    final res = await _dio.post('/api/auth/otp/send', data: {
      'phone': phone,
      'channel': channel,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await _dio.post('/api/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
    });
    final data = res.data as Map<String, dynamic>;
    if (data['ok'] == true) {
      final tokens = data['tokens'] as Map<String, dynamic>;
      await saveTokens(tokens['access'] as String, tokens['refresh'] as String);
    }
    return data;
  }

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _dio.options.headers['Authorization'] = 'Bearer $access';
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> logout() async {
    _accessToken = null;
    _dio.options.headers.remove('Authorization');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> get isLoggedIn async => (await _storage.read(key: 'access_token')) != null;

  // ---- Public catalog ----

  Future<Map<String, dynamic>> getServices() async {
    final res = await _dio.get('/api/public/services');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNearbyPartners({
    required double lat,
    required double lng,
    String? vehicleType,
    double radiusKm = 5,
  }) async {
    final res = await _dio.get('/api/partners/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      if (vehicleType != null) 'vehicleType': vehicleType,
      'radiusKm': radiusKm,
    });
    return res.data as Map<String, dynamic>;
  }

  // ---- Pricing ----

  Future<Map<String, dynamic>> getFareQuote({
    required String serviceType,
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String? couponCode,
  }) async {
    final res = await _dio.post('/api/pricing/quote', data: {
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      if (couponCode != null) 'couponCode': couponCode,
    });
    return res.data as Map<String, dynamic>;
  }

  // ---- Orders ----

  Future<Map<String, dynamic>> createOrder({
    required String quoteId,
    required String serviceType,
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String packageType = 'SMALL_PARCEL',
    double packageWeightKg = 0,
    bool fragile = false,
    String? packageDescription,
    String? pickupInstructions,
    String? dropInstructions,
    String paymentMethod = 'UPI',
    bool isInstant = true,
  }) async {
    final res = await _dio.post('/api/orders/create', data: {
      'quoteId': quoteId,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupAddress': pickupAddress,
      'pickupInstructions': pickupInstructions,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'dropAddress': dropAddress,
      'dropInstructions': dropInstructions,
      'packageType': packageType,
      'packageWeightKg': packageWeightKg,
      'fragile': fragile,
      'packageDescription': packageDescription,
      'paymentMethod': paymentMethod,
      'isInstant': isInstant,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyOrders({int page = 1, int pageSize = 20}) async {
    final res = await _dio.get('/api/orders/me', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return res.data as Map<String, dynamic>;
  }
}
