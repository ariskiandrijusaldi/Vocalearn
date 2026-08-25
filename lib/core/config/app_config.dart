import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _androidBaseUrl = 'http://192.168.1.13:8000';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidBaseUrl;
    }
    return 'http://localhost:8000';
  }
  static const String loginEmail = 'admin@vocalearn.id';
  static const String loginPassword = 'admin123';
}
