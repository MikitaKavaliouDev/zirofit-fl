import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

/// Provider for [WorkoutRemoteSource] singleton.
final workoutRemoteSourceProvider = Provider<WorkoutRemoteSource>((ref) {
  return WorkoutRemoteSource(apiClient: ApiClient.instance);
});

/// Remote data source for all workout-related API calls.
///
/// All methods throw [ApiException] on failure.
class WorkoutRemoteSource {
  final ApiClient _apiClient;

  WorkoutRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// POST /api/workout-sessions/start
  /// Starts a new workout session, optionally from a template.
  Future<WorkoutSession> startWorkout({String? templateId}) async {
    final body = <String, dynamic>{};
    if (templateId != null) {
      body['templateId'] = templateId;
    }

    final response = await _apiClient.post<ApiResponse<WorkoutSession>>(
      ApiConstants.workoutStart,
      body: body,
      fromJson: (json) => ApiResponse.fromJson(json, WorkoutSession.fromJson),
    );

    if (response.data == null) {
      throw response.toException();
    }
    return response.data!;
  }

  /// GET /api/workout-sessions/live
  /// Returns the currently active workout session and its exercise logs.
  Future<({WorkoutSession session, List<ClientExerciseLog> logs})>
  getActiveSession() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutLive,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final sessionMap = data['session'] as Map<String, dynamic>;
    final session = WorkoutSession.fromJson(sessionMap);

    // Logs are nested inside session as 'exerciseLogs' (camelCase)
    final logsList =
        (sessionMap['exerciseLogs'] as List<dynamic>?)
            ?.map((e) => ClientExerciseLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return (session: session, logs: logsList);
  }

  /// POST /api/workout-sessions/live
  /// Logs an exercise set in the current workout session.
  Future<ClientExerciseLog> logExercise({
    required String exerciseId,
    int? reps,
    double? weight,
    String? side,
    int? order,
  }) async {
    final body = <String, dynamic>{'exercise_id': exerciseId};
    if (reps != null) body['reps'] = reps;
    if (weight != null) body['weight'] = weight;
    if (side != null) body['side'] = side;
    if (order != null) body['order'] = order;

    final response = await _apiClient.post<ApiResponse<ClientExerciseLog>>(
      ApiConstants.workoutLive,
      body: body,
      fromJson: (json) =>
          ApiResponse.fromJson(json, ClientExerciseLog.fromJson),
    );

    if (response.data == null) {
      throw response.toException();
    }
    return response.data!;
  }

  /// POST /api/workout-sessions/finish
  /// Marks the workout session as completed.
  Future<WorkoutSession> finishWorkout(String sessionId) async {
    final response = await _apiClient.post<ApiResponse<WorkoutSession>>(
      ApiConstants.workoutFinish,
      body: {'workoutSessionId': sessionId},
      fromJson: (json) => ApiResponse.fromJson(json, WorkoutSession.fromJson),
    );

    if (response.data == null) {
      throw response.toException();
    }
    return response.data!;
  }

  /// GET /api/workout-sessions/history
  /// Fetches paginated workout history.
  Future<({List<WorkoutSession> sessions, bool hasMore})> getHistory({
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutHistory,
      queryParams: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final sessions =
        (data['sessions'] as List<dynamic>?)
            ?.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final hasMore = (data['has_more'] as bool?) ?? false;

    return (sessions: sessions, hasMore: hasMore);
  }

  /// POST /api/workout-sessions/rest/start
  /// Starts the rest timer for a workout session.
  Future<void> startRest(String sessionId) async {
    await _apiClient.post(ApiConstants.workoutRestStart(sessionId));
  }

  /// POST /api/workout-sessions/rest/end
  /// Ends the rest timer for a workout session.
  Future<void> endRest(String sessionId) async {
    await _apiClient.post(ApiConstants.workoutRestEnd(sessionId));
  }

  /// POST /api/workout-sessions/cancel
  /// Cancels/abandons the workout session.
  Future<void> cancelWorkout(String sessionId) async {
    await _apiClient.post(ApiConstants.workoutCancel(sessionId));
  }
}
