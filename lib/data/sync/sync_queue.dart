import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../core/database/app_database.dart' as db;
import 'sync_models.dart';

/// Data class representing a single item in the offline mutation queue.
class SyncQueueItem {
  final String id;
  final String targetTable;
  final String recordId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  SyncQueueItem({
    String? id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.error,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory SyncQueueItem.fromRow(db.SyncQueueItem row) {
    return SyncQueueItem(
      id: row.id,
      targetTable: row.targetTable,
      recordId: row.recordId,
      operation: SyncOperation.values.firstWhere(
        (e) => e.name.toUpperCase() == row.operation,
      ),
      data: jsonDecode(row.data) as Map<String, dynamic>,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt.toInt()),
      retryCount: row.retryCount,
      error: row.error,
    );
  }

  db.SyncQueueItemsCompanion toCompanion() {
    return db.SyncQueueItemsCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation.name.toUpperCase()),
      data: Value(jsonEncode(data)),
      createdAt:
          Value(BigInt.from(createdAt.millisecondsSinceEpoch)),
      retryCount: Value(retryCount),
      error: Value(error),
    );
  }
}

/// Persistent FIFO queue of offline mutations using the SyncQueueItems Drift table.
class SyncQueue {
  final db.AppDatabase _db;

  SyncQueue(this._db);

  /// Add a mutation to the queue.
  Future<void> add(SyncQueueItem item) async {
    await _db.into(_db.syncQueueItems).insert(item.toCompanion());
  }

  /// Get all pending mutations ordered by creation (FIFO).
  Future<List<SyncQueueItem>> getAllPending() async {
    final rows = await (_db.select(_db.syncQueueItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
    return rows.map((row) => SyncQueueItem.fromRow(row)).toList();
  }

  /// Count pending mutations.
  Future<int> count() async {
    return _db.select(_db.syncQueueItems).get().then((rows) => rows.length);
  }

  /// Remove a processed item from the queue.
  Future<void> remove(String id) async {
    await (_db.delete(_db.syncQueueItems)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Clear all items (used after sync failure reset).
  Future<void> clearAll() async {
    await _db.delete(_db.syncQueueItems).go();
  }

  /// Increment retry count and save error message.
  Future<void> markFailed(String id, String errorMessage) async {
    final existing = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.id.equals(id)))
        .get();
    if (existing.isEmpty) return;

    final currentRetryCount = existing.first.retryCount;
    await (_db.update(_db.syncQueueItems)
          ..where((t) => t.id.equals(id)))
        .write(db.SyncQueueItemsCompanion(
          retryCount: Value(currentRetryCount + 1),
          error: Value(errorMessage),
        ));
  }
}
