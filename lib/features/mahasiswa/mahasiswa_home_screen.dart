import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/providers/competency_provider.dart';
import '../../data/providers/refresh_provider.dart';
import '../../data/repositories/dosen_service.dart';
import '../../data/models/competency.dart';
import 'module_detail_screen.dart';
import 'diagnostic_screen.dart';

class MahasiswaHomeScreen extends ConsumerStatefulWidget {
  const MahasiswaHomeScreen({super.key});

  @override
  ConsumerState<MahasiswaHomeScreen> createState() => _MahasiswaHomeScreenState();
}

class _MahasiswaHomeScreenState extends ConsumerState<MahasiswaHomeScreen> {
  Map<String, dynamic>? _recommendation;
  bool _loadingRec = true;
  Map<String, dynamic>? _diagnostic;
  List<Competency> _diagResults = [];
  bool _loadingDiag = true;
  List<dynamic> _leaderboard = [];
  bool _loadingLeaderboard = true;
  Timer? _timer;

  static const _competencyNames = {
    'c1': 'Logika Pemrograman',
    'c2': 'Manajemen Basis Data',
    'c3': 'Instalasi Jaringan LAN',
    'c4': 'Pengembangan Aplikasi Web',
    'c5': 'Administrasi Sistem & Keamanan',
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final data = await DosenService().getRecommendation(studentId);
      if (!mounted) return;
      setState(() {
        _recommendation = data;
      });
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadRecommendation(), _loadDiagnostic(), _loadLeaderboard()]);
  }

  Future<void> _loadLeaderboard() async {
    try {
      final data = await DosenService().getLeaderboard();
      if (!mounted) return;
      setState(() {
        _leaderboard = data;
        _loadingLeaderboard = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _loadRecommendation() async {
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final data = await DosenService().getRecommendation(studentId);
      setState(() {
        _recommendation = data;
        _loadingRec = false;
      });
    } catch (_) {
      setState(() => _loadingRec = false);
    }
  }

  /// Hasil diagnostik tersimpan (diagnostik hanya diisi sekali).
  Future<void> _loadDiagnostic() async {
    final studentId = ref.read(authProvider).user?.id ?? 0;
    if (studentId == 0) {
      setState(() => _loadingDiag = false);
      return;
    }
    try {
      final data = await ref.read(aiServiceProvider).getDiagnostic(studentId: studentId);
      if (!mounted) return;
      setState(() {
        _diagnostic = data;
        _diagResults =
            data != null ? _competenciesFromSkor(data['kompetensi_skor']) : [];
        _loadingDiag = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDiag = false);
    }
  }

  List<Competency> _competenciesFromSkor(dynamic raw) {
    final Map<String, dynamic> skor = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);
    return skor.entries.map((e) {
      final s = (e.value as num).toDouble();
      return Competency(
        id: e.key,
        name: _competencyNames[e.key] ?? 'Kompetensi',
        masteryScore: s,
        status: CompetencyController.statusFromScore(s),
      );
    }).toList();
  }

  String _diagMeta() {
    final parts = <String>[];
    final gaya = _diagnostic?['gaya_belajar'];
    final tgl = _diagnostic?['submitted_at'];
    if (gaya != null && gaya.toString().isNotEmpty) parts.add('gaya belajar $gaya');
    if (tgl != null) parts.add(tgl.toString().split('T').first);
    return parts.isEmpty ? '' : ' • ${parts.join(' • ')}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeRefreshProvider, (prev, next) {
      if (next > 0) _silentRefresh();
    });
    final user = ref.watch(authProvider).user;
    final competencies = ref.watch(competencyProvider);
    final initial = (user?.name ?? 'U')[0].toUpperCase();

    final competenciesData = _recommendation?['competencies'] as List<dynamic>? ?? [];
    final nextModule = _recommendation?['next_module'] as Map<String, dynamic>?;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HALO,',
                        style: TextStyle(
                          color: const Color(0xFF7A8A76),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user?.name ?? 'Mahasiswa'} 👋',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (user?.kelasName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Kelas ${user!.kelasName}',
                            style: const TextStyle(
                              color: AppColors.body,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.sage,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Peta kompetensi terkini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Berdasarkan hasil diagnostik & modul yang sudah kamu selesaikan.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(217),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Peta Kompetensi title
              const Text(
                'Peta Kompetensi',
                style: TextStyle(
                  color: Color(0xFF33472F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Skill cards from real data
              if (competenciesData.isNotEmpty)
                ...competenciesData.map((c) {
                  final mastery = ((c['mastery'] ?? 0.0) as num).toDouble();
                  final title = c['module_title'] ?? 'Kompetensi';
                  final (status, color) = _statusFromMastery(mastery);
                  return _SkillCard(title: title, status: status, value: mastery, color: color);
                })
              else if (_diagResults.isNotEmpty)
                ..._diagResults.map((c) {
                  final (status, color) = _statusFromCompetency(c.status);
                  return _SkillCard(title: c.name, status: status, value: c.masteryScore, color: color);
                })
              else if (competencies.isNotEmpty)
                ...competencies.map((c) {
                  final (status, color) = _statusFromCompetency(c.status);
                  return _SkillCard(title: c.name, status: status, value: c.masteryScore, color: color);
                })
              else
                const _SkillCard(title: 'Belum ada data kompetensi', status: 'BELUM MULAI', value: 0, color: AppColors.muted),

              const SizedBox(height: 14),

              // Recommendation card
              if (nextModule != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIREKOMENDASIKAN UNTUKMU',
                        style: TextStyle(
                          color: const Color(0xFFBEB069),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nextModule['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextModule['description'] ?? 'Mulai modul ini untuk meningkatkan kompetensimu.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ModuleDetailScreen(moduleId: nextModule['id'].toString()),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.greenDark,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Mulai Modul →', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
              else if (!_loadingRec && _diagResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HASIL DIAGNOSTIKMU',
                        style: const TextStyle(
                          color: Color(0xFFBEB069),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Diagnostik sudah kamu isi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lihat ringkasan kompetensimu${_diagMeta()} beserta modul rekomendasi sesuai levelmu.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.greenDark,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Lihat Hasil Diagnostik →',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
              else if (!_loadingRec && !_loadingDiag)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIREKOMENDASIKAN UNTUKMU',
                        style: TextStyle(
                          color: const Color(0xFFBEB069),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Isi diagnostik terlebih dahulu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kerjakan diagnostik awal agar kami bisa merekomendasikan modul yang tepat untukmu.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.greenDark,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Mulai Diagnostik →', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // Papan Peringkat (sekelas)
              const Text(
                'Papan Peringkat',
                style: TextStyle(
                  color: Color(0xFF33472F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Peringkat kamu di kelas ${user?.kelasName ?? 'ini'}',
                style: const TextStyle(
                  color: AppColors.body,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              _LeaderboardCard(
                entries: _leaderboard,
                loading: _loadingLeaderboard,
                currentStudentId: user?.id ?? 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusFromMastery(double mastery) {
    if (mastery >= 0.7) return ('DIKUASAI', AppColors.green2);
    if (mastery >= 0.4) return ('PROSES', AppColors.yellow);
    return ('PERLU BANTUAN', AppColors.red);
  }

  (String, Color) _statusFromCompetency(CompetencyStatus status) {
    return switch (status) {
      CompetencyStatus.dikuasai => ('DIKUASAI', AppColors.green2),
      CompetencyStatus.dalamProses => ('PROSES', AppColors.yellow),
      CompetencyStatus.perluIntervensi => ('PERLU BANTUAN', AppColors.red),
      CompetencyStatus.belumMulai => ('BELUM MULAI', AppColors.muted),
    };
  }
}

class _SkillCard extends StatelessWidget {
  final String title, status;
  final double value;
  final Color color;
  const _SkillCard({required this.title, required this.status, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.cream,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final List<dynamic> entries;
  final bool loading;
  final int currentStudentId;
  const _LeaderboardCard({
    required this.entries,
    required this.loading,
    required this.currentStudentId,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _LeaderboardEmpty(message: 'Memuat papan peringkat…');
    }
    if (entries.isEmpty) {
      return const _LeaderboardEmpty(
        message: 'Belum ada peserta. Kerjakan modul untuk masuk peringkat.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: entries.map((e) {
          final rank = e['rank'] as int?;
          final isCurrent = e['student_id'] == currentStudentId;
          return _LeaderboardRow(entry: e, rank: rank, isCurrent: isCurrent);
        }).toList(),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final dynamic entry;
  final int? rank;
  final bool isCurrent;
  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.isCurrent,
  });

  String _medal(int? rank) {
    if (rank == null) return '-';
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
  }

  @override
  Widget build(BuildContext context) {
    final name = entry['full_name'] as String? ?? 'Mahasiswa';
    final aver = (entry['average_score'] as num?)?.toDouble() ?? 0.0;
    final attempts = entry['attempt_count'] as int? ?? 0;
    final kelasName = entry['kelas_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.green : AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              _medal(rank),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrent ? Colors.white : AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (kelasName != null && kelasName.isNotEmpty)
                  Text(
                    kelasName,
                    style: TextStyle(
                      color: isCurrent ? Colors.white.withAlpha(204) : AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                aver.toStringAsFixed(1),
                style: TextStyle(
                  color: isCurrent ? Colors.white : AppColors.greenDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$attempts latihan',
                style: TextStyle(
                  color: isCurrent ? Colors.white.withAlpha(204) : AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEmpty extends StatelessWidget {
  final String message;
  const _LeaderboardEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withAlpha(204),
          fontSize: 12,
        ),
      ),
    );
  }
}
