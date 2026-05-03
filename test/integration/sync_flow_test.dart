import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/database/app_database.dart';
import 'package:zirofit_fl/data/sync/connectivity_manager.dart';
import 'package:zirofit_fl/data/sync/sync_engine.dart';
import 'package:zirofit_fl/data/sync/sync_local_source.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';
import 'package:zirofit_fl/data/sync/sync_queue.dart' as sq;
import 'package:zirofit_fl/data/sync/sync_remote_source.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSyncRemoteSource extends Mock implements SyncRemoteSource {}
class MockSyncLocalSource extends Mock implements SyncLocalSource {}
class MockSyncQueue extends Mock implements sq.SyncQueue {}
class MockConnectivityManager extends Mock implements ConnectivityManager {}
class MockAppDatabase extends Mock implements AppDatabase {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

sq.SyncQueueItem _queueItem({
  String targetTable = 'clients',
  String recordId = 'client-1',
  SyncOperation operation = SyncOperation.create,
  Map<String, dynamic> data = const {'name': 'New Client'},
}) {
  return sq.SyncQueueItem(
    targetTable: targetTable,
    recordId: recordId,
    operation: operation,
    data: data,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late SyncEngine syncEngine;
  late MockSyncRemoteSource mockRemote;
  late MockSyncLocalSource mockLocal;
  late MockSyncQueue mockQueue;
  late MockConnectivityManager mockConnectivity;
  late MockAppDatabase mockDb;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockRemote = MockSyncRemoteSource();
    mockLocal = MockSyncLocalSource();
    mockQueue = MockSyncQueue();
    mockConnectivity = MockConnectivityManager();
    mockDb = MockAppDatabase();

    // Mocktail fallback values for types used with any()
    registerFallbackValue(sq.SyncQueueItem(
      targetTable: 'fallback',
      recordId: 'fallback',
      operation: SyncOperation.create,
      data: {},
    ));

    // Stub connectivity stream to prevent NullError in constructor
    connectivityController = StreamController<bool>.broadcast();
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);

    syncEngine = SyncEngine(
      remoteSource: mockRemote,
      localSource: mockLocal,
      queue: mockQueue,
      connectivity: mockConnectivity,
      db: mockDb,
    );
  });

  tearDown(() {
    syncEngine.dispose();
    connectivityController.close();
  });

  group('SyncEngine — connectivity', () {
    test('initial status is synced', () {
      expect(syncEngine.currentStatus, SyncUiStatus.synced);
    });

    test('sync() returns failure when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final result = await syncEngine.sync();
      expect(result.isSuccess, false);
      expect(result.error, contains('offline'));
      verifyNever(() => mockRemote.pull(any()));
      verifyNever(() => mockRemote.push(any()));
    });

    test('emits offline status when connectivity is lost', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      await Future.delayed(Duration.zero);
      // The connectivity listener fires after setup
      connectivityController.add(false);
      await Future.delayed(Duration.zero);
      // After the connectivity change, status should become offline
      expect(syncEngine.currentStatus, SyncUiStatus.offline);
    });
  });

  group('SyncEngine — pull', () {
    test('sync() performs pull when online with no pending changes', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});

      final result = await syncEngine.sync();

      expect(result.isSuccess, true);
      expect(result.pushedCount, 0);
      expect(result.pulledCount, 0);
      verify(() => mockRemote.pull(1000)).called(1);
      verify(() => mockLocal.setLastPulledAt(2000)).called(1);
    });

    test('sync() handles pulled records correctly', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 0);

      // Simulate pull returning created and updated records
      when(() => mockRemote.pull(0)).thenAnswer(
            (_) async => const SyncPayload(
              changes: {
                'clients': SyncChanges(
                  created: [
                    {'id': 'c-1', 'name': 'Alice', 'updated_at': 1000},
                  ],
                  updated: [
                    {'id': 'c-2', 'name': 'Bob', 'updated_at': 1001},
                  ],
                  deleted: ['c-3'],
                ),
                'workout_sessions': SyncChanges(
                  created: [
                    {'id': 's-1', 'name': 'Morning Workout', 'updated_at': 1002},
                  ],
                ),
              },
              timestamp: 2000,
            ),
          );

      // Stub local source operations
      when(() => mockLocal.upsertRecord(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.softDeleteRecord(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});

      final result = await syncEngine.sync();

      expect(result.isSuccess, true);
      expect(result.pulledCount, 4); // 2 created + 1 updated + 1 deleted
      verify(() => mockLocal.upsertRecord('clients', any())).called(2);
      verify(() => mockLocal.softDeleteRecord('clients', 'c-3')).called(1);
      verify(() => mockLocal.upsertRecord('workout_sessions', any())).called(1);
      verify(() => mockLocal.setLastPulledAt(2000)).called(1);
    });

    test('sync() emits syncing then synced status during pull', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});

      // Initially synced
      expect(syncEngine.currentStatus, SyncUiStatus.synced);

      final statuses = <SyncUiStatus>[];
      final sub = syncEngine.statusStream.listen(statuses.add);

      await syncEngine.sync();

      expect(statuses, contains(SyncUiStatus.syncing));
      expect(syncEngine.currentStatus, SyncUiStatus.synced);

      await sub.cancel();
    });
  });

  group('SyncEngine — push', () {
    test('sync() pushes pending mutations before pull', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);

      final queueItem = _queueItem(
        targetTable: 'clients',
        recordId: 'client-1',
        operation: SyncOperation.create,
        data: {'name': 'New Client'},
      );
      when(() => mockQueue.getAllPending())
          .thenAnswer((_) async => [queueItem]);
      when(() => mockRemote.push(any())).thenAnswer(
            (_) async => {'timestamp': 2000},
          );
      when(() => mockLocal.markAllSynced()).thenAnswer((_) async {});
      when(() => mockQueue.remove(any())).thenAnswer((_) async {});
      when(() => mockLocal.cleanSyncedDeletions()).thenAnswer((_) async {});
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );

      final result = await syncEngine.sync();

      expect(result.isSuccess, true);
      expect(result.pushedCount, 1);
      verify(() => mockRemote.push(any())).called(1);
      verify(() => mockRemote.pull(any())).called(1);
      verify(() => mockLocal.markAllSynced()).called(1);
      verify(() => mockQueue.remove(queueItem.id)).called(1);
      verify(() => mockLocal.cleanSyncedDeletions()).called(1);
    });

    test('sync() pushes both queue items and pending local changes', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      // Pending local changes (from sync_status columns)
      when(() => mockLocal.collectPendingChanges()).thenAnswer(
            (_) async => {
              'clients': const SyncChanges(
                created: [{'id': 'c-local-1', 'name': 'Local Client'}],
                updated: [],
                deleted: [],
              ),
            },
          );

      // Queue items
      final queueItem = _queueItem(
        targetTable: 'workout_sessions',
        recordId: 's-1',
        operation: SyncOperation.update,
        data: {'id': 's-1', 'name': 'Updated Session'},
      );
      when(() => mockQueue.getAllPending())
          .thenAnswer((_) async => [queueItem]);

      when(() => mockRemote.push(any())).thenAnswer(
            (_) async => {'timestamp': 3000},
          );
      when(() => mockLocal.markAllSynced()).thenAnswer((_) async {});
      when(() => mockQueue.remove(any())).thenAnswer((_) async {});
      when(() => mockLocal.cleanSyncedDeletions()).thenAnswer((_) async {});
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 3000),
          );

      final result = await syncEngine.sync();

      expect(result.isSuccess, true);
      expect(result.pushedCount, 2); // 1 queue item + 1 local change entry
      verify(() => mockRemote.push(any())).called(1);
    });

    test('queueMutation adds item and triggers sync when online', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockQueue.add(any())).thenAnswer((_) async {});
      // The sync triggered by queueMutation will be called later; stub it
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});

      await syncEngine.queueMutation(
        tableName: 'clients',
        recordId: 'client-2',
        operation: SyncOperation.create,
        data: {'name': 'Another Client'},
      );

      verify(() => mockQueue.add(any())).called(1);
      // After a 1-second debounce, sync should be called
      await Future.delayed(const Duration(milliseconds: 1100));
      verify(() => mockRemote.pull(any())).called(1);
    });

    test('queueMutation emits pending status when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockQueue.add(any())).thenAnswer((_) async {});

      await syncEngine.queueMutation(
        tableName: 'clients',
        recordId: 'client-3',
        operation: SyncOperation.create,
        data: {'name': 'Offline Client'},
      );

      // Should emit pending status since we're offline
      expect(syncEngine.currentStatus, SyncUiStatus.pending);
    });
  });

  group('SyncEngine — error handling', () {
    test('sync() returns failure and emits error on push exception', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending())
          .thenAnswer((_) async => [_queueItem()]);
      when(() => mockRemote.push(any())).thenThrow(Exception('Server error'));

      final result = await syncEngine.sync();

      expect(result.isSuccess, false);
      expect(result.error, contains('Server error'));
      expect(syncEngine.currentStatus, SyncUiStatus.error);
    });

    test('sync() returns failure and emits error on pull exception', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges())
          .thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000))
          .thenThrow(Exception('Network error'));

      final result = await syncEngine.sync();

      expect(result.isSuccess, false);
      expect(result.error, contains('Network error'));
      expect(syncEngine.currentStatus, SyncUiStatus.error);
    });
  });

  group('SyncEngine — initial sync', () {
    test('initialSync pulls all records from the beginning', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockRemote.pull(0)).thenAnswer(
            (_) async => const SyncPayload(
              changes: {
                'clients': SyncChanges(
                  created: [
                    {'id': 'c-1', 'name': 'Client 1'},
                    {'id': 'c-2', 'name': 'Client 2'},
                  ],
                ),
              },
              timestamp: 5000,
            ),
          );
      when(() => mockLocal.upsertRecord(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.setLastPulledAt(any()))
          .thenAnswer((_) async {});

      final result = await syncEngine.initialSync();

      expect(result.isSuccess, true);
      expect(result.pulledCount, 2);
      verify(() => mockLocal.upsertRecord('clients', any())).called(2);
      verify(() => mockLocal.setLastPulledAt(5000)).called(1);
    });

    test('initialSync skips when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final result = await syncEngine.initialSync();

      expect(result.isSuccess, false);
      expect(result.error, contains('offline'));
      verifyNever(() => mockRemote.pull(any()));
    });
  });
}
