import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Possible states for the upcoming session detail fetch.
sealed class UpcomingSessionState {
  const UpcomingSessionState();
}

class UpcomingSessionInitial extends UpcomingSessionState {
  const UpcomingSessionInitial();
}

class UpcomingSessionLoading extends UpcomingSessionState {
  const UpcomingSessionLoading();
}

class UpcomingSessionLoaded extends UpcomingSessionState {
  final WorkoutSession session;
  final List<ClientExerciseLog> exercises;
  final String? clientName;

  const UpcomingSessionLoaded({
    required this.session,
    required this.exercises,
    this.clientName,
  });
}

class UpcomingSessionError extends UpcomingSessionState {
  final String message;

  const UpcomingSessionError(this.message);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UpcomingSessionNotifier
    extends StateNotifier<UpcomingSessionState> {
  final ApiClient _api;
  final String sessionId;

  UpcomingSessionNotifier(this.sessionId, this._api)
      : super(const UpcomingSessionInitial());

  /// Fetches the session detail from the API.
  Future<void> fetch() async {
    state = const UpcomingSessionLoading();

    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.workoutSessionDetail(sessionId),
      );

      final data =
          response['data'] as Map<String, dynamic>? ?? response;
      final sessionJson =
          data['session'] as Map<String, dynamic>? ?? data;

      final session = WorkoutSession.fromJson(sessionJson);

      // Extract client name from the nested client object
      // (backend sends {"client":{"id":"...","name":"..."}})
      final clientMap = sessionJson['client'] as Map<String, dynamic>?;
      final clientName = clientMap?['name'] as String?;

      // Parse exercise logs from the response
      final exercisesRaw =
          sessionJson['exerciseLogs'] as List<dynamic>? ?? [];
      final exercises = exercisesRaw
          .map((e) => ClientExerciseLog.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();

      state = UpcomingSessionLoaded(
        session: session,
        exercises: exercises,
        clientName: clientName,
      );
    } catch (e) {
      state = UpcomingSessionError(
        e.toString(),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider (family by sessionId)
// ---------------------------------------------------------------------------

final upcomingSessionProvider = StateNotifierProvider.family<
    UpcomingSessionNotifier, UpcomingSessionState, String>(
  (ref, sessionId) {
    final api = ref.read(apiClientProvider);
    return UpcomingSessionNotifier(sessionId, api);
  },
);
