import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

/// A day-of-week entry for scheduling.
class _DaySchedule {
  final int weekday; // 1=Mon ... 7=Sun
  bool enabled = false;
  TimeOfDay? time;
  String? templateLabel;

  _DaySchedule({required this.weekday});
}

/// Screen for scheduling a routine across the week.
///
/// Displays Monday–Sunday toggles. Each day can be enabled with an optional
/// time picker.  "Save Schedule" calls `PUT /api/client/program/active`
/// via [clientProgramsProvider], and "Skip" navigates back without scheduling.
class RoutineSchedulerScreen extends ConsumerStatefulWidget {
  final WorkoutProgram routine;

  const RoutineSchedulerScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineSchedulerScreen> createState() =>
      _RoutineSchedulerScreenState();
}

class _RoutineSchedulerScreenState
    extends ConsumerState<RoutineSchedulerScreen> {
  late List<_DaySchedule> _days;
  bool _isSaving = false;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) => _DaySchedule(weekday: i + 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Routine'),
      ),
      body: Column(
        children: [
          // Routine info banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.routine.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.routine.description != null &&
                          widget.routine.description!.isNotEmpty)
                        Text(
                          widget.routine.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Select Days',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_days.where((d) => d.enabled).length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Day-of-week list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _DayTile(
                  day: _days[index],
                  label: _weekdayLabels[index],
                  colorScheme: colorScheme,
                  onToggle: (enabled) {
                    setState(() {
                      _days[index].enabled = enabled;
                      if (enabled && _days[index].time == null) {
                        _days[index].time = const TimeOfDay(hour: 7, minute: 0);
                      }
                    });
                  },
                  onTimeTap: () => _pickTime(context, index),
                );
              },
            ),
          ),

          // Bottom actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save Schedule button
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveSchedule,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Save Schedule'),
                  ),
                  const SizedBox(height: 8),
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, int index) async {
    final initial = _days[index].time ?? const TimeOfDay(hour: 7, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _days[index].time = picked;
        if (!_days[index].enabled) {
          _days[index].enabled = true;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(clientProgramsProvider.notifier).setActiveProgram(
            widget.routine.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine scheduled successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Day tile widget
// ---------------------------------------------------------------------------

class _DayTile extends StatelessWidget {
  final _DaySchedule day;
  final String label;
  final ColorScheme colorScheme;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _DayTile({
    required this.day,
    required this.label,
    required this.colorScheme,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Switch(
        value: day.enabled,
        onChanged: onToggle,
      ),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: day.enabled ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: day.enabled && day.time != null
          ? Text(
              day.time!.format(context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            )
          : null,
      trailing: day.enabled
          ? TextButton.icon(
              onPressed: onTimeTap,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(
                day.time?.format(context) ?? 'Set time',
                style: TextStyle(color: colorScheme.primary),
              ),
            )
          : null,
      onTap: () => onToggle(!day.enabled),
    );
  }
}
