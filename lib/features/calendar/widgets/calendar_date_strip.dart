import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';

/// Horizontal scrollable strip of date pills with client avatar stacks.
/// Auto-scrolls to the selected date on init and change.
/// Mirrors iOS CalendarDateStrip.swift design.
class CalendarDateStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<CalendarEvent> events;

  const CalendarDateStrip({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.onDateSelected,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = _isSameDay(date, selectedDate);
          final dailyEvents = events
              .where((e) => _isSameDay(e.startTime, date))
              .toList();
          return _DateCell(
            date: date,
            isSelected: isSelected,
            events: dailyEvents,
            onTap: () {
              HapticFeedback.lightImpact();
              onDateSelected(date);
            },
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// A single date pill in the strip.
class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  String get _dayName {
    return DateFormat('E').format(date).substring(0, 1).toUpperCase();
  }

  String get _dayNumber => date.day.toString();

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get unique client summaries for this date's events.
  List<_ClientSummary> get _clients {
    final seen = <String>{};
    final clients = <_ClientSummary>[];
    for (final event in events) {
      final id = event.clientId ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        clients.add(_ClientSummary(
          id: id,
          name: event.clientName ?? '',
          avatarUrl: event.clientAvatarUrl,
        ));
      }
    }
    return clients;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clients = _clients;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day name (first letter)
            Text(
              _dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // Day number circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : (_isToday
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : Colors.transparent),
                shape: BoxShape.circle,
                border: _isToday && !isSelected
                    ? Border.all(color: colorScheme.primary, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _dayNumber,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : _isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Avatar stack
            if (clients.isNotEmpty)
              SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    for (var i = 0; i < clients.length.clamp(0, 2); i++)
                      Positioned(
                        left: i * 12.0,
                        top: 0,
                        child: _ClientAvatar(
                          client: clients[i],
                          size: 18,
                        ),
                      ),
                    if (clients.length > 2)
                      Positioned(
                        left: 24.0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+${clients.length - 2}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/// Small client avatar with initials fallback.
class _ClientAvatar extends StatelessWidget {
  final _ClientSummary client;
  final double size;

  const _ClientAvatar({required this.client, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(client.name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColor(client.id, theme),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String id, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      theme.colorScheme.error,
      Colors.orange,
      Colors.purple,
    ];
    final hash = id.hashCode.abs();
    return colors[hash % colors.length];
  }
}

/// Lightweight client summary for the date strip.
class _ClientSummary {
  final String id;
  final String name;
  final String? avatarUrl;

  const _ClientSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}
