import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Donut/pie chart showing muscle group distribution with legend.
///
/// Mirrors iOS InteractiveDonutChart.
class MuscleFocusChart extends StatelessWidget {
  final List<MusclePoint> muscleData;

  const MuscleFocusChart({super.key, required this.muscleData});

  static const _chartColors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.green,
    Colors.cyan,
    Colors.red,
    Colors.amber,
    Colors.indigo,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    if (muscleData.isEmpty) {
      return Center(
        child: Text(
          'No muscle data yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    final total = muscleData.fold<int>(0, (sum, m) => sum + m.count);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  // Could add selected state here
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: muscleData.asMap().entries.map((entry) {
                final isLast = entry.key == muscleData.length - 1;
                final percentage = total > 0 ? entry.value.count / total : 0.0;
                return PieChartSectionData(
                  color: _chartColors[entry.key % _chartColors.length],
                  value: percentage * 100,
                  title: percentage > 0.08
                      ? '${(percentage * 100).toInt()}%'
                      : '',
                  radius: isLast ? 55 : 50,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: muscleData.asMap().entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _chartColors[entry.key % _chartColors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.value.muscle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.value.count} sets',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
