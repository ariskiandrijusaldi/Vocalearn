import 'package:flutter/material.dart';

import '../../data/repositories/ai_service.dart';
import '../../data/repositories/dosen_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  static const cream = Color(0xFFEFE8DF);
  static const navy = Color(0xFF0F414A);
  static const blue = Color(0xFF96C0CE);

  Map<String, dynamic>? _data;
  List<dynamic> _quizResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await DosenService().getStudentDetail(widget.studentId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    // Riwayat nilai kuis (best-effort, terpisah agar detail tetap tampil).
    try {
      final results =
          await AiService().getQuizResults(studentId: widget.studentId);
      if (mounted) setState(() => _quizResults = results);
    } catch (_) {
      // Biarkan kosong.
    }
  }

  Color _scoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double score) {
    if (score >= 70) return 'Dikuasai';
    if (score >= 40) return 'Berjalan';
    return 'Perlu Latihan';
  }

  Widget _buildQuizResultCard(dynamic r) {
    final skor = (r['skor'] ?? 0) as int;
    final dikuasai = (r['dikuasai'] ?? false) as bool;
    final benar = (r['jawaban_benar'] ?? 0) as int;
    final total = (r['total_soal'] ?? 0) as int;
    final title = (r['material_title'] as String?) ?? 'Materi';
    final createdAt = r['created_at'] as String?;
    DateTime? tanggal;
    if (createdAt != null) tanggal = DateTime.tryParse(createdAt);
    final tanggalText = tanggal == null
        ? ''
        : '${tanggal.day}/${tanggal.month}/${tanggal.year} '
            '${tanggal.hour.toString().padLeft(2, '0')}:'
            '${tanggal.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _scoreColor(skor.toDouble()).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$skor',
              style: TextStyle(
                color: _scoreColor(skor.toDouble()),
                fontSize: 15,
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
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$benar dari $total soal benar'
                  '${tanggalText.isEmpty ? '' : ' • $tanggalText'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _scoreColor(skor.toDouble()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dikuasai ? 'DIKUASAI' : 'PERLU RANGKUMAN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Gagal memuat data'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final student = _data!['student'] as Map<String, dynamic>;
    final stats = _data!['stats'] as Map<String, dynamic>;
    final interactions = _data!['interactions'] as List<dynamic>;

    final avgScore = (stats['avg_score'] ?? 0.0) as num;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'Detail Mahasiswa',
                style: TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: blue,
                  child: Icon(Icons.person, size: 45, color: navy),
                ),
                const SizedBox(height: 15),
                Text(
                  student['full_name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  student['nim'] ?? student['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                if (student['prodi'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    student['prodi'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Score card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kompetensi Saat Ini',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    '${avgScore.toInt()}%',
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: avgScore.toDouble() / 100,
                    backgroundColor: Colors.black12,
                    color: _scoreColor(avgScore.toDouble()),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _scoreColor(avgScore.toDouble()),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _scoreLabel(avgScore.toDouble()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '${stats['total_interactions'] ?? 0} aktivitas latihan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Riwayat Nilai Kuis
          const Text(
            'Riwayat Nilai Kuis',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_quizResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'Belum ada nilai kuis.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),

          ..._quizResults.map(_buildQuizResultCard),

        ],
      ),
    );
  }
}
