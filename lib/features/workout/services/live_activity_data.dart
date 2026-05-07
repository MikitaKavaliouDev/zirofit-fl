/// Data payload for updating the iOS Live Activity / Dynamic Island.
///
/// Maps directly to the ActivityKit `Activity<WorkoutActivityAttributes>`
/// content state on the native side.
class LiveActivityData {
  /// The current exercise name (e.g. "Bench Press").
  final String exerciseName;

  /// How many sets have been completed for the current exercise.
  final int setCount;

  /// Total sets planned (0 if unknown).
  final int totalSets;

  /// Remaining rest time in seconds (0 if no rest active).
  final int restSeconds;

  /// Total elapsed workout time in seconds.
  final int elapsedSeconds;

  /// Unique activity identifier; reused between start/update/end calls.
  final String activityId;

  const LiveActivityData({
    this.exerciseName = '',
    this.setCount = 0,
    this.totalSets = 0,
    this.restSeconds = 0,
    this.elapsedSeconds = 0,
    this.activityId = '',
  });

  LiveActivityData copyWith({
    String? exerciseName,
    int? setCount,
    int? totalSets,
    int? restSeconds,
    int? elapsedSeconds,
    String? activityId,
  }) {
    return LiveActivityData(
      exerciseName: exerciseName ?? this.exerciseName,
      setCount: setCount ?? this.setCount,
      totalSets: totalSets ?? this.totalSets,
      restSeconds: restSeconds ?? this.restSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      activityId: activityId ?? this.activityId,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'setCount': setCount,
        'totalSets': totalSets,
        'restSeconds': restSeconds,
        'elapsedSeconds': elapsedSeconds,
        'activityId': activityId,
      };

  factory LiveActivityData.fromJson(Map<String, dynamic> json) {
    return LiveActivityData(
      exerciseName: (json['exerciseName'] as String?) ?? '',
      setCount: (json['setCount'] as int?) ?? 0,
      totalSets: (json['totalSets'] as int?) ?? 0,
      restSeconds: (json['restSeconds'] as int?) ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as int?) ?? 0,
      activityId: (json['activityId'] as String?) ?? '',
    );
  }

  @override
  String toString() =>
      'LiveActivityData(exerciseName: $exerciseName, setCount: $setCount, '
      'totalSets: $totalSets, restSeconds: $restSeconds, '
      'elapsedSeconds: $elapsedSeconds, activityId: $activityId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveActivityData &&
          exerciseName == other.exerciseName &&
          setCount == other.setCount &&
          totalSets == other.totalSets &&
          restSeconds == other.restSeconds &&
          elapsedSeconds == other.elapsedSeconds &&
          activityId == other.activityId;

  @override
  int get hashCode => Object.hash(
        exerciseName,
        setCount,
        totalSets,
        restSeconds,
        elapsedSeconds,
        activityId,
      );
}
