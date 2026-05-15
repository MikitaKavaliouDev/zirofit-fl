import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/core/database/app_database.dart' as db;
import 'package:zirofit_fl/core/database/database_provider.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';

/// Provider for TemplateExerciseDao.
final templateExerciseDaoProvider = Provider<TemplateExerciseDao>((ref) {
  final database = ref.watch(databaseProvider);
  return TemplateExerciseDao(database);
});

/// Data access object for TemplateExercises local Drift table.
///
/// Provides offline CRUD operations for template exercise steps.
/// Mutations set the appropriate sync_status so the SyncEngine
/// picks them up during the next push cycle.
class TemplateExerciseDao {
  final db.AppDatabase _database;

  TemplateExerciseDao(this._database);

  /// Get all non-deleted steps for a template, ordered by [order].
  Future<List<TemplateExercise>> getByTemplateId(String templateId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM "template_exercises" '
      'WHERE "template_id" = ? AND "deleted_at" IS NULL '
      'ORDER BY "order" ASC',
      variables: [Variable.withString(templateId)],
    ).get();

    return rows.map((row) => _fromRow(row.data)).toList();
  }

  /// Get a single step by its ID.
  Future<TemplateExercise?> getById(String id) async {
    final rows = await _database.customSelect(
      'SELECT * FROM "template_exercises" WHERE "id" = ?',
      variables: [Variable.withString(id)],
    ).get();

    if (rows.isEmpty) return null;
    return _fromRow(rows.first.data);
  }

  /// Insert a new template exercise step with PENDING_CREATE sync status.
  Future<void> insert(TemplateExercise item) async {
    await _database.customInsert(
      'INSERT INTO "template_exercises" ('
      '"id", "template_id", "type", "exercise_id", "target_reps", '
      '"target_rir", "tempo", "enable_rpe", "duration_seconds", '
      '"notes", "order", "superset_group_id", "superset_order", '
      '"target_sets", "target_rest", "exercise_category", '
      '"created_at", "updated_at", "sync_status"'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(item.id),
        Variable.withString(item.templateId),
        _stringOrNull(item.type?.toJson()),
        _stringOrNull(item.exerciseId),
        _stringOrNull(item.targetReps),
        _intOrNull(item.targetRIR),
        _stringOrNull(item.tempo),
        Variable.withInt(item.enableRpe ? 1 : 0),
        _intOrNull(item.durationSeconds),
        _stringOrNull(item.notes),
        Variable.withInt(item.order),
        _stringOrNull(item.supersetGroupId),
        _intOrNull(item.supersetOrder),
        _intOrNull(item.targetSets),
        _intOrNull(item.targetRest),
        const Variable(null),
        Variable.withInt(item.createdAt.millisecondsSinceEpoch),
        Variable.withInt(item.updatedAt.millisecondsSinceEpoch),
        Variable.withInt(1), // PENDING_CREATE
      ],
    );
  }

  /// Update an existing template exercise step with PENDING_UPDATE.
  Future<void> update(TemplateExercise item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.customUpdate(
      'UPDATE "template_exercises" SET '
      '"type" = ?, "exercise_id" = ?, "target_reps" = ?, '
      '"target_rir" = ?, "tempo" = ?, "enable_rpe" = ?, '
      '"duration_seconds" = ?, "notes" = ?, "order" = ?, '
      '"superset_group_id" = ?, "superset_order" = ?, '
      '"target_sets" = ?, "target_rest" = ?, '
      '"updated_at" = ?, "sync_status" = 2 '
      'WHERE "id" = ?',
      variables: [
        _stringOrNull(item.type?.toJson()),
        _stringOrNull(item.exerciseId),
        _stringOrNull(item.targetReps),
        _intOrNull(item.targetRIR),
        _stringOrNull(item.tempo),
        Variable.withInt(item.enableRpe ? 1 : 0),
        _intOrNull(item.durationSeconds),
        _stringOrNull(item.notes),
        Variable.withInt(item.order),
        _stringOrNull(item.supersetGroupId),
        _intOrNull(item.supersetOrder),
        _intOrNull(item.targetSets),
        _intOrNull(item.targetRest),
        Variable.withInt(now),
        Variable.withString(item.id),
      ],
    );
  }

  /// Soft-delete a step by setting deleted_at and sync_status = PENDING_DELETE.
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.customUpdate(
      'UPDATE "template_exercises" SET '
      '"deleted_at" = ?, "updated_at" = ?, "sync_status" = 3 '
      'WHERE "id" = ?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withString(id),
      ],
    );
  }

  /// Reorder steps by setting their order field based on the provided list.
  Future<void> reorder(String templateId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _database.customUpdate(
        'UPDATE "template_exercises" SET "order" = ? WHERE "id" = ?',
        variables: [
          Variable.withInt(i),
          Variable.withString(orderedIds[i]),
        ],
      );
    }
  }

  /// Convert a raw SQL row to a TemplateExercise model.
  TemplateExercise _fromRow(Map<String, dynamic> data) {
    return TemplateExercise(
      id: data['id'] as String,
      templateId: data['template_id'] as String,
      type: data['type'] != null
          ? StepType.values.firstWhere(
              (e) => e.toJson() == data['type'] as String,
            )
          : null,
      exerciseId: data['exercise_id'] as String?,
      targetReps: data['target_reps'] as String?,
      targetRIR: data['target_rir'] as int?,
      tempo: data['tempo'] as String?,
      enableRpe: data['enable_rpe'] == 1,
      durationSeconds: data['duration_seconds'] as int?,
      notes: data['notes'] as String?,
      order: (data['order'] as int?) ?? 0,
      supersetGroupId: data['superset_group_id'] as String?,
      supersetOrder: data['superset_order'] as int?,
      targetSets: data['target_sets'] as int?,
      targetRest: data['target_rest'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data['updated_at'] as int),
      deletedAt: data['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deleted_at'] as int)
          : null,
    );
  }

  Variable _stringOrNull(String? value) {
    if (value == null) return const Variable(null);
    return Variable.withString(value);
  }

  Variable _intOrNull(int? value) {
    if (value == null) return const Variable(null);
    return Variable.withInt(value);
  }
}
