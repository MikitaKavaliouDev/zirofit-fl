import 'package:drift/drift.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get trainerId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get status => text()();
  Int64Column get dateOfBirth => int64().nullable()();
  TextColumn get goals => text().nullable()();
  TextColumn get healthNotes => text().nullable()();
  TextColumn get emergencyContactName => text().nullable()();
  TextColumn get emergencyContactPhone => text().nullable()();
  IntColumn get checkInDay => integer().nullable()();
  IntColumn get checkInHour => integer().nullable()();
  Int64Column get dataSharingExpiresAt => int64().nullable()();
  TextColumn get sharingSettings => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
