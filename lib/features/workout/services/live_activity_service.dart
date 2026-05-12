import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'live_activity_data.dart';

/// Service for managing iOS Live Activity / Dynamic Island during workouts.
///
/// Communicates with the native iOS layer via MethodChannel to start, update,
/// and end Live Activities using Apple's ActivityKit framework.
///
/// ## Architecture
/// ```
/// Dart (this service)  →  MethodChannel  →  Swift LiveActivityManager  →  ActivityKit
/// ```
///
/// ## Supported view modes
/// - **Compact leading/trailing**: Exercise icon + timer or rest countdown
/// - **Expanded**: Full workout details with weight/reps steppers + complete button
/// - **Minimal**: Pinpoint view in crowded Dynamic Island
/// - **Lock Screen / Banner**: Full-width workout status with controls
///
/// ## Usage
/// ```dart
/// final liveActivity = LiveActivityService();
///
/// // Start a new Live Activity
/// await liveActivity.startActivity(
///   LiveActivityData(
///     clientName: 'Personal Workout',
///     startTime: DateTime.now(),
///     workoutMode: 'personal',
///     currentExercise: 'Bench Press',
///     currentExerciseIndex: 1,
///     totalExercisesCount: 8,
///     currentSetIndex: 1,
///     totalSetsCount: 4,
///     currentReps: 10,
///     currentWeight: 80.0,
///   ),
/// );
///
/// // Update during workout
/// await liveActivity.updateActivity(
///   LiveActivityData(currentSetIndex: 2),
/// );
///
/// // Start rest timer
/// await liveActivity.updateActivity(
///   LiveActivityData(isResting: true, restSeconds: 90, totalRestSeconds: 90),
/// );
///
/// // End workout
/// await liveActivity.endActivity(summary: '45 min · 12 sets · 4500 kg');
/// ```
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel(
    'com.zirofit.fl/live_activity',
  );

  static const LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  const LiveActivityService._internal();

  // MARK: - Feature Support

  /// Whether Live Activities are supported on this device (iOS 16.1+).
  Future<bool> get isSupported async {
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] isSupported error: $e');
      return false;
    }
  }

  // MARK: - Start Activity

  /// Starts a new Live Activity with the given [data].
  ///
  /// The [data] should include at minimum:
  /// - `clientName`, `startTime`, `workoutMode` (static attributes)
  /// - `currentExercise`, `currentExerciseIndex`, `totalExercisesCount`
  /// - `currentSetIndex`, `totalSetsCount`
  ///
  /// If a Live Activity is already active, it will be updated instead of
  /// replaced (native side handles this automatically).
  ///
  /// Returns `true` if the activity was successfully started/updated.
  Future<bool> startActivity(LiveActivityData data) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startActivity',
        data.toJson(),
      );
      debugPrint('[LiveActivity] Started: $result');
      return result ?? false;
    } on MissingPluginException {
      debugPrint('[LiveActivity] Not supported on this platform');
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] startActivity error: $e');
      return false;
    }
  }

  /// Convenience method: starts a Live Activity from a [WorkoutSession].
  ///
  /// Maps the session's fields to the `LiveActivityData` model. If a more
  /// detailed setup is needed (exercise index, sets, etc.), use
  /// [startActivity] directly with a fully populated `LiveActivityData`.
  Future<bool> startWorkout(WorkoutSession session) async {
    final data = LiveActivityData(
      clientName: session.name ?? 'Workout',
      startTime: session.startTime,
      workoutMode: session.isTrainerLed ? 'trainer' : 'personal',
      workoutStartDate: session.startTime,
      currentExercise: session.name ?? 'Workout',
      currentExerciseIndex: 1,
      totalExercisesCount: 1,
      currentSetIndex: 1,
      totalSetsCount: 1,
    );
    return startActivity(data);
  }

  // MARK: - Update Activity

  /// Updates the current Live Activity with new [data].
  ///
  /// Only the fields present in [data] will be sent to the native side.
  /// Fields with null values are omitted, so partial updates are natural:
  ///
  /// ```dart
  /// // Update just the set index
  /// await liveActivity.updateActivity(
  ///   LiveActivityData(currentSetIndex: 3),
  /// );
  ///
  /// // Update rest timer
  /// await liveActivity.updateActivity(
  ///   LiveActivityData(isResting: true, restSeconds: 90),
  /// );
  /// ```
  ///
  /// Returns `true` if the activity was successfully updated.
  Future<bool> updateActivity(LiveActivityData data) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateActivity',
        data.toJson(),
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] updateActivity error: $e');
      return false;
    }
  }

  /// Convenience method: updates just the exercise info.
  ///
  /// Shorthand for:
  /// ```dart
  /// updateActivity(LiveActivityData(
  ///   currentExercise: exerciseName,
  ///   currentSetIndex: setCount,
  ///   totalSetsCount: totalSets,
  /// ));
  /// ```
  Future<bool> updateExercise({
    required String exerciseName,
    int setCount = 0,
    int totalSets = 0,
    int exerciseIndex = 0,
    int totalExercises = 0,
    double reps = 0,
    double weight = 0,
  }) async {
    return updateActivity(
      LiveActivityData(
        currentExercise: exerciseName,
        currentSetIndex: setCount,
        totalSetsCount: totalSets,
        currentExerciseIndex: exerciseIndex,
        totalExercisesCount: totalExercises,
        currentReps: reps,
        currentWeight: weight,
      ),
    );
  }

  /// Convenience method: updates just the rest timer.
  ///
  /// Sets [isResting] to `true` automatically when [secondsRemaining] > 0.
  /// Pass [secondsRemaining] = 0 to clear the rest timer.
  Future<bool> updateRestTimer(int secondsRemaining) async {
    return updateActivity(
      LiveActivityData(
        isResting: secondsRemaining > 0,
        restSeconds: secondsRemaining,
        restFormattedTime: _formatTime(secondsRemaining),
      ),
    );
  }

  /// Sets the rest timer with full rest tracking info.
  ///
  /// Unlike [updateRestTimer], this also sets [totalRestSeconds] for the
  /// progress bar display and [nextExerciseName] to show what's coming next.
  Future<bool> setRestTimer({
    required int secondsRemaining,
    int totalSeconds = 0,
    String? nextExerciseName,
  }) async {
    return updateActivity(
      LiveActivityData(
        isResting: secondsRemaining > 0,
        restSeconds: secondsRemaining,
        totalRestSeconds: totalSeconds > 0 ? totalSeconds : secondsRemaining,
        restFormattedTime: _formatTime(secondsRemaining),
        nextExerciseName: nextExerciseName,
      ),
    );
  }

  // MARK: - End Activity

  /// Ends the Live Activity for the workout.
  ///
  /// The activity will be removed from the Dynamic Island and Lock Screen.
  /// On iOS 16.2+, a brief dismissal animation is shown.
  ///
  /// An optional [summary] string can be provided to show a brief message
  /// before the activity is dismissed (e.g. "Workout Complete · 12 sets").
  Future<bool> endActivity({String? summary}) async {
    try {
      final args = <String, dynamic>{};
      if (summary != null) {
        args['summary'] = summary;
      }

      final result = await _channel.invokeMethod<bool>(
        'endActivity',
        args,
      );
      debugPrint('[LiveActivity] Ended: $result');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] endActivity error: $e');
      return false;
    }
  }

  /// Convenience method: ends the Live Activity with workout summary data.
  ///
  /// Builds a summary string from the provided stats before dismissing.
  Future<bool> endWithSummary({
    required Duration duration,
    int totalSets = 0,
    double totalVolume = 0,
  }) async {
    final parts = <String>[
      '${duration.inMinutes} min',
      if (totalSets > 0) '$totalSets sets',
      if (totalVolume > 0) '${totalVolume.toStringAsFixed(0)} kg',
    ];

    return endActivity(summary: parts.join(' · '));
  }

  /// Alias for [endActivity] for backward compatibility.
  Future<bool> endWorkout({String? summary}) => endActivity(summary: summary);

  // MARK: - Private Helpers

  /// Formats seconds as "MM:SS" for display.
  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
