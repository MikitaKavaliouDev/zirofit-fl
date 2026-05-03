import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

// ---------------------------------------------------------------------------
// Dashboard Data Models
// ---------------------------------------------------------------------------

/// Quick stats for the trainer dashboard
class TrainerDashboardStats {
  final double revenue;
  final int activeClients;
  final int todaySessions;
  final int pendingCheckIns;

  const TrainerDashboardStats({
    required this.revenue,
    required this.activeClients,
    required this.todaySessions,
    required this.pendingCheckIns,
  });

  factory TrainerDashboardStats.mock() {
    return const TrainerDashboardStats(
      revenue: 4250.00,
      activeClients: 24,
      todaySessions: 6,
      pendingCheckIns: 3,
    );
  }
}

/// Activity item for the recent activity feed
class ActivityItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  factory ActivityItem.mock({
    required String id,
    required String title,
    required String description,
    required DateTime timestamp,
    required ActivityType type,
  }) {
    return ActivityItem(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      type: type,
    );
  }
}

enum ActivityType {
  checkIn,
  session,
  client,
  payment,
  other,
}

/// Complete trainer dashboard data
class TrainerDashboardData {
  final TrainerDashboardStats stats;
  final List<WorkoutSession> upcomingSessions;
  final List<ActivityItem> recentActivity;
  final List<Client> activeClients;

  const TrainerDashboardData({
    required this.stats,
    required this.upcomingSessions,
    required this.recentActivity,
    required this.activeClients,
  });

  factory TrainerDashboardData.mock() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return TrainerDashboardData(
      stats: TrainerDashboardStats.mock(),
      upcomingSessions: [
        WorkoutSession(
          id: '1',
          clientId: 'client-1',
          name: 'Strength Training - John',
          startTime: today.add(const Duration(hours: 9)),
          status: WorkoutSessionStatus.planned,
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: '2',
          clientId: 'client-2',
          name: 'HIIT Session - Sarah',
          startTime: today.add(const Duration(hours: 11)),
          status: WorkoutSessionStatus.planned,
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: '3',
          clientId: 'client-3',
          name: 'Yoga - Mike',
          startTime: today.add(const Duration(hours: 14)),
          status: WorkoutSessionStatus.planned,
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: '4',
          clientId: 'client-4',
          name: 'Cardio - Emma',
          startTime: today.add(const Duration(hours: 16)),
          status: WorkoutSessionStatus.planned,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      recentActivity: [
        ActivityItem.mock(
          id: '1',
          title: 'Check-in Received',
          description: 'John completed his weekly check-in',
          timestamp: now.subtract(const Duration(minutes: 15)),
          type: ActivityType.checkIn,
        ),
        ActivityItem.mock(
          id: '2',
          title: 'Session Completed',
          description: 'Sarah finished HIIT workout',
          timestamp: now.subtract(const Duration(hours: 1)),
          type: ActivityType.session,
        ),
        ActivityItem.mock(
          id: '3',
          title: 'New Client',
          description: 'Mike joined your training program',
          timestamp: now.subtract(const Duration(hours: 3)),
          type: ActivityType.client,
        ),
        ActivityItem.mock(
          id: '4',
          title: 'Payment Received',
          description: 'Emma paid for monthly package',
          timestamp: now.subtract(const Duration(hours: 5)),
          type: ActivityType.payment,
        ),
        ActivityItem.mock(
          id: '5',
          title: 'Check-in Received',
          description: 'Alex submitted progress photos',
          timestamp: now.subtract(const Duration(hours: 8)),
          type: ActivityType.checkIn,
        ),
      ],
      activeClients: [
        Client(
          id: 'client-1',
          name: 'John Smith',
          email: 'john@example.com',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
        Client(
          id: 'client-2',
          name: 'Sarah Johnson',
          email: 'sarah@example.com',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
        Client(
          id: 'client-3',
          name: 'Mike Williams',
          email: 'mike@example.com',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
        Client(
          id: 'client-4',
          name: 'Emma Davis',
          email: 'emma@example.com',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
        Client(
          id: 'client-5',
          name: 'Alex Brown',
          email: 'alex@example.com',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum TrainerDashboardStatus { initial, loading, loaded, error }

class TrainerDashboardState {
  final TrainerDashboardStatus status;
  final TrainerDashboardData? data;
  final String? error;

  const TrainerDashboardState({
    this.status = TrainerDashboardStatus.initial,
    this.data,
    this.error,
  });

  TrainerDashboardState copyWith({
    TrainerDashboardStatus? status,
    TrainerDashboardData? data,
    String? error,
    bool clearError = false,
  }) {
    return TrainerDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoading => status == TrainerDashboardStatus.loading;
  bool get isLoaded => status == TrainerDashboardStatus.loaded;
  bool get hasError => status == TrainerDashboardStatus.error;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerDashboardNotifier extends StateNotifier<TrainerDashboardState> {
  final ApiClient _apiClient;

  TrainerDashboardNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerDashboardState());

  /// Fetch dashboard data - uses mock data for now
  Future<void> fetchDashboard() async {
    state = state.copyWith(
      status: TrainerDashboardStatus.loading,
      clearError: true,
    );

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Call API (mocked in tests; returns mock data until backend is ready)
      await _apiClient.get('/api/mobile/home');

      final data = TrainerDashboardData.mock();

      state = state.copyWith(
        status: TrainerDashboardStatus.loaded,
        data: data,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrainerDashboardStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final trainerDashboardProvider = StateNotifierProvider<
    TrainerDashboardNotifier, TrainerDashboardState>((ref) {
  final apiClient = ApiClient.instance;
  return TrainerDashboardNotifier(apiClient: apiClient);
});
