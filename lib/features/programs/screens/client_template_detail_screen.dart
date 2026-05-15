import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

/// Client-facing detail screen for a workout template.
///
/// Shows template info and a list of its steps (exercises + rest periods).
class ClientTemplateDetailScreen extends ConsumerWidget {
  final String templateId;

  const ClientTemplateDetailScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientProgramsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Search both personal and system templates
    final template = state.library?.personalTemplates
            .where((t) => t.id == templateId)
            .firstOrNull ??
        state.library?.systemTemplates
            .where((t) => t.id == templateId)
            .firstOrNull;

    // Loading (no library yet)
    if (state.isLoading && state.library == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Template')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error (no data loaded)
    if (state.error != null && state.library == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Template')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      ref.read(clientProgramsProvider.notifier).fetchLibrary(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Not found
    if (template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Template')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Template not found',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Data — sort exercises by order
    final exercises = List<TemplateExercise>.from(template.exercises)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(clientProgramsProvider.notifier).fetchLibrary(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Template header card ────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: theme.textTheme.titleLarge),
                    if (template.description != null &&
                        template.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        template.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${template.exerciseCount} exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Steps section ──────────────────────────────────────
            if (exercises.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 40,
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No exercises in this template',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...exercises.asMap().entries.map(
                    (entry) => _StepCard(
                      exercise: entry.value,
                      isLast: entry.key == exercises.length - 1,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step card — renders either an exercise or rest step
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  final TemplateExercise exercise;
  final bool isLast;

  const _StepCard({
    required this.exercise,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isRest = exercise.type == StepType.rest;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isRest ? _buildRestStep(theme, colorScheme) : _buildExerciseStep(theme, colorScheme),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseStep(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Superset badge
        if (exercise.supersetGroupId != null) ...[
          Row(
            children: [
              Icon(Icons.link, size: 14, color: colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                exercise.supersetOrder != null
                    ? 'Superset ${exercise.supersetOrder! + 1}'
                    : 'Superset',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Exercise reference
        Text(
          'Exercise',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        if (exercise.exerciseId != null) ...[
          const SizedBox(height: 2),
          Text(
            exercise.exerciseId!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Metrics row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Sets × Reps
            _MetricChip(
              icon: Icons.repeat,
              label: exercise.targetSets != null
                  ? '${exercise.targetSets} × ${exercise.targetReps ?? '?'} reps'
                  : (exercise.targetReps ?? '—'),
            ),

            // Tempo
            if (exercise.tempo != null && exercise.tempo!.isNotEmpty)
              _MetricChip(
                icon: Icons.speed,
                label: exercise.tempo!,
              ),

            // Rest between sets
            if (exercise.targetRest != null)
              _MetricChip(
                icon: Icons.timer_outlined,
                label: _formatDuration(exercise.targetRest!),
              ),
          ],
        ),

        // RPE indicator
        if (exercise.enableRpe) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'RPE enabled',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (exercise.targetRIR != null) ...[
                const SizedBox(width: 12),
                Text(
                  'RIR: ${exercise.targetRIR}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],

        // Notes
        if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestStep(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.timer_outlined,
            color: colorScheme.onTertiaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.durationSeconds != null
                    ? _formatDuration(exercise.durationSeconds!)
                    : '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final remaining = seconds % 60;
      return remaining > 0 ? '${minutes}m ${remaining}s' : '$minutes min';
    }
    return '$seconds sec';
  }
}

// ---------------------------------------------------------------------------
// Metric chip for exercise details
// ---------------------------------------------------------------------------

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
