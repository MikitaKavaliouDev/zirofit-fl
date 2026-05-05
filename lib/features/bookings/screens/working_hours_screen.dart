import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/bookings/providers/working_hours_provider.dart';

// ---------------------------------------------------------------------------
// Working Hours Screen
// ---------------------------------------------------------------------------

class WorkingHoursScreen extends ConsumerStatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  ConsumerState<WorkingHoursScreen> createState() =>
      _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<WorkingHoursScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workingHoursProvider.notifier).loadWorkingHours();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workingHoursProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Working Hours'),
      ),
      body: Column(
        children: [
          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Set your weekly availability. Clients can only book sessions during these hours.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Loading
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),

          // Day rows
          if (!state.isLoading)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: state.days.length,
                separatorBuilder: (_, _) => const SizedBox(height: 1),
                itemBuilder: (context, index) {
                  final day = state.days[index];
                  return _DayCard(
                    day: day,
                    index: index,
                    onToggle: () {
                      ref
                          .read(workingHoursProvider.notifier)
                          .toggleDay(index);
                    },
                    onStartTimeChanged: (time) {
                      ref
                          .read(workingHoursProvider.notifier)
                          .updateDayTime(index, startTime: time);
                    },
                    onEndTimeChanged: (time) {
                      ref
                          .read(workingHoursProvider.notifier)
                          .updateDayTime(index, endTime: time);
                    },
                  );
                },
              ),
            ),

          // Messages
          if (state.successMessage != null)
            _MessageBanner(
              message: state.successMessage!,
              type: _MessageType.success,
              onDismiss: () =>
                  ref.read(workingHoursProvider.notifier).clearMessages(),
            ),
          if (state.error != null)
            _MessageBanner(
              message: state.error!,
              type: _MessageType.error,
              onDismiss: () =>
                  ref.read(workingHoursProvider.notifier).clearMessages(),
            ),
        ],
      ),
      // Save button in bottom sheet area
      bottomNavigationBar: _SaveButton(
        isSaving: state.isSaving,
        onSave: () => _saveWorkingHours(ref),
      ),
    );
  }

  Future<void> _saveWorkingHours(WidgetRef ref) async {
    final success =
        await ref.read(workingHoursProvider.notifier).saveWorkingHours();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Working hours saved successfully')),
      );
      Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Day Card
// ---------------------------------------------------------------------------

class _DayCard extends StatelessWidget {
  final DaySchedule day;
  final int index;
  final VoidCallback onToggle;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;

  const _DayCard({
    required this.day,
    required this.index,
    required this.onToggle,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.day,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.isOpen
                            ? '${day.startTime} – ${day.endTime}'
                            : 'Closed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: day.isOpen
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: day.isOpen,
                  onChanged: (_) => onToggle(),
                  activeTrackColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          // Time pickers (visible when open)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Start',
                      time: day.startTime,
                      onChanged: onStartTimeChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimePickerTile(
                      label: 'End',
                      time: day.endTime,
                      onChanged: onEndTimeChanged,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: day.isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time Picker Tile
// ---------------------------------------------------------------------------

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final ValueChanged<String> onChanged;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse "HH:mm" string into TimeOfDay
    final parts = time.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    // Format for display
    final displayFormat = DateFormat('HH:mm'); // 24h format
    final now = DateTime(2024, 1, 1, initialTime.hour, initialTime.minute);
    final displayText = displayFormat.format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (picked != null) {
              final formatted =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              onChanged(formatted);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  displayText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Save Button (bottom bar)
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveButton({
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Banner
// ---------------------------------------------------------------------------

enum _MessageType { success, error }

class _MessageBanner extends StatelessWidget {
  final String message;
  final _MessageType type;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = type == _MessageType.error;

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: isError
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      leading: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onPrimaryContainer,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
