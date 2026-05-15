import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/database/app_database.dart' hide TemplateExercise;
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/features/programs/data/template_exercise_dao.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TemplateExerciseDao dao;

  setUp(() async {
    db = await createTestDatabase();
    dao = TemplateExerciseDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TemplateExerciseDao', () {
    final baseTime = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    TemplateExercise exercise({
      String id = 'te-1',
      String templateId = 'tmpl-1',
      String? exerciseId = 'ex-1',
      String? targetReps = '8-12',
      String? tempo = '3010',
      int? targetSets = 3,
      int? durationSeconds = 60,
      String? notes = 'Focus on form',
      int order = 0,
    }) {
      return TemplateExercise(
        id: id,
        templateId: templateId,
        exerciseId: exerciseId,
        targetReps: targetReps,
        tempo: tempo,
        targetSets: targetSets,
        durationSeconds: durationSeconds,
        notes: notes,
        order: order,
        enableRpe: false,
        createdAt: baseTime,
        updatedAt: baseTime,
      );
    }

    test('insert and retrieve by template id', () async {
      await dao.insert(exercise());

      final exercises = await dao.getByTemplateId('tmpl-1');

      expect(exercises, hasLength(1));
      expect(exercises[0].id, 'te-1');
      expect(exercises[0].tempo, '3010');
      expect(exercises[0].targetReps, '8-12');
    });

    test('insert multiple and verify order', () async {
      await dao.insert(exercise());
      await dao.insert(exercise(id: 'te-2', exerciseId: 'ex-2', order: 1));

      final exercises = await dao.getByTemplateId('tmpl-1');

      expect(exercises, hasLength(2));
      expect(exercises[0].order, 0);
      expect(exercises[1].order, 1);
    });

    test('get by id returns correct record', () async {
      await dao.insert(exercise());

      final result = await dao.getById('te-1');

      expect(result, isNotNull);
      expect(result!.id, 'te-1');
      expect(result.tempo, '3010');
    });

    test('get by non-existent id returns null', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('update modifies fields', () async {
      await dao.insert(exercise());

      await dao.update(
        exercise(targetReps: '10-12', tempo: '2110'),
      );

      final result = await dao.getById('te-1');
      expect(result, isNotNull);
      expect(result!.targetReps, '10-12');
      expect(result.tempo, '2110');
    });

    test('soft delete sets deleted_at and sync_status', () async {
      await dao.insert(exercise());

      await dao.softDelete('te-1');

      final result = await db.customSelect(
        'SELECT "deleted_at", "sync_status" FROM "template_exercises" WHERE "id" = ?',
        variables: [drift.Variable.withString('te-1')],
      ).get();

      expect(result, isNotEmpty);
      final row = result.first.data;
      expect(row['deleted_at'], isNotNull);
      expect(row['sync_status'], 3);
    });

    test('reorder updates order fields', () async {
      await dao.insert(exercise());
      await dao.insert(exercise(id: 'te-2', exerciseId: 'ex-2', order: 0));
      await dao.insert(exercise(id: 'te-3', exerciseId: 'ex-3', order: 0));

      await dao.reorder('tmpl-1', ['te-3', 'te-1', 'te-2']);

      final exercises = await dao.getByTemplateId('tmpl-1');
      expect(exercises, hasLength(3));
      expect(exercises[0].id, 'te-3');
      expect(exercises[1].id, 'te-1');
      expect(exercises[2].id, 'te-2');
    });

    test('empty template returns empty list', () async {
      final exercises = await dao.getByTemplateId('non-existent');
      expect(exercises, isEmpty);
    });
  });
}
