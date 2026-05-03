import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';
import 'package:zirofit_fl/data/sync/sync_remote_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SyncRemoteSource remoteSource;

  setUp(() {
    mockDio = MockDio();
    remoteSource = SyncRemoteSource(mockDio);
  });

  group('SyncRemoteSource', () {
    // ---------------------------------------------------------------------------
    // pull
    // ---------------------------------------------------------------------------

    group('pull', () {
      test('sends GET to /sync/pull with last_pulled_at query param', () async {
        when(() => mockDio.get(
              '/sync/pull',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/pull'),
              statusCode: 200,
              data: <String, dynamic>{
                'data': <String, dynamic>{
                  'changes': <String, dynamic>{},
                  'timestamp': 2000,
                },
              },
            ));

        await remoteSource.pull(1000);

        verify(() => mockDio.get(
              '/sync/pull',
              queryParameters: {'last_pulled_at': 1000},
        )).called(1);
      });

      test('parses nested data.data response correctly', () async {
        when(() => mockDio.get(
              '/sync/pull',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/pull'),
              statusCode: 200,
              data: {
                'data': {
                  'changes': {
                    'clients': {
                      'created': [
                        {
                          'id': 'client-1',
                          'name': 'John',
                          'created_at': 1700000000000,
                          'updated_at': 1700000000000,
                        },
                      ],
                      'updated': [],
                      'deleted': [],
                    },
                  },
                  'timestamp': 2000,
                },
              },
            ));

        final result = await remoteSource.pull(1500);

        expect(result, isA<SyncPayload>());
        expect(result.timestamp, 2000);
        expect(result.changes.containsKey('clients'), true);
        expect(result.changes['clients']!.created.length, 1);
        expect(result.changes['clients']!.created[0]['name'], 'John');
      });

      test('parses flat response (no data key) correctly', () async {
        when(() => mockDio.get(
              '/sync/pull',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/pull'),
              statusCode: 200,
              data: {
                'changes': {
                  'workout_sessions': {
                    'created': [],
                    'updated': [],
                    'deleted': ['session-deleted-1'],
                  },
                },
                'timestamp': 3000,
              },
            ));

        final result = await remoteSource.pull(2000);

        expect(result.timestamp, 3000);
        expect(result.changes['workout_sessions']!.deleted, [
          'session-deleted-1',
        ]);
      });

      test('handles empty changes gracefully', () async {
        when(() => mockDio.get(
              '/sync/pull',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/pull'),
              statusCode: 200,
              data: <String, dynamic>{
                'data': <String, dynamic>{
                  'changes': <String, dynamic>{},
                  'timestamp': 4000,
                },
              },
            ));

        final result = await remoteSource.pull(3000);

        expect(result.timestamp, 4000);
        expect(result.changes, isEmpty);
      });
    });

    // ---------------------------------------------------------------------------
    // push
    // ---------------------------------------------------------------------------

    group('push', () {
      test('sends POST to /sync/push with changes in body', () async {
        when(() => mockDio.post(
              '/sync/push',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/push'),
              statusCode: 200,
              data: {
                'data': {'timestamp': 5000},
              },
            ));

        final changes = {
          'clients': {
            'created': [
              {'id': 'local-1', 'name': 'Offline Client'},
            ],
            'updated': [],
            'deleted': [],
          },
        };

        await remoteSource.push(changes);

        verify(() => mockDio.post(
              '/sync/push',
              data: {'changes': changes},
        )).called(1);
      });

      test('parses nested data.data response correctly', () async {
        when(() => mockDio.post(
              '/sync/push',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/push'),
              statusCode: 200,
              data: {
                'data': {'timestamp': 6000},
              },
            ));

        final result = await remoteSource.push({});

        expect(result['timestamp'], 6000);
      });

      test('parses flat response (no data key) correctly', () async {
        when(() => mockDio.post(
              '/sync/push',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/push'),
              statusCode: 200,
              data: {
                'timestamp': 7000,
              },
            ));

        final result = await remoteSource.push({});

        expect(result['timestamp'], 7000);
      });

      test('handles empty changes', () async {
        when(() => mockDio.post(
              '/sync/push',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/sync/push'),
              statusCode: 200,
              data: {
                'data': {'timestamp': 8000},
              },
            ));

        final result = await remoteSource.push({});

        expect(result['timestamp'], 8000);
      });
    });
  });
}
