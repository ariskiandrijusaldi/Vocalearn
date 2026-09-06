import 'package:dio/dio.dart';

import '../../core/config/api_client.dart';

class AdminService {
  final Dio _dio;

  AdminService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  Future<List<dynamic>> getUsers() async {
    final resp = await _dio.get('/admin/users');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? nim,
    String? nip,
    String? prodi,
    int? kelasId,
    int? jurusanId,
  }) async {
    final resp = await _dio.post('/admin/users', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      if (nim != null) 'nim': nim,
      if (nip != null) 'nip': nip,
      if (prodi != null) 'prodi': prodi,
      if (kelasId != null) 'kelas_id': kelasId,
      if (jurusanId != null) 'jurusan_id': jurusanId,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/admin/users/$userId', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete('/admin/users/$userId');
  }

  Future<Map<String, dynamic>> getStats() async {
    final resp = await _dio.get('/admin/stats');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getModules({String? status}) async {
    final resp = await _dio.get('/modules', queryParameters: {if (status != null) 'status': status});
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> approveModule(int moduleId) async {
    final resp = await _dio.post('/modules/$moduleId/approve');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectModule(int moduleId) async {
    final resp = await _dio.post('/modules/$moduleId/reject');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> publishModule(int moduleId) async {
    final resp = await _dio.post('/modules/$moduleId/approve');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCourses() async {
    final resp = await _dio.get('/courses');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCourse({
    required String code,
    required String name,
    String? prodi,
    int semester = 1,
    int credits = 3,
    String? description,
  }) async {
    final resp = await _dio.post('/courses', data: {
      'code': code,
      'name': name,
      if (prodi != null && prodi.isNotEmpty) 'prodi': prodi,
      'semester': semester,
      'credits': credits,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteCourse(int courseId) async {
    await _dio.delete('/courses/$courseId');
  }

  Future<Map<String, dynamic>> updateCourse(
    int courseId, {
    required String code,
    required String name,
    String? prodi,
    int semester = 1,
    int credits = 3,
    String? description,
  }) async {
    final resp = await _dio.patch('/courses/$courseId', data: {
      'code': code,
      'name': name,
      'prodi': prodi,
      'semester': semester,
      'credits': credits,
      'description': description,
    });
    return resp.data as Map<String, dynamic>;
  }

  // ==================== KELAS ====================

  Future<List<dynamic>> getKelas() async {
    final resp = await _dio.get('/kelas');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createKelas({
    required String name,
    int? dosenId,
    String? description,
  }) async {
    final resp = await _dio.post('/kelas', data: {
      'name': name,
      if (dosenId != null) 'dosen_id': dosenId,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKelas(int kelasId, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/kelas/$kelasId', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteKelas(int kelasId) async {
    await _dio.delete('/kelas/$kelasId');
  }

  // ==================== JURUSAN & PRODI ====================

  Future<List<dynamic>> getJurusan() async {
    final resp = await _dio.get('/jurusan');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createJurusan(String name) async {
    final resp = await _dio.post('/jurusan', data: {'name': name});
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateJurusan(int id, String name) async {
    final resp = await _dio.patch('/jurusan/$id', data: {'name': name});
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteJurusan(int id) async {
    await _dio.delete('/jurusan/$id');
  }

  Future<Map<String, dynamic>> createProdi(int jurusanId, String name) async {
    final resp =
        await _dio.post('/jurusan/$jurusanId/prodi', data: {'name': name});
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProdi(int prodiId, String name) async {
    final resp = await _dio.patch('/jurusan/prodi/$prodiId', data: {'name': name});
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteProdi(int prodiId) async {
    await _dio.delete('/jurusan/prodi/$prodiId');
  }
}
