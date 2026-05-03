import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

class MockWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}

void main() {
  late MockWorkoutRemoteSource mockRemoteSource;
  late ActiveWorkoutNotifier notifier;

  setUp(() {
    mockRemoteSource = MockWorkoutRemoteSource();
    notifier = ActiveWorkoutNotifier(remoteSource: mockRemoteSource);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
  }) {
    return ClientExerciseLog(
      id: id,
      clientId: 'client-1',
      exerciseId: exerciseId,
      workoutSessionId: 'ws-1',
      reps: reps,
      weight: weight,
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
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
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
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
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
        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
            )).thenAnswer((_) async => log);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);
        expect(notifier.state.logs.first.isCompleted, isNull);

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
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
            )).thenAnswer((_) async => log1);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 10, weight: 50);

        when(() => mockRemoteSource.logExercise(
              exerciseId: any(named: 'exerciseId'),
              reps: any(named: 'reps'),
              weight: any(named: 'weight'),
            )).thenAnswer((_) async => log2);

        await notifier.logExercise(exerciseId: 'ex-1', reps: 20, weight: 60);

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
  });
}
