/// Factory for generating workout session JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class WorkoutSessionFixture {
  static Map<String, dynamic> createJson({
    String id = 'test-session-id',
    String clientId = 'test-client-id',
    String trainerId = 'test-trainer-id',
    String status = 'IN_PROGRESS',
    int startTime = 1700000000000,
    int? endTime,
    String? notes,
    int createdAt = 1700000000000,
    int updatedAt = 1700000000000,
  }) =>
      {
        'id': id,
        'client_id': clientId,
        'trainer_id': trainerId,
        'status': status,
        'start_time': startTime,
        'end_time': ?endTime,
        'notes': ?notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// A completed workout session fixture.
  static Map<String, dynamic> completedSession() => createJson(
        id: 'test-session-completed',
        status: 'COMPLETED',
        startTime: 1700000000000,
        endTime: 1700003600000,
        notes: 'Great session!',
      );

  /// A planned (future) workout session fixture.
  static Map<String, dynamic> plannedSession() => createJson(
        id: 'test-session-planned',
        status: 'PLANNED',
        startTime: 1700100000000,
      );
}
