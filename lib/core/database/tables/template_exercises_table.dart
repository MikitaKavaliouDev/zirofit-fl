import 'package:drift/drift.dart';

class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  TextColumn get type => text().nullable()();
  TextColumn get exerciseId => text().nullable()();
  TextColumn get targetReps => text().nullable()();
  TextColumn get targetRir => text().nullable()();
  TextColumn get tempo => text().nullable()();
  IntColumn get enableRpe => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get supersetGroupId => text().nullable()();
  IntColumn get supersetOrder => integer().nullable()();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetRest => integer().nullable()();
  TextColumn get exerciseCategory => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
