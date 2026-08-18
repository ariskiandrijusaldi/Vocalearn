import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/entities/practice_module.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/recommendation_repository.dart';

class RecommendationApiRepository implements RecommendationRepository {
  RecommendationApiRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  String? _token;
  static const Duration _cacheTtl = Duration(minutes: 5);

  List<User>? _studentsCache;
  DateTime? _studentsCachedAt;
  final Map<int, Recommendation> _recommendationCache = {};
  final Map<int, DateTime> _recommendationCachedAt = {};

  bool _isFresh(DateTime cachedAt) =>
      DateTime.now().difference(cachedAt) < _cacheTtl;

  Map<String, String> _jsonHeaders() => {'Content-Type': 'application/json'};

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<String> _ensureToken() async {
    if (_token != null) return _token!;
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
    return _token!;
  }

  @override
  Future<void> refresh() async {
    _studentsCache = null;
    _studentsCachedAt = null;
    _recommendationCache.clear();
    _recommendationCachedAt.clear();
  }

  @override
  Future<List<User>> getStudents() async {
    final cached = _studentsCache;
    final cachedAt = _studentsCachedAt;
    if (cached != null && cachedAt != null && _isFresh(cachedAt)) {
      return cached;
    }
    final students = await _fetchStudents();
    _studentsCache = students;
    _studentsCachedAt = DateTime.now();
    return students;
  }

  Future<List<User>> _fetchStudents() async {
    await _ensureToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/admin/users'),
      headers: _authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data mahasiswa (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final students = <User>[];
    for (final item in data) {
      final json = item as Map<String, dynamic>;
      if (json['role'] != 'mahasiswa' || json['is_active'] != true) continue;
      students.add(_userFromJson(json));
    }
    return students;
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

  @override
  Future<Recommendation> getRecommendation(int studentId) async {
    final cached = _recommendationCache[studentId];
    final cachedAt = _recommendationCachedAt[studentId];
    if (cached != null && cachedAt != null && _isFresh(cachedAt)) {
      return cached;
    }
    final recommendation = await _fetchRecommendation(studentId);
    _recommendationCache[studentId] = recommendation;
    _recommendationCachedAt[studentId] = DateTime.now();
    return recommendation;
  }

  Future<Recommendation> _fetchRecommendation(int studentId) async {
    await _ensureToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/recommendation/$studentId'),
      headers: _authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat rekomendasi (${response.statusCode})');
    }
    return _recommendationFromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Recommendation _recommendationFromJson(Map<String, dynamic> json) {
    final risk = json['risk'] as Map<String, dynamic>;
    final nextModuleJson = json['next_module'] as Map<String, dynamic>?;
    final competenciesJson = (json['competencies'] as List<dynamic>?) ?? [];
    return Recommendation(
      studentId: json['student_id'] as int,
      riskLevel: risk['level'] as String,
      averageScore: (risk['average_score'] as num).toDouble(),
      attemptCount: risk['attempt_count'] as int,
      reasons: (risk['reasons'] as List<dynamic>).cast<String>(),
      competencies: [
        for (final item in competenciesJson)
          _competencyFromJson(item as Map<String, dynamic>),
      ],
      nextModule: nextModuleJson == null
          ? null
          : _moduleFromJson(nextModuleJson),
      reason: json['reason'] as String,
      aiSuggestion: json['ai_suggestion'] as String?,
    );
  }

  Competency _competencyFromJson(Map<String, dynamic> json) {
    return Competency(
      moduleId: json['module_id'] as int,
      moduleTitle: json['module_title'] as String,
      mastery: (json['mastery'] as num).toDouble(),
      attempts: json['attempts'] as int,
    );
  }

  PracticeModule _moduleFromJson(Map<String, dynamic> json) {
    return PracticeModule(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String,
      difficulty: json['difficulty'] as int,
      orderIndex: json['order_index'] as int,
      status: ModuleStatus.fromApi(json['status'] as String),
    );
  }
}
