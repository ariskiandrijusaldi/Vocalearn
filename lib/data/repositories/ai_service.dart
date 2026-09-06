import 'package:dio/dio.dart';

import '../../core/config/api_client.dart';

class AiService {
  final Dio _dio;

  AiService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  Future<Map<String, dynamic>> simplifyMaterial({
    required int materialId,
    required int studentId,
  }) async {
    final resp = await _dio.post(
      '/ai/simplify-material',
      data: {'material_id': materialId, 'student_id': studentId},
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Mengambil rangkuman materi milik user yang sedang login.
  /// Null jika belum pernah dibuat (nilai kuis masih di atas ambang).
  Future<Map<String, dynamic>?> getSimplifiedMaterial({
    required int materialId,
  }) async {
    final resp = await _dio.get('/ai/simplified-material/$materialId');
    final data = resp.data;
    if (data == null) return null;
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> generateQuiz({
    required int materialId,
    int jumlahSoal = 5,
    String level = 'pemula',
  }) async {
    final resp = await _dio.post(
      '/ai/generate-quiz',
      data: {
        'material_id': materialId,
        'jumlah_soal': jumlahSoal,
        'level': level,
      },
    );
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> quizSubmit({
    required int studentId,
    required int questionId,
    required String jawabanSiswa,
  }) async {
    final resp = await _dio.post(
      '/ai/quiz-submit',
      data: {
        'student_id': studentId,
        'question_id': questionId,
        'jawaban_siswa': jawabanSiswa,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> explainWrongAnswer({
    required int quizAttemptId,
    required int studentId,
  }) async {
    final resp = await _dio.post(
      '/ai/explain-wrong-answer',
      data: {'quiz_attempt_id': quizAttemptId, 'student_id': studentId},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveQuizResult({
    required int studentId,
    required int materialId,
    required int skor,
    required int totalSoal,
    required int jawabanBenar,
    required bool dikuasai,
  }) async {
    final resp = await _dio.post(
      '/ai/quiz-result',
      data: {
        'student_id': studentId,
        'material_id': materialId,
        'skor': skor,
        'total_soal': totalSoal,
        'jawaban_benar': jawabanBenar,
        'dikuasai': dikuasai,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getQuizResults({required int studentId}) async {
    final resp = await _dio.get('/ai/quiz-results/$studentId');
    return resp.data as List<dynamic>;
  }

  /// Riwayat jawaban per soal untuk satu materi kuis.
  Future<List<dynamic>> getQuizAttempts({
    required int studentId,
    required int materialId,
  }) async {
    final resp = await _dio.get('/ai/quiz-attempts/$studentId/$materialId');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> chatTutor({
    required int studentId,
    required String pesan,
    int? materialId,
  }) async {
    final resp = await _dio.post(
      '/ai/chat-tutor',
      data: {
        'student_id': studentId,
        'pesan': pesan,
        if (materialId != null) 'material_id': materialId,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> chatHistory({
    required int studentId,
  }) async {
    final resp = await _dio.get('/ai/chat-history/$studentId');
    final data = resp.data as Map<String, dynamic>;
    return data['messages'] as List<dynamic>;
  }

  /// Mengambil hasil diagnostik mahasiswa. Null jika belum pernah mengisi.
  Future<Map<String, dynamic>?> getDiagnostic({required int studentId}) async {
    final resp = await _dio.get('/ai/diagnostic/$studentId');
    final data = resp.data;
    if (data == null) return null;
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitDiagnostic({
    required int studentId,
    required Map<String, double> kompetensiSkor,
    required String gayaBelajar,
  }) async {
    final resp = await _dio.post(
      '/ai/diagnostic',
      data: {
        'student_id': studentId,
        'kompetensi_skor': kompetensiSkor,
        'gaya_belajar': gayaBelajar,
      },
    );
    return resp.data as Map<String, dynamic>;
  }
}
