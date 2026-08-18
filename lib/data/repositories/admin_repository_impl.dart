import '../../domain/entities/course.dart';
import '../../domain/entities/learning_record.dart';
import '../../domain/entities/practice_module.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/local/dummy_data.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl() {
    _students = List.of(DummyData.students);
    _lecturers = List.of(DummyData.lecturers);
    _courses = List.of(DummyData.courses);
    _modules = List.of(DummyData.modules);
    _records = List.of(DummyData.learningRecords);
  }

  late List<User> _students;
  late List<User> _lecturers;
  late List<Course> _courses;
  late List<PracticeModule> _modules;
  late List<LearningRecord> _records;

  int get _nextUserId {
    final ids = [..._students.map((u) => u.id), ..._lecturers.map((u) => u.id)];
    return ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Future<List<User>> getStudents() async => List.of(_students);

  @override
  Future<List<User>> getLecturers() async => List.of(_lecturers);

  @override
  Future<List<Course>> getCourses() async => List.of(_courses);

  @override
  Future<List<PracticeModule>> getModules({ModuleStatus? status}) async {
    if (status == null) return List.of(_modules);
    return _modules.where((m) => m.status == status).toList();
  }

  @override
  Future<List<LearningRecord>> getLearningRecords() async => List.of(_records);

  @override
  Future<User> createUser({
    required UserRole role,
    required String fullName,
    required String email,
    String? password,
    String? nim,
    String? nip,
    String? prodi,
  }) async {
    final user = User(
      id: _nextUserId,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      role: role,
      nim: role == UserRole.student ? nim?.trim() : null,
      nip: role == UserRole.lecturer ? nip?.trim() : null,
      prodi: prodi?.trim(),
      createdAt: DateTime.now(),
    );
    if (role == UserRole.student) {
      _students.add(user);
    } else {
      _lecturers.add(user);
    }
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    final target = user.role == UserRole.student ? _students : _lecturers;
    final index = target.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      throw StateError('User dengan id ${user.id} tidak ditemukan');
    }
    target[index] = user;
    return user;
  }

  @override
  Future<void> deleteUser(int id) async {
    _students.removeWhere((u) => u.id == id);
    _lecturers.removeWhere((u) => u.id == id);
  }

  @override
  Future<PracticeModule> approveModule(int moduleId, {String note = 'Disetujui'}) async {
    return _setModuleStatus(moduleId, ModuleStatus.published, note);
  }

  @override
  Future<PracticeModule> rejectModule(
    int moduleId, {
    String note = 'Ditolak, mohon direvisi',
  }) async {
    return _setModuleStatus(moduleId, ModuleStatus.draft, note);
  }

  PracticeModule _setModuleStatus(int moduleId, ModuleStatus status, String note) {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index == -1) {
      throw StateError('Modul dengan id $moduleId tidak ditemukan');
    }
    final updated = _modules[index].copyWith(status: status, reviewNote: note);
    _modules[index] = updated;
    return updated;
  }
}
