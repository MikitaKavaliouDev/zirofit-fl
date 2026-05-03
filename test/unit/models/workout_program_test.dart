import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';

void main() {
  group('WorkoutProgram', () {
    final json = {
      'id': 'prog-1',
      'name': 'Summer Shred',
      'description': '12-week cutting program',
      'trainer_id': 'trainer-1',
      'category': 'strength',
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final program = WorkoutProgram.fromJson(json);

      expect(program.id, 'prog-1');
      expect(program.name, 'Summer Shred');
      expect(program.description, '12-week cutting program');
      expect(program.trainerId, 'trainer-1');
      expect(program.category, 'strength');
      expect(program.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(program.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(program.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final program = WorkoutProgram.fromJson(json);
      final output = program.toJson();

      expect(output['id'], 'prog-1');
      expect(output['name'], 'Summer Shred');
      expect(output['description'], '12-week cutting program');
      expect(output['trainer_id'], 'trainer-1');
      expect(output['category'], 'strength');
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'prog-2',
        'name': 'Beginner Plan',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final program = WorkoutProgram.fromJson(minimal);

      expect(program.id, 'prog-2');
      expect(program.description, isNull);
      expect(program.trainerId, isNull);
      expect(program.category, isNull);
      expect(program.deletedAt, isNull);
    });

    test('equality', () {
      final a = WorkoutProgram.fromJson(json);
      final b = WorkoutProgram.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = WorkoutProgram.fromJson(json);
      final b = WorkoutProgram.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
