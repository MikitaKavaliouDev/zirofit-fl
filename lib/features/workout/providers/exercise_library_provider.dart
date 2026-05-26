import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';

// ---------------------------------------------------------------------------
// ExerciseLibraryState
// ---------------------------------------------------------------------------

/// State container for the exercise library search/filter/selection flow.
///
/// Mirrors the iOS `ExerciseSelectionView` experience:
///  - Full exercise catalogue from the API (lazy-loaded via [exerciseListProvider])
///  - Client-side real-time search by exercise name
///  - Filter by muscle group / body part
///  - In-memory recent exercise tracking (per-session)
///  - Derived filteredExercises, availableMuscleGroups, etc.
class ExerciseLibraryState {
  /// The complete set of exercises loaded from the API.
  final List<Exercise> allExercises;

  /// Exercises that pass the current search + filter criteria.
  /// Computed client-side for instant feedback.
  final List<Exercise> filteredExercises;

  /// Current search query (case-insensitive, matched against exercise name).
  final String searchQuery;

  /// Currently selected muscle group filter, or `null` for "all".
  final String? selectedMuscleGroup;

  /// In-memory list of recently used exercise IDs (most recent first).
  /// Persists only for the duration of the session.
  final List<String> recentExercises;

  /// Whether the underlying exercise list is loading.
  final bool isLoading;

  /// Error message from the underlying provider, if any.
  final String? error;

  const ExerciseLibraryState({
    this.allExercises = const [],
    this.filteredExercises = const [],
    this.searchQuery = '',
    this.selectedMuscleGroup,
    this.recentExercises = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseLibraryState copyWith({
    List<Exercise>? allExercises,
    List<Exercise>? filteredExercises,
    String? searchQuery,
    String? selectedMuscleGroup,
    bool clearMuscleGroup = false,
    List<String>? recentExercises,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExerciseLibraryState(
      allExercises: allExercises ?? this.allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscleGroup:
          clearMuscleGroup ? null : (selectedMuscleGroup ?? this.selectedMuscleGroup),
      recentExercises: recentExercises ?? this.recentExercises,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Unique, sorted muscle groups derived from [allExercises].
  List<String> get availableMuscleGroups {
    final groups = allExercises
        .map((e) => e.muscleGroup)
        .where((mg) => mg != null && mg.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return groups.cast<String>();
  }

  /// Unique, sorted body parts derived from [allExercises].
  /// Currently synonymous with [availableMuscleGroups] since the
  /// [Exercise] model uses `muscleGroup` for body-part classification.
  List<String> get availableBodyParts => availableMuscleGroups;

  /// Whether any filter is active.
  bool get hasActiveFilters => searchQuery.isNotEmpty || selectedMuscleGroup != null;

  @override
  String toString() =>
      'ExerciseLibraryState('
      'allExercises: ${allExercises.length}, '
      'filteredExercises: ${filteredExercises.length}, '
      'searchQuery: "$searchQuery", '
      'selectedMuscleGroup: $selectedMuscleGroup, '
      'recentExercises: ${recentExercises.length}, '
      'isLoading: $isLoading'
      ')';
}

// ---------------------------------------------------------------------------
// ExerciseLibraryNotifier
// ---------------------------------------------------------------------------

/// Manages [ExerciseLibraryState] with client-side search / filter logic.
///
/// Synchronises its `allExercises` list from the existing [exerciseListProvider]
/// so that API fetching remains the concern of [ExerciseListNotifier].
/// All filtering (search, muscle group) is applied **client-side** for
/// instant responsiveness.
class ExerciseLibraryNotifier extends StateNotifier<ExerciseLibraryState> {
  final Ref _ref;

  ExerciseLibraryNotifier(this._ref) : super(const ExerciseLibraryState());

  // ---------------------------------------------------------------------------
  // Sync from the external exercise list provider
  // ---------------------------------------------------------------------------

  /// Replaces [allExercises] and re-applies the current filters.
  void syncExercises(List<Exercise> exercises) {
    state = state.copyWith(
      allExercises: exercises,
      isLoading: false,
      clearError: true,
    );
    _applyFilters();
  }

  /// Mirrors the loading state of [exerciseListProvider].
  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  /// Mirrors the error state of [exerciseListProvider].
  void setError(String? message) {
    state = state.copyWith(error: message, isLoading: false);
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Triggers a fresh fetch from the API via the underlying provider.
  void loadExercises() {
    state = state.copyWith(isLoading: true, clearError: true);
    _ref.read(exerciseListProvider.notifier).fetchExercises();
  }

  /// Updates the search query and instantly re-filters locally.
  ///
  /// Pass an empty string to clear search.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Sets a muscle group filter.
  /// Pass `null` to show all muscle groups.
  void setMuscleGroupFilter(String? muscleGroup) {
    state = state.copyWith(
      selectedMuscleGroup: muscleGroup,
      clearMuscleGroup: muscleGroup == null,
    );
    _applyFilters();
  }

  /// Resets both the search query and the muscle group filter.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedMuscleGroup: null,
      clearMuscleGroup: true,
    );
    _applyFilters();
  }

  /// Convenience alias for [addToRecent] — called when user taps an exercise.
  void selectExercise(String exerciseId) {
    addToRecent(exerciseId);
  }

  /// Adds [exerciseId] to the in-memory recent list (deduped, most-recent-first).
  /// Caps at 20 entries to avoid unbounded growth.
  void addToRecent(String exerciseId) {
    final recent = List<String>.from(state.recentExercises);
    recent.remove(exerciseId);
    recent.insert(0, exerciseId);
    if (recent.length > 20) {
      recent.removeRange(20, recent.length);
    }
    state = state.copyWith(recentExercises: recent);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Applies the current [searchQuery] and [selectedMuscleGroup] to
  /// [allExercises] and writes the result into [filteredExercises].
  ///
  /// - Search: case-insensitive substring match on exercise name.
  /// - Muscle group: case-insensitive exact match.
  void _applyFilters() {
    var exercises = state.allExercises.toList();

    // --- search by name (case-insensitive, contains) ---
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      exercises = exercises.where((e) {
        return e.name.toLowerCase().contains(query);
      }).toList();
    }

    // --- filter by muscle group ---
    if (state.selectedMuscleGroup != null && state.selectedMuscleGroup!.isNotEmpty) {
      final target = state.selectedMuscleGroup!.toLowerCase();
      exercises = exercises.where((e) {
        return e.muscleGroup?.toLowerCase() == target;
      }).toList();
    }

    state = state.copyWith(filteredExercises: exercises);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the exercise library state with client-side search/filter.
///
/// Syncs its [ExerciseLibraryState.allExercises] from the server-fetching
/// [exerciseListProvider] and applies all filtering locally so the UI
/// responds instantly to user input.
final exerciseLibraryProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, ExerciseLibraryState>((ref) {
  final notifier = ExerciseLibraryNotifier(ref);

  // --- initial sync ---
  final initialListState = ref.read(exerciseListProvider);
  if (initialListState.exercises.isNotEmpty) {
    notifier.syncExercises(initialListState.exercises);
  }
  notifier.setLoading(initialListState.isLoading);
  if (initialListState.hasError) {
    notifier.setError(initialListState.error);
  }

  // --- keep in sync with the server-driven provider ---
  ref.listen(exerciseListProvider, (prev, next) {
    notifier.syncExercises(next.exercises);
    notifier.setLoading(next.isLoading);
    if (next.hasError) {
      notifier.setError(next.error);
    }
  });

  // --- kick off initial fetch if it hasn't been started ---
  if (initialListState.status == ExerciseListStatus.initial) {
    ref.read(exerciseListProvider.notifier).fetchExercises();
  }

  return notifier;
});

/// Read-only provider exposing just the list of recently used exercise IDs.
///
/// ```dart
/// final recentIds = ref.watch(recentExercisesProvider);
/// ```
final recentExercisesProvider = Provider<List<String>>((ref) {
  return ref.watch(exerciseLibraryProvider).recentExercises;
});
