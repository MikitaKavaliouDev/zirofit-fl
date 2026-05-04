import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

// ---------------------------------------------------------------------------
// Dashboard Data Models
// ---------------------------------------------------------------------------

/// Last workout summary
class LastWorkoutSummary {
  final DateTime date;
  final int exercisesCompleted;
  final int totalExercises;
  final Duration duration;
  final int caloriesBurned;

  const LastWorkoutSummary({
    required this.date,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.duration,
    required this.caloriesBurned,
  });

  factory LastWorkoutSummary.mock() {
    final now = DateTime.now();
    return LastWorkoutSummary(
      date: now.subtract(const Duration(days: 1)),
      exercisesCompleted: 8,
      totalExercises: 10,
      duration: const Duration(minutes: 45),
      caloriesBurned: 320,
    );
  }
}

/// Progress summary for the client
class ProgressSummary {
  final double weightChange;
  final int workoutStreak;
  final int totalWorkoutsThisMonth;
  final double? currentWeight;
  final double? startingWeight;

  const ProgressSummary({
    required this.weightChange,
    required this.workoutStreak,
    required this.totalWorkoutsThisMonth,
    this.currentWeight,
    this.startingWeight,
  });

  factory ProgressSummary.mock() {
    return const ProgressSummary(
      weightChange: -2.5,
      workoutStreak: 7,
      totalWorkoutsThisMonth: 12,
      currentWeight: 75.0,
      startingWeight: 77.5,
    );
  }
}

/// Check-in status
class CheckInStatus {
  final bool isDueToday;
  final bool isCompleted;
  final DateTime? lastCheckInDate;
  final DateTime? nextCheckInDate;

  const CheckInStatus({
    required this.isDueToday,
    required this.isCompleted,
    this.lastCheckInDate,
    this.nextCheckInDate,
  });

  factory CheckInStatus.mock() {
    final now = DateTime.now();
    return CheckInStatus(
      isDueToday: true,
      isCompleted: false,
      lastCheckInDate: now.subtract(const Duration(days: 7)),
      nextCheckInDate: now,
    );
  }
}

/// Complete client dashboard data
class ClientDashboardData {
  final LastWorkoutSummary lastWorkout;
  final List<WorkoutSession> upcomingSessions;
  final CheckInStatus checkInStatus;
  final ProgressSummary progress;
  final String? trainerName;

  const ClientDashboardData({
    required this.lastWorkout,
    required this.upcomingSessions,
    required this.checkInStatus,
    required this.progress,
    this.trainerName,
  });

  factory ClientDashboardData.mock() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ClientDashboardData(
      lastWorkout: LastWorkoutSummary.mock(),
      upcomingSessions: [
        WorkoutSession(
          id: '1',
          clientId: 'my-client-id',
          name: 'Upper Body Strength',
          startTime: today.add(const Duration(days: 1, hours: 10)),
          status: WorkoutSessionStatus.planned,
          isTrainerLed: true,
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: '2',
          clientId: 'my-client-id',
          name: 'Cardio & Core',
          startTime: today.add(const Duration(days: 2, hours: 14)),
          status: WorkoutSessionStatus.planned,
          isTrainerLed: false,
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: '3',
          clientId: 'my-client-id',
          name: 'Full Body HIIT',
          startTime: today.add(const Duration(days: 4, hours: 9)),
          status: WorkoutSessionStatus.planned,
          isTrainerLed: true,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      checkInStatus: CheckInStatus.mock(),
      progress: ProgressSummary.mock(),
      trainerName: 'Coach Mike',
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum ClientDashboardStatus { initial, loading, loaded, error }

class ClientDashboardState {
  final ClientDashboardStatus status;
  final ClientDashboardData? data;
  final String? error;

  const ClientDashboardState({
    this.status = ClientDashboardStatus.initial,
    this.data,
    this.error,
  });

  ClientDashboardState copyWith({
    ClientDashboardStatus? status,
    ClientDashboardData? data,
    String? error,
    bool clearError = false,
  }) {
    return ClientDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoading => status == ClientDashboardStatus.loading;
  bool get isLoaded => status == ClientDashboardStatus.loaded;
  bool get hasError => status == ClientDashboardStatus.error;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientDashboardNotifier extends StateNotifier<ClientDashboardState> {
  final ApiClient _apiClient;

  ClientDashboardNotifier({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(const ClientDashboardState());

  /// Fetch dashboard data - uses mock data for now
  Future<void> fetchDashboard() async {
    state = state.copyWith(
      status: ClientDashboardStatus.loading,
      clearError: true,
    );

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Call API (mocked in tests; returns mock data until backend is ready)
      await _apiClient.get(ApiConstants.clientDashboard);

      final data = ClientDashboardData.mock();

      state = state.copyWith(status: ClientDashboardStatus.loaded, data: data);
    } catch (e) {
      state = state.copyWith(
        status: ClientDashboardStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }

  /// Mark check-in as completed (optimistic update)
  void markCheckInCompleted() {
    if (state.data != null) {
      final updatedData = ClientDashboardData(
        lastWorkout: state.data!.lastWorkout,
        upcomingSessions: state.data!.upcomingSessions,
        checkInStatus: CheckInStatus(
          isDueToday: state.data!.checkInStatus.isDueToday,
          isCompleted: true,
          lastCheckInDate: DateTime.now(),
          nextCheckInDate: state.data!.checkInStatus.nextCheckInDate,
        ),
        progress: state.data!.progress,
        trainerName: state.data!.trainerName,
      );
      state = state.copyWith(data: updatedData);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final clientDashboardProvider =
    StateNotifierProvider<ClientDashboardNotifier, ClientDashboardState>((ref) {
      final apiClient = ApiClient.instance;
      return ClientDashboardNotifier(apiClient: apiClient);
    });
