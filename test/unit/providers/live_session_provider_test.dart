import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/clients/providers/live_session_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Provider unit tests — test fetch/parse logic WITHOUT Timer.periodic.
/// We test the notifier's ability to fetch and parse session data by calling
/// its internal fetch via the mock API client. Polling timer behavior is
/// tested separately via state checks only (not timer ticks).
void main() {
  const testClientId = 'test-client-id';
  late MockApiClient mockApiClient;
  late LiveSessionNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = LiveSessionNotifier(apiClient: mockApiClient);
  });

  tearDown(() {
    notifier.stopPolling();
    notifier.dispose();
  });

  WorkoutSession createSession({
    String id = 'ws-1',
    WorkoutSessionStatus status = WorkoutSessionStatus.inProgress,
  }) {
    return WorkoutSession(
      id: id,
      clientId: testClientId,
      startTime: DateTime.now(),
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> buildActiveSessionResponse({
    WorkoutSession? session,
    List<Map<String, dynamic>>? logs,
  }) {
    final s = session ?? createSession();
    return {
      'data': {
        'session': {
          ...s.toJson(),
          'exerciseLogs': logs ?? [],
        },
      },
    };
  }

  group('LiveSessionNotifier', () {
    test('initial state has session=null, loading flags false', () {
      final state = notifier.state;
      expect(state.session, isNull);
      expect(state.exerciseLogs, isEmpty);
      expect(state.isLoading, false);
      expect(state.isPolling, false);
      expect(state.error, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('startPolling sets isPolling to true and triggers fetch', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => buildActiveSessionResponse());

      notifier.startPolling(testClientId);

      // Synchronous after startPolling: isPolling should be true
      expect(notifier.state.isPolling, isTrue);

      // Wait for the fire-and-forget _fetchSession to complete
      await Future(() {});
      await Future(() {});
      await Future(() {});
      await Future(() {});

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.session, isNotNull);
    });

    test('startPolling for same client keeps polling active', () {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => buildActiveSessionResponse());

      notifier.startPolling(testClientId);
      notifier.startPolling(testClientId);
      expect(notifier.state.isPolling, isTrue);
    });

    test('stopPolling cancels polling', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => buildActiveSessionResponse());

      notifier.startPolling(testClientId);
      await Future(() {});
      await Future(() {});
      await Future(() {});

      notifier.stopPolling();
      expect(notifier.state.isPolling, isFalse);
    });

    test('parses session with exercise logs correctly', () async {
      final now = DateTime.now();
      final sessionJson = <String, dynamic>{
        'id': 'ws-1',
        'client_id': testClientId,
        'start_time': now.millisecondsSinceEpoch,
        'status': 'IN_PROGRESS',
        'name': 'Morning Workout',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
        'exerciseLogs': [
          <String, dynamic>{
            'id': 'log-1',
            'client_id': testClientId,
            'exercise_id': 'ex-1',
            'exercise_name': 'Bench Press',
            'reps': 10,
            'weight': 50.0,
            'is_completed': true,
            'side': 'BOTH',
            'workout_session_id': 'ws-1',
            'created_at': now.millisecondsSinceEpoch,
          },
          <String, dynamic>{
            'id': 'log-2',
            'client_id': testClientId,
            'exercise_id': 'ex-2',
            'exercise_name': 'Squat',
            'reps': 8,
            'weight': 80.0,
            'is_completed': false,
            'side': 'BOTH',
            'workout_session_id': 'ws-1',
            'created_at': now.millisecondsSinceEpoch,
          },
        ],
      };

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{
              'session': sessionJson,
              'exerciseLogs': sessionJson['exerciseLogs'] as List<dynamic>,
            },
          });

      notifier.startPolling(testClientId);
      await Future(() {});
      await Future(() {});
      await Future(() {});
      await Future(() {});

      final state = notifier.state;
      expect(state.session, isNotNull);
      expect(state.session!.id, 'ws-1');
      expect(state.session!.name, 'Morning Workout');
      expect(state.session!.status, WorkoutSessionStatus.inProgress);
      expect(state.exerciseLogs.length, 2);
      expect(state.exerciseLogs[0].exerciseName, 'Bench Press');
      expect(state.exerciseLogs[0].isCompleted, isTrue);
      expect(state.exerciseLogs[1].exerciseName, 'Squat');
      expect(state.exerciseLogs[1].isCompleted, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.lastUpdated, isNotNull);
    });

    test('no active session clears data and stops polling', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
        'data': <String, dynamic>{},
      });

      notifier.startPolling(testClientId);
      await Future(() {});
      await Future(() {});
      await Future(() {});
      await Future(() {});

      final state = notifier.state;
      expect(state.session, isNull);
      expect(state.exerciseLogs, isEmpty);
      expect(state.isPolling, isFalse);
      expect(state.lastUpdated, isNotNull);
    });

    test('sets error on API failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientActiveSession(testClientId),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: ApiConstants.clientActiveSession(testClientId)),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(
              path: ApiConstants.clientActiveSession(testClientId)),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Server error'},
          },
        ),
      ));

      notifier.startPolling(testClientId);
      await Future(() {});
      await Future(() {});
      await Future(() {});
      await Future(() {});

      final state = notifier.state;
      expect(state.error, 'Server error');
      expect(state.isLoading, isFalse);
    });

    test('refresh does nothing when no client is set', () async {
      await notifier.refresh();
      expect(notifier.state.session, isNull);
    });
  });
}
