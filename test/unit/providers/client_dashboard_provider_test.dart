import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ClientDashboardNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ClientDashboardNotifier(apiClient: mockApiClient);
  });

  group('ClientDashboardNotifier', () {
    test('initial state has status initial, data=null', () {
      final state = notifier.state;
      expect(state.status, ClientDashboardStatus.initial);
      expect(state.data, isNull);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    group('fetchDashboard', () {
      test('sets data on success', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.loaded);
        expect(state.data, isNotNull);
        expect(state.isLoading, false);
        expect(state.hasError, false);
      });

      test('sets error on API failure', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard))
            .thenThrow(Exception('Network error'));

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.error);
        expect(state.data, isNull);
        expect(state.isLoading, false);
        expect(state.hasError, true);
        expect(state.error, isNotNull);
      });

      test('sets loading state during API call', () async {
        final completer = Completer<void>();
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) => completer.future,
        );

        // Start fetch without awaiting so we can observe the loading state
        final future = notifier.fetchDashboard();

        // State transitions to loading synchronously before first await
        expect(notifier.state.status, ClientDashboardStatus.loading);
        expect(notifier.state.isLoading, true);
        expect(notifier.state.hasError, false);

        completer.complete();
        await future;

        expect(notifier.state.status, ClientDashboardStatus.loaded);
      });

      test('handles DioException connectionTimeout', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: ApiConstants.clientDashboard),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timeout',
          ),
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.error);
        expect(state.hasError, true);
        expect(state.error, contains('Connection timeout'));
      });

      test('handles DioException connectionError', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: ApiConstants.clientDashboard),
            type: DioExceptionType.connectionError,
            message: 'Connection error',
          ),
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.error);
        expect(state.hasError, true);
        expect(state.error, contains('Connection error'));
      });

      test('handles DioException badResponse 401', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: ApiConstants.clientDashboard),
            type: DioExceptionType.badResponse,
            message: 'Unauthorized',
            response: Response(
              requestOptions:
                  RequestOptions(path: ApiConstants.clientDashboard),
              statusCode: 401,
              data: null,
            ),
          ),
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.error);
        expect(state.hasError, true);
        expect(state.error, contains('Unauthorized'));
      });

      test('handles DioException badResponse 500', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: ApiConstants.clientDashboard),
            type: DioExceptionType.badResponse,
            message: 'Internal server error',
            response: Response(
              requestOptions:
                  RequestOptions(path: ApiConstants.clientDashboard),
              statusCode: 500,
              data: null,
            ),
          ),
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.status, ClientDashboardStatus.error);
        expect(state.hasError, true);
        expect(state.error, contains('Internal server error'));
      });

      test('handles empty API response and still sets data', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        await notifier.fetchDashboard();

        // Data is set from mock regardless of API response content
        final state = notifier.state;
        expect(state.data, isNotNull);
        expect(state.data, isA<ClientDashboardData>());
      });

      test('loaded status has correct flags', () async {
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        await notifier.fetchDashboard();

        final state = notifier.state;
        expect(state.isLoaded, true);
        expect(state.isLoading, false);
        expect(state.hasError, false);
        expect(state.data, isNotNull);
      });
    });

    group('refresh', () {
      test('resets previous error on success', () async {
        // First make the API fail
        when(() => mockApiClient.get(ApiConstants.clientDashboard))
            .thenThrow(Exception('Network error'));

        await notifier.fetchDashboard();

        expect(notifier.state.status, ClientDashboardStatus.error);
        expect(notifier.state.hasError, true);

        // Now make refresh succeed
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        await notifier.refresh();

        expect(notifier.state.status, ClientDashboardStatus.loaded);
        expect(notifier.state.hasError, false);
        expect(notifier.state.error, isNull);
        expect(notifier.state.data, isNotNull);
      });

      test('failure preserves existing data', () async {
        // First succeed
        when(() => mockApiClient.get(ApiConstants.clientDashboard)).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        await notifier.fetchDashboard();

        expect(notifier.state.data, isNotNull);

        // Now make refresh fail
        when(() => mockApiClient.get(ApiConstants.clientDashboard))
            .thenThrow(Exception('Refresh error'));

        await notifier.refresh();

        // Error state is set but data from previous successful load is preserved
        expect(notifier.state.status, ClientDashboardStatus.error);
        expect(notifier.state.hasError, true);
        expect(notifier.state.data, isNotNull);
      });
    });

    group('state management', () {
      test('copyWith creates new state instances with modified fields', () {
        const initialState = ClientDashboardState();

        // Modify status
        final loadingState = initialState.copyWith(
          status: ClientDashboardStatus.loading,
        );
        expect(loadingState.status, ClientDashboardStatus.loading);
        expect(loadingState.data, isNull);
        expect(loadingState.error, isNull);
        expect(identical(loadingState, initialState), false);

        // Add data
        final dataState = loadingState.copyWith(
          status: ClientDashboardStatus.loaded,
          data: ClientDashboardData.mock(),
        );
        expect(dataState.status, ClientDashboardStatus.loaded);
        expect(dataState.data, isNotNull);
        expect(identical(dataState, loadingState), false);

        // Add error (data preserved from previous state)
        final errorState = dataState.copyWith(
          status: ClientDashboardStatus.error,
          error: 'test error',
        );
        expect(errorState.status, ClientDashboardStatus.error);
        expect(errorState.error, 'test error');
        expect(errorState.data, isNotNull);

        // Clear error via clearError flag
        final clearedState = errorState.copyWith(
          status: ClientDashboardStatus.loading,
          clearError: true,
        );
        expect(clearedState.status, ClientDashboardStatus.loading);
        expect(clearedState.error, isNull);
        expect(clearedState.data, isNotNull);

        // Original state remains unchanged
        expect(initialState.status, ClientDashboardStatus.initial);
      });
    });
  });
}
