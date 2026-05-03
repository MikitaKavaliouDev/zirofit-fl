import 'package:drift/drift.dart';

class ClientExerciseLogs extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  BoolColumn get isCompleted => boolean().nullable()();
  IntColumn get order => integer().nullable()();
  TextColumn get tempo => text().nullable()();
  TextColumn get side => text().withDefault(const Constant('BOTH'))();
  TextColumn get workoutSessionId => text()();
  TextColumn get supersetKey => text().nullable()();
  IntColumn get orderInSuperset => integer().nullable()();
  TextColumn get sets => text().nullable()(); // DEPRECATED JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
