import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/providers/program_assignment_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProgramAssignmentNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ProgramAssignmentNotifier(apiClient: mockApiClient);
  });

  group('ProgramAssignmentNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty programs, not loading, not assigning, '
        'no error, no success', () {
      final state = notifier.state;
      expect(state.programs, isEmpty);
      expect(state.isLoading, false);
      expect(state.isAssigning, false);
      expect(state.assignSuccess, false);
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

    test('fetchPrograms sets error on DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Failed to load programs'},
          },
        ),
      ));

      await notifier.fetchPrograms();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Failed to load programs');
      expect(state.programs, isEmpty);
    });

    test('fetchPrograms resets assignSuccess to false', () async {
      // First perform a successful assign
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});
      await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );
      expect(notifier.state.assignSuccess, true);

      // Then fetch programs
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchPrograms();

      expect(notifier.state.assignSuccess, false);
    });

    // ---------------------------------------------------------------------------
    // assignProgram
    // ---------------------------------------------------------------------------
    test('assignProgram sends correct params', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final result = await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(result, isNull);
      expect(notifier.state.isAssigning, false);
      expect(notifier.state.assignSuccess, true);

      // Verify correct body was sent
      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.programAssign('prog-1'),
        body: {'clientId': 'client-1'},
      )).called(1);
    });

    test('assignProgram sets isAssigning true before completion', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final future = notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );
      expect(notifier.state.isAssigning, isTrue);
      await future;
      expect(notifier.state.isAssigning, isFalse);
    });

    test('assignProgram returns error on DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: ApiConstants.programAssign('prog-1')),
        response: Response(
          requestOptions: RequestOptions(
              path: ApiConstants.programAssign('prog-1')),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Assignment failed'},
          },
        ),
      ));

      final result = await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(result, 'Assignment failed');
      expect(notifier.state.assignSuccess, false);
      expect(notifier.state.isAssigning, false);
    });

    test('assignProgram handles connection timeout', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions:
            RequestOptions(path: ApiConstants.programAssign('prog-1')),
      ));

      final result = await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(result, 'Connection timeout. Please try again.');
      expect(notifier.state.assignSuccess, false);
    });

    test('assignProgram handles network error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.programAssign('prog-1')),
      ));

      final result = await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(result, 'No internet connection. Please check your network.');
    });

    test('assignProgram handles non-Dio exception', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Unexpected error'));

      final result = await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(result, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // resetSuccess
    // ---------------------------------------------------------------------------
    test('resetSuccess sets assignSuccess to false', () async {
      // First assign a program to set success flag
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.programAssign('prog-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.assignProgram(
        programId: 'prog-1',
        clientId: 'client-1',
      );

      expect(notifier.state.assignSuccess, true);

      notifier.resetSuccess();
      expect(notifier.state.assignSuccess, false);
    });
  });
}
