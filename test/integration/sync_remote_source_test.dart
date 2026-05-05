import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/data/sync/sync_remote_source.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

/// Creates a minimal sync pull backend response with optional changes.
///
/// Backend wraps the sync data in a `data` envelope:
/// ```json
/// { "data": { "changes": {...}, "timestamp": 1704067200000 } }
/// ```
Map<String, dynamic> _pullResponse({
  Map<String, dynamic> changes = const {},
  int timestamp = 1704067200000,
  bool withEnvelope = true,
}) {
  final payload = <String, dynamic>{
    'changes': changes,
    'timestamp': timestamp,
  };
  return withEnvelope ? {'data': payload} : payload;
}

/// Creates a minimal sync push backend response.
///
/// Backend wraps the result in a `data` envelope:
/// ```json
/// { "data": { "timestamp": 1704067200000 } }
/// ```
Map<String, dynamic> _pushResponse({
  int timestamp = 1704067200000,
  bool withEnvelope = true,
}) {
  final payload = <String, dynamic>{'timestamp': timestamp};
  return withEnvelope ? {'data': payload} : payload;
}

/// Builds a Dio [Response] with the given [data].
Response _dioResponse(Map<String, dynamic> data, {String path = ''}) {
  return Response(
    data: data,
    requestOptions: RequestOptions(path: path),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDio mockDio;
  late SyncRemoteSource remoteSource;

  setUp(() {
    mockDio = MockDio();
    remoteSource = SyncRemoteSource(mockDio);
  });

  group('SyncRemoteSource', () {
    group('pull', () {
      test('sends GET /sync/pull with last_pulled_at param', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pullResponse(),
            path: '/sync/pull',
          ),
        );

        await remoteSource.pull(1000);

        verify(
          () => mockDio.get(
            '/sync/pull',
            queryParameters: {'last_pulled_at': 1000},
          ),
        ).called(1);
      });

      test('returns SyncPayload with changes on success', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pullResponse(
              changes: {
                'workout_sessions': {
                  'created': [
                    {'id': 's1', 'name': 'Morning Workout'},
                  ],
                  'updated': <Map<String, dynamic>>[],
                  'deleted': <String>[],
                },
              },
            ),
            path: '/sync/pull',
          ),
        );

        final result = await remoteSource.pull(1000);

        expect(result, isA<SyncPayload>());
        expect(result.timestamp, 1704067200000);
        expect(result.changes, contains('workout_sessions'));
        expect(result.changes['workout_sessions']!.created, hasLength(1));
        expect(
          result.changes['workout_sessions']!.created[0]['id'],
          's1',
        );
        expect(result.changes['workout_sessions']!.updated, isEmpty);
        expect(result.changes['workout_sessions']!.deleted, isEmpty);
      });

      test('handles empty changes', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pullResponse(changes: {}),
            path: '/sync/pull',
          ),
        );

        final result = await remoteSource.pull(1000);

        expect(result, isA<SyncPayload>());
        expect(result.timestamp, 1704067200000);
        expect(result.changes, isEmpty);
      });

      test('handles flat response without data envelope', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pullResponse(changes: {}, withEnvelope: false),
            path: '/sync/pull',
          ),
        );

        // When there's no `data` envelope, the code falls back to the
        // full response body.  The SyncPayload.fromJson expects
        // `{ changes: ..., timestamp: ... }` at the top level.
        final result = await remoteSource.pull(1000);

        expect(result, isA<SyncPayload>());
        expect(result.timestamp, 1704067200000);
      });

      test('throws on network error', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/sync/pull'),
            message: 'Connection refused',
          ),
        );

        expect(
          () => remoteSource.pull(1000),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('push', () {
      test('sends POST /sync/push with changes body', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pushResponse(),
            path: '/sync/push',
          ),
        );

        await remoteSource.push({'workout_sessions': []});

        verify(
          () => mockDio.post(
            '/sync/push',
            data: {'changes': {'workout_sessions': []}},
          ),
        ).called(1);
      });

      test('returns timestamp on success', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pushResponse(timestamp: 1704067200000),
            path: '/sync/push',
          ),
        );

        final result = await remoteSource.push({'workout_sessions': []});

        expect(result, isA<Map<String, dynamic>>());
        expect(result['timestamp'], 1704067200000);
      });

      test('handles flat response without data envelope', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _dioResponse(
            _pushResponse(timestamp: 1704067200001, withEnvelope: false),
            path: '/sync/push',
          ),
        );

        // Without the `data` envelope the full body is returned as-is.
        final result = await remoteSource.push({'workout_sessions': []});

        expect(result, isA<Map<String, dynamic>>());
        // The timestamp comes from the top-level response body.
        expect(result['timestamp'], 1704067200001);
      });

      test('throws on network error', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/sync/push'),
            message: 'Connection refused',
          ),
        );

        expect(
          () => remoteSource.push({'workout_sessions': []}),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
