import 'practice_module.dart';

class Competency {
  const Competency({
    required this.moduleId,
    required this.moduleTitle,
    required this.mastery,
    required this.attempts,
  });

  final int moduleId;
  final String moduleTitle;
  final double mastery;
  final int attempts;
}

class Recommendation {
  const Recommendation({
    required this.studentId,
    required this.riskLevel,
    required this.averageScore,
    required this.attemptCount,
    required this.reasons,
    required this.competencies,
    this.nextModule,
    required this.reason,
    this.aiSuggestion,
  });

  final int studentId;
  final String riskLevel;
  final double averageScore;
  final int attemptCount;
  final List<String> reasons;
  final List<Competency> competencies;
  final PracticeModule? nextModule;
  final String reason;
  final String? aiSuggestion;
}
