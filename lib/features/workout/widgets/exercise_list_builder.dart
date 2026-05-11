import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

/// Builds the exercise list for the active workout screen, grouping exercises
/// by supersetKey and rendering supersets with visual indicators.
class ExerciseListBuilder extends ConsumerWidget {
  final VoidCallback onAddExercise;

  const ExerciseListBuilder({
    super.key,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final enhancementState = ref.watch(workoutEnhancementProvider);
    final theme = Theme.of(context);

    // Handle empty state
    if (state.logs.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Group exercises by supersetKey
    final Map<String, List<ClientExerciseLog>> groupedExercises =
        _groupExercisesBySupersetKey(state.logs);
    final List<String> supersetKeys =
        groupedExercises.keys.where((key) => key.isNotEmpty).toList();
    final List<ClientExerciseLog> nonSupersetExercises =
        groupedExercises[''] ?? [];

    // Build list items
    final List<Widget> items = [];

    // Add superset groups
    for (final key in supersetKeys) {
      final exercises = groupedExercises[key]!;
      final supersetGroup = _findSupersetGroup(enhancementState, key);
      items.add(
        _buildSupersetGroupContainer(
          context,
          key,
          exercises,
          supersetGroup,
          theme,
          ref,
        ),
      );
    }

    // Add non-superset exercises
    for (final exercise in nonSupersetExercises) {
      items.add(_buildExerciseCard(context, exercise, theme, ref: ref));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  /// Groups exercises by supersetKey. Empty/null keys are grouped under ''.
  Map<String, List<ClientExerciseLog>> _groupExercisesBySupersetKey(
      List<ClientExerciseLog> logs) {
    final Map<String, List<ClientExerciseLog>> grouped = {};
    for (final log in logs) {
      final key = log.supersetKey ?? '';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(log);
    }
    return grouped;
  }

  /// Finds the superset group by key from the enhancement state.
  SupersetGroup? _findSupersetGroup(
      WorkoutEnhancementState state, String key) {
    return state.supersetGroups.firstWhere(
      (group) => group.key == key,
      orElse: () => SupersetGroup(key: key),
    );
  }

  /// Builds a container for a superset group with blue border and link icon.
  Widget _buildSupersetGroupContainer(
      BuildContext context,
      String groupKey,
      List<ClientExerciseLog> exercises,
      SupersetGroup? supersetGroup,
      ThemeData theme,
      WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF2563EB),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header with link icon and label
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.link,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    groupKey.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (supersetGroup != null &&
                    supersetGroup.totalSets > 0)
                  Text(
                    '${supersetGroup.completedSets}/${supersetGroup.totalSets} sets',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Exercises in the group
          Column(
            children: exercises
                .map((exercise) => _buildExerciseCard(
                      context,
                      exercise,
                      theme,
                      ref: ref,
                      isInSuperset: true,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Builds an exercise card, optionally styled for superset grouping.
  Widget _buildExerciseCard(
      BuildContext context,
      ClientExerciseLog exercise,
      ThemeData theme, {
      bool isInSuperset = false,
      required WidgetRef ref,
    }) {
    final state = ref.watch(activeWorkoutProvider);
    final isCompleted = exercise.isCompleted ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isInSuperset ? 0 : 8,
        top: isInSuperset ? 0 : 8,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          title: Text(
            _formatExerciseName(exercise, state.exerciseNames),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${exercise.weight != null ? '${exercise.weight!.toStringAsFixed(1)} kg' : '—'} × '
                '${exercise.reps != null ? '${exercise.reps} reps' : '—'}'
                '${exercise.side != 'BOTH' ? ' (${exercise.side})' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              if (state.isTrainerLed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.clientName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: isCompleted
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : IconButton(
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Complete set',
                  onPressed: () {
                    ref.read(activeWorkoutProvider.notifier).completeSet(
                      exercise.id,
                      exerciseName: exercise.exerciseName,
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Builds the empty state UI matching iOS SafeEmptySessionView.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Start by adding an exercise',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap "Add Exercise" to begin your workout.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats exercise name using exerciseNames map from provider.
  String _formatExerciseName(ClientExerciseLog log, Map<String, String> exerciseNames) {
    return exerciseNames[log.exerciseId] ??
        'Exercise: ${log.exerciseId.substring(0, 8)}…';
  }
}