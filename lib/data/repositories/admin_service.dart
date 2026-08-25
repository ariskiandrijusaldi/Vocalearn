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
  }) async {
    final resp = await _dio.post('/admin/users', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      if (nim != null) 'nim': nim,
      if (nip != null) 'nip': nip,
      if (prodi != null) 'prodi': prodi,
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
    int semester = 1,
    int credits = 3,
    String? description,
  }) async {
    final resp = await _dio.post('/courses', data: {
      'code': code,
      'name': name,
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
}
