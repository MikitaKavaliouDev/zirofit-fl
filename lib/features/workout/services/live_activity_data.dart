/// Data payload for the iOS Live Activity / Dynamic Island during workouts.
///
/// Maps directly to the native `WorkoutAttributes.ContentState` struct in
/// `SharedWorkoutAttributes.swift`. The data is serialized to JSON and sent
/// through the `MethodChannel('com.zirofit.fl/live_activity')` to the native
/// iOS layer which creates/updates the ActivityKit Live Activity.
///
/// ## Field mapping to native ContentState
/// | Dart field            | iOS ContentState field | Notes                         |
/// |-----------------------|------------------------|-------------------------------|
/// | workoutStartDate      | workoutStartDate       | msSinceEpoch → Date           |
/// | restSeconds           | restEndDate            | converted to Date on iOS side |
/// | totalRestSeconds      | totalRestTime          | TimeInterval on iOS           |
/// | Everything else       | 1:1 mapping            | direct pass-through           |
class LiveActivityData {
  // MARK: - Timer

  /// When the workout started (null if unknown).
  /// Used by the widget for the system-driven elapsed timer.
  final DateTime? workoutStartDate;

  // MARK: - Exercise Info

  /// Name of the current exercise (e.g. "Bench Press").
  final String? currentExercise;

  /// 1-based index of the current exercise in the workout.
  final int currentExerciseIndex;

  /// Total number of exercises in the workout.
  final int totalExercisesCount;

  /// 1-based index of the current set for the current exercise.
  final int currentSetIndex;

  /// Total number of sets planned for the current exercise.
  final int totalSetsCount;

  /// Optional set descriptor (e.g. "Warm-up", "Drop set", "Failure").
  final String? setInfo;

  /// Number of reps for the current set.
  final double currentReps;

  /// Weight in kg for the current set.
  final double currentWeight;

  // MARK: - Rest Timer

  /// Whether the user is currently resting between sets.
  final bool isResting;

  /// Remaining rest time in seconds (0 when not resting).
  /// On the native side, this is converted to `restEndDate = Date.now + restSeconds`
  /// so the system can drive the countdown automatically.
  final int restSeconds;

  /// Total rest time in seconds for this rest period (for progress bar).
  final int totalRestSeconds;

  /// Formatted rest time string for display (e.g. "01:30").
  final String restFormattedTime;

  /// Name of the next exercise to be shown during rest.
  final String? nextExerciseName;

  // MARK: - Workout Status

  /// Whether the entire workout is complete.
  final bool isWorkoutComplete;

  /// Whether the current set is the last set of this exercise.
  final bool isLastSet;

  /// Whether the workout is paused.
  final bool isPaused;

  // MARK: - Static Attributes (set once at activity creation)

  /// Client name for display (e.g. "John D." or "Personal Workout").
  /// Only used when starting a new activity.
  final String? clientName;

  /// Workout start time — used as the static `startTime` attribute.
  /// Only used when starting a new activity.
  final DateTime? startTime;

  /// Workout mode: "personal" or "trainer".
  /// Only used when starting a new activity.
  final String? workoutMode;

  // MARK: - Constructor

  const LiveActivityData({
    this.workoutStartDate,
    this.currentExercise,
    this.currentExerciseIndex = 0,
    this.totalExercisesCount = 0,
    this.currentSetIndex = 0,
    this.totalSetsCount = 0,
    this.setInfo,
    this.currentReps = 0,
    this.currentWeight = 0,
    this.isResting = false,
    this.restSeconds = 0,
    this.totalRestSeconds = 0,
    this.restFormattedTime = '00:00',
    this.nextExerciseName,
    this.isWorkoutComplete = false,
    this.isLastSet = false,
    this.isPaused = false,
    this.clientName,
    this.startTime,
    this.workoutMode,
  });

  // MARK: - copyWith

  LiveActivityData copyWith({
    DateTime? workoutStartDate,
    String? currentExercise,
    int? currentExerciseIndex,
    int? totalExercisesCount,
    int? currentSetIndex,
    int? totalSetsCount,
    String? setInfo,
    double? currentReps,
    double? currentWeight,
    bool? isResting,
    int? restSeconds,
    int? totalRestSeconds,
    String? restFormattedTime,
    String? nextExerciseName,
    bool? isWorkoutComplete,
    bool? isLastSet,
    bool? isPaused,
    String? clientName,
    DateTime? startTime,
    String? workoutMode,
  }) {
    return LiveActivityData(
      workoutStartDate: workoutStartDate ?? this.workoutStartDate,
      currentExercise: currentExercise ?? this.currentExercise,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      totalExercisesCount: totalExercisesCount ?? this.totalExercisesCount,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      totalSetsCount: totalSetsCount ?? this.totalSetsCount,
      setInfo: setInfo ?? this.setInfo,
      currentReps: currentReps ?? this.currentReps,
      currentWeight: currentWeight ?? this.currentWeight,
      isResting: isResting ?? this.isResting,
      restSeconds: restSeconds ?? this.restSeconds,
      totalRestSeconds: totalRestSeconds ?? this.totalRestSeconds,
      restFormattedTime: restFormattedTime ?? this.restFormattedTime,
      nextExerciseName: nextExerciseName ?? this.nextExerciseName,
      isWorkoutComplete: isWorkoutComplete ?? this.isWorkoutComplete,
      isLastSet: isLastSet ?? this.isLastSet,
      isPaused: isPaused ?? this.isPaused,
      clientName: clientName ?? this.clientName,
      startTime: startTime ?? this.startTime,
      workoutMode: workoutMode ?? this.workoutMode,
    );
  }

  // MARK: - Serialization

  /// Converts this data to a JSON-compatible map for the method channel.
  ///
  /// - `DateTime` values are converted to milliseconds since epoch (int).
  /// - Null values are omitted so partial updates only send changed fields.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      if (workoutStartDate != null)
        'workoutStartDate': workoutStartDate!.millisecondsSinceEpoch,
      if (currentExercise != null) 'currentExercise': currentExercise,
      'currentExerciseIndex': currentExerciseIndex,
      'totalExercisesCount': totalExercisesCount,
      'currentSetIndex': currentSetIndex,
      'totalSetsCount': totalSetsCount,
      if (setInfo != null) 'setInfo': setInfo,
      'currentReps': currentReps,
      'currentWeight': currentWeight,
      'isResting': isResting,
      'restSeconds': restSeconds,
      'totalRestSeconds': totalRestSeconds,
      'restFormattedTime': restFormattedTime,
      if (nextExerciseName != null) 'nextExerciseName': nextExerciseName,
      'isWorkoutComplete': isWorkoutComplete,
      'isLastSet': isLastSet,
      'isPaused': isPaused,
      if (clientName != null) 'clientName': clientName,
      if (startTime != null) 'startTime': startTime!.millisecondsSinceEpoch,
      if (workoutMode != null) 'workoutMode': workoutMode,
    };
    return map;
  }

  // MARK: - fromJson

  /// Creates a [LiveActivityData] from a JSON map (e.g., received from the
  /// method channel response or parsed locally).
  factory LiveActivityData.fromJson(Map<String, dynamic> json) {
    return LiveActivityData(
      workoutStartDate: _parseDate(json['workoutStartDate']),
      currentExercise: json['currentExercise'] as String?,
      currentExerciseIndex: (json['currentExerciseIndex'] as num?)?.toInt() ?? 0,
      totalExercisesCount: (json['totalExercisesCount'] as num?)?.toInt() ?? 0,
      currentSetIndex: (json['currentSetIndex'] as num?)?.toInt() ?? 0,
      totalSetsCount: (json['totalSetsCount'] as num?)?.toInt() ?? 0,
      setInfo: json['setInfo'] as String?,
      currentReps: (json['currentReps'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 0.0,
      isResting: json['isResting'] as bool? ?? false,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 0,
      totalRestSeconds: (json['totalRestSeconds'] as num?)?.toInt() ?? 0,
      restFormattedTime: json['restFormattedTime'] as String? ?? '00:00',
      nextExerciseName: json['nextExerciseName'] as String?,
      isWorkoutComplete: json['isWorkoutComplete'] as bool? ?? false,
      isLastSet: json['isLastSet'] as bool? ?? false,
      isPaused: json['isPaused'] as bool? ?? false,
      clientName: json['clientName'] as String?,
      startTime: _parseDate(json['startTime']),
      workoutMode: json['workoutMode'] as String?,
    );
  }

  /// Parses a DateTime from a milliseconds-since-epoch value (int or double).
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }

  // MARK: - Equality & Debug

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveActivityData &&
          runtimeType == other.runtimeType &&
          workoutStartDate == other.workoutStartDate &&
          currentExercise == other.currentExercise &&
          currentExerciseIndex == other.currentExerciseIndex &&
          totalExercisesCount == other.totalExercisesCount &&
          currentSetIndex == other.currentSetIndex &&
          totalSetsCount == other.totalSetsCount &&
          setInfo == other.setInfo &&
          currentReps == other.currentReps &&
          currentWeight == other.currentWeight &&
          isResting == other.isResting &&
          restSeconds == other.restSeconds &&
          totalRestSeconds == other.totalRestSeconds &&
          restFormattedTime == other.restFormattedTime &&
          nextExerciseName == other.nextExerciseName &&
          isWorkoutComplete == other.isWorkoutComplete &&
          isLastSet == other.isLastSet &&
          isPaused == other.isPaused &&
          clientName == other.clientName &&
          startTime == other.startTime &&
          workoutMode == other.workoutMode;

  @override
  int get hashCode => Object.hash(
        workoutStartDate,
        currentExercise,
        currentExerciseIndex,
        totalExercisesCount,
        currentSetIndex,
        totalSetsCount,
        setInfo,
        currentReps,
        currentWeight,
        isResting,
        restSeconds,
        totalRestSeconds,
        restFormattedTime,
        nextExerciseName,
        isWorkoutComplete,
        isLastSet,
        isPaused,
        clientName,
        startTime,
        workoutMode,
      );

  @override
  String toString() =>
      'LiveActivityData('
      'exercise: $currentExercise[$currentExerciseIndex/$totalExercisesCount], '
      'set: $currentSetIndex/$totalSetsCount, '
      'reps: $currentReps, weight: $currentWeight, '
      'resting: $isResting($restSeconds)s, '
      'paused: $isPaused, complete: $isWorkoutComplete'
      ')';
}
