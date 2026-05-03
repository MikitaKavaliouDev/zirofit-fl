import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final workoutHistoryProvider = StateNotifierProvider<
    WorkoutHistoryNotifier, WorkoutHistoryState>((ref) {
  final remoteSource = ref.watch(workoutRemoteSourceProvider);
  return WorkoutHistoryNotifier(remoteSource: remoteSource);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorkoutHistoryState {
  final List<WorkoutSession> sessions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? cursor;

  const WorkoutHistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.cursor,
  });

  WorkoutHistoryState copyWith({
    List<WorkoutSession>? sessions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? cursor,
    bool clearError = false,
  }) {
    return WorkoutHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      cursor: cursor ?? this.cursor,
    );
  }

  bool get isEmpty => sessions.isEmpty && !isLoading;

  /// Whether the initial load has completed (even if empty).
  bool get isInitialLoadComplete =>
      !isLoading && sessions.isNotEmpty || (!isLoading && !hasMore);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WorkoutHistoryNotifier extends StateNotifier<WorkoutHistoryState> {
  final WorkoutRemoteSource _remoteSource;
  static const int _pageSize = 20;

  WorkoutHistoryNotifier({required WorkoutRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const WorkoutHistoryState());

  /// Fetches the first page of workout history.
  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _pageSize,
      );

      state = WorkoutHistoryState(
        sessions: result.sessions,
        hasMore: result.hasMore,
        cursor: result.sessions.isNotEmpty
            ? result.sessions.last.id
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetches the next page of workout history (append mode).
  Future<void> fetchMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _remoteSource.getHistory(
        cursor: state.cursor,
        limit: _pageSize,
      );

      state = state.copyWith(
        isLoadingMore: false,
        sessions: [...state.sessions, ...result.sessions],
        hasMore: result.hasMore,
        cursor: result.sessions.isNotEmpty
            ? result.sessions.last.id
            : state.cursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Pull-to-refresh: resets and re-fetches.
  Future<void> refresh() async {
    state = const WorkoutHistoryState(isLoading: true);

    try {
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _pageSize,
      );

      state = WorkoutHistoryState(
        sessions: result.sessions,
        hasMore: result.hasMore,
        cursor: result.sessions.isNotEmpty
            ? result.sessions.last.id
            : null,
      );
    } catch (e) {
      state = WorkoutHistoryState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
