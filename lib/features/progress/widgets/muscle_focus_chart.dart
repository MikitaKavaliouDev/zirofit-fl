import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';

/// Bar chart showing muscle group focus with total set counts.
///
/// Connects directly to [analyticsProvider] for real data.
/// Supports time range toggling: This Week (7d), This Month (30d), All Time
/// (90d). Bars are color-coded with a legend showing total sets per muscle.
class MuscleFocusChart extends ConsumerStatefulWidget {
  const MuscleFocusChart({super.key});

  @override
  ConsumerState<MuscleFocusChart> createState() => _MuscleFocusChartState();
}

class _MuscleFocusChartState extends ConsumerState<MuscleFocusChart> {
  _TimeRange _selectedRange = _TimeRange.thisMonth;

  /// Distinct palette for muscle group bars. Uses brand-adjacent colors
  /// rather than the Material set in the old donut chart.
  static const _barColors = [
    Color(0xFF10B981), // Emerald  (primary)
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  int get _daysForRange {
    switch (_selectedRange) {
      case _TimeRange.thisWeek:
        return 7;
      case _TimeRange.thisMonth:
        return 30;
      case _TimeRange.allTime:
        return 90;
    }
  }

  void _onRangeChanged(_TimeRange range) {
    if (range == _selectedRange) return;
    setState(() {
      _selectedRange = range;
    });
    // Reload analytics scoped to the selected time range.
    ref.read(analyticsProvider.notifier).loadAnalytics(days: _daysForRange);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final muscleData = analyticsState.analytics?.muscleDistribution ?? [];
    final isLoading = analyticsState.isLoading;

    // --- Loading (no cached data yet) ---
    if (isLoading && muscleData.isEmpty) {
      return Column(
        children: [
          _buildTimeToggle(),
          const SizedBox(height: 24),
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
      );
    }

    // --- Empty ---
    if (muscleData.isEmpty) {
      return Column(
        children: [
          _buildTimeToggle(),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'No muscle data yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // --- Data ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeToggle(),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildBarChart(muscleData),
        ),
        const SizedBox(height: 16),
        _buildLegend(muscleData),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Time range toggle
  // ------------------------------------------------------------------

  Widget _buildTimeToggle() {
    return Row(
      children: [
        _ToggleChip(
          label: 'This Week',
          selected: _selectedRange == _TimeRange.thisWeek,
          onTap: () => _onRangeChanged(_TimeRange.thisWeek),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'This Month',
          selected: _selectedRange == _TimeRange.thisMonth,
          onTap: () => _onRangeChanged(_TimeRange.thisMonth),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'All Time',
          selected: _selectedRange == _TimeRange.allTime,
          onTap: () => _onRangeChanged(_TimeRange.allTime),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Bar chart
  // ------------------------------------------------------------------

  Widget _buildBarChart(List<MusclePoint> muscleData) {
    final maxCount =
        muscleData.fold<int>(0, (max, m) => m.count > max ? m.count : max);
    final yMax = (maxCount * 1.25).clamp(5.0, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final muscle = muscleData[groupIndex].muscle;
              final count = muscleData[groupIndex].count;
              return BarTooltipItem(
                '$muscle\n$count sets',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
                if (index < 0 || index >= muscleData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _shortMuscleName(muscleData[index].muscle),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
              reservedSize: 28,
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
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(maxCount),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.12),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: muscleData.asMap().entries.map((entry) {
          final color = _barColors[entry.key % _barColors.length];
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: color,
                width: 18,
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

  // ------------------------------------------------------------------
  // Legend
  // ------------------------------------------------------------------

  Widget _buildLegend(List<MusclePoint> muscleData) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: muscleData.asMap().entries.map((entry) {
        final color = _barColors[entry.key % _barColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
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
    );
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Abbreviates long muscle names for the x-axis labels.
  String _shortMuscleName(String name) {
    if (name.length <= 6) return name;
    return '${name.substring(0, 4)}.';
  }

  /// Reasonable grid-line interval based on the maximum set count.
  double _gridInterval(int maxCount) {
    if (maxCount <= 5) return 1;
    if (maxCount <= 20) return 5;
    return 10;
  }
}

// ---------------------------------------------------------------------------
// Private types & helpers
// ---------------------------------------------------------------------------

enum _TimeRange { thisWeek, thisMonth, allTime }

/// A small pill-shaped toggle chip used in the time range selector.
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? theme.colorScheme.primary : Colors.grey,
          ),
        ),
      ),
    );
  }
}
