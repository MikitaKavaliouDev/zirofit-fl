import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';

void main() {
  group('ClientExerciseLog', () {
    final json = {
      'id': 'test-id',
      'client_id': 'test-client-id',
      'exercise_id': 'test-exercise-id',
      'reps': 10,
      'weight': 50.5,
      'is_completed': true,
      'order': 1,
      'tempo': '2-0-2-0',
      'side': 'LEFT',
      'workout_session_id': 'test-session-id',
      'superset_key': 'superset-a',
      'order_in_superset': 1,
      'sets': [
        {'reps': 10, 'weight': 50.5}
      ],
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = ClientExerciseLog.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.clientId, 'test-client-id');
      expect(model.exerciseId, 'test-exercise-id');
      expect(model.reps, 10);
      expect(model.weight, 50.5);
      expect(model.isCompleted, true);
      expect(model.order, 1);
      expect(model.tempo, '2-0-2-0');
      expect(model.side, 'LEFT');
      expect(model.workoutSessionId, 'test-session-id');
      expect(model.supersetKey, 'superset-a');
      expect(model.orderInSuperset, 1);
      expect(model.sets, hasLength(1));
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = ClientExerciseLog.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'client_id': 'test-client-id',
        'exercise_id': 'test-exercise-id',
        'side': 'BOTH',
        'workout_session_id': 'test-session-id',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = ClientExerciseLog.fromJson(minimalJson);
      expect(model.reps, isNull);
      expect(model.weight, isNull);
      expect(model.isCompleted, isNull);
      expect(model.order, isNull);
      expect(model.tempo, isNull);
      expect(model.supersetKey, isNull);
      expect(model.orderInSuperset, isNull);
      expect(model.sets, isNull);
      expect(model.deletedAt, isNull);
      expect(model.side, 'BOTH');
    });

    test('equality works correctly', () {
      final model1 = ClientExerciseLog.fromJson(json);
      final model2 = ClientExerciseLog.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = ClientExerciseLog.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
