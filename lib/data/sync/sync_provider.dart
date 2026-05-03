import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/network/api_client.dart';
import 'connectivity_manager.dart';
import 'sync_engine.dart';
import 'sync_local_source.dart';
import 'sync_models.dart';
import 'sync_queue.dart';
import 'sync_remote_source.dart';

/// Provider for the SyncRemoteSource (uses the shared authenticated ApiClient).
final syncRemoteSourceProvider =
    Provider<SyncRemoteSource>((ref) {
  return SyncRemoteSource(ApiClient.instance.dio);
});

/// Provider for the SyncLocalSource.
final syncLocalSourceProvider =
    Provider<SyncLocalSource>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncLocalSource(db);
});

/// Provider for the SyncQueue.
final syncQueueProvider = Provider<SyncQueue>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncQueue(db);
});

/// Provider for the ConnectivityManager.
final connectivityManagerProvider =
    Provider<ConnectivityManager>((ref) {
  final manager = ConnectivityManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for the SyncEngine.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final remoteSource = ref.watch(syncRemoteSourceProvider);
  final localSource = ref.watch(syncLocalSourceProvider);
  final queue = ref.watch(syncQueueProvider);
  final connectivity = ref.watch(connectivityManagerProvider);
  final db = ref.watch(databaseProvider);

  final engine = SyncEngine(
    remoteSource: remoteSource,
    localSource: localSource,
    queue: queue,
    connectivity: connectivity,
    db: db,
  );

  ref.onDispose(() => engine.dispose());

  // Initialize connectivity monitoring
  connectivity.initialize();

  return engine;
});

/// Stream provider that exposes the current sync status.
final syncStatusProvider =
    StreamProvider<SyncUiStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.statusStream;
});
