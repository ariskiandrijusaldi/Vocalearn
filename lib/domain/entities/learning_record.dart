class LearningRecord {
  const LearningRecord({
    required this.id,
    required this.studentId,
    required this.moduleId,
    required this.score,
    this.correctCount = 0,
    this.totalQuestions = 0,
    this.durationSeconds = 0,
    required this.createdAt,
  });

  final int id;
  final int studentId;
  final int moduleId;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int durationSeconds;
  final DateTime createdAt;
}
