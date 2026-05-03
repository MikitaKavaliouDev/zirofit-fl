import 'package:drift/drift.dart';

class TrainerServices extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get price => real().nullable()();
  TextColumn get currency => text().nullable()();
  IntColumn get duration => integer().nullable()(); // minutes

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
