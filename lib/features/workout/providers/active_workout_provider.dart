import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final activeWorkoutProvider = StateNotifierProvider<
    ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  final remoteSource = ref.watch(workoutRemoteSourceProvider);
  return ActiveWorkoutNotifier(remoteSource: remoteSource);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ActiveWorkoutState {
  final WorkoutSession? session;
  final List<ClientExerciseLog> logs;
  final bool isLoading;
  final String? error;
  final int restSeconds;
  final bool isRestRunning;
  final Map<String, String> exerciseNames; // exerciseId → exerciseName

  const ActiveWorkoutState({
    this.session,
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.restSeconds = 0,
    this.isRestRunning = false,
    this.exerciseNames = const {},
  });

  ActiveWorkoutState copyWith({
    WorkoutSession? session,
    List<ClientExerciseLog>? logs,
    bool? isLoading,
    String? error,
    int? restSeconds,
    bool? isRestRunning,
    Map<String, String>? exerciseNames,
    bool clearError = false,
  }) {
    return ActiveWorkoutState(
      session: session ?? this.session,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      restSeconds: restSeconds ?? this.restSeconds,
      isRestRunning: isRestRunning ?? this.isRestRunning,
      exerciseNames: exerciseNames ?? this.exerciseNames,
    );
  }

  bool get hasActiveSession => session != null;
  bool get isIdle => !isLoading && session == null && error == null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRemoteSource _remoteSource;
  Timer? _restTimer;

  ActiveWorkoutNotifier({required WorkoutRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const ActiveWorkoutState());

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  /// POST /api/workout-sessions/start
  /// Starts a new workout, optionally from a template.
  Future<void> startWorkout({String? templateId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await _remoteSource.startWorkout(
        templateId: templateId,
      );
      state = ActiveWorkoutState(
        session: session,
        logs: [],
        restSeconds: 90, // default rest timer
        exerciseNames: const {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Loads the currently active session (for re-entering the screen).
  Future<void> loadActiveSession() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _remoteSource.getActiveSession();
      state = ActiveWorkoutState(
        session: result.session,
        logs: result.logs,
        restSeconds: result.session.restStartedAt != null
            ? _computeRemainingRest(result.session.restStartedAt!)
            : 90,
        isRestRunning: result.session.restStartedAt != null,
        exerciseNames: const {},
      );

      if (result.session.restStartedAt != null) {
        _startRestTimer();
      }
    } catch (e) {
      // If there's no active session, that's fine — just stay idle.
      state = const ActiveWorkoutState();
    }
  }

  /// POST /api/workout-sessions/live
  /// Logs a new exercise set.
  Future<void> logExercise({
    required String exerciseId,
    int? reps,
    double? weight,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final log = await _remoteSource.logExercise(
        exerciseId: exerciseId,
        workoutSessionId: state.session!.id,
        reps: reps,
        weight: weight,
      );
      state = state.copyWith(
        isLoading: false,
        logs: [...state.logs, log],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marks an existing log entry as completed (optimistic update).
  Future<void> completeSet(String logId) async {
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: log.reps,
          weight: log.weight,
          isCompleted: true,
          order: log.order,
          tempo: log.tempo,
          side: log.side,
          workoutSessionId: log.workoutSessionId,
          supersetKey: log.supersetKey,
          orderInSuperset: log.orderInSuperset,
          sets: log.sets,
          rpe: log.rpe,
          rir: log.rir,
          exerciseName: log.exerciseName,
          createdAt: log.createdAt,
          updatedAt: log.updatedAt,
          deletedAt: log.deletedAt,
        );
      }
      return log;
    }).toList();

    state = state.copyWith(logs: updatedLogs);
  }

  /// POST /api/workout-sessions/finish
  /// Finishes the current workout and navigates to summary.
  Future<WorkoutSession?> finishWorkout() async {
    final sessionId = state.session?.id;
    if (sessionId == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _restTimer?.cancel();
      final finishedSession = await _remoteSource.finishWorkout(sessionId);
      state = const ActiveWorkoutState();
      return finishedSession;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// POST /api/workout-sessions/cancel
  /// Cancels/abandons the workout.
  Future<void> cancelWorkout() async {
    final sessionId = state.session?.id;
    if (sessionId == null) {
      state = const ActiveWorkoutState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _restTimer?.cancel();
      await _remoteSource.cancelWorkout(sessionId);
      state = const ActiveWorkoutState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Rest timer
  // ---------------------------------------------------------------------------

  /// POST /api/workout-sessions/rest/start
  /// Starts the rest timer.
  Future<void> startRest() async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    try {
      await _remoteSource.startRest(sessionId);
      state = state.copyWith(
        restSeconds: 90,
        isRestRunning: true,
      );
      _startRestTimer();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// POST /api/workout-sessions/rest/end
  /// Ends the rest timer early.
  Future<void> endRest() async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    try {
      await _remoteSource.endRest(sessionId);
      _restTimer?.cancel();
      state = state.copyWith(
        restSeconds: 0,
        isRestRunning: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Decrements [restSeconds] every second via a periodic timer.
  void tickRestTimer() {
    if (state.restSeconds > 0) {
      state = state.copyWith(restSeconds: state.restSeconds - 1);
    } else {
      _restTimer?.cancel();
      state = state.copyWith(isRestRunning: false);
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tickRestTimer();
    });
  }

  int _computeRemainingRest(DateTime restStartedAt) {
    final elapsed = DateTime.now().difference(restStartedAt).inSeconds;
    return (90 - elapsed).clamp(0, 90);
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Sets the name for a given exercise.
  void setExerciseName(String exerciseId, String name) {
    state = state.copyWith(
      exerciseNames: {...state.exerciseNames, exerciseId: name},
    );
  }

  /// Resets to idle state.
  void reset() {
    _restTimer?.cancel();
    state = const ActiveWorkoutState();
  }
}
