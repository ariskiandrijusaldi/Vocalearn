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
  final int? jurusanId;
  final String? jurusanName;

  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.prodi,
    this.kelasId,
    this.kelasName,
    this.jurusanId,
    this.jurusanName,
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
      jurusanId: j['jurusan_id'] as int?,
      jurusanName: j['jurusan_name'] as String?,
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

  AuthState copyWith({
    ApiUser? user,
    String? token,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
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

  // ------------------------------------------------------------
  // LOGIN
  // Semua kemungkinan error — termasuk parsing response yang
  // format-nya tidak terduga — WAJIB ketangkep di sini, supaya
  // Future yang di-await di LoginScreen tidak pernah throw.
  // ------------------------------------------------------------
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
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e, fallback: 'Gagal login'));
    } catch (e) {
      // Menangkap SEMUA error lain (parsing, cast, null, dll)
      // supaya tidak pernah lolos ke pemanggil.
      state = state.copyWith(isLoading: false, error: 'Tidak dapat terhubung ke server');
    }
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------
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
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e, fallback: 'Gagal mendaftar'));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Tidak dapat terhubung ke server');
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final resp = await _api.dio.post(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      if (resp.statusCode != 200) {
        throw Exception(_extractErrorMessage(
          DioException(requestOptions: resp.requestOptions, response: resp),
          fallback: 'Gagal mengubah password',
        ));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Gagal mengubah password'));
    }
  }

  // ------------------------------------------------------------
  // Helper aman untuk ambil pesan error dari response backend.
  // Menangani semua bentuk response: Map dengan 'detail' String,
  // Map dengan 'detail' List (validation error FastAPI/Pydantic),
  // String polos, atau null/format tak terduga.
  // ------------------------------------------------------------
  String _extractErrorMessage(DioException e, {required String fallback}) {
    try {
      final data = e.response?.data;

      if (data == null) return fallback;

      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) {
          // Format validation error Pydantic: [{msg: ..., loc: [...]}]
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.first.toString();
        }
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }

      if (data is String && data.isNotEmpty) return data;

      // Fallback berdasarkan status code
      switch (e.response?.statusCode) {
        case 401:
          return 'Email atau password salah';
        case 404:
          return 'Akun tidak ditemukan';
        case 422:
          return 'Data yang dikirim tidak valid';
        case 500:
          return 'Server sedang bermasalah, coba lagi nanti';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Koneksi timeout, coba lagi';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak bisa terhubung ke server';
      }

      return fallback;
    } catch (_) {
      // Jaga-jaga kalau parsing error message-nya sendiri gagal.
      return fallback;
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);
