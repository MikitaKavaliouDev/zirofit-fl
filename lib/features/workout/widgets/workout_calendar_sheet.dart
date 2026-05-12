import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/shared/widgets/sheet_background_modifier.dart';
import 'package:zirofit_fl/shared/widgets/ziro_sheet_header.dart';

/// A scrollable multi-month calendar bottom sheet for browsing workout history
/// by date. Mirrors iOS [WorkoutCalendarSheet].
///
/// Displays 12 months (current + 11 prior) in a lazy-loaded [ListView.builder],
/// with a Monday-start week header, month headers in blue, and day cells that
/// indicate workout days (blue filled circle + dot), today (blue stroked
/// circle), or default styling.
///
/// {@tool dartpad}
/// ```dart
/// WorkoutCalendarSheet.show(
///   context: context,
///   completedDates: {DateTime(2026, 5, 10), DateTime(2026, 5, 8)},
///   onDateSelected: (date) => print('Selected: $date'),
/// );
/// ```
/// {@end-tool}
class WorkoutCalendarSheet extends StatefulWidget {
  /// Set of dates (normalized to midnight) that have completed workouts.
  ///
  /// Used to determine which day cells show the workout-indicator styling
  /// (blue filled circle + small blue dot).
  final Set<DateTime> completedDates;

  /// Initially selected date, if any.
  final DateTime? selectedDate;

  /// Called when a date is selected. The sheet is dismissed automatically
  /// after this callback.
  final void Function(DateTime date) onDateSelected;

  const WorkoutCalendarSheet({
    super.key,
    this.completedDates = const {},
    this.selectedDate,
    required this.onDateSelected,
  });

  /// Shows the [WorkoutCalendarSheet] as a modal bottom sheet with
  /// [isScrollControlled] enabled and constrained to 85% of screen height.
  static Future<void> show({
    required BuildContext context,
    Set<DateTime> completedDates = const {},
    DateTime? selectedDate,
    required void Function(DateTime date) onDateSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => WorkoutCalendarSheet(
        completedDates: completedDates,
        selectedDate: selectedDate,
        onDateSelected: onDateSelected,
      ),
    );
  }

  @override
  State<WorkoutCalendarSheet> createState() => _WorkoutCalendarSheetState();
}

class _WorkoutCalendarSheetState extends State<WorkoutCalendarSheet> {
  static const _daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthsToShow = 12;

  late final List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    _months = _generateMonths();
  }

  /// Generates a list of 12 months starting from the current month backwards.
  List<DateTime> _generateMonths() {
    final now = DateTime.now();
    return List.generate(_monthsToShow, (i) {
      return DateTime(now.year, now.month - i, 1);
    });
  }

  /// Returns the number of days in the given [month].
  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// Returns the Monday-based weekday offset for the first day of the given
  /// [month]. Monday = 0, Tuesday = 1, ..., Sunday = 6.
  int _monthOffset(DateTime month) {
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    return month.weekday - 1;
  }

  /// Checks whether the given [date] has a completed workout.
  bool _hasWorkout(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return widget.completedDates.contains(normalized);
  }

  /// Checks whether the given [date] is today.
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _onDateTap(DateTime date) {
    widget.onDateSelected(date);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ZiroSheetBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with "History" title and Done button
          ZiroSheetHeader(
            title: 'History',
            showDone: true,
            onDone: () => Navigator.of(context).pop(),
          ),
          // Day-of-week header row
          _buildDaysOfWeek(),
          // Scrollable months body
          Expanded(child: _buildMonthsList()),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: _daysOfWeek.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 40),
      itemCount: _months.length,
      itemBuilder: (context, index) {
        final month = _months[index];
        return _MonthView(
          month: month,
          daysInMonth: _daysInMonth(month),
          offset: _monthOffset(month),
          hasWorkout: _hasWorkout,
          isToday: _isToday,
          onDateTap: _onDateTap,
        );
      },
    );
  }
}

/// A single month grid rendered by [WorkoutCalendarSheet]'s [ListView.builder].
///
/// Each month shows a "MMMM yyyy" header in blue followed by a 7-column
/// day grid with Monday-based weekday offset.
class _MonthView extends StatelessWidget {
  final DateTime month;
  final int daysInMonth;
  final int offset;
  final bool Function(DateTime date) hasWorkout;
  final bool Function(DateTime date) isToday;
  final void Function(DateTime date) onDateTap;

  const _MonthView({
    required this.month,
    required this.daysInMonth,
    required this.offset,
    required this.hasWorkout,
    required this.isToday,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month / year header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          // Day grid
          _buildDayGrid(),
        ],
      ),
    );
  }

  /// Builds the 7-column day grid with proper Monday-based offset and
  /// 12px vertical spacing between rows (matching Swift's LazyVGrid spacing).
  Widget _buildDayGrid() {
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: rowIndex < rows - 1
                ? const EdgeInsets.only(bottom: 12)
                : EdgeInsets.zero,
            child: Row(
              children: List.generate(7, (colIndex) {
                final slotIndex = rowIndex * 7 + colIndex;
                final day = slotIndex - offset + 1;

                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }

                final date = DateTime(month.year, month.month, day);
                return Expanded(
                  child: _DayCell(
                    day: day,
                    date: date,
                    hasWorkout: hasWorkout(date),
                    isToday: isToday(date),
                    onTap: () => onDateTap(date),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// A single day cell in the calendar grid.
///
/// Renders with:
/// - **Has workout:** Blue filled circle (15% opacity) + small blue dot below
///   the date number; bold text in [onSurface] color.
/// - **Today (no workout):** Blue stroked circle; bold blue text.
/// - **Other days:** No circle; regular weight text at 70% opacity.
class _DayCell extends StatelessWidget {
  final int day;
  final DateTime date;
  final bool hasWorkout;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.date,
    required this.hasWorkout,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = theme.colorScheme.onSurface;

    final Color textColor;
    final FontWeight fontWeight;

    if (isToday) {
      textColor = Colors.blue;
      fontWeight = FontWeight.bold;
    } else if (hasWorkout) {
      textColor = defaultTextColor;
      fontWeight = FontWeight.bold;
    } else {
      textColor = defaultTextColor.withValues(alpha: 0.7);
      fontWeight = FontWeight.normal;
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Filled blue circle for workout days
            if (hasWorkout)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              )
            // Stroked blue circle for today (without workout)
            else if (isToday)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 1),
                ),
              ),

            // Day number
            Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),

            // Small blue dot below the day number for workout days
            if (hasWorkout)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
