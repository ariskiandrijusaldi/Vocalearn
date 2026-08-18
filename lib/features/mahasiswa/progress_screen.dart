import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/competency.dart';
import '../../data/providers/competency_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 7: Progress & Gamifikasi
/// ==========================================================
/// Terhubung ke to-do list §7 & Mini-PRD Fitur 3.
/// Acceptance criteria:
///   - 1 halaman menampilkan semua Competency dengan warna status
///   - minimal 1 badge muncul saat 1 kompetensi mencapai status "dikuasai"
///
/// Sengaja TIDAK dibuat leaderboard/badge bertingkat (out of scope
/// di Mini-PRD) — gamifikasi di sini memang dibuat ringan.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competencies = ref.watch(competencyProvider);
    final masteredCompetencies =
    competencies.where((c) => c.status == CompetencyStatus.dikuasai).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Kompetensi')),
      body: competencies.isEmpty
          ? const Center(child: Text('Isi diagnostik awal dulu untuk melihat progres.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Grafik Kompetensi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _CompetencyBarChart(competencies: competencies),
          ),
          const SizedBox(height: 24),

          Text('Rincian per Kompetensi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...competencies.map(
                (c) => Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: LinearProgressIndicator(
                  value: c.masteryScore,
                  color: _colorForStatus(c.status),
                ),
                trailing: Text('${(c.masteryScore * 100).round()}%'),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('Lencana Pencapaian', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (masteredCompetencies.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada lencana — selesaikan modul praktik '
                    'sampai kompetensimu berstatus "Dikuasai".'),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: masteredCompetencies
                  .map((c) => _BadgeChip(competencyName: c.name))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Color _colorForStatus(CompetencyStatus status) {
    return switch (status) {
      CompetencyStatus.dikuasai => Colors.green,
      CompetencyStatus.dalamProses => Colors.orange,
      CompetencyStatus.perluIntervensi => Colors.red,
      CompetencyStatus.belumMulai => Colors.grey,
    };
  }
}

class _CompetencyBarChart extends StatelessWidget {
  final List<Competency> competencies;
  const _CompetencyBarChart({required this.competencies});

  Color _colorForStatus(CompetencyStatus status) {
    return switch (status) {
      CompetencyStatus.dikuasai => Colors.green,
      CompetencyStatus.dalamProses => Colors.orange,
      CompetencyStatus.perluIntervensi => Colors.red,
      CompetencyStatus.belumMulai => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 1.0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 0.25),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= competencies.length) return const SizedBox();
                final label = competencies[index].name;
                final shortLabel =
                label.length > 10 ? '${label.substring(0, 9)}…' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(shortLabel, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (var i = 0; i < competencies.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: competencies[i].masteryScore,
                  color: _colorForStatus(competencies[i].status),
                  width: 28,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String competencyName;
  const _BadgeChip({required this.competencyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA726)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(competencyName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}