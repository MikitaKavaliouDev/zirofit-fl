import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_workout_set_row.dart';

/// Enhanced exercise list builder matching iOS WorkoutSessionContent
///
/// Features:
/// - Inline WorkoutSetRow editing with focus awareness
/// - Exercise cards with focus metric selector
/// - Superset grouping with visual borders
/// - "Add Set" and "Add Exercise" buttons
/// - Empty state matching iOS SafeEmptySessionView
class EnhancedExerciseListBuilder extends ConsumerStatefulWidget {
  final VoidCallback onAddExercise;
  final WorkoutInputState inputState;
  final void Function(SessionFocusField field) onFocus;
  final void Function(double weight) onWeightChanged;
  final void Function(int reps) onRepsChanged;
  final void Function(double rpe) onRpeChanged;

  const EnhancedExerciseListBuilder({
    super.key,
    required this.onAddExercise,
    required this.inputState,
    required this.onFocus,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRpeChanged,
  });

  @override
  ConsumerState<EnhancedExerciseListBuilder> createState() =>
      _EnhancedExerciseListBuilderState();
}

class _EnhancedExerciseListBuilderState
    extends ConsumerState<EnhancedExerciseListBuilder> {
  @override
  Widget build(BuildContext context) {
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
        ),
      );
    }

    // Add non-superset exercises
    for (final exercise in nonSupersetExercises) {
      items.add(_buildExerciseCard(context, exercise, theme));
    }

    // Add button at bottom
    items.add(_buildAddExerciseButton(theme));

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
  ) {
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
          // Group header
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
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (supersetGroup != null && supersetGroup.totalSets > 0)
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
                      isInSuperset: true,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Builds an exercise card matching iOS WorkoutExerciseCard
  Widget _buildExerciseCard(
    BuildContext context,
    ClientExerciseLog exercise,
    ThemeData theme, {
    bool isInSuperset = false,
  }) {
    final state = ref.watch(activeWorkoutProvider);
    final exerciseName = state.exerciseNames[exercise.exerciseId] ?? 'Exercise';

    // Get sets from the exercise (stored in sets field)
    final sets = _parseSets(exercise);

    return Container(
      margin: EdgeInsets.only(
        bottom: isInSuperset ? 0 : 8,
        top: isInSuperset ? 0 : 8,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            _buildExerciseHeader(context, exercise, exerciseName, theme),

            // Table header
            _buildSetsTableHeader(theme),

            // Sets list
            ...sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              final previousSet = _getPreviousSet(exercise.exerciseId, index);

              return Dismissible(
                key: ValueKey('set-${set.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  ref.read(activeWorkoutProvider.notifier).deleteSet(set.id);
                },
                child: EnhancedWorkoutSetRow(
                  set: set,
                  index: index,
                  previousSet: previousSet,
                  isActive: widget.inputState.overlay == WorkoutInputOverlay.keyboard ||
                      widget.inputState.overlay == WorkoutInputOverlay.rpePicker,
                  activeText: widget.inputState.activeSetId == set.id
                      ? widget.inputState.activeText
                      : '',
                  isInputSelected: widget.inputState.isInputSelected,
                  onFocus: widget.onFocus,
                  onWeightChanged: (weight) {
                    widget.onWeightChanged(weight ?? 0);
                  },
                  onRepsChanged: (reps) {
                    widget.onRepsChanged(reps ?? 0);
                  },
                  onRpeChanged: (rpe) {
                    widget.onRpeChanged(rpe ?? 0);
                  },
                  onStatusChanged: (status) {
                    ref.read(activeWorkoutProvider.notifier).updateSetStatus(set.id, status);
                  },
                  onDelete: () {
                    ref.read(activeWorkoutProvider.notifier).deleteSet(set.id);
                  },
                  onComplete: () {
                    HapticFeedback.mediumImpact();
                    ref.read(activeWorkoutProvider.notifier).completeSet(exercise.id);
                  },
                ),
              );
            }),

            // Add Set button
            _buildAddSetButton(context, exercise, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseHeader(
    BuildContext context,
    ClientExerciseLog exercise,
    String exerciseName,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (exercise.side != null && exercise.side != 'BOTH')
                  Text(
                    exercise.side!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Menu button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  ref.read(activeWorkoutProvider.notifier).removeExercise(exercise.exerciseId);
                  break;
                case 'superset':
                  ref.read(workoutEnhancementProvider.notifier).createSuperset([exercise.exerciseId]);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'superset',
                child: Row(
                  children: [
                    Icon(Icons.link, size: 20),
                    SizedBox(width: 8),
                    Text('Create Superset'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetsTableHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('SET', style: theme.textTheme.labelSmall)),
          Expanded(child: Center(child: Text('KG', style: theme.textTheme.labelSmall))),
          const SizedBox(width: 8),
          Expanded(child: Center(child: Text('REPS', style: theme.textTheme.labelSmall))),
          const SizedBox(width: 8),
          SizedBox(width: 50, child: Center(child: Text('RPE', style: theme.textTheme.labelSmall))),
          const SizedBox(width: 8),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildAddSetButton(
    BuildContext context,
    ClientExerciseLog exercise,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          ref.read(activeWorkoutProvider.notifier).addSet(exercise.exerciseId);
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Set'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAddExerciseButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: OutlinedButton.icon(
        onPressed: widget.onAddExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state UI matching iOS SafeEmptySessionView
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
                onPressed: widget.onAddExercise,
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

  /// Parse workout sets from ClientExerciseLog
  List<WorkoutSet> _parseSets(ClientExerciseLog log) {
    // The sets are stored in the log - need to convert
    // For now, create a set from the log data if no sets exist
    final sets = log.sets;
    if (sets != null && sets.isNotEmpty) {
      try {
        return (sets as List).map((s) {
          if (s is WorkoutSet) return s;
          if (s is Map) return WorkoutSet.fromJson(Map<String, dynamic>.from(s));
          return null;
        }).whereType<WorkoutSet>().toList();
      } catch (_) {
        // Fall through to create from log
      }
    }

    // Create a set from the log data
    return [
      WorkoutSet(
        id: '${log.id}-set-1',
        logId: log.id,
        reps: log.reps,
        weight: log.weight,
        rpe: log.rpe,
        isCompleted: log.isCompleted ?? false,
      ),
    ];
  }

  /// Get previous set data for comparison (mock for now)
  WorkoutSet? _getPreviousSet(String exerciseId, int setIndex) {
    // TODO: Fetch from exercise stats provider
    return null;
  }
}