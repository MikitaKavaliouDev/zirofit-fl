import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  tearDown(() {
    container.dispose();
  });

  group('TrainerDashboardNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        trainerDashboardProvider.overrideWith(
          (ref) => TrainerDashboardNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has not loaded and has no data', () {
      final state = container.read(trainerDashboardProvider);
      expect(state.status, TrainerDashboardStatus.initial);
      expect(state.data, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('fetchDashboard loads trainer dashboard data on success', () async {
      // Arrange — the provider calls GET /api/mobile/home (ignores response body)
      when(() => mockApiClient.get(
            '/api/mobile/home',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'message': 'ok'},
          });

      // Act
      await container.read(trainerDashboardProvider.notifier).fetchDashboard();

      // Assert
      final state = container.read(trainerDashboardProvider);
      expect(state.status, TrainerDashboardStatus.loaded);
      expect(state.isLoaded, isTrue);
      expect(state.data, isNotNull);
      expect(state.error, isNull);

      // Verify mock data shape
      final data = state.data!;
      expect(data.stats, isNotNull);
      expect(data.upcomingSessions, isNotEmpty);
      expect(data.recentActivity, isNotEmpty);
      expect(data.activeClients, isNotEmpty);
      expect(data.stats.activeClients, greaterThan(0));
      expect(data.stats.revenue, greaterThan(0));
    });

    test('fetchDashboard sets error on API failure', () async {
      // Arrange
      when(() => mockApiClient.get(
            '/api/mobile/home',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/mobile/home'),
        type: DioExceptionType.connectionError,
        error: 'No internet connection',
      ));

      // Act
      await container.read(trainerDashboardProvider.notifier).fetchDashboard();

      // Assert
      final state = container.read(trainerDashboardProvider);
      expect(state.status, TrainerDashboardStatus.error);
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
      expect(state.data, isNull);
    });

    test('fetchDashboard transitions through loading state', () async {
      // Arrange — delay the response to observe loading
      when(() => mockApiClient.get(
            '/api/mobile/home',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return <String, dynamic>{'data': {}};
      });

      // Act
      final fetchFuture =
          container.read(trainerDashboardProvider.notifier).fetchDashboard();

      // Should be loading during the request
      expect(container.read(trainerDashboardProvider).isLoading, isTrue);

      await fetchFuture;

      // Should be loaded after completion
      expect(container.read(trainerDashboardProvider).isLoaded, isTrue);
    });

    test('refresh calls fetchDashboard', () async {
      when(() => mockApiClient.get(
            '/api/mobile/home',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': {}});

      await container.read(trainerDashboardProvider.notifier).refresh();

      final state = container.read(trainerDashboardProvider);
      expect(state.isLoaded, isTrue);
      verify(() => mockApiClient.get(
            '/api/mobile/home',
            queryParams: any(named: 'queryParams'),
          )).called(1);
    });
  });

  group('ClientDashboardNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        clientDashboardProvider.overrideWith(
          (ref) => ClientDashboardNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has not loaded and has no data', () {
      final state = container.read(clientDashboardProvider);
      expect(state.status, ClientDashboardStatus.initial);
      expect(state.data, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('fetchDashboard loads client dashboard data on success', () async {
      // Arrange — the provider calls GET /api/mobile/client/dashboard
      when(() => mockApiClient.get(
            '/api/mobile/client/dashboard',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'message': 'ok'},
          });

      // Act
      await container.read(clientDashboardProvider.notifier).fetchDashboard();

      // Assert
      final state = container.read(clientDashboardProvider);
      expect(state.status, ClientDashboardStatus.loaded);
      expect(state.isLoaded, isTrue);
      expect(state.data, isNotNull);
      expect(state.error, isNull);

      // Verify mock data shape
      final data = state.data!;
      expect(data.lastWorkout, isNotNull);
      expect(data.upcomingSessions, isNotEmpty);
      expect(data.checkInStatus, isNotNull);
      expect(data.progress, isNotNull);
      expect(data.trainerName, isNotNull);
    });

    test('fetchDashboard sets error on API failure', () async {
      // Arrange
      when(() => mockApiClient.get(
            '/api/mobile/client/dashboard',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/mobile/client/dashboard'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/api/mobile/client/dashboard'),
          data: {'error': 'Internal server error'},
        ),
      ));

      // Act
      await container.read(clientDashboardProvider.notifier).fetchDashboard();

      // Assert
      final state = container.read(clientDashboardProvider);
      expect(state.status, ClientDashboardStatus.error);
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
      expect(state.data, isNull);
    });

    test('markCheckInCompleted optimistically updates check-in status', () async {
      // Arrange — first load dashboard data
      when(() => mockApiClient.get(
            '/api/mobile/client/dashboard',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'message': 'ok'},
          });

      await container.read(clientDashboardProvider.notifier).fetchDashboard();

      // Verify initial state
      var state = container.read(clientDashboardProvider);
      expect(state.isLoaded, isTrue);
      expect(state.data!.checkInStatus.isCompleted, isFalse);

      // Act
      container.read(clientDashboardProvider.notifier).markCheckInCompleted();

      // Assert
      state = container.read(clientDashboardProvider);
      expect(state.data!.checkInStatus.isCompleted, isTrue);
    });
  });
}
