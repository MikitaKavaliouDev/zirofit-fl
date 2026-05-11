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
      // Real API response shape: {"data": {"user":..., "upcoming":[], "stats":{...}}}
      // Stub with proper type matching
      when(() => mockApiClient.get<String>(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'data': {
            'user': {'name': 'Ada Lovelace', 'avatarUrl': 'https://example.com/avatar.jpg', 'username': 'ada-lovelace'},
            'upcoming': [
              {'id': 'sess1', 'clientId': 'client1', 'title': 'Morning Workout', 'startTime': '2026-05-10T09:00:00.000Z'}
            ],
            'stats': {
              'revenue': 1000.0,
              'activeClients': 10,
              'todaySessions': 3,
              'pendingCheckIns': 2
            }
          }
        } as String,
      );

      await notifier.fetchDashboard();

      final state = notifier.state;
      expect(state.status, TrainerDashboardStatus.loaded);
      expect(state.data, isNotNull);
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    test('fetchDashboard sets error on API failure', () async {
      when(() => mockApiClient.get('/mobile/home')).thenThrow(
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

    test('fetchDashboard properly parses real API response into TrainerDashboardData', () async {
      // Real API response shape
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => {
          'data': {
            'user': {'name': 'Ada Lovelace', 'avatarUrl': 'https://example.com/avatar.jpg', 'username': 'ada-lovelace'},
            'upcoming': [
              {'id': 'sess1', 'clientId': 'client1', 'title': 'Morning Workout', 'startTime': '2026-05-10T09:00:00.000Z'},
              {'id': 'sess2', 'clientId': 'client2', 'title': 'Evening Yoga', 'startTime': '2026-05-11T18:00:00.000Z'}
            ],
            'stats': {
              'revenue': 5000.0,
              'activeClients': 25,
              'todaySessions': 5,
              'pendingCheckIns': 3
            }
          }
        },
      );

      await notifier.fetchDashboard();

      final data = notifier.state.data!;

      // --- Stats (parsed from JSON) ---
      expect(data.stats.revenue, 5000.0);
      expect(data.stats.activeClients, 25);
      expect(data.stats.todaySessions, 5);
      expect(data.stats.pendingCheckIns, 3);

      // --- Upcoming sessions (parsed from JSON) ---
      expect(data.upcomingSessions.length, 2);
      expect(data.upcomingSessions[0].name, 'Morning Workout');
      expect(data.upcomingSessions[0].status, WorkoutSessionStatus.planned);
      expect(data.upcomingSessions[1].name, 'Evening Yoga');

      // --- Recent activity (not in API yet) ---
      expect(data.recentActivity.length, 0);

      // --- Active clients (not in API yet) ---
      expect(data.activeClients.length, 0);
    });
  });
}
