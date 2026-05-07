import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workout timer states
enum WorkoutTimerState {
  idle,
  running,
  paused,
}

/// Provider for workout timer that tracks elapsed time during active workout
class WorkoutTimerNotifier extends StateNotifier<WorkoutTimerState> {
  WorkoutTimerNotifier() : super(WorkoutTimerState.idle);

  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  
  // Callbacks
  void Function()? on2HourWarning;
  void Function()? on4HourAutoEnd;

  // Constants
  static const Duration maxDuration = Duration(hours: 4);
  static const Duration warningDuration = Duration(hours: 2);

  Duration get elapsed => _elapsed;
  
  bool get isRunning => state == WorkoutTimerState.running;
  bool get isPaused => state == WorkoutTimerState.paused;
  bool get isIdle => state == WorkoutTimerState.idle;

  /// Formatted time string (MM:SS or H:MM:SS)
  String get formattedTime {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Progress as percentage of max duration (0.0 - 1.0)
  double get progress {
    if (maxDuration.inSeconds == 0) return 0;
    return (_elapsed.inSeconds / maxDuration.inSeconds).clamp(0.0, 1.0);
  }

  /// Check if we're in warning zone (2+ hours)
  bool get isInWarningZone => _elapsed >= warningDuration;

  /// Check if we're at max duration
  bool get isAtMaxDuration => _elapsed >= maxDuration;

  /// Start the timer
  void start(DateTime startTime) {
    _startTime = startTime;
    _elapsed = Duration.zero;
    state = WorkoutTimerState.running;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Pause the timer
  void pause() {
    if (state != WorkoutTimerState.running) return;
    
    _timer?.cancel();
    _timer = null;
    _pauseTime = DateTime.now();
    state = WorkoutTimerState.paused;
  }

  /// Resume from paused state
  void resume() {
    if (state != WorkoutTimerState.paused) return;
    
    _startTime = DateTime.now().subtract(_elapsed);
    state = WorkoutTimerState.running;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Toggle between pause and resume
  void togglePause() {
    if (state == WorkoutTimerState.running) {
      pause();
    } else if (state == WorkoutTimerState.paused) {
      resume();
    }
  }

  /// Stop and reset the timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _pauseTime = null;
    _elapsed = Duration.zero;
    state = WorkoutTimerState.idle;
  }

  /// Reset while keeping start time (for continue after app restart)
  void reset(DateTime startTime) {
    _timer?.cancel();
    _timer = null;
    _startTime = startTime;
    _pauseTime = null;
    _elapsed = Duration.zero;
    state = WorkoutTimerState.running;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_startTime == null) return;
    
    final now = DateTime.now();
    _elapsed = now.difference(_startTime!);
    
    // Check 2-hour warning
    if (_elapsed >= warningDuration && !isInWarningZone) {
      on2HourWarning?.call();
    }
    
    // Check 4-hour auto-end
    if (_elapsed >= maxDuration) {
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
final workoutTimerProvider = StateNotifierProvider<WorkoutTimerNotifier, WorkoutTimerState>((ref) {
  return WorkoutTimerNotifier();
});