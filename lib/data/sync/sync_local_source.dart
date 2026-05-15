import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import 'sync_models.dart';

/// Local data source for sync operations.
///
/// Handles reading/writing sync metadata and upserting records
/// from pull responses into the local Drift database.
///
/// Drift by default uses snake_case for SQL column names (e.g. Dart
/// getter `syncStatus` maps to SQL column `sync_status`). All raw SQL
/// in this class uses snake_case column names to match Drift's convention.
class SyncLocalSource {
  final AppDatabase _db;
  static const _lastPulledAtKey = 'sync_last_pulled_at';

  SyncLocalSource(this._db);

  /// Get the last successful pull timestamp.
  /// Persisted in SharedPreferences to survive app restarts.
  Future<int> getLastPulledAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPulledAtKey) ?? 0;
  }

  /// Set the last successful pull timestamp.
  Future<void> setLastPulledAt(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPulledAtKey, timestamp);
  }

  /// Upsert a record into the appropriate Drift table.
  ///
  /// The [record] map should contain snake_case keys matching Drift's
  /// generated column names (e.g. `sync_status`, `created_at`).
  /// The `sync_status` column is always set to 0 (SYNCED) on pull.
  Future<void> upsertRecord(
      String tableName, Map<String, dynamic> record) async {
    final id = record['id'] as String;
    if (id.isEmpty) return;

    // Set sync status to SYNCED (0) for pulled records
    record['sync_status'] = 0;

    // Check if record exists
    final existing = await _db.customSelect(
      'SELECT id FROM "$tableName" WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();

    if (existing.isNotEmpty) {
      // Update existing record
      final setClauses = <String>[];
      final variables = <Variable>[];
      for (final entry in record.entries) {
        setClauses.add('"${entry.key}" = ?');
        variables.add(_toVariable(entry.value));
      }
      variables.add(Variable.withString(id));

      await _db.customUpdate(
        'UPDATE "$tableName" SET ${setClauses.join(', ')} WHERE "id" = ?',
        variables: variables,
      );
    } else {
      // Insert new record
      final columns = record.keys.map((k) => '"$k"').join(', ');
      final placeholders = record.keys.map((_) => '?').join(', ');
      final variables = record.values.map((v) => _toVariable(v)).toList();

      await _db.customInsert(
        'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
        variables: variables,
      );
    }
  }

  /// Soft delete a record by setting its deleted_at timestamp.
  Future<void> softDeleteRecord(String tableName, String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE "$tableName" SET "deleted_at" = ?, "updated_at" = ?, "sync_status" = 0 WHERE "id" = ?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withString(id),
      ],
    );
  }

  /// Collect all pending changes across all sync tables.
  ///
  /// Returns a map of tableName → SyncChanges for the push payload.
  /// Only records with `sync_status != 0` and not soft-deleted are included.
  Future<Map<String, SyncChanges>?> collectPendingChanges() async {
    final syncTableNames = _allSyncTableNames();
    final result = <String, SyncChanges>{};

    for (final tableName in syncTableNames) {
      try {
        final rows = await _db.customSelect(
          'SELECT * FROM "$tableName" WHERE "sync_status" != 0',
        ).get();

        if (rows.isEmpty) continue;

        final created = <Map<String, dynamic>>[];
        final updated = <Map<String, dynamic>>[];
        final deleted = <String>[];

        for (final row in rows) {
          final data = Map<String, dynamic>.from(row.data);
          final syncStatus = data['sync_status'] as int? ?? 0;

          if (syncStatus == 3) {
            // PENDING_DELETE
            deleted.add(data['id'] as String);
          } else if (syncStatus == 1) {
            // PENDING_CREATE — strip internal timestamps for push
            data.remove('created_at');
            data.remove('updated_at');
            data.remove('sync_status');
            data.remove('deleted_at');
            created.add(data);
          } else if (syncStatus == 2) {
            // PENDING_UPDATE
            data.remove('sync_status');
            updated.add(data);
          }
        }

        if (created.isNotEmpty || updated.isNotEmpty || deleted.isNotEmpty) {
          result[tableName] = SyncChanges(
            created: created,
            updated: updated,
            deleted: deleted,
          );
        }
      } catch (_) {
        // Table might not exist yet; skip
        continue;
      }
    }

    return result.isNotEmpty ? result : null;
  }

  /// Mark all pending records as synced (sync_status = 0).
  Future<void> markAllSynced() async {
    for (final tableName in _allSyncTableNames()) {
      try {
        await _db.customUpdate(
          'UPDATE "$tableName" SET "sync_status" = 0 WHERE "sync_status" != 0',
        );
      } catch (_) {
        continue;
      }
    }
  }

  /// Remove all soft-deleted records that have been synced.
  Future<void> cleanSyncedDeletions() async {
    for (final tableName in _allSyncTableNames()) {
      try {
        await _db.customUpdate(
          'DELETE FROM "$tableName" WHERE "deleted_at" IS NOT NULL AND "sync_status" = 0',
        );
      } catch (_) {
        continue;
      }
    }
  }

  /// Delete a record entirely from a table.
  Future<void> deleteRecord(String tableName, String id) async {
    await _db.customUpdate(
      'DELETE FROM "$tableName" WHERE "id" = ?',
      variables: [Variable.withString(id)],
    );
  }

  /// Mark a single record as synced (sync_status = 0).
  Future<void> markSynced(String tableName, String recordId) async {
    await _db.customUpdate(
      'UPDATE "$tableName" SET "sync_status" = 0 WHERE "id" = ?',
      variables: [Variable.withString(recordId)],
    );
  }

  /// Get count of all pending records across all sync tables.
  Future<int> getPendingCount() async {
    int count = 0;
    for (final tableName in _allSyncTableNames()) {
      try {
        final result = await _db.customSelect(
          'SELECT COUNT(*) as cnt FROM "$tableName" WHERE "sync_status" != 0',
        ).get();
        if (result.isNotEmpty) {
          count += result.first.data['cnt'] as int;
        }
      } catch (_) {
        continue;
      }
    }
    return count;
  }

  /// Convert a Dart value to a Drift Variable for use in raw SQL.
  Variable _toVariable(dynamic value) {
    if (value == null) {
      return const Variable(null);
    } else if (value is int) {
      return Variable.withInt(value);
    } else if (value is double) {
      return Variable.withReal(value);
    } else if (value is bool) {
      return Variable.withInt(value ? 1 : 0);
    } else if (value is String) {
      return Variable.withString(value);
    } else {
      return Variable.withString(jsonEncode(value));
    }
  }

  /// Returns the list of all sync table names used in push/pull.
  ///
  /// These match Drift's default snake_case table naming convention
  /// (e.g. class `ClientExerciseLogs` → table `client_exercise_logs`).
  List<String> _allSyncTableNames() {
    return [
      'clients',
      'profiles',
      'trainer_profiles',
      'workout_sessions',
      'exercises',
      'workout_templates',
      'client_assessments',
      'client_measurements',
      'client_photos',
      'client_exercise_logs',
      'template_exercises',
      'trainer_services',
      'trainer_packages',
      'trainer_testimonials',
      'trainer_programs',
      'calendar_events',
      'notifications',
      'bookings',
    ];
  }
}
