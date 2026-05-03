import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';

void main() {
  group('PersonalRecord', () {
    const achievedAt = 1700300000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'pr-1',
      'client_id': 'client-1',
      'exercise_id': 'ex-1',
      'workout_session_id': 'ws-1',
      'record_type': 'weight',
      'value': 100.5,
      'achieved_at': achievedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = PersonalRecord.fromJson(json);
      expect(model.id, 'pr-1');
      expect(model.clientId, 'client-1');
      expect(model.exerciseId, 'ex-1');
      expect(model.workoutSessionId, 'ws-1');
      expect(model.recordType, 'weight');
      expect(model.value, 100.5);
      expect(model.achievedAt, DateTime.fromMillisecondsSinceEpoch(achievedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = PersonalRecord.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'pr-2',
        'client_id': 'client-2',
        'exercise_id': 'ex-2',
        'workout_session_id': 'ws-2',
        'record_type': 'reps',
        'value': 15,
        'achieved_at': achievedAt,
      };
      final model = PersonalRecord.fromJson(minimal);
      expect(model.id, 'pr-2');
      expect(model.clientId, 'client-2');
      expect(model.exerciseId, 'ex-2');
      expect(model.workoutSessionId, 'ws-2');
      expect(model.recordType, 'reps');
      expect(model.value, 15.0);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = PersonalRecord.fromJson(json);
      final model2 = PersonalRecord.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = PersonalRecord.fromJson({...json, 'id': 'pr-1'});
      final model2 = PersonalRecord.fromJson({...json, 'id': 'pr-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = PersonalRecord.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
