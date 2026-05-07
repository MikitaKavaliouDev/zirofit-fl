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
/// ## Supported view modes
/// - **Compact leading/trailing**: Shows exercise name + rest timer
/// - **Expanded**: Shows full workout details (sets, elapsed time, rest)
/// - **Minimal**: Pinpoint view in Dynamic Island
///
/// ## Usage
/// ```dart
/// final liveActivity = LiveActivityService();
/// await liveActivity.startWorkout(session);
/// await liveActivity.updateExercise('Bench Press', setCount: 3);
/// await liveActivity.updateRestTimer(45);
/// await liveActivity.endWorkout();
/// ```
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel(
    'com.zirofit.fl/live_activity',
  );

  static const LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  const LiveActivityService._internal();

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

  /// Starts a new Live Activity when a workout begins.
  ///
  /// Creates an ActivityKit activity on iOS that appears in the Dynamic Island
  /// and on the Lock Screen. The activity shows:
  /// - **Compact**: Current exercise name (trailing) and rest indicator (leading)
  /// - **Expanded**: Full workout details
  ///
  /// If an activity is already active, it will be updated rather than replaced.
  Future<bool> startWorkout(WorkoutSession session) async {
    try {
      final data = LiveActivityData(
        activityId: session.id,
        exerciseName: session.name ?? 'Workout',
        elapsedSeconds:
            DateTime.now().difference(session.startTime).inSeconds,
      );

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
      debugPrint('[LiveActivity] startWorkout error: $e');
      return false;
    }
  }

  /// Updates the Live Activity with the current exercise and set progress.
  ///
  /// The Dynamic Island compact view shows the exercise name on the trailing
  /// side. The expanded view shows exercise name, set count, and elapsed time.
  Future<bool> updateExercise({
    required String exerciseName,
    int setCount = 0,
    int totalSets = 0,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateActivity',
        LiveActivityData(
          exerciseName: exerciseName,
          setCount: setCount,
          totalSets: totalSets,
        ).toJson(),
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] updateExercise error: $e');
      return false;
    }
  }

  /// Updates the Live Activity with the current rest timer countdown.
  ///
  /// The Dynamic Island shows the remaining rest time in the compact view.
  /// When rest reaches 0, the activity returns to showing just the exercise.
  Future<bool> updateRestTimer(int secondsRemaining) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateActivity',
        LiveActivityData(
          restSeconds: secondsRemaining,
        ).toJson(),
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] updateRestTimer error: $e');
      return false;
    }
  }

  /// Updates both exercise info and rest timer in one call.
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

  /// Ends the Live Activity when the workout completes.
  ///
  /// The Live Activity will be removed from the Dynamic Island and Lock Screen.
  /// On iOS 16.2+, the activity can show a "completed" state briefly before
  /// being dismissed.
  Future<bool> endWorkout({String? summary}) async {
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
      debugPrint('[LiveActivity] endWorkout error: $e');
      return false;
    }
  }

  /// Ends the Live Activity with the final workout summary data.
  Future<bool> endWithSummary({
    required Duration duration,
    int totalSets = 0,
    double totalVolume = 0,
  }) async {
    try {
      final args = <String, dynamic>{
        'summary':
            '${duration.inMinutes} min · $totalSets sets · ${totalVolume.toStringAsFixed(0)} kg',
      };

      final result = await _channel.invokeMethod<bool>(
        'endActivity',
        args,
      );
      debugPrint('[LiveActivity] Ended with summary: $result');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LiveActivity] endWithSummary error: $e');
      return false;
    }
  }
}
