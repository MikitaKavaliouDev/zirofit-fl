import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/calendar/screens/create_session_screen.dart';
import 'package:zirofit_fl/features/calendar/widgets/calendar_day_cell.dart';
import 'package:zirofit_fl/features/calendar/widgets/session_card.dart';
import 'package:zirofit_fl/features/calendar/widgets/calendar_date_strip.dart';
import 'package:zirofit_fl/features/calendar/widgets/calendar_day_view.dart';
import 'package:zirofit_fl/features/calendar/widgets/calendar_agenda_view.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';

/// Calendar screen with month grid, day view (swipeable), and agenda view.
/// Mirrors iOS CalendarView.swift with 3-mode switching.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  void _loadEvents() {
    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // Extend range so date strip / day / agenda have enough data
    final extendedStart = startOfMonth.subtract(const Duration(days: 31));
    final extendedEnd = endOfMonth.add(const Duration(days: 31));
    ref.read(calendarProvider.notifier).fetchEvents(extendedStart, extendedEnd);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadEvents();
  }

  void _selectDate(DateTime date) {
    ref.read(calendarProvider.notifier).setSelectedDate(date);
  }

  void _onDateStripChanged(DateTime date) {
    _selectDate(date);
  }

  void _onDayViewDateChanged(DateTime date) {
    _selectDate(date);
  }

  void _navigateToCreateSession() {
    final selectedDate = ref.read(calendarProvider).selectedDate;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateSessionScreen(
          initialDate: selectedDate,
        ),
      ),
    );
  }

  void _showSessionDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SessionDetailsSheet(event: event),
    );
  }

  IconData _iconForMode(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return Icons.calendar_month;
      case CalendarViewMode.day:
        return Icons.view_day;
      case CalendarViewMode.agenda:
        return Icons.list_alt;
    }
  }

  String _appBarTitle(CalendarViewMode mode, CalendarState state) {
    switch (mode) {
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(_currentMonth);
      case CalendarViewMode.day:
        return DateFormat('EEEE, MMM d').format(state.selectedDate);
      case CalendarViewMode.agenda:
        return DateFormat('MMMM yyyy').format(state.selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarState = ref.watch(calendarProvider);
    final viewMode = calendarState.viewMode;
    final selectedDate = calendarState.selectedDate;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _appBarTitle(viewMode, calendarState),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (viewMode == CalendarViewMode.month) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              tooltip: 'Previous month',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
              tooltip: 'Next month',
            ),
          ],
          // Filter icon placeholder (will be implemented separately)
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
            tooltip: 'Filters',
          ),
          // Mode switching popup menu
          PopupMenuButton<CalendarViewMode>(
            icon: Icon(_iconForMode(viewMode)),
            tooltip: 'View mode',
            onSelected: (mode) {
              ref.read(calendarProvider.notifier).setViewMode(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarViewMode.month,
                child: ListTile(
                  leading: Icon(_iconForMode(CalendarViewMode.month)),
                  title: const Text('Month'),
                  trailing: viewMode == CalendarViewMode.month
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: CalendarViewMode.day,
                child: ListTile(
                  leading: Icon(_iconForMode(CalendarViewMode.day)),
                  title: const Text('Day'),
                  trailing: viewMode == CalendarViewMode.day
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: CalendarViewMode.agenda,
                child: ListTile(
                  leading: Icon(_iconForMode(CalendarViewMode.agenda)),
                  title: const Text('Agenda'),
                  trailing: viewMode == CalendarViewMode.agenda
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // CalendarDateStrip shown in Day + Agenda modes
          AnimatedCrossFade(
            firstChild: CalendarDateStrip(
              days: calendarState.daysAroundSelected,
              selectedDate: selectedDate,
              onDateSelected: _onDateStripChanged,
              events: calendarState.events,
            ),
            secondChild: const SizedBox(height: 100),
            crossFadeState: viewMode == CalendarViewMode.month
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const Divider(height: 1),
          // Content area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildContentForKey(viewMode, calendarState, theme),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateSession,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }

  /// Returns a widget with a [Key] based on [viewMode] so AnimatedSwitcher
  /// correctly transitions between different view modes.
  Widget _buildContentForKey(
    CalendarViewMode viewMode,
    CalendarState calendarState,
    ThemeData theme,
  ) {
    switch (viewMode) {
      case CalendarViewMode.month:
        return _buildMonthContent(theme, calendarState);
      case CalendarViewMode.day:
        return CalendarDayView(
          key: const ValueKey('day_view'),
          events: calendarState.events,
          selectedDate: calendarState.selectedDate,
          onDateChanged: _onDayViewDateChanged,
          onSessionTap: _showSessionDetails,
          onStartWorkout: () {
            ref.read(sessionOverlayProvider.notifier).showFull();
            ref.read(activeWorkoutProvider.notifier).startWorkout();
          },
        );
      case CalendarViewMode.agenda:
        return CalendarAgendaView(
          key: const ValueKey('agenda_view'),
          events: calendarState.events,
          selectedDate: calendarState.selectedDate,
          onSessionTap: _showSessionDetails,
          onStartWorkout: () {
            ref.read(sessionOverlayProvider.notifier).showFull();
            ref.read(activeWorkoutProvider.notifier).startWorkout();
          },
        );
    }
  }

  Widget _buildMonthContent(ThemeData theme, CalendarState calendarState) {
    if (calendarState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (calendarState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load sessions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              calendarState.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Month calendar grid
        _buildCalendarGrid(theme, calendarState),
        const Divider(height: 1),
        // Selected day's sessions
        Expanded(
          child: _buildDaySessions(theme, calendarState),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, CalendarState calendarState) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final selectedDate = calendarState.selectedDate;

    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          SizedBox(
            height: 240, // Fixed height for 6 weeks
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 42, // 6 weeks
              itemBuilder: (context, index) {
                final dayOffset = index - firstWeekday;
                final day = dayOffset + 1;

                if (dayOffset < 0 || day > daysInMonth) {
                  return const SizedBox();
                }

                final date =
                    DateTime(_currentMonth.year, _currentMonth.month, day);
                final eventsForDay = calendarState.getEventsForDate(date);
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, DateTime.now());

                return CalendarDayCell(
                  day: day,
                  events: eventsForDay,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () => _selectDate(date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySessions(ThemeData theme, CalendarState calendarState) {
    final selectedDate = calendarState.selectedDate;

    if (calendarState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (calendarState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load sessions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              calendarState.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final selectedDateEvents = calendarState.getEventsForDate(selectedDate);

    if (selectedDateEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions on ${DateFormat('MMM d').format(selectedDate)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _navigateToCreateSession,
              icon: const Icon(Icons.add),
              label: const Text('Create session'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedDateEvents.length,
      itemBuilder: (context, index) {
        final event = selectedDateEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SessionCard(
            event: event,
            onTap: () => _showSessionDetails(event),
            onStartWorkout: () {
              ref.read(sessionOverlayProvider.notifier).showFull();
              ref.read(activeWorkoutProvider.notifier).startWorkout();
            },
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Bottom sheet showing session details with actions.
class _SessionDetailsSheet extends ConsumerWidget {
  final CalendarEvent event;

  const _SessionDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value:
                '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
          ),
          if (event.clientName != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person,
              label: 'Client',
              value: event.clientName!,
            ),
          ],
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes,
              label: 'Notes',
              value: event.notes!,
            ),
          ],
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.label,
            label: 'Type',
            value: event.type == 'booking' ? 'Booking' : 'Workout Session',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await ref
                        .read(calendarProvider.notifier)
                        .sendReminder(event.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Reminder sent successfully'
                                : 'Failed to send reminder',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Send Reminder'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Session'),
                        content: const Text(
                          'Are you sure you want to delete this session?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final success = await ref
                          .read(calendarProvider.notifier)
                          .deleteSession(event.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Session deleted'
                                  : 'Failed to delete session',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
