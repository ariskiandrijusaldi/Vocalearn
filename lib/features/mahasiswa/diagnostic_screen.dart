import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/competency.dart';
import '../../data/providers/competency_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 4: Diagnostik Awal
/// ==========================================================
/// Terhubung ke to-do list §4 & Mini-PRD Fitur 1.
/// Acceptance criteria:
///   - minimal 5 pertanyaan self-rating per sub-kompetensi
///   - 1 pertanyaan gaya belajar
///   - hasil disimpan sebagai List<Competency> (skor 0.0-1.0)
///   - ada layar ringkasan hasil sebelum lanjut
///
/// TODO selanjutnya (Alya):
///   [ ] Setelah selesai, tombol "Ke Beranda" -> nanti bisa diarahkan ke
///       ModuleListScreen (langkah 6) begitu itu dibuat.
class _DiagnosticQuestion {
  final String competencyId;
  final String competencyName;
  final String question;
  const _DiagnosticQuestion({
    required this.competencyId,
    required this.competencyName,
    required this.question,
  });
}

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  // 5 pertanyaan self-rating, dipetakan ke 3 sub-kompetensi dummy
  // (samakan dengan yang dipakai di mahasiswa_home_screen.dart lama
  // supaya konsisten setelah tersambung).
  static const _questions = [
    _DiagnosticQuestion(
      competencyId: 'c1',
      competencyName: 'Instalasi Jaringan LAN',
      question: 'Seberapa yakin kamu bisa memasang kabel & perangkat LAN sendiri?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c1',
      competencyName: 'Instalasi Jaringan LAN',
      question: 'Seberapa paham kamu dengan topologi jaringan dasar (star, bus, ring)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c2',
      competencyName: 'Konfigurasi Routing Dasar',
      question: 'Seberapa yakin kamu bisa mengatur routing statis pada router?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c2',
      competencyName: 'Konfigurasi Routing Dasar',
      question: 'Seberapa paham kamu dengan konsep subnetting?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c3',
      competencyName: 'Troubleshooting Jaringan',
      question: 'Seberapa yakin kamu bisa mendiagnosis jaringan yang bermasalah?',
    ),
  ];

  static const _gayaBelajarOptions = [
    'Visual (lebih paham lewat gambar/diagram)',
    'Auditori (lebih paham lewat penjelasan lisan)',
    'Kinestetik (lebih paham lewat praktik langsung)',
  ];

  // Skor 1-5 per pertanyaan, default di tengah (3).
  final Map<int, int> _answers = {
    for (var i = 0; i < _questions.length; i++) i: 3,
  };
  String? _gayaBelajar;
  List<Competency>? _results; // null = belum submit, sudah diisi = tampil ringkasan

  void _submit() {
    // Kelompokkan skor per competencyId, lalu rata-ratakan & normalisasi ke 0.0-1.0
    final Map<String, List<int>> grouped = {};
    for (var i = 0; i < _questions.length; i++) {
      grouped.putIfAbsent(_questions[i].competencyId, () => []);
      grouped[_questions[i].competencyId]!.add(_answers[i]!);
    }

    final results = grouped.entries.map((entry) {
      final competencyName =
          _questions.firstWhere((q) => q.competencyId == entry.key).competencyName;
      final avgScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final normalizedScore = avgScore / 5.0; // skala 1-5 -> 0.0-1.0
      return Competency(
        id: entry.key,
        name: competencyName,
        masteryScore: normalizedScore,
        status: CompetencyController.statusFromScore(normalizedScore),
      );
    }).toList();

    ref.read(competencyProvider.notifier).setFromDiagnostic(results);
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    if (_results != null) return _ResultSummary(results: _results!);

    final isFormValid = _gayaBelajar != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostik Awal')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Isi sejujurnya, hasil ini hanya untuk menentukan modul praktik awalmu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          for (var i = 0; i < _questions.length; i++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${_questions[i].question}',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(_questions[i].competencyName,
                        style: Theme.of(context).textTheme.bodySmall),
                    Slider(
                      value: _answers[i]!.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${_answers[i]}',
                      onChanged: (value) =>
                          setState(() => _answers[i] = value.round()),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Belum bisa', style: TextStyle(fontSize: 11)),
                        Text('Sangat yakin', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text('Gaya Belajar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._gayaBelajarOptions.map(
                (option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _gayaBelajar,
              onChanged: (value) => setState(() => _gayaBelajar = value),
            ),
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: isFormValid ? _submit : null,
            child: const Text('Lihat Hasil Diagnostik'),
          ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final List<Competency> results;
  const _ResultSummary({required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Diagnostik')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ini titik awal kompetensimu. VocaLearn akan merekomendasikan '
                'modul praktik berdasarkan hasil ini.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...results.map(
                (c) => Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: LinearProgressIndicator(value: c.masteryScore),
                trailing: Text('${(c.masteryScore * 100).round()}%'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            // Halaman home akan otomatis baca dari competencyProvider,
            // jadi tidak perlu passing data manual di sini.
            onPressed: () => context.go('/mahasiswa'),
            child: const Text('Ke Beranda'),
          ),
        ],
      ),
    );
  }
}