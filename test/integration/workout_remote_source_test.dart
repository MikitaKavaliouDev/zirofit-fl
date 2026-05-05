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
// Fixture helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _sessionJson({
  String id = 'test-session-id',
  String status = 'IN_PROGRESS',
}) => {
  'id': id,
  'client_id': 'test-client-id',
  'status': status,
  'start_time': 1700000000000,
  if (status == 'COMPLETED') 'end_time': 1700003600000,
  'created_at': 1700000000000,
  'updated_at': 1700000000000,
};

Map<String, dynamic> _logJson({
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
  'side': side,
  'created_at': 1700000000000,
  'updated_at': 1700000000000,
  if (reps != null) 'reps': reps,
  if (weight != null) 'weight': weight,
  if (order != null) 'order': order,
};

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

  group('WorkoutRemoteSource', () {
    // =========================================================================
    // startWorkout
    // =========================================================================

    group('startWorkout', () {
      test(
        'sends POST /workout-sessions/start with empty body when no templateId',
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
                    as ApiResponse<WorkoutSession> Function(
                      Map<String, dynamic>,
                    );
            // Backend wraps session under a "session" key
            return fromJson({
              'data': {'session': _sessionJson()},
            });
          });

          final result = await remoteSource.startWorkout();

          expect(result, isA<WorkoutSession>());
          verify(
            () => mockApiClient.post<ApiResponse<WorkoutSession>>(
              ApiConstants.workoutStart,
              body: <String, dynamic>{},
              fromJson: any(named: 'fromJson'),
            ),
          ).called(1);
        },
      );

      test('sends templateId in body when provided', () async {
        when(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutStart,
            body: {'templateId': 'tpl-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
          // Backend wraps session under a "session" key
          return fromJson({
            'data': {'session': _sessionJson()},
          });
        });

        await remoteSource.startWorkout(templateId: 'tpl-1');

        verify(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutStart,
            body: {'templateId': 'tpl-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('throws ApiException when response.data is null', () async {
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
            'error': {'message': 'fail'},
          });
        });

        expect(() => remoteSource.startWorkout(), throwsA(isA<ApiException>()));
      });
    });

    // =========================================================================
    // getActiveSession
    // =========================================================================

    group('getActiveSession', () {
      test(
        'sends GET /workout-sessions/live and returns session with logs',
        () async {
          when(
            () => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.workoutLive,
            ),
          ).thenAnswer(
            (_) async => {
              'data': {
                'session': {
                  ..._sessionJson(),
                  'exerciseLogs': [_logJson()],
                },
              },
            },
          );

          final result = await remoteSource.getActiveSession();

          expect(result.session, isA<WorkoutSession>());
          expect(result.logs, hasLength(1));
          verify(
            () => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.workoutLive,
            ),
          ).called(1);
        },
      );

      test('defaults logs to empty list when null', () async {
        when(
          () =>
              mockApiClient.get<Map<String, dynamic>>(ApiConstants.workoutLive),
        ).thenAnswer(
          (_) async => {
            'data': {'session': _sessionJson()},
          },
        );

        final result = await remoteSource.getActiveSession();

        expect(result.logs, isEmpty);
      });

      test('handles flat response without data envelope', () async {
        when(
          () =>
              mockApiClient.get<Map<String, dynamic>>(ApiConstants.workoutLive),
        ).thenAnswer(
          (_) async => {
            'session': _sessionJson(id: 'flat-session'),
            'logs': <Map<String, dynamic>>[],
          },
        );

        final result = await remoteSource.getActiveSession();

        expect(result.session.id, 'flat-session');
      });

      test('parses nested client object from backend response', () async {
        // Backend returns nested client: {"client":{"id":"c-1","name":"Client Name"}}
        when(
          () =>
              mockApiClient.get<Map<String, dynamic>>(ApiConstants.workoutLive),
        ).thenAnswer(
          (_) async => {
            'data': {
              'session': {
                'id': 'session-nested',
                'client': {'id': 'client-nested', 'name': 'John Doe'},
                'start_time': 1700000000000,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              'exerciseLogs': [],
            },
          },
        );

        final result = await remoteSource.getActiveSession();

        expect(result.session.id, 'session-nested');
        expect(result.session.clientId, 'client-nested');
        expect(
          result.session.name,
          'John Doe',
        ); // Should be read from nested client name
      });
    });

    // =========================================================================
    // logExercise
    // =========================================================================

    group('logExercise', () {
      test('sends exercise_id only', () async {
        when(
          () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
            ApiConstants.workoutLive,
            body: {'exerciseId': 'ex-1', 'workoutSessionId': 'sid-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<ClientExerciseLog> Function(
                    Map<String, dynamic>,
                  );
          return fromJson({'data': _logJson(exerciseId: 'ex-1')});
        });

        await remoteSource.logExercise(exerciseId: 'ex-1', workoutSessionId: 'sid-1');

        verify(
          () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
            ApiConstants.workoutLive,
            body: {'exerciseId': 'ex-1', 'workoutSessionId': 'sid-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('sends all optional params when provided', () async {
        when(
          () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
            ApiConstants.workoutLive,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<ClientExerciseLog> Function(
                    Map<String, dynamic>,
                  );
          return fromJson({'data': _logJson(exerciseId: 'ex-1')});
        });

        await remoteSource.logExercise(
          exerciseId: 'ex-1',
          workoutSessionId: 'sid-1',
          reps: 10,
          weight: 100.0,
          side: 'LEFT',
          order: 1,
        );

        verify(
          () => mockApiClient.post<ApiResponse<ClientExerciseLog>>(
            ApiConstants.workoutLive,
            body: {
              'exerciseId': 'ex-1',
              'workoutSessionId': 'sid-1',
              'reps': 10,
              'weight': 100.0,
              'side': 'LEFT',
              'order': 1,
            },
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('throws ApiException when response.data is null', () async {
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
            'error': {'message': 'fail'},
          });
        });

        expect(
          () => remoteSource.logExercise(exerciseId: 'ex-1', workoutSessionId: 'sid-1'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    // =========================================================================
    // finishWorkout
    // =========================================================================

    group('finishWorkout', () {
      test('sends workoutSessionId in body', () async {
        when(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutFinish,
            body: {'workoutSessionId': 'sid-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<WorkoutSession> Function(Map<String, dynamic>);
          // Backend wraps session under a "session" key
          return fromJson({
            'data': {'session': _sessionJson(status: 'COMPLETED')},
          });
        });

        final result = await remoteSource.finishWorkout('sid-1');

        expect(result, isA<WorkoutSession>());
        verify(
          () => mockApiClient.post<ApiResponse<WorkoutSession>>(
            ApiConstants.workoutFinish,
            body: {'workoutSessionId': 'sid-1'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('throws ApiException when response.data is null', () async {
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
            'error': {'message': 'fail'},
          });
        });

        expect(
          () => remoteSource.finishWorkout('sid-1'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    // =========================================================================
    // getHistory
    // =========================================================================

    group('getHistory', () {
      test('sends GET with default limit 20', () async {
        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.workoutHistory,
            queryParams: {'limit': 20},
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

      test('includes cursor when provided', () async {
        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.workoutHistory,
            queryParams: {'limit': 20, 'cursor': 'cur-1'},
          ),
        ).thenAnswer(
          (_) async => {
            'data': {'sessions': <Map<String, dynamic>>[], 'has_more': false},
          },
        );

        await remoteSource.getHistory(cursor: 'cur-1');

        verify(
          () => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.workoutHistory,
            queryParams: {'limit': 20, 'cursor': 'cur-1'},
          ),
        ).called(1);
      });

      test('returns sessions and hasMore', () async {
        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          ),
        ).thenAnswer(
          (_) async => {
            'data': {
              'sessions': [_sessionJson(id: 'h-1')],
              'has_more': true,
            },
          },
        );

        final result = await remoteSource.getHistory();

        expect(result.sessions, hasLength(1));
        expect(result.sessions.first.id, 'h-1');
        expect(result.hasMore, true);
      });

      test('returns empty when no sessions', () async {
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

        final result = await remoteSource.getHistory();

        expect(result.sessions, isEmpty);
        expect(result.hasMore, false);
      });
    });

    // =========================================================================
    // startRest — sessionId in PATH, NO body
    // =========================================================================

    group('startRest', () {
      test('sends POST with sessionId in path, no body', () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => <String, dynamic>{});

        await remoteSource.startRest('sid-1');

        final path = ApiConstants.workoutRestStart('sid-1');
        expect(path, '/workout-sessions/sid-1/rest/start');
        verify(() => mockApiClient.post(path)).called(1);
      });
    });

    // =========================================================================
    // endRest — sessionId in PATH, NO body
    // =========================================================================

    group('endRest', () {
      test('sends POST with sessionId in path, no body', () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => <String, dynamic>{});

        await remoteSource.endRest('sid-1');

        final path = ApiConstants.workoutRestEnd('sid-1');
        expect(path, '/workout-sessions/sid-1/rest/end');
        verify(() => mockApiClient.post(path)).called(1);
      });
    });

    // =========================================================================
    // cancelWorkout — sessionId in PATH, NO body
    // =========================================================================

    group('cancelWorkout', () {
      test('sends POST with sessionId in path, no body', () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => <String, dynamic>{});

        await remoteSource.cancelWorkout('sid-1');

        final path = ApiConstants.workoutCancel('sid-1');
        expect(path, '/workout-sessions/sid-1/cancel');
        verify(() => mockApiClient.post(path)).called(1);
      });
    });
  });
}
