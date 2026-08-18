import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/learning_record.dart';
import '../../../../domain/entities/user.dart';

class AverageScoreChart extends StatelessWidget {
  const AverageScoreChart({super.key, required this.students, required this.records});

  final List<User> students;
  final List<LearningRecord> records;

  @override
  Widget build(BuildContext context) {
    final points = students
        .map((student) {
          final studentRecords =
              records.where((r) => r.studentId == student.id).toList();
          final average = studentRecords.isEmpty
              ? 0.0
              : studentRecords.map((r) => r.score).reduce((a, b) => a + b) /
                  studentRecords.length;
          return (label: student.nim ?? student.fullName, value: average);
        })
        .toList();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    color: Theme.of(context).colorScheme.primary,
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      points[index].label,
                      style: const TextStyle(fontSize: 11),
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
                final point = points[group.x];
                return BarTooltipItem(
                  '${point.label}\n${point.value.toStringAsFixed(0)}',
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
    );
  }
}
