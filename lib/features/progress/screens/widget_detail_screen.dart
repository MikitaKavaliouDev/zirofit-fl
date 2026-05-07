import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';
import 'package:zirofit_fl/features/progress/widgets/activity_heatmap_widget.dart';
import 'package:zirofit_fl/features/progress/widgets/muscle_focus_chart.dart';

/// Expanded detail view of a single analytics widget.
///
/// Mirrors iOS WidgetDetailView.
class WidgetDetailScreen extends StatelessWidget {
  final AnalyticsWidgetType type;
  final List<VolumePoint> volumeData;
  final List<MusclePoint> muscleData;
  final List<AnalyticsPersonalRecord> prData;
  final List<String> heatmapDates;
  final double consistency;

  const WidgetDetailScreen({
    super.key,
    required this.type,
    this.volumeData = const [],
    this.muscleData = const [],
    this.prData = const [],
    this.heatmapDates = const [],
    this.consistency = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(type.displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart section
            if (_hasChart)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildChart(context),
              ),
            const SizedBox(height: 24),
            // Data list section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _listTitle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildDataList(context),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasChart {
    switch (type) {
      case AnalyticsWidgetType.workoutsPerWeek:
      case AnalyticsWidgetType.volumeProgression:
      case AnalyticsWidgetType.muscleFocus:
      case AnalyticsWidgetType.heatMap:
      case AnalyticsWidgetType.consistency:
        return true;
      default:
        return false;
    }
  }

  String get _listTitle {
    switch (type) {
      case AnalyticsWidgetType.prs:
        return 'Records Log';
      case AnalyticsWidgetType.muscleFocus:
        return 'Muscle Breakdown';
      case AnalyticsWidgetType.consistency:
        return 'Consistency Log';
      default:
        return 'Data Log';
    }
  }

  Widget _buildChart(BuildContext context) {
    switch (type) {
      case AnalyticsWidgetType.workoutsPerWeek:
        return _buildWorkoutsChart(context);
      case AnalyticsWidgetType.volumeProgression:
        return _buildVolumeChart(context);
      case AnalyticsWidgetType.muscleFocus:
        return _buildMuscleChart(context);
      case AnalyticsWidgetType.heatMap:
        return ActivityHeatMapWidget(activeDates: heatmapDates);
      case AnalyticsWidgetType.consistency:
        return _buildConsistencyGauge(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWorkoutsChart(BuildContext context) {
    final weekData = _groupByWeek();
    if (weekData.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weekData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
          barGroups: weekData.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.purple,
                  width: 20,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'W${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Map<int, int> _groupByWeek() {
    final weeks = <int, int>{};
    for (final point in volumeData) {
      final date = DateTime.tryParse(point.date);
      if (date == null) continue;
      final weekNum = date.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
      weeks[weekNum] = (weeks[weekNum] ?? 0) + 1;
    }
    return weeks;
  }

  Widget _buildVolumeChart(BuildContext context) {
    if (volumeData.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Log more sessions to see progression')),
      );
    }

    final spots = volumeData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.volume);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.withValues(alpha: 0.3), Colors.blue.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= volumeData.length) return const SizedBox.shrink();
                  final date = DateTime.tryParse(volumeData[idx].date);
                  if (date == null) return const SizedBox.shrink();
                  return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildMuscleChart(BuildContext context) {
    return const SizedBox(
      height: 250,
      child: MuscleFocusChart(),
    );
  }

  Widget _buildConsistencyGauge(BuildContext context) {
    final clampedConsistency = consistency.clamp(0.0, 100.0);
    return SizedBox(
      height: 250,
      child: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: clampedConsistency / 100.0,
                strokeWidth: 15,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${clampedConsistency.toInt()}%',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const Text('30 Days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataList(BuildContext context) {
    final theme = Theme.of(context);

    switch (type) {
      case AnalyticsWidgetType.prs:
        if (prData.isEmpty) {
          return const Center(child: Text('No records yet'));
        }
        return Column(
          children: prData.map((pr) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pr.exercise, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(pr.date.toIso8601String(), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    '${pr.value.toStringAsFixed(1)} kg',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.purple),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case AnalyticsWidgetType.muscleFocus:
        if (muscleData.isEmpty) {
          return const Center(child: Text('No muscle data'));
        }
        return Column(
          children: muscleData.map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(m.muscle, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${m.count} sets', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        );

      default:
        if (volumeData.isEmpty) {
          return const Center(child: Text('No data available yet'));
        }
        return Column(
          children: volumeData.reversed.map((v) {
            final date = DateTime.tryParse(v.date);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date != null ? '${date.month}/${date.day}/${date.year}' : v.date,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text('${v.volume.toInt()} kg', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue)),
                ],
              ),
            );
          }).toList(),
        );
    }
  }
}
