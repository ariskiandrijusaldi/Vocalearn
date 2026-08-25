import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/dosen_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Map<String, dynamic>? _recommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() => _isLoading = true);
    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final data = await DosenService().getRecommendation(studentId);
      setState(() {
        _recommendation = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recommendation == null
                ? const Center(child: Text('Isi diagnostik awal dulu untuk melihat progres.'))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final competencies = _recommendation!['competencies'] as List<dynamic>? ?? [];
    final risk = _recommendation!['risk'] as Map<String, dynamic>? ?? {};
    final nextModule = _recommendation!['next_module'] as Map<String, dynamic>?;

    final radarData = competencies.map((c) {
      return ((c['mastery'] ?? 0.0) as num).toDouble();
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadRecommendation,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        children: [
          const Text(
            'Progress Kompetensi',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Grafik Kompetensi',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Radar chart
          if (radarData.isNotEmpty && radarData.length >= 3)
            Container(
              height: 256,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sage.withAlpha(51)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _RadarPainter(data: radarData),
                child: const SizedBox.expand(),
              ),
            )
          else if (radarData.isNotEmpty && radarData.length < 3)
            Container(
              height: 256,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sage.withAlpha(51)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Perlu minimal 3 kompetensi untuk radar chart.\nSekarang: ${radarData.length} kompetensi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.body, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              height: 256,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('Belum ada data kompetensi.')),
            ),

          const SizedBox(height: 22),

          // Skill cards
          ...competencies.map((c) {
            final mastery = ((c['mastery'] ?? 0.0) as num).toDouble();
            final title = c['module_title'] ?? 'Kompetensi';
            final (status, color) = _statusFromMastery(mastery);
            return _SkillCard(title: title, status: status, value: mastery, color: color);
          }),

          if (competencies.isEmpty)
            const _SkillCard(title: 'Belum ada data', status: 'BELUM MULAI', value: 0, color: AppColors.muted),

          const SizedBox(height: 16),

          // Risk status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _riskColor(risk['level'] as String? ?? 'low').withAlpha(38),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield,
                  color: _riskColor(risk['level'] as String? ?? 'low'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Risiko: ${_riskLabel(risk['level'] as String? ?? 'low')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rata-rata skor: ${((risk['average_score'] ?? 0.0) as num).toInt()}%'
                            ' \u2022 ${risk['attempt_count'] ?? 0} percobaan',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Next module
          if (nextModule != null) ...[
            const SizedBox(height: 16),
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
                    nextModule['description'] ?? 'Mulai modul ini.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    return switch (level) {
      'high' => AppColors.red,
      'medium' => AppColors.yellow,
      _ => AppColors.green2,
    };
  }

  String _riskLabel(String level) {
    return switch (level) {
      'high' => 'Tinggi',
      'medium' => 'Sedang',
      _ => 'Rendah',
    };
  }

  (String, Color) _statusFromMastery(double mastery) {
    if (mastery >= 0.7) return ('DIKUASAI', AppColors.green2);
    if (mastery >= 0.4) return ('PROSES', AppColors.yellow);
    return ('PERLU BANTUAN', AppColors.red);
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

class _RadarPainter extends CustomPainter {
  final List<double> data;
  _RadarPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE0E4DC);
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final r = size.shortestSide * .32;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, r * i / 3, p);
    }

    final axis = Paint()
      ..color = const Color(0xFFE0E4DC)
      ..strokeWidth = 1;
    final n = data.length;
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      canvas.drawLine(
        center,
        center + Offset(r * 1.45 * math.cos(a), r * 1.45 * math.sin(a)),
        axis,
      );
    }

    final fill = Paint()
      ..color = AppColors.green.withAlpha(56)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = AppColors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final pt = center + Offset(r * data[i] * math.cos(a), r * data[i] * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
