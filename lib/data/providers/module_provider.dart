import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/competency.dart';
import 'competency_provider.dart';
enum ModuleStatus { terkunci, direkomendasikan, selesai }

class PracticeModuleItem {
  final String id;
  final String competencyId;
  final String title;
  final String description;
  final List<String> checklistItems;
  final ModuleStatus status;

  const PracticeModuleItem({
    required this.id,
    required this.competencyId,
    required this.title,
    required this.description,
    required this.checklistItems,
    required this.status,
  });

  PracticeModuleItem copyWith({ModuleStatus? status}) {
    return PracticeModuleItem(
      id: id,
      competencyId: competencyId,
      title: title,
      description: description,
      checklistItems: checklistItems,
      status: status ?? this.status,
    );
  }
}
class ModuleController extends StateNotifier<List<PracticeModuleItem>> {
  ModuleController(this._ref) : super(_seedModules) {
    // Setiap kali hasil diagnostik berubah, hitung ulang rekomendasi.
    _ref.listen<List<Competency>>(competencyProvider, (_, competencies) {
      _recalculate(competencies);
    });
  }

  final Ref _ref;

  static const _seedModules = [
    PracticeModuleItem(
      id: 'm1',
      competencyId: 'c1',
      title: 'Dasar Pengkabelan LAN',
      description: 'Pelajari cara memasang & menguji kabel jaringan straight/cross.',
      checklistItems: [
        'Siapkan kabel UTP, connector RJ45, dan crimping tool',
        'Susun urutan kabel sesuai standar T568B',
        'Crimping & uji dengan LAN tester',
      ],
      status: ModuleStatus.terkunci,
    ),
    PracticeModuleItem(
      id: 'm2',
      competencyId: 'c1',
      title: 'Topologi Jaringan Lanjutan',
      description: 'Kenali kelebihan & kekurangan topologi star, bus, dan ring.',
      checklistItems: [
        'Gambarkan topologi star untuk 5 perangkat',
        'Identifikasi single point of failure pada tiap topologi',
      ],
      status: ModuleStatus.terkunci,
    ),
    PracticeModuleItem(
      id: 'm3',
      competencyId: 'c2',
      title: 'Konfigurasi Routing Statis',
      description: 'Latihan mengatur routing statis pada router sederhana.',
      checklistItems: [
        'Login ke konfigurasi router',
        'Tambahkan 1 entri routing statis',
        'Uji konektivitas antar jaringan',
      ],
      status: ModuleStatus.terkunci,
    ),
    PracticeModuleItem(
      id: 'm4',
      competencyId: 'c2',
      title: 'Subnetting Dasar',
      description: 'Latihan membagi 1 jaringan menjadi beberapa subnet.',
      checklistItems: [
        'Hitung subnet mask untuk kebutuhan 4 subnet',
        'Tentukan network ID & broadcast ID tiap subnet',
      ],
      status: ModuleStatus.terkunci,
    ),
    PracticeModuleItem(
      id: 'm5',
      competencyId: 'c3',
      title: 'Diagnosis Masalah Jaringan',
      description: 'Latihan menelusuri penyebab jaringan yang tidak terhubung.',
      checklistItems: [
        'Gunakan ping & traceroute untuk cek konektivitas',
        'Identifikasi 3 kemungkinan penyebab jaringan putus',
      ],
      status: ModuleStatus.terkunci,
    ),
  ];

  void _recalculate(List<Competency> competencies) {
    if (competencies.isEmpty) return;
    final sorted = [...competencies]
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));

    final updated = <PracticeModuleItem>[];
    for (final competency in sorted) {
      final modulesForCompetency =
      state.where((m) => m.competencyId == competency.id).toList();

      bool previousDone = true;
      for (final module in modulesForCompetency) {
        if (module.status == ModuleStatus.selesai) {
          updated.add(module);
          continue;
        }
        if (previousDone) {
          updated.add(module.copyWith(status: ModuleStatus.direkomendasikan));
          previousDone = false; // modul berikutnya di kompetensi ini terkunci
        } else {
          updated.add(module.copyWith(status: ModuleStatus.terkunci));
        }
      }
    }
    state = updated;
  }

  void completeModule(String moduleId) {
    state = state
        .map((m) => m.id == moduleId ? m.copyWith(status: ModuleStatus.selesai) : m)
        .toList();
    _recalculate(_ref.read(competencyProvider));
  }
}

final moduleProvider =
StateNotifierProvider<ModuleController, List<PracticeModuleItem>>(
      (ref) => ModuleController(ref),
);
