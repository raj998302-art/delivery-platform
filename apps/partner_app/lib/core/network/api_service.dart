/// API service for the partner app.
/// Mirrors the user_app ApiService but uses partner-scoped endpoints.

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
  String? get partnerId => _partnerId;
  String? _partnerId;
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

    _accessToken = await _storage.read(key: 'access_token');
    _partnerId = await _storage.read(key: 'partner_id');
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
      // The user id from JWT is the partner's user id; in production we'd
      // fetch the partner profile separately. For MVP, we store the user id.
      final user = data['user'] as Map<String, dynamic>;
      _partnerId = user['id'];
      await _storage.write(key: 'partner_id', value: _partnerId);
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
    _partnerId = null;
    _dio.options.headers.remove('Authorization');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'partner_id');
  }

  Future<bool> get isLoggedIn async => (await _storage.read(key: 'access_token')) != null;

  // ---- Public ----

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

  // ---- Partner-specific ----
  // For MVP, partner dashboard shows aggregate stats from public/tracking endpoint.

  Future<Map<String, dynamic>> getOnlinePartners() async {
    final res = await _dio.get('/api/tracking');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyOrders({int page = 1, int pageSize = 20}) async {
    final res = await _dio.get('/api/orders/me', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return res.data as Map<String, dynamic>;
  }

  // Push location update (called every 5s while on delivery)
  Future<void> pushLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? orderId,
  }) async {
    await _dio.post('/api/tracking', data: {
      'partnerId': _partnerId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      if (orderId != null) 'orderId': orderId,
    });
  }
}
