import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

class MockWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}

void main() {
  late MockWorkoutRemoteSource mockRemoteSource;
  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;


  setUp(() {
    mockRemoteSource = MockWorkoutRemoteSource();
    container = ProviderContainer(
      overrides: [
        activeWorkoutProvider.overrideWith((ref) => ActiveWorkoutNotifier(
          remoteSource: mockRemoteSource,
          ref: ref,
        )),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  setUp(() {
    notifier = container.read(activeWorkoutProvider.notifier);
  });

  WorkoutSession createSession({
    String id = 'ws-1',
    WorkoutSessionStatus status = WorkoutSessionStatus.inProgress,
  }) {
    return WorkoutSession(
      id: id,
      clientId: 'client-1',
      startTime: DateTime.now(),
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ClientExerciseLog createLog({
    String id = 'log-1',
    String exerciseId = 'ex-1',
    int? reps = 10,
    double? weight = 50,
    bool? isCompleted,
  }) {
    return ClientExerciseLog(
      id: id,
      clientId: 'client-1',
      exerciseId: exerciseId,
      workoutSessionId: 'ws-1',
      reps: reps,
      weight: weight,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> setupSession() async {
    when(() => mockRemoteSource.startWorkout(
          templateId: any(named: 'templateId'),
        )).thenAnswer((_) async => createSession());
    await notifier.startWorkout();
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('ActiveWorkoutNotifier', () {
    test('initial state: isLoading=false, session=null, error=null', () {
      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.session, isNull);
      expect(state.error, isNull);
      expect(state.logs, isEmpty);
      expect(state.restSeconds, 0);
      expect(state.isRestRunning, false);
    });

    group('startWorkout', () {
      test('sets loading then session on success', () async {
        final session = createSession();
        when(() => mockRemoteSource.startWorkout(
              templateId: any(named: 'templateId'),
            )).thenAnswer((_) async => session);

        final future = notifier.startWorkout();
        // Intermediate loading state
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, session);
        expect(state.error, isNull);
        expect(state.restSeconds, 90);
      });

      test('sets error on API failure', () async {
        when(() => mockRemoteSource.startWorkout(
              templateId: any(named: 'templateId'),
            )).thenThrow(Exception('Failed to start workout'));

        await notifier.startWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.error, contains('Failed to start workout'));
      });
    });

    group('logExercise', () {
      test('adds exercise to logs on success', () async {
        await setupSession();
        final log = createLog();
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: any(named: 'isCompleted'),
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => log);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.logs.length, 1);
        expect(state.logs.first.id, 'log-1');
        expect(state.logs.first.reps, 10);
        expect(state.logs.first.weight, 50);
      });

      test('sets error on API failure', () async {
        await setupSession();
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: any(named: 'isCompleted'),
              logId: any(named: 'logId'),
            )).thenThrow(Exception('Failed to log exercise'));

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.logs, isEmpty);
        expect(state.error, contains('Failed to log exercise'));
      });
    });

    group('completeSet', () {
      test('toggles isCompleted on matching log', () async {
        await setupSession();
        final log = createLog();
        // Mock for initial logExercise call (without isCompleted/logId)
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: any(named: 'isCompleted'),
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => log);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);
        expect(notifier.state.logs.first.isCompleted, isNull);

        // Mock for completeSet call (with isCompleted: true and logId)
        final completedLog = createLog(isCompleted: true);
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: true,
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => completedLog);

        await notifier.completeSet('log-1');

        final state = notifier.state;
        expect(state.logs.first.isCompleted, true);
        // Other fields preserved
        expect(state.logs.first.reps, 10);
        expect(state.logs.first.weight, 50);
      });

      test('does not modify other logs', () async {
        await setupSession();
        final log1 = createLog(id: 'log-1', reps: 10);
        final log2 = createLog(id: 'log-2', reps: 20);
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: any(named: 'isCompleted'),
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => log1);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);

        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: any(named: 'isCompleted'),
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => log2);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 20, weight: 60);

        // Mock for completeSet call
        final completedLog1 = createLog(id: 'log-1', isCompleted: true);
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              workoutSessionId: any(named: 'workoutSessionId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
              isCompleted: true,
              logId: any(named: 'logId'),
            )).thenAnswer((_) async => completedLog1);

        await notifier.completeSet('log-1');

        final state = notifier.state;
        expect(state.logs.length, 2);
        expect(state.logs[0].isCompleted, true);
        expect(state.logs[1].isCompleted, isNull);
      });
    });

    group('finishWorkout', () {
      test('calls API and resets state on success', () async {
        await setupSession();
        final completedSession = createSession(
          status: WorkoutSessionStatus.completed,
        );
        when(() => mockRemoteSource.finishWorkout(any()))
            .thenAnswer((_) async => completedSession);

        final result = await notifier.finishWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.logs, isEmpty);
        expect(result, isNotNull);
        expect(result!.status, WorkoutSessionStatus.completed);
      });

      test('returns null when no active session', () async {
        final result = await notifier.finishWorkout();
        expect(result, isNull);
      });

      test('sets error on API failure', () async {
        await setupSession();
        when(() => mockRemoteSource.finishWorkout(any()))
            .thenThrow(Exception('Failed to finish'));

        final result = await notifier.finishWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.error, contains('Failed to finish'));
        // Session preserved on error
        expect(state.session, isNotNull);
        expect(result, isNull);
      });
    });

    group('rest timer', () {
      test('startRest sets isRestRunning and begins countdown', () async {
        await setupSession();
        when(() => mockRemoteSource.startRest(any()))
            .thenAnswer((_) async {});

        await notifier.startRest();

        final state = notifier.state;
        expect(state.isRestRunning, true);
        expect(state.restSeconds, 90);
      });

      test('endRest stops rest timer', () async {
        await setupSession();
        when(() => mockRemoteSource.startRest(any()))
            .thenAnswer((_) async {});
        await notifier.startRest();

        when(() => mockRemoteSource.endRest(any()))
            .thenAnswer((_) async {});

        await notifier.endRest();

        final state = notifier.state;
        expect(state.isRestRunning, false);
        expect(state.restSeconds, 0);
      });

      test('tickRestTimer decrements restSeconds', () async {
        await setupSession();
        when(() => mockRemoteSource.startRest(any()))
            .thenAnswer((_) async {});
        await notifier.startRest();

        expect(notifier.state.restSeconds, 90);

        notifier.tickRestTimer();
        expect(notifier.state.restSeconds, 89);

        notifier.tickRestTimer();
        expect(notifier.state.restSeconds, 88);
      });

      test('tickRestTimer stops rest when reaching zero', () async {
        await setupSession();
        when(() => mockRemoteSource.startRest(any()))
            .thenAnswer((_) async {});
        await notifier.startRest();

        // Tick down to 1
        for (int i = 0; i < 89; i++) {
          notifier.tickRestTimer();
        }
        expect(notifier.state.restSeconds, 1);
        expect(notifier.state.isRestRunning, true);

        // Tick that decrements 1 → 0
        notifier.tickRestTimer();
        expect(notifier.state.restSeconds, 0);
        expect(notifier.state.isRestRunning,
            true); // still running until next tick

        // Tick when already at 0 → stops rest
        notifier.tickRestTimer();
        expect(notifier.state.restSeconds, 0);
        expect(notifier.state.isRestRunning, false);
      });
    });

    group('cancelWorkout', () {
      test('calls API and resets state on success', () async {
        await setupSession();
        when(() => mockRemoteSource.cancelWorkout(any()))
            .thenAnswer((_) async {});

        await notifier.cancelWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.logs, isEmpty);
        expect(state.restSeconds, 0);
        expect(state.isRestRunning, false);
      });

      test('resets state when no active session', () async {
        await notifier.cancelWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.error, isNull);
      });

      test('sets error on API failure', () async {
        await setupSession();
        when(() => mockRemoteSource.cancelWorkout(any()))
            .thenThrow(Exception('Failed to cancel'));

        await notifier.cancelWorkout();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.error, contains('Failed to cancel'));
        // Session preserved on error
        expect(state.session, isNotNull);
      });
    });

    group('startWorkout with templateId', () {
      test('passes templateId to remote source', () async {
        when(() => mockRemoteSource.startWorkout(
              templateId: any(named: 'templateId'),
            )).thenAnswer((_) async => createSession());

        await notifier.startWorkout(templateId: 'tmpl-1');

        verify(() => mockRemoteSource.startWorkout(
              templateId: 'tmpl-1',
            )).called(1);

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNotNull);
        expect(state.error, isNull);
      });
    });

    group('loadActiveSession', () {
      test('loads session and logs on success', () async {
        final session = createSession();
        final logs = [createLog()];
        when(() => mockRemoteSource.getActiveSession())
            .thenAnswer((_) async => (session: session, logs: logs));

        final future = notifier.loadActiveSession();
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, session);
        expect(state.logs, logs);
        expect(state.error, isNull);
        expect(state.restSeconds, 90);
        expect(state.isRestRunning, false);
      });

      test('stays idle when no active session exists', () async {
        when(() => mockRemoteSource.getActiveSession())
            .thenThrow(Exception('No active session'));

        await notifier.loadActiveSession();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.logs, isEmpty);
        expect(state.error, isNull);
        expect(state.isIdle, true);
      });

      test('computes remaining rest when session has restStartedAt', () async {
        final restStartedAt = DateTime.now().subtract(
          const Duration(seconds: 30),
        );
        final session = WorkoutSession(
          id: 'ws-1',
          clientId: 'client-1',
          startTime: DateTime.now(),
          status: WorkoutSessionStatus.inProgress,
          restStartedAt: restStartedAt,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockRemoteSource.getActiveSession())
            .thenAnswer((_) async => (session: session, logs: <ClientExerciseLog>[]));

        await notifier.loadActiveSession();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, session);
        expect(state.restSeconds, greaterThan(50));
        expect(state.restSeconds, lessThanOrEqualTo(60));
        expect(state.isRestRunning, true);
        expect(state.error, isNull);
      });
    });

    group('clearError', () {
      test('clears the error message', () async {
        when(() => mockRemoteSource.startWorkout(
              templateId: any(named: 'templateId'),
            )).thenThrow(Exception('Some error'));
        await notifier.startWorkout();
        expect(notifier.state.error, contains('Some error'));

        notifier.clearError();

        expect(notifier.state.error, isNull);
      });
    });

    group('reset', () {
      test('resets state to idle', () async {
        when(() => mockRemoteSource.startWorkout(
              templateId: any(named: 'templateId'),
            )).thenAnswer((_) async => createSession());
        await notifier.startWorkout();
        expect(notifier.state.session, isNotNull);

        notifier.reset();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.logs, isEmpty);
        expect(state.error, isNull);
        expect(state.restSeconds, 0);
        expect(state.isRestRunning, false);
        expect(state.isIdle, true);
      });
    });

    group('startRest without session', () {
      test('is no-op when no active session', () async {
        expect(notifier.state.session, isNull);

        await notifier.startRest();

        final state = notifier.state;
        expect(state.isRestRunning, false);
        expect(state.restSeconds, 0);
      });
    });

    group('endRest without session', () {
      test('is no-op when no active session', () async {
        expect(notifier.state.session, isNull);

        await notifier.endRest();

        final state = notifier.state;
        expect(state.isRestRunning, false);
        expect(state.restSeconds, 0);
      });
    });

    group('startSessionForClient', () {
      test('sends clientId to remote source and sets clientName', () async {
        when(() => mockRemoteSource.startWorkout(
              clientId: any(named: 'clientId'),
            )).thenAnswer((_) async => createSession());

        await notifier.startSessionForClient(
          clientId: 'client-2',
          clientName: 'Jane Doe',
        );

        verify(() => mockRemoteSource.startWorkout(
              clientId: 'client-2',
            )).called(1);

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNotNull);
        expect(state.clientName, 'Jane Doe');
        expect(state.isTrainerLed, true);
      });

      test('sets error on API failure', () async {
        when(() => mockRemoteSource.startWorkout(
              clientId: any(named: 'clientId'),
            )).thenThrow(Exception('Failed to start client session'));

        await notifier.startSessionForClient(
          clientId: 'client-2',
          clientName: 'Jane Doe',
        );

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.session, isNull);
        expect(state.clientName, isNull);
        expect(state.isTrainerLed, false);
        expect(state.error, contains('Failed to start client session'));
      });
    });
  });
}
