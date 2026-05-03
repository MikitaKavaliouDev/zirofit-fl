import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Possible statuses for the exercise list.
enum ExerciseListStatus { initial, loading, loaded, error, loadingMore }

/// State container for the exercise list screen.
class ExerciseListState {
  final List<Exercise> exercises;
  final ExerciseListStatus status;
  final String? error;
  final String search;
  final String? category;
  final String? muscleGroup;
  final int page;
  final bool hasMore;

  const ExerciseListState({
    this.exercises = const [],
    this.status = ExerciseListStatus.initial,
    this.error,
    this.search = '',
    this.category,
    this.muscleGroup,
    this.page = 1,
    this.hasMore = true,
  });

  ExerciseListState copyWith({
    List<Exercise>? exercises,
    ExerciseListStatus? status,
    String? error,
    bool clearError = false,
    String? search,
    String? category,
    bool clearCategory = false,
    String? muscleGroup,
    bool clearMuscleGroup = false,
    int? page,
    bool? hasMore,
  }) {
    return ExerciseListState(
      exercises: exercises ?? this.exercises,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
      muscleGroup: clearMuscleGroup
          ? null
          : (muscleGroup ?? this.muscleGroup),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  bool get isLoading => status == ExerciseListStatus.loading;
  bool get isLoaded => status == ExerciseListStatus.loaded;
  bool get hasError => status == ExerciseListStatus.error;
  bool get isLoadingMore => status == ExerciseListStatus.loadingMore;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages exercise list state including search, filters, and pagination.
class ExerciseListNotifier extends StateNotifier<ExerciseListState> {
  final ExerciseRemoteSource _remoteSource;

  ExerciseListNotifier(this._remoteSource)
      : super(const ExerciseListState());

  /// Fetches exercises with optional [search], [category], and [muscleGroup].
  /// Resets pagination to page 1.
  Future<void> fetchExercises({
    String? search,
    String? category,
    String? muscleGroup,
  }) async {
    state = state.copyWith(
      status: ExerciseListStatus.loading,
      search: search,
      category: category,
      muscleGroup: muscleGroup,
      clearError: true,
      page: 1,
      exercises: [],
    );

    try {
      final response = await _remoteSource.searchExercises(
        search: search,
        category: category,
        muscleGroup: muscleGroup,
        page: 1,
        limit: 50,
      );

      if (response.isSuccess && response.data != null) {
        state = state.copyWith(
          exercises: response.data!,
          status: ExerciseListStatus.loaded,
          page: 1,
          hasMore: response.data!.length >= 50,
        );
      } else {
        state = state.copyWith(
          status: ExerciseListStatus.error,
          error: response.errorMessage ?? 'Failed to load exercises',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ExerciseListStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Loads the next page of exercises (append mode).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(status: ExerciseListStatus.loadingMore);

    try {
      final response = await _remoteSource.searchExercises(
        search: state.search.isNotEmpty ? state.search : null,
        category: state.category,
        muscleGroup: state.muscleGroup,
        page: nextPage,
        limit: 50,
      );

      if (response.isSuccess && response.data != null) {
        final existingIds = state.exercises.map((e) => e.id).toSet();
        final newExercises = response.data!
            .where((e) => !existingIds.contains(e.id))
            .toList();

        state = state.copyWith(
          exercises: [...state.exercises, ...newExercises],
          status: ExerciseListStatus.loaded,
          page: nextPage,
          hasMore: newExercises.length >= 50,
        );
      } else {
        // No more data or error — just revert status
        state = state.copyWith(status: ExerciseListStatus.loaded);
      }
    } catch (e) {
      state = state.copyWith(status: ExerciseListStatus.loaded);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final exerciseListProvider =
    StateNotifierProvider<ExerciseListNotifier, ExerciseListState>((ref) {
  return ExerciseListNotifier(ExerciseRemoteSource());
});
