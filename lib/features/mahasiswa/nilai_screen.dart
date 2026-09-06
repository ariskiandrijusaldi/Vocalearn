import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/providers/auth_provider.dart';
import 'quiz_history_screen.dart';

class NilaiScreen extends ConsumerStatefulWidget {
  const NilaiScreen({super.key});

  @override
  ConsumerState<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends ConsumerState<NilaiScreen> {
  List<dynamic> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final data = await ref.read(aiServiceProvider).getQuizResults(
            studentId: studentId,
          );
      if (!mounted) return;
      setState(() {
        _results = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadResults,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
            children: [
              const Text(
                'Nilai Kuis',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Riwayat nilai kuis yang sudah kamu kerjakan.',
                style: TextStyle(color: AppColors.body, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                const _EmptyCard(
                  icon: Icons.error_outline,
                  text: 'Gagal memuat nilai.\nTarik ke bawah untuk mencoba lagi.',
                )
              else if (_results.isEmpty)
                const _EmptyCard(
                  icon: Icons.quiz_outlined,
                  text:
                      'Belum ada nilai kuis.\nKerjakan kuis di salah satu modul untuk melihat nilaimu di sini.',
                )
              else
                ..._results.map(_buildResultCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(dynamic r) {
    final skor = (r['skor'] ?? 0) as int;
    final dikuasai = (r['dikuasai'] ?? false) as bool;
    final benar = (r['jawaban_benar'] ?? 0) as int;
    final total = (r['total_soal'] ?? 0) as int;
    final title = (r['material_title'] as String?) ?? 'Materi';
    final materialId = (r['material_id'] as num?)?.toInt() ?? 0;
    final createdAt = r['created_at'] as String?;
    final warna = dikuasai ? AppColors.green2 : AppColors.yellow;

    DateTime? tanggal;
    if (createdAt != null) {
      tanggal = DateTime.tryParse(createdAt);
    }
    final tanggalText = tanggal == null
        ? ''
        : '${tanggal.day}/${tanggal.month}/${tanggal.year} '
            '${tanggal.hour.toString().padLeft(2, '0')}:'
            '${tanggal.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizHistoryScreen(
                  materialId: materialId,
                  materialTitle: title,
                  skor: skor,
                  dikuasai: dikuasai,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: warna.withAlpha(38),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$skor',
                    style: TextStyle(
                      color: warna,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$benar dari $total soal benar'
                        '${tanggalText.isEmpty ? '' : ' \u2022 $tanggalText'}',
                        style: const TextStyle(
                            color: AppColors.body, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: warna,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    dikuasai ? 'DIKUASAI' : 'PERLU RANGKUMAN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.body, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
