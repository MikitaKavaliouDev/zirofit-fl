import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading placeholder for a calendar month grid view.
///
/// Displays a shimmer animation over a 7-column × 6-row grid of rounded
/// rectangles, with a weekday header row at the top.
///
/// Mirrors iOS [CalendarSkeleton].
class CalendarSkeleton extends StatelessWidget {
  /// The number of day cells to render per row.
  final int columns;

  /// The number of week rows to render.
  final int rows;

  const CalendarSkeleton({
    super.key,
    this.columns = 7,
    this.rows = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdayLabels.map((label) {
          return Expanded(
            child: Center(
              child: Container(
                height: 14,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: columns * rows,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
