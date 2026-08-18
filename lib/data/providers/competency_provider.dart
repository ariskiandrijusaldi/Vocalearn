import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/competency.dart';

/// Menyimpan daftar Competency hasil diagnostik mahasiswa.
/// Diisi oleh DiagnosticScreen, dibaca oleh MahasiswaHomeScreen &
/// (nanti) ProgressScreen — supaya keduanya selalu tampilkan data yang sama.
///
/// Kosong ([]) berarti mahasiswa belum mengisi diagnostik.
///
/// TODO (Alya, setelah endpoint Arrizki siap): begitu AI Adaptive Engine
/// jalan, competencies ini idealnya diambil dari
/// GET /recommendation/{student_id} (lihat kontrak data di Mini-PRD),
/// bukan cuma dihitung lokal dari diagnostik saja.
class CompetencyController extends StateNotifier<List<Competency>> {
  CompetencyController() : super([]);

  void setFromDiagnostic(List<Competency> results) {
    state = results;
  }

  /// Threshold status — SESUAI kontrak data di Mini-PRD.
  /// Kalau angka ini diubah, update juga tabel kontrak data di
  /// VocaLearn_Mini_PRD.md supaya track Dosen tetap konsisten.
  static CompetencyStatus statusFromScore(double score) {
    if (score < 0.4) return CompetencyStatus.perluIntervensi;
    if (score <= 0.7) return CompetencyStatus.dalamProses;
    return CompetencyStatus.dikuasai;
  }
}

final competencyProvider =
StateNotifierProvider<CompetencyController, List<Competency>>(
      (ref) => CompetencyController(),
);