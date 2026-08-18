/// Model kompetensi (mengacu SKKNI/KKNI) dan modul praktik.
/// Dipakai lintas role:
/// - Mahasiswa: melihat skor & progres kompetensi sendiri
/// - Dosen: melihat agregat kompetensi kelas
/// - Admin: mengelola master data mata kuliah & sub-kompetensi (lihat features/admin)

enum CompetencyStatus { belumMulai, perluIntervensi, dalamProses, dikuasai }

class Competency {
  final String id;
  final String name; // nama sub-kompetensi, mis. "Instalasi Jaringan LAN"
  final double masteryScore; // 0.0 - 1.0, hasil AI Adaptive Engine
  final CompetencyStatus status;

  const Competency({
    required this.id,
    required this.name,
    required this.masteryScore,
    required this.status,
  });
}

class PracticeModule {
  final String id;
  final String title;
  final String competencyId;
  final String description;
  final bool isRecommended; // hasil rekomendasi AI Adaptive Engine
  final bool isCompleted;

  const PracticeModule({
    required this.id,
    required this.title,
    required this.competencyId,
    required this.description,
    this.isRecommended = false,
    this.isCompleted = false,
  });
}