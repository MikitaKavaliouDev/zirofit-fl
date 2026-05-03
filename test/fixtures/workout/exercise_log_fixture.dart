/// Factory for generating exercise log (ClientExerciseLog) JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class ExerciseLogFixture {
  static Map<String, dynamic> createJson({
    String id = 'test-exercise-log-id',
    String sessionId = 'test-session-id',
    String exerciseName = 'Bench Press',
    int setNumber = 1,
    double weight = 80.0,
    int reps = 10,
    String weightUnit = 'KG',
    bool isCompleted = true,
    String? notes,
    int createdAt = 1700000000000,
    int updatedAt = 1700000000000,
  }) =>
      {
        'id': id,
        'session_id': sessionId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'weight_unit': weightUnit,
        'is_completed': isCompleted,
        'notes': ?notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Multiple sets for a single exercise within a session.
  static List<Map<String, dynamic>> benchPressSets(String sessionId) => [
        createJson(
          id: '${sessionId}_bp_1',
          sessionId: sessionId,
          exerciseName: 'Bench Press',
          setNumber: 1,
          weight: 60.0,
          reps: 12,
        ),
        createJson(
          id: '${sessionId}_bp_2',
          sessionId: sessionId,
          exerciseName: 'Bench Press',
          setNumber: 2,
          weight: 70.0,
          reps: 10,
        ),
        createJson(
          id: '${sessionId}_bp_3',
          sessionId: sessionId,
          exerciseName: 'Bench Press',
          setNumber: 3,
          weight: 80.0,
          reps: 8,
        ),
      ];
}
