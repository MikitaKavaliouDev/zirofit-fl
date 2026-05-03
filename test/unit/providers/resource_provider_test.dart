import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/resources/providers/resource_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ResourceNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ResourceNotifier(apiClient: mockApiClient);
  });

  group('ResourceNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty resources, not loading, no error, not saving',
        () {
      final state = notifier.state;
      expect(state.resources, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSaving, false);
      expect(state.successMessage, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchResources
    // ---------------------------------------------------------------------------
    test('fetchResources sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.fetchResources();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchResources populates list on success', () async {
      final resourceJson = <String, dynamic>{
        'id': 'resource-1',
        'trainer_id': 'trainer-1',
        'title': 'Workout Plan PDF',
        'description': 'A complete workout plan',
        'file_url': 'https://example.com/workout.pdf',
        'file_type': 'pdf',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [resourceJson],
          });

      await notifier.fetchResources();

      final state = notifier.state;
      expect(state.resources.length, 1);
      expect(state.resources[0].id, 'resource-1');
      expect(state.resources[0].title, 'Workout Plan PDF');
      expect(state.resources[0].description, 'A complete workout plan');
      expect(state.resources[0].fileUrl, 'https://example.com/workout.pdf');
      expect(state.resources[0].fileType, 'pdf');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchResources populates multiple resources', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'title': 'Resource A',
                'file_url': 'https://example.com/a.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 'r2',
                'trainer_id': 't1',
                'title': 'Resource B',
                'file_url': 'https://example.com/b.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchResources();

      expect(notifier.state.resources.length, 2);
      expect(notifier.state.resources[0].title, 'Resource A');
      expect(notifier.state.resources[1].title, 'Resource B');
    });

    test('fetchResources handles empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchResources();

      expect(notifier.state.resources, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchResources handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchResources();

      expect(notifier.state.resources, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchResources sets error on DioException with error message',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResourceVault),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerResourceVault),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Internal server error'},
          },
        ),
      ));

      await notifier.fetchResources();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Internal server error');
      expect(state.resources, isEmpty);
    });

    test('fetchResources sets error on DioException with message field',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResourceVault),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerResourceVault),
          statusCode: 400,
          data: <String, dynamic>{'message': 'Bad request'},
        ),
      ));

      await notifier.fetchResources();

      expect(notifier.state.error, 'Bad request');
    });

    test('fetchResources handles connection timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResourceVault),
      ));

      await notifier.fetchResources();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    test('fetchResources handles network error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResourceVault),
      ));

      await notifier.fetchResources();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('fetchResources handles non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchResources();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // createResource
    // ---------------------------------------------------------------------------
    test('createResource sends POST and returns resource on success',
        () async {
      final responseJson = <String, dynamic>{
        'data': {
          'id': 'new-resource',
          'trainer_id': 'trainer-1',
          'title': 'New Resource',
          'description': 'A new resource',
          'file_url': 'https://example.com/new.pdf',
          'file_type': 'pdf',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      };

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenAnswer((_) async => responseJson);

      final resource =
          await notifier.createResource({'title': 'New Resource'});

      expect(resource, isNotNull);
      expect(resource.id, 'new-resource');
      expect(resource.title, 'New Resource');
      expect(resource.description, 'A new resource');
      expect(notifier.state.resources.length, 1);
      expect(notifier.state.resources[0].title, 'New Resource');
      expect(notifier.state.isSaving, false);
    });

    test('createResource sets isSaving before and after', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'r2',
              'trainer_id': 't1',
              'title': 'Saving Test',
              'file_url': 'https://example.com/test.pdf',
              'file_type': 'pdf',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      final future =
          notifier.createResource({'title': 'Saving Test'});
      expect(notifier.state.isSaving, isTrue);
      await future;
      expect(notifier.state.isSaving, isFalse);
    });

    test('createResource throws and sets error on DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResourceVault),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerResourceVault),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Creation failed'},
          },
        ),
      ));

      expect(
        () => notifier.createResource({'title': 'Fail'}),
        throwsA(isA<DioException>()),
      );
      expect(notifier.state.error, 'Creation failed');
    });

    test('createResource appends to existing resources', () async {
      // First populate with one resource
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'existing',
                'trainer_id': 't1',
                'title': 'Existing',
                'file_url': 'https://example.com/existing.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchResources();
      expect(notifier.state.resources.length, 1);

      // Then create a new one
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'new',
              'trainer_id': 't1',
              'title': 'New Resource',
              'file_url': 'https://example.com/new.pdf',
              'file_type': 'pdf',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      await notifier.createResource({'title': 'New Resource'});

      expect(notifier.state.resources.length, 2);
      expect(notifier.state.resources[0].title, 'Existing');
      expect(notifier.state.resources[1].title, 'New Resource');
    });

    // ---------------------------------------------------------------------------
    // deleteResource
    // ---------------------------------------------------------------------------
    test('deleteResource sends DELETE and removes resource from list',
        () async {
      // First populate with resources
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'title': 'Resource One',
                'file_url': 'https://example.com/one.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 'r2',
                'trainer_id': 't1',
                'title': 'Resource Two',
                'file_url': 'https://example.com/two.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchResources();
      expect(notifier.state.resources.length, 2);

      when(() => mockApiClient.delete(
          ApiConstants.trainerResource('r1')))
          .thenAnswer((_) async => {});

      await notifier.deleteResource('r1');

      expect(notifier.state.resources.length, 1);
      expect(notifier.state.resources[0].id, 'r2');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.successMessage, 'Resource deleted');
    });

    test('deleteResource sets error on DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'title': 'Resource One',
                'file_url': 'https://example.com/one.pdf',
                'file_type': 'pdf',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchResources();

      when(() => mockApiClient.delete(
          ApiConstants.trainerResource('r1')))
          .thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerResource('r1')),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerResource('r1')),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Delete failed'},
          },
        ),
      ));

      await notifier.deleteResource('r1');

      expect(notifier.state.error, 'Delete failed');
      // Resource should still be in the list
      expect(notifier.state.resources.length, 1);
    });

    // ---------------------------------------------------------------------------
    // clearSuccessMessage
    // ---------------------------------------------------------------------------
    test('clearSuccessMessage clears the success message', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchResources();

      when(() => mockApiClient.delete(
          ApiConstants.trainerResource('dummy')))
          .thenAnswer((_) async => {});

      await notifier.deleteResource('dummy');
      expect(notifier.state.successMessage, 'Resource deleted');

      notifier.clearSuccessMessage();
      expect(notifier.state.successMessage, isNull);
    });
  });
}
