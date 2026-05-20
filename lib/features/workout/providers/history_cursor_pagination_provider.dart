import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// WorkoutSessionSummary
// ---------------------------------------------------------------------------

/// Lightweight summary representation of a workout session for list display.
///
/// Derived from [WorkoutSession] but only carries fields needed for
/// paginated history browsing — avoids pulling full session graphs.
class WorkoutSessionSummary {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int exerciseCount;
  final double totalVolume;
  final String? clientName;

  const WorkoutSessionSummary({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.exerciseCount = 0,
    this.totalVolume = 0,
    this.clientName,
  });

  factory WorkoutSessionSummary.fromWorkoutSession(WorkoutSession session) {
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;

    // session.name maps to the workout name or nested client name
    // (see WorkoutSession.fromJson logic).
    return WorkoutSessionSummary(
      id: session.id,
      startTime: session.startTime,
      endTime: session.endTime,
      durationMinutes: duration.inMinutes,
      exerciseCount: 0, // not available on WorkoutSession directly
      totalVolume: 0, // not available on WorkoutSession directly
      clientName: session.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionSummary &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          durationMinutes == other.durationMinutes &&
          exerciseCount == other.exerciseCount &&
          totalVolume == other.totalVolume &&
          clientName == other.clientName;

  @override
  int get hashCode => Object.hash(
        id,
        startTime,
        endTime,
        durationMinutes,
        exerciseCount,
        totalVolume,
        clientName,
      );

  @override
  String toString() =>
      'WorkoutSessionSummary(id: $id, startTime: $startTime, '
      'durationMinutes: $durationMinutes, clientName: $clientName)';
}

// ---------------------------------------------------------------------------
// HistoryCursorPaginationState
// ---------------------------------------------------------------------------

/// State for cursor-based workout history pagination.
///
/// Tracks the session list, opaque cursor for the next page, and distinct
/// loading flags for initial load vs. page-appends so the UI can show
/// appropriate indicators (full-screen spinner vs. bottom loader).
class HistoryCursorPaginationState {
  /// Accumulated list of workout session summaries across pages.
  final List<WorkoutSessionSummary> sessions;

  /// Opaque cursor for fetching the next page.
  /// `null` when there is no next page or before the first load.
  final String? cursor;

  /// Whether more pages are available on the server.
  final bool hasMore;

  /// `true` during the initial page load (full-screen spinner).
  final bool isLoading;

  /// `true` while appending a subsequent page (inline/bottom loader).
  final bool isLoadingMore;

  /// Human-readable error message, or `null`.
  final String? error;

  const HistoryCursorPaginationState({
    this.sessions = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  HistoryCursorPaginationState copyWith({
    List<WorkoutSessionSummary>? sessions,
    String? cursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return HistoryCursorPaginationState(
      sessions: sessions ?? this.sessions,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provider for cursor-based workout history pagination.
///
/// Replaces offset-based approaches with an opaque cursor model matching the
/// iOS reference implementation.
final historyCursorPaginationProvider = StateNotifierProvider<
    HistoryCursorPaginationNotifier, HistoryCursorPaginationState>((ref) {
  final remoteSource = ref.watch(workoutRemoteSourceProvider);
  return HistoryCursorPaginationNotifier(remoteSource: remoteSource);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages cursor-based pagination of workout history.
///
/// Architecture (matching iOS reference):
/// - Page size: 20 items
/// - Initial load fetches page 1, sets [cursor] to the last item's ID
/// - [loadMore] appends the next page using the stored cursor
/// - Rapid [loadMore] calls are debounced to prevent duplicate requests
/// - [refresh] resets the cursor and re-fetches from scratch
class HistoryCursorPaginationNotifier
    extends StateNotifier<HistoryCursorPaginationState> {
  final WorkoutRemoteSource _remoteSource;

  /// Page size matching iOS reference (20 items).
  static const int _pageSize = 20;

  /// Debounce window for rapid [loadMore] calls (e.g. scroll events).
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// Timer for debouncing consecutive [loadMore] invocations.
  Timer? _debounceTimer;

  HistoryCursorPaginationNotifier({required WorkoutRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const HistoryCursorPaginationState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads the first page of workout history.
  ///
  /// Sets [isLoading] to `true` during the request. On success the accumulated
  /// [sessions] list is replaced (not appended) and [cursor] points to the
  /// last item for subsequent [loadMore] calls.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _pageSize,
      );

      final summaries = result.sessions
          .map(WorkoutSessionSummary.fromWorkoutSession)
          .toList();

      state = HistoryCursorPaginationState(
        sessions: summaries,
        hasMore: result.hasMore,
        cursor: summaries.isNotEmpty ? summaries.last.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Loads the next page using cursor-based pagination.
  ///
  /// Debounces rapid calls ([_debounceDuration]) so that only the final
  /// invocation in a burst is executed. No-op when:
  /// - A page append is already in flight ([isLoadingMore])
  /// - The initial load is still running ([isLoading])
  /// - No more pages are available ([hasMore] is `false`)
  Future<void> loadMore() async {
    // Guard: prevent concurrent / duplicate requests
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    // Debounce: cancel any pending timer from a previous call
    _debounceTimer?.cancel();

    // Use a Completer so the caller can await the debounced operation
    final completer = Completer<void>();
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        state = state.copyWith(isLoadingMore: true);

        final result = await _remoteSource.getHistory(
          cursor: state.cursor,
          limit: _pageSize,
        );

        final summaries = result.sessions
            .map(WorkoutSessionSummary.fromWorkoutSession)
            .toList();

        state = state.copyWith(
          isLoadingMore: false,
          sessions: [...state.sessions, ...summaries],
          hasMore: result.hasMore,
          cursor: summaries.isNotEmpty ? summaries.last.id : state.cursor,
        );
      } catch (e) {
        state = state.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        );
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  /// Resets all state and reloads from the first page.
  ///
  /// Cancels any pending debounced [loadMore] and discards accumulated
  /// sessions before fetching fresh data — identical semantics to
  /// pull-to-refresh.
  Future<void> refresh() async {
    _debounceTimer?.cancel();
    state = const HistoryCursorPaginationState(isLoading: true);

    try {
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _pageSize,
      );

      final summaries = result.sessions
          .map(WorkoutSessionSummary.fromWorkoutSession)
          .toList();

      state = HistoryCursorPaginationState(
        sessions: summaries,
        hasMore: result.hasMore,
        cursor: summaries.isNotEmpty ? summaries.last.id : null,
      );
    } catch (e) {
      state = HistoryCursorPaginationState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears all state and resets to initial values.
  ///
  /// Cancels any pending debounced [loadMore] and discards accumulated
  /// sessions and error state.
  void clear() {
    _debounceTimer?.cancel();
    state = const HistoryCursorPaginationState();
  }
}
