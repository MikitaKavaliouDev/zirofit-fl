import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';
import 'package:zirofit_fl/features/workout/providers/rest_timer_manager_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_stats_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_library_provider.dart';
import 'package:zirofit_fl/features/workout/services/new_record_detection_service.dart';

// ---------------------------------------------------------------------------
// Finish option (iOS-aligned)
// ---------------------------------------------------------------------------

/// How to handle incomplete sets when finishing a workout.
enum FinishOption {
  /// Mark all incomplete sets that have data as completed before finishing.
  completeUnfinished,
  /// Delete all incomplete sets before finishing.
  discardUnfinished,
}

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
  final bool isPaused;
  final bool showLongSessionWarning;
  final bool longSessionWarningAcknowledged;
  final String? selectedExerciseId;
  final bool showRestTimerFinishedToast;
  final String? pendingSetId;
  final List<SetStatus> availableSetStatuses;
  final String? coachNotes;
  final String? activeVideoUrl; // Set when user taps "Watch Video" → triggers YouTubeSheetView
  final bool showFinishWorkoutAlert;
  final bool showExerciseSelection;

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
    this.isPaused = false,
    this.showLongSessionWarning = false,
    this.longSessionWarningAcknowledged = false,
    this.selectedExerciseId,
    this.showRestTimerFinishedToast = false,
    this.pendingSetId,
    this.availableSetStatuses = const [SetStatus.normal, SetStatus.warmUp, SetStatus.dropSet, SetStatus.failure],
    this.coachNotes,
    this.activeVideoUrl,
    this.showFinishWorkoutAlert = false,
    this.showExerciseSelection = false,
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
    bool? isPaused,
    bool? showLongSessionWarning,
    bool? longSessionWarningAcknowledged,
    String? selectedExerciseId,
    bool? showRestTimerFinishedToast,
    String? pendingSetId,
    List<SetStatus>? availableSetStatuses,
    String? coachNotes,
    String? activeVideoUrl,
    bool? showFinishWorkoutAlert,
    bool? showExerciseSelection,
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
      isPaused: isPaused ?? this.isPaused,
      showLongSessionWarning: showLongSessionWarning ?? this.showLongSessionWarning,
      longSessionWarningAcknowledged: longSessionWarningAcknowledged ?? this.longSessionWarningAcknowledged,
      selectedExerciseId: selectedExerciseId ?? this.selectedExerciseId,
      showRestTimerFinishedToast: showRestTimerFinishedToast ?? this.showRestTimerFinishedToast,
      pendingSetId: pendingSetId ?? this.pendingSetId,
      availableSetStatuses: availableSetStatuses ?? this.availableSetStatuses,
      coachNotes: coachNotes ?? this.coachNotes,
      activeVideoUrl: activeVideoUrl ?? this.activeVideoUrl,
      showFinishWorkoutAlert: showFinishWorkoutAlert ?? this.showFinishWorkoutAlert,
      showExerciseSelection: showExerciseSelection ?? this.showExerciseSelection,
    );
  }

  bool get hasActiveSession => session != null;
  bool get isIdle => !isLoading && session == null && error == null;
  /// Whether this is a trainer-led session (training a client).
  bool get isTrainerLed => clientName != null;

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Any logs where isCompleted != true.
  bool get hasIncompleteSets => logs.any((log) => log.isCompleted != true);

  /// Total number of exercise logs.
  int get totalSets => logs.length;

  /// Number of completed exercise logs.
  int get completedSets => logs.where((log) => log.isCompleted == true).length;

  /// Estimated session duration based on number of sets (~2 min per set).
  Duration get estimatedDuration => Duration(seconds: totalSets * 120);

  /// Exercise logs filtered by completed status.
  List<ClientExerciseLog> get completedExerciseLogs =>
      logs.where((log) => log.isCompleted == true).toList();

  /// Exercise logs that are not yet completed.
  List<ClientExerciseLog> get pendingExerciseLogs =>
      logs.where((log) => log.isCompleted != true).toList();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRemoteSource _remoteSource;
  final Ref _ref;
  final NewRecordDetectionService _newRecordDetectionService;

  ActiveWorkoutNotifier({required WorkoutRemoteSource remoteSource, required Ref ref})
      : _remoteSource = remoteSource,
        _ref = ref,
        _newRecordDetectionService = NewRecordDetectionService(
          getHistoricalLogs: (exerciseId) async {
            return ref.read(exerciseStatsProvider.notifier).getHistoricalLogs(exerciseId);
          },
          getExerciseName: (exerciseId) {
            // Look up exercise name from the exercise library
            final libraryState = ref.read(exerciseLibraryProvider);
            final exercise = libraryState.allExercises
                .where((e) => e.id == exerciseId)
                .firstOrNull;
            return exercise?.name;
          },
        ),
        super(const ActiveWorkoutState(newRecordDetected: null)) {
    // ------------------------------------------------------------------
    // Listen to rest timer manager — sync state on every tick
    // ------------------------------------------------------------------
    ref.listen(restTimerManagerProvider, (prev, RestTimerState next) {
      state = state.copyWith(
        restSeconds: next.remainingTime,
        isRestRunning: next.isRunning,
      );
    });

    // ------------------------------------------------------------------
    // Listen to workout timer — sync pause state
    // ------------------------------------------------------------------
    ref.listen(workoutTimerProvider, (prev, WorkoutTimerData next) {
      state = state.copyWith(isPaused: next.isPaused);
    });

    // ------------------------------------------------------------------
    // Subscribe to rest-finished stream — show toast
    // ------------------------------------------------------------------
    final restTimerNotifier = ref.read(restTimerManagerProvider.notifier);
    restTimerNotifier.onRestFinished.listen((_) {
      if (!mounted) return;
      state = state.copyWith(showRestTimerFinishedToast: true);
    });
  }

  @override
  void dispose() {
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

      // Wire timer callbacks before starting
      final timerNotifier = _ref.read(workoutTimerProvider.notifier);
      timerNotifier.onLongSessionWarning = () {
        state = state.copyWith(showLongSessionWarning: true);
      };
      timerNotifier.onAutoEnd = () {
        finishWorkoutWithOption(FinishOption.completeUnfinished);
      };

      // Start workout timer with actual session start time for accurate elapsed calculation
      timerNotifier.start(session.startTime);

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

      // Wire timer callbacks before starting
      final timerNotifier = _ref.read(workoutTimerProvider.notifier);
      timerNotifier.onLongSessionWarning = () {
        state = state.copyWith(showLongSessionWarning: true);
      };
      timerNotifier.onAutoEnd = () {
        finishWorkoutWithOption(FinishOption.completeUnfinished);
      };

      // Start workout timer with actual session start time for accurate elapsed calculation
      timerNotifier.start(session.startTime);

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
        exerciseNames: const {},
      );

      // Start session elapsed timer with actual session start time
      _ref.read(workoutTimerProvider.notifier).reset(result.session.startTime);

      // Wire timer callbacks after loading a session (they are reset on provider init)
      final timerNotifier = _ref.read(workoutTimerProvider.notifier);
      timerNotifier.onLongSessionWarning = () {
        state = state.copyWith(showLongSessionWarning: true);
      };
      timerNotifier.onAutoEnd = () {
        finishWorkoutWithOption(FinishOption.completeUnfinished);
      };

      // Resume rest timer if one was active on the server
      if (result.session.restStartedAt != null) {
        final elapsed = DateTime.now().difference(result.session.restStartedAt!).inSeconds;
        final remaining = (90 - elapsed).clamp(0, 90);
        _ref.read(restTimerManagerProvider.notifier).start(duration: remaining);
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

      // Check for new personal record (iOS-aligned: uses full historical data)
      final result = await _newRecordDetectionService.checkForNewRecord(
        existingLog.exerciseId,
        existingLog.weight ?? 0,
        existingLog.reps ?? 0,
      );
      if (result != null) {
        state = state.copyWith(lastNewRecord: result.exerciseName);
      }

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
      // Delegate to RestTimerManager — it handles ticking internally
      _ref.read(restTimerManagerProvider.notifier).start(duration: 90);
      // restSeconds & isRestRunning synced via listener in constructor
    } catch (e, st) {
      debugPrint('REST_TIMER_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Manual tick for the rest timer. Delegates to RestTimerNotifier.
  /// State (restSeconds, isRestRunning) is synced via constructor listener.
  void tickRestTimer() {
    _ref.read(restTimerManagerProvider.notifier).tick();
  }

  /// POST /api/workout-sessions/rest/end
  /// Ends the rest timer early.
  Future<void> endRest() async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    try {
      await _remoteSource.endRest(sessionId);
      _ref.read(restTimerManagerProvider.notifier).stop();
      // restSeconds & isRestRunning synced via listener in constructor
    } catch (e, st) {
      debugPrint('REST_TIMER_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Sets the active video URL, which triggers the YouTubeSheetView in the UI.
  /// Pass null to dismiss the sheet.
  void setActiveVideoUrl(String? url) {
    state = state.copyWith(activeVideoUrl: url);
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
  }

  /// Update weight for a specific set in local state (optimistic, no API call).
  /// Mirrors iOS manager.updateSetWeight(setId:weight:).
  void updateSetWeight(String logId, double weight) {
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: log.reps,
          weight: weight,
          isCompleted: log.isCompleted,
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

    state = state.copyWith(logs: updatedLogs);
  }

  /// Update reps for a specific set in local state (optimistic, no API call).
  /// Mirrors iOS manager.updateSetReps(setId:reps:).
  void updateSetReps(String logId, int reps) {
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: reps,
          weight: log.weight,
          isCompleted: log.isCompleted,
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

    state = state.copyWith(logs: updatedLogs);
  }

  /// Update tempo for a specific set in local state (optimistic, no API call).
  /// Mirrors iOS manager.updateSetTempo(setId:tempo:).
  void updateSetTempo(String logId, String tempo) {
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
          tempo: tempo,
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

    state = state.copyWith(logs: updatedLogs);
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
      await _remoteSource.fetchSession(templateId); // Using fetchSession as placeholder
      // In a real implementation, we would fetch template exercises and add them to the session
    } catch (e, st) {
      debugPrint('TEMPLATE_PREPOPULATION_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      // Don't fail the workout start if template prepopulation fails
    }
  }

  /// Adds exercises from a template to the current session.
  /// Mirrors iOS TemplatePickerView → manager.addExercises(exercises).
  Future<void> addExercisesFromTemplate(String templateId) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _populateTemplateExercises(sessionId, templateId);
      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      debugPrint('ADD_EXERCISES_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sets the name for a given exercise.
  void setExerciseName(String exerciseId, String name) {
    state = state.copyWith(
      exerciseNames: {...state.exerciseNames, exerciseId: name},
    );
  }

  // ---------------------------------------------------------------------------
  // iOS-aligned: Finish workout with option
  // ---------------------------------------------------------------------------

  /// Finishes the workout, handling incomplete sets according to [option].
  ///
  /// - [FinishOption.completeUnfinished]: marks all valid incomplete sets as
  ///   completed before finishing (matching iOS "Complete Unfinished").
  /// - [FinishOption.discardUnfinished]: removes incomplete sets from the log
  ///   before finishing (matching iOS "Discard Unfinished").
  Future<WorkoutSession?> finishWorkoutWithOption(FinishOption option) async {
    switch (option) {
      case FinishOption.completeUnfinished:
        completeUnfinishedSets();
      case FinishOption.discardUnfinished:
        final completedLogs =
            state.logs.where((log) => log.isCompleted == true).toList();
        state = state.copyWith(logs: completedLogs);
    }
    return finishWorkout();
  }

  // ---------------------------------------------------------------------------
  // iOS-aligned: Pause / Resume
  // ---------------------------------------------------------------------------

  /// Toggles the workout timer between paused and running.
  /// The [isPaused] state field is synced via the [workoutTimerProvider] listener
  /// set up in the constructor.
  void togglePause() {
    _ref.read(workoutTimerProvider.notifier).togglePause();
  }

  /// Acknowledges and dismisses the long-session warning.
  void acknowledgeLongSessionWarning() {
    state = state.copyWith(
      showLongSessionWarning: false,
      longSessionWarningAcknowledged: true,
    );
    _ref.read(workoutTimerProvider.notifier).acknowledgeLongSessionWarning();
  }

  // ---------------------------------------------------------------------------
  // UI state flags
  // ---------------------------------------------------------------------------

  /// Shows/hides the finish-workout confirmation alert.
  void setShowFinishWorkoutAlert(bool value) {
    state = state.copyWith(showFinishWorkoutAlert: value);
  }

  /// Shows/hides the exercise selection sheet.
  void setShowExerciseSelection(bool value) {
    state = state.copyWith(showExerciseSelection: value);
  }

  /// Resets to idle state.
  void reset() {
    state = const ActiveWorkoutState();
  }

  /// Saves the current workout session as a template for reuse.
  /// Mirrors iOS manager.saveSessionAsTemplate(name:description:).
  Future<void> saveSessionAsTemplate({
    required String name,
    String? description,
  }) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    try {
      await _remoteSource.saveSessionAsTemplate(
        sessionId: sessionId,
        name: name,
        description: description,
      );
    } catch (e, st) {
      debugPrint('SAVE_TEMPLATE_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(error: 'Failed to save template: $e');
    }
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
