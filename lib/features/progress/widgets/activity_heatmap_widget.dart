import 'package:flutter/material.dart';

/// Simple grid-based heat map showing 365 days of activity.
///
/// Green = active day, grey = inactive day.
/// Mirrors iOS HeatMapWidget.
class ActivityHeatMapWidget extends StatelessWidget {
  final List<String> activeDates;
  final int daysToDisplay;

  const ActivityHeatMapWidget({
    super.key,
    required this.activeDates,
    this.daysToDisplay = 365,
  });

  @override
  Widget build(BuildContext context) {
    final activeSet = activeDates.toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate the start date (365 days ago, padded to the previous Monday)
    final startRange = today.subtract(Duration(days: daysToDisplay - 1));
    // Weekday: 1 (Mon) to 7 (Sun). We want padding to start on Monday.
    final startDay = startRange.subtract(Duration(days: startRange.weekday - 1));
    
    final totalDays = today.difference(startDay).inDays + 1;
    final allDays = List.generate(
      totalDays,
      (i) => startDay.add(Duration(days: i)),
    );

    final dateStrings = allDays.map((d) => _formatDate(d)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels (Fixed on the left)
            Padding(
              padding: const EdgeInsets.only(top: 16.0), // Align with grid (under month labels)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ['Mon', '', 'Wed', '', 'Fri', '', 'Sun']
                    .map((label) => SizedBox(
                          height: 14,
                          child: label.isNotEmpty
                              ? Text(
                                  label,
                                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                                )
                              : const SizedBox.shrink(),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 4),
            // Scrollable area for Month labels + Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels
                    _buildMonthLabels(allDays),
                    const SizedBox(height: 4),
                    // Grid
                    SizedBox(
                      height: 98, // 7 rows * 14px
                      child: Wrap(
                        direction: Axis.vertical,
                        spacing: 2,
                        runSpacing: 2,
                        children: dateStrings.map((dateStr) {
                          final isActive = activeSet.contains(dateStr);
                          return Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.7)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Less', style: TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              final alphas = [0.15, 0.3, 0.5, 0.7, 1.0];
              return Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.grey.withValues(alpha: alphas[index])
                        : Colors.green.withValues(alpha: alphas[index]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
            const SizedBox(width: 4),
            const Text('More', style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildMonthLabels(List<DateTime> days) {
    final labels = <Widget>[];
    String? lastMonth;
    
    // Each column is 14 pixels wide (12 square + 2 runSpacing)
    for (int i = 0; i < days.length; i += 7) {
      final day = days[i];
      final monthKey = '${day.year}-${day.month}';
      if (monthKey != lastMonth) {
        labels.add(Positioned(
          left: (i / 7) * 14,
          child: Text(
            _monthAbbr(day.month),
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ));
        lastMonth = monthKey;
      }
    }

    return SizedBox(
      height: 12,
      width: (days.length / 7).ceil() * 14.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: labels,
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
