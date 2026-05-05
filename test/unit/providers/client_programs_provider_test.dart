import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ClientProgramsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ClientProgramsNotifier(apiClient: mockApiClient);
  });

  group('ClientProgramsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty programs, empty templates, no active program, '
        'not loading, no error', () {
      final state = notifier.state;
      expect(state.programs, isEmpty);
      expect(state.templates, isEmpty);
      expect(state.activeProgram, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchPrograms
    // ---------------------------------------------------------------------------
    test('fetchPrograms sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.fetchPrograms();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchPrograms populates list on success', () async {
      final programJson = <String, dynamic>{
        'id': 'prog-1',
        'name': 'Beginner Full Body',
        'description': 'A great starting program',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [programJson],
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
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'p1',
                'name': 'Program A',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 'p2',
                'name': 'Program B',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchPrograms();

      expect(notifier.state.programs.length, 2);
      expect(notifier.state.programs[0].name, 'Program A');
      expect(notifier.state.programs[1].name, 'Program B');
    });

    test('fetchPrograms handles empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms sets error on DioException with error message', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
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
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
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
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
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
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
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
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // fetchTemplates
    // ---------------------------------------------------------------------------
    test('fetchTemplates sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.fetchTemplates();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchTemplates populates templates on success', () async {
      final templateJson = <String, dynamic>{
        'id': 'tmpl-1',
        'name': 'Full Body Workout',
        'description': 'A complete full body session',
        'program_id': 'prog-1',
        'order': 1,
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [templateJson],
          });

      await notifier.fetchTemplates();

      final state = notifier.state;
      expect(state.templates.length, 1);
      expect(state.templates[0].id, 'tmpl-1');
      expect(state.templates[0].name, 'Full Body Workout');
      expect(state.templates[0].description, 'A complete full body session');
      expect(state.templates[0].programId, 'prog-1');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchTemplates handles empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchTemplates();

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchTemplates handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchTemplates();

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchTemplates sets error on DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerWorkoutTemplates),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerWorkoutTemplates),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Failed to load templates'},
          },
        ),
      ));

      await notifier.fetchTemplates();

      expect(notifier.state.error, 'Failed to load templates');
      expect(notifier.state.isLoading, false);
    });

    // ---------------------------------------------------------------------------
    // setActiveProgram
    // ---------------------------------------------------------------------------
    test('setActiveProgram sets loading true before completion', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'prog-1',
              'name': 'Active Program',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      final future = notifier.setActiveProgram('prog-1');
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('setActiveProgram sets active program on success', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'prog-1',
              'name': 'Active Program',
              'description': 'Now active',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      await notifier.setActiveProgram('prog-1');

      final state = notifier.state;
      expect(state.activeProgram, isNotNull);
      expect(state.activeProgram!.id, 'prog-1');
      expect(state.activeProgram!.name, 'Active Program');
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Verify correct body was sent
      verify(() => mockApiClient.put<Map<String, dynamic>>(
        ApiConstants.clientActiveProgram,
        body: {'programId': 'prog-1'},
      )).called(1);
    });

    test('setActiveProgram handles null data in response', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{'data': null});

      await notifier.setActiveProgram('prog-1');

      expect(notifier.state.activeProgram, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('setActiveProgram sets error on DioException', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Activation failed'},
          },
        ),
      ));

      await notifier.setActiveProgram('prog-1');

      expect(notifier.state.error, 'Activation failed');
      expect(notifier.state.activeProgram, isNull);
    });

    // ---------------------------------------------------------------------------
    // clearActiveProgram
    // ---------------------------------------------------------------------------
    test('clearActiveProgram clears active program on success', () async {
      // First activate a program
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'prog-1',
              'name': 'Active Program',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      await notifier.setActiveProgram('prog-1');
      expect(notifier.state.activeProgram, isNotNull);

      // Then clear it
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.clearActiveProgram();

      expect(notifier.state.activeProgram, isNull);
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
