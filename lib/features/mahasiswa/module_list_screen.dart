import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/dosen_service.dart';
import 'module_detail_screen.dart';

class ModuleListScreen extends ConsumerStatefulWidget {
  const ModuleListScreen({super.key});

  @override
  ConsumerState<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends ConsumerState<ModuleListScreen> {
  List<dynamic> _modules = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;

  /// Mastery per modul (0..1) dari mesin rekomendasi; kosong jika gagal dimuat.
  Map<int, double> _masteryByModule = {};
  int? _recommendedModuleId;
  bool _recFailed = false;

  /// Selaras MASTERY_THRESHOLD di backend (app/ai/scheduler.py).
  static const double _kMasteryThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final modules = await DosenService().getModules(status: 'published');
      final courses = await DosenService().getCourses();

      final mastery = <int, double>{};
      int? recommendedId;
      var failed = false;
      try {
        final studentId = ref.read(authProvider).user?.id ?? 0;
        final rec = await DosenService().getRecommendation(studentId);
        for (final c in (rec['competencies'] as List<dynamic>? ?? [])) {
          final mid = c['module_id'];
          if (mid != null) {
            mastery[(mid as num).toInt()] =
                ((c['mastery'] ?? 0) as num).toDouble();
          }
        }
        final nm = rec['next_module'];
        if (nm is Map && nm['id'] != null) {
          recommendedId = (nm['id'] as num).toInt();
        }
      } catch (_) {
        failed = true;
      }

      if (!mounted) return;
      setState(() {
        _modules = modules;
        _courses = courses;
        _masteryByModule = mastery;
        _recommendedModuleId = recommendedId;
        _recFailed = failed;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _courseName(int courseId) {
    final match = _courses.firstWhere(
          (c) => c['id'] == courseId,
      orElse: () => null,
    );
    return match != null ? (match['name'] ?? 'Modul') : 'Modul';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Modul Praktik',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _modules.isEmpty
                  ? const Center(child: Text('Belum ada modul tersedia.'))
                  : RefreshIndicator(
                onRefresh: _load,
                child: _buildGroupedList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = <int, List<dynamic>>{};
    for (final m in _modules) {
      final cid = m['course_id'] as int? ?? 0;
      grouped.putIfAbsent(cid, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_recFailed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Progres belum termuat — semua modul sementara terbuka.',
              style: TextStyle(color: AppColors.body, fontSize: 12),
            ),
          ),
        for (final entry in grouped.entries) ...[
          Text(
            _courseName(entry.key).toUpperCase(),
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ..._cardsFor(entry.value),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  /// Kartu modul satu mata kuliah, terurut order_index. Modul pertama yang
  /// belum dikuasai adalah posisi belajar saat ini; sisanya terkunci.
  List<Widget> _cardsFor(List<dynamic> mods) {
    mods.sort((a, b) {
      final byOrder = (a['order_index'] as int? ?? 0)
          .compareTo(b['order_index'] as int? ?? 0);
      if (byOrder != 0) return byOrder;
      return (a['id'] as num).toInt().compareTo((b['id'] as num).toInt());
    });

    final activeIdx = mods
        .indexWhere((m) => (_masteryByModule[m['id']] ?? 0) < _kMasteryThreshold);

    _ModState stateOf(int i) {
      if (_recFailed) return _ModState.open;
      if (activeIdx == -1) return _ModState.mastered;
      if (i == activeIdx) return _ModState.active;
      return i < activeIdx ? _ModState.mastered : _ModState.locked;
    }

    return [
      for (var i = 0; i < mods.length; i++)
        _ModuleCard(
          module: mods[i],
          state: stateOf(i),
          mastery: _masteryByModule[mods[i]['id']],
          isEnginePick: _recommendedModuleId == mods[i]['id'],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ModuleDetailScreen(moduleId: mods[i]['id'].toString()),
              ),
            );
            // Muat ulang progres agar status kunci terbarui.
            _load();
          },
        ),
    ];
  }
}

enum _ModState { mastered, active, locked, open }

class _ModuleCard extends StatelessWidget {
  final dynamic module;
  final VoidCallback? onTap;
  final _ModState state;
  final double? mastery;
  final bool isEnginePick;

  const _ModuleCard({
    required this.module,
    required this.state,
    this.mastery,
    this.isEnginePick = false,
    this.onTap,
  });

  (String, Color) get _pill {
    switch (state) {
      case _ModState.mastered:
        return ('DIKUASAI', AppColors.green2);
      case _ModState.locked:
        return ('TERKUNCI', AppColors.muted);
      case _ModState.active:
        return isEnginePick ? ('REKOMENDASI', AppColors.gold) : ('MULAI', AppColors.green2);
      case _ModState.open:
        return ('MULAI', AppColors.green2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = module['title'] ?? '-';
    final description = module['description'] ?? 'Tanpa deskripsi';
    final hasPdf = module['pdf_path'] != null;
    final locked = state == _ModState.locked;
    final (pillText, pillColor) = _pill;

    return Opacity(
      opacity: locked ? 0.65 : 1,
      child: GestureDetector(
        onTap: locked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kuasai modul sebelumnya (nilai tinggi) untuk membuka modul ini.',
                    ),
                  ),
                );
              }
            : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isEnginePick && !locked
                ? Border.all(color: AppColors.gold, width: 1.5)
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: locked ? AppColors.cream : const Color(0xFF7DA67D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  locked
                      ? Icons.lock_outline
                      : hasPdf
                          ? Icons.picture_as_pdf
                          : Icons.article_outlined,
                  color: const Color(0xFF153B1C),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: locked
                                  ? AppColors.body
                                  : const Color(0xFF1B1C1C),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            mastery != null && state == _ModState.mastered
                                ? '$pillText ${(mastery! * 100).round()}%'
                                : pillText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locked
                          ? 'Selesaikan modul sebelumnya untuk membuka modul ini.'
                          : description,
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (module['kelas_name'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Kelas: ${module['kelas_name']}',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
