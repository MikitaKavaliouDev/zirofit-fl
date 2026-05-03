import 'package:drift/drift.dart';

class TrainerTestimonials extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get clientName => text()();
  TextColumn get testimonialText => text()();
  IntColumn get rating => integer().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
