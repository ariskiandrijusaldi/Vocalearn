import 'package:dio/dio.dart';

import '../../core/config/api_client.dart';

class DosenService {
  final Dio _dio;

  DosenService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  Future<List<dynamic>> getMyModules() async {
    final resp = await _dio.get('/dosen/my-modules');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getStudents() async {
    final resp = await _dio.get('/dosen/students');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getStudentDetail(int studentId) async {
    final resp = await _dio.get('/dosen/students/$studentId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createModule({
    required int courseId,
    required String title,
    String? description,
    String? content,
    int difficulty = 1,
    int orderIndex = 0,
    String? youtubeUrl,
    int? kelasId,
  }) async {
    final resp = await _dio.post('/modules', data: {
      'course_id': courseId,
      'title': title,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      'difficulty': difficulty,
      'order_index': orderIndex,
      if (youtubeUrl != null && youtubeUrl.isNotEmpty) 'youtube_url': youtubeUrl,
      if (kelasId != null) 'kelas_id': kelasId,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitModule(int moduleId) async {
    final resp = await _dio.post('/modules/$moduleId/submit');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadModulePdf(int moduleId, String filePath) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post('/modules/$moduleId/upload-pdf', data: formData);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCourses() async {
    final resp = await _dio.get('/courses');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getModules({String? status}) async {
    final resp = await _dio.get(
      '/modules',
      queryParameters: {if (status != null) 'status': status},
    );
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getRecommendation(int studentId) async {
    final resp = await _dio.get('/recommendation/$studentId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getInteractions() async {
    final resp = await _dio.get('/interactions/me');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getKelasList() async {
    final resp = await _dio.get('/kelas');
    return resp.data as List<dynamic>;
  }
}
