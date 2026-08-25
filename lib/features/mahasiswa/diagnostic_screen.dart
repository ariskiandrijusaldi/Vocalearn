import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/competency.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/competency_provider.dart';
import '../../data/repositories/dosen_service.dart';
import 'module_detail_screen.dart';


// =========================
// Tema visual modern
// =========================
const _bgColor = Color(0xFFFFFDF5);
const _tealColor = Color(0xFF173F40);
const _surfaceColor = Color(0xFFFFFFFF);
const _softSurface = Color(0xFFF5F2E8);
const _borderColor = Color(0xFFE6E1D5);
const _greenColor = Color(0xFF6E9D64);
const _goldColor = Color(0xFFD8C68A);
const _redColor = Color(0xFFB85D4B);
const _textColor = Color(0xFF354142);
const _mutedColor = Color(0xFF667171);

class _ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  const _ModernCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = _surfaceColor,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A263B3B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ThemeProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ThemeProgressBar({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 7,
        child: LinearProgressIndicator(
          value: safeValue,
          backgroundColor: const Color(0xFFE9E6DC),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

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
  static const _questions = [
    // Pemrograman Dasar
    _DiagnosticQuestion(
      competencyId: 'c1',
      competencyName: 'Logika Pemrograman',
      question: 'Seberapa yakin kamu bisa membuat alur logika program (percabangan & perulangan)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c1',
      competencyName: 'Logika Pemrograman',
      question: 'Seberapa paham kamu dengan struktur data dasar (array, list)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c1',
      competencyName: 'Logika Pemrograman',
      question: 'Seberapa yakin kamu bisa membuat fungsi/method sendiri untuk menyelesaikan masalah?',
    ),

    // Basis Data
    _DiagnosticQuestion(
      competencyId: 'c2',
      competencyName: 'Manajemen Basis Data',
      question: 'Seberapa yakin kamu bisa menulis query SQL dasar (SELECT, JOIN)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c2',
      competencyName: 'Manajemen Basis Data',
      question: 'Seberapa paham kamu dengan konsep normalisasi database?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c2',
      competencyName: 'Manajemen Basis Data',
      question: 'Seberapa yakin kamu bisa merancang skema tabel (ERD) untuk sebuah sistem sederhana?',
    ),

    // Jaringan Komputer
    _DiagnosticQuestion(
      competencyId: 'c3',
      competencyName: 'Instalasi Jaringan LAN',
      question: 'Seberapa yakin kamu bisa memasang kabel & perangkat LAN sendiri?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c3',
      competencyName: 'Instalasi Jaringan LAN',
      question: 'Seberapa paham kamu dengan topologi jaringan dasar (star, bus, ring)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c3',
      competencyName: 'Instalasi Jaringan LAN',
      question: 'Seberapa yakin kamu bisa melakukan konfigurasi IP address & subnetting?',
    ),

    // Pengembangan Web/Aplikasi
    _DiagnosticQuestion(
      competencyId: 'c4',
      competencyName: 'Pengembangan Aplikasi Web',
      question: 'Seberapa yakin kamu bisa membuat halaman web dengan HTML/CSS?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c4',
      competencyName: 'Pengembangan Aplikasi Web',
      question: 'Seberapa paham kamu dengan konsep client-server pada aplikasi web?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c4',
      competencyName: 'Pengembangan Aplikasi Web',
      question: 'Seberapa yakin kamu bisa menghubungkan aplikasi web dengan API/backend?',
    ),

    // Administrasi Sistem & Keamanan
    _DiagnosticQuestion(
      competencyId: 'c5',
      competencyName: 'Administrasi Sistem & Keamanan',
      question: 'Seberapa yakin kamu bisa mengelola user & permission pada sistem operasi?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c5',
      competencyName: 'Administrasi Sistem & Keamanan',
      question: 'Seberapa paham kamu dengan konsep dasar keamanan siber (enkripsi, autentikasi)?',
    ),
    _DiagnosticQuestion(
      competencyId: 'c5',
      competencyName: 'Administrasi Sistem & Keamanan',
      question: 'Seberapa yakin kamu bisa mengidentifikasi potensi celah keamanan pada sistem sederhana?',
    ),
  ];

  static const _gayaBelajarOptions = [
    'Visual (lebih paham lewat gambar/diagram)',
    'Auditori (lebih paham lewat penjelasan lisan)',
    'Kinestetik (lebih paham lewat praktik langsung)',
  ];


  final Map<int, int> _answers = {
    for (var i = 0; i < _questions.length; i++) i: 3,
  };
  String? _gayaBelajar;
  List<Competency>? _results; // null = belum submit, sudah diisi = tampil ringkasan

  bool _submitting = false;
  bool _checkingExisting = true;
  bool _sudahDiisi = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Diagnostik hanya boleh diisi sekali — jika sudah ada hasil tersimpan,
  /// langsung tampilkan ringkasan tanpa form.
  Future<void> _loadExisting() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    try {
      final data = await ref
          .read(aiServiceProvider)
          .getDiagnostic(studentId: auth.user!.id);
      if (!mounted) return;
      setState(() {
        if (data != null) {
          _results = _resultsFromSkor(data['kompetensi_skor']);
          _sudahDiisi = true;
        }
        _checkingExisting = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  List<Competency> _resultsFromSkor(dynamic raw) {
    final Map<String, dynamic> skor = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);
    return skor.entries.map((e) {
      final q = _questions.firstWhere(
            (x) => x.competencyId == e.key,
        orElse: () => const _DiagnosticQuestion(
          competencyId: '',
          competencyName: 'Kompetensi',
          question: '',
        ),
      );
      final s = (e.value as num).toDouble();
      return Competency(
        id: e.key,
        name: q.competencyName,
        masteryScore: s,
        status: CompetencyController.statusFromScore(s),
      );
    }).toList();
  }

  Future<void> _submit() async {
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

    // Submit ke backend (best-effort)
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        final kompetensiSkor = <String, double>{};
        for (final c in results) {
          kompetensiSkor[c.id] = c.masteryScore;
        }
        final gaya = _gayaBelajar?.contains('Visual') == true
            ? 'visual'
            : _gayaBelajar?.contains('Auditori') == true
            ? 'auditori'
            : 'kinestetik';
        await ref.read(aiServiceProvider).submitDiagnostic(
          studentId: auth.user!.id,
          kompetensiSkor: kompetensiSkor,
          gayaBelajar: gaya,
        );
        if (mounted) setState(() => _sudahDiisi = true);
      }
    } on DioException catch (e) {
      // Pengisian kedua ditolak backend — hasil lokal tetap ditampilkan.
      if (e.response?.statusCode == 409 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostik hanya bisa diisi sekali.'),
          ),
        );
      }
    } catch (_) {
      // Best-effort: biarkan lokal tetap jalan
    }

    setState(() {
      _results = results;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingExisting) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: _tealColor),
        ),
      );
    }

    if (_results != null) {
      return _ResultSummary(
        results: _results!,
        sudahDiisiSebelumnya: _sudahDiisi,
      );
    }

    final isFormValid = _gayaBelajar != null;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Diagnostik Awal',
          style: TextStyle(
            color: _textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _tealColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostik Kompetensi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi sejujurnya untuk menentukan modul praktik awalmu.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.fromLTRB(2, 2, 2, 9),
            child: Text(
              'Kompetensi',
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: .1,
              ),
            ),
          ),

          for (var i = 0; i < _questions.length; i++) ...[
            _ModernCard(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${_questions[i].question}',
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _questions[i].competencyName,
                    style: const TextStyle(
                      color: _mutedColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _greenColor,
                      inactiveTrackColor: const Color(0xFFE9E6DC),
                      thumbColor: _greenColor,
                      overlayColor: _greenColor.withAlpha(20),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: _answers[i]!.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${_answers[i]}',
                      onChanged: (value) =>
                          setState(() => _answers[i] = value.round()),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Belum bisa',
                        style: TextStyle(fontSize: 10, color: _mutedColor),
                      ),
                      Text(
                        'Sangat yakin',
                        style: TextStyle(fontSize: 10, color: _mutedColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(2, 7, 2, 9),
            child: Text(
              'Gaya Belajar',
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: .1,
              ),
            ),
          ),
          _ModernCard(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._gayaBelajarOptions.map(
                      (option) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: _tealColor,
                    title: Text(
                      option,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 11,
                      ),
                    ),
                    value: option,
                    groupValue: _gayaBelajar,
                    onChanged: (value) =>
                        setState(() => _gayaBelajar = value),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _tealColor,
                disabledBackgroundColor: _tealColor.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (isFormValid && !_submitting) ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Lihat Hasil Diagnostik',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatefulWidget {
  final List<Competency> results;
  final bool sudahDiisiSebelumnya;
  const _ResultSummary({
    required this.results,
    this.sudahDiisiSebelumnya = false,
  });

  @override
  State<_ResultSummary> createState() => _ResultSummaryState();
}

class _ResultSummaryState extends State<_ResultSummary> {
  /// Level target 1-5 = skor rata-rata (0.0-1.0) x 5.
  late final int _targetLevel;
  List<dynamic>? _suggested;

  @override
  void initState() {
    super.initState();
    final avg = widget.results.map((c) => c.masteryScore).reduce((a, b) => a + b) /
        widget.results.length;
    _targetLevel = (avg * 5).round().clamp(1, 5);
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final mods = await DosenService().getModules(status: 'published');
      if (!mounted) return;
      int jarak(dynamic m) =>
          ((m['difficulty'] as int? ?? 1) - _targetLevel).abs();
      mods.sort((a, b) => jarak(a).compareTo(jarak(b)));
      // Utamakan modul dalam rentang +-1 level dari hasil diagnostik.
      final withinBand =
      mods.where((m) => jarak(m) <= 1).toList();
      setState(() {
        _suggested = (withinBand.isNotEmpty ? withinBand : mods.take(3))
            .take(6)
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _suggested = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textColor),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/mahasiswa');
            }
          },
        ),
        title: const Text(
          'Hasil Diagnostik',
          style: TextStyle(
            color: _textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        children: [
          if (widget.sudahDiisiSebelumnya) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _greenColor.withAlpha(80),
                ),
              ),
              child: const Text(
                'Diagnostik hanya bisa diisi sekali. Berikut hasil tersimpanmu.',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _tealColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Kompetensi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Titik awal kompetensimu dan rekomendasi modul praktik.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.fromLTRB(2, 2, 2, 9),
            child: Text(
              'Kompetensi',
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: .1,
              ),
            ),
          ),

          ...widget.results.map(
                (c) {
              final score = c.masteryScore.clamp(0.0, 1.0).toDouble();
              final percent = (score * 100).round();
              final progressColor = score >= .7
                  ? _greenColor
                  : score >= .4
                  ? _goldColor
                  : _redColor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _ModernCard(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                color: _textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: _textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      _ThemeProgressBar(
                        value: score,
                        color: progressColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 6),
          _ModernCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modul yang Disarankan',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sesuai tingkat kesulitan level $_targetLevel/5 dari hasil diagnostikmu.',
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 9),
                _buildSuggestions(context),
              ],
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _tealColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/mahasiswa');
                }
              },
              child: const Text(
                'Ke Beranda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    if (_suggested == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suggested!.isEmpty) {
      return const Text('Belum ada modul yang tersedia.');
    }
    return Column(
      children: _suggested!.map((m) {
        final difficulty = m['difficulty'] as int? ?? 1;
        final selisih = (difficulty - _targetLevel).abs();
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _ModernCard(
            padding: const EdgeInsets.fromLTRB(11, 10, 9, 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModuleDetailScreen(
                      moduleId: m['id'].toString(),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: selisih == 0
                        ? _greenColor.withAlpha(35)
                        : _goldColor.withAlpha(45),
                    child: Text(
                      '$difficulty',
                      style: TextStyle(
                        color: selisih == 0 ? _greenColor : _goldColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] ?? 'Modul',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _mutedColor,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _mutedColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
