import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerDashboardNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerDashboardNotifier(apiClient: mockApiClient);
  });

  group('TrainerDashboardNotifier', () {
    test('initial state has status initial, data=null', () {
      final state = notifier.state;
      expect(state.status, TrainerDashboardStatus.initial);
      expect(state.data, isNull);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    test('fetchDashboard sets data on success', () async {
      when(() => mockApiClient.get('/api/mobile/home')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/mobile/home'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await notifier.fetchDashboard();

      final state = notifier.state;
      expect(state.status, TrainerDashboardStatus.loaded);
      expect(state.data, isNotNull);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    test('fetchDashboard sets error on API failure', () async {
      when(() => mockApiClient.get('/api/mobile/home')).thenThrow(
        Exception('Network error'),
      );

      await notifier.fetchDashboard();

      final state = notifier.state;
      expect(state.status, TrainerDashboardStatus.error);
      expect(state.data, isNull);
      expect(state.isLoading, false);
      expect(state.hasError, true);
      expect(state.error, isNotNull);
    });

    test('fetchDashboard properly parses mock API response into TrainerDashboardData', () async {
      when(() => mockApiClient.get('/api/mobile/home')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/mobile/home'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await notifier.fetchDashboard();

      final data = notifier.state.data!;

      // --- Stats ---
      expect(data.stats.revenue, 4250.00);
      expect(data.stats.activeClients, 24);
      expect(data.stats.todaySessions, 6);
      expect(data.stats.pendingCheckIns, 3);

      // --- Upcoming sessions ---
      expect(data.upcomingSessions.length, 4);
      expect(data.upcomingSessions[0].name, 'Strength Training - John');
      expect(data.upcomingSessions[0].status, WorkoutSessionStatus.planned);
      expect(data.upcomingSessions[1].name, 'HIIT Session - Sarah');
      expect(data.upcomingSessions[2].name, 'Yoga - Mike');
      expect(data.upcomingSessions[3].name, 'Cardio - Emma');

      // --- Recent activity ---
      expect(data.recentActivity.length, 5);
      expect(data.recentActivity[0].type, ActivityType.checkIn);
      expect(data.recentActivity[0].title, 'Check-in Received');
      expect(data.recentActivity[1].type, ActivityType.session);
      expect(data.recentActivity[2].type, ActivityType.client);
      expect(data.recentActivity[3].type, ActivityType.payment);
      expect(data.recentActivity[4].type, ActivityType.checkIn);

      // --- Active clients ---
      expect(data.activeClients.length, 5);
      expect(data.activeClients[0].name, 'John Smith');
      expect(data.activeClients[0].email, 'john@example.com');
      expect(data.activeClients[1].name, 'Sarah Johnson');
      expect(data.activeClients[2].name, 'Mike Williams');
      expect(data.activeClients[3].name, 'Emma Davis');
      expect(data.activeClients[4].name, 'Alex Brown');
    });
  });
}
