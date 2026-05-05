import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Performance summary widget showing Volume, Consistency, Frequency, and
/// Avg Volume metric cards with trend indicators.
///
/// Mirrors iOS [PerformanceSummaryWidget].
class PerformanceSummaryWidget extends StatelessWidget {
  final List<VolumePoint> volumeData;
  final int consistency;
  final int currentStreak;
  final int longestStreak;
  final double volumeTrend;
  final double consistencyTrend;
  final double frequencyTrend;
  final double averageVolumeTrend;

  const PerformanceSummaryWidget({
    super.key,
    required this.volumeData,
    required this.consistency,
    required this.currentStreak,
    required this.longestStreak,
    this.volumeTrend = 0,
    this.consistencyTrend = 0,
    this.frequencyTrend = 0,
    this.averageVolumeTrend = 0,
  });

  double get totalVolume =>
      volumeData.fold<double>(0.0, (sum, p) => sum + p.volume);

  double get averageVolume =>
      volumeData.isEmpty ? 0 : totalVolume / volumeData.length;

  double get frequency {
    if (volumeData.isEmpty) return 0;
    final dates = volumeData.map((p) => DateTime.tryParse(p.date)).whereType<DateTime>().toList();
    if (dates.isEmpty) return 0;
    dates.sort();
    final days = dates.last.difference(dates.first).inDays;
    final weeks = (days / 7).clamp(1.0, double.infinity);
    return volumeData.length / weeks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Streak bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STREAK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentStreak Days',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LONGEST STREAK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$longestStreak Days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Metric cards grid
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Volume',
                value: _formatLargeNumber(totalVolume),
                unit: 'kg',
                trend: _formatTrend(volumeTrend),
                isPositive: volumeTrend >= 0,
                icon: Icons.monitor_weight_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Consistency',
                value: '$consistency',
                unit: '%',
                trend: _formatTrend(consistencyTrend),
                isPositive: consistencyTrend >= 0,
                icon: Icons.bolt,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Frequency',
                value: frequency.toStringAsFixed(1),
                unit: '/ week',
                trend: _formatTrend(frequencyTrend),
                isPositive: frequencyTrend >= 0,
                icon: Icons.calendar_month,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Avg. Session',
                value: _formatLargeNumber(averageVolume),
                unit: 'kg',
                trend: _formatTrend(averageVolumeTrend),
                isPositive: averageVolumeTrend >= 0,
                icon: Icons.bar_chart,
                color: Colors.cyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toInt().toString();
  }

  String _formatTrend(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toInt()}%';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String trend;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(title, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 10,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
