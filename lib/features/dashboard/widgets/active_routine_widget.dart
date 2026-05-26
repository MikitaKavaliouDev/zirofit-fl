import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zirofit_fl/data/models/enums/template_step_status.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

/// Dashboard card showing the client's current routine progress.
///
/// Mirrors iOS [ActiveRoutineWidget]:
/// - Routine / template name
/// - Progress bar (completed / total exercises)
/// - Next exercise or template name
/// - Start / Continue Workout button
///
/// Watches [clientProgramsProvider] for active program data and
/// [activeWorkoutProvider] to determine if a session is in progress.
class ActiveRoutineWidget extends ConsumerWidget {
  const ActiveRoutineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsState = ref.watch(clientProgramsProvider);
    final activeState = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    // -------------------------------------------------------------------------
    // Loading state: shimmer skeleton
    // -------------------------------------------------------------------------
    if (programsState.isLoading && programsState.activeProgramResponse == null) {
      return _buildSkeleton(theme);
    }

    // -------------------------------------------------------------------------
    // Empty state: no active routine → render nothing
    // -------------------------------------------------------------------------
    final activeResponse = programsState.activeProgramResponse;
    if (activeResponse == null) {
      return const SizedBox.shrink();
    }

    // -------------------------------------------------------------------------
    // Data state
    // -------------------------------------------------------------------------
    final program = activeResponse.program;
    final progress = activeResponse.progress;
    final templates = activeResponse.templates;

    // Find the "next" template — prefers TemplateStepStatus.next, falls back
    // to the first pending template.
    final nextTemplate = templates.where(
      (t) => t.status == TemplateStepStatus.next,
    ).firstOrNull ?? templates.where(
      (t) => t.status == TemplateStepStatus.pending,
    ).firstOrNull;

    final hasActiveSession = activeState.hasActiveSession;
    final completedCount = progress.completedCount;
    final totalCount = progress.totalCount;
    final progressValue = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/client/workout'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: icon + label
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE ROUTINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          program.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Active-pill indicator
                  if (hasActiveSession)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress count text
              Text(
                '$completedCount of $totalCount exercises completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),

              // Linear progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Next exercise / template
              if (nextTemplate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Up next: ${nextTemplate.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Start / Continue button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/client/workout'),
                  icon: Icon(
                    hasActiveSession ? Icons.play_circle_fill : Icons.play_arrow,
                  ),
                  label: Text(
                    hasActiveSession ? 'Continue Workout' : 'Start Workout',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer skeleton for loading state
  // ---------------------------------------------------------------------------

  Widget _buildSkeleton(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row skeleton
              Row(
                children: [
                  // Icon placeholder
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 140,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress text skeleton
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Progress bar skeleton
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Next item skeleton
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Button skeleton
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
