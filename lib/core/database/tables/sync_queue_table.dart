import 'package:drift/drift.dart';

/// Local-only table for the offline mutation FIFO queue.
/// Stores pending create/update/delete operations to be pushed
/// to the server when connectivity is restored.
class SyncQueueItems extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get targetTable => text()(); // Name of the table being mutated ('clients', etc.)
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get data => text()(); // Full JSON payload of the record
  Int64Column get createdAt => int64()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
