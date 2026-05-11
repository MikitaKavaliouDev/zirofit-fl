import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A single data point for exercise-specific progress tracking.
///
/// Contains both [weight] and [volume] measurements for a given [date],
/// allowing the chart to toggle between views.
class ExerciseDataPoint {
  final DateTime date;
  final double weight;
  final double volume;

  const ExerciseDataPoint({
    required this.date,
    required this.weight,
    required this.volume,
  });
}

/// Analytics widget for tracking exercise-specific progress over time.
///
/// Features:
/// - Dropdown to select which exercise to inspect
/// - Line chart (fl_chart) showing weight × date or volume × date
/// - Toggle between weight and volume views
/// - All-time best line as a dashed horizontal reference
/// - Config: [exerciseId] for persisted exercise selection
///
/// Mirrors iOS ExerciseProgressWidget.
class ExerciseProgressWidget extends StatefulWidget {
  /// Names of exercises available for selection in the dropdown.
  final List<String> exerciseNames;

  /// Data points for the currently selected exercise.
  ///
  /// These should be pre-filtered to the relevant exercise by the parent.
  /// When empty, the chart shows an appropriate empty state.
  final List<ExerciseDataPoint> dataPoints;

  /// Whether data is still loading.
  final bool isLoading;

  /// Optional persisted exercise ID to pre-select.
  final String? exerciseId;

  const ExerciseProgressWidget({
    super.key,
    this.exerciseNames = const [],
    this.dataPoints = const [],
    this.isLoading = false,
    this.exerciseId,
  });

  @override
  State<ExerciseProgressWidget> createState() => _ExerciseProgressWidgetState();
}

class _ExerciseProgressWidgetState extends State<ExerciseProgressWidget> {
  bool _showWeight = true;
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    // Pre-select from config if valid
    if (widget.exerciseId != null &&
        widget.exerciseNames.contains(widget.exerciseId)) {
      _selectedExercise = widget.exerciseId;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelector(context),
        const SizedBox(height: 12),
        _buildChartContent(context),
      ],
    );
  }

  Widget _buildSelector(BuildContext context) {
    if (widget.exerciseNames.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No exercise data available',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedExercise != null &&
              widget.exerciseNames.contains(_selectedExercise)
          ? _selectedExercise
          : null,
      decoration: InputDecoration(
        hintText: 'Select exercise',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        isDense: true,
      ),
      items: widget.exerciseNames.map((name) {
        return DropdownMenuItem(
          value: name,
          child: Text(name, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedExercise = value;
        });
      },
    );
  }

  Widget _buildChartContent(BuildContext context) {
    // No exercise selected — prompt
    if (_selectedExercise == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Select an exercise above to see progress',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final data = widget.dataPoints;

    // No data for this exercise
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.fitness_center,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No progress data for $_selectedExercise yet',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Not enough data points
    if (data.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Need at least 2 data points to show a chart.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildToggle(context),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: _buildChart(context, data)),
      ],
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Row(
      children: [
        _ToggleChip(
          label: 'Weight',
          selected: _showWeight,
          onTap: () => setState(() => _showWeight = true),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'Volume',
          selected: !_showWeight,
          onTap: () => setState(() => _showWeight = false),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List<ExerciseDataPoint> data) {
    final chartColor = _showWeight ? Colors.orange : Colors.blue;

    // Build spots and compute Y range
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < data.length; i++) {
      final val = _showWeight ? data[i].weight : data[i].volume;
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    // Y-axis padding
    final yPadding = minY == maxY ? minY * 0.2 : (maxY - minY) * 0.2;
    final yMin = (minY - yPadding).clamp(0.0, double.infinity);
    final yMax = maxY + yPadding;

    // All-time best value
    final allTimeBest = _showWeight
        ? data.map((d) => d.weight).reduce((a, b) => a > b ? a : b)
        : data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        lineBarsData: [
          // Main data line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: chartColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 30,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: chartColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  chartColor.withValues(alpha: 0.2),
                  chartColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        // All-time best as horizontal reference line
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: allTimeBest,
              color: Colors.green,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _calculateInterval(spots.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${data[index].date.month}/${data[index].date.day}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
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
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        minY: yMin,
        maxY: yMax,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                final date =
                    index < data.length ? data[index].date : null;
                final dateStr =
                    date != null ? '${date.month}/${date.day}' : '';
                final val =
                    _showWeight ? data[index].weight : data[index].volume;
                final unit = _showWeight ? 'kg' : 'vol';
                return LineTooltipItem(
                  '$dateStr\n${val.toStringAsFixed(1)} $unit',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).ceilToDouble();
  }
}

/// A small toggle chip used for Weight/Volume switching.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }
}
