import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/transformation_photo_pair.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_transformation_photos_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerTransformationPhotosNotifier notifier;

  late Directory tmpDir;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerTransformationPhotosNotifier(apiClient: mockApiClient);
    // Create a temp directory with dummy image files for multipart tests
    tmpDir = Directory.systemTemp.createTempSync('transformation_test_');
    File('${tmpDir.path}/before.jpg').writeAsStringSync('fake-image-data');
    File('${tmpDir.path}/after.jpg').writeAsStringSync('fake-image-data');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  TransformationPhotoPair createPair({
    String id = 'pair-1',
    String beforeUrl = 'https://example.com/before.jpg',
    String afterUrl = 'https://example.com/after.jpg',
    String? caption = '12-week transformation',
  }) =>
      TransformationPhotoPair(
        id: id,
        beforeImageUrl: beforeUrl,
        afterImageUrl: afterUrl,
        caption: caption,
        createdAt: DateTime(2024, 6, 15),
      );

  Map<String, dynamic> buildListResponse(List<TransformationPhotoPair> pairs) =>
      {
        'data': pairs.map((p) => p.toJson()).toList(),
      };

  group('TrainerTransformationPhotosNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('Test 1: initial state has loading false and empty photos', () {
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isUploading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.photos, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // fetchPhotos – success
    // ---------------------------------------------------------------------------
    test('Test 1: fetchPhotos populates gallery on success', () async {
      final pairs = [
        createPair(id: '1'),
        createPair(id: '2', caption: '8-week progress'),
      ];

      when(() => mockApiClient.get<List<TransformationPhotoPair>>(
            ApiConstants.profileMeTransformations,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => pairs);

      await notifier.fetchPhotos();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.photos.length, 2);
      expect(notifier.state.photos[0].id, '1');
      expect(notifier.state.photos[1].caption, '8-week progress');
      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchPhotos – failure
    // ---------------------------------------------------------------------------
    test('Test 4: fetchPhotos sets error on failure', () async {
      when(() => mockApiClient.get<List<TransformationPhotoPair>>(
            ApiConstants.profileMeTransformations,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Server error'));

      await notifier.fetchPhotos();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.photos, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // uploadPhotos – multipart success
    // ---------------------------------------------------------------------------
    test('Test 2: uploadPhotos sends multipart and refreshes list', () async {
      final mockDio = MockDio();

      // Stub the dio getter on the mock ApiClient
      when(() => mockApiClient.dio).thenReturn(mockDio);

      // Mock the dio.post for FormData upload
      when(() => mockDio.post(
            ApiConstants.profileMeTransformations,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {'message': 'Uploaded'},
          ));

      // After upload, fetchPhotos is called - stub that too
      final pairs = [createPair(id: 'new-1')];
      when(() => mockApiClient.get<List<TransformationPhotoPair>>(
            ApiConstants.profileMeTransformations,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => pairs);

      final error = await notifier.uploadPhotos(
        beforeImagePath: '${tmpDir.path}/before.jpg',
        afterImagePath: '${tmpDir.path}/after.jpg',
        caption: 'Test transformation',
        date: DateTime(2024, 7, 1),
      );

      expect(error, isNull);
      expect(notifier.state.isUploading, false);
      expect(notifier.state.photos.length, 1);
      expect(notifier.state.photos.first.id, 'new-1');

      // Verify the multipart POST was called
      verify(() => mockDio.post(
            ApiConstants.profileMeTransformations,
            data: any(named: 'data'),
          )).called(1);
    });

    // ---------------------------------------------------------------------------
    // uploadPhotos – failure
    // ---------------------------------------------------------------------------
    test('Test 4: uploadPhotos returns error message on failure', () async {
      final mockDio = MockDio();

      // Stub the dio getter on the mock ApiClient
      when(() => mockApiClient.dio).thenReturn(mockDio);

      when(() => mockDio.post(
            ApiConstants.profileMeTransformations,
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          data: {'message': 'Upload failed'},
        ),
      ));

      final error = await notifier.uploadPhotos(
        beforeImagePath: '${tmpDir.path}/before.jpg',
        afterImagePath: '${tmpDir.path}/after.jpg',
      );

      expect(error, isNotNull);
      expect(notifier.state.isUploading, false);
    });

    // ---------------------------------------------------------------------------
    // deletePhoto – success
    // ---------------------------------------------------------------------------
    test('Test 3: deletePhoto removes the pair from state', () async {
      // Pre-populate
      when(() => mockApiClient.get<List<TransformationPhotoPair>>(
            ApiConstants.profileMeTransformations,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [createPair(id: 'p1'), createPair(id: 'p2')]);

      await notifier.fetchPhotos();
      expect(notifier.state.photos.length, 2);

      // Stub DELETE
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeTransformations}/p1',
          )).thenAnswer((_) async => {});

      await notifier.deletePhoto('p1');

      expect(notifier.state.photos.length, 1);
      expect(notifier.state.photos.first.id, 'p2');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // deletePhoto – failure
    // ---------------------------------------------------------------------------
    test('Test 4: deletePhoto sets error on failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeTransformations}/invalid',
          )).thenThrow(Exception('Delete failed'));

      await notifier.deletePhoto('invalid');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });
  });
}
