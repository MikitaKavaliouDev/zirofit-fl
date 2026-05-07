import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_branding_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late TrainerBrandingNotifier notifier;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();

    // Wire mockDio as the dio instance of ApiClient
    when(() => mockApiClient.dio).thenReturn(mockDio);

    notifier = TrainerBrandingNotifier(apiClient: mockApiClient);
  });

  group('TrainerBrandingNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has loading false and null URLs', () {
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isUploading, false);
      expect(notifier.state.bannerUrl, isNull);
      expect(notifier.state.avatarUrl, isNull);
      expect(notifier.state.error, isNull);
      expect(notifier.state.uploadProgress, 0.0);
    });

    // ---------------------------------------------------------------------------
    // fetchBranding
    // ---------------------------------------------------------------------------
    test('fetchBranding populates URLs on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerProfileBranding,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'banner_url': 'https://example.com/banner.jpg',
              'avatar_url': 'https://example.com/avatar.jpg',
            },
          });

      await notifier.fetchBranding();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.bannerUrl, 'https://example.com/banner.jpg');
      expect(notifier.state.avatarUrl, 'https://example.com/avatar.jpg');
      expect(notifier.state.error, isNull);
    });

    test('fetchBranding handles flat response (no data wrapper)', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerProfileBranding,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'banner_url': 'https://example.com/banner.jpg',
            'avatar_url': 'https://example.com/avatar.jpg',
          });

      await notifier.fetchBranding();

      expect(notifier.state.bannerUrl, 'https://example.com/banner.jpg');
      expect(notifier.state.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('fetchBranding sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerProfileBranding,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Network error'));

      await notifier.fetchBranding();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // uploadAvatar
    // ---------------------------------------------------------------------------
    test('uploadAvatar sends multipart and updates avatarUrl', () async {
      // Create a temporary test file
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_avatar.jpg');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProfileAvatar,
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((invocation) async {
        // Invoke progress callback
        final onSendProgress =
            invocation.namedArguments[Symbol('onSendProgress')]
                as void Function(int, int);
        onSendProgress(50, 100);

        return Response<Map<String, dynamic>>(
          data: {'data': {'url': 'https://example.com/new_avatar.jpg'}},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      await notifier.uploadAvatar(tempFile.path);

      expect(notifier.state.isUploading, false);
      expect(notifier.state.avatarUrl, 'https://example.com/new_avatar.jpg');
      expect(notifier.state.error, isNull);

      // Cleanup
      await tempFile.delete();
      await tempDir.delete();
    });

    // ---------------------------------------------------------------------------
    // uploadBanner
    // ---------------------------------------------------------------------------
    test('uploadBanner sends multipart and updates bannerUrl', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_banner.jpg');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProfileBanner,
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((invocation) async {
        final onSendProgress =
            invocation.namedArguments[Symbol('onSendProgress')]
                as void Function(int, int);
        onSendProgress(100, 100);

        return Response<Map<String, dynamic>>(
          data: {'data': {'url': 'https://example.com/new_banner.jpg'}},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      await notifier.uploadBanner(tempFile.path);

      expect(notifier.state.isUploading, false);
      expect(notifier.state.bannerUrl, 'https://example.com/new_banner.jpg');
      expect(notifier.state.error, isNull);

      await tempFile.delete();
      await tempDir.delete();
    });

    test('uploadAvatar handles flat response URL key', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_avatar2.jpg');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProfileAvatar,
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response<Map<String, dynamic>>(
                data: {'url': 'https://example.com/direct_url.jpg'},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      await notifier.uploadAvatar(tempFile.path);

      expect(notifier.state.avatarUrl, 'https://example.com/direct_url.jpg');

      await tempFile.delete();
      await tempDir.delete();
    });

    // ---------------------------------------------------------------------------
    // Error handling
    // ---------------------------------------------------------------------------
    test('uploadAvatar sets error on failure', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/fail_avatar.jpg');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProfileAvatar,
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      await notifier.uploadAvatar(tempFile.path);

      expect(notifier.state.isUploading, false);
      expect(notifier.state.uploadProgress, 0.0);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.avatarUrl, isNull);

      await tempFile.delete();
      await tempDir.delete();
    });

    test('uploadBanner sets error on failure', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/fail_banner.jpg');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProfileBanner,
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          data: {'message': 'File too large'},
          statusCode: 413,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      await notifier.uploadBanner(tempFile.path);

      expect(notifier.state.isUploading, false);
      expect(notifier.state.error, isNotNull);

      await tempFile.delete();
      await tempDir.delete();
    });
  });
}
