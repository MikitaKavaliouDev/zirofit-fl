import 'package:zirofit_fl/data/models/client_exercise_log.dart';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Type of personal record that was broken.
enum NewRecordType {
  /// Highest weight ever for this exercise.
  weight,
  /// Highest volume (weight × reps) ever.
  volume,
  /// Most reps at the current weight.
  reps,
  /// Highest estimated 1RM (Epley formula).
  oneRM,
}

/// A record entry with the recorded value and the date it was achieved.
class RecordEntry {
  final double value;
  final DateTime date;

  const RecordEntry({required this.value, required this.date});

  @override
  String toString() => 'RecordEntry(value: $value, date: $date)';
}

/// Result returned when a new personal record is detected after completing a
/// set.
class NewRecordResult {
  final String exerciseId;
  final String exerciseName;
  final NewRecordType recordType;
  final RecordEntry previousRecord;
  final RecordEntry newRecord;

  const NewRecordResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.previousRecord,
    required this.newRecord,
  });

  @override
  String toString() =>
      'NewRecordResult(exerciseId: $exerciseId, exerciseName: $exerciseName, '
      'recordType: $recordType, previousRecord: $previousRecord, '
      'newRecord: $newRecord)';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Detects new personal records by comparing current set data with historical
/// exercise logs.
///
/// Uses four criteria ordered by significance:
///   1. **Estimated 1RM** (primary metric) — Epley formula: weight × (1 + reps/30)
///   2. **Highest weight** ever lifted for this exercise
///   3. **Highest volume** (weight × reps) ever accumulated in a single set
///   4. **Most reps** at the current weight
///
/// The first criterion that qualifies as a record is returned, with estimated
/// 1RM taking precedence (matching the iOS reference behaviour).
///
/// This is a **plain Dart class** (not a Riverpod provider).  Data dependencies
/// are injected as constructor callbacks, which makes the service unit-testable
/// and fully decoupled from the widget tree.
///
/// ## Edge cases handled
/// - **No history** (first time doing the exercise) — treated as a new record
///   for all criteria; previous value is reported as `0`.
/// - **Zero weight or reps** — returns `null` because no meaningful record
///   can be established from an empty set.
class NewRecordDetectionService {
  final Future<List<ClientExerciseLog>> Function(String exerciseId)
      _getHistoricalLogs;
  final String? Function(String exerciseId)? _getExerciseName;

  /// Tolerance used when comparing weight values for the "most reps at weight"
  /// criterion to avoid floating-point mismatches.
  static const double _weightEpsilon = 0.001;

  /// [getHistoricalLogs] is required and should return all past exercise logs
  /// for a given [exerciseId].  The caller is responsible for scoping the
  /// query to the current user/client.
  ///
  /// [getExerciseName] is an optional lookup that maps an [exerciseId] to its
  /// display name.  If omitted, the service falls back to the most recent
  /// non-null `exerciseName` found in the historical logs.
  NewRecordDetectionService({
    required Future<List<ClientExerciseLog>> Function(String exerciseId)
        getHistoricalLogs,
    String? Function(String exerciseId)? getExerciseName,
    String? Function(String exerciseId)? exerciseNameLookup,
  })  : _getHistoricalLogs = getHistoricalLogs,
        _getExerciseName = getExerciseName ?? exerciseNameLookup;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Checks whether the given [weight] and [reps] for [exerciseId] constitute
  /// a new personal record.
  ///
  /// Returns `null` when no record is broken or when the input is invalid
  /// (zero weight or reps).
  Future<NewRecordResult?> checkForNewRecord(
    String exerciseId,
    double weight,
    int reps,
  ) async {
    // Edge case: cannot set a record with zero values
    if (weight <= 0 || reps <= 0) return null;

    // Fetch historical logs for this exercise
    final allLogs = await _getHistoricalLogs(exerciseId);

    // Filter to completed logs with valid, non-zero weight and reps
    final validLogs = allLogs.where((log) {
      return log.isCompleted == true &&
          log.weight != null &&
          log.weight! > 0 &&
          log.reps != null &&
          log.reps! > 0;
    }).toList();

    // Resolve the exercise display name
    final exerciseName = _resolveExerciseName(exerciseId, allLogs);

    // Compute current-set metrics
    final currentVolume = weight * reps;
    final currentOneRM = _epleyOneRM(weight, reps);

    // Collect best historical values for each criterion
    final bestWeight = _findBestWeight(validLogs);
    final bestVolume = _findBestVolume(validLogs);
    final bestRepsAtWeight = _findBestRepsAtWeight(validLogs, weight);
    final bestOneRM = _findBestOneRM(validLogs);

    // ------------------------------------------------------------------
    // Evaluate each criterion in priority order (1RM > weight > volume > reps)
    // ------------------------------------------------------------------

    // 1. Estimated 1RM — primary PR metric (matching iOS behaviour)
    if (bestOneRM == null || currentOneRM > bestOneRM.value) {
      return NewRecordResult(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: NewRecordType.oneRM,
        previousRecord: bestOneRM ??
            RecordEntry(value: 0, date: DateTime(2000)),
        newRecord: RecordEntry(value: currentOneRM, date: DateTime.now()),
      );
    }

    // 2. Highest weight ever
    if (bestWeight == null || weight > bestWeight.value) {
      return NewRecordResult(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: NewRecordType.weight,
        previousRecord: bestWeight ??
            RecordEntry(value: 0, date: DateTime(2000)),
        newRecord: RecordEntry(value: weight, date: DateTime.now()),
      );
    }

    // 3. Highest volume ever (weight × reps)
    if (bestVolume == null || currentVolume > bestVolume.value) {
      return NewRecordResult(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: NewRecordType.volume,
        previousRecord: bestVolume ??
            RecordEntry(value: 0, date: DateTime(2000)),
        newRecord: RecordEntry(value: currentVolume, date: DateTime.now()),
      );
    }

    // 4. Most reps at the current weight
    if (bestRepsAtWeight == null || reps > bestRepsAtWeight.value) {
      return NewRecordResult(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: NewRecordType.reps,
        previousRecord: bestRepsAtWeight ??
            RecordEntry(value: 0, date: DateTime(2000)),
        newRecord:
            RecordEntry(value: reps.toDouble(), date: DateTime.now()),
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Epley formula for estimated one-rep max.
  double _epleyOneRM(double weight, int reps) {
    return weight * (1 + reps / 30);
  }

  /// Finds the highest weight ever recorded across [logs].
  RecordEntry? _findBestWeight(List<ClientExerciseLog> logs) {
    if (logs.isEmpty) return null;
    RecordEntry? best;
    for (final log in logs) {
      final w = log.weight!;
      if (best == null || w > best.value) {
        best = RecordEntry(value: w, date: log.createdAt);
      }
    }
    return best;
  }

  /// Finds the highest volume (weight × reps) ever recorded.
  RecordEntry? _findBestVolume(List<ClientExerciseLog> logs) {
    if (logs.isEmpty) return null;
    RecordEntry? best;
    for (final log in logs) {
      final volume = log.weight! * log.reps!;
      if (best == null || volume > best.value) {
        best = RecordEntry(value: volume, date: log.createdAt);
      }
    }
    return best;
  }

  /// Finds the most reps performed at [targetWeight].
  ///
  /// Uses [_weightEpsilon] for floating-point-safe equality comparison.
  RecordEntry? _findBestRepsAtWeight(
    List<ClientExerciseLog> logs,
    double targetWeight,
  ) {
    RecordEntry? best;
    for (final log in logs) {
      if ((log.weight! - targetWeight).abs() > _weightEpsilon) continue;
      final r = log.reps!;
      if (best == null || r > best.value) {
        best = RecordEntry(value: r.toDouble(), date: log.createdAt);
      }
    }
    return best;
  }

  /// Finds the highest estimated 1RM ever recorded using the Epley formula.
  RecordEntry? _findBestOneRM(List<ClientExerciseLog> logs) {
    if (logs.isEmpty) return null;
    RecordEntry? best;
    for (final log in logs) {
      final e1rm = _epleyOneRM(log.weight!, log.reps!);
      if (best == null || e1rm > best.value) {
        best = RecordEntry(value: e1rm, date: log.createdAt);
      }
    }
    return best;
  }

  /// Resolves the exercise name from the optional lookup callback, then from
  /// historical logs, and finally falls back to the raw [exerciseId].
  String _resolveExerciseName(
    String exerciseId,
    List<ClientExerciseLog> logs,
  ) {
    // 1. Try the optional lookup callback
    final fromCallback = _getExerciseName?.call(exerciseId);
    if (fromCallback != null && fromCallback.isNotEmpty) return fromCallback;

    // 2. Try the most recent non-empty exerciseName from historical logs
    //    (iterate in reverse so the most recent name wins)
    for (int i = logs.length - 1; i >= 0; i--) {
      final name = logs[i].exerciseName;
      if (name != null && name.isNotEmpty) return name;
    }

    // 3. Fallback to the exercise ID itself
    return exerciseId;
  }
}
