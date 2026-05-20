import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final exerciseStatsProvider = StateNotifierProvider<
    ExerciseStatsNotifier, ExerciseStatsState>((ref) {
  final remoteSource = ref.watch(workoutRemoteSourceProvider);
  return ExerciseStatsNotifier(remoteSource: remoteSource);
});

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// Personal record for a single exercise, representing the best known
/// performance across ALL historical data available to the provider.
class ExercisePR {
  final String exerciseId;
  final double maxWeight;
  final int maxReps;
  final double maxVolume; // weight × reps
  final DateTime date;

  const ExercisePR({
    required this.exerciseId,
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
    required this.date,
  });

  ExercisePR copyWith({
    String? exerciseId,
    double? maxWeight,
    int? maxReps,
    double? maxVolume,
    DateTime? date,
  }) {
    return ExercisePR(
      exerciseId: exerciseId ?? this.exerciseId,
      maxWeight: maxWeight ?? this.maxWeight,
      maxReps: maxReps ?? this.maxReps,
      maxVolume: maxVolume ?? this.maxVolume,
      date: date ?? this.date,
    );
  }

  /// Estimated one-rep max using the Epley formula.
  /// Uses the best weight-lifting pair on record.
  double? get estimated1RM {
    if (maxWeight <= 0 || maxReps <= 0) return null;
    if (maxReps == 1) return maxWeight; // already a 1RM
    return maxWeight * (1.0 + maxReps / 30.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercisePR &&
          exerciseId == other.exerciseId &&
          maxWeight == other.maxWeight &&
          maxReps == other.maxReps &&
          maxVolume == other.maxVolume &&
          date == other.date;

  @override
  int get hashCode => Object.hash(
        exerciseId,
        maxWeight,
        maxReps,
        maxVolume,
        date,
      );

  @override
  String toString() =>
      'ExercisePR(exerciseId: $exerciseId, maxWeight: $maxWeight, '
      'maxReps: $maxReps, maxVolume: $maxVolume, date: $date)';
}

/// Summary of a single exercise's performance in one past session.
class SessionExerciseData {
  final String exerciseId;
  final double bestWeight;
  final int bestReps;
  final double totalVolume;
  final DateTime date;

  const SessionExerciseData({
    required this.exerciseId,
    required this.bestWeight,
    required this.bestReps,
    required this.totalVolume,
    required this.date,
  });

  SessionExerciseData copyWith({
    String? exerciseId,
    double? bestWeight,
    int? bestReps,
    double? totalVolume,
    DateTime? date,
  }) {
    return SessionExerciseData(
      exerciseId: exerciseId ?? this.exerciseId,
      bestWeight: bestWeight ?? this.bestWeight,
      bestReps: bestReps ?? this.bestReps,
      totalVolume: totalVolume ?? this.totalVolume,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExerciseData &&
          exerciseId == other.exerciseId &&
          bestWeight == other.bestWeight &&
          bestReps == other.bestReps &&
          totalVolume == other.totalVolume &&
          date == other.date;

  @override
  int get hashCode => Object.hash(
        exerciseId,
        bestWeight,
        bestReps,
        totalVolume,
        date,
      );

  @override
  String toString() =>
      'SessionExerciseData(exerciseId: $exerciseId, bestWeight: $bestWeight, '
      'bestReps: $bestReps, totalVolume: $totalVolume, date: $date)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ExerciseStatsState {
  /// exerciseId → all-time personal record for that exercise.
  final Map<String, ExercisePR> prByExercise;

  /// exerciseId → most recent session's exercise data.
  final Map<String, SessionExerciseData> lastSessionData;

  /// exerciseId → cumulative lifetime volume (all sets from all sessions).
  final Map<String, int> volumeByExercise;

  final bool isLoading;
  final bool isLoaded;
  final String? error;

  const ExerciseStatsState({
    this.prByExercise = const {},
    this.lastSessionData = const {},
    this.volumeByExercise = const {},
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  ExerciseStatsState copyWith({
    Map<String, ExercisePR>? prByExercise,
    Map<String, SessionExerciseData>? lastSessionData,
    Map<String, int>? volumeByExercise,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    bool clearError = false,
  }) {
    return ExerciseStatsState(
      prByExercise: prByExercise ?? this.prByExercise,
      lastSessionData: lastSessionData ?? this.lastSessionData,
      volumeByExercise: volumeByExercise ?? this.volumeByExercise,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseStatsState &&
          prByExercise == other.prByExercise &&
          lastSessionData == other.lastSessionData &&
          volumeByExercise == other.volumeByExercise &&
          isLoading == other.isLoading &&
          isLoaded == other.isLoaded &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        prByExercise,
        lastSessionData,
        volumeByExercise,
        isLoading,
        isLoaded,
        error,
      );

  @override
  String toString() =>
      'ExerciseStatsState(prs: ${prByExercise.length}, '
      'lastSession: ${lastSessionData.length}, '
      'volumes: ${volumeByExercise.length}, '
      'isLoading: $isLoading, isLoaded: $isLoaded)';
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ExerciseStatsNotifier extends StateNotifier<ExerciseStatsState> {
  final WorkoutRemoteSource _remoteSource;
  static const int _recentSessionsToFetch = 20;

  ExerciseStatsNotifier({required WorkoutRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const ExerciseStatsState());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetches historical workout data and computes exercise statistics.
  ///
  /// [forceRefresh] bypasses the in-memory cache, forcing a full re-fetch from
  /// the API. By default the provider caches results for the lifetime of the
  /// session to avoid redundant network calls during a workout.
  Future<void> fetchExerciseStats({bool forceRefresh = false}) async {
    // Cache hit: skip if already loaded (unless forced refresh).
    if (state.isLoaded && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Fetch recent workout sessions.
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _recentSessionsToFetch,
      );

      final sessions = result.sessions;

      // 2. Build per-session exercise summaries from each session's detailed
      //    summary endpoint so we have exercise-level data (weight, reps,
      //    volume) rather than just session-level metadata.
      final allExerciseSummaries = <String, List<_SessionExerciseEntry>>{};

      for (final session in sessions) {
        try {
          final summaryResponse =
              await _remoteSource.fetchWorkoutSummary(session.id);
          final exercises = summaryResponse.session.exercises;

          for (final ex in exercises) {
            final entry = _SessionExerciseEntry(
              sessionDate: summaryResponse.session.startTime,
              bestWeight: ex.bestWeight ?? 0,
              totalReps: ex.totalReps,
              totalVolume: ex.totalVolume,
            );
            allExerciseSummaries
                .putIfAbsent(ex.exerciseId, () => [])
                .add(entry);
          }
        } catch (_) {
          // Silently skip sessions that fail to load summaries — the
          // provider degrades gracefully when some historical data is
          // unavailable.
          debugPrint('EXERCISE_STATS: skipped summary for ${session.id}');
        }
      }

      // 3. Compute PRs, last-session data, and lifetime volumes from the
      //    collected summaries.
      final prByExercise = <String, ExercisePR>{};
      final lastSessionData = <String, SessionExerciseData>{};
      final volumeByExercise = <String, int>{};
      final sessionDates = <String, DateTime>{};

      for (final entry in allExerciseSummaries.entries) {
        final exerciseId = entry.key;
        final entries = entry.value;

        // --- Compute lifetime totals ---
        int lifetimeVolume = 0;
        for (final e in entries) {
          lifetimeVolume += e.totalVolume.toInt();
        }
        volumeByExercise[exerciseId] = lifetimeVolume;

        // --- Compute PR (max weight, then max volume, then max reps) ---
        double maxW = 0;
        int maxR = 0;
        double maxV = 0;
        DateTime prDate = DateTime.fromMillisecondsSinceEpoch(0);

        for (final e in entries) {
          bool updated = false;

          if (e.bestWeight > maxW) {
            maxW = e.bestWeight;
            updated = true;
          } else if (e.bestWeight == maxW && e.bestWeight > 0) {
            // Same weight → compare volume, then reps
            // Volume per best set isn't in ExerciseSummary, so we use
            // bestWeight × (totalReps / setsCompleted) as an approximation,
            // but the PR detection at runtime (isNewPR) will use actual
            // weight×reps from the current set.
            if (e.totalVolume > maxV) {
              updated = true;
            } else if (e.totalVolume == maxV &&
                e.totalReps > maxR) {
              updated = true;
            }
          }

          if (updated) {
            maxW = e.bestWeight;
            maxV = e.totalVolume;
            maxR = e.totalReps;
            prDate = e.sessionDate;
          }

          // Track max reps separately for the PR record
          if (e.totalReps > maxR) {
            maxR = e.totalReps;
          }
          if (e.totalVolume > maxV) {
            maxV = e.totalVolume;
            if (e.totalReps > maxR) maxR = e.totalReps;
          }
        }

        prByExercise[exerciseId] = ExercisePR(
          exerciseId: exerciseId,
          maxWeight: maxW,
          maxReps: maxR,
          maxVolume: maxV,
          date: prDate,
        );

        // --- Compute last-session data ---
        // Sort entries by date; the most recent is "last session".
        entries.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
        final latest = entries.last;

        lastSessionData[exerciseId] = SessionExerciseData(
          exerciseId: exerciseId,
          bestWeight: latest.bestWeight,
          bestReps: latest.totalReps,
          totalVolume: latest.totalVolume,
          date: latest.sessionDate,
        );

        // Track latest date per exercise for the PR date update
        final existing = sessionDates[exerciseId];
        if (existing == null || latest.sessionDate.isAfter(existing)) {
          sessionDates[exerciseId] = latest.sessionDate;
        }
      }

      state = ExerciseStatsState(
        prByExercise: prByExercise,
        lastSessionData: lastSessionData,
        volumeByExercise: volumeByExercise,
        isLoaded: true,
      );
    } catch (e, st) {
      debugPrint('EXERCISE_STATS_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Evaluates whether a set (identified by [exerciseId], [weight], [reps])
  /// constitutes a new personal record.
  ///
  /// Comparison hierarchy (must NOT):
  ///   1. **Weight** — the heaviest single set ever recorded for this
  ///      exercise. Any set heavier than this is an automatic PR.
  ///   2. **Volume (weight × reps)** — if the weight matches the existing PR
  ///      weight, the set's volume is compared.
  ///   3. **Reps** — if both weight and volume match, the set with more reps
  ///      wins.
  bool isNewPR(String exerciseId, double weight, int reps) {
    final currentPR = state.prByExercise[exerciseId];
    if (currentPR == null) return true; // No history → first set is a PR
    if (weight <= 0 || reps <= 0) return false;

    final volume = weight * reps;

    // 1. Heaviest weight wins.
    if (weight > currentPR.maxWeight) return true;

    // 2. Same weight → compare volume.
    if (weight == currentPR.maxWeight) {
      if (volume > currentPR.maxVolume) return true;

      // 3. Same weight and volume → compare reps.
      if (volume == currentPR.maxVolume && reps > currentPR.maxReps) {
        return true;
      }
    }

    return false;
  }

  /// Returns the [SessionExerciseData] for the most recent session that
  /// included [exerciseId], or `null` if the exercise has never been
  /// performed.
  SessionExerciseData? getLastSessionData(String exerciseId) {
    return state.lastSessionData[exerciseId];
  }

  /// Estimates the one-rep max (1RM) for [exerciseId] using the **Epley
  /// formula**:
  ///
  ///     estimated1RM = weight × (1 + reps / 30)
  ///
  /// The estimate is based on the best recorded set for this exercise.
  /// Returns `null` when no data is available or the PR weight is zero.
  double? estimateOneRepMax(String exerciseId) {
    return state.prByExercise[exerciseId]?.estimated1RM;
  }

  /// Clears any error message in the state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Invalidates the cache so the next call to [fetchExerciseStats] will
  /// re-fetch from the API.
  void invalidateCache() {
    state = state.copyWith(isLoaded: false);
  }

  /// Resets all state to defaults.
  void reset() {
    state = const ExerciseStatsState();
  }

  /// Returns historical [ClientExerciseLog] entries for the given [exerciseId],
  /// used by [NewRecordDetectionService.checkForNewRecord] to detect personal
  /// records.
  ///
  /// Fetches recent session summaries from the API and constructs log entries
  /// from each session's per-exercise summary data.  If the stats cache hasn't
  /// been populated yet it will be loaded first.
  ///
  /// Returns an empty list if the exercise has never been performed or on error.
  Future<List<ClientExerciseLog>> getHistoricalLogs(String exerciseId) async {
    // Ensure stats are loaded
    if (!state.isLoaded) {
      await fetchExerciseStats();
    }

    // Check if we have any relevant data before hitting the API again
    if (!state.prByExercise.containsKey(exerciseId) &&
        !state.lastSessionData.containsKey(exerciseId)) {
      return [];
    }

    try {
      final result = await _remoteSource.getHistory(
        cursor: null,
        limit: _recentSessionsToFetch,
      );

      final logs = <ClientExerciseLog>[];
      for (final session in result.sessions) {
        try {
          final summaryResponse =
              await _remoteSource.fetchWorkoutSummary(session.id);
          final filtered = summaryResponse.session.exercises
              .where((ex) => ex.exerciseId == exerciseId)
              .toList();

          for (final ex in filtered) {
            // Average reps per set as a reasonable per-set approximation
            final avgReps = ex.setsCompleted > 0
                ? (ex.totalReps / ex.setsCompleted).round()
                : ex.totalReps;

            logs.add(ClientExerciseLog(
              id: 'hist_${session.id}_${ex.exerciseId}',
              clientId: session.clientId,
              exerciseId: ex.exerciseId,
              weight: ex.bestWeight,
              reps: avgReps,
              isCompleted: true,
              exerciseName: ex.exerciseName,
              workoutSessionId: session.id,
              createdAt: summaryResponse.session.startTime,
            ));
          }
        } catch (_) {
          // Silently skip sessions that fail to load summaries
          debugPrint('GET_HISTORICAL_LOGS: skipped session ${session.id}');
        }
      }

      return logs;
    } catch (e) {
      debugPrint('GET_HISTORICAL_LOGS_ERROR: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
}

/// Internal grouping helper that pairs exercise-by-session data with its
/// session date for chronological sorting and PR computation.
class _SessionExerciseEntry {
  final DateTime sessionDate;
  final double bestWeight;
  final int totalReps;
  final double totalVolume;

  const _SessionExerciseEntry({
    required this.sessionDate,
    required this.bestWeight,
    required this.totalReps,
    required this.totalVolume,
  });
}
