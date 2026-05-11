import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

// ---------------------------------------------------------------------------
// Dashboard Data Models
// ---------------------------------------------------------------------------

/// Quick stats for the trainer dashboard.
///
/// Backend response shape from GET /api/mobile/home:
/// ```json
/// {"stats": {"pendingBookings": int, "pendingCheckIns": int, "activeClients": int, "revenue": float}}
/// ```
class TrainerDashboardStats {
  final double revenue;
  final int activeClients;
  final int todaySessions;
  final int pendingCheckIns;
  final int pendingBookings;

  const TrainerDashboardStats({
    required this.revenue,
    required this.activeClients,
    required this.todaySessions,
    required this.pendingCheckIns,
    this.pendingBookings = 0,
  });

  factory TrainerDashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json;
    return TrainerDashboardStats(
      revenue: (stats['revenue'] as num?)?.toDouble() ?? 0.0,
      activeClients: stats['activeClients'] as int? ?? 0,
      // TODO: backend does not yet return todaySessions; remove when endpoint provides it
      todaySessions: 0,
      pendingCheckIns: stats['pendingCheckIns'] as int? ?? 0,
      pendingBookings: stats['pendingBookings'] as int? ?? 0,
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

}

enum ActivityType { checkIn, session, client, payment, other }

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

  factory TrainerDashboardData.fromJson(Map<String, dynamic> json) {
    final data = json;
    final statsJson = data['stats'] is Map ? data['stats'] as Map<String, dynamic> : <String, dynamic>{};
    
    // Parse upcoming sessions
    final upcomingList = data['upcoming'] is List ? data['upcoming'] as List : [];
    final upcomingSessions = upcomingList.map((e) {
      if (e is Map<String, dynamic>) {
        return WorkoutSession(
          id: e['id'] as String? ?? '',
          clientId: e['clientId'] as String? ?? '',
          name: e['title'] as String? ?? 'Workout',
          startTime: e['startTime'] != null 
              ? DateTime.tryParse(e['startTime'] as String) ?? DateTime.now()
              : DateTime.now(),
          status: WorkoutSessionStatus.planned,
          isTrainerLed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return WorkoutSession(
        id: '',
        clientId: '',
        name: 'Workout',
        startTime: DateTime.now(),
        status: WorkoutSessionStatus.planned,
        isTrainerLed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    return TrainerDashboardData(
      stats: TrainerDashboardStats.fromJson(statsJson),
      upcomingSessions: upcomingSessions,
      // TODO: backend response does not yet include recentActivity or activeClients lists
      recentActivity: const <ActivityItem>[],
      activeClients: const <Client>[],
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

  /// Fetch dashboard data from /api/mobile/home
  Future<void> fetchDashboard() async {
    state = state.copyWith(
      status: TrainerDashboardStatus.loading,
      clearError: true,
    );

    try {
      // Call API and parse real response
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.mobileHome,
      );
      
      // API returns {"data": {...}}, extract the data object
      final dataMap = response['data'] as Map<String, dynamic>?;
      
      if (dataMap == null) {
        throw Exception('No data received from /mobile/home API');
      }
      
      final data = TrainerDashboardData.fromJson(dataMap);

      state = state.copyWith(status: TrainerDashboardStatus.loaded, data: data);
    } catch (e, st) {
      // Log error to terminal
      debugPrint('❌ trainer_dashboard_provider ERROR: $e');
      debugPrint('Stack: $st');
      
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

final trainerDashboardProvider =
    StateNotifierProvider<TrainerDashboardNotifier, TrainerDashboardState>((
      ref,
    ) {
      final apiClient = ApiClient.instance;
      return TrainerDashboardNotifier(apiClient: apiClient);
    });
