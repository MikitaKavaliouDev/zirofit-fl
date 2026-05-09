import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/services/apple_calendar_service.dart';
import 'package:zirofit_fl/features/bookings/providers/client_booking_provider.dart';

// ---------------------------------------------------------------------------
// Client Booking Screen
// ---------------------------------------------------------------------------

class ClientBookingScreen extends ConsumerStatefulWidget {
  final String trainerId;

  const ClientBookingScreen({super.key, required this.trainerId});

  @override
  ConsumerState<ClientBookingScreen> createState() =>
      _ClientBookingScreenState();
}

class _ClientBookingScreenState extends ConsumerState<ClientBookingScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  TimeSlot? _selectedSlot;
  final _notesController = TextEditingController();
  bool _addToCalendar = false;
  final _datesWithAvailability = <DateTime>{};

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.microtask(() async {
      _selectDate(DateTime.now());
      // Restore calendar sync toggle preference
      final service = ref.read(appleCalendarServiceProvider);
      final enabled = await service.isSyncEnabled();
      if (enabled) {
        setState(() => _addToCalendar = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Apple Calendar integration
  // ---------------------------------------------------------------------------

  /// Creates a calendar event for the booking and returns a user-facing
  /// confirmation message, or `null` if the calendar operation is skipped.
  Future<String?> _addToAppleCalendar(
    AppleCalendarService service,
    String bookingId,
    TimeSlot slot,
    DateTime date,
    String notes,
    ThemeData theme,
  ) async {
    // 1. Request permission (idempotent if already granted)
    final hasPermission = await service.requestPermission();
    if (!hasPermission) {
      return 'Booking confirmed! Calendar permission was denied.';
    }

    // 2. Create the event
    final trainer = ref.read(clientBookingProvider).trainerInfo;
    final title = trainer != null
        ? 'Training with ${trainer.name}'
        : 'Fitness Session';

    final created = await service.createEvent(
      title: title,
      start: slot.start,
      end: slot.end,
      notes: notes.isNotEmpty ? notes : null,
      location: null,
    );

    if (created == null) {
      return 'Booking confirmed! Could not add to calendar.';
    }

    // 3. Store the mapping so we can update / delete later
    await service.storeEventMapping(
      bookingId: bookingId,
      eventId: created.eventId,
      calendarId: created.calendarId,
    );

    return 'Booking confirmed! Added to your calendar.';
  }

  // ---------------------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------------------

  Future<void> _selectDate(DateTime date) async {
    setState(() => _selectedSlot = null);
    await ref.read(clientBookingProvider.notifier).selectDate(date);

    final state = ref.read(clientBookingProvider);
    if (state.availableSlots.isNotEmpty &&
        !state.isLoading &&
        state.error == null) {
      _datesWithAvailability
          .add(DateTime(date.year, date.month, date.day));
    }
  }

  Future<String?> _submitBooking() async {
    if (_selectedSlot == null) return null;
    final trainerId = ref.read(clientBookingProvider).trainerInfo?.id;
    if (trainerId == null) return null;

    return ref
        .read(clientBookingProvider.notifier)
        .requestBooking(trainerId, _selectedSlot!);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientBookingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Session')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trainer header
                  _TrainerHeader(trainer: state.trainerInfo),
                  const SizedBox(height: 24),

                  // Calendar section
                  Text(
                    'Select Date',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _MonthCalendar(
                    currentMonth: _currentMonth,
                    selectedDate: state.selectedDate,
                    datesWithAvailability: _datesWithAvailability,
                    onMonthChanged: (m) =>
                        setState(() => _currentMonth = m),
                    onDateSelected: _selectDate,
                  ),
                  const SizedBox(height: 24),

                  // Slots section
                  if (state.selectedDate != null) ...[
                    Text(
                      DateFormat('MMMM d, yyyy').format(state.selectedDate!),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSlotsSection(state, theme),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedSlot != null && state.selectedDate != null)
            _buildConfirmBar(state, theme),
        ],
      ),
    );
  }

  Widget _buildSlotsSection(ClientBookingState state, ThemeData theme) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return _ErrorDisplay(
        message: state.error!,
        onRetry: () {
          if (state.selectedDate != null) {
            _selectDate(state.selectedDate!);
          }
        },
      );
    }

    if (state.availableSlots.isEmpty) {
      return _EmptySlots(theme: theme);
    }

    return _TimeSlotGrid(
      slots: state.availableSlots,
      selectedSlot: _selectedSlot,
      onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
    );
  }

  Widget _buildConfirmBar(ClientBookingState state, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state.pendingBooking
                ? null
                : () => _showConfirmSheet(state),
            icon: state.pendingBooking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.calendar_month),
            label: Text(
              state.pendingBooking
                  ? 'Booking...'
                  : 'Confirm Booking',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm bottom sheet
  // ---------------------------------------------------------------------------

  void _showConfirmSheet(ClientBookingState state) {
    final theme = Theme.of(context);
    final date = state.selectedDate!;
    final slot = _selectedSlot!;
    final timeFormat = DateFormat('HH:mm');
    final duration = slot.end.difference(slot.start).inMinutes;
    final notesController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var addToCalendar = _addToCalendar;
        var isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Confirm Booking',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Date row
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormat('EEEE, MMMM d, yyyy').format(date),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),

                  // Time row
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value:
                        '${timeFormat.format(slot.start)} – ${timeFormat.format(slot.end)}',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),

                  // Duration row
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '$duration min',
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // Notes field
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add a note for your trainer...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),

                  // Apple Calendar toggle (iOS only)
                  if (Platform.isIOS)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add to Apple Calendar'),
                      subtitle: const Text('Sync this session to your calendar'),
                      value: addToCalendar,
                      onChanged: (v) =>
                          setSheetState(() => addToCalendar = v),
                    ),

                  const SizedBox(height: 8),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);

                              // 1. Submit the booking to the server
                              final bookingId = await _submitBooking();
                              if (!context.mounted) return;
                              Navigator.of(sheetContext).pop();

                              if (bookingId != null) {
                                setState(() {
                                  _selectedSlot = null;
                                  _notesController.clear();
                                  _addToCalendar = addToCalendar;
                                });

                                // 2. Persist the toggle preference
                                final calendarService =
                                    ref.read(appleCalendarServiceProvider);
                                await calendarService
                                    .setSyncEnabled(addToCalendar);

                                // 3. Optionally create a calendar event
                                String? calendarMessage;
                                if (addToCalendar && Platform.isIOS) {
                                  calendarMessage = await _addToAppleCalendar(
                                    calendarService,
                                    bookingId,
                                    slot,
                                    date,
                                    notesController.text,
                                    theme,
                                  );
                                }

                                // 4. Show confirmation
                                final message = calendarMessage ??
                                    'Booking confirmed! ID: $bookingId';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } else {
                                final errorState =
                                    ref.read(clientBookingProvider).error;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorState ??
                                          'Failed to confirm booking. Please try again.',
                                    ),
                                    backgroundColor:
                                        theme.colorScheme.error,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm Booking'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trainer header
// ---------------------------------------------------------------------------

class _TrainerHeader extends StatelessWidget {
  final Trainer? trainer;

  const _TrainerHeader({this.trainer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trainer == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundImage: trainer!.avatarUrl != null && trainer!.avatarUrl!.isNotEmpty
                  ? NetworkImage(trainer!.avatarUrl!)
                  : null,
              child: trainer!.avatarUrl == null || trainer!.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            // Name, specialty, rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer!.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (trainer!.specialty != null &&
                      trainer!.specialty!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      trainer!.specialty!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (trainer!.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 16, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(
                          trainer!.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month calendar
// ---------------------------------------------------------------------------

class _MonthCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final Set<DateTime> datesWithAvailability;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthCalendar({
    required this.currentMonth,
    this.selectedDate,
    required this.datesWithAvailability,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month navigation
        _MonthNavigation(
          currentMonth: currentMonth,
          onPrevious: () {
            final prev = DateTime(currentMonth.year, currentMonth.month - 1);
            onMonthChanged(prev);
          },
          onNext: () {
            final next = DateTime(currentMonth.year, currentMonth.month + 1);
            onMonthChanged(next);
          },
        ),
        const SizedBox(height: 12),
        // Day-of-week headers
        _DayHeaders(),
        const SizedBox(height: 4),
        // Day grid
        _DayGrid(
          currentMonth: currentMonth,
          selectedDate: selectedDate,
          datesWithAvailability: datesWithAvailability,
          onDateSelected: onDateSelected,
        ),
      ],
    );
  }
}

class _MonthNavigation extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigation({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat('MMMM yyyy').format(currentMonth),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DayHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 36,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final Set<DateTime> datesWithAvailability;
  final ValueChanged<DateTime> onDateSelected;

  const _DayGrid({
    required this.currentMonth,
    this.selectedDate,
    required this.datesWithAvailability,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    // Monday = 1, Sunday = 7
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final totalCells = ((startWeekday - 1) + daysInMonth + 6) ~/ 7 * 7;

    final cells = <Widget>[];
    for (int i = 0; i < totalCells; i++) {
      final day = i - (startWeekday - 1) + 1;
      if (day < 1 || day > daysInMonth) {
        cells.add(const SizedBox(width: 36, height: 42));
      } else {
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final isSelected = selectedDate != null &&
            selectedDate!.year == date.year &&
            selectedDate!.month == date.month &&
            selectedDate!.day == date.day;
        final isToday = date == today;
        final hasAvailability =
            date.isAfter(today) || date == today
                ? datesWithAvailability.contains(date)
                : false;

        cells.add(_DayCell(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          hasAvailability: hasAvailability,
          isPast: date.isBefore(today),
          onTap: date.isBefore(today) ? null : () => onDateSelected(date),
        ));
      }
    }

    return Column(
      children: [
        for (int row = 0; row < totalCells ~/ 7; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: cells.sublist(row * 7, (row + 1) * 7),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasAvailability;
  final bool isPast;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasAvailability,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;
    FontWeight fontWeight;

    if (isSelected) {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      fontWeight = FontWeight.bold;
    } else if (isToday) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      bgColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      fontWeight = FontWeight.normal;
    } else {
      bgColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface;
      fontWeight = FontWeight.normal;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
            if (hasAvailability && !isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            if (isToday && !isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time slot grid
// ---------------------------------------------------------------------------

class _TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;

  const _TimeSlotGrid({
    required this.slots,
    this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    // Generate time slots from 6:00 to 21:00 in 30-min increments
    final generated = <TimeSlot>[];
    final dayStart = slots.isNotEmpty
        ? DateTime(
            slots.first.start.year,
            slots.first.start.month,
            slots.first.start.day,
          )
        : DateTime.now();

    for (int hour = 6; hour < 21; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final start = dayStart.add(Duration(hours: hour, minutes: minute));
        final end = start.add(const Duration(minutes: 30));
        generated.add(TimeSlot(start: start, end: end));
      }
    }

    // Classify each generated slot
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: generated.map((slot) {
        final isAvailable = slots.any((s) =>
            s.start == slot.start && s.end == slot.end);
        final isSelected = selectedSlot != null &&
            selectedSlot!.start == slot.start &&
            selectedSlot!.end == slot.end;

        if (!isAvailable) {
          // Booked (grayed out)
          return _SlotChip(
            label: timeFormat.format(slot.start),
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            textColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.3),
            onTap: null,
          );
        }

        if (isSelected) {
          // Selected (highlighted)
          return _SlotChip(
            label: timeFormat.format(slot.start),
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
            onTap: () => onSlotSelected(slot),
          );
        }

        // Available
        return _SlotChip(
          label: timeFormat.format(slot.start),
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          textColor: theme.colorScheme.primary,
          onTap: () => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: textColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty slots
// ---------------------------------------------------------------------------

class _EmptySlots extends StatelessWidget {
  final ThemeData theme;

  const _EmptySlots({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No available slots',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting a different date',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error display
// ---------------------------------------------------------------------------

class _ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorDisplay({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load slots',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row helper (used in confirm sheet)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
