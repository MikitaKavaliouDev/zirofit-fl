import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/database/app_database.dart' as db;
import 'package:zirofit_fl/data/sync/sync_models.dart';
import 'package:zirofit_fl/data/sync/sync_queue.dart';
import '../../helpers/test_database.dart';

void main() {
  late db.AppDatabase database;
  late SyncQueue syncQueue;

  setUp(() async {
    database = await createTestDatabase();
    syncQueue = SyncQueue(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncQueueItem construction', () {
    test('id is auto-generated when not provided', () {
      final item = SyncQueueItem(
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'name': 'test'},
      );
      expect(item.id, isNotEmpty);
      // Should be a UUID-like string
      expect(item.id.length, greaterThanOrEqualTo(32));
    });

    test('createdAt is auto-generated when not provided', () {
      final before = DateTime.now();
      final item = SyncQueueItem(
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'name': 'test'},
      );
      final after = DateTime.now();
      expect(item.createdAt, isNotNull);
      // createdAt should be between before and after (within reasonable delta)
      expect(
        item.createdAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch - 1),
      );
      expect(
        item.createdAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch + 1),
      );
    });

    test('fromRow() converts database row to domain model correctly', () {
      final dbRow = db.SyncQueueItem(
        id: 'test-id',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: 'CREATE',
        data: '{"name":"test client"}',
        createdAt: BigInt.from(1000000),
        retryCount: 2,
        error: 'previous error',
      );
      final item = SyncQueueItem.fromRow(dbRow);

      expect(item.id, 'test-id');
      expect(item.targetTable, 'clients');
      expect(item.recordId, 'rec-1');
      expect(item.operation, SyncOperation.create);
      expect(item.data, {'name': 'test client'});
      expect(item.createdAt.millisecondsSinceEpoch, 1000000);
      expect(item.retryCount, 2);
      expect(item.error, 'previous error');
    });

    test('fromRow() handles all SyncOperation types', () {
      for (final op in SyncOperation.values) {
        final dbRow = db.SyncQueueItem(
          id: 'id-${op.name}',
          targetTable: 'clients',
          recordId: 'rec-1',
          operation: op.name.toUpperCase(),
          data: '{}',
          createdAt: BigInt.zero,
          retryCount: 0,
        );
        final item = SyncQueueItem.fromRow(dbRow);
        expect(item.operation, op);
      }
    });

    test('fromRow() handles null error field', () {
      final dbRow = db.SyncQueueItem(
        id: 'no-error',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: 'DELETE',
        data: '{}',
        createdAt: BigInt.zero,
        retryCount: 0,
      );
      final item = SyncQueueItem.fromRow(dbRow);
      expect(item.error, isNull);
    });

    test('toCompanion() produces correct data with all fields', () {
      final item = SyncQueueItem(
        id: 'test-id',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.update,
        data: {'name': 'test', 'age': 30},
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000000),
        retryCount: 3,
        error: 'previous error',
      );

      final companion = item.toCompanion();

      expect(companion.id.value, 'test-id');
      expect(companion.targetTable.value, 'clients');
      expect(companion.recordId.value, 'rec-1');
      expect(companion.operation.value, 'UPDATE');
      expect(companion.data.value, '{"name":"test","age":30}');
      expect(companion.createdAt.value, BigInt.from(2000000));
      expect(companion.retryCount.value, 3);
      expect(companion.error.value, 'previous error');
    });

    test('toCompanion() handles null error field', () {
      final item = SyncQueueItem(
        id: 'no-error',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      );

      final companion = item.toCompanion();

      expect(companion.error.value, isNull);
    });
  });

  group('SyncQueue.add()', () {
    test('adds item to queue', () async {
      final item = SyncQueueItem(
        id: 'add-test-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'name': 'test'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      await syncQueue.add(item);

      final count = await syncQueue.count();
      expect(count, 1);
    });

    test('maintains FIFO order of added items', () async {
      final item1 = SyncQueueItem(
        id: 'fifo-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'name': 'first'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final item2 = SyncQueueItem(
        id: 'fifo-2',
        targetTable: 'workouts',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {'name': 'second'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      await syncQueue.add(item1);
      await syncQueue.add(item2);

      final items = await syncQueue.getAllPending();
      expect(items.length, 2);
      expect(items[0].id, 'fifo-1');
      expect(items[1].id, 'fifo-2');
    });
  });

  group('SyncQueue.getAllPending()', () {
    test('returns empty list when no items', () async {
      final items = await syncQueue.getAllPending();
      expect(items, isEmpty);
    });

    test('returns items in FIFO order (by createdAt)', () async {
      // Insert out of chronological order but with explicit timestamps
      final itemEarly = SyncQueueItem(
        id: 'early',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'order': 1},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      );
      final itemLate = SyncQueueItem(
        id: 'late',
        targetTable: 'exercises',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {'order': 2},
        createdAt: DateTime.fromMillisecondsSinceEpoch(200),
      );
      final itemLatest = SyncQueueItem(
        id: 'latest',
        targetTable: 'workouts',
        recordId: 'rec-3',
        operation: SyncOperation.delete,
        data: {'order': 3},
        createdAt: DateTime.fromMillisecondsSinceEpoch(300),
      );

      await syncQueue.add(itemLate);
      await syncQueue.add(itemEarly);
      await syncQueue.add(itemLatest);

      final items = await syncQueue.getAllPending();
      expect(items.length, 3);
      expect(items[0].id, 'early'); // earliest createdAt first
      expect(items[1].id, 'late');
      expect(items[2].id, 'latest');
    });
  });

  group('SyncQueue.count()', () {
    test('returns 0 when empty', () async {
      final count = await syncQueue.count();
      expect(count, 0);
    });

    test('returns correct count after adding items', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'cnt-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));
      await syncQueue.add(SyncQueueItem(
        id: 'cnt-2',
        targetTable: 'workouts',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(200),
      ));
      await syncQueue.add(SyncQueueItem(
        id: 'cnt-3',
        targetTable: 'exercises',
        recordId: 'rec-3',
        operation: SyncOperation.delete,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(300),
      ));

      expect(await syncQueue.count(), 3);
    });

    test('returns correct count after removing items', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'c-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));
      await syncQueue.add(SyncQueueItem(
        id: 'c-2',
        targetTable: 'workouts',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(200),
      ));

      expect(await syncQueue.count(), 2);

      await syncQueue.remove('c-1');

      expect(await syncQueue.count(), 1);
    });
  });

  group('SyncQueue.remove()', () {
    test('removes item by id', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'remove-me',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));

      expect(await syncQueue.count(), 1);

      await syncQueue.remove('remove-me');

      expect(await syncQueue.count(), 0);
      final items = await syncQueue.getAllPending();
      expect(items.where((i) => i.id == 'remove-me'), isEmpty);
    });

    test('removing non-existent id does nothing (no crash)', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'stay',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));

      expect(await syncQueue.count(), 1);

      // Should not throw
      await syncQueue.remove('non-existent');

      expect(await syncQueue.count(), 1);
      final items = await syncQueue.getAllPending();
      expect(items[0].id, 'stay');
    });
  });

  group('SyncQueue.clearAll()', () {
    test('removes all items from queue', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'clr-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));
      await syncQueue.add(SyncQueueItem(
        id: 'clr-2',
        targetTable: 'workouts',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(200),
      ));

      expect(await syncQueue.count(), 2);

      await syncQueue.clearAll();

      expect(await syncQueue.count(), 0);
    });

    test('count returns 0 after clear and getAllPending is empty', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'clr-3',
        targetTable: 'clients',
        recordId: 'rec-3',
        operation: SyncOperation.delete,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));

      await syncQueue.clearAll();

      expect(await syncQueue.count(), 0);
      final items = await syncQueue.getAllPending();
      expect(items, isEmpty);
    });
  });

  group('SyncQueue.markFailed()', () {
    test('increments retryCount and sets error message', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'fail-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
        retryCount: 0,
      ));

      await syncQueue.markFailed('fail-1', 'network error');

      final items = await syncQueue.getAllPending();
      expect(items.length, 1);
      expect(items[0].retryCount, 1);
      expect(items[0].error, 'network error');
    });

    test('increments retryCount cumulatively across multiple failures', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'fail-2',
        targetTable: 'clients',
        recordId: 'rec-2',
        operation: SyncOperation.update,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
        retryCount: 0,
      ));

      await syncQueue.markFailed('fail-2', 'error 1');
      await syncQueue.markFailed('fail-2', 'error 2');
      await syncQueue.markFailed('fail-2', 'error 3');

      final items = await syncQueue.getAllPending();
      expect(items[0].retryCount, 3);
      expect(items[0].error, 'error 3');
    });

    test('non-existent id does nothing (no crash)', () async {
      await syncQueue.add(SyncQueueItem(
        id: 'fail-3',
        targetTable: 'clients',
        recordId: 'rec-3',
        operation: SyncOperation.delete,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));

      expect(await syncQueue.count(), 1);

      // Should not throw
      await syncQueue.markFailed('non-existent', 'something went wrong');

      // Original item should be unchanged
      expect(await syncQueue.count(), 1);
      final items = await syncQueue.getAllPending();
      expect(items[0].id, 'fail-3');
      expect(items[0].retryCount, 0);
      expect(items[0].error, isNull);
    });
  });

  group('SyncQueue integration', () {
    test('full lifecycle: add, retrieve, mark failed, remove', () async {
      final item = SyncQueueItem(
        id: 'lifecycle-1',
        targetTable: 'clients',
        recordId: 'rec-1',
        operation: SyncOperation.create,
        data: {'name': 'integration test'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        retryCount: 0,
      );

      // Add
      await syncQueue.add(item);
      expect(await syncQueue.count(), 1);

      // Retrieve
      var items = await syncQueue.getAllPending();
      expect(items.length, 1);
      expect(items[0].targetTable, 'clients');

      // Mark failed
      await syncQueue.markFailed('lifecycle-1', 'server timeout');
      items = await syncQueue.getAllPending();
      expect(items[0].retryCount, 1);
      expect(items[0].error, 'server timeout');

      // Remove
      await syncQueue.remove('lifecycle-1');
      expect(await syncQueue.count(), 0);
    });

    test('handles multiple items with mixed operations', () async {
      final create = SyncQueueItem(
        id: 'mix-1',
        targetTable: 'clients',
        recordId: 'c-1',
        operation: SyncOperation.create,
        data: {'name': 'new'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(100),
      );
      final update = SyncQueueItem(
        id: 'mix-2',
        targetTable: 'workouts',
        recordId: 'w-1',
        operation: SyncOperation.update,
        data: {'name': 'changed'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(200),
      );
      final delete = SyncQueueItem(
        id: 'mix-3',
        targetTable: 'exercises',
        recordId: 'e-1',
        operation: SyncOperation.delete,
        data: {},
        createdAt: DateTime.fromMillisecondsSinceEpoch(300),
      );

      await syncQueue.add(update);
      await syncQueue.add(delete);
      await syncQueue.add(create);

      var count = await syncQueue.count();
      expect(count, 3);

      var items = await syncQueue.getAllPending();
      // Sorted by createdAt ascending: 100, 200, 300
      expect(items[0].id, 'mix-1'); // createdAt 100
      expect(items[1].id, 'mix-2'); // createdAt 200
      expect(items[2].id, 'mix-3'); // createdAt 300

      // Fail the middle one
      await syncQueue.markFailed('mix-3', 'conflict');

      items = await syncQueue.getAllPending();
      expect(items[2].retryCount, 1); // mix-3 was marked failed
      expect(items[2].error, 'conflict');

      // Clear all
      await syncQueue.clearAll();
      expect(await syncQueue.count(), 0);
    });
  });
}
