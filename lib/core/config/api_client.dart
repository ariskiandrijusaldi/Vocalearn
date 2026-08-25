import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_config.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const _tokenKey = 'jwt_token';

  final _storage = const FlutterSecureStorage();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(_AuthInterceptor(this));

  Future<String?> get token async => _storage.read(key: _tokenKey);
  Future<void> saveToken(String t) => _storage.write(key: _tokenKey, value: t);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._api);
  final ApiClient _api;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _api.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _api.clearToken();
    }
    handler.next(err);
  }
}
