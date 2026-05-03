import 'package:drift/drift.dart';

class TrainerPackages extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  IntColumn get numberOfSessions => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get stripeProductId => text()();
  TextColumn get stripePriceId => text()();
  TextColumn get trainerId => text()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
