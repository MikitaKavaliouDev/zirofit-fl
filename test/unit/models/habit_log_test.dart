import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/habit_log.dart';

void main() {
  group('HabitLog', () {
    final json = {
      'id': 'test-id',
      'habit_id': 'test-habit-id',
      'client_id': 'test-client-id',
      'date': 1700000000000,
      'is_completed': true,
      'note': 'Completed all glasses',
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
    };

    test('fromJson parses all fields correctly', () {
      final model = HabitLog.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.habitId, 'test-habit-id');
      expect(model.clientId, 'test-client-id');
      expect(model.date, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.isCompleted, true);
      expect(model.note, 'Completed all glasses');
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
    });

    test('toJson produces correct wire format', () {
      final model = HabitLog.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'habit_id': 'test-habit-id',
        'client_id': 'test-client-id',
        'date': 1700000000000,
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = HabitLog.fromJson(minimalJson);
      expect(model.note, isNull);
      expect(model.isCompleted, false);
    });

    test('equality works correctly', () {
      final model1 = HabitLog.fromJson(json);
      final model2 = HabitLog.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = HabitLog.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
