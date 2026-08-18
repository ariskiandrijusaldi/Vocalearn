enum ModuleStatus {
  draft,
  review,
  published;

  String get label => switch (this) {
        ModuleStatus.draft => 'Draft',
        ModuleStatus.review => 'Menunggu Review',
        ModuleStatus.published => 'Terbit',
      };

  static ModuleStatus fromApi(String value) => switch (value) {
        'draft' => ModuleStatus.draft,
        'review' => ModuleStatus.review,
        'published' => ModuleStatus.published,
        _ => ModuleStatus.draft,
      };
}

class PracticeModule {
  const PracticeModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.content,
    this.difficulty = 1,
    this.orderIndex = 0,
    this.status = ModuleStatus.draft,
    this.reviewNote,
  });

  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String? content;
  final int difficulty;
  final int orderIndex;
  final ModuleStatus status;
  final String? reviewNote;

  PracticeModule copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    String? content,
    int? difficulty,
    int? orderIndex,
    ModuleStatus? status,
    String? reviewNote,
  }) {
    return PracticeModule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      difficulty: difficulty ?? this.difficulty,
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
