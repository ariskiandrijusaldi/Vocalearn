class Course {
  const Course({
    required this.id,
    required this.code,
    required this.name,
    this.semester = 1,
    this.credits = 3,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final int semester;
  final int credits;
  final String? description;

  Course copyWith({
    int? id,
    String? code,
    String? name,
    int? semester,
    int? credits,
    String? description,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      semester: semester ?? this.semester,
      credits: credits ?? this.credits,
      description: description ?? this.description,
    );
  }
}
