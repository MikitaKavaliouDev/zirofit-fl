import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/calendar/widgets/session_card.dart';

/// Day view with PageView for swipe navigation between days.
/// Mirrors iOS dayTabView: TabView with .tabViewStyle(.page).
/// Includes haptic feedback on swipe.
class CalendarDayView extends StatefulWidget {
  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final void Function(CalendarEvent event) onSessionTap;
  final VoidCallback? onStartWorkout;

  const CalendarDayView({
    super.key,
    required this.events,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onSessionTap,
    this.onStartWorkout,
  });

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  late PageController _pageController;
  late int _currentPage;

  /// Generate ~1000 virtual pages centered around today.
  /// Page 500 corresponds to today's date.
  static DateTime _dateForPage(int page) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: page - 500));
  }

  static int _pageForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return 500 + target.difference(today).inDays;
  }

  @override
  void initState() {
    super.initState();
    _currentPage = _pageForDate(widget.selectedDate);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(CalendarDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final newPage = _pageForDate(widget.selectedDate);
      if (newPage != _currentPage) {
        _currentPage = newPage;
        _pageController.animateToPage(
          newPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    final date = _dateForPage(page);
    if (!_isSameDay(date, widget.selectedDate)) {
      HapticFeedback.lightImpact();
      widget.onDateChanged(date);
    }
    _currentPage = page;
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: 1000,
      itemBuilder: (context, page) {
        final date = _dateForPage(page);
        final dayEvents = widget.events
            .where((e) =>
                e.startTime.year == date.year &&
                e.startTime.month == date.month &&
                e.startTime.day == date.day)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return _DayPage(
          date: date,
          events: dayEvents,
          onSessionTap: widget.onSessionTap,
          onStartWorkout: widget.onStartWorkout,
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// A single day page showing events for that date.
class _DayPage extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event) onSessionTap;
  final VoidCallback? onStartWorkout;

  const _DayPage({
    required this.date,
    required this.events,
    required this.onSessionTap,
    this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions on ${DateFormat('MMM d').format(date)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SessionCard(
            event: event,
            onTap: () => onSessionTap(event),
            onStartWorkout: onStartWorkout != null
                ? onStartWorkout
                : null,
          ),
        );
      },
    );
  }
}
