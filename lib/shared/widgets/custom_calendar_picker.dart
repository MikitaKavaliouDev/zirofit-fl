import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/shared/widgets/cached_async_image.dart';

// =============================================================================
// CalendarClientSummary
// =============================================================================

/// Lightweight client summary for calendar day indicators.
///
/// Mirrors iOS [ClientSummary] used in [CustomCalendarPicker].
class CalendarClientSummary {
  /// Unique client identifier.
  final String id;

  /// Display name (e.g. "John Doe").
  final String name;

  /// Optional avatar image URL.
  final String? avatarUrl;

  const CalendarClientSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

// =============================================================================
// CustomCalendarPicker
// =============================================================================

/// A full calendar month-picker with date selection and client avatar
/// indicators.
///
/// Mirrors iOS [CustomCalendarPicker.swift].
///
/// Provides a month grid with:
/// - Header row: month/year text centered, chevron navigation on the right
/// - Day-of-week labels (SUN–SAT) in a 7-column row
/// - 6-week × 7-column calendar grid with:
///   - Day number in a circle (blue filled if selected, blue stroke if today,
///     gray/white otherwise)
///   - Below the number: overlapping small circular client avatars (up to 3)
///     with "+N" overflow badge
/// - "Jump to Today" footer button
///
/// {@tool snippet}
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => CustomCalendarPicker(
///     selectedDate: selectedDate,
///     onDateSelected: (date) { ... },
///     clientsByDate: clientsByDate,
///   ),
/// );
/// ```
/// {@end-tool}
class CustomCalendarPicker extends StatefulWidget {
  /// Currently selected date (nullable for initial empty state).
  final DateTime? selectedDate;

  /// Called when a date cell is tapped.
  final ValueChanged<DateTime> onDateSelected;

  /// Optional map of clients grouped by date for avatar indicators.
  ///
  /// Keys should be date-only [DateTime] values (time component ignored).
  final Map<DateTime, List<CalendarClientSummary>>? clientsByDate;

  const CustomCalendarPicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.clientsByDate,
  });

  @override
  State<CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<CustomCalendarPicker> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final seed = widget.selectedDate ?? DateTime.now();
    _currentMonth = DateTime(seed.year, seed.month, 1);
  }

  // -------------------------------------------------------------------------
  // Grid calculation helpers
  // -------------------------------------------------------------------------

  /// Returns exactly 42 [DateTime] values representing 6 full weeks (rows)
  /// starting from the Sunday on or before the 1st of [_currentMonth].
  List<DateTime> _buildDays() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // weekday: Mon=1 … Sun=7  →  daysFromSunday: Mon=1, Sun=0
    final offset = firstOfMonth.weekday % 7;
    final start = firstOfMonth.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  /// Normalize a [DateTime] to a hashable / sortable integer (YYYYMMDD).
  static int _dateKey(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

  /// Whether [a] and [b] represent the same calendar day.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _previousMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      });

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
    });
    widget.onDateSelected(DateTime(now.year, now.month, now.day));
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final today = DateTime.now();
    final selectedDate = widget.selectedDate;
    final days = _buildDays();

    // Build a normalized client lookup map (ignores time-of-day in keys).
    final clientMap = <int, List<CalendarClientSummary>>{};
    if (widget.clientsByDate != null) {
      for (final entry in widget.clientsByDate!.entries) {
        clientMap[_dateKey(entry.key)] = entry.value;
      }
    }

    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);

    return Material(
      color: themeColors.backgroundPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(monthYear, themeColors),
            const SizedBox(height: 16),
            _buildWeekdayHeaders(themeColors),
            const SizedBox(height: 8),
            _buildCalendarGrid(
              days: days,
              selectedDate: selectedDate,
              today: today,
              clientMap: clientMap,
              themeColors: themeColors,
            ),
            const SizedBox(height: 12),
            _buildJumpToToday(themeColors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String monthYear, ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          Text(
            monthYear,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeColors.textPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: themeColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: themeColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(ThemeColors themeColors) {
    const labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: themeColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid({
    required List<DateTime> days,
    required DateTime? selectedDate,
    required DateTime today,
    required Map<int, List<CalendarClientSummary>> clientMap,
    required ThemeColors themeColors,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 64,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        final isSelected =
            selectedDate != null && _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, today);
        final isCurrentMonth =
            date.month == _currentMonth.month &&
            date.year == _currentMonth.year;
        final clients = clientMap[_dateKey(date)] ?? const [];

        return GestureDetector(
          onTap: () => widget.onDateSelected(date),
          child: _DayCell(
            date: date,
            isSelected: isSelected,
            isToday: isToday,
            isCurrentMonth: isCurrentMonth,
            clients: clients,
            themeColors: themeColors,
          ),
        );
      },
    );
  }

  Widget _buildJumpToToday(ThemeColors themeColors) {
    return GestureDetector(
      onTap: _jumpToToday,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Jump to Today',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeColors.accent,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DayCell
// =============================================================================

/// A single day cell in the calendar grid.
///
/// Displays the day number in a styled circle with a client avatar stack below.
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;
  final List<CalendarClientSummary> clients;
  final ThemeColors themeColors;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isCurrentMonth,
    required this.clients,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        // Day number circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? themeColors.accent
                : isToday
                    ? themeColors.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: themeColors.accent, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isCurrentMonth
                      ? themeColors.textPrimary
                      : themeColors.textPrimary.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Avatar stack
        _AvatarStack(clients: clients, themeColors: themeColors),
      ],
    );
  }
}

// =============================================================================
// _AvatarStack
// =============================================================================

/// Overlapping circular client avatars with "+N" overflow badge.
///
/// Shows up to 3 avatars overlapping by 6px each, then a "+N" badge if more.
class _AvatarStack extends StatelessWidget {
  final List<CalendarClientSummary> clients;
  final ThemeColors themeColors;

  const _AvatarStack({
    required this.clients,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox(height: 16);

    const avatarSize = 14.0;
    const overlap = 6.0;
    const stride = avatarSize - overlap; // 8

    final displayCount = clients.length.clamp(0, 3);

    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          for (var i = 0; i < displayCount; i++)
            Positioned(
              left: i * stride,
              top: 1,
              child: _ClientAvatar(
                client: clients[i],
                size: avatarSize,
                themeColors: themeColors,
              ),
            ),
          if (clients.length > 3)
            Positioned(
              left: displayCount * stride,
              top: 1,
              child: _OverflowBadge(
                count: clients.length - 3,
                themeColors: themeColors,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ClientAvatar
// =============================================================================

/// A single circular client avatar.
///
/// Shows the image from [CalendarClientSummary.avatarUrl] via [CachedAsyncImage]
/// when available; otherwise renders a colored initials fallback.
class _ClientAvatar extends StatelessWidget {
  final CalendarClientSummary client;
  final double size;
  final ThemeColors themeColors;

  const _ClientAvatar({
    required this.client,
    required this.size,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = client.avatarUrl != null && client.avatarUrl!.isNotEmpty;

    Widget content;
    if (hasUrl) {
      content = CachedAsyncImage(
        imageUrl: client.avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: _buildInitials(),
      );
    } else {
      content = _buildInitials();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: themeColors.backgroundPrimary,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildInitials() {
    final initials = _extractInitials(client.name);
    final color = _pickAvatarColor(client.id);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
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
}

// =============================================================================
// _OverflowBadge
// =============================================================================

/// Small circular badge showing "+N" when there are more clients than fit.
class _OverflowBadge extends StatelessWidget {
  final int count;
  final ThemeColors themeColors;

  const _OverflowBadge({
    required this.count,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: themeColors.backgroundSecondary,
        shape: BoxShape.circle,
        border: Border.all(
          color: themeColors.backgroundPrimary,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.bold,
          color: themeColors.textPrimary,
        ),
      ),
    );
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

/// Extract initials (up to 2 characters) from a full name.
///
/// Examples:
/// - "John Doe" → "JD"
/// - "Alice" → "A"
/// - "" → "?"
String _extractInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  if (name.isNotEmpty) return name[0].toUpperCase();
  return '?';
}

/// Deterministically pick a colour from a palette based on [id].
Color _pickAvatarColor(String id) {
  const palette = <Color>[
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.purple,
    Colors.cyan,
  ];
  return palette[id.hashCode.abs() % palette.length];
}
