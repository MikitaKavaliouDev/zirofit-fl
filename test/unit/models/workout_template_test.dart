import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';

void main() {
  group('WorkoutTemplate', () {
    final json = {
      'id': 'wt-1',
      'name': 'Push Day A',
      'description': 'Chest, shoulders, triceps',
      'program_id': 'prog-1',
      'order': 1,
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final template = WorkoutTemplate.fromJson(json);

      expect(template.id, 'wt-1');
      expect(template.name, 'Push Day A');
      expect(template.description, 'Chest, shoulders, triceps');
      expect(template.programId, 'prog-1');
      expect(template.order, 1);
      expect(template.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(template.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(template.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final template = WorkoutTemplate.fromJson(json);
      final output = template.toJson();

      expect(output['id'], 'wt-1');
      expect(output['name'], 'Push Day A');
      expect(output['description'], 'Chest, shoulders, triceps');
      expect(output['program_id'], 'prog-1');
      expect(output['order'], 1);
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'wt-2',
        'name': 'Pull Day',
        'program_id': 'prog-2',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final template = WorkoutTemplate.fromJson(minimal);

      expect(template.id, 'wt-2');
      expect(template.description, isNull);
      expect(template.order, 0);
      expect(template.deletedAt, isNull);
    });

    test('equality', () {
      final a = WorkoutTemplate.fromJson(json);
      final b = WorkoutTemplate.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = WorkoutTemplate.fromJson(json);
      final b = WorkoutTemplate.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
