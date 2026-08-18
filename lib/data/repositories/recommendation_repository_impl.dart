import 'dart:math' as math;

import '../../domain/entities/enrollment.dart';
import '../../domain/entities/learning_record.dart';
import '../../domain/entities/practice_module.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/local/dummy_data.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  RecommendationRepositoryImpl({
    List<LearningRecord>? records,
    List<PracticeModule>? modules,
    List<Enrollment>? enrollments,
  })  : _records = records ?? List.of(DummyData.learningRecords),
        _modules = modules ?? List.of(DummyData.modules),
        _enrollments = enrollments ?? List.of(DummyData.enrollments);

  final List<LearningRecord> _records;
  final List<PracticeModule> _modules;
  final List<Enrollment> _enrollments;

  static const double _masteryThreshold = 0.8;
  static const double _highAvg = 55.0;
  static const double _mediumAvg = 70.0;
  static const int _minAttempts = 3;
  static const double _halfLifeHours = 48.0;

  @override
  Future<void> refresh() async {}

  @override
  Future<List<User>> getStudents() async => List.of(DummyData.students);

  @override
  Future<Recommendation> getRecommendation(int studentId) async {
    final history = _records.where((r) => r.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final risk = _assessRisk(history);

    final masteryMap = _computeMastery(history);
    final competencies = masteryMap.entries
        .map((e) {
          final module = _modules.firstWhere(
            (m) => m.id == e.key,
            orElse: () => PracticeModule(id: e.key, courseId: 0, title: 'Modul #${e.key}'),
          );
          return Competency(
            moduleId: e.key,
            moduleTitle: module.title,
            mastery: e.value['mastery'],
            attempts: e.value['attempts'],
          );
        })
        .toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));

    final (nextModule, reason) = _recommendNext(studentId, masteryMap);

    return Recommendation(
      studentId: studentId,
      riskLevel: risk['level'],
      averageScore: risk['averageScore'],
      attemptCount: history.length,
      reasons: List<String>.from(risk['reasons']),
      competencies: competencies,
      nextModule: nextModule,
      reason: reason,
      aiSuggestion: _mockAiSuggestion(
        riskLevel: risk['level'],
        nextModuleTitle: nextModule?.title,
      ),
    );
  }

  String _mockAiSuggestion({required String riskLevel, required String? nextModuleTitle}) {
    final target = nextModuleTitle ?? 'materi yang sedang kamu pelajari';
    return switch (riskLevel) {
      'high' =>
        'Kamu perlu menambah jam latihan harian. Mulailah dari "$target" dan '
            'ulangi tiap modul sampai nilaimu stabil di atas 70. Jangan menyerah!',
      'medium' =>
        'Belajarmu cukup baik, tapi masih bisa ditingkatkan. Fokus dulu ke '
            '"$target", lalu buat jadwal latihan rutin agar mastery kamu naik.',
      _ =>
        'Performa belajarmu sudah bagus! Pertahankan ritme belajar harianmu '
            'dan lanjutkan ke "$target" untuk menambah kompetensi baru.',
    };
  }

  Map<String, dynamic> _assessRisk(List<LearningRecord> history) {
    if (history.isEmpty) {
      return {
        'level': 'low',
        'averageScore': 0.0,
        'reasons': ['Belum ada aktivitas belajar — mulailah dengan modul pertama.'],
      };
    }

    final scores = history.map((r) => r.score).toList();
    final average = scores.reduce((a, b) => a + b) / scores.length;
    final reasons = <String>[];

    final recent = scores.take(3).toList();
    if (scores.length >= 2 && recent.first < recent.last) {
      reasons.add('Skor terakhir cenderung menurun.');
    }
    if (scores.length >= _minAttempts && average < _highAvg) {
      reasons.add(
        'Rata-rata nilai rendah (${average.toStringAsFixed(0)}/100) dari ${scores.length} latihan.',
      );
    }
    if (scores.length < _minAttempts) {
      reasons.add('Data latihan masih sedikit, pantau terus.');
    }

    final String level;
    if (scores.length >= _minAttempts && average < _highAvg) {
      level = 'high';
    } else if (average < _mediumAvg || scores.length < _minAttempts) {
      level = 'medium';
    } else {
      level = 'low';
    }

    if (level == 'low') {
      reasons.add('Performa stabil dan baik. Pertahankan ritme belajarmu!');
    }

    return {'level': level, 'averageScore': average, 'reasons': reasons};
  }

  Map<int, Map<String, dynamic>> _computeMastery(List<LearningRecord> history) {
    final byModule = <int, List<LearningRecord>>{};
    for (final record in history) {
      byModule.putIfAbsent(record.moduleId, () => []).add(record);
    }

    final now = DateTime.now();
    final result = <int, Map<String, dynamic>>{};
    byModule.forEach((moduleId, records) {
      var totalWeight = 0.0;
      var acc = 0.0;
      for (final record in records) {
        final ageHours = math.max(
          0.0,
          now.difference(record.createdAt).inMicroseconds /
              Duration.microsecondsPerHour,
        );
        final weight = math.pow(0.5, ageHours / _halfLifeHours).toDouble();
        totalWeight += weight;
        acc += weight * (record.score / 100.0);
      }
      result[moduleId] = {
        'mastery': totalWeight == 0 ? 0.0 : acc / totalWeight,
        'attempts': records.length,
      };
    });
    return result;
  }

  (PracticeModule?, String) _recommendNext(
    int studentId,
    Map<int, Map<String, dynamic>> masteryMap,
  ) {
    final courseIds = _enrollments
        .where((e) => e.studentId == studentId)
        .map((e) => e.courseId)
        .toSet();
    if (courseIds.isEmpty) {
      return (null, 'Siswa belum terdaftar di mata kuliah mana pun.');
    }

    final modules = _modules
        .where((m) =>
            courseIds.contains(m.courseId) &&
            m.status == ModuleStatus.published)
        .toList();
    if (modules.isEmpty) {
      return (null, 'Belum ada modul terbit (published) untuk mata kuliah Anda.');
    }

    final recentlyDone = _records
        .where((r) =>
            r.studentId == studentId &&
            DateTime.now().difference(r.createdAt).inHours < 6)
        .map((r) => r.moduleId)
        .toSet();

    final candidates = <({double mastery, PracticeModule module, String reason})>[];
    for (final module in modules) {
      final info = masteryMap[module.id];
      final mastery = info?['mastery'] as double? ?? 0.0;
      if (mastery >= _masteryThreshold) continue;
      final reason = info != null
          ? 'Nilai Anda masih perlu ditingkatkan (mastery ${(mastery * 100).round()}%).'
          : 'Modul ini belum pernah Anda kerjakan.';
      candidates.add((mastery: mastery, module: module, reason: reason));
    }

    if (candidates.isEmpty) {
      return (null, 'Semua modul Anda sudah dikuasai. Istirahat atau naik ke topik baru!');
    }

    candidates.sort((a, b) {
      final byMastery = a.mastery.compareTo(b.mastery);
      if (byMastery != 0) return byMastery;
      final byOrder = a.module.orderIndex.compareTo(b.module.orderIndex);
      if (byOrder != 0) return byOrder;
      return recentlyDone.contains(a.module.id)
          ? 1
          : (recentlyDone.contains(b.module.id) ? -1 : 0);
    });

    final best = candidates.first;
    return (best.module, best.reason);
  }
}
