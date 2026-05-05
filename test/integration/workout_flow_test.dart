import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

WorkoutSession _createSession({
  String id = 'test-session-id',
  WorkoutSessionStatus status = WorkoutSessionStatus.inProgress,
  int startTimeMs = 1700000000000,
  int? endTimeMs,
}) {
  return WorkoutSession(
    id: id,
    clientId: 'test-client-id',
    startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
    endTime: endTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endTimeMs)
        : null,
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
  );
}

ClientExerciseLog _createLog({
  String id = 'test-log-id',
  String sessionId = 'test-session-id',
  String exerciseId = 'test-exercise-id',
  int reps = 10,
  double weight = 80.0,
  bool isCompleted = false,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return ClientExerciseLog(
    id: id,
    clientId: 'test-client-id',
    exerciseId: exerciseId,
    reps: reps,
    weight: weight,
    isCompleted: isCompleted,
    side: 'BOTH',
    workoutSessionId: sessionId,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockWorkoutRemoteSource mockRemoteSource;
  late ProviderContainer container;

  setUp(() {
    mockRemoteSource = MockWorkoutRemoteSource();
    container = createTestContainer(overrides: [
      workoutRemoteSourceProvider.overrideWithValue(mockRemoteSource),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ActiveWorkoutNotifier', () {
    test('initial state is idle', () {
      final state = container.read(activeWorkoutProvider);
      expect(state.isIdle, isTrue);
      expect(state.session, isNull);
      expect(state.logs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('startWorkout creates session and transitions to active', () async {
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      final state = container.read(activeWorkoutProvider);
      expect(state.session, isNotNull);
      expect(state.session!.id, 'test-session-id');
      expect(state.session!.status, WorkoutSessionStatus.inProgress);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasActiveSession, isTrue);
    });

    test('logExercise adds a log entry to state', () async {
      // Arrange: start workout first
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Arrange: mock log exercise
      final log = _createLog(id: 'log-1', reps: 12, weight: 60.0);
      when(() => mockRemoteSource.logExercise(
            exerciseId: any(named: 'exerciseId'),
            workoutSessionId: any(named: 'workoutSessionId'),
            reps: any(named: 'reps'),
            weight: any(named: 'weight'),
          )).thenAnswer((_) async => log);

      // Act
      await container
          .read(activeWorkoutProvider.notifier)
          .logExercise(exerciseId: 'test-exercise-id', reps: 12, weight: 60.0);

      // Assert
      final state = container.read(activeWorkoutProvider);
      expect(state.logs, hasLength(1));
      expect(state.logs.first.id, 'log-1');
      expect(state.logs.first.reps, 12);
      expect(state.logs.first.weight, 60.0);
      expect(state.isLoading, isFalse);
    });

    test('completeSet marks a log entry as completed locally', () async {
      // Arrange: start workout and log an exercise set
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);
      await container.read(activeWorkoutProvider.notifier).startWorkout();

      final log = _createLog(id: 'log-1', isCompleted: false);
      when(() => mockRemoteSource.logExercise(
            exerciseId: any(named: 'exerciseId'),
            workoutSessionId: any(named: 'workoutSessionId'),
            reps: any(named: 'reps'),
            weight: any(named: 'weight'),
          )).thenAnswer((_) async => log);
      await container
          .read(activeWorkoutProvider.notifier)
          .logExercise(exerciseId: 'test-exercise-id');

      // Act: complete the set
      container.read(activeWorkoutProvider.notifier).completeSet('log-1');

      // Assert
      final state = container.read(activeWorkoutProvider);
      expect(state.logs, hasLength(1));
      expect(state.logs.first.isCompleted, isTrue);
    });

    test('finishWorkout resets state and returns completed session', () async {
      // Arrange: start workout
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);
      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Arrange: mock finish
      final completedSession = _createSession(
        id: 'test-session-id',
        status: WorkoutSessionStatus.completed,
        endTimeMs: 1700003600000,
      );
      when(() => mockRemoteSource.finishWorkout(any()))
          .thenAnswer((_) async => completedSession);

      // Act
      final result =
          await container.read(activeWorkoutProvider.notifier).finishWorkout();

      // Assert: state resets
      final state = container.read(activeWorkoutProvider);
      expect(state.isIdle, isTrue);
      expect(state.session, isNull);
      expect(state.logs, isEmpty);

      // Assert: returned completed session
      expect(result, isNotNull);
      expect(result!.status, WorkoutSessionStatus.completed);
    });

    test('sets error state when startWorkout fails', () async {
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenThrow(Exception('Network error'));

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      final state = container.read(activeWorkoutProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
    });

    test('startWorkout with templateId passes templateId to remote source', () async {
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container
          .read(activeWorkoutProvider.notifier)
          .startWorkout(templateId: 'tpl-1');

      final state = container.read(activeWorkoutProvider);
      expect(state.session, isNotNull);
      expect(state.session!.id, 'test-session-id');
      expect(state.hasActiveSession, isTrue);

      verify(() => mockRemoteSource.startWorkout(templateId: 'tpl-1')).called(1);
    });

    test('loadActiveSession returns session and logs', () async {
      final session = _createSession();
      final log = _createLog(id: 'log-1', reps: 12, weight: 60.0);
      when(() => mockRemoteSource.getActiveSession())
          .thenAnswer((_) async => (session: session, logs: [log]));

      await container.read(activeWorkoutProvider.notifier).loadActiveSession();

      final state = container.read(activeWorkoutProvider);
      expect(state.session, isNotNull);
      expect(state.session!.id, 'test-session-id');
      expect(state.logs, hasLength(1));
      expect(state.logs.first.id, 'log-1');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('loadActiveSession with no active session stays idle', () async {
      when(() => mockRemoteSource.getActiveSession())
          .thenThrow(Exception('No active session'));

      await container.read(activeWorkoutProvider.notifier).loadActiveSession();

      final state = container.read(activeWorkoutProvider);
      expect(state.session, isNull);
      expect(state.logs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isIdle, isTrue);
    });

    test('cancelWorkout with no session resets state', () async {
      final state = container.read(activeWorkoutProvider);
      expect(state.isIdle, isTrue);

      await container.read(activeWorkoutProvider.notifier).cancelWorkout();

      final updatedState = container.read(activeWorkoutProvider);
      expect(updatedState.isIdle, isTrue);
      expect(updatedState.session, isNull);
      expect(updatedState.error, isNull);
    });
  });

  group('WorkoutHistoryNotifier', () {
    test('fetchHistory returns completed session in history', () async {
      final completedSession = _createSession(
        id: 'session-completed',
        status: WorkoutSessionStatus.completed,
        endTimeMs: 1700003600000,
      );
      final historyResult = (
        sessions: [completedSession],
        hasMore: false,
      );
      when(() => mockRemoteSource.getHistory(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => historyResult);

      await container.read(workoutHistoryProvider.notifier).fetchHistory();

      final state = container.read(workoutHistoryProvider);
      expect(state.sessions, hasLength(1));
      expect(state.sessions.first.id, 'session-completed');
      expect(state.sessions.first.status, WorkoutSessionStatus.completed);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchHistory handles empty history', () async {
      when(() => mockRemoteSource.getHistory(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => (sessions: <WorkoutSession>[], hasMore: false));

      await container.read(workoutHistoryProvider.notifier).fetchHistory();

      final state = container.read(workoutHistoryProvider);
      expect(state.sessions, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('refresh resets and refetches history', () async {
      // First fetch with one session
      final session = _createSession(id: 'session-1');
      when(() => mockRemoteSource.getHistory(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
      )).thenAnswer((_) async => (sessions: [session], hasMore: false));

      await container.read(workoutHistoryProvider.notifier).fetchHistory();
      expect(container.read(workoutHistoryProvider).sessions, hasLength(1));

      // Refresh now returns two sessions
      final session2 = _createSession(id: 'session-2');
      when(() => mockRemoteSource.getHistory(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
      )).thenAnswer((_) async => (sessions: [session, session2], hasMore: false));

      await container.read(workoutHistoryProvider.notifier).refresh();

      final state = container.read(workoutHistoryProvider);
      expect(state.sessions, hasLength(2));
      expect(state.isLoading, isFalse);
    });
  });

  group('Workout Lifecycle', () {
    test('Full workflow: start → log → complete → finish', () async {
      // Arrange: start workout
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Verify active
      var state = container.read(activeWorkoutProvider);
      expect(state.hasActiveSession, isTrue);
      expect(state.isLoading, isFalse);

      // Arrange: log exercise
      final log = _createLog(id: 'log-1', reps: 10, weight: 80.0);
      when(() => mockRemoteSource.logExercise(
            exerciseId: any(named: 'exerciseId'),
            workoutSessionId: any(named: 'workoutSessionId'),
            reps: any(named: 'reps'),
            weight: any(named: 'weight'),
          )).thenAnswer((_) async => log);

      await container
          .read(activeWorkoutProvider.notifier)
          .logExercise(exerciseId: 'test-exercise-id', reps: 10, weight: 80.0);

      // Verify log added
      state = container.read(activeWorkoutProvider);
      expect(state.logs, hasLength(1));
      expect(state.logs.first.id, 'log-1');

      // Act: complete the set
      container.read(activeWorkoutProvider.notifier).completeSet('log-1');

      // Verify log marked completed
      state = container.read(activeWorkoutProvider);
      expect(state.logs.first.isCompleted, isTrue);

      // Arrange: mock finish
      final completedSession = _createSession(
        id: 'test-session-id',
        status: WorkoutSessionStatus.completed,
        endTimeMs: 1700003600000,
      );
      when(() => mockRemoteSource.finishWorkout(any()))
          .thenAnswer((_) async => completedSession);

      // Act: finish workout
      final result =
          await container.read(activeWorkoutProvider.notifier).finishWorkout();

      // Verify idle + completed session returned
      state = container.read(activeWorkoutProvider);
      expect(state.isIdle, isTrue);
      expect(state.session, isNull);
      expect(state.logs, isEmpty);
      expect(result, isNotNull);
      expect(result!.status, WorkoutSessionStatus.completed);
    });
  });

  group('Cancel Workout', () {
    test('Full workflow: start (no template) → cancel', () async {
      // Arrange: start workout
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Verify active
      var state = container.read(activeWorkoutProvider);
      expect(state.hasActiveSession, isTrue);
      expect(state.isLoading, isFalse);

      // Arrange: mock cancel
      when(() => mockRemoteSource.cancelWorkout(any()))
          .thenAnswer((_) async {});

      // Act: cancel
      await container.read(activeWorkoutProvider.notifier).cancelWorkout();

      // Verify idle
      state = container.read(activeWorkoutProvider);
      expect(state.isIdle, isTrue);
      expect(state.session, isNull);
      expect(state.logs, isEmpty);
      expect(state.error, isNull);
    });
  });

  group('Error Recovery', () {
    test('fail on startWorkout, retry succeeds', () async {
      // First call: mock throws
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenThrow(Exception('Network error'));

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Verify error state
      var state = container.read(activeWorkoutProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);

      // Second call: mock succeeds
      final session = _createSession();
      when(() => mockRemoteSource.startWorkout(
            templateId: any(named: 'templateId'),
          )).thenAnswer((_) async => session);

      await container.read(activeWorkoutProvider.notifier).startWorkout();

      // Verify session is now active (error cleared)
      state = container.read(activeWorkoutProvider);
      expect(state.session, isNotNull);
      expect(state.session!.id, 'test-session-id');
      expect(state.hasActiveSession, isTrue);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });
  });
}
