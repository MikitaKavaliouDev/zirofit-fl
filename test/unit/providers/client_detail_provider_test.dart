import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  const testClientId = 'test-client-id';
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late ClientDetailNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    notifier = ClientDetailNotifier(
      apiClient: mockApiClient,
      clientId: testClientId,
    );
  });

  group('ClientDetailNotifier', () {
    test('initial state has client=null, loading flags false', () {
      final state = notifier.state;
      expect(state.client, isNull);
      expect(state.measurements, isEmpty);
      expect(state.photos, isEmpty);
      expect(state.sessions, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------------
    // fetchClient
    // -----------------------------------------------------------------------

    test('fetchClient sets loading true before completion', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'id': testClientId,
          'name': 'Test Client',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      });

      final future = notifier.fetchClient();
      expect(notifier.state.isLoadingClient, isTrue);
      await future;
      expect(notifier.state.isLoadingClient, isFalse);
    });

    test('fetchClient populates client on success', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'id': testClientId,
          'name': 'Jane Doe',
          'email': 'jane@test.com',
          'phone': '+1234567890',
          'status': 'active',
          'trainer_id': 'trainer-1',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      });

      await notifier.fetchClient();

      final state = notifier.state;
      expect(state.client, isNotNull);
      expect(state.client!.id, testClientId);
      expect(state.client!.name, 'Jane Doe');
      expect(state.client!.email, 'jane@test.com');
      expect(state.isLoadingClient, false);
      expect(state.error, isNull);
    });

    test('fetchClient sets error when data is not a map', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': 'not-a-map'});

      await notifier.fetchClient();

      final state = notifier.state;
      expect(state.isLoadingClient, false);
      expect(state.error, 'Client not found');
      expect(state.client, isNull);
    });

    test('fetchClient sets error on failure', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: '${ApiConstants.clients}/$testClientId'),
        response: Response(
          requestOptions:
              RequestOptions(path: '${ApiConstants.clients}/$testClientId'),
          statusCode: 404,
          data: <String, dynamic>{
            'error': {'message': 'Client not found'},
          },
        ),
      ));

      await notifier.fetchClient();

      final state = notifier.state;
      expect(state.isLoadingClient, false);
      expect(state.error, 'Client not found');
      expect(state.client, isNull);
    });

    // -----------------------------------------------------------------------
    // fetchMeasurements
    // -----------------------------------------------------------------------

    test('fetchMeasurements populates measurements list', () async {
      final mockData = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 'm-1',
            'client_id': testClientId,
            'measurement_date': 1700000000000,
            'weight_kg': 75.0,
            'body_fat_percentage': 15.0,
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
        ],
      };
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchMeasurements();

      expect(notifier.state.measurements.length, 1);
      expect(notifier.state.measurements.first.weightKg, 75.0);
      expect(notifier.state.measurements.first.bodyFatPercentage, 15.0);
      expect(notifier.state.isLoadingMeasurements, false);
    });

    test('fetchMeasurements handles empty data', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      await notifier.fetchMeasurements();

      expect(notifier.state.measurements, isEmpty);
      expect(notifier.state.isLoadingMeasurements, false);
    });

    test('fetchMeasurements sets error on failure', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/$testClientId/measurements'),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchMeasurements();

      expect(notifier.state.isLoadingMeasurements, false);
      expect(notifier.state.error,
          'Connection timeout. Please try again.');
    });

    // -----------------------------------------------------------------------
    // fetchPhotos
    // -----------------------------------------------------------------------

    test('fetchPhotos populates photos list', () async {
      final mockData = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 'p-1',
            'client_id': testClientId,
            'photo_date': 1700000000000,
            'image_path': '/photos/test.jpg',
            'caption': 'Front view',
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
        ],
      };
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchPhotos();

      expect(notifier.state.photos.length, 1);
      expect(
          notifier.state.photos.first.imagePath, '/photos/test.jpg');
      expect(
          notifier.state.photos.first.caption, 'Front view');
      expect(notifier.state.isLoadingPhotos, false);
    });

    test('fetchPhotos handles empty data', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': []});

      await notifier.fetchPhotos();

      expect(notifier.state.photos, isEmpty);
      expect(notifier.state.isLoadingPhotos, false);
    });

    test('fetchPhotos sets error on failure', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/$testClientId/photos'),
        type: DioExceptionType.connectionError,
      ));

      await notifier.fetchPhotos();

      expect(notifier.state.isLoadingPhotos, false);
      expect(notifier.state.error,
          'No internet connection. Please check your network.');
    });

    // -----------------------------------------------------------------------
    // fetchSessions
    // -----------------------------------------------------------------------

    test('fetchSessions populates sessions list', () async {
      final mockData = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-1',
            'client_id': testClientId,
            'start_time': 1700000000000,
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
        ],
      };
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchSessions();

      expect(notifier.state.sessions.length, 1);
      expect(notifier.state.sessions.first.id, 's-1');
      expect(notifier.state.isLoadingSessions, false);
    });

    test('fetchSessions handles empty data', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': []});

      await notifier.fetchSessions();

      expect(notifier.state.sessions, isEmpty);
      expect(notifier.state.isLoadingSessions, false);
    });

    test('fetchSessions sets error on failure', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Session fetch failed'));

      await notifier.fetchSessions();

      expect(notifier.state.isLoadingSessions, false);
      expect(notifier.state.error, 'Exception: Session fetch failed');
    });

    // -----------------------------------------------------------------------
    // fetchAll
    // -----------------------------------------------------------------------

    test('fetchAll fetches client, measurements, photos, and sessions',
        () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'id': testClientId,
          'name': 'Test Client',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      });
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': []});
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': []});

      await notifier.fetchAll();

      final state = notifier.state;
      expect(state.client, isNotNull);
      expect(state.client!.name, 'Test Client');
      expect(state.isLoadingClient, false);
      expect(state.isLoadingMeasurements, false);
      expect(state.isLoadingPhotos, false);
      expect(state.isLoadingSessions, false);
    });

    // -----------------------------------------------------------------------
    // addMeasurement
    // -----------------------------------------------------------------------

    test('addMeasurement posts and re-fetches measurements', () async {
      // Mock the POST
      when(() => mockApiClient.post(
            '${ApiConstants.clients}/$testClientId/measurements',
            body: any(named: 'body'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': {'id': 'm-new'}});

      // Mock the subsequent GET from fetchMeasurements
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 'm-1',
            'client_id': testClientId,
            'measurement_date': 1700000000000,
            'weight_kg': 80.0,
            'body_fat_percentage': 18.0,
            'notes': 'Post-test measurement',
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
        ],
      });

      final result = await notifier.addMeasurement(
        measurementDate: DateTime(2024, 1, 15),
        weightKg: 80.0,
        bodyFatPercentage: 18.0,
        notes: 'Post-test measurement',
      );

      expect(result, isNull);
      expect(notifier.state.measurements.length, 1);
      expect(
          notifier.state.measurements.first.weightKg, 80.0);
      expect(notifier.state.measurements.first.bodyFatPercentage,
          18.0);
    });

    test('addMeasurement returns error on failure', () async {
      when(() => mockApiClient.post(
            '${ApiConstants.clients}/$testClientId/measurements',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/$testClientId/measurements'),
        response: Response(
          requestOptions: RequestOptions(
              path: '${ApiConstants.clients}/$testClientId/measurements'),
          statusCode: 400,
          data: <String, dynamic>{
            'error': {'message': 'Invalid measurement data'},
          },
        ),
      ));

      final result = await notifier.addMeasurement(
        measurementDate: DateTime(2024, 1, 15),
        weightKg: -1,
      );

      expect(result, 'Invalid measurement data');
    });

    // -----------------------------------------------------------------------
    // uploadPhoto
    // -----------------------------------------------------------------------

    test('uploadPhoto posts via dio and re-fetches photos', () async {
      // Create a real temp file so MultipartFile.fromFile succeeds
      final tempFile =
          await _createTempFile('upload_test.jpg', 'fake-image-data');

      // Mock the dio.post
      when(() => mockDio.post(
            '${ApiConstants.clients}/$testClientId/photos',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(
                path: '${ApiConstants.clients}/$testClientId/photos'),
            statusCode: 200,
            data: <String, dynamic>{},
          ));

      // Mock the subsequent GET from fetchPhotos
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 'p-1',
            'client_id': testClientId,
            'photo_date': 1700000000000,
            'image_path': '/photos/uploaded.jpg',
            'caption': 'After upload',
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
        ],
      });

      final result = await notifier.uploadPhoto(
        imagePath: tempFile.path,
        photoDate: DateTime(2024, 1, 15),
        caption: 'After upload',
      );

      expect(result, isNull);
      expect(notifier.state.photos.length, 1);
      expect(notifier.state.photos.first.imagePath,
          '/photos/uploaded.jpg');
      expect(
          notifier.state.photos.first.caption, 'After upload');

      // Clean up
      await tempFile.delete();
    });

    test('uploadPhoto returns error on failure', () async {
      // Create a real temp file so MultipartFile.fromFile succeeds
      final tempFile =
          await _createTempFile('upload_fail.jpg', 'fake-data');

      when(() => mockDio.post(
            '${ApiConstants.clients}/$testClientId/photos',
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/$testClientId/photos'),
        response: Response(
          requestOptions: RequestOptions(
              path: '${ApiConstants.clients}/$testClientId/photos'),
          statusCode: 413,
          data: <String, dynamic>{
            'error': {'message': 'File too large'},
          },
        ),
      ));

      final result = await notifier.uploadPhoto(
        imagePath: tempFile.path,
      );

      expect(result, 'File too large');

      // Clean up
      await tempFile.delete();
    });
  });
}

/// Creates a temporary file with the given [name] and [content] for testing
/// file-upload scenarios. The caller is responsible for deleting it.
Future<File> _createTempFile(String name, String content) async {
  final dir = await Directory.systemTemp.createTemp('detail_test_');
  final file = File('${dir.path}/$name');
  await file.writeAsString(content);
  return file;
}
