import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';

/// Interactive bar chart with tap‑to‑select, gradient fill, and dynamic
/// x‑axis labels driven by [DateRange].
///
/// Mirrors the iOS [InteractiveBarChart] from Swift Charts.
class InteractiveBarChart extends StatefulWidget {
  final List<VolumeData> data;
  final Color color;
  final DateRange dateRange;
  final double? yDomainMax;

  const InteractiveBarChart({
    super.key,
    required this.data,
    required this.color,
    this.dateRange = DateRange.last7Days,
    this.yDomainMax,
  });

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart> {
  int? _selectedIndex;

  VolumeData? get _selectedValue {
    if (_selectedIndex != null && _selectedIndex! < widget.data.length) {
      return widget.data[_selectedIndex!];
    }
    return null;
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
        // -- Header / tooltip --
        if (_selectedValue case final selected?)
          _buildHeader(selected)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Select a bar to view details',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        const SizedBox(height: 8),
        // -- Chart --
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BarChart(_buildChartData()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(VolumeData selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(selected.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${selected.volume.toStringAsFixed(0)} kg',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  BarChartData _buildChartData() {
    final data = widget.data;
    final maxY = widget.yDomainMax ??
        data.fold<double>(0, (m, d) => d.volume > m ? d.volume : m) *
            1.15; // 15% headroom

    return BarChartData(
      maxY: maxY,
      barGroups: data.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        final isSelected = _selectedIndex == i;
        final barColor = widget.color;
        final opacity = _selectedIndex == null || isSelected ? 1.0 : 0.4;

        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.volume,
              color: barColor.withOpacity(opacity),
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
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
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: _xInterval(),
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  _formatDateLabel(data[i].date),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.15),
          strokeWidth: 1,
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchCallback: (event, response) {
          if (event is FlTapUpEvent && response?.spot != null) {
            setState(() {
              _selectedIndex = response!.spot!.touchedBarGroupIndex;
            });
          }
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF2D2D2D),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex >= data.length) return null;
            final d = data[groupIndex];
            return BarTooltipItem(
              '${DateFormat('MMM dd, yyyy').format(d.date)}\n'
              '${d.volume.toStringAsFixed(0)} kg',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Format x‑axis label according to the current [DateRange].
  String _formatDateLabel(DateTime date) {
    return switch (widget.dateRange) {
      DateRange.last7Days => DateFormat('E').format(date), // Mon, Tue …
      DateRange.last30Days => DateFormat('M/d').format(date), // 5/12 …
      DateRange.threeMonths => DateFormat('MMM').format(date), // Jan …
    };
  }

  double _xInterval() {
    return switch (widget.dateRange) {
      DateRange.last7Days => 1,
      DateRange.last30Days => 7,
      DateRange.threeMonths => 30,
    };
  }
}
