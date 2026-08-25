import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/ai_provider.dart';
import '../../data/providers/auth_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int materialId;
  final String materialTitle;

  const QuizScreen({
    super.key,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  Map<String, dynamic>? _explanation;
  bool _explanationLoading = false;
  int _correctCount = 0;
  bool _finished = false;
  Future<Map<String, dynamic>?>? _rangkumanFuture;

  static const _masteryThreshold = 70;

  int get _skor =>
      _questions.isEmpty ? 0 : (_correctCount / _questions.length * 100).round();

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(aiServiceProvider).generateQuiz(
            materialId: widget.materialId,
            jumlahSoal: 5,
            level: 'pemula',
          );
      if (!mounted) return;
      setState(() {
        _questions = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitAnswer(String answer) async {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });

    final question = _questions[_currentIndex];
    final isCorrect = answer == question['jawaban_benar'];
    if (isCorrect) _correctCount++;

    // Submit jawaban ke backend + minta analisis AI kalau salah
    if (!isCorrect) {
      setState(() => _explanationLoading = true);
      try {
        final auth = ref.read(authProvider);
        final studentId = auth.user?.id ?? 0;
        final submitResult = await ref.read(aiServiceProvider).quizSubmit(
              studentId: studentId,
              questionId: question['id'],
              jawabanSiswa: answer,
            );

        if (submitResult.containsKey('id')) {
          final expl = await ref.read(aiServiceProvider).explainWrongAnswer(
                quizAttemptId: submitResult['id'],
                studentId: studentId,
              );
          if (mounted) setState(() => _explanation = expl);
        }
      } catch (_) {
        // Best-effort — fallback ke penjelasan soal ditampilkan di UI.
      } finally {
        if (mounted) setState(() => _explanationLoading = false);
      }
    } else {
      try {
        final auth = ref.read(authProvider);
        final studentId = auth.user?.id ?? 0;
        await ref.read(aiServiceProvider).quizSubmit(
              studentId: studentId,
              questionId: question['id'],
              jawabanSiswa: answer,
            );
      } catch (_) {
        // Best-effort
      }
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _explanation = null;
        _explanationLoading = false;
      });
    } else {
      _finishQuiz();
    }
  }

  String get _penjelasanText {
    final ai = _explanation?['penjelasan_ai'] as String?;
    if (ai != null && ai.isNotEmpty) return ai;
    // Fallback: penjelasan bawaan soal (kenapa jawaban benar itu benar).
    final q = _questions[_currentIndex];
    final builtin = q['penjelasan'] as String?;
    if (builtin != null && builtin.isNotEmpty) {
      return 'Jawaban yang benar: ${q['jawaban_benar']}. $builtin';
    }
    return 'Analisis AI belum tersedia. Jawaban yang benar: '
        '${_questions[_currentIndex]['jawaban_benar']}.';
  }

  Future<Map<String, dynamic>?> _loadRangkuman() async {
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      return await ref.read(aiServiceProvider).simplifyMaterial(
            materialId: widget.materialId,
            studentId: studentId,
          );
    } catch (_) {
      return null;
    }
  }

  void _finishQuiz() {
    if (_skor < _masteryThreshold) {
      _rangkumanFuture = _loadRangkuman();
    }
    setState(() => _finished = true);
    // Simpan nilai akhir ke database (best-effort).
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      final auth = ref.read(authProvider);
      final studentId = auth.user?.id ?? 0;
      await ref.read(aiServiceProvider).saveQuizResult(
            studentId: studentId,
            materialId: widget.materialId,
            skor: _skor,
            totalSoal: _questions.length,
            jawabanBenar: _correctCount,
            dikuasai: _skor >= _masteryThreshold,
          );
    } catch (_) {
      // Best-effort — nilai tetap tampil di navbar bawah walau gagal simpan.
    }
  }

  Widget _buildResultBar() {
    final mastered = _skor >= _masteryThreshold;
    final warna = mastered ? Colors.green : Colors.orange;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 12,
            color: Color(0x1A000000),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nilai Kuis',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  '$_skor',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: warna,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        mastered ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: warna,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mastered ? 'Materi Dikuasai' : 'Perlu Rangkuman',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: warna,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$_correctCount dari ${_questions.length} soal benar',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: warna,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Kuis: ${widget.materialTitle}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Kuis: ${widget.materialTitle}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadQuiz, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Kuis: ${widget.materialTitle}')),
        body: const Center(child: Text('Belum ada soal tersedia.')),
      );
    }

    final question = _questions[_currentIndex];
    final options = {
      'A': question['opsi_a'],
      'B': question['opsi_b'],
      'C': question['opsi_c'],
      'D': question['opsi_d'],
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Soal ${_currentIndex + 1}/${_questions.length}'),
      ),
      bottomNavigationBar: _finished ? _buildResultBar() : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
          ),
          const SizedBox(height: 20),
          Text(
            question['pertanyaan'] ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _answered ? null : () => _submitAnswer(entry.key),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _answered
                      ? entry.key == question['jawaban_benar']
                          ? Colors.green.shade50
                          : entry.key == _selectedAnswer
                              ? Colors.red.shade50
                              : null
                      : null,
                  side: _answered
                      ? BorderSide(
                          color: entry.key == question['jawaban_benar']
                              ? Colors.green
                              : entry.key == _selectedAnswer
                                  ? Colors.red
                                  : Colors.grey.shade300,
                        )
                      : null,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${entry.key}. ${entry.value}'),
                ),
              ),
            ),
          if (_answered && _explanationLoading) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI sedang menganalisis kesalahan jawabanmu...',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_answered && !_explanationLoading) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Penjelasan Jawaban',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_penjelasanText),
                    if (_explanation?['tips'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tips: ${_explanation!['tips']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_answered) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex < _questions.length - 1 ? 'Soal Berikutnya' : 'Lihat Hasil',
              ),
            ),
          ],
          if (_finished && _skor < _masteryThreshold) ...[
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: _rangkumanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text('Menyiapkan rangkuman...')),
                      ],
                    ),
                  );
                }
                final konten = snapshot.data?['konten_sederhana'] as String?;
                if (konten == null || konten.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rangkuman Mudah Dipahami',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(konten),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
