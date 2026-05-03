import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:zirofit_fl/core/database/app_database.dart';
import 'package:zirofit_fl/data/sync/sync_local_source.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncLocalSource source;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = await createTestDatabase();
    source = SyncLocalSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('constructor', () {
    test('creates SyncLocalSource successfully', () {
      expect(source, isNotNull);
    });
  });

  group('getLastPulledAt / setLastPulledAt', () {
    test('getLastPulledAt returns 0 when no value stored yet', () async {
      final result = await source.getLastPulledAt();
      expect(result, 0);
    });

    test('getLastPulledAt returns stored value after setLastPulledAt', () async {
      await source.setLastPulledAt(987654321);
      final result = await source.getLastPulledAt();
      expect(result, 987654321);
    });

    test('setLastPulledAt overwrites previous value', () async {
      await source.setLastPulledAt(1000);
      await source.setLastPulledAt(9999);
      final result = await source.getLastPulledAt();
      expect(result, 9999);
    });
  });

  group('upsertRecord', () {
    test('inserts a new record when it does not exist', () async {
      await source.upsertRecord('clients', {
        'id': 'client-1',
        'name': 'Test Client',
        'email': 'test@example.com',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      final rows = await db.customSelect(
        'SELECT id, name, email FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-1')],
      ).get();

      expect(rows.length, 1);
      expect(rows.first.data['id'], 'client-1');
      expect(rows.first.data['name'], 'Test Client');
      expect(rows.first.data['email'], 'test@example.com');
    });

    test('updates existing record when it already exists', () async {
      // Insert first
      await source.upsertRecord('clients', {
        'id': 'client-2',
        'name': 'Original Name',
        'email': 'original@example.com',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      // Update same record
      await source.upsertRecord('clients', {
        'id': 'client-2',
        'name': 'Updated Name',
        'email': 'updated@example.com',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 2000,
      });

      final rows = await db.customSelect(
        'SELECT name, email FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-2')],
      ).get();

      expect(rows.length, 1);
      expect(rows.first.data['name'], 'Updated Name');
      expect(rows.first.data['email'], 'updated@example.com');
    });

    test('sets sync_status to 0 on inserted records', () async {
      // Pass sync_status: 1, but upsertRecord should override to 0
      await source.upsertRecord('clients', {
        'id': 'client-3',
        'name': 'Sync Status Test',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
        'sync_status': 1,
      });

      final rows = await db.customSelect(
        'SELECT sync_status FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-3')],
      ).get();

      expect(rows.first.data['sync_status'], 0);
    });

    test('skips when id is empty string', () async {
      await source.upsertRecord('clients', {
        'id': '',
        'name': 'Empty ID',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      final rows = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM "clients" WHERE name = ?',
        variables: [Variable.withString('Empty ID')],
      ).get();

      expect(rows.first.data['cnt'], 0);
    });
  });

  group('softDeleteRecord', () {
    test('sets deleted_at, updated_at, and sync_status to 0', () async {
      // Insert a record first
      await source.upsertRecord('clients', {
        'id': 'client-del',
        'name': 'To Soft Delete',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      // Mark sync_status as pending so we can verify it gets reset to 0
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 1 WHERE id = ?',
        variables: [Variable.withString('client-del')],
      );

      await source.softDeleteRecord('clients', 'client-del');

      final rows = await db.customSelect(
        'SELECT deleted_at, updated_at, sync_status FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-del')],
      ).get();

      expect(rows.length, 1);
      expect(rows.first.data['deleted_at'], isNotNull);
      expect(rows.first.data['deleted_at'] as int, greaterThan(0));
      expect(rows.first.data['updated_at'] as int, greaterThan(1000));
      expect(rows.first.data['sync_status'], 0);
    });
  });

  group('deleteRecord', () {
    test('removes a record entirely from the table', () async {
      // Insert a record first
      await source.upsertRecord('clients', {
        'id': 'client-hard-del',
        'name': 'Hard Delete',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      await source.deleteRecord('clients', 'client-hard-del');

      final rows = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-hard-del')],
      ).get();

      expect(rows.first.data['cnt'], 0);
    });
  });

  group('markSynced', () {
    test('sets sync_status to 0 for the specific record', () async {
      await source.upsertRecord('clients', {
        'id': 'client-sync-me',
        'name': 'Mark Synced',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      // Set sync_status to pending (2 = PENDING_UPDATE)
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 2 WHERE id = ?',
        variables: [Variable.withString('client-sync-me')],
      );

      await source.markSynced('clients', 'client-sync-me');

      final rows = await db.customSelect(
        'SELECT sync_status FROM "clients" WHERE id = ?',
        variables: [Variable.withString('client-sync-me')],
      ).get();

      expect(rows.first.data['sync_status'], 0);
    });
  });

  group('markAllSynced', () {
    test('resets all pending records to sync_status 0 across tables', () async {
      // Insert records in multiple tables
      await source.upsertRecord('clients', {
        'id': 'c1', 'name': 'Client1', 'status': 'active',
        'created_at': 1000, 'updated_at': 1000,
      });
      await source.upsertRecord('profiles', {
        'id': 'p1', 'user_id': 'u1',
        'created_at': 1000, 'updated_at': 1000,
      });

      // Set various non-zero sync_status values
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 1 WHERE id = ?',
        variables: [Variable.withString('c1')],
      );
      await db.customUpdate(
        'UPDATE "profiles" SET sync_status = 2 WHERE id = ?',
        variables: [Variable.withString('p1')],
      );

      await source.markAllSynced();

      final clientRows = await db.customSelect(
        'SELECT sync_status FROM "clients" WHERE id = ?',
        variables: [Variable.withString('c1')],
      ).get();
      final profileRows = await db.customSelect(
        'SELECT sync_status FROM "profiles" WHERE id = ?',
        variables: [Variable.withString('p1')],
      ).get();

      expect(clientRows.first.data['sync_status'], 0);
      expect(profileRows.first.data['sync_status'], 0);
    });
  });

  group('getPendingCount', () {
    test('returns 0 when no pending records exist', () async {
      final count = await source.getPendingCount();
      expect(count, 0);
    });

    test('returns correct count after inserting pending records', () async {
      // Insert two records
      await source.upsertRecord('clients', {
        'id': 'pc1', 'name': 'Pending1', 'status': 'active',
        'created_at': 1000, 'updated_at': 1000,
      });
      await source.upsertRecord('clients', {
        'id': 'pc2', 'name': 'Pending2', 'status': 'active',
        'created_at': 1000, 'updated_at': 1000,
      });

      // Mark both as pending
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 1 WHERE id = ?',
        variables: [Variable.withString('pc1')],
      );
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 2 WHERE id = ?',
        variables: [Variable.withString('pc2')],
      );

      final count = await source.getPendingCount();
      expect(count, 2);
    });
  });

  group('collectPendingChanges', () {
    test('returns null when no pending records', () async {
      final result = await source.collectPendingChanges();
      expect(result, isNull);
    });

    test('returns PENDING_CREATE changes with internal timestamps stripped',
        () async {
      await source.upsertRecord('clients', {
        'id': 'cc1', 'name': 'Created Client', 'status': 'active',
        'created_at': 1000, 'updated_at': 2000,
      });

      // Set sync_status = 1 (PENDING_CREATE)
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 1 WHERE id = ?',
        variables: [Variable.withString('cc1')],
      );

      final result = await source.collectPendingChanges();
      expect(result, isNotNull);
      expect(result!.containsKey('clients'), isTrue);

      final changes = result['clients']!;
      expect(changes.created.length, 1);
      expect(changes.created.first['id'], 'cc1');
      expect(changes.created.first['name'], 'Created Client');
      // PENDING_CREATE strips internal timestamps
      expect(changes.created.first.containsKey('created_at'), isFalse);
      expect(changes.created.first.containsKey('updated_at'), isFalse);
      expect(changes.created.first.containsKey('sync_status'), isFalse);
      expect(changes.created.first.containsKey('deleted_at'), isFalse);
    });

    test('returns PENDING_UPDATE changes with only sync_status stripped',
        () async {
      await source.upsertRecord('clients', {
        'id': 'cu1', 'name': 'Updated Client', 'status': 'active',
        'created_at': 1000, 'updated_at': 2000,
      });

      // Set sync_status = 2 (PENDING_UPDATE)
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 2 WHERE id = ?',
        variables: [Variable.withString('cu1')],
      );

      final result = await source.collectPendingChanges();
      expect(result, isNotNull);
      expect(result!.containsKey('clients'), isTrue);

      final changes = result['clients']!;
      expect(changes.updated.length, 1);
      expect(changes.updated.first['id'], 'cu1');
      expect(changes.updated.first['name'], 'Updated Client');
      // PENDING_UPDATE only strips sync_status
      expect(changes.updated.first.containsKey('sync_status'), isFalse);
      // created_at should still be present
      expect(changes.updated.first.containsKey('created_at'), isTrue);
      expect(changes.updated.first['created_at'], 1000);
    });

    test('returns PENDING_DELETE changes with deleted record ids', () async {
      await source.upsertRecord('clients', {
        'id': 'cd1', 'name': 'Deleted Client', 'status': 'active',
        'created_at': 1000, 'updated_at': 2000,
      });

      // Set sync_status = 3 (PENDING_DELETE)
      await db.customUpdate(
        'UPDATE "clients" SET sync_status = 3 WHERE id = ?',
        variables: [Variable.withString('cd1')],
      );

      final result = await source.collectPendingChanges();
      expect(result, isNotNull);
      expect(result!.containsKey('clients'), isTrue);

      final changes = result['clients']!;
      expect(changes.deleted.length, 1);
      expect(changes.deleted.first, 'cd1');
    });
  });

  group('cleanSyncedDeletions', () {
    test('removes deleted records that are synced (deleted_at IS NOT NULL AND sync_status = 0)',
        () async {
      await source.upsertRecord('clients', {
        'id': 'clean-synced',
        'name': 'Clean Me',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      // Set deleted_at and sync_status = 0 (synced and soft-deleted)
      await db.customUpdate(
        'UPDATE "clients" SET deleted_at = 100, sync_status = 0 WHERE id = ?',
        variables: [Variable.withString('clean-synced')],
      );

      await source.cleanSyncedDeletions();

      final rows = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM "clients" WHERE id = ?',
        variables: [Variable.withString('clean-synced')],
      ).get();
      expect(rows.first.data['cnt'], 0);
    });

    test('keeps deleted records that are not synced (deleted_at IS NOT NULL BUT sync_status != 0)',
        () async {
      await source.upsertRecord('clients', {
        'id': 'keep-unsynced',
        'name': 'Keep Me',
        'status': 'active',
        'created_at': 1000,
        'updated_at': 1000,
      });

      // Set deleted_at but sync_status = 1 (not synced)
      await db.customUpdate(
        'UPDATE "clients" SET deleted_at = 200, sync_status = 1 WHERE id = ?',
        variables: [Variable.withString('keep-unsynced')],
      );

      await source.cleanSyncedDeletions();

      final rows = await db.customSelect(
        'SELECT COUNT(*) as cnt, sync_status FROM "clients" WHERE id = ?',
        variables: [Variable.withString('keep-unsynced')],
      ).get();
      expect(rows.first.data['cnt'], 1);
      expect(rows.first.data['sync_status'], 1);
    });
  });

  group('_toVariable (indirect test via upsertRecord)', () {
    test('correctly converts null, int, double, bool, String, and complex values',
        () async {
      await source.upsertRecord('profiles', {
        'id': 'type-test-1',
        'user_id': 'user-1',
        // null → NULL variable
        'phone': null,
        // double → REAL variable
        'average_rating': 4.5,
        // bool → INT (0/1) variable
        'is_verified': true,
        // String → string variable
        'specialties': '["strength","cardio"]',
        // complex object → JSON string variable
        'training_types': ['online', 'in_person'],
        // int → int variable
        'created_at': 1000,
        'updated_at': 999,
      });

      final rows = await db.customSelect(
        'SELECT * FROM "profiles" WHERE id = ?',
        variables: [Variable.withString('type-test-1')],
      ).get();

      expect(rows.length, 1);
      final data = rows.first.data;

      // null → null
      expect(data['phone'], isNull);

      // double → real (stored as REAL in SQLite)
      expect(data['average_rating'], closeTo(4.5, 0.001));

      // bool → int (0/1 in SQLite)
      expect(data['is_verified'], 1);

      // String → string variable
      expect(data['user_id'], 'user-1');

      // complex object → JSON string
      expect(data['training_types'], isA<String>());
      expect((data['training_types'] as String).contains('online'), isTrue);
      expect((data['training_types'] as String).contains('in_person'), isTrue);

      // int values round-trip
      expect(data['created_at'], 1000);
      expect(data['updated_at'], 999);
    });
  });
}
