import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workout timer states
enum WorkoutTimerState {
  idle,
  running,
  paused,
}

/// State data class containing both the timer state and elapsed duration.
/// This ensures that `ref.watch(workoutTimerProvider)` triggers rebuilds
/// on every tick (when elapsed changes), fixing the issue where the timer
/// display showed 00:00 forever.
class WorkoutTimerData {
  final WorkoutTimerState state;
  final Duration elapsed;

  /// Whether the long session warning banner should be displayed in the UI.
  /// Set to true when the timer first hits the 2-hour warning zone.
  /// Dismissed by [WorkoutTimerNotifier.acknowledgeLongSessionWarning].
  final bool showLongSessionWarning;

  /// Whether to show a one-time toast notification when timer hits 2 hours.
  /// Unlike [showLongSessionWarning], this is intended for a transient toast
  /// that auto-dismisses after being consumed by the UI.
  final bool showLongSessionToast;

  const WorkoutTimerData({
    required this.state,
    required this.elapsed,
    this.showLongSessionWarning = false,
    this.showLongSessionToast = false,
  });

  bool get isRunning => state == WorkoutTimerState.running;
  bool get isPaused => state == WorkoutTimerState.paused;
  bool get isIdle => state == WorkoutTimerState.idle;

  /// Formatted time string (MM:SS or H:MM:SS)
  String get formattedTime {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Progress as percentage of max duration (0.0 - 1.0)
  double get progress {
    const maxSeconds = 4 * 3600; // 4 hours
    if (maxSeconds == 0) return 0;
    return (elapsed.inSeconds / maxSeconds).clamp(0.0, 1.0);
  }

  /// Check if we're in warning zone (2+ hours)
  bool get isInWarningZone => elapsed >= const Duration(hours: 2);

  /// Check if we're at max duration
  bool get isAtMaxDuration => elapsed >= const Duration(hours: 4);

  /// Create a copy with the specified fields replaced.
  WorkoutTimerData copyWith({
    WorkoutTimerState? state,
    Duration? elapsed,
    bool? showLongSessionWarning,
    bool? showLongSessionToast,
  }) {
    return WorkoutTimerData(
      state: state ?? this.state,
      elapsed: elapsed ?? this.elapsed,
      showLongSessionWarning:
          showLongSessionWarning ?? this.showLongSessionWarning,
      showLongSessionToast: showLongSessionToast ?? this.showLongSessionToast,
    );
  }
}

/// Provider for workout timer that tracks elapsed time during active workout
class WorkoutTimerNotifier extends StateNotifier<WorkoutTimerData> {
  WorkoutTimerNotifier()
      : super(const WorkoutTimerData(
          state: WorkoutTimerState.idle,
          elapsed: Duration.zero,
        ));

  DateTime? _startTime;
  Timer? _timer;

  /// Tracks whether the 2-hour warning has already been shown to prevent
  /// repeated callbacks and duplicate UI transitions.
  bool _hasShownWarning = false;

  // Callbacks
  void Function()? on2HourWarning;
  void Function()? onLongSessionWarning;
  void Function()? on4HourAutoEnd;
  void Function()? onAutoEnd;

  // Constants
  static const Duration maxDuration = Duration(hours: 4);
  static const Duration warningDuration = Duration(hours: 2);

  // Convenience getters that delegate to state (for backward compat with
  // consumers that use notifier.formattedTime or notifier.isPaused etc.)
  Duration get elapsed => state.elapsed;
  String get formattedTime => state.formattedTime;
  double get progress => state.progress;
  bool get isInWarningZone => state.isInWarningZone;
  bool get isAtMaxDuration => state.isAtMaxDuration;
  bool get isRunning => state.isRunning;
  bool get isPaused => state.isPaused;
  bool get isIdle => state.isIdle;

  /// Start the timer with the given session start time.
  /// Computes initial elapsed from [startTime] so that resuming a session
  /// that started minutes/hours ago shows the correct elapsed time immediately.
  void start(DateTime startTime) {
    _startTime = startTime;
    final elapsed = DateTime.now().difference(startTime);
    final inWarning = elapsed >= warningDuration;

    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: elapsed,
      showLongSessionWarning: inWarning,
    );

    if (inWarning) {
      _hasShownWarning = true;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Pause the timer
  void pause() {
    if (state.state != WorkoutTimerState.running) return;

    _timer?.cancel();
    _timer = null;
    state = WorkoutTimerData(
      state: WorkoutTimerState.paused,
      elapsed: state.elapsed,
    );
  }

  /// Resume from paused state
  void resume() {
    if (state.state != WorkoutTimerState.paused) return;

    _startTime = DateTime.now().subtract(state.elapsed);
    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: state.elapsed,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Toggle between pause and resume
  void togglePause() {
    if (state.state == WorkoutTimerState.running) {
      pause();
    } else if (state.state == WorkoutTimerState.paused) {
      resume();
    }
  }

  /// Stop and reset the timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    state = const WorkoutTimerData(
      state: WorkoutTimerState.idle,
      elapsed: Duration.zero,
    );
  }

  /// Reset while keeping start time (for continue after app restart).
  /// Computes initial elapsed from [startTime] so resumed sessions show
  /// the correct duration immediately.
  void reset(DateTime startTime) {
    _timer?.cancel();
    _timer = null;
    _startTime = startTime;
    final elapsed = DateTime.now().difference(startTime);
    final inWarning = elapsed >= warningDuration;

    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: elapsed,
      showLongSessionWarning: inWarning,
    );

    if (inWarning) {
      _hasShownWarning = true;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Dismiss the long session warning banner.
  /// Sets [WorkoutTimerData.showLongSessionWarning] to false so the UI
  /// hides the warning banner while continuing the session.
  void acknowledgeLongSessionWarning() {
    state = state.copyWith(showLongSessionWarning: false);
  }

  /// Sync the timer state with elapsed time loaded from the server.
  /// This is used when loading a session from the backend to ensure the
  /// local timer reflects the actual server-recorded duration.
  /// Unlike [start]/[reset], this does NOT fire warning callbacks since
  /// the crossing already happened on the server side.
  void resetFromServer(Duration serverElapsed) {
    _timer?.cancel();
    _timer = null;
    _startTime = DateTime.now().subtract(serverElapsed);
    _hasShownWarning = serverElapsed >= warningDuration;

    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: serverElapsed,
      showLongSessionWarning: serverElapsed >= warningDuration,
      showLongSessionToast: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_startTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_startTime!);

    // Start with base state update (preserves warning flags)
    var newState = state.copyWith(elapsed: elapsed);

    // Check 2-hour warning (fire once)
    if (elapsed >= warningDuration && !_hasShownWarning) {
      _hasShownWarning = true;
      newState = newState.copyWith(
        showLongSessionWarning: true,
        showLongSessionToast: true,
      );
      on2HourWarning?.call();
      onLongSessionWarning?.call();
    }

    state = newState;

    // Check 4-hour auto-end
    if (elapsed >= maxDuration) {
      // Clear warning before firing callbacks (matching iOS behavior)
      state = state.copyWith(showLongSessionWarning: false);
      on4HourAutoEnd?.call();
      onAutoEnd?.call();
      stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the workout timer
final workoutTimerProvider = StateNotifierProvider<WorkoutTimerNotifier, WorkoutTimerData>((ref) {
  return WorkoutTimerNotifier();
});
