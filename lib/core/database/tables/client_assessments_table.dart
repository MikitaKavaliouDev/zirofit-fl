import 'package:drift/drift.dart';

class ClientAssessments extends Table {
  TextColumn get id => text()();
  TextColumn get assessmentId => text()();
  TextColumn get clientId => text()();
  RealColumn get value => real()();
  Int64Column get date => int64()();
  TextColumn get notes => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
