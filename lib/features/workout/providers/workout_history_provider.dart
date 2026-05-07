import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// DateRange
// ---------------------------------------------------------------------------

enum DateRangePreset { last7Days, last30Days, last3Months, custom }

class DateRange {
  final DateTime start;
  final DateTime end;
  final DateRangePreset preset;

  const DateRange({
    required this.start,
    required this.end,
    required this.preset,
  });

  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
      preset: DateRangePreset.last7Days,
    );
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
      preset: DateRangePreset.last30Days,
    );
  }

  factory DateRange.last3Months() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 3, now.day),
      end: now,
      preset: DateRangePreset.last3Months,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          start == other.start &&
          end == other.end &&
          preset == other.preset;

  @override
  int get hashCode => Object.hash(start, end, preset);
}

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
  final String searchQuery;
  final DateRange? dateRange;

  const WorkoutHistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.cursor,
    this.searchQuery = '',
    this.dateRange,
  });

  WorkoutHistoryState copyWith({
    List<WorkoutSession>? sessions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? cursor,
    bool clearError = false,
    String? searchQuery,
    Object? dateRange = _sentinel,
  }) {
    return WorkoutHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      cursor: cursor ?? this.cursor,
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: identical(dateRange, _sentinel)
          ? this.dateRange
          : dateRange as DateRange?,
    );
  }

  bool get isEmpty => sessions.isEmpty && !isLoading;

  /// Whether the initial load has completed (even if empty).
  bool get isInitialLoadComplete =>
      !isLoading && sessions.isNotEmpty || (!isLoading && !hasMore);

  /// Computed: sessions filtered by [searchQuery] and [dateRange].
  List<WorkoutSession> get filteredSessions {
    var result = sessions;

    // Apply search query against session name and notes
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((s) {
        final nameMatch = s.name?.toLowerCase().contains(query) ?? false;
        final notesMatch = s.notes?.toLowerCase().contains(query) ?? false;
        return nameMatch || notesMatch;
      }).toList();
    }

    // Apply date range filter
    if (dateRange != null) {
      final start = dateRange!.start;
      final end = dateRange!.end;
      result = result.where((s) {
        return s.startTime.isAfter(start) &&
            s.startTime.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    }

    return result;
  }
}

/// Sentinel value to distinguish "not passed" from `null` for nullable
/// [dateRange] in [WorkoutHistoryState.copyWith].
const _sentinel = Object();

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

  /// Sets the search query for filtering sessions by name or notes.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets (or clears) the date range filter.
  void setDateRange(DateRange? range) {
    state = state.copyWith(dateRange: range);
  }
}
