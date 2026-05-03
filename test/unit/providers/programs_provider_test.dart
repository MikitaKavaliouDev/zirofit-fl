import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProgramsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ProgramsNotifier(apiClient: mockApiClient);
  });

  group('ProgramsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty programs, not loading, no error', () {
      final state = notifier.state;
      expect(state.programs, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchPrograms
    // ---------------------------------------------------------------------------
    test('fetchPrograms sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
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
            ApiConstants.trainerPrograms,
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
            ApiConstants.trainerPrograms,
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
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchPrograms sets error on DioException with error message', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
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
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
          statusCode: 400,
          data: <String, dynamic>{'message': 'Bad request'},
        ),
      ));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Bad request');
    });

    test('fetchPrograms handles connection timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
      ));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Connection timeout. Please try again.');
    });

    test('fetchPrograms handles network error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
      ));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'No internet connection. Please check your network.');
    });

    test('fetchPrograms handles non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchPrograms();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // createProgram
    // ---------------------------------------------------------------------------
    test('createProgram sends POST and returns program on success', () async {
      final responseJson = <String, dynamic>{
        'data': {
          'id': 'new-prog',
          'name': 'New Program',
          'description': 'A new program',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      };

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => responseJson);

      final program = await notifier.createProgram('New Program', 'A new program');

      expect(program, isNotNull);
      expect(program!.id, 'new-prog');
      expect(program.name, 'New Program');
      expect(program.description, 'A new program');
      expect(notifier.state.programs.length, 1);
      expect(notifier.state.programs[0].name, 'New Program');
      expect(notifier.state.isLoading, false);
    });

    test('createProgram without description omits it from body', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'p2',
              'name': 'Minimal',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      final program = await notifier.createProgram('Minimal', null);

      expect(program, isNotNull);
      expect(program!.name, 'Minimal');
      // Verify body does NOT contain description
      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
        body: {'name': 'Minimal'},
      )).called(1);
    });

    test('createProgram returns null on DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Creation failed'},
          },
        ),
      ));

      final program = await notifier.createProgram('Fail', null);

      expect(program, isNull);
      expect(notifier.state.error, 'Creation failed');
    });

    test('createProgram returns null when response has no data', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final program = await notifier.createProgram('No Data', null);

      expect(program, isNull);
    });

    test('createProgram appends to existing programs', () async {
      // First populate with one program
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'existing',
                'name': 'Existing',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchPrograms();
      expect(notifier.state.programs.length, 1);

      // Then create a new one
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'new',
              'name': 'New Program',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      await notifier.createProgram('New Program', null);

      expect(notifier.state.programs.length, 2);
      expect(notifier.state.programs[0].name, 'Existing');
      expect(notifier.state.programs[1].name, 'New Program');
    });
  });
}
