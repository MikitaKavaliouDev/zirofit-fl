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

  const WorkoutTimerData({
    required this.state,
    required this.elapsed,
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

  // Callbacks
  void Function()? on2HourWarning;
  void Function()? on4HourAutoEnd;

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
    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: DateTime.now().difference(startTime),
    );

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
    state = WorkoutTimerData(
      state: WorkoutTimerState.running,
      elapsed: DateTime.now().difference(startTime),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_startTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_startTime!);

    state = WorkoutTimerData(
      state: state.state,
      elapsed: elapsed,
    );

    // Check 2-hour warning
    if (elapsed >= warningDuration) {
      on2HourWarning?.call();
    }

    // Check 4-hour auto-end
    if (elapsed >= maxDuration) {
      on4HourAutoEnd?.call();
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
