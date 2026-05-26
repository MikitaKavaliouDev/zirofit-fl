import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_library_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_stats_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_workout_set_row.dart';
import 'package:zirofit_fl/features/workout/widgets/coach_notes_card.dart';
import 'package:zirofit_fl/features/workout/widgets/section_header_label.dart';
import 'package:zirofit_fl/features/workout/widgets/youtube_sheet_view.dart';

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
  final Set<String> _collapsedExerciseIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-load exercise stats for previous set comparison display.
    // Stats are cached by the provider — subsequent calls are no-ops.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseStatsProvider.notifier).fetchExerciseStats();
    });
  }

  void _toggleCollapse(String exerciseId) {
    setState(() {
      if (_collapsedExerciseIds.contains(exerciseId)) {
        _collapsedExerciseIds.remove(exerciseId);
      } else {
        _collapsedExerciseIds.add(exerciseId);
      }
    });
  }

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
          sectionLabel: currentLabel,
        ),
      );
    }

    // Add non-superset exercises
    for (final exercise in nonSupersetExercises) {
      final currentLabel = sectionLabelFor(exercise);
      addSectionHeaderIfNeeded(currentLabel);
      items.add(_buildExerciseCard(context, exercise, theme, sectionLabel: currentLabel));
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
    ThemeData theme, {
    String? sectionLabel,
  }) {
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
                const Icon(
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
                      sectionLabel: sectionLabel,
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
    String? sectionLabel,
  }) {
    final state = ref.watch(activeWorkoutProvider);
    final exerciseName = state.exerciseNames[exercise.exerciseId] ?? 'Exercise';
    final sets = _parseSets(exercise);
    final statsState = ref.watch(exerciseStatsProvider);

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
          _buildExerciseHeader(context, exercise, exerciseName, theme, sectionLabel: sectionLabel),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _collapsedExerciseIds.contains(exercise.exerciseId)
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      _buildSetsTableHeader(theme),
                      ...sets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final set = entry.value;
                        final previousSet = _getPreviousSet(exercise.exerciseId, index, statsState);

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
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(
    BuildContext context,
    ClientExerciseLog exercise,
    String exerciseName,
    ThemeData theme, {
    String? sectionLabel,
  }) {
    final isCollapsed = _collapsedExerciseIds.contains(exercise.exerciseId);
    final state = ref.watch(activeWorkoutProvider);
    final sets = _parseSets(exercise);
    final currentMetric = sets.isNotEmpty ? sets.first.focusMetric : FocusMetric.none;

    return GestureDetector(
      onTap: () => _toggleCollapse(exercise.exerciseId),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
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
                  if (sectionLabel != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sectionLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Coach notes button - per-exercise notes (matching iOS)
            if (exercise.notes != null && exercise.notes!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: Colors.orange,
                ),
                tooltip: 'Coach notes',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: CoachNotesCard(
                        note: exercise.notes!,
                        videoUrl: exercise.videoUrl,
                        trainerName: state.clientName ?? 'Coach',
                        onWatchVideo: exercise.videoUrl != null
                            ? () {
                                Navigator.of(context).pop();
                                YouTubeSheetView.show(context, exercise.videoUrl!);
                              }
                            : null,
                      ),
                    ),
                  );
                },
              ),
            PopupMenuButton<FocusMetric>(
              tooltip: 'Focus metric',
              onSelected: (metric) {
                ref.read(activeWorkoutProvider.notifier).updateFocusMetric(
                  exercise.id,
                  metric,
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: FocusMetric.none,
                  child: _buildFocusMenuItem('None', FocusMetric.none, currentMetric),
                ),
                PopupMenuItem(
                  value: FocusMetric.volume,
                  child: _buildFocusMenuItem('Volume', FocusMetric.volume, currentMetric),
                ),
                PopupMenuItem(
                  value: FocusMetric.maxWeight,
                  child: _buildFocusMenuItem('Max Weight', FocusMetric.maxWeight, currentMetric),
                ),
                PopupMenuItem(
                  value: FocusMetric.maxReps,
                  child: _buildFocusMenuItem('Max Reps', FocusMetric.maxReps, currentMetric),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFocusMetricIcon(currentMetric),
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentMetric != FocusMetric.none
                          ? _calculateFocusValue(exercise, currentMetric)
                          : '-',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
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
                  case 'focus_info':
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _FocusMetricInfoSheet(),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'focus_info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text('About Focus Metrics'),
                    ],
                  ),
                ),
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
                      SizedBox(width: 12),
                      Text('Remove Exercise', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
          SizedBox(width: 60, child: Center(child: Text('TEMPO', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)))),
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

  /// Get icon for a focus metric
  IconData _getFocusMetricIcon(FocusMetric metric) {
    switch (metric) {
      case FocusMetric.volume:
        return Icons.auto_graph;
      case FocusMetric.maxWeight:
        return Icons.monitor_weight_outlined;
      case FocusMetric.maxReps:
        return Icons.repeat;
      case FocusMetric.none:
        return Icons.touch_app_outlined;
    }
  }

  Widget _buildFocusMenuItem(String label, FocusMetric value, FocusMetric current) {
    return Row(
      children: [
        Icon(_getFocusMetricIcon(value), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (value == current)
          const Icon(Icons.check, size: 18, color: Colors.green),
      ],
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
        tempo: log.tempo,
      ),
    ];
  }

  /// Get previous set data for comparison.
  /// Uses the best weight/reps from the last session for this exercise
  /// (via [ExerciseStatsState.lastSessionData]), converted to a [WorkoutSet]
  /// so the set row can display historical comparison data in gray.
  WorkoutSet? _getPreviousSet(
    String exerciseId,
    int setIndex,
    ExerciseStatsState statsState,
  ) {
    final lastSession = statsState.lastSessionData[exerciseId];
    if (lastSession == null) return null;
    // Only show previous data if we have meaningful values.
    if (lastSession.bestWeight <= 0 && lastSession.bestReps <= 0) return null;

    return WorkoutSet(
      id: 'prev_${exerciseId}_$setIndex',
      logId: 'prev_${exerciseId}_log',
      reps: lastSession.bestReps,
      weight: lastSession.bestWeight,
      isCompleted: true,
    );
  }

  /// Calculate the computed focus metric value for an exercise, matching iOS.
  String _calculateFocusValue(ClientExerciseLog exercise, FocusMetric metric) {
    final sets = _parseSets(exercise);
    final completedSets = sets.where((s) => s.isCompleted);
    switch (metric) {
      case FocusMetric.volume:
        final volume = completedSets.fold<double>(
          0,
          (sum, s) => sum + ((s.weight ?? 0) * (s.reps ?? 0)),
        );
        return '${volume.toStringAsFixed(0)} kg';
      case FocusMetric.maxWeight:
        final maxW = completedSets
            .map((s) => s.weight ?? 0.0)
            .fold<double>(0.0, (a, b) => a > b ? a : b);
        return maxW > 0.0 ? '${maxW.toStringAsFixed(1)} kg' : '-';
      case FocusMetric.maxReps:
        final maxR = completedSets
            .map<double>((s) => (s.reps ?? 0).toDouble())
            .fold<double>(0.0, (a, b) => a > b ? a : b);
        return maxR > 0.0 ? maxR.toStringAsFixed(0) : '-';
      case FocusMetric.none:
        return '-';
    }
  }
}

/// A bottom sheet explaining focus metrics, matching iOS FocusMetricInfoSheet.
class _FocusMetricInfoSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'About Focus Metrics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _FocusMetricInfoRow(
            theme: theme,
            icon: Icons.auto_graph,
            title: 'Volume',
            description:
                'Total weight lifted across all completed sets.\n'
                'Calculated as Σ(weight × reps) for each set.',
          ),
          const SizedBox(height: 20),
          _FocusMetricInfoRow(
            theme: theme,
            icon: Icons.monitor_weight_outlined,
            title: 'Max Weight',
            description:
                'The heaviest weight lifted in any single completed set.\n'
                'Tracks your peak load for this exercise.',
          ),
          const SizedBox(height: 20),
          _FocusMetricInfoRow(
            theme: theme,
            icon: Icons.repeat,
            title: 'Max Reps',
            description:
                'The most repetitions completed in any single set.\n'
                'Measures muscular endurance.',
          ),
          const SizedBox(height: 20),
          Text(
            'Focus metrics only count completed sets. '
            'Tap the metric name to switch between them for each exercise.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the focus metric info sheet.
class _FocusMetricInfoRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String description;

  const _FocusMetricInfoRow({
    required this.theme,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}