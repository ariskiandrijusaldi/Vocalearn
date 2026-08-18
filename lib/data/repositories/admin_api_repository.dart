import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/learning_record.dart';
import '../../domain/entities/practice_module.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_repository_impl.dart';

class AdminApiRepository implements AdminRepository {
  AdminApiRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final AdminRepository _fallback = AdminRepositoryImpl();
  String? _token;

  Map<String, String> _jsonHeaders() => {'Content-Type': 'application/json'};

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<void> _ensureToken() async {
    if (_token != null) return;
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': AppConfig.loginEmail,
        'password': AppConfig.loginPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Login gagal (${response.statusCode}). Pastikan backend berjalan '
        'dan akun admin tersedia.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
  }

  Future<List<User>> _fetchUsers() async {
    await _ensureToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/admin/users'),
      headers: _authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data pengguna (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return [
      for (final item in data)
        _userFromJson(item as Map<String, dynamic>),
    ];
  }

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromApi(json['role'] as String),
      nim: json['nim'] as String?,
      nip: json['nip'] as String?,
      prodi: json['prodi'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> _userToJson(User user) {
    return {
      if (user.role == UserRole.student) 'nim': user.nim,
      if (user.role == UserRole.lecturer) 'nip': user.nip,
      'prodi': user.prodi,
    };
  }

  @override
  Future<List<User>> getStudents() async =>
      (await _fetchUsers())
          .where((u) => u.role == UserRole.student && u.isActive)
          .toList();

  @override
  Future<List<User>> getLecturers() async =>
      (await _fetchUsers())
          .where((u) => u.role == UserRole.lecturer && u.isActive)
          .toList();

  @override
  Future<User> createUser({
    required UserRole role,
    required String fullName,
    required String email,
    String? password,
    String? nim,
    String? nip,
    String? prodi,
  }) async {
    await _ensureToken();
    final response = await _client.post(
      Uri.parse('$_baseUrl/admin/users'),
      headers: _authHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password ?? AppConfig.loginPassword,
        'full_name': fullName,
        'role': role.apiValue,
        if (role == UserRole.student) 'nim': nim,
        if (role == UserRole.lecturer) 'nip': nip,
        'prodi': prodi,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan pengguna (${response.statusCode}): ${response.body}',
      );
    }
    return _userFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<User> updateUser(User user) async {
    await _ensureToken();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/admin/users/${user.id}'),
      headers: _authHeaders(),
      body: jsonEncode({
        'full_name': user.fullName,
        ..._userToJson(user),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memperbarui pengguna (${response.statusCode}): ${response.body}',
      );
    }
    return _userFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _ensureToken();
    final response = await _client.delete(
      Uri.parse('$_baseUrl/admin/users/$id'),
      headers: _authHeaders(),
    );
    if (response.statusCode != 204) {
      throw Exception(
        'Gagal menghapus pengguna (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<List<Course>> getCourses() => _fallback.getCourses();

  @override
  Future<List<PracticeModule>> getModules({ModuleStatus? status}) =>
      _fallback.getModules(status: status);

  @override
  Future<List<LearningRecord>> getLearningRecords() =>
      _fallback.getLearningRecords();

  @override
  Future<PracticeModule> approveModule(int moduleId, {String note = 'Disetujui'}) =>
      _fallback.approveModule(moduleId, note: note);

  @override
  Future<PracticeModule> rejectModule(
    int moduleId, {
    String note = 'Ditolak, mohon direvisi',
  }) =>
      _fallback.rejectModule(moduleId, note: note);
}
