import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/providers/system_config_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_setup.dart';

void main() {
  late MockApiClient mockApiClient;
  late SystemConfigNotifier notifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = SystemConfigNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  Map<String, dynamic> responseWithData(Map<String, dynamic> flags) {
    return <String, dynamic>{'data': flags};
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('flags empty, isLoading=false', () {
      final state = notifier.state;
      expect(state.flags, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SystemConfigState (unit)
  // ---------------------------------------------------------------------------

  group('SystemConfigState', () {
    test('copyWith preserves unspecified fields and clearError works', () {
      const state = SystemConfigState(
        flags: {'key': 'val'},
        isLoading: true,
        error: 'some error',
      );

      // Updating only isLoading keeps flags and error
      final updated = state.copyWith(isLoading: false);
      expect(updated.flags, {'key': 'val'});
      expect(updated.isLoading, false);
      expect(updated.error, 'some error');

      // clearError nullifies error while keeping flags
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
      expect(cleared.flags, {'key': 'val'});
      expect(cleared.isLoading, true);

      // Explicit error overrides
      final overridden = state.copyWith(error: 'new error');
      expect(overridden.error, 'new error');
      expect(overridden.flags, {'key': 'val'});
    });
  });

  // ---------------------------------------------------------------------------
  // fetchConfig
  // ---------------------------------------------------------------------------

  group('fetchConfig', () {
    test('populates flags on success', () async {
      final flags = <String, dynamic>{
        'maintenance_mode': false,
        'blog_enabled': true,
        'max_upload_size_mb': 50,
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData(flags));

      final future = notifier.fetchConfig();
      // Intermediate loading state
      expect(notifier.state.isLoading, true);

      await future;

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.flags['maintenance_mode'], false);
      expect(state.flags['blog_enabled'], true);
      expect(state.flags['max_upload_size_mb'], 50);
      expect(state.error, isNull);
    });

    test('handles empty flags', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData(<String, dynamic>{}));

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.flags, isEmpty);
      expect(state.error, isNull);
    });

    test('sets error on badResponse 500', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.systemConfig),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.systemConfig),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Server error'},
        ),
      ));

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.flags, isEmpty);
      expect(state.error, isNotNull);
    });

    test('sets error on connectionTimeout with loading=false', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.systemConfig),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Connection timeout. Please try again.');
    });

    test('sets error on connectionError', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.systemConfig),
        type: DioExceptionType.connectionError,
      ));

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'No internet connection. Please check your network.');
    });

    test('sets error on unknown Exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Something weird happened'));

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Exception: Something weird happened');
    });

    test('calls correct endpoint (ApiConstants.systemConfig)', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData({}));

      await notifier.fetchConfig();

      verify(() => mockApiClient.get<Map<String, dynamic>>(
        ApiConstants.systemConfig,
        queryParams: any(named: 'queryParams'),
      )).called(1);
    });

    test('does not pass queryParams when none are provided', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData({}));

      await notifier.fetchConfig();

      verify(() => mockApiClient.get<Map<String, dynamic>>(
        ApiConstants.systemConfig,
        queryParams: null,
      )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchConfig – edge cases
  // ---------------------------------------------------------------------------

  group('fetchConfig – edge cases', () {
    test('handles null or missing data key gracefully', () async {
      // Response without 'data' key
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'unexpected': 'value'});

      await notifier.fetchConfig();
      expect(notifier.state.flags, isEmpty);
      expect(notifier.state.error, isNull);

      // Response with null data
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': null});

      await notifier.fetchConfig();
      expect(notifier.state.flags, isEmpty);
      expect(notifier.state.error, isNull);
    });

    test('handles data field that is not a map', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': 'string_value'});

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      // The cast from String to Map throws, caught as error
      expect(state.error, isNotNull);
    });

    test('ignores extra unknown fields in response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{'feature_x': true},
            'meta': <String, dynamic>{'page': 1},
            'status': 'ok',
          });

      await notifier.fetchConfig();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.flags, {'feature_x': true});
      expect(state.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // State behavior
  // ---------------------------------------------------------------------------

  group('state behavior', () {
    test('clearError sets error to null without affecting flags', () async {
      // First cause an error so error is populated
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.systemConfig),
        type: DioExceptionType.connectionError,
      ));

      await notifier.fetchConfig();
      expect(notifier.state.error, isNotNull);

      // Now clear the error
      notifier.clearError();
      expect(notifier.state.error, isNull);
      expect(notifier.state.flags, isEmpty);
    });

    test('flags preserved when subsequent fetch fails', () async {
      // First call succeeds
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData({'feature_x': true}));

      await notifier.fetchConfig();
      expect(notifier.state.flags, {'feature_x': true});
      expect(notifier.state.error, isNull);

      // Second call fails – flags should survive
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.systemConfig),
        type: DioExceptionType.connectionError,
      ));

      await notifier.fetchConfig();

      expect(notifier.state.flags, {'feature_x': true});
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });
  });
}
