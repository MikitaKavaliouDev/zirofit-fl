# Phase 1 Implementation Plan: Critical iOS UX Parity

## Context
Gap analysis at `.sisyphus/plans/ios-parity-gap-analysis.md` identifies 7 P0 items.

## Dependency Graph
- **Independent (parallel Wave 1)**: T1 (model), T3 (rest bar), T4 (collapse), T5 (focus metric), T6 (coach notes), T7 (push-to-talk), T8 (template pre-pop)
- **Depends on T1**: T2 (tempo cell) — Wave 2

## Wave 1 Tasks (Parallel)

### Task 1: Add `tempo` to WorkoutSet model
- **File**: `lib/data/models/workout_set.dart`
- **Change**: Add `String? tempo`, update fromJson/toJson/copyWith/==/hashCode
- **Also**: `lib/features/workout/widgets/enhanced_exercise_list_builder.dart` — update `_parseSets()` to pass `log.tempo`
- **Category**: `coding`
- **Test**: `flutter test test/unit/models/workout_set_test.dart`

### Task 3: Visual rest progress bar in header
- **File**: `lib/features/workout/widgets/workout_session_header.dart`
- **Change**: Replace text "REST: MM:SS" with `LinearProgressIndicator` using `restState.progress`
- **Category**: `visual-engineering`
- **QA**: Verify progress bar animates smoothly from full to empty

### Task 4: Collapse/expand exercise cards
- **File**: `lib/features/workout/widgets/enhanced_exercise_list_builder.dart`
- **Change**: Add `Set<String> _collapsedExerciseIds`; chevron with `AnimatedRotation`; wrap sets in `AnimatedSize`
- **Category**: `visual-engineering`
- **Test**: Verify toggling collapses/expands sets section

### Task 5: Focus metric selector on exercise header
- **File**: `lib/features/workout/widgets/enhanced_exercise_list_builder.dart`
- **Change**: Add `PopupMenuButton<FocusMetric>` to exercise header; wire to `updateFocusMetric` provider
- **Category**: `coding`

### Task 6: Coach notes popover
- **File**: `lib/features/workout/widgets/enhanced_exercise_list_builder.dart`
- **Change**: Add lightbulb `IconButton` when `state.coachNotes != null`; opens `CoachNotesCard` in bottom sheet
- **Category**: `coding`

### Task 7: Push-to-talk voice recording
- **File**: `lib/features/workout/widgets/workout_session_controls.dart`
- **Change**: Replace `onTapDown` with `onTapDown`(start) + `onTapUp`(stop) + `onTapCancel`(stop)
- **Also**: Update `EnhancedActiveWorkoutScreen` to handle recording start/stop
- **Category**: `coding`

### Task 8: Template exercise pre-population
- **Files**: `lib/features/workout/data/workout_remote_source.dart` + `lib/features/workout/providers/active_workout_provider.dart`
- **Change**: Add `fetchTemplateExercises()` to remote source; rewrite `_populateTemplateExercises()` to fetch and add exercises
- **Category**: `deep`

## Wave 2 (After T1)

### Task 2: Tempo input cell + TEMPO column
- **File**: `lib/features/workout/widgets/enhanced_workout_set_row.dart` + `enhanced_exercise_list_builder.dart`
- **Change**: Add `_buildTempoInput()` between RPE and completion toggle; add TEMPO column header
- **Category**: `visual-engineering`
- **Depends**: Task 1

## Success Criteria
1. `flutter analyze` — clean
2. `flutter test` — all green
3. Tempo field renders and accepts input
4. Rest progress bar animates during rest
5. Exercise cards collapse/expand with animation
6. Focus metric selector changes icon on selection
7. Coach notes popover opens from header
8. Voice button responds to press-and-hold
9. Template exercises pre-populate on session start
