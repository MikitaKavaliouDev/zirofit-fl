import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';

/// Displays a routine (WorkoutProgram) with its key details and actions.
///
/// Shows routine name, optional description, template count badge,
/// schedule/icon button, edit tap target, and template name chips.
class RoutineCard extends StatelessWidget {
  final WorkoutProgram routine;
  final List<WorkoutTemplate>? templates;
  final VoidCallback? onEdit;
  final VoidCallback? onSchedule;

  const RoutineCard({
    super.key,
    required this.routine,
    this.templates,
    this.onEdit,
    this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateCount = templates?.length ?? 0;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top row: name, badge, schedule icon ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (routine.description != null &&
                            routine.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            routine.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Template count badge
                  _Badge(
                    count: templateCount,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 4),
                  // Schedule button
                  IconButton(
                    onPressed: onSchedule,
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Schedule',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              // --- Template name chips ---
              if (templates != null && templates!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates!.length > 3
                        ? 4 // show 3 chips + "+N" chip
                        : templates!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 3) {
                        final remaining = templates!.length - 3;
                        return Chip(
                          label: Text(
                            '+$remaining',
                            style: const TextStyle(fontSize: 10),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          labelPadding: EdgeInsets.zero,
                        );
                      }
                      return _TemplateChip(
                        label: templates![index].name,
                        colorScheme: colorScheme,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

/// Small circular badge showing a count.
class _Badge extends StatelessWidget {
  final int count;
  final ColorScheme colorScheme;

  const _Badge({required this.count, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small chip displaying a template name.
class _TemplateChip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _TemplateChip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
