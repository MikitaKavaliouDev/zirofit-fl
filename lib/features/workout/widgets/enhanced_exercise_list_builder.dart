import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_library_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_workout_set_row.dart';
import 'package:zirofit_fl/features/workout/widgets/section_header_label.dart';

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

    // --- Section header logic ---
    // Build a muscleGroup lookup from the exercise library.
    // The Exercise.muscleGroup serves as the iOS-aligned sectionLabel.
    final libraryState = ref.watch(exerciseLibraryProvider);
    final Map<String, String?> exerciseSectionLabels = {};
    for (final e in libraryState.allExercises) {
      exerciseSectionLabels[e.id] = e.muscleGroup;
    }

    // Resolve the section label for an exercise log (or the first in a group).
    String? sectionLabelFor(ClientExerciseLog log) =>
        exerciseSectionLabels[log.exerciseId];

    // Build list items with section headers interleaved
    final List<Widget> items = [];
    String? previousSectionLabel;

    void addSectionHeaderIfNeeded(String? currentLabel) {
      if (currentLabel != null && currentLabel != previousSectionLabel) {
        items.add(SectionHeaderLabel(title: currentLabel));
      }
      previousSectionLabel = currentLabel;
    }

    // Add superset groups (section derived from first exercise in superset)
    for (final key in supersetKeys) {
      final exercises = groupedExercises[key]!;
      final currentLabel = sectionLabelFor(exercises.first);
      addSectionHeaderIfNeeded(currentLabel);
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
      final currentLabel = sectionLabelFor(exercise);
      addSectionHeaderIfNeeded(currentLabel);
      items.add(_buildExerciseCard(context, exercise, theme));
    }

    // Add button at bottom
    items.add(const SizedBox(height: 16));
    items.add(_buildAddExerciseButton(theme));
    if (widget.inputState.isActive) {
      items.add(const SizedBox(height: 380)); // Padding to allow scrolling above the virtual keyboard overlay
    } else {
      items.add(const SizedBox(height: 100)); // Padding for floating controls
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

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

  SupersetGroup? _findSupersetGroup(
      WorkoutEnhancementState state, String key) {
    return state.supersetGroups.firstWhere(
      (group) => group.key == key,
      orElse: () => SupersetGroup(key: key),
    );
  }

  Widget _buildSupersetGroupContainer(
    BuildContext context,
    String groupKey,
    List<ClientExerciseLog> exercises,
    SupersetGroup? supersetGroup,
    ThemeData theme,
  ) {
    const accentColor = Color(0xFF3B82F6);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.03),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'SUPERSET ${groupKey.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (supersetGroup != null && supersetGroup.totalSets > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${supersetGroup.completedSets}/${supersetGroup.totalSets}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ClientExerciseLog exercise,
    ThemeData theme, {
    bool isInSuperset = false,
  }) {
    final state = ref.watch(activeWorkoutProvider);
    final exerciseName = state.exerciseNames[exercise.exerciseId] ?? 'Exercise';
    final sets = _parseSets(exercise);

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isInSuperset ? 4 : 10,
        horizontal: isInSuperset ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isInSuperset ? 14 : 20),
        boxShadow: isInSuperset ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isInSuperset ? null : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExerciseHeader(context, exercise, exerciseName, theme),
          _buildSetsTableHeader(theme),
          ...sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            final previousSet = _getPreviousSet(exercise.exerciseId, index);

            return Dismissible(
              key: ValueKey('set-${set.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white),
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
                    widget.inputState.overlay == WorkoutInputOverlay.rpePicker ||
                    widget.inputState.overlay == WorkoutInputOverlay.plateCalculator,
                focusedField: widget.inputState.focusedField,
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
                  ref.read(activeWorkoutProvider.notifier).completeSet(
                    exercise.id,
                    exerciseName: exercise.exerciseName,
                  );
                },
                activeSetId: widget.inputState.activeSetId,
              ),
            );
          }),
          _buildAddSetButton(context, exercise, theme),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                if (exercise.side != 'BOTH')
                  Text(
                    exercise.side,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              PopupMenuItem(
                value: 'superset',
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    const Text('Create Superset'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('Remove Exercise', style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('SET', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Center(child: Text('KG', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          Expanded(child: Center(child: Text('REPS', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Center(child: Text('RPE', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 40),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(activeWorkoutProvider.notifier).addSet(exercise.exerciseId);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'ADD SET',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddExerciseButton(ThemeData theme) {
    return GestureDetector(
      onTap: widget.onAddExercise,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'ADD EXERCISE',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your workout is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Time to put in some work.\nAdd your first exercise to begin.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: widget.onAddExercise,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('ADD FIRST EXERCISE'),
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
        return sets.map((s) {
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