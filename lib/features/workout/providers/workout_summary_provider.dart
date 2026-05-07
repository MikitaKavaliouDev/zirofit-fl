import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final workoutSummaryProvider = StateNotifierProvider<
    WorkoutSummaryNotifier, WorkoutSummaryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutSummaryNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// PersonalRecord (local summary model)
// ---------------------------------------------------------------------------

/// A personal record detected by comparing current workout sets against
/// historical data. This is distinct from the data-layer [PersonalRecord]
/// model used for persistence.
class PersonalRecord {
  final String exerciseName;
  final String type; // 'weight', 'volume', or 'reps'
  final double value;
  final double previousValue;

  const PersonalRecord({
    required this.exerciseName,
    required this.type,
    required this.value,
    required this.previousValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecord &&
          exerciseName == other.exerciseName &&
          type == other.type &&
          value == other.value &&
          previousValue == other.previousValue;

  @override
  int get hashCode => Object.hash(exerciseName, type, value, previousValue);

  @override
  String toString() =>
      'PersonalRecord(exerciseName: $exerciseName, type: $type, '
      'value: $value, previousValue: $previousValue)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorkoutSummaryState {
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final Duration duration;
  final List<PersonalRecord> personalRecords;
  final WorkoutSet? bestSet;
  final List<ExerciseSummary> exerciseSummaries;

  const WorkoutSummaryState({
    this.totalVolume = 0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.duration = Duration.zero,
    this.personalRecords = const [],
    this.bestSet,
    this.exerciseSummaries = const [],
  });

  WorkoutSummaryState copyWith({
    double? totalVolume,
    int? totalSets,
    int? totalReps,
    Duration? duration,
    List<PersonalRecord>? personalRecords,
    WorkoutSet? bestSet,
    List<ExerciseSummary>? exerciseSummaries,
  }) {
    return WorkoutSummaryState(
      totalVolume: totalVolume ?? this.totalVolume,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      duration: duration ?? this.duration,
      personalRecords: personalRecords ?? this.personalRecords,
      bestSet: bestSet ?? this.bestSet,
      exerciseSummaries: exerciseSummaries ?? this.exerciseSummaries,
    );
  }

  /// Whether any summary data has been computed.
  bool get isEmpty =>
      totalVolume == 0 &&
      totalSets == 0 &&
      totalReps == 0 &&
      duration == Duration.zero &&
      exerciseSummaries.isEmpty;

  /// Whether the summary contains meaningful data.
  bool get isNotEmpty => !isEmpty;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WorkoutSummaryNotifier extends StateNotifier<WorkoutSummaryState> {
  final ApiClient? _api;

  WorkoutSummaryNotifier({ApiClient? apiClient})
      : _api = apiClient,
        super(const WorkoutSummaryState());

  /// Saves the workout session as a reusable template.
  ///
  /// POSTs to `/workout-sessions/{sessionId}/save-as-template` with an
  /// optional [name]. Throws on failure.
  Future<void> saveAsTemplate(String sessionId, {String? name}) async {
    final api = _api ?? ApiClient.instance;
    await api.post(
      ApiConstants.workoutSaveAsTemplate(sessionId),
      body: {'name': name},
    );
  }

  /// Processes completed sets from a workout session and updates the summary
  /// state with computed totals, the best set, and per-exercise summaries.
  ///
  /// [exerciseNamesByLogId] maps a [WorkoutSet.logId] to a human-readable
  /// exercise name. When omitted, the logId itself is used as the name.
  void calculateSummary(
    WorkoutSession session, {
    required List<WorkoutSet> completedSets,
    Map<String, String>? exerciseNamesByLogId,
  }) {
    final names = exerciseNamesByLogId ?? const {};
    final totalVolume = _calculateTotalVolume(completedSets);
    final totalSets = _calculateTotalSets(completedSets);
    final totalReps = _calculateTotalReps(completedSets);
    final duration = _calculateDuration(session);
    final bestSet = findBestSet(completedSets);
    final exerciseSummaries = _buildExerciseSummaries(completedSets, names);

    state = WorkoutSummaryState(
      totalVolume: totalVolume,
      totalSets: totalSets,
      totalReps: totalReps,
      duration: duration,
      personalRecords: state.personalRecords,
      bestSet: bestSet,
      exerciseSummaries: exerciseSummaries,
    );
  }

  /// Replaces the list of personal records in the current state.
  void updatePersonalRecords(List<PersonalRecord> records) {
    state = state.copyWith(personalRecords: records);
  }

  /// Resets the state back to its initial empty values.
  void reset() {
    state = const WorkoutSummaryState();
  }

  // ---------------------------------------------------------------------------
  // Pure computation methods
  // ---------------------------------------------------------------------------

  /// Finds the best set — the one with the highest volume (weight × reps).
  /// Returns `null` when [sets] is empty or contains no completed sets with
  /// both weight and reps.
  WorkoutSet? findBestSet(List<WorkoutSet> sets) {
    WorkoutSet? best;
    double bestVolume = 0;

    for (final set in sets) {
      if (!set.isCompleted || set.weight == null || set.reps == null) continue;
      final volume = set.weight! * set.reps!;
      if (volume > bestVolume) {
        bestVolume = volume;
        best = set;
      }
    }

    return best;
  }

  /// Detects personal records by comparing completed sets from the current
  /// workout against historical sets.
  ///
  /// For each exercise (identified by name via [exerciseNamesByLogId]), this
  /// compares the maximum per-set weight and maximum per-set volume to their
  /// historical counterparts. Records are returned only when the current value
  /// strictly exceeds the historical best.
  List<PersonalRecord> detectPRs({
    required List<WorkoutSet> currentSets,
    required List<WorkoutSet> historicalSets,
    required Map<String, String> exerciseNamesByLogId,
  }) {
    final prs = <PersonalRecord>[];

    // Group sets by exercise name
    final currentByName = _groupSetsByExerciseName(
      currentSets,
      exerciseNamesByLogId,
    );
    final historicalByName = _groupSetsByExerciseName(
      historicalSets,
      exerciseNamesByLogId,
    );

    for (final entry in currentByName.entries) {
      final exerciseName = entry.key;
      final currentGroup = entry.value;
      final historicalGroup = historicalByName[exerciseName] ?? [];

      // --- Weight PR ---
      final currentMaxWeight = _maxWeight(currentGroup);
      final historicalMaxWeight = _maxWeight(historicalGroup);

      if (currentMaxWeight > historicalMaxWeight && historicalMaxWeight > 0) {
        prs.add(PersonalRecord(
          exerciseName: exerciseName,
          type: 'weight',
          value: currentMaxWeight,
          previousValue: historicalMaxWeight,
        ));
      }

      // --- Volume PR (per-set volume = weight × reps) ---
      final currentMaxVolume = _maxVolume(currentGroup);
      final historicalMaxVolume = _maxVolume(historicalGroup);

      if (currentMaxVolume > historicalMaxVolume && historicalMaxVolume > 0) {
        prs.add(PersonalRecord(
          exerciseName: exerciseName,
          type: 'volume',
          value: currentMaxVolume,
          previousValue: historicalMaxVolume,
        ));
      }
    }

    return prs;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  double _calculateTotalVolume(List<WorkoutSet> sets) {
    double volume = 0;
    for (final set in sets) {
      if (!set.isCompleted || set.weight == null || set.reps == null) continue;
      volume += set.weight! * set.reps!;
    }
    return volume;
  }

  int _calculateTotalSets(List<WorkoutSet> sets) {
    return sets.where((s) => s.isCompleted && s.hasData).length;
  }

  int _calculateTotalReps(List<WorkoutSet> sets) {
    int reps = 0;
    for (final set in sets) {
      if (!set.isCompleted || set.reps == null) continue;
      reps += set.reps!;
    }
    return reps;
  }

  Duration _calculateDuration(WorkoutSession session) {
    if (session.endTime == null) return Duration.zero;
    return session.endTime!.difference(session.startTime);
  }

  List<ExerciseSummary> _buildExerciseSummaries(
    List<WorkoutSet> sets,
    Map<String, String> exerciseNamesByLogId,
  ) {
    final grouped = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      if (!set.isCompleted) continue;
      final name = exerciseNamesByLogId[set.logId] ?? set.logId;
      grouped.putIfAbsent(name, () => []).add(set);
    }

    return grouped.entries.map((entry) {
      final name = entry.key;
      final exerciseSets = entry.value;

      final totalReps = exerciseSets
          .where((s) => s.reps != null)
          .fold(0, (int sum, s) => sum + s.reps!);

      double totalVolume = 0;
      double bestWeight = 0;
      for (final s in exerciseSets) {
        if (s.weight != null && s.reps != null) {
          totalVolume += s.weight! * s.reps!;
        }
        if (s.weight != null && s.weight! > bestWeight) {
          bestWeight = s.weight!;
        }
      }

      return ExerciseSummary(
        exerciseId: exerciseSets.first.logId,
        exerciseName: name,
        setsCompleted: exerciseSets.length,
        totalReps: totalReps,
        totalVolume: totalVolume,
        bestWeight: bestWeight > 0 ? bestWeight : null,
      );
    }).toList();
  }

  /// Groups a list of [WorkoutSet]s by exercise name using the provided map.
  Map<String, List<WorkoutSet>> _groupSetsByExerciseName(
    List<WorkoutSet> sets,
    Map<String, String> exerciseNamesByLogId,
  ) {
    final grouped = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      if (!set.isCompleted) continue;
      final name = exerciseNamesByLogId[set.logId] ?? set.logId;
      grouped.putIfAbsent(name, () => []).add(set);
    }
    return grouped;
  }

  double _maxWeight(List<WorkoutSet> sets) {
    double max = 0;
    for (final s in sets) {
      if (s.weight != null && s.weight! > max) max = s.weight!;
    }
    return max;
  }

  double _maxVolume(List<WorkoutSet> sets) {
    double max = 0;
    for (final s in sets) {
      if (s.weight != null && s.reps != null) {
        final vol = s.weight! * s.reps!;
        if (vol > max) max = vol;
      }
    }
    return max;
  }
}
