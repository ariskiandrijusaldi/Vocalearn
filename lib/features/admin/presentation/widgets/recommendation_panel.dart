import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/recommendation.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/recommendation_repository.dart';

class RecommendationPanel extends StatefulWidget {
  const RecommendationPanel({super.key, required this.repository});

  final RecommendationRepository repository;

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel>
    with AutomaticKeepAliveClientMixin {
  List<User> _students = [];
  int? _selectedId;
  Recommendation? _result;
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_loading) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await widget.repository.getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedId = students.isEmpty ? null : students.first.id;
        _loading = false;
      });
      if (students.isNotEmpty) await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      await widget.repository.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      return;
    }
    await _loadStudents();
  }

  Future<void> _load() async {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getRecommendation(id);
      if (!mounted) return;
      setState(() {
        _result = result;
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

  Color _riskColor(String level) {
    return switch (level) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };
  }

  String _riskLabel(String level) {
    return switch (level) {
      'high' => 'Risiko Tinggi',
      'medium' => 'Risiko Sedang',
      _ => 'Risiko Rendah',
    };
  }

  String _shortTitle(String title) {
    final words = title.split(' ');
    return words.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _students.isEmpty ? _loadStudents : _load,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(child: Text('Belum ada mahasiswa.'));
    }

    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pilih Mahasiswa',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final student in _students)
                    DropdownMenuItem(
                      value: student.id,
                      child: Text('${student.fullName} (${student.nim ?? '-'})'),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _selectedId = value);
                  _load();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang data',
              onPressed: _loading ? null : _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (result == null && _loading)
          const Center(child: CircularProgressIndicator())
        else if (result == null)
          const Center(child: Text('Pilih mahasiswa untuk melihat rekomendasi.'))
        else ...[
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          _RiskCard(
            result: result,
            color: _riskColor(result.riskLevel),
            label: _riskLabel(result.riskLevel),
          ),
          if (result.aiSuggestion != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saran AI',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.aiSuggestion!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (result.nextModule != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modul Selanjutnya',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.nextModule!.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result.reason),
              ),
            ),
          const SizedBox(height: 16),
          if (result.competencies.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada data kompetensi untuk mahasiswa ini.'),
              ),
            )
          else
            _CompetencyChart(competencies: result.competencies, shortTitle: _shortTitle),
        ],
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.result, required this.color, required this.label});

  final Recommendation result;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  'Skor rata-rata: ${result.averageScore.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Jumlah latihan: ${result.attemptCount}'),
            const SizedBox(height: 8),
            for (final reason in result.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompetencyChart extends StatelessWidget {
  const _CompetencyChart({required this.competencies, required this.shortTitle});

  final List<Competency> competencies;
  final String Function(String title) shortTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mastery per Modul', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: 1,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    for (var i = 0; i < competencies.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: competencies[i].mastery,
                            color: Theme.of(context).colorScheme.secondary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 0.25),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= competencies.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              shortTitle(competencies[index].moduleTitle),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final competency = competencies[group.x];
                        return BarTooltipItem(
                          '${competency.moduleTitle}\n'
                          '${(competency.mastery * 100).toStringAsFixed(0)}% '
                          '(${competency.attempts} latihan)',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
