import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';

void main() {
  group('TemplateExercise', () {
    final json = {
      'id': 'te-1',
      'template_id': 'tmpl-1',
      'type': 'EXERCISE',
      'exercise_id': 'ex-1',
      'target_reps': '10-12',
      'target_rir': 1,
      'tempo': '2010',
      'enable_rpe': false,
      'duration_seconds': null,
      'notes': 'Focus on form',
      'order': 1,
      'superset_group_id': 'ss-1',
      'superset_order': 1,
      'target_sets': 3,
      'target_rest': 90,
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final te = TemplateExercise.fromJson(json);

      expect(te.id, 'te-1');
      expect(te.templateId, 'tmpl-1');
      expect(te.type, StepType.exercise);
      expect(te.exerciseId, 'ex-1');
      expect(te.targetReps, '10-12');
      expect(te.targetRIR, 1);
      expect(te.tempo, '2010');
      expect(te.enableRpe, false);
      expect(te.durationSeconds, isNull);
      expect(te.notes, 'Focus on form');
      expect(te.order, 1);
      expect(te.supersetGroupId, 'ss-1');
      expect(te.supersetOrder, 1);
      expect(te.targetSets, 3);
      expect(te.targetRest, 90);
      expect(te.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(te.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(te.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final te = TemplateExercise.fromJson(json);
      final output = te.toJson();

      expect(output['id'], 'te-1');
      expect(output['template_id'], 'tmpl-1');
      expect(output['type'], 'EXERCISE');
      expect(output['exercise_id'], 'ex-1');
      expect(output['target_reps'], '10-12');
      expect(output['target_rir'], 1);
      expect(output['tempo'], '2010');
      expect(output['enable_rpe'], false);
      expect(output['duration_seconds'], null);
      expect(output['notes'], 'Focus on form');
      expect(output['order'], 1);
      expect(output['superset_group_id'], 'ss-1');
      expect(output['superset_order'], 1);
      expect(output['target_sets'], 3);
      expect(output['target_rest'], 90);
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'te-2',
        'template_id': 'tmpl-2',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final te = TemplateExercise.fromJson(minimal);

      expect(te.id, 'te-2');
      expect(te.type, isNull);
      expect(te.exerciseId, isNull);
      expect(te.targetReps, isNull);
      expect(te.targetRIR, isNull);
      expect(te.tempo, isNull);
      expect(te.enableRpe, false);
      expect(te.durationSeconds, isNull);
      expect(te.notes, isNull);
      expect(te.order, 0);
      expect(te.supersetGroupId, isNull);
      expect(te.supersetOrder, isNull);
      expect(te.targetSets, isNull);
      expect(te.targetRest, isNull);
      expect(te.deletedAt, isNull);
    });

    test('equality', () {
      final a = TemplateExercise.fromJson(json);
      final b = TemplateExercise.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = TemplateExercise.fromJson(json);
      final b = TemplateExercise.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
