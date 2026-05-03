import 'package:drift/drift.dart';

class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get message => text()();
  TextColumn get type => text()();
  BoolColumn get readStatus => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
