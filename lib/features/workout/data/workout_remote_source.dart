import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/data/models/sync_action.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';

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
  /// Starts a new workout session, optionally from a template
  /// or for a specific client (trainer-led session).
  Future<WorkoutSession> startWorkout({String? templateId, String? clientId}) async {
    final body = <String, dynamic>{};
    if (templateId != null) {
      body['templateId'] = templateId;
    }
    if (clientId != null) {
      body['clientId'] = clientId;
    }

    final response = await _apiClient.post<ApiResponse<WorkoutSession>>(
      ApiConstants.workoutStart,
      body: body,
      fromJson: (json) => ApiResponse.fromJson(
        json,
        (dataJson) {
          // Backend returns {data: {session: {...}}}, unwrap the session key.
          final sessionJson =
              dataJson.containsKey('id')
                  ? dataJson
                  : dataJson['session'] as Map<String, dynamic>;
          return WorkoutSession.fromJson(sessionJson);
        },
      ),
    );

    if (response.data == null) {
      throw response.toException();
    }
    return response.data!;
  }

  /// GET /api/workout-sessions/live
  /// Returns the currently active workout session and its exercise logs.
  /// Returns null if no active session exists.
  Future<({WorkoutSession session, List<ClientExerciseLog> logs})?> getActiveSession() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutLive,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final sessionMap = data['session'] as Map<String, dynamic>?;

    // No active session - return null to indicate no workout in progress
    if (sessionMap == null) {
      return null;
    }

    final session = WorkoutSession.fromJson(sessionMap);

    // Logs are nested inside session as 'exerciseLogs' (camelCase)
    // Backend omits clientId from individual log entries — inject it from
    // the session-level client object so parsing doesn't throw.
    final sessionClientId =
        (sessionMap['client'] as Map<String, dynamic>?)?['id'] as String?;

    final logsList =
        (sessionMap['exerciseLogs'] as List<dynamic>?)
            ?.map((e) {
              final logJson = e as Map<String, dynamic>;
              return ClientExerciseLog.fromJson(
                logJson,
                sessionClientId: sessionClientId,
                workoutSessionId: session.id,
              );
            })
            .toList() ??
        [];

    return (session: session, logs: logsList);
  }

  /// POST /api/workout-sessions/live
  /// Logs an exercise set in the current workout session.
  Future<ClientExerciseLog> logExercise({
    required String exerciseId,
    required String workoutSessionId,
    int? reps,
    double? weight,
    String? side,
    int? order,
  }) async {
    final body = <String, dynamic>{
      'exerciseId': exerciseId,
      'workoutSessionId': workoutSessionId,
    };
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
      fromJson: (json) => ApiResponse.fromJson(
        json,
        (dataJson) {
          // Backend returns {data: {session: {...}}}, unwrap the session key.
          final sessionJson =
              dataJson.containsKey('id')
                  ? dataJson
                  : dataJson['session'] as Map<String, dynamic>;
          return WorkoutSession.fromJson(sessionJson);
        },
      ),
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
    final hasMore = (data['hasMore'] as bool?) ?? false;

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

  /// POST /api/workout-sessions/bulk-log
  /// Logs multiple sets at once (used on session finish for offline sync).
  Future<List<ClientExerciseLog>> bulkLogSets({
    required String sessionId,
    required List<LogSetPayload> sets,
  }) async {
    final body = <String, dynamic>{
      'sets': sets.map((s) => s.toJson()).toList(),
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.workoutBulkLog(sessionId),
      body: body,
    );

    // Handle wrapped or flat response
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final logsList = data['logs'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    
    return logsList
        .map((e) => ClientExerciseLog.fromJson(
          e as Map<String, dynamic>,
          workoutSessionId: sessionId,
        ))
        .toList();
  }

  /// POST /api/workout-sessions/{id}/exercises
  /// Adds an exercise to the active workout session.
  Future<ClientExerciseLog> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
  }) async {
    final body = <String, dynamic>{'exerciseId': exerciseId};

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.workoutExercises(sessionId),
      body: body,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return ClientExerciseLog.fromJson(
      data,
      workoutSessionId: sessionId,
    );
  }

  /// DELETE /api/workout-sessions/{id}/exercises/{logId}
  /// Removes an exercise log from the session.
  Future<void> deleteSessionExerciseLog({
    required String sessionId,
    required String logId,
  }) async {
    await _apiClient.delete(ApiConstants.workoutExerciseLog(sessionId, logId));
  }

  /// GET /api/workout-sessions/{id}/summary
  /// Fetches the summary data for a completed workout.
  Future<WorkoutSummaryResponse> fetchWorkoutSummary(String sessionId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutSummary(sessionId),
    );

    // Handle wrapped or flat response
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return WorkoutSummaryResponse.fromJson(data);
  }

  /// GET /api/workout-sessions/{id}
  /// Fetches a single workout session by ID.
  Future<WorkoutSession> fetchSession(String sessionId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutSessionDetail(sessionId),
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final sessionMap = data.containsKey('id') ? data : data['session'] as Map<String, dynamic>?;
    return WorkoutSession.fromJson(sessionMap ?? data);
  }

  /// POST /api/exercises/custom
  /// Creates a new custom exercise for the client.
  Future<Exercise> createCustomExercise({
    required String name,
    String? muscleGroup,
    String? equipment,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (muscleGroup != null) 'muscleGroup': muscleGroup,
      if (equipment != null) 'equipment': equipment,
      if (description != null) 'description': description,
    };

    final response = await _apiClient.post<ApiResponse<Exercise>>(
      ApiConstants.customExercises,
      body: body,
      fromJson: (json) => ApiResponse.fromJson(json, Exercise.fromJson),
    );

    if (response.data == null) {
      throw response.toException();
    }
    return response.data!;
  }

  /// GET /trainer/programs
  /// Fetches workout programs for template saving.
  Future<List<WorkoutProgram>> fetchPrograms() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutPrograms,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final programsList = data['programs'] as List<dynamic>? ?? [];
    
    return programsList
        .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /trainer/programs/{id}/templates
  /// Creates a workout template under a program.
  Future<WorkoutTemplate> createWorkoutTemplate({
    required String programId,
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': ?description,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.createProgramTemplate(programId),
      body: body,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return WorkoutTemplate.fromJson(data);
  }

  /// PUT /calendar/events/{id}
  /// Updates a calendar event (e.g. mark as completed).
  Future<void> updateCalendarEvent({
    required String eventId,
    required String status,
    DateTime? endAt,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      if (endAt != null) 'endAt': endAt.toIso8601String(),
    };

    await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.calendarEvent(eventId),
      body: body,
    );
  }

  /// POST /api/workout-sessions/{id}/media
  /// Uploads media for a workout session.
  /// Note: Full implementation requires dio FormData support
  Future<bool> uploadSessionMedia({
    required String sessionId,
    required String imagePath,
  }) async {
    // Stub for now - full implementation needs dio FormData
    // This would require adding proper multipart upload support
    return false;
  }
}
