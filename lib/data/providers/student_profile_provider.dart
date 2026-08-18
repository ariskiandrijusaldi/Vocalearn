import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State profil mahasiswa. Untuk hackathon, disimpan di memori (Riverpod)
/// dulu — belum ke backend. Nanti begitu Arrizki siapkan API/Firestore,
/// tinggal tambahkan pemanggilan API di dalam StudentProfileController.
class StudentProfile {
  final String? programStudi;
  final String? mataKuliah;
  final bool isComplete;

  const StudentProfile({
    this.programStudi,
    this.mataKuliah,
    this.isComplete = false,
  });

  StudentProfile copyWith({
    String? programStudi,
    String? mataKuliah,
    bool? isComplete,
  }) {
    return StudentProfile(
      programStudi: programStudi ?? this.programStudi,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class StudentProfileController extends StateNotifier<StudentProfile> {
  StudentProfileController() : super(const StudentProfile());

  void save({required String programStudi, required String mataKuliah}) {
    // TODO (Alya, setelah backend Arrizki siap): kirim juga ke API/Firestore
    // di sini, bukan cuma disimpan lokal.
    state = StudentProfile(
      programStudi: programStudi,
      mataKuliah: mataKuliah,
      isComplete: true,
    );
  }
}

final studentProfileProvider =
StateNotifierProvider<StudentProfileController, StudentProfile>(
      (ref) => StudentProfileController(),
);