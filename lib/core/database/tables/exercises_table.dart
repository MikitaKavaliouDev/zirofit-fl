import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get createdById => text().nullable()();
  IntColumn get recommendedRestSeconds => integer().nullable()();
  BoolColumn get isUnilateral => boolean().withDefault(const Constant(false))();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
