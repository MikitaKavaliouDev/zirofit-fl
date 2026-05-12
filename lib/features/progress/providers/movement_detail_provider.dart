import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/shared/widgets/charts/models.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Aggregated stats for a single exercise / movement.
class MovementStats {
  final int totalReps;
  final int totalSets;
  final double maxWeight;
  final double maxVolume;

  const MovementStats({
    required this.totalReps,
    required this.totalSets,
    required this.maxWeight,
    required this.maxVolume,
  });

  static const empty = MovementStats(
    totalReps: 0,
    totalSets: 0,
    maxWeight: 0,
    maxVolume: 0,
  );
}

/// A single historical set used in the "Top Historical Sets" list.
class HistoricalSet {
  final DateTime date;
  final double weight;
  final int reps;
  final double estimated1RM;

  const HistoricalSet({
    required this.date,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class MovementDetailState {
  final bool isLoading;
  final String? error;
  final MovementStats stats;
  final List<VolumeData> oneRMHistory;
  final List<VolumeData> volumeHistory;
  final List<HistoricalSet> bestSets;

  const MovementDetailState({
    this.isLoading = false,
    this.error,
    this.stats = MovementStats.empty,
    this.oneRMHistory = const [],
    this.volumeHistory = const [],
    this.bestSets = const [],
  });

  /// True when data has been loaded at least once (even if empty).
  bool get hasLoaded => !isLoading && error == null;

  /// True when we have chartable data.
  bool get hasChartData => oneRMHistory.isNotEmpty || volumeHistory.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Provider (family: keyed by exercise name)
// ---------------------------------------------------------------------------

final movementDetailProvider = StateNotifierProvider.family<
    MovementDetailNotifier, MovementDetailState, String>(
  (ref, exerciseName) => MovementDetailNotifier(exerciseName),
);

class MovementDetailNotifier extends StateNotifier<MovementDetailState> {
  final String exerciseName;

  MovementDetailNotifier(this.exerciseName)
      : super(const MovementDetailState());

  /// Fetches the last 50 workout sessions, filters by [exerciseName]
  /// (case-insensitive), and computes stats, chart data, and best sets.
  Future<void> loadHistory() async {
    state = const MovementDetailState(isLoading: true);

    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConstants.workoutHistory,
        queryParams: {'limit': 50},
      );

      final data =
          response['data'] as Map<String, dynamic>? ?? response;
      final sessions =
          (data['sessions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];

      _processSessions(sessions);
    } catch (e) {
      state = MovementDetailState(error: e.toString());
    }
  }

  void _processSessions(List<Map<String, dynamic>> sessions) {
    // Sort by start time ascending for chronological charts
    sessions.sort((a, b) {
      final aTime =
          readDateTimeOrNull(a, 'start_time', 'startTime') ?? DateTime.now();
      final bTime =
          readDateTimeOrNull(b, 'start_time', 'startTime') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    final volumePoints = <VolumeData>[];
    final oneRMPoints = <VolumeData>[];
    final allSets = <HistoricalSet>[];

    var totalReps = 0;
    var totalSetsCount = 0;
    var maxWeight = 0.0;
    var maxVolume = 0.0;

    for (final session in sessions) {
      final logs = (session['exerciseLogs'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      if (logs.isEmpty) continue;

      // Filter logs matching the exercise name (case-insensitive)
      final relevantLogs = logs.where((log) {
        final name = (log['exerciseName'] as String? ?? '').toLowerCase();
        return name == exerciseName.toLowerCase();
      }).toList();

      if (relevantLogs.isEmpty) continue;

      final sessionDate =
          readDateTimeOrNull(session, 'start_time', 'startTime') ??
              DateTime.now();
      var sessionVolume = 0.0;
      var sessionMax1RM = 0.0;

      for (final log in relevantLogs) {
        final reps = log['reps'] as int? ?? 0;
        final weight = (log['weight'] as num?)?.toDouble() ?? 0.0;

        if (reps <= 0 || weight <= 0) continue;

        final volume = weight * reps;
        sessionVolume += volume;

        // Brzycki formula for estimated 1RM
        // e1RM = weight / (1.0278 - 0.0278 * reps)
        final e1RM = weight / (1.0278 - (0.0278 * reps));

        if (e1RM > sessionMax1RM) {
          sessionMax1RM = e1RM;
        }

        if (weight > maxWeight) {
          maxWeight = weight;
        }

        totalReps += reps;
        totalSetsCount += 1;

        allSets.add(HistoricalSet(
          date: sessionDate,
          weight: weight,
          reps: reps,
          estimated1RM: e1RM,
        ));
      }

      if (sessionVolume > 0) {
        volumePoints.add(VolumeData(date: sessionDate, volume: sessionVolume));
        if (sessionVolume > maxVolume) {
          maxVolume = sessionVolume;
        }
      }

      if (sessionMax1RM > 0) {
        oneRMPoints.add(VolumeData(date: sessionDate, volume: sessionMax1RM));
      }
    }

    // Top 10 best sets by estimated 1RM (descending)
    allSets.sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
    final bestSets = allSets.take(10).toList();

    state = MovementDetailState(
      stats: MovementStats(
        totalReps: totalReps,
        totalSets: totalSetsCount,
        maxWeight: maxWeight,
        maxVolume: maxVolume,
      ),
      oneRMHistory: oneRMPoints,
      volumeHistory: volumePoints,
      bestSets: bestSets,
    );
  }

  /// Convenience to reload.
  Future<void> refresh() => loadHistory();
}
