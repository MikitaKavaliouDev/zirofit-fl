import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
import '../helpers/test_setup.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures — backend response shapes with snake_case keys
// ---------------------------------------------------------------------------

const _ts = 1700000000000;

/// Simulates GET /mobile/home response body
Map<String, dynamic> _trainerDashboardResponse() => <String, dynamic>{
      'data': {
        'recent_activity': [
          {
            'id': 'act-1',
            'title': 'Check-in Received',
            'description': 'John completed his weekly check-in',
            'timestamp': _ts,
            'type': 'check_in',
          },
        ],
        'upcoming_sessions': [
          {
            'id': 'ws-1',
            'client_id': 'client-1',
            'name': 'Strength Training',
            'start_time': _ts,
            'status': 'PLANNED',
            'is_trainer_led': true,
            'created_at': _ts,
            'updated_at': _ts,
          },
        ],
        'stats': {
          'revenue': 4250.00,
          'active_clients': 24,
          'today_sessions': 6,
          'pending_check_ins': 3,
        },
        'active_clients': [
          {
            'id': 'client-1',
            'name': 'John Smith',
            'email': 'john@example.com',
            'status': 'active',
            'created_at': _ts,
            'updated_at': _ts,
          },
        ],
      },
    };

/// Simulates GET /client/dashboard response body (actual backend shape)
Map<String, dynamic> _clientDashboardResponse() => <String, dynamic>{
      'data': {
        'clientData': {
          'id': 'client-1',
          'userId': 'user-1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'trainer': {
            'id': 'trainer-1',
            'name': 'Coach Mike',
            'username': 'coachmike',
            'email': 'mike@example.com',
          },
          'workoutSessions': [
            {
              'id': 'ws-completed',
              'clientId': 'client-1',
              'name': 'Upper Body',
              'startTime': '2026-05-05T10:00:00.000Z',
              'endTime': '2026-05-05T11:00:00.000Z',
              'status': 'COMPLETED',
              'isTrainerLed': false,
              'exerciseLogs': [
                {'id': 'log-1'},
                {'id': 'log-2'},
                {'id': 'log-3'},
              ],
            },
          ],
          'measurements': [
            {
              'id': 'm-1',
              'measurementDate': '2026-05-01T00:00:00.000Z',
              'weightKg': 80.0,
            },
            {
              'id': 'm-2',
              'measurementDate': '2026-05-05T00:00:00.000Z',
              'weightKg': 78.5,
            },
          ],
        },
        'weightUnit': 'KG',
        'upcomingClientSessions': [
          {
            'id': 'us-1',
            'title': 'Upper Body Strength',
            'date': '2026-05-06T10:00:00.000Z',
            'duration': 60,
          },
        ],
        'lastCheckIn': null,
      },
    };

/// A Dio interceptor that resolves every request with the client dashboard fixture.
class _ClientDashboardMockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        statusMessage: 'OK',
        data: _clientDashboardResponse(),
      ),
    );
  }
}

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
      container = createTestContainer(
        overrides: [
          trainerDashboardProvider.overrideWith(
            (ref) => TrainerDashboardNotifier(apiClient: mockApiClient),
          ),
        ],
      );
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
      when(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'data': {'message': 'ok'},
        },
      );

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
      when(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.mobileHome),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        ),
      );
      // Arrange — delay the response to observe loading
      when(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return <String, dynamic>{'data': {}};
      });

      // Act
      final fetchFuture = container
          .read(trainerDashboardProvider.notifier)
          .fetchDashboard();

      // Should be loading during the request
      expect(container.read(trainerDashboardProvider).isLoading, isTrue);

      await fetchFuture;

      // Should be loaded after completion
      expect(container.read(trainerDashboardProvider).isLoaded, isTrue);
    });

    test('refresh calls fetchDashboard', () async {
      when(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'data': {}});

      await container.read(trainerDashboardProvider.notifier).refresh();

      final state = container.read(trainerDashboardProvider);
      expect(state.isLoaded, isTrue);
      verify(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).called(1);
    });

    test('fetchDashboard succeeds with real backend response shape', () async {
      // The provider ignores the response body, but the request/response
      // cycle must not throw when given the actual backend payload.
      when(
        () => mockApiClient.get(
          ApiConstants.mobileHome,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer((_) async => _trainerDashboardResponse());

      await container.read(trainerDashboardProvider.notifier).fetchDashboard();

      final state = container.read(trainerDashboardProvider);
      expect(state.status, TrainerDashboardStatus.loaded);
      expect(state.data, isNotNull);
      expect(state.error, isNull);
    });
  });

  group('ClientDashboardNotifier', () {
    setUp(() {
      ApiClient.reset();
      configureTestApiClient();
      ApiClient.instance.dio.interceptors
        ..clear()
        ..add(_ClientDashboardMockInterceptor());

      container = createTestContainer();
    });

    test('build loads dashboard data from fixture', () async {
      final dashboard = await container.read(clientDashboardProvider.future);
      expect(dashboard.trainerName, 'Coach Mike');
      expect(dashboard.upcomingSessions, hasLength(1));
      expect(dashboard.checkInStatus.isCompleted, isFalse);
      expect(dashboard.lastWorkout.exercisesCompleted, 3);
      expect(dashboard.progress.currentWeight, 78.5);
    });

    test('markCheckInCompleted optimistically updates check-in status', () async {
      // Force-build the provider by listening
      final sub = container.listen(clientDashboardProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(clientDashboardProvider.future);

      final notifier = container.read(clientDashboardProvider.notifier);
      expect(
        container.read(clientDashboardProvider).requireValue
            .checkInStatus.isCompleted,
        isFalse,
      );

      notifier.markCheckInCompleted();

      expect(
        container.read(clientDashboardProvider).requireValue
            .checkInStatus.isCompleted,
        isTrue,
      );
    });

    test('loads data from real backend response shape', () async {
      final dashboard = await container.read(clientDashboardProvider.future);
      expect(dashboard, isA<ClientDashboardData>());
      expect(dashboard.lastWorkout.exercisesCompleted, greaterThan(0));
    });
  });
}
