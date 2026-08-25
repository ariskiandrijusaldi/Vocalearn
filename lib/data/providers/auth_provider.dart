import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_client.dart';
import '../models/user_role.dart';

class ApiUser {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? nim;
  final String? prodi;
  final int? kelasId;
  final String? kelasName;

  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.prodi,
    this.kelasId,
    this.kelasName,
  });

  factory ApiUser.fromJson(Map<String, dynamic> j) {
    return ApiUser(
      id: j['id'] as int,
      name: (j['full_name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      role: parseUserRole(j['role'] as String? ?? 'mahasiswa'),
      nim: j['nim'] as String?,
      prodi: j['prodi'] as String?,
      kelasId: j['kelas_id'] as int?,
      kelasName: j['kelas_name'] as String?,
    );
  }
}

class AuthState {
  final ApiUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null && token != null;

  AuthState copyWith({ApiUser? user, String? token, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _restoreSession();
  }

  final _api = ApiClient.instance;

  Future<void> _restoreSession() async {
    final token = await _api.token;
    if (token == null || token.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final resp = await _api.dio.get('/auth/me');
      final user = ApiUser.fromJson(resp.data as Map<String, dynamic>);
      state = AuthState(user: user, token: token);
    } catch (_) {
      await _api.clearToken();
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final accessToken = (resp.data as Map<String, dynamic>)['access_token'] as String;
      await _api.saveToken(accessToken);

      final meResp = await _api.dio.get('/auth/me');
      final user = ApiUser.fromJson(meResp.data as Map<String, dynamic>);

      state = AuthState(user: user, token: accessToken);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ?? 'Gagal login';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Tidak dapat terhubung ke server');
    }
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String nim,
    required String prodi,
    required int kelasId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.dio.post('/auth/register', data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName,
        'role': 'mahasiswa',
        'nim': nim,
        'prodi': prodi,
        'kelas_id': kelasId,
      });

      // Auto-login setelah register berhasil
      final loginResp = await _api.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final accessToken =
          (loginResp.data as Map<String, dynamic>)['access_token'] as String;
      await _api.saveToken(accessToken);

      final meResp = await _api.dio.get('/auth/me');
      final user = ApiUser.fromJson(meResp.data as Map<String, dynamic>);

      state = AuthState(user: user, token: accessToken);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ?? 'Gagal mendaftar';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Tidak dapat terhubung ke server');
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final resp = await _api.dio.post(
      '/auth/change-password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.data?['detail'] ?? 'Gagal mengubah password');
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
