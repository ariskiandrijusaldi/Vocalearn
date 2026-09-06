import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/providers/auth_provider.dart';

class QuizHistoryScreen extends ConsumerStatefulWidget {
  final int materialId;
  final String materialTitle;
  final int skor;
  final bool dikuasai;

  const QuizHistoryScreen({
    super.key,
    required this.materialId,
    required this.materialTitle,
    required this.skor,
    required this.dikuasai,
  });

  @override
  ConsumerState<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends ConsumerState<QuizHistoryScreen> {
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final data = await ref.read(aiServiceProvider).getQuizAttempts(
            studentId: studentId,
            materialId: widget.materialId,
          );
      if (!mounted) return;
      setState(() {
        _attempts = data;
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
    final warna = widget.dikuasai ? AppColors.green2 : AppColors.yellow;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.materialTitle,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header ringkasan
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(16),
            ),
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
                    '${widget.skor}',
                    style: TextStyle(
                      color: warna,
                      fontSize: 18,
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
                        widget.dikuasai ? 'Materi Dikuasai' : 'Perlu Rangkuman',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Riwayat jawaban per soal',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 40, color: AppColors.muted),
                            const SizedBox(height: 8),
                            const Text(
                              'Gagal memuat riwayat.',
                              style: TextStyle(
                                  color: AppColors.body, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadAttempts,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _attempts.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada riwayat jawaban.',
                              style:
                                  TextStyle(color: AppColors.body, fontSize: 13),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAttempts,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _attempts.length,
                              itemBuilder: (context, index) {
                                return _buildAttemptCard(
                                    _attempts[index], index);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(dynamic attempt, int index) {
    final isCorrect = (attempt['is_correct'] ?? false) as bool;
    final jawabanSiswa = (attempt['jawaban_siswa'] ?? '') as String;
    final jawabanBenar = (attempt['jawaban_benar'] ?? '') as String;
    final pertanyaan = (attempt['pertanyaan'] ?? '') as String;
    final options = {
      'A': attempt['opsi_a'] as String? ?? '',
      'B': attempt['opsi_b'] as String? ?? '',
      'C': attempt['opsi_c'] as String? ?? '',
      'D': attempt['opsi_d'] as String? ?? '',
    };
    final penjelasan = attempt['penjelasan'] as String?;
    final penjelasanAi = attempt['penjelasan_ai'] as String?;
    final tips = attempt['tips'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.green2.withAlpha(60)
              : AppColors.red.withAlpha(60),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header soal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.green2.withAlpha(20)
                  : AppColors.red.withAlpha(20),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: isCorrect ? AppColors.green2 : AppColors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Soal ${index + 1}',
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppColors.green2 : AppColors.red,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isCorrect ? 'BENAR' : 'SALAH',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pertanyaan
                Text(
                  pertanyaan,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Opsi jawaban
                for (final entry in options.entries) ...[
                  _buildOption(
                    label: entry.key,
                    text: entry.value,
                    isJawabanBenar: entry.key == jawabanBenar,
                    isJawabanSiswa: entry.key == jawabanSiswa,
                    isCorrect: isCorrect,
                  ),
                  const SizedBox(height: 6),
                ],

                // Jawaban siswa vs jawaban benar
                if (!isCorrect) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.body),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Jawabanmu: $jawabanSiswa  •  Jawaban benar: $jawabanBenar',
                            style: const TextStyle(
                              color: AppColors.body,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Penjelasan
                if (penjelasanAi != null && penjelasanAi.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildExplanation(
                    'Penjelasan AI',
                    penjelasanAi,
                    AppColors.dark,
                  ),
                ],
                if (penjelasan != null &&
                    penjelasan.isNotEmpty &&
                    (penjelasanAi == null || penjelasanAi.isEmpty)) ...[
                  const SizedBox(height: 10),
                  _buildExplanation(
                    'Penjelasan',
                    penjelasan,
                    AppColors.dark,
                  ),
                ],
                if (tips != null && tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildExplanation('Tips', tips, AppColors.green),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required String text,
    required bool isJawabanBenar,
    required bool isJawabanSiswa,
    required bool isCorrect,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isJawabanBenar) {
      bgColor = AppColors.green2.withAlpha(25);
      borderColor = AppColors.green2;
      textColor = AppColors.dark;
    } else if (isJawabanSiswa && !isCorrect) {
      bgColor = AppColors.red.withAlpha(20);
      borderColor = AppColors.red;
      textColor = AppColors.dark;
    } else {
      bgColor = Colors.transparent;
      borderColor = const Color(0xFFE0E0E0);
      textColor = AppColors.body;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isJawabanBenar
                  ? AppColors.green2
                  : isJawabanSiswa && !isCorrect
                      ? AppColors.red
                      : AppColors.cream,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isJawabanBenar || (isJawabanSiswa && !isCorrect)
                    ? Colors.white
                    : AppColors.body,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (isJawabanSiswa && !isJawabanBenar) ...[
            const SizedBox(width: 6),
            const Icon(Icons.close, size: 14, color: AppColors.red),
          ],
          if (isJawabanBenar) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check, size: 14, color: AppColors.green2),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanation(String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
