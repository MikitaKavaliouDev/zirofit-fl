import 'workout_session_fixture.dart';

/// Factory for generating workout history list JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class WorkoutHistoryFixture {
  /// A paginated workout history response with a mix of session states.
  static Map<String, dynamic> paginatedHistory({
    int page = 1,
    int perPage = 20,
    int total = 1,
  }) =>
      {
        'data': [
          WorkoutSessionFixture.completedSession(),
          WorkoutSessionFixture.plannedSession(),
          WorkoutSessionFixture.createJson(
            id: 'test-session-in-progress-2',
            status: 'IN_PROGRESS',
          ),
        ],
        'total': total,
        'page': page,
        'perPage': perPage,
        'totalPages': (total / perPage).ceil(),
        'hasMore': page * perPage < total,
      };

  /// Empty history response (no sessions yet).
  static Map<String, dynamic> emptyHistory() => {
        'data': [],
        'total': 0,
        'page': 1,
        'perPage': 20,
        'totalPages': 0,
        'hasMore': false,
      };
}
