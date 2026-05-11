import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final activeWorkoutProvider = StateNotifierProvider<
    ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  final remoteSource = ref.watch(workoutRemoteSourceProvider);
  return ActiveWorkoutNotifier(
    remoteSource: remoteSource,
    ref: ref,
  );
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
  final String? clientName; // target client name for trainer-led sessions
  final StreamController<bool>? newRecordDetected; // Stream for new PR detection
  final String? lastNewRecord; // Last exercise that achieved a new record (for toast)

  const ActiveWorkoutState({
    this.session,
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.restSeconds = 0,
    this.isRestRunning = false,
    this.exerciseNames = const {},
    this.clientName,
    this.newRecordDetected,
    this.lastNewRecord,
  });

  ActiveWorkoutState copyWith({
    WorkoutSession? session,
    List<ClientExerciseLog>? logs,
    bool? isLoading,
    String? error,
    int? restSeconds,
    bool? isRestRunning,
    Map<String, String>? exerciseNames,
    String? clientName,
    StreamController<bool>? newRecordDetected,
    String? lastNewRecord,
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
      clientName: clientName ?? this.clientName,
      newRecordDetected: newRecordDetected ?? this.newRecordDetected,
      lastNewRecord: lastNewRecord,
    );
  }

  bool get hasActiveSession => session != null;
  bool get isIdle => !isLoading && session == null && error == null;
  /// Whether this is a trainer-led session (training a client).
  bool get isTrainerLed => clientName != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRemoteSource _remoteSource;
  final Ref _ref;
  Timer? _restTimer;
  final StreamController<bool> _newRecordController = StreamController<bool>.broadcast();

  ActiveWorkoutNotifier({required WorkoutRemoteSource remoteSource, required Ref ref})
      : _remoteSource = remoteSource,
        _ref = ref,
        super(const ActiveWorkoutState(newRecordDetected: null));

  @override
  void dispose() {
    _restTimer?.cancel();
    _newRecordController.close();
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
      
      // Start workout timer with actual session start time for accurate elapsed calculation
      _ref.read(workoutTimerProvider.notifier).start(session.startTime);
      
      // Template exercise prepopulation
      if (templateId != null) {
        await _populateTemplateExercises(session.id, templateId);
      }
      
      state = ActiveWorkoutState(
        session: session,
        logs: [],
        restSeconds: 90, // default rest timer
        exerciseNames: const {},
      );
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// POST /api/workout-sessions/start (trainer-led)
  /// Starts a new workout session for a specific client.
  Future<void> startSessionForClient({
    required String clientId,
    required String clientName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await _remoteSource.startWorkout(
        clientId: clientId,
      );
      
      // Start workout timer with actual session start time for accurate elapsed calculation
      _ref.read(workoutTimerProvider.notifier).start(session.startTime);
      
      state = ActiveWorkoutState(
        session: session,
        logs: [],
        restSeconds: 90,
        exerciseNames: const {},
        clientName: clientName,
      );
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
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

      // No active session - stay idle
      if (result == null) {
        state = const ActiveWorkoutState();
        return;
      }

      state = ActiveWorkoutState(
        session: result.session,
        logs: result.logs,
        restSeconds: result.session.restStartedAt != null
            ? _computeRemainingRest(result.session.restStartedAt!)
            : 90,
        isRestRunning: result.session.restStartedAt != null,
        exerciseNames: const {},
      );

      // Start session elapsed timer with actual session start time
      _ref.read(workoutTimerProvider.notifier).reset(result.session.startTime);

      if (result.session.restStartedAt != null) {
        _startRestTimer();
      }
    } catch (e, st) {
      // If there's no active session, that's fine — just stay idle.
      // But we still want to log the error if it's NOT a 404/Empty session.
      debugPrint('LOAD_ACTIVE_SESSION_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = const ActiveWorkoutState();
    }
  }

  /// POST /api/workout-sessions/live
  /// Logs a new exercise set.
  /// Optionally marks the exercise as completed.
  Future<void> logExercise({
    required String exerciseId,
    int? reps,
    double? weight,
    bool? isCompleted,
    String? logId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final log = await _remoteSource.logExercise(
        exerciseId: exerciseId,
        workoutSessionId: state.session!.id,
        reps: reps,
        weight: weight,
        isCompleted: isCompleted,
        logId: logId,
      );
      // If updating existing log (logId provided), replace it; otherwise add new
      if (logId != null) {
        final updatedLogs = state.logs.map((l) {
          return l.id == logId ? log : l;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          logs: updatedLogs,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          logs: [...state.logs, log],
        );
      }
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marks an existing log entry as completed with optimistic UI update.
  /// 
  /// Flow:
  /// 1. Immediately update local state (optimistic)
  /// 2. Call backend API
  /// 3. On success: sync with server response, show PR toast if new records
  /// 4. On failure: rollback local state
  Future<void> completeSet(String logId, {String? exerciseName}) async {
    // Find the existing log to get its data
    final existingLog = state.logs.where((log) => log.id == logId).firstOrNull;
    if (existingLog == null) {
      state = state.copyWith(error: 'Log not found');
      return;
    }

    // Store pre-update state for potential rollback
    final previousLogs = List<ClientExerciseLog>.from(state.logs);

    // OPTIMISTIC UPDATE: Immediately mark as completed in UI
    final optimisticLogs = state.logs.map((log) {
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
          updatedAt: DateTime.now(),
          deletedAt: log.deletedAt,
        );
      }
      return log;
    }).toList();

    state = state.copyWith(logs: optimisticLogs);

    try {
      // Call API to mark as completed (updates existing log via logId)
      final log = await _remoteSource.logExercise(
        exerciseId: existingLog.exerciseId,
        workoutSessionId: state.session!.id,
        reps: existingLog.reps,
        weight: existingLog.weight,
        isCompleted: true,
        logId: logId,
      );

      // Sync with server response (update with actual data from backend)
      final syncedLogs = state.logs.map((l) {
        return l.id == logId ? log : l;
      }).toList();

      state = state.copyWith(logs: syncedLogs);
      
      // Start rest timer after completing a set
      startRest();
    } catch (e, st) {
      debugPrint('COMPLETE_SET_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      
      // ROLLBACK: Restore previous state on API failure
      state = state.copyWith(
        logs: previousLogs,
        error: e.toString(),
      );
    }
  }

  /// POST /api/workout-sessions/finish
  /// Finishes the current workout and navigates to summary.
  Future<WorkoutSession?> finishWorkout() async {
    final sessionId = state.session?.id;
    if (sessionId == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _restTimer?.cancel();
      // Stop workout timer
      _ref.read(workoutTimerProvider.notifier).stop();
      final finishedSession = await _remoteSource.finishWorkout(sessionId);
      state = const ActiveWorkoutState();
      return finishedSession;
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
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
      // Stop workout timer
      _ref.read(workoutTimerProvider.notifier).stop();
      await _remoteSource.cancelWorkout(sessionId);
      state = const ActiveWorkoutState();
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
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
    } catch (e, st) {
      debugPrint('REST_TIMER_ERROR: $e');
      debugPrint('STACKTRACE: $st');
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
    } catch (e, st) {
      debugPrint('REST_TIMER_ERROR: $e');
      debugPrint('STACKTRACE: $st');
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

  /// DELETE /api/workout-sessions/{id}/exercises/{logId}
  /// Remove a specific set from the active session.
  Future<void> deleteSet(String logId) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.deleteSessionExerciseLog(
        sessionId: sessionId,
        logId: logId,
      );
      state = state.copyWith(
        isLoading: false,
        logs: state.logs.where((log) => log.id != logId).toList(),
      );
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update a set's status (normal/warmUp/dropSet/failure).
  /// Updates both local state AND API.
  Future<void> updateSetStatus(String logId, SetStatus status) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

try {
        // TODO: Implement API call for updating set status when endpoint is available
        // For now, update local state optimistically
        final updatedLogs = state.logs.map((log) {
          if (log.id == logId) {
            // Find the set and update its status (need to modify the sets field)
            final updatedSets = log.sets?.map((setJson) {
              final set = WorkoutSet.fromJson(setJson);
              // TODO: Need to identify which set to update - this is simplified
              return set.copyWith(status: status).toJson();
            }).toList() ?? log.sets;
            
            return ClientExerciseLog(
              id: log.id,
              clientId: log.clientId,
              exerciseId: log.exerciseId,
              reps: log.reps,
              weight: log.weight,
              isCompleted: log.isCompleted,
              order: log.order,
              tempo: log.tempo,
              side: log.side,
              workoutSessionId: log.workoutSessionId,
              supersetKey: log.supersetKey,
              orderInSuperset: log.orderInSuperset,
              sets: updatedSets,
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
      
      state = state.copyWith(
        isLoading: false,
        logs: updatedLogs,
      );
    } catch (e, st) {
      debugPrint('WORKOUT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update RPE for a specific set in local state.
  void updateSetRpe(String logId, double rpe) {
    // Update local state - TODO: Add API call when endpoint available
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: log.reps,
          weight: log.weight,
          isCompleted: log.isCompleted,
          order: log.order,
          tempo: log.tempo,
          side: log.side,
          workoutSessionId: log.workoutSessionId,
          supersetKey: log.supersetKey,
          orderInSuperset: log.orderInSuperset,
          sets: log.sets,
          rpe: rpe,
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
    
    // Check for new record detection (simplified)
    _checkForNewRecord(logId, rpe: rpe);
  }

  /// Update focus metric for an exercise in local state.
  void updateFocusMetric(String logId, FocusMetric metric) {
    // Update local state - TODO: Add API call when endpoint available
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        // Update focus metric in all sets for this exercise
        final updatedSets = log.sets?.map((setJson) {
          final set = WorkoutSet.fromJson(setJson);
          return set.copyWith(focusMetric: metric).toJson();
        }).toList() ?? log.sets;
        
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: log.reps,
          weight: log.weight,
          isCompleted: log.isCompleted,
          order: log.order,
          tempo: log.tempo,
          side: log.side,
          workoutSessionId: log.workoutSessionId,
          supersetKey: log.supersetKey,
          orderInSuperset: log.orderInSuperset,
          sets: updatedSets,
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

  /// Before finishing, mark all valid incomplete sets (weight > 0 AND reps > 0) as completed.
  /// Returns count of completed sets.
  int completeUnfinishedSets() {
    int completedCount = 0;
    final updatedLogs = state.logs.map((log) {
      // Update isCompleted flag
      final updatedSets = log.sets?.map((setJson) {
        final set = WorkoutSet.fromJson(setJson);
        if (set.hasData && !set.isCompleted) {
          completedCount++;
          return set.copyWith(isCompleted: true, completedAt: DateTime.now()).toJson();
        }
        return setJson;
      }).toList() ?? log.sets;
      
      final hasIncompleteSets = (log.sets)?.any((s) {
        final set = WorkoutSet.fromJson(s);
        return set.hasData && !set.isCompleted;
      }) ?? false;
      
      if (!hasIncompleteSets) return log;
      
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
        sets: updatedSets,
        rpe: log.rpe,
        rir: log.rir,
        exerciseName: log.exerciseName,
        createdAt: log.createdAt,
        updatedAt: log.updatedAt,
        deletedAt: log.deletedAt,
      );
    }).toList();
    
    state = state.copyWith(logs: updatedLogs);
    return completedCount;
  }

  /// When startWorkout is called with a templateId, fetch template exercises 
  /// from remote source and pre-populate the session's exercises list.
  Future<void> _populateTemplateExercises(String sessionId, String templateId) async {
    try {
      // TODO: Implement when template exercise endpoint is available
      // For now, this is a placeholder that follows the existing pattern
      final response = await _remoteSource.fetchSession(templateId); // Using fetchSession as placeholder
      // In a real implementation, we would fetch template exercises and add them to the session
    } catch (e, st) {
      debugPrint('TEMPLATE_PREPOPULATION_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      // Don't fail the workout start if template prepopulation fails
    }
  }

  /// Check for new record detection and emit to stream
  void _checkForNewRecord(String logId, {double? weight, double? rpe}) {
    // Simplified new record detection - in reality this would compare against historical data
    final isNewRecord = (rpe ?? 0) >= 10.0 || (weight ?? 0) > 100.0; // Placeholder logic
    if (isNewRecord && !_newRecordController.isClosed) {
      _newRecordController.add(true);
    }
  }

  /// Computed property that returns historical sets per exerciseId from exerciseStats.
  Map<String, List<WorkoutSet>> get previousSetData {
    // TODO: Implement when exerciseStats is available in state
    // This would typically come from a separate provider or service
    return {};
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

  /// Add a new set to an exercise log (creates a new ClientExerciseLog entry).
  void addSet(String exerciseId) {
    final exerciseName = state.exerciseNames[exerciseId] ?? 'Exercise';
    final newLog = ClientExerciseLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      clientId: state.session?.clientId ?? '',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      workoutSessionId: state.session?.id ?? '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(logs: [...state.logs, newLog]);
  }

  /// Remove an exercise from the session by exerciseId.
  void removeExercise(String exerciseId) {
    state = state.copyWith(
      logs: state.logs.where((log) => log.exerciseId != exerciseId).toList(),
    );
  }
}
