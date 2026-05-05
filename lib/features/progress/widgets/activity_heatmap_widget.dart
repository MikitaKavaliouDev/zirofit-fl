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
    final allDays = List.generate(
      daysToDisplay,
      (i) => now.subtract(Duration(days: daysToDisplay - 1 - i)),
    );

    final dateStrings = allDays.map((d) => _formatDate(d)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        SizedBox(
          height: 16,
          child: Row(
            children: _buildMonthLabels(allDays),
          ),
        ),
        const SizedBox(height: 4),
        // Day-of-week labels + grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ['Mon', '', 'Wed', '', 'Fri', '']
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
            const SizedBox(width: 4),
            // Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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

  List<Widget> _buildMonthLabels(List<DateTime> days) {
    final months = <Widget>[];
    String? lastMonth;
    for (final day in days) {
      final monthKey = '${day.year}-${day.month}';
      if (monthKey != lastMonth) {
        months.add(
          SizedBox(
            width: 12 * 7, // approx width of a week column
            child: Text(
              _monthAbbr(day.month),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        );
        lastMonth = monthKey;
      }
    }
    return months;
  }

  String _monthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
