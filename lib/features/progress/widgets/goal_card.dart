import 'package:flutter/material.dart';

import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/features/progress/widgets/goal_progress_bar.dart';

/// A card that displays a single [FitnessGoal] with progress, actions, and
/// expandable details.
///
/// Supports swipe-to-delete via [Dismissible].
class GoalCard extends StatefulWidget {
  final FitnessGoal goal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.goal;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text(
              'Are you sure you want to delete this ${_goalTypeLabel(goal.type)} goal?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => widget.onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon + title + actions
                Row(
                  children: [
                    _GoalTypeIcon(type: goal.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _goalTypeLabel(goal.type),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (goal.type == GoalType.pr &&
                              goal.exerciseName != null)
                            Text(
                              goal.exerciseName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onEdit,
                      tooltip: 'Edit goal',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        widget.onDelete?.call();
                      },
                      tooltip: 'Delete goal',
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                GoalProgressBar(progress: goal.progress),

                const SizedBox(height: 8),

                // Value display row
                Row(
                  children: [
                    Text(
                      _valueLabel(goal),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(goal.progress * 100).round()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _progressTextColor(goal.progress, theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Expandable details
                if (_expanded) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Target',
                    value: goal.targetValue.toStringAsFixed(
                      goal.targetValue == goal.targetValue.roundToDouble()
                          ? 0
                          : 1,
                    ),
                  ),
                  _DetailRow(
                    label: 'Current',
                    value: goal.currentValue.toStringAsFixed(
                      goal.currentValue == goal.currentValue.roundToDouble()
                          ? 0
                          : 1,
                    ),
                  ),
                  _DetailRow(
                    label: 'Start',
                    value: _formatDate(goal.startDate),
                  ),
                  if (goal.endDate != null)
                    _DetailRow(
                      label: 'End',
                      value: _formatDate(goal.endDate!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _goalTypeLabel(GoalType type) => switch (type) {
        GoalType.sessions => 'Weekly Workouts',
        GoalType.volume => 'Weekly Volume',
        GoalType.pr => 'Personal Record',
      };

  String _valueLabel(FitnessGoal goal) {
    final current = goal.currentValue.toStringAsFixed(
      goal.currentValue == goal.currentValue.roundToDouble() ? 0 : 1,
    );
    final target = goal.targetValue.toStringAsFixed(
      goal.targetValue == goal.targetValue.roundToDouble() ? 0 : 1,
    );

    return switch (goal.type) {
      GoalType.sessions => '$current/$target sessions',
      GoalType.volume => '$current/$target kg',
      GoalType.pr => goal.currentValue >= 1 ? 'Achieved' : 'Not yet achieved',
    };
  }

  Color _progressTextColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return Colors.green.shade600;
    if (progress >= 0.5) return Colors.amber.shade700;
    return Colors.red.shade400;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _GoalTypeIcon extends StatelessWidget {
  final GoalType type;
  const _GoalTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      GoalType.sessions => (Icons.calendar_month_rounded, Colors.blue.shade400),
      GoalType.volume => (Icons.monitor_weight_rounded, Colors.orange.shade400),
      GoalType.pr => (Icons.emoji_events_rounded, Colors.amber.shade600),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
