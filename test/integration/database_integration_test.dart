import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/database/app_database.dart';

/// Helper to generate a Unix ms timestamp as BigInt.
BigInt _ts() => BigInt.from(DateTime.now().millisecondsSinceEpoch);

/// Helper to generate a slightly offset timestamp.
BigInt _tsLater({int offsetMs = 1000}) =>
    BigInt.from(DateTime.now().millisecondsSinceEpoch + offsetMs);

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // =========================================================================
  // 1. Schema creation
  // =========================================================================
  group('Schema creation', () {
    test('database initializes without errors', () {
      // setUp already created the DB — reaching here means no crash.
      expect(db, isNotNull);
    });

    test('all expected tables exist in generated schema', () {
      final tableNames = db.allTables.map((t) => t.actualTableName).toSet();

      const expected = <String>{
        'users',
        'sync_queue_items',
        'clients',
        'profiles',
        'trainer_profiles',
        'workout_sessions',
        'exercises',
        'workout_templates',
        'client_assessments',
        'client_measurements',
        'client_photos',
        'client_exercise_logs',
        'trainer_services',
        'trainer_packages',
        'trainer_testimonials',
        'trainer_programs',
        'calendar_events',
        'notifications',
        'bookings',
      };

      for (final name in expected) {
        expect(tableNames.contains(name), isTrue,
            reason: 'Table "$name" is missing from the database schema.');
      }
    });

    test('can select from each table without error', () async {
      // Perform a simple select on every registered table to verify the SQL
      // was correctly generated and each table is queryable.
      for (final table in db.allTables) {
        // ignore: deprecated_member_use
        final rows = await db.select(table).get();
        expect(rows, isEmpty,
            reason:
                'Expected empty table ${table.actualTableName} on fresh DB.');
      }
    });
  });

  // =========================================================================
  // 2. Users table CRUD
  // =========================================================================
  group('Users table', () {
    final now = _ts();

    test('insert and read back by id', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            name: 'Alice Trainer',
            email: 'alice@example.com',
            role: 'trainer',
            createdAt: now,
            updatedAt: now,
          ));

      final user = await db.select(db.users).getSingle();
      expect(user.id, 'user-1');
      expect(user.name, 'Alice Trainer');
      expect(user.email, 'alice@example.com');
    });

    test('verify all columns after insert', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-2',
            name: 'Bob Client',
            email: 'bob@example.com',
            username: const Value('bob_the_client'),
            role: 'client',
            createdAt: now,
            updatedAt: now,
          ));

      final user = (await db.select(db.users).get()).single;

      expect(user.id, 'user-2');
      expect(user.name, 'Bob Client');
      expect(user.email, 'bob@example.com');
      expect(user.username, 'bob_the_client');
      expect(user.role, 'client');
      // Default values
      expect(user.tier, 'STARTER');
      expect(user.weightUnit, 'KG');
      expect(user.pushTokens, '[]');
      expect(user.defaultCheckInDay, 0);
      expect(user.defaultCheckInHour, 9);
      expect(user.hasCompletedOnboarding, false);
      expect(user.stripeCancelAtPeriodEnd, false);
      // Timestamps
      expect(user.createdAt, now);
      expect(user.updatedAt, now);
    });

    test('update a record', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-3',
            name: 'Old Name',
            email: 'old@example.com',
            role: 'trainer',
            createdAt: now,
            updatedAt: now,
          ));

      final later = _tsLater();
      await db.update(db.users).replace(UsersCompanion(
            id: const Value('user-3'),
            name: const Value('New Name'),
            email: const Value('new@example.com'),
            role: const Value('trainer'),
            createdAt: Value(now),
            updatedAt: Value(later),
          ));

      final user = (await db.select(db.users).get()).single;
      expect(user.name, 'New Name');
      expect(user.email, 'new@example.com');
      expect(user.updatedAt, later);
    });

    test('soft-delete by setting deletedAt', () async {
      // Users table does NOT have deletedAt column — skip this for users.
      // Instead, verify that the user can be deleted via delete query.
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-4',
            name: 'To Delete',
            email: 'delete@example.com',
            role: 'client',
            createdAt: now,
            updatedAt: now,
          ));

      await db.delete(db.users).go();
      final remaining = await db.select(db.users).get();
      expect(remaining, isEmpty);
    });
  });

  // =========================================================================
  // 3. Clients table CRUD
  // =========================================================================
  group('Clients table', () {
    final now = _ts();

    test('insert a client with trainerId foreign key', () async {
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'client-1',
            name: 'John Doe',
            status: 'active',
            trainerId: const Value('trainer-1'),
            createdAt: now,
            updatedAt: now,
          ));

      final client = (await db.select(db.clients).get()).single;
      expect(client.id, 'client-1');
      expect(client.name, 'John Doe');
      expect(client.trainerId, 'trainer-1');
      expect(client.status, 'active');
    });

    test('query clients by trainerId', () async {
      await db.batch((batch) {
        batch.insert(db.clients, ClientsCompanion.insert(
              id: 'client-a',
              name: 'Alice',
              status: 'active',
              trainerId: const Value('trainer-x'),
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.clients, ClientsCompanion.insert(
              id: 'client-b',
              name: 'Bob',
              status: 'active',
              trainerId: const Value('trainer-x'),
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.clients, ClientsCompanion.insert(
              id: 'client-c',
              name: 'Carol',
              status: 'active',
              trainerId: const Value('trainer-y'),
              createdAt: now,
              updatedAt: now,
            ));
      });

      final forTrainerX = await (db.select(db.clients)
            ..where((t) => t.trainerId.equals('trainer-x')))
          .get();
      expect(forTrainerX.length, 2);
      expect(forTrainerX.map((c) => c.name), containsAll(['Alice', 'Bob']));

      final forTrainerY = await (db.select(db.clients)
            ..where((t) => t.trainerId.equals('trainer-y')))
          .get();
      expect(forTrainerY.length, 1);
      expect(forTrainerY.single.name, 'Carol');
    });

    test('syncStatus defaults to 0', () async {
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'client-sync',
            name: 'Sync Check',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ));

      final client = (await db.select(db.clients).get()).single;
      expect(client.syncStatus, 0);
    });
  });

  // =========================================================================
  // 4. Exercises table CRUD
  // =========================================================================
  group('Exercises table', () {
    final now = _ts();

    test('insert exercises', () async {
      await db.into(db.exercises).insert(ExercisesCompanion.insert(
            id: 'ex-1',
            name: 'Bench Press',
            muscleGroup: const Value('Chest'),
            createdAt: now,
            updatedAt: now,
          ));

      final exercise = (await db.select(db.exercises).get()).single;
      expect(exercise.id, 'ex-1');
      expect(exercise.name, 'Bench Press');
      expect(exercise.muscleGroup, 'Chest');
    });

    test('list all exercises', () async {
      await db.batch((batch) {
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-1',
              name: 'Bench Press',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-2',
              name: 'Squat',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-3',
              name: 'Deadlift',
              createdAt: now,
              updatedAt: now,
            ));
      });

      final all = await db.select(db.exercises).get();
      expect(all.length, 3);
    });

    test('filter exercises by name', () async {
      await db.batch((batch) {
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-1',
              name: 'Bench Press',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-2',
              name: 'Incline Bench Press',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-3',
              name: 'Squat',
              createdAt: now,
              updatedAt: now,
            ));
      });

      final benchExercises = await (db.select(db.exercises)
            ..where((t) => t.name.contains('Bench')))
          .get();
      expect(benchExercises.length, 2);
    });

    test('filter exercises by muscleGroup', () async {
      await db.batch((batch) {
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-1',
              name: 'Bench Press',
              muscleGroup: const Value('Chest'),
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-2',
              name: 'Leg Press',
              muscleGroup: const Value('Legs'),
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'ex-3',
              name: 'Push Up',
              muscleGroup: const Value('Chest'),
              createdAt: now,
              updatedAt: now,
            ));
      });

      final chestExercises = await (db.select(db.exercises)
            ..where((t) => t.muscleGroup.equals('Chest')))
          .get();
      expect(chestExercises.length, 2);
      expect(chestExercises.map((e) => e.name),
          containsAll(['Bench Press', 'Push Up']));
    });
  });

  // =========================================================================
  // 5. SyncQueueItems table CRUD
  // =========================================================================
  group('SyncQueueItems table', () {
    final now = _ts();

    test('insert a sync queue item', () async {
      await db.into(db.syncQueueItems).insert(SyncQueueItemsCompanion.insert(
            id: 'sync-1',
            targetTable: 'clients',
            recordId: 'client-1',
            operation: 'CREATE',
            data: '{"name": "Test"}',
            createdAt: now,
          ));

      final item = (await db.select(db.syncQueueItems).get()).single;
      expect(item.id, 'sync-1');
      expect(item.targetTable, 'clients');
      expect(item.recordId, 'client-1');
      expect(item.operation, 'CREATE');
      expect(item.data, '{"name": "Test"}');
      expect(item.retryCount, 0); // default value
    });

    test('query pending items (all items)', () async {
      await db.batch((batch) {
        batch.insert(db.syncQueueItems, SyncQueueItemsCompanion.insert(
              id: 'sync-a',
              targetTable: 'clients',
              recordId: 'c-1',
              operation: 'CREATE',
              data: '{}',
              createdAt: now,
            ));
        batch.insert(db.syncQueueItems, SyncQueueItemsCompanion.insert(
              id: 'sync-b',
              targetTable: 'exercises',
              recordId: 'e-1',
              operation: 'UPDATE',
              data: '{}',
              createdAt: now,
            ));
      });

      final all = await db.select(db.syncQueueItems).get();
      expect(all.length, 2);

      // Query only CREATE operations
      final creates = await (db.select(db.syncQueueItems)
            ..where((t) => t.operation.equals('CREATE')))
          .get();
      expect(creates.length, 1);
      expect(creates.single.id, 'sync-a');
    });

    test('delete item after syncing (mark as synced)', () async {
      await db.into(db.syncQueueItems).insert(SyncQueueItemsCompanion.insert(
            id: 'sync-to-delete',
            targetTable: 'clients',
            recordId: 'c-1',
            operation: 'CREATE',
            data: '{}',
            createdAt: now,
          ));

      // "Mark as synced" — delete the processed item
      await (db.delete(db.syncQueueItems)
            ..where((t) => t.id.equals('sync-to-delete')))
          .go();

      final remaining = await db.select(db.syncQueueItems).get();
      expect(remaining, isEmpty);
    });

    test('clear all synced items', () async {
      await db.batch((batch) {
        batch.insert(db.syncQueueItems, SyncQueueItemsCompanion.insert(
              id: 's1',
              targetTable: 'clients',
              recordId: 'c-1',
              operation: 'CREATE',
              data: '{}',
              createdAt: now,
            ));
        batch.insert(db.syncQueueItems, SyncQueueItemsCompanion.insert(
              id: 's2',
              targetTable: 'exercises',
              recordId: 'e-1',
              operation: 'DELETE',
              data: '{}',
              createdAt: now,
            ));
      });

      // Clear all processed items
      await db.delete(db.syncQueueItems).go();
      final remaining = await db.select(db.syncQueueItems).get();
      expect(remaining, isEmpty);
    });
  });

  // =========================================================================
  // 6. WorkoutSessions table CRUD
  // =========================================================================
  group('WorkoutSessions table', () {
    final now = _ts();

    test('insert with clientId foreign key', () async {
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: 'ws-1',
              clientId: 'client-1',
              startTime: now,
              status: 'SCHEDULED',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final session =
          (await db.select(db.workoutSessions).get()).single;
      expect(session.id, 'ws-1');
      expect(session.clientId, 'client-1');
      expect(session.status, 'SCHEDULED');
    });

    test('query sessions by status', () async {
      await db.batch((batch) {
        batch.insert(db.workoutSessions, WorkoutSessionsCompanion.insert(
              id: 'ws-1',
              clientId: 'c-1',
              startTime: now,
              status: 'SCHEDULED',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.workoutSessions, WorkoutSessionsCompanion.insert(
              id: 'ws-2',
              clientId: 'c-2',
              startTime: now,
              status: 'COMPLETED',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.workoutSessions, WorkoutSessionsCompanion.insert(
              id: 'ws-3',
              clientId: 'c-1',
              startTime: now,
              status: 'SCHEDULED',
              createdAt: now,
              updatedAt: now,
            ));
      });

      final scheduled = await (db.select(db.workoutSessions)
            ..where((t) => t.status.equals('SCHEDULED')))
          .get();
      expect(scheduled.length, 2);
      expect(scheduled.map((s) => s.clientId),
          containsAll(['c-1', 'c-1']));
    });

    test('update status to COMPLETED', () async {
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: 'ws-update',
              clientId: 'c-1',
              startTime: now,
              status: 'SCHEDULED',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final later = _tsLater();
      await (db.update(db.workoutSessions)
            ..where((t) => t.id.equals('ws-update')))
          .write(const WorkoutSessionsCompanion(
            status: Value('COMPLETED'),
          ));

      // Also update updatedAt manually — drift's write with a companion
      // that doesn't include updatedAt won't touch it. Let's do a full
      // companion update to be explicit.
      await (db.update(db.workoutSessions)
            ..where((t) => t.id.equals('ws-update')))
          .write(WorkoutSessionsCompanion(
            status: const Value('COMPLETED'),
            updatedAt: Value(later),
          ));

      final session = (await db.select(db.workoutSessions).get()).single;
      expect(session.status, 'COMPLETED');
      expect(session.updatedAt, later);
    });
  });

  // =========================================================================
  // 7. Batch operations
  // =========================================================================
  group('Batch operations', () {
    final now = _ts();

    test('insert multiple records across tables in one batch', () async {
      await db.batch((batch) {
        batch.insert(db.users, UsersCompanion.insert(
              id: 'batch-user',
              name: 'Batch User',
              email: 'batch@example.com',
              role: 'trainer',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.clients, ClientsCompanion.insert(
              id: 'batch-client',
              name: 'Batch Client',
              status: 'active',
              createdAt: now,
              updatedAt: now,
            ));
        batch.insert(db.exercises, ExercisesCompanion.insert(
              id: 'batch-ex',
              name: 'Batch Exercise',
              createdAt: now,
              updatedAt: now,
            ));
      });

      final users = await db.select(db.users).get();
      expect(users.length, 1);
      expect(users.single.id, 'batch-user');

      final clients = await db.select(db.clients).get();
      expect(clients.length, 1);
      expect(clients.single.id, 'batch-client');

      final exercises = await db.select(db.exercises).get();
      expect(exercises.length, 1);
      expect(exercises.single.id, 'batch-ex');
    });

    test('duplicate key throws exception', () async {
      // First insert succeeds
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'dup',
            name: 'First',
            email: 'first@example.com',
            role: 'trainer',
            createdAt: now,
            updatedAt: now,
          ));

      // Second insert with same primary key must throw
      await expectLater(
        db.into(db.users).insert(UsersCompanion.insert(
              id: 'dup',
              name: 'Second',
              email: 'second@example.com',
              role: 'client',
              createdAt: now,
              updatedAt: now,
            )),
        throwsException,
      );
    });
  });

  // =========================================================================
  // 8. Data integrity
  // =========================================================================
  group('Data integrity', () {
    final now = _ts();

    test('timestamps are stored as int64 (BigInt)', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'ts-user',
            name: 'Timestamp Test',
            email: 'ts@example.com',
            role: 'trainer',
            createdAt: now,
            updatedAt: now,
          ));

      final user = (await db.select(db.users).get()).single;
      expect(user.createdAt, isA<BigInt>());
      expect(user.updatedAt, isA<BigInt>());
      expect(user.createdAt, now);
    });

    test('nullable fields can be null', () async {
      // Clients has many nullable columns
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'nullable-test',
            name: 'Nullable Test',
            status: 'active',
            createdAt: now,
            updatedAt: now,
            // All optional fields left absent → should be NULL
          ));

      final client = (await db.select(db.clients).get()).single;
      expect(client.email, isNull);
      expect(client.phone, isNull);
      expect(client.avatarPath, isNull);
      expect(client.dateOfBirth, isNull);
      expect(client.goals, isNull);
      expect(client.healthNotes, isNull);
      expect(client.trainerId, isNull);
      expect(client.userId, isNull);
      expect(client.deletedAt, isNull);
    });

    test('default values are applied (syncStatus = 0)', () async {
      // Check on Clients
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'default-client',
            name: 'Default Val',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ));
      final client = (await db.select(db.clients).get()).single;
      expect(client.syncStatus, 0);

      // Check on Exercises
      await db.into(db.exercises).insert(ExercisesCompanion.insert(
            id: 'default-ex',
            name: 'Default Val Ex',
            createdAt: now,
            updatedAt: now,
          ));
      final exercise = (await db.select(db.exercises).get()).single;
      expect(exercise.syncStatus, 0);

      // Check on WorkoutSessions
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: 'default-ws',
              clientId: 'c-1',
              startTime: now,
              status: 'SCHEDULED',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final session =
          (await db.select(db.workoutSessions).get()).single;
      expect(session.syncStatus, 0);

      // Check Users defaults
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'default-user',
            name: 'Default User',
            email: 'default@example.com',
            role: 'trainer',
            createdAt: now,
            updatedAt: now,
          ));
      final user = (await db.select(db.users).get()).single;
      expect(user.tier, 'STARTER');
      expect(user.weightUnit, 'KG');
      expect(user.pushTokens, '[]');
      expect(user.defaultCheckInDay, 0);
      expect(user.defaultCheckInHour, 9);
    });

    test('multiple records with distinct primary keys', () async {
      await db.batch((batch) {
        for (int i = 1; i <= 5; i++) {
          batch.insert(db.exercises, ExercisesCompanion.insert(
                id: 'ex-batch-$i',
                name: 'Exercise $i',
                createdAt: now,
                updatedAt: now,
              ));
        }
      });

      final all = await db.select(db.exercises).get();
      expect(all.length, 5);
      for (int i = 1; i <= 5; i++) {
        expect(all.any((e) => e.id == 'ex-batch-$i'), isTrue);
      }
    });

    test('soft-delete pattern (deletedAt on supported tables)', () async {
      // Clients has deletedAt — soft-delete by setting it
      await db.into(db.clients).insert(ClientsCompanion.insert(
            id: 'soft-del-client',
            name: 'Soft Delete',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ));

      final deletedTs = _tsLater();
      await (db.update(db.clients)
            ..where((t) => t.id.equals('soft-del-client')))
          .write(ClientsCompanion(
            deletedAt: Value(deletedTs),
            updatedAt: Value(deletedTs),
          ));

      // The row should still exist but with deletedAt set
      final client =
          (await db.select(db.clients).get()).single;
      expect(client.deletedAt, isNotNull);
      expect(client.deletedAt, deletedTs);

      // Query only non-deleted clients by filtering out deletedAt
      // (this is the pattern used in the app for soft-delete filtering)
      final activeClients = await (db.select(db.clients)
            ..where((t) => t.deletedAt.isNull()))
          .get();
      expect(activeClients, isEmpty);
    });
  });
}
