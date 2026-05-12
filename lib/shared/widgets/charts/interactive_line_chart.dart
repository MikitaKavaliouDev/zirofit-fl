import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';

/// Interactive line chart with touch crosshair, catmull‑rom interpolation,
/// gradient stroke + fill, and a y‑axis domain with 20% buffer.
///
/// Mirrors the iOS [InteractiveLineChart] from Swift Charts.
class InteractiveLineChart extends StatefulWidget {
  final List<VolumeData> data;
  final LinearGradient gradient;
  final LinearGradient fillGradient;

  const InteractiveLineChart({
    super.key,
    required this.data,
    required this.gradient,
    required this.fillGradient,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _selectedIndex;

  VolumeData? get _activeValue {
    final d = widget.data;
    if (_selectedIndex != null && _selectedIndex! < d.length) {
      return d[_selectedIndex!];
    }
    return d.isNotEmpty ? d.last : null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Header (tooltip mirror) --
        if (_activeValue case final active?) _buildHeader(active),
        const SizedBox(height: 8),
        // -- Chart --
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LineChart(_buildChartData()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(VolumeData active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(active.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) =>
                    widget.gradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  '${active.volume.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_selectedIndex == null)
            Text(
              'Long press to explore',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final data = widget.data;
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.volume);
    }).toList();

    // Y-axis domain with 20 % buffer
    final values = data.map((d) => d.volume).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final buffer = range * 0.2;
    final yMin = range == 0 ? minY - 5 : (minY - buffer).clamp(0.0, double.infinity);
    final yMax = range == 0 ? maxY + 5 : maxY + buffer;

    return LineChartData(
      minY: yMin,
      maxY: yMax,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _niceInterval(yMin, yMax),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.15),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: _xInterval(),
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('MMM').format(data[i].date),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _niceInterval(yMin, yMax),
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  '${value.toInt()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: widget.gradient,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              if (_selectedIndex == index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: widget.gradient.colors.last,
                );
              }
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.fillGradient.colors.first.withOpacity(0.35),
                widget.fillGradient.colors.last.withOpacity(0.02),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (response?.lineBarSpots?.isNotEmpty == true &&
              event is FlTapUpEvent) {
            setState(() {
              _selectedIndex = response!.lineBarSpots!.first.spotIndex;
            });
          }
        },
        getTouchedSpotIndicator: (barData, spots) {
          return spots.map((spot) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: widget.gradient.colors.last,
                  );
                },
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF2D2D2D),
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final i = spot.spotIndex;
              if (i >= data.length) return null;
              final d = data[i];
              return LineTooltipItem(
                '${DateFormat('MMM dd, yyyy').format(d.date)}\n'
                '${d.volume.toStringAsFixed(1)} kg',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Calculate a nice tick interval for horizontal grid lines.
  double _niceInterval(double min, double max) {
    final diff = max - min;
    if (diff <= 0) return 10;
    if (diff <= 20) return 5;
    if (diff <= 50) return 10;
    if (diff <= 200) return 50;
    return (diff / 5).ceilToDouble();
  }

  double _xInterval() {
    final n = widget.data.length;
    if (n <= 7) return 1;
    if (n <= 14) return 2;
    if (n <= 31) return 5;
    return (n / 6).ceilToDouble();
  }
}
