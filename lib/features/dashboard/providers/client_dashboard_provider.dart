import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

// ---------------------------------------------------------------------------
// Dashboard Data Models
// ---------------------------------------------------------------------------

/// Last workout summary.
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

  /// Creates a summary from a raw backend workout-session map.
  ///
  /// Backend shape: `{id, startTime, endTime, status, name, exerciseLogs: [{id}], ...}`
  factory LastWorkoutSummary.fromSession(Map<String, dynamic> session) {
    final logs = (session['exerciseLogs'] as List<dynamic>?) ?? [];
    final startTime = readDateTimeOrNull(session, 'start_time', 'startTime');
    final endTime = readDateTimeOrNull(session, 'end_time', 'endTime');
    return LastWorkoutSummary(
      date: endTime ?? startTime ?? DateTime.now(),
      exercisesCompleted: logs.length,
      totalExercises: logs.length,
      duration: (endTime != null && startTime != null)
          ? endTime.difference(startTime)
          : Duration.zero,
      caloriesBurned: 0,
    );
  }
}

/// Progress summary for the client.
///
/// Computed from the backend `clientData.workoutSessions` and
/// `clientData.measurements` arrays.
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

  /// Computes a progress summary from backend data.
  ///
  /// [workoutSessions] — the client's recent workout sessions.
  /// [measurements] — the client's body measurements.
  factory ProgressSummary.compute({
    required List<Map<String, dynamic>> workoutSessions,
    required List<Map<String, dynamic>> measurements,
  }) {
    // Compute totalWorkoutsThisMonth
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthWorkouts = workoutSessions.where((s) {
      final st = readDateTimeOrNull(s, 'end_time', 'endTime');
      return st != null && st.isAfter(monthStart);
    }).length;

    // Compute weight change from measurements
    // Backend: [{id, weightKg, bodyFatPercentage, measurementDate, ...}]
    final sortedMeasurements = List<Map<String, dynamic>>.from(measurements)
      ..sort((a, b) => (a['measurementDate'] as String? ?? '')
          .compareTo(b['measurementDate'] as String? ?? ''));

    final firstWeight =
        sortedMeasurements.isNotEmpty
            ? (sortedMeasurements.first['weightKg'] as num?)?.toDouble()
            : null;
    final lastWeight =
        sortedMeasurements.isNotEmpty
            ? (sortedMeasurements.last['weightKg'] as num?)?.toDouble()
            : null;

    return ProgressSummary(
      weightChange: (firstWeight != null && lastWeight != null)
          ? lastWeight - firstWeight
          : 0.0,
      workoutStreak: 0,
      totalWorkoutsThisMonth: monthWorkouts,
      currentWeight: lastWeight,
      startingWeight: firstWeight,
    );
  }
}

/// Check-in status for the client dashboard.
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

  /// Creates status from the backend `lastCheckIn` field.
  ///
  /// [lastCheckIn] — ISO date string or null.
  factory CheckInStatus.fromLastCheckIn(String? lastCheckIn) {
    final checkInDate = lastCheckIn != null
        ? DateTime.tryParse(lastCheckIn)
        : null;
    return CheckInStatus(
      isDueToday: checkInDate == null,
      isCompleted: checkInDate != null,
      lastCheckInDate: checkInDate,
      nextCheckInDate: null,
    );
  }
}

/// Complete client dashboard data.
///
/// Parsed from `GET /api/client/dashboard` response.
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

  /// Parses from the backend response shape:
  ///
  /// ```json
  /// {
  ///   "clientData": {
  ///     "workoutSessions": [{id, startTime, endTime, status, name, exerciseLogs}],
  ///     "measurements": [{id, measurementDate, weightKg, bodyFatPercentage}],
  ///     "trainer": {name, ...} | null
  ///   },
  ///   "upcomingClientSessions": [{id, title, date, duration}],
  ///   "lastCheckIn": "ISO-date" | null
  /// }
  /// ```
  factory ClientDashboardData.fromJson(Map<String, dynamic> json) {
    final data = json is Map ? json : <String, dynamic>{};

    // clientData nested object
    final clientData = data['clientData'] is Map
        ? data['clientData'] as Map<String, dynamic>
        : <String, dynamic>{};

    // Workout sessions array
    final rawSessions = (clientData['workoutSessions'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    // Last workout = most recent completed/in-progress session
    final sortedSessions = List<Map<String, dynamic>>.of(rawSessions)
      ..sort((a, b) => ((b['endTime'] as String?) ?? (b['startTime'] as String?) ?? '')
          .compareTo((a['endTime'] as String?) ?? (a['startTime'] as String?) ?? ''));
    final lastSession =
        sortedSessions.isNotEmpty ? sortedSessions.first : <String, dynamic>{};

    // Measurements
    final rawMeasurements = (clientData['measurements'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    // Upcoming sessions — mapped from upcomingClientSessions
    final upcomingList = data['upcomingClientSessions'] is List
        ? data['upcomingClientSessions'] as List
        : <dynamic>[];
    final upcomingSessions = upcomingList.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      final startDate = DateTime.tryParse(m['date'] as String? ?? '');
      final endDate = startDate?.add(Duration(minutes: m['duration'] as int? ?? 60));
      return WorkoutSession(
        id: m['id'] as String? ?? '',
        clientId: clientData['id'] as String? ?? '',
        name: m['title'] as String? ?? 'Workout',
        startTime: startDate ?? DateTime.now(),
        endTime: endDate,
        status: WorkoutSessionStatus.planned,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    // Trainer name
    final trainer = clientData['trainer'] as Map<String, dynamic>?;
    final trainerName = trainer?['name'] as String?;

    // Last check-in
    final lastCheckIn = data['lastCheckIn'] as String?;

    return ClientDashboardData(
      lastWorkout: LastWorkoutSummary.fromSession(lastSession),
      upcomingSessions: upcomingSessions,
      checkInStatus: CheckInStatus.fromLastCheckIn(lastCheckIn),
      progress: ProgressSummary.compute(
        workoutSessions: sortedSessions,
        measurements: rawMeasurements,
      ),
      trainerName: trainerName,
    );
  }

  /// Creates a copy with updated check-in status (optimistic update).
  ClientDashboardData copyWithCheckIn({
    required bool isCompleted,
    DateTime? lastCheckInDate,
  }) {
    return ClientDashboardData(
      lastWorkout: lastWorkout,
      upcomingSessions: upcomingSessions,
      checkInStatus: CheckInStatus(
        isDueToday: checkInStatus.isDueToday,
        isCompleted: isCompleted,
        lastCheckInDate: lastCheckInDate ?? checkInStatus.lastCheckInDate,
        nextCheckInDate: checkInStatus.nextCheckInDate,
      ),
      progress: progress,
      trainerName: trainerName,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier - Uses AsyncValue for automatic loading/error handling
// ---------------------------------------------------------------------------

/// Provider that returns AsyncValue<ClientDashboardData> - works with ZiroDataView
final clientDashboardProvider =
    AutoDisposeAsyncNotifierProvider<ClientDashboardNotifier, ClientDashboardData>(
  ClientDashboardNotifier.new,
);

class ClientDashboardNotifier extends AutoDisposeAsyncNotifier<ClientDashboardData> {
  @override
  Future<ClientDashboardData> build() async {
    return _fetchDashboard();
  }

  Future<ClientDashboardData> _fetchDashboard() async {
    final apiClient = ApiClient.instance;

    try {
      // Call API
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiConstants.clientDashboard,
      );

      // Extract data from response {"data": {...}}
      final dataMap = response['data'] as Map<String, dynamic>?;
      
      if (dataMap == null) {
        throw Exception('Client dashboard API returned no data');
      }

      return ClientDashboardData.fromJson(dataMap);
    } catch (e, st) {
      // Log error to terminal for debugging
      debugPrint('❌ client_dashboard_provider ERROR: $e');
      debugPrint('Stack: $st');
      if (e is DioException && e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response body: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Refresh dashboard data - triggers reload
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDashboard());
  }

  /// Mark check-in as completed (optimistic update)
  void markCheckInCompleted() {
    final currentData = state.valueOrNull;
    if (currentData != null) {
      state = AsyncData(
        currentData.copyWithCheckIn(
          isCompleted: true,
          lastCheckInDate: DateTime.now(),
        ),
      );
    }
  }
}