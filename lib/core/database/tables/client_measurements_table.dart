import 'package:drift/drift.dart';

class ClientMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  Int64Column get measurementDate => int64()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPercentage => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get customMetrics => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
