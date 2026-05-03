import 'package:drift/drift.dart';

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get name => text().nullable()();
  Int64Column get startTime => int64()();
  Int64Column? get endTime => int64().nullable()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  Int64Column? get restStartedAt => int64().nullable()();
  TextColumn get workoutTemplateId => text().nullable()();
  Int64Column? get plannedDate => int64().nullable()();
  TextColumn get clientPackageId => text().nullable()();
  BoolColumn get isTrainerLed => boolean().withDefault(const Constant(false))();
  Int64Column? get reminderTime => int64().nullable()();
  BoolColumn get trainerReminderSent => boolean().withDefault(const Constant(false))();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
