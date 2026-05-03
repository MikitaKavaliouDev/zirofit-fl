import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/data/models/enums/habit_frequency.dart';

void main() {
  group('DailyHabit', () {
    final json = {
      'id': 'test-id',
      'client_id': 'test-client-id',
      'trainer_id': 'test-trainer-id',
      'title': 'Drink water',
      'description': 'Drink 8 glasses of water daily',
      'frequency': 'DAILY',
      'is_active': true,
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = DailyHabit.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.clientId, 'test-client-id');
      expect(model.trainerId, 'test-trainer-id');
      expect(model.title, 'Drink water');
      expect(model.description, 'Drink 8 glasses of water daily');
      expect(model.frequency, HabitFrequency.daily);
      expect(model.isActive, true);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = DailyHabit.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'client_id': 'test-client-id',
        'trainer_id': 'test-trainer-id',
        'title': 'Drink water',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = DailyHabit.fromJson(minimalJson);
      expect(model.description, isNull);
      expect(model.deletedAt, isNull);
      expect(model.frequency, HabitFrequency.daily);
      expect(model.isActive, true);
    });

    test('equality works correctly', () {
      final model1 = DailyHabit.fromJson(json);
      final model2 = DailyHabit.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = DailyHabit.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
