import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Interactive donut chart with sections, inner‑radius hole (≈0.6 ratio),
/// and a 3‑column grid legend.
///
/// Mirrors the iOS [InteractiveDonutChart] from Swift Charts.
class InteractiveDonutChart extends StatelessWidget {
  final List<MuscleDistribution> data;

  const InteractiveDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return Column(
      children: [
        // -- Donut --
        SizedBox(
          height: 180,
          child: PieChart(_buildChartData()),
        ),
        const SizedBox(height: 16),
        // -- Custom legend (3‑column grid) --
        _buildLegend(context),
      ],
    );
  }

  PieChartData _buildChartData() {
    return PieChartData(
      sections: data.map((item) {
        return PieChartSectionData(
          value: item.value,
          color: item.color,
          radius: 0, // fill available space
          title: '',
        );
      }).toList(),
      centerSpaceRadius: 60,
      sectionsSpace: 2,
      pieTouchData: PieTouchData(
        enabled: true,
        touchCallback: (event, response) {
          // Tap handling left for consumers via callbacks if needed.
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Build rows of 3 items each, matching iOS stride(from:to:by:).
    final rows = <List<MuscleDistribution>>[];
    for (var i = 0; i < data.length; i += 3) {
      rows.add(data.sublist(i, (i + 3).clamp(0, data.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final item in row) Expanded(child: _legendItem(item, context)),
              // Fill remaining slots so spacing stays aligned
              if (row.length < 3)
                ...List.generate(3 - row.length, (_) => const Expanded(child: SizedBox())),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _legendItem(MuscleDistribution item, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            item.group,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
