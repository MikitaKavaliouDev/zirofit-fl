import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';

/// A data point used to render history charts and lists.
///
/// The caller (e.g. [MeasurementsScreen]) converts provider data into
/// this generic representation so that the history screen stays agnostic
/// of the data source (API or local storage).
typedef MeasurementDataPoint = ({DateTime date, double value});

/// Historical view for a single measurement type.
///
/// Displays a line chart (via fl_chart) and a scrollable list of past
/// entries sorted newest-first. Shows an empty state when no data exists.
class MeasurementHistoryScreen extends StatefulWidget {
  const MeasurementHistoryScreen({
    super.key,
    required this.type,
    required this.dataPoints,
  });

  /// The measurement type whose history is shown.
  final MeasurementType type;

  /// Historical data points. Expected to contain at least two points for a
  /// meaningful chart; the empty state is shown when this list is empty.
  final List<MeasurementDataPoint> dataPoints;

  @override
  State<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState extends State<MeasurementHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.name),
      ),
      body: widget.dataPoints.isEmpty
          ? _EmptyHistory(
              theme: theme,
              typeName: widget.type.name,
            )
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Sort newest-first for the list, oldest-first for the chart
    final newestFirst = widget.dataPoints.sorted(
      (a, b) => b.date.compareTo(a.date),
    );
    final oldestFirst = widget.dataPoints.sorted(
      (a, b) => a.date.compareTo(b.date),
    );

    final unit = _displayUnit(widget.type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------------------------
          // Line chart
          // ------------------------------------------------------------------
          SizedBox(
            height: 220,
            child: _buildChart(oldestFirst, unit, theme),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------------------
          // History list header
          // ------------------------------------------------------------------
          Text(
            'History',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // ------------------------------------------------------------------
          // Measurement entries
          // ------------------------------------------------------------------
          ...newestFirst.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;

            // Change from previous (older) entry
            final nextIndex = index + 1;
            final change = nextIndex < newestFirst.length
                ? point.value - newestFirst[nextIndex].value
                : 0.0;

            return _HistoryRow(
              point: point,
              unit: unit,
              change: change,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<MeasurementDataPoint> sortedData,
    String unit,
    ThemeData theme,
  ) {
    final spots = sortedData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    // Determine how many labels to show on the x-axis
    final totalPoints = sortedData.length;
    final labelInterval = _labelInterval(totalPoints);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _yInterval(sortedData),
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                axisNameSize: 20,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: _yInterval(sortedData),
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toStringAsFixed(value < 10 ? 1 : 0),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: labelInterval,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedData.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MM/dd').format(sortedData[idx].date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
                left: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            minY: _minValue(sortedData) * 0.95,
            maxY: _maxValue(sortedData) * 1.05,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: spots.length <= 30,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: theme.colorScheme.primary,
                    strokeWidth: 1.5,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _minValue(List<MeasurementDataPoint> data) {
    return data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  double _maxValue(List<MeasurementDataPoint> data) {
    return data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  double _yInterval(List<MeasurementDataPoint> data) {
    final min = _minValue(data);
    final max = _maxValue(data);
    final range = max - min;
    if (range == 0) return 1;
    // Aim for ~4 horizontal grid lines
    final raw = range / 4;
    // Round to a "nice" number
    final magnitude = _pow10((raw).toStringAsFixed(0).length - 1);
    return (raw / magnitude).ceilToDouble() * magnitude;
  }

  static double _pow10(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  double _labelInterval(int totalPoints) {
    if (totalPoints <= 6) return 1;
    if (totalPoints <= 12) return 2;
    if (totalPoints <= 24) return 4;
    return (totalPoints / 6).ceilToDouble();
  }

  String _displayUnit(MeasurementType type) {
    if (type.category == 'core') {
      switch (type.id) {
        case 'weight':
          return 'kg';
        case 'body_fat':
          return '%';
        default:
          return type.unit;
      }
    }
    return type.unit;
  }
}

// =============================================================================
// Empty history state
// =============================================================================

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.theme,
    required this.typeName,
  });

  final ThemeData theme;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No measurements recorded yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your past $typeName measurements '
              'will appear here once you start tracking.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Single history entry row
// =============================================================================

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.point,
    required this.unit,
    required this.change,
    required this.theme,
  });

  final MeasurementDataPoint point;
  final String unit;
  final double change;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isIncrease = change > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(point.date),
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Value
          Expanded(
            flex: 1,
            child: Text(
              '${point.value.toStringAsFixed(1)} $unit',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),

          // Change indicator
          SizedBox(
            width: 20,
            child: change != 0
                ? Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isIncrease
                        ? Colors.red
                        : Colors.green,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Extension on List to provide sorted() similar to Kotlin / Swift.
// ===========================================================================

extension _SortedExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = [...this];
    copy.sort(compare);
    return copy;
  }
}
