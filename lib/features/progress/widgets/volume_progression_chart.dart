import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Line chart showing volume over time with gradient fill and tappable data
/// points.
///
/// Mirrors iOS InteractiveLineChart for volume progression.
class VolumeProgressionChart extends StatelessWidget {
  final List<VolumePoint> volumeData;

  const VolumeProgressionChart({super.key, required this.volumeData});

  @override
  Widget build(BuildContext context) {
    if (volumeData.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Log more sessions to see progression',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < volumeData.length; i++) {
      final vol = volumeData[i].volume;
      spots.add(FlSpot(i.toDouble(), vol));
      if (vol < minY) minY = vol;
      if (vol > maxY) maxY = vol;
    }

    final yPadding = (maxY - minY) * 0.15;
    final yMin = (minY - yPadding).clamp(0.0, double.infinity);
    final yMax = maxY + yPadding;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.blue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 30,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.blue,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _calculateInterval(spots.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= volumeData.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.tryParse(volumeData[index].date);
                if (date == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
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
                  _formatVolume(value),
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
                final date = index < volumeData.length
                    ? DateTime.tryParse(volumeData[index].date)
                    : null;
                final dateStr = date != null
                    ? '${date.month}/${date.day}'
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${_formatVolume(spot.y)} kg',
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

  String _formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }
}
