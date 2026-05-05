import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late WorkoutRemoteSource remoteSource;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteSource = WorkoutRemoteSource(apiClient: mockApiClient);
  });

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Map<String, dynamic> workoutSessionJson({
    String id = 'test-session-id',
    String status = 'IN_PROGRESS',
  }) => {
    'id': id,
    'client_id': 'test-client-id',
    'trainer_id': 'test-trainer-id',
    'status': status,
    'start_time': 1700000000000,
    'end_time': null,
    'notes': null,
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  };

  Map<String, dynamic> exerciseLogJson({
    String id = 'test-log-id',
    String exerciseId = 'test-exercise-id',
    String workoutSessionId = 'test-session-id',
    int? reps,
    double? weight,
    String side = 'BOTH',
    int? order,
  }) => {
    'id': id,
    'client_id': 'test-client-id',
    'exercise_id': exerciseId,
    'workout_session_id': workoutSessionId,
    'reps': reps,
    'weight': weight,
    'side': side,
    'order': order,
    'is_completed': null,
    'tempo': null,
    'superset_key': null,
    'order_in_superset': null,
    'sets': null,
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
    'deleted_at': null,
  };

  // ===========================================================================
  // startWorkout
  // ===========================================================================

  group('startWorkout', () {
    test(
      'without templateId sends empty body and returns WorkoutSession',
      () async {
        when(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutStart,
            body: <String, dynamic>{},
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
          // Backend wraps session under a "session" key
          return fromJson({
            'data': {'session': workoutSessionJson()},
          });
        });

        final result = await remoteSource.startWorkout();

        expect(result, isA<WorkoutSession>());
        expect(result.id, 'test-session-id');
        expect(result.clientId, 'test-client-id');
      },
    );

    test('with templateId includes templateId in body', () async {
      when(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          ApiConstants.workoutStart,
          body: {'templateId': 'template-1'},
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
        // Backend wraps session under a "session" key
        return fromJson({
          'data': {'session': workoutSessionJson()},
        });
      });

      await remoteSource.startWorkout(templateId: 'template-1');

      verify(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          ApiConstants.workoutStart,
          body: {'templateId': 'template-1'},
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('response.data is null throws ApiException', () async {
      when(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
        return fromJson({
          'error': {'message': 'Failed to start', 'statusCode': 400},
        });
      });

      expect(() => remoteSource.startWorkout(), throwsA(isA<ApiException>()));
    });

    test('calls correct endpoint', () async {
      when(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
        // Backend wraps session under a "session" key
        return fromJson({
          'data': {'session': workoutSessionJson()},
        });
      });

      await remoteSource.startWorkout();

      verify(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          ApiConstants.workoutStart,
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // getActiveSession
  // ===========================================================================

  group('getActiveSession', () {
    test('returns session and logs when data key is present', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutLive,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'session': {
              ...workoutSessionJson(),
              'exerciseLogs': [exerciseLogJson()],
            },
          },
        },
      );

      final (:session, :logs) = await remoteSource.getActiveSession();

      expect(session, isA<WorkoutSession>());
      expect(session.id, 'test-session-id');
      expect(logs, hasLength(1));
      expect(logs.first.id, 'test-log-id');
    });

    test('handles flat response when data key is absent', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutLive,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'session': {
            ...workoutSessionJson(id: 'flat-session'),
            'exerciseLogs': [exerciseLogJson(id: 'flat-log')],
          },
        },
      );

      final (:session, :logs) = await remoteSource.getActiveSession();

      expect(session.id, 'flat-session');
      expect(logs, hasLength(1));
      expect(logs.first.id, 'flat-log');
    });

    test('defaults logs to empty list when logs is null', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutLive,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'session': workoutSessionJson(), 'logs': null},
        },
      );

      final (:session, :logs) = await remoteSource.getActiveSession();

      expect(session, isA<WorkoutSession>());
      expect(logs, isEmpty);
    });

    test('calls correct endpoint', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'session': workoutSessionJson(),
            'logs': <Map<String, dynamic>>[],
          },
        },
      );

      await remoteSource.getActiveSession();

      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutLive,
          queryParams: any(named: 'queryParams'),
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // logExercise
  // ===========================================================================

  group('logExercise', () {
    test('sends only exerciseId when other params are omitted', () async {
      when(
        () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
          ApiConstants.workoutLive,
          body: {'exerciseId': 'ex-1', 'workoutSessionId': 'test-session-id'},
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<ClientExerciseLog> Function(
                  Map<String, dynamic>,
                );
        return fromJson({'data': exerciseLogJson(exerciseId: 'ex-1')});
      });

      final result = await remoteSource.logExercise(exerciseId: 'ex-1', workoutSessionId: 'test-session-id');

      expect(result, isA<ClientExerciseLog>());
      expect(result.exerciseId, 'ex-1');
    });

    test('sends all optional params when provided', () async {
      when(
        () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
          ApiConstants.workoutLive,
          body: {
            'exerciseId': 'ex-1',
            'workoutSessionId': 'test-session-id',
            'reps': 10,
            'weight': 50.0,
            'side': 'LEFT',
            'order': 1,
          },
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<ClientExerciseLog> Function(
                  Map<String, dynamic>,
                );
        return fromJson({
          'data': exerciseLogJson(
            exerciseId: 'ex-1',
            reps: 10,
            weight: 50.0,
            side: 'LEFT',
            order: 1,
          ),
        });
      });

      final result = await remoteSource.logExercise(
        exerciseId: 'ex-1',
        workoutSessionId: 'test-session-id',
        reps: 10,
        weight: 50.0,
        side: 'LEFT',
        order: 1,
      );

      expect(result.reps, 10);
      expect(result.weight, 50.0);
      expect(result.side, 'LEFT');
      expect(result.order, 1);
    });

    test('response.data is null throws ApiException', () async {
      when(
        () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<ClientExerciseLog> Function(
                  Map<String, dynamic>,
                );
        return fromJson({
          'error': {'message': 'Log failed', 'statusCode': 500},
        });
      });

      expect(
        () => remoteSource.logExercise(exerciseId: 'ex-1', workoutSessionId: 'test-session-id'),
        throwsA(isA<ApiException>()),
      );
    });

    test('calls correct endpoint', () async {
      when(
        () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<ClientExerciseLog> Function(
                  Map<String, dynamic>,
                );
        return fromJson({'data': exerciseLogJson()});
      });

      await remoteSource.logExercise(exerciseId: 'ex-1', workoutSessionId: 'test-session-id');

      verify(
        () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
          ApiConstants.workoutLive,
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // finishWorkout
  // ===========================================================================

  group('finishWorkout', () {
    test(
      'includes workoutSessionId in body and returns WorkoutSession',
      () async {
        when(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutFinish,
            body: {'workoutSessionId': 'test-session-id'},
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
          // Backend wraps session under a "session" key
          return fromJson({
            'data': {'session': workoutSessionJson(status: 'COMPLETED')},
          });
        });

        final result = await remoteSource.finishWorkout('test-session-id');

        expect(result, isA<WorkoutSession>());
        expect(result.id, 'test-session-id');
      },
    );

    test('response.data is null throws ApiException', () async {
      when(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
        return fromJson({
          'error': {'message': 'Finish failed', 'statusCode': 400},
        });
      });

      expect(
        () => remoteSource.finishWorkout('test-session-id'),
        throwsA(isA<ApiException>()),
      );
    });

    test('calls correct endpoint', () async {
      when(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          any(),
          body: any(named: 'body'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
        // Backend wraps session under a "session" key
        return fromJson({
          'data': {'session': workoutSessionJson()},
        });
      });

      await remoteSource.finishWorkout('test-session-id');

      verify(
        () => mockApiClient.post<ApiResponse<WorkoutSession>>(
          ApiConstants.workoutFinish,
          body: {'workoutSessionId': 'test-session-id'},
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // getHistory
  // ===========================================================================

  group('getHistory', () {
    test('returns sessions without cursor', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'sessions': [workoutSessionJson(id: 'h-1')],
            'has_more': false,
          },
        },
      );

      final (:sessions, :hasMore) = await remoteSource.getHistory();

      expect(sessions, hasLength(1));
      expect(sessions.first.id, 'h-1');
      expect(hasMore, false);
    });

    test('includes cursor in query params when provided', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: {'limit': 20, 'cursor': 'cursor-1'},
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'sessions': [workoutSessionJson()],
            'has_more': false,
          },
        },
      );

      await remoteSource.getHistory(cursor: 'cursor-1');

      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: {'limit': 20, 'cursor': 'cursor-1'},
        ),
      ).called(1);
    });

    test('returns empty list when response has no sessions', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'sessions': <Map<String, dynamic>>[], 'has_more': false},
        },
      );

      final (:sessions, :hasMore) = await remoteSource.getHistory();

      expect(sessions, isEmpty);
      expect(hasMore, false);
    });

    test('hasMore is true when response has_more is true', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'sessions': [workoutSessionJson()],
            'has_more': true,
          },
        },
      );

      final (:sessions, :hasMore) = await remoteSource.getHistory();

      expect(sessions, hasLength(1));
      expect(hasMore, true);
    });

    test('hasMore is false when response has_more is null', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'sessions': [workoutSessionJson()],
          },
        },
      );

      final (:sessions, :hasMore) = await remoteSource.getHistory();

      expect(sessions, hasLength(1));
      expect(hasMore, false);
    });

    test('calls correct endpoint with default limit', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {'sessions': <Map<String, dynamic>>[], 'has_more': false},
        },
      );

      await remoteSource.getHistory();

      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.workoutHistory,
          queryParams: {'limit': 20},
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // startRest
  // ===========================================================================

  group('startRest', () {
    test('calls correct endpoint without body', () async {
      when(
        () => mockApiClient.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await remoteSource.startRest('test-session-id');

      verify(
        () => mockApiClient.post(
          ApiConstants.workoutRestStart('test-session-id'),
        ),
      ).called(1);
    });
  });

  // ===========================================================================
  // endRest
  // ===========================================================================

  group('endRest', () {
    test('calls correct endpoint without body', () async {
      when(
        () => mockApiClient.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await remoteSource.endRest('test-session-id');

      verify(
        () =>
            mockApiClient.post(ApiConstants.workoutRestEnd('test-session-id')),
      ).called(1);
    });
  });

  // ===========================================================================
  // cancelWorkout
  // ===========================================================================

  group('cancelWorkout', () {
    test('calls correct endpoint without body', () async {
      when(
        () => mockApiClient.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await remoteSource.cancelWorkout('test-session-id');

      verify(
        () => mockApiClient.post(ApiConstants.workoutCancel('test-session-id')),
      ).called(1);
    });
  });
}
