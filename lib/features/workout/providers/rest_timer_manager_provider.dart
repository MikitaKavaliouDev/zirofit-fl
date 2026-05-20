import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final restTimerManagerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

/// Stream provider that emits the [activeSetId] (or null) whenever a rest
/// period finishes naturally (remainingTime reaches 0). Listeners can use
/// this to trigger UI alerts, haptics, or push notifications.
final restTimerFinishedProvider = StreamProvider<String?>((ref) {
  return ref.watch(restTimerManagerProvider.notifier).onRestFinished;
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RestTimerState {
  /// Seconds remaining in the current rest period.
  final int remainingTime;

  /// Total duration the rest period was started with (seconds).
  final int totalTime;

  /// Whether the countdown is actively ticking.
  final bool isRunning;

  /// The ID of the set that triggered this rest period, if any.
  final String? activeSetId;

  const RestTimerState({
    this.remainingTime = 0,
    this.totalTime = 0,
    this.isRunning = false,
    this.activeSetId,
  });

  RestTimerState copyWith({
    int? remainingTime,
    int? totalTime,
    bool? isRunning,
    String? activeSetId,
    bool clearSetId = false,
  }) {
    return RestTimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      totalTime: totalTime ?? this.totalTime,
      isRunning: isRunning ?? this.isRunning,
      activeSetId: clearSetId ? null : (activeSetId ?? this.activeSetId),
    );
  }

  // ---------------------------------------------------------------------------
  // Computed helpers (mirror iOS convenience)
  // ---------------------------------------------------------------------------

  /// Progress from 0.0 (just started) to 1.0 (finished).
  double get progress =>
      totalTime > 0 ? (remainingTime / totalTime).clamp(0.0, 1.0) : 0.0;

  /// Formatted MM:SS string.
  String get formattedTime {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// True when the countdown has reached zero.
  bool get isFinished => remainingTime <= 0 && totalTime > 0;

  /// Whether a rest timer is actively running or paused with remaining time.
  bool get hasRemainingTime => remainingTime > 0;

  /// Whether the timer is paused (has remaining but not ticking).
  bool get isPaused => !isRunning && remainingTime > 0;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  /// Broadcast stream for rest-finished events.
  final StreamController<String?> _onRestFinishedController =
      StreamController<String?>.broadcast();

  RestTimerNotifier()
      : super(const RestTimerState(
          remainingTime: 90, // Default 90 seconds (matches iOS default)
          totalTime: 90,
          isRunning: false,
        ));

  /// Stream that emits the [activeSetId] (or null) each time a rest period
  /// finishes naturally. Listeners can trigger dialogs, haptics, sounds, or
  /// push notifications.
  Stream<String?> get onRestFinished => _onRestFinishedController.stream;

  // ---------------------------------------------------------------------------
  // iOS-aligned: start(duration:setId:)
  // ---------------------------------------------------------------------------

  /// Starts (or restarts) the rest timer with the given [duration] in seconds
  /// and an optional [setId] that identifies which set triggered the rest.
  ///
  /// Mirrors iOS `RestTimerManager.start(duration:setId:)`.
  void start({required int duration, String? setId}) {
    _timer?.cancel();

    state = RestTimerState(
      remainingTime: duration,
      totalTime: duration,
      isRunning: true,
      activeSetId: setId,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  // ---------------------------------------------------------------------------
  // iOS-aligned: stop()
  // ---------------------------------------------------------------------------

  /// Stops the rest timer and resets all state to zero/idle.
  ///
  /// Mirrors iOS `RestTimerManager.stop()`.
  void stop() {
    _timer?.cancel();
    _timer = null;
    state = const RestTimerState(isRunning: false);
  }

  // ---------------------------------------------------------------------------
  // Pause / Resume
  // ---------------------------------------------------------------------------

  /// Pauses the countdown without resetting remaining time.
  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  /// Resumes a paused countdown.
  void resume() {
    if (state.isRunning || state.remainingTime <= 0) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Toggles between pause and resume.
  void togglePause() {
    if (state.isRunning) {
      pause();
    } else if (state.remainingTime > 0) {
      resume();
    }
  }

  // ---------------------------------------------------------------------------
  // Time manipulation
  // ---------------------------------------------------------------------------

  /// Adds (or subtracts) [delta] seconds from the current remaining time.
  /// Clamps the result between 0 and 600 seconds (10 minutes max) to match
  /// the existing UI sheet behavior.
  void addTime(int delta) {
    final newTime = (state.remainingTime + delta).clamp(0, 600);
    final newTotal = newTime > state.totalTime ? newTime : state.totalTime;

    state = state.copyWith(
      remainingTime: newTime,
      totalTime: newTotal,
    );

    // If adding time to a finished timer and it's not running, auto-resume
    if (state.isFinished && !state.isRunning && delta > 0) {
      resume();
    }

    // If we drained all time while running, stop cleanly
    if (newTime <= 0 && state.isRunning) {
      _finish();
    }
  }

  /// Resets the timer to the given [seconds] and (re)starts the countdown.
  ///
  /// Mirrors the iOS preset / custom-duration reset behaviour.
  void resetTimer(int seconds) {
    _timer?.cancel();

    state = RestTimerState(
      remainingTime: seconds,
      totalTime: seconds,
      isRunning: true,
      activeSetId: state.activeSetId, // Preserve the set context
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Decrements the remaining time each second. When it hits 0, fires the
  /// rest-finished stream and stops the timer.
  void tick() {
    if (state.remainingTime > 1) {
      state = state.copyWith(remainingTime: state.remainingTime - 1);
    } else {
      _finish();
    }
  }

  /// Called when the countdown reaches zero.
  void _finish() {
    _timer?.cancel();
    _timer = null;

    final setId = state.activeSetId;

    state = RestTimerState(
      remainingTime: 0,
      totalTime: state.totalTime,
      isRunning: false,
      activeSetId: setId,
    );

    debugPrint('REST_FINISHED: setId=$setId');

    // Notify listeners (UI can show alert, trigger haptics, push notification)
    if (!_onRestFinishedController.isClosed) {
      _onRestFinishedController.add(setId);
    }
  }

  /// Resets to initial default state (90s, idle).
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = const RestTimerState(
      remainingTime: 90,
      totalTime: 90,
      isRunning: false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _onRestFinishedController.close();
    super.dispose();
  }
}
