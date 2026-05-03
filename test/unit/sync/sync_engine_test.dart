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

class MockSyncRemoteSource extends Mock implements SyncRemoteSource {}
class MockSyncLocalSource extends Mock implements SyncLocalSource {}
class MockSyncQueue extends Mock implements sq.SyncQueue {}
class MockConnectivityManager extends Mock implements ConnectivityManager {}
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late SyncEngine syncEngine;
  late MockSyncRemoteSource mockRemote;
  late MockSyncLocalSource mockLocal;
  late MockSyncQueue mockQueue;
  late MockConnectivityManager mockConnectivity;
  late MockAppDatabase mockDb;

  setUp(() {
    mockRemote = MockSyncRemoteSource();
    mockLocal = MockSyncLocalSource();
    mockQueue = MockSyncQueue();
    mockConnectivity = MockConnectivityManager();
    mockDb = MockAppDatabase();

    // Mocktail requires fallback values for types used with any()
    registerFallbackValue(sq.SyncQueueItem(
      targetTable: 'clients',
      recordId: 'fallback',
      operation: SyncOperation.create,
      data: {},
    ));

    // Stub connectivity stream to prevent NullError in constructor
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());

    syncEngine = SyncEngine(
      remoteSource: mockRemote,
      localSource: mockLocal,
      queue: mockQueue,
      connectivity: mockConnectivity,
      db: mockDb,
    );
  });

  group('SyncEngine', () {
    test('initial status is synced', () {
      expect(syncEngine.currentStatus, SyncUiStatus.synced);
    });

    test('sync() skips when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final result = await syncEngine.sync();
      expect(result.isSuccess, false);
      expect(result.error, contains('offline'));
      verifyNever(() => mockRemote.pull(any()));
    });

    test('sync() performs pull when online with no pending changes', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges()).thenAnswer((_) async => null);
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => []);
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );
      when(() => mockLocal.setLastPulledAt(any())).thenAnswer((_) async {});

      final result = await syncEngine.sync();
      expect(result.isSuccess, true);
      verify(() => mockRemote.pull(any())).called(1);
      verify(() => mockLocal.setLastPulledAt(any())).called(1);
    });

    test('sync() pushes pending mutations before pull', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockLocal.collectPendingChanges()).thenAnswer((_) async => null);

      final queueItem = sq.SyncQueueItem(
        targetTable: 'clients',
        recordId: 'client-1',
        operation: SyncOperation.create,
        data: {'name': 'New Client'},
      );
      when(() => mockQueue.getAllPending()).thenAnswer((_) async => [queueItem]);
      when(() => mockRemote.push(any())).thenAnswer(
            (_) async => {'data': {'timestamp': 2000}},
          );
      when(() => mockLocal.markAllSynced()).thenAnswer((_) async {});
      when(() => mockQueue.remove(any())).thenAnswer((_) async {});
      when(() => mockLocal.cleanSyncedDeletions()).thenAnswer((_) async {});
      when(() => mockLocal.setLastPulledAt(any())).thenAnswer((_) async {});
      when(() => mockLocal.getLastPulledAt()).thenAnswer((_) async => 1000);
      when(() => mockRemote.pull(1000)).thenAnswer(
            (_) async => const SyncPayload(timestamp: 2000),
          );

      final result = await syncEngine.sync();
      expect(result.isSuccess, true);
      verify(() => mockRemote.push(any())).called(1);
      verify(() => mockRemote.pull(any())).called(1);
    });

    test('queueMutation adds to queue', () async {
      when(() => mockQueue.add(any())).thenAnswer((_) async {});
      when(() => mockConnectivity.isOnline).thenReturn(false);

      await syncEngine.queueMutation(
        tableName: 'clients',
        recordId: 'client-1',
        operation: SyncOperation.create,
        data: {'name': 'New Client'},
      );
      verify(() => mockQueue.add(any())).called(1);
    });
  });
}
