import 'package:drift/native.dart';
import 'package:zirofit_fl/core/database/app_database.dart';

/// Creates an in-memory Drift [AppDatabase] for use in tests.
///
/// Usage:
/// ```dart
/// late AppDatabase db;
/// setUp(() {
///   db = createTestDatabase();
/// });
/// tearDown(() => db.close());
/// ```
Future<AppDatabase> createTestDatabase() async {
  final db = AppDatabase.withExecutor(NativeDatabase.memory());
  return db;
}
