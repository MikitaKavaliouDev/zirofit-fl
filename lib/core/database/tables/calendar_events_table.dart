import 'package:drift/drift.dart';

class CalendarEvents extends Table {
  TextColumn get id => text()();
  Int64Column get startTime => int64()();
  Int64Column get endTime => int64()();
  TextColumn get status => text()();
  BoolColumn get dataSharingApproved => boolean().nullable().withDefault(const Constant(false))();
  Int64Column? get dataSharingApprovedAt => int64().nullable()();
  TextColumn get trainerId => text()();
  TextColumn get clientId => text().nullable()();
  TextColumn get clientName => text().nullable()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get clientNotes => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
