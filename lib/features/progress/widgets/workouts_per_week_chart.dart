import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Bar chart showing workout frequency per week using fl_chart.
///
/// Mirrors iOS InteractiveBarChart for workouts per week.
class WorkoutsPerWeekChart extends StatelessWidget {
  final List<VolumePoint> volumeData;

  const WorkoutsPerWeekChart({super.key, required this.volumeData});

  List<_WeekData> _groupByWeek() {
    if (volumeData.isEmpty) return [];

    final Map<int, _WeekData> weeks = {};
    for (final point in volumeData) {
      final date = DateTime.tryParse(point.date);
      if (date == null) continue;
      final weekNumber = _getWeekNumber(date);
      weeks.putIfAbsent(weekNumber, () => _WeekData(weekNumber: weekNumber, count: 0));
      weeks[weekNumber]!.count++;
    }

    final sorted = weeks.values.toList()..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    return sorted;
  }

  int _getWeekNumber(DateTime date) {
    // Approximate week number within the data range
    return date.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
  }

  @override
  Widget build(BuildContext context) {
    final weekData = _groupByWeek();
    if (weekData.isEmpty) {
      return Center(
        child: Text(
          'No workout data yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    final maxY = weekData.fold<int>(0, (max, w) => w.count > max ? w.count : max);
    final yMax = (maxY + 1).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax < 5 ? 5 : yMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} workouts',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weekData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'W${weekData[index].weekNumber % 100}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: weekData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: Colors.purple,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _WeekData {
  final int weekNumber;
  int count;

  _WeekData({required this.weekNumber, required this.count});
}
