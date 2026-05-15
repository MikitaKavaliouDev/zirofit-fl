import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/data/client_program_remote_source.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockClientProgramRemoteSource extends Mock
    implements ClientProgramRemoteSource {}

void main() {
  late MockApiClient mockApiClient;
  late MockClientProgramRemoteSource mockRemoteSource;
  late ClientProgramsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    mockRemoteSource = MockClientProgramRemoteSource();
    notifier = ClientProgramsNotifier(
      apiClient: mockApiClient,
      remoteSource: mockRemoteSource,
    );
  });

  group('ClientProgramsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty programs, empty templates, no active program, '
        'not loading, no error', () {
      final state = notifier.state;
      expect(state.programs, isEmpty);
      expect(state.library?.personalTemplates ?? [], isEmpty);
      expect(state.activeProgramResponse?.program, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchPrograms
    // ---------------------------------------------------------------------------
    test('fetchPrograms sets loading true before completion', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      final future = notifier.fetchPrograms();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchPrograms populates list on success', () async {
      final assignedProgramJson = <String, dynamic>{
        'assignmentId': 'assign-1',
        'startDate': '2024-01-01T00:00:00.000',
        'isActive': true,
        'source': 'trainer',
        'program': <String, dynamic>{
          'id': 'prog-1',
          'name': 'Beginner Full Body',
          'description': 'A great starting program',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      };

      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[assignedProgramJson],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      await notifier.fetchPrograms();

      final state = notifier.state;
      expect(state.programs.length, 1);
      expect(state.programs[0].id, 'prog-1');
      expect(state.programs[0].name, 'Beginner Full Body');
      expect(state.programs[0].description, 'A great starting program');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchPrograms populates multiple programs', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[
                <String, dynamic>{
                  'assignmentId': 'a1',
                  'startDate': '2024-01-01T00:00:00.000',
                  'isActive': true,
                  'source': 'trainer',
                  'program': <String, dynamic>{
                    'id': 'p1',
                    'name': 'Program A',
                    'created_at': 1700000000000,
                    'updated_at': 1700000000000,
                  },
                },
                <String, dynamic>{
                  'assignmentId': 'a2',
                  'startDate': '2024-01-01T00:00:00.000',
                  'isActive': true,
                  'source': 'trainer',
                  'program': <String, dynamic>{
                    'id': 'p2',
                    'name': 'Program B',
                    'created_at': 1700000000000,
                    'updated_at': 1700000000000,
                  },
                },
              ],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      await notifier.fetchPrograms();

      expect(notifier.state.programs.length, 2);
      expect(notifier.state.programs[0].name, 'Program A');
      expect(notifier.state.programs[1].name, 'Program B');
    });

    test('fetchPrograms handles empty data list', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms handles missing data key', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms sets error on DioException with error message', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Internal server error'},
          },
        ),
      ));

      await notifier.fetchPrograms();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Internal server error');
      expect(state.programs, isEmpty);
    });

    test('fetchPrograms sets error on DioException with message field', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
          statusCode: 400,
          data: <String, dynamic>{'message': 'Bad request'},
        ),
      ));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Bad request');
    });

    test('fetchPrograms handles connection timeout', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
      ));

      await notifier.fetchPrograms();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    test('fetchPrograms handles network error', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
      ));

      await notifier.fetchPrograms();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('fetchPrograms handles non-Dio exception', () async {
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // setActiveProgram
    // ---------------------------------------------------------------------------
    test('setActiveProgram sets loading true before completion', () async {
      when(() => mockRemoteSource.setActiveProgram('prog-1'))
          .thenAnswer((_) async => <String, dynamic>{});
      when(() => mockRemoteSource.fetchActiveProgram())
          .thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'program': <String, dynamic>{
                'id': 'prog-1',
                'name': 'Active Program',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              'progress': <String, dynamic>{
                'completedCount': 0,
                'totalCount': 0,
              },
              'templates': <dynamic>[],
            },
          });
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      final future = notifier.setActiveProgram('prog-1');
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('setActiveProgram sets active program on success', () async {
      when(() => mockRemoteSource.setActiveProgram('prog-1'))
          .thenAnswer((_) async => <String, dynamic>{});
      when(() => mockRemoteSource.fetchActiveProgram())
          .thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'program': <String, dynamic>{
                'id': 'prog-1',
                'name': 'Active Program',
                'description': 'Now active',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              'progress': <String, dynamic>{
                'completedCount': 0,
                'totalCount': 0,
              },
              'templates': <dynamic>[],
            },
          });
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      final result = await notifier.setActiveProgram('prog-1');

      expect(result, isTrue);
      final state = notifier.state;
      expect(state.activeProgramResponse?.program, isNotNull);
      expect(state.activeProgramResponse!.program.id, 'prog-1');
      expect(state.activeProgramResponse!.program.name, 'Active Program');
      expect(state.isLoading, false);
      expect(state.error, isNull);

      verify(() => mockRemoteSource.setActiveProgram('prog-1')).called(1);
    });

    test('setActiveProgram returns false when remote source throws', () async {
      when(() => mockRemoteSource.setActiveProgram('prog-1'))
          .thenThrow(Exception('Failed'));

      final result = await notifier.setActiveProgram('prog-1');

      expect(result, isFalse);
      expect(notifier.state.activeProgramResponse?.program, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('setActiveProgram sets error on DioException', () async {
      when(() => mockRemoteSource.setActiveProgram('prog-1'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Activation failed'},
          },
        ),
      ));

      final result = await notifier.setActiveProgram('prog-1');

      expect(result, isFalse);
      expect(notifier.state.error, 'Activation failed');
      expect(notifier.state.activeProgramResponse?.program, isNull);
    });

    // ---------------------------------------------------------------------------
    // clearActiveProgram
    // ---------------------------------------------------------------------------
    test('clearActiveProgram clears active program on success', () async {
      // First activate a program
      when(() => mockRemoteSource.setActiveProgram('prog-1'))
          .thenAnswer((_) async => <String, dynamic>{});
      when(() => mockRemoteSource.fetchActiveProgram())
          .thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'program': <String, dynamic>{
                'id': 'prog-1',
                'name': 'Active Program',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              'progress': <String, dynamic>{
                'completedCount': 0,
                'totalCount': 0,
              },
              'templates': <dynamic>[],
            },
          });
      when(() => mockRemoteSource.fetchLibrary(
            category: any(named: 'category'),
            source: any(named: 'source'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'assignedPrograms': <dynamic>[],
              'personalPrograms': <dynamic>[],
              'personalTemplates': <dynamic>[],
              'systemTemplates': <dynamic>[],
              'categories': <dynamic>[],
            },
          });

      await notifier.setActiveProgram('prog-1');
      expect(notifier.state.activeProgramResponse?.program, isNotNull);

      // Then clear it
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.clearActiveProgram();

      expect(notifier.state.activeProgramResponse?.program, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('clearActiveProgram sets error on DioException', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Clear failed'},
          },
        ),
      ));

      await notifier.clearActiveProgram();

      expect(notifier.state.error, 'Clear failed');
    });
  });
}
