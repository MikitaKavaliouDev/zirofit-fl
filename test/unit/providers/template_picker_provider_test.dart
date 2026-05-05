import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/providers/template_picker_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TemplatePickerNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TemplatePickerNotifier(apiClient: mockApiClient);
  });

  group('TemplatePickerNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty templates, not loading, no search query, '
        'no error', () {
      final state = notifier.state;
      expect(state.templates, isEmpty);
      expect(state.isLoading, false);
      expect(state.searchQuery, isNull);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // loadTemplates
    // ---------------------------------------------------------------------------
    test('loadTemplates sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.loadTemplates();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('loadTemplates populates list on success', () async {
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

      await notifier.loadTemplates();

      final state = notifier.state;
      expect(state.templates.length, 1);
      expect(state.templates[0].id, 'tmpl-1');
      expect(state.templates[0].name, 'Full Body Workout');
      expect(state.templates[0].description, 'A complete full body session');
      expect(state.templates[0].programId, 'prog-1');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadTemplates populates multiple templates', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Push Day',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't2',
                'name': 'Pull Day',
                'program_id': 'p1',
                'order': 2,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();

      expect(notifier.state.templates.length, 2);
      expect(notifier.state.templates[0].name, 'Push Day');
      expect(notifier.state.templates[1].name, 'Pull Day');
    });

    test('loadTemplates handles empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.loadTemplates();

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('loadTemplates handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.loadTemplates();

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('loadTemplates sets error on DioException with error message', () async {
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

      await notifier.loadTemplates();

      expect(notifier.state.error, 'Failed to load templates');
      expect(notifier.state.isLoading, false);
    });

    test('loadTemplates handles connection timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions:
            RequestOptions(path: ApiConstants.trainerWorkoutTemplates),
      ));

      await notifier.loadTemplates();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    test('loadTemplates handles network error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.trainerWorkoutTemplates),
      ));

      await notifier.loadTemplates();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('loadTemplates handles non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.loadTemplates();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // search
    // ---------------------------------------------------------------------------
    test('search filters templates by name (case insensitive)', () async {
      // Load templates first
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Push Day',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't2',
                'name': 'Pull Day',
                'program_id': 'p1',
                'order': 2,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't3',
                'name': 'Leg Day',
                'program_id': 'p1',
                'order': 3,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();
      expect(notifier.state.templates.length, 3);

      // Search by name (lowercase)
      notifier.search('push');
      expect(notifier.state.templates.length, 1);
      expect(notifier.state.templates[0].id, 't1');
      expect(notifier.state.searchQuery, 'push');

      // Search by name (uppercase)
      notifier.search('PULL');
      expect(notifier.state.templates.length, 1);
      expect(notifier.state.templates[0].id, 't2');
      expect(notifier.state.searchQuery, 'PULL');
    });

    test('search filters templates by description', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Morning Workout',
                'description': 'Focus on upper body strength',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't2',
                'name': 'Evening Workout',
                'description': 'Focus on lower body power',
                'program_id': 'p1',
                'order': 2,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();
      expect(notifier.state.templates.length, 2);

      // Search by description content
      notifier.search('lower body');
      expect(notifier.state.templates.length, 1);
      expect(notifier.state.templates[0].id, 't2');
    });

    test('search returns all templates when query is empty', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Push Day',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't2',
                'name': 'Pull Day',
                'program_id': 'p1',
                'order': 2,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();
      expect(notifier.state.templates.length, 2);

      // Filter down
      notifier.search('push');
      expect(notifier.state.templates.length, 1);

      // Clear search
      notifier.search('');
      expect(notifier.state.templates.length, 2);
      expect(notifier.state.searchQuery, '');
    });

    test('search returns empty list when no match found', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Push Day',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();

      notifier.search('nonexistent');
      expect(notifier.state.templates, isEmpty);
    });

    test('search does not mutate _allTemplates', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerWorkoutTemplates,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 't1',
                'name': 'Push Day',
                'program_id': 'p1',
                'order': 1,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 't2',
                'name': 'Pull Day',
                'program_id': 'p1',
                'order': 2,
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.loadTemplates();

      // Search for something that only matches one
      notifier.search('push');
      expect(notifier.state.templates.length, 1);
      expect(notifier.state.templates[0].name, 'Push Day');

      // Clear should restore all
      notifier.search('');
      expect(notifier.state.templates.length, 2);
    });

    // ---------------------------------------------------------------------------
    // copyTemplate
    // ---------------------------------------------------------------------------
    test('copyTemplate sets loading true before completion', () async {
      const templateId = 'tmpl-1';
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.templateCopy(templateId),
          )).thenAnswer((_) async => <String, dynamic>{});

      final future = notifier.copyTemplate(templateId);
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('copyTemplate calls the copy endpoint with correct template ID', () async {
      const templateId = 'tmpl-1';
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.templateCopy(templateId),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.copyTemplate(templateId);

      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.templateCopy(templateId),
      )).called(1);
    });

    test('copyTemplate sets error on DioException', () async {
      const templateId = 'tmpl-1';
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.templateCopy(templateId),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.templateCopy(templateId)),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.templateCopy(templateId)),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Copy failed'},
          },
        ),
      ));

      await notifier.copyTemplate(templateId);

      expect(notifier.state.error, 'Copy failed');
    });

    test('copyTemplate handles connection timeout', () async {
      const templateId = 'tmpl-1';
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.templateCopy(templateId),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.templateCopy(templateId)),
      ));

      await notifier.copyTemplate(templateId);

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });
  });
}
