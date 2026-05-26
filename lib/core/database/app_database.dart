import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/bookings_table.dart';
import 'tables/calendar_events_table.dart';
import 'tables/client_assessments_table.dart';
import 'tables/client_exercise_logs_table.dart';
import 'tables/client_measurements_table.dart';
import 'tables/client_photos_table.dart';
import 'tables/clients_table.dart';
import 'tables/exercises_table.dart';
import 'tables/notifications_table.dart';
import 'tables/profiles_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/trainer_packages_table.dart';
import 'tables/trainer_profiles_table.dart';
import 'tables/trainer_programs_table.dart';
import 'tables/trainer_services_table.dart';
import 'tables/trainer_testimonials_table.dart';
import 'tables/users_table.dart';
import 'tables/template_exercises_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/workout_templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Local-only
    Users,
    SyncQueueItems,
    // Sync tables
    Clients,
    Profiles,
    TrainerProfiles,
    TemplateExercises,
    WorkoutSessions,
    Exercises,
    WorkoutTemplates,
    ClientAssessments,
    ClientMeasurements,
    ClientPhotos,
    ClientExerciseLogs,
    TrainerServices,
    TrainerPackages,
    TrainerTestimonials,
    TrainerPrograms,
    CalendarEvents,
    Notifications,
    Bookings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations go here as from/to version blocks
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode=WAL');
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'zirofit.db'));
      return NativeDatabase(file);
    });
  }
}
