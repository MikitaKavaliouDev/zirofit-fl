import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
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

/// Simulates GET /client/dashboard response body
Map<String, dynamic> _clientDashboardResponse() => <String, dynamic>{
      'data': {
        'last_workout': {
          'date': _ts - 86400000,
          'exercises_completed': 8,
          'total_exercises': 10,
          'duration_minutes': 45,
          'calories_burned': 320,
        },
        'upcoming_sessions': [
          {
            'id': 'ws-1',
            'client_id': 'my-client',
            'name': 'Upper Body Strength',
            'start_time': _ts + 86400000,
            'status': 'PLANNED',
            'is_trainer_led': true,
            'created_at': _ts,
            'updated_at': _ts,
          },
        ],
        'check_in_status': {
          'is_due_today': true,
          'is_completed': false,
          'last_check_in_date': _ts - 604800000,
          'next_check_in_date': _ts,
        },
        'progress': {
          'weight_change': -2.5,
          'workout_streak': 7,
          'total_workouts_this_month': 12,
        },
        'trainer_name': 'Coach Mike',
      },
    };

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
      container = createTestContainer(
        overrides: [
          clientDashboardProvider.overrideWith(
            (ref) => ClientDashboardNotifier(apiClient: mockApiClient),
          ),
        ],
      );
    });

    test('initial state has not loaded and has no data', () {
      final state = container.read(clientDashboardProvider);
      expect(state.status, ClientDashboardStatus.initial);
      expect(state.data, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('fetchDashboard loads client dashboard data on success', () async {
      // Arrange — the provider calls GET /api/client/dashboard
      when(
        () => mockApiClient.get(
          ApiConstants.clientDashboard,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'data': {'message': 'ok'},
        },
      );

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
      when(
        () => mockApiClient.get(
          ApiConstants.clientDashboard,
          queryParams: any(named: 'queryParams'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.clientDashboard),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: ApiConstants.clientDashboard),
            data: {'error': 'Internal server error'},
          ),
        ),
      );

      // Act
      await container.read(clientDashboardProvider.notifier).fetchDashboard();

      // Assert
      final state = container.read(clientDashboardProvider);
      expect(state.status, ClientDashboardStatus.error);
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
      expect(state.data, isNull);
    });

    test(
      'markCheckInCompleted optimistically updates check-in status',
      () async {
        // Arrange — first load dashboard data
        when(
          () => mockApiClient.get(
            ApiConstants.clientDashboard,
            queryParams: any(named: 'queryParams'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'data': {'message': 'ok'},
          },
        );

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
      },
    );

    test(
      'fetchDashboard succeeds with real backend response shape',
      () async {
        when(
          () => mockApiClient.get(
            ApiConstants.clientDashboard,
            queryParams: any(named: 'queryParams'),
          ),
        ).thenAnswer((_) async => _clientDashboardResponse());

        await container
            .read(clientDashboardProvider.notifier)
            .fetchDashboard();

        final state = container.read(clientDashboardProvider);
        expect(state.status, ClientDashboardStatus.loaded);
        expect(state.data, isNotNull);
        expect(state.error, isNull);
      },
    );
  });
}
