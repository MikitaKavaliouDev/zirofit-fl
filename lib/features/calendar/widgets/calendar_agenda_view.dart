import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/calendar/widgets/session_card.dart';

/// Agenda view showing events grouped by date with sticky section headers.
/// Mirrors iOS agendaView: ScrollView with LazyVStack + pinned section headers.
class CalendarAgendaView extends StatelessWidget {
  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final void Function(CalendarEvent event) onSessionTap;
  final VoidCallback? onStartWorkout;

  const CalendarAgendaView({
    super.key,
    required this.events,
    required this.selectedDate,
    required this.onSessionTap,
    this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter events from selected date forward
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final filteredEvents = events
        .where((event) =>
            event.startTime.isAfter(startOfDay) ||
            _isSameDay(event.startTime, selectedDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group events by date
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in filteredEvents) {
      final dateKey = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(event);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEvents = grouped[date]!;
        final isToday = _isSameDay(date, DateTime.now());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky-like header (works with ListView since each section is sequential)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    _formatDateHeader(date, isToday),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Events for this date
            ...dayEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SessionCard(
                    event: event,
                    onTap: () => onSessionTap(event),
                    onStartWorkout: onStartWorkout,
                  ),
                )),
            // Separator between date groups
            if (index < sortedDates.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date, bool isToday) {
    if (isToday) return 'TODAY';
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (_isSameDay(date, tomorrow)) return 'TOMORROW';

    return DateFormat('EEEE, MMMM d').format(date).toUpperCase();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
