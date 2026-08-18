import '../entities/course.dart';
import '../entities/learning_record.dart';
import '../entities/practice_module.dart';
import '../entities/user.dart';

abstract class AdminRepository {
  Future<List<User>> getStudents();

  Future<List<User>> getLecturers();

  Future<List<Course>> getCourses();

  Future<List<PracticeModule>> getModules({ModuleStatus? status});

  Future<List<LearningRecord>> getLearningRecords();

  Future<User> createUser({
    required UserRole role,
    required String fullName,
    required String email,
    String? password,
    String? nim,
    String? nip,
    String? prodi,
  });

  Future<User> updateUser(User user);

  Future<void> deleteUser(int id);

  Future<PracticeModule> approveModule(int moduleId, {String note = 'Disetujui'});

  Future<PracticeModule> rejectModule(
    int moduleId, {
    String note = 'Ditolak, mohon direvisi',
  });
}
