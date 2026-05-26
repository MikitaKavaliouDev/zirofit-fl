import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart' hide SyncQueueItem;
import 'connectivity_manager.dart';
import 'sync_local_source.dart';
import 'sync_models.dart';
import 'sync_queue.dart';
import 'sync_remote_source.dart';

/// Orchestrates the full sync cycle: push pending mutations → pull latest data.
///
/// Uses a push-before-pull strategy to ensure local changes are sent to the
/// server before fetching updates, avoiding conflicts and ensuring
/// server-generated fields (IDs, timestamps) are reconciled.
class SyncEngine {
  final SyncRemoteSource _remoteSource;
  final SyncLocalSource _localSource;
  final SyncQueue _queue;
  final ConnectivityManager _connectivity;
  final AppDatabase _db;

  /// Maximum retry attempts for a queue item before auto-discard.
  static const int maxRetries = 5;

  final StreamController<SyncUiStatus> _statusController =
      StreamController<SyncUiStatus>.broadcast();
  Stream<SyncUiStatus> get statusStream => _statusController.stream;
  SyncUiStatus _currentStatus = SyncUiStatus.synced;
  SyncUiStatus get currentStatus => _currentStatus;

  SyncEngine({
    required SyncRemoteSource remoteSource,
    required SyncLocalSource localSource,
    required SyncQueue queue,
    required ConnectivityManager connectivity,
    required AppDatabase db,
  })  : _remoteSource = remoteSource,
        _localSource = localSource,
        _queue = queue,
        _connectivity = connectivity,
        _db = db {
    _setupConnectivityListener();
  }

  /// Performs a full sync cycle: push pending → pull changes.
  Future<SyncResult> sync() async {
    if (!_connectivity.isOnline) {
      return const SyncResult.failure('Device is offline');
    }

    _emitStatus(SyncUiStatus.syncing);

    try {
      // Step 1: Push pending mutations first
      final pushResult = await _push();

      // Step 2: Pull latest data from server
      final pullResult = await _pull();

      _emitStatus(SyncUiStatus.synced);
      return SyncResult.success(
        pushedCount: pushResult.mutationsCount,
        pulledCount: pullResult.recordsCount,
        timestamp: pullResult.timestamp,
      );
    } catch (e) {
      _emitStatus(SyncUiStatus.error);
      return SyncResult.failure(e.toString());
    }
  }

  /// Push all pending local mutations to the server.
  Future<PushResult> _push() async {
    // Collect pending changes from syncStatus columns
    final pendingChanges = await _localSource.collectPendingChanges();

    // Build the push payload from syncStatus changes
    final changesPayload = <String, Map<String, dynamic>>{};
    if (pendingChanges != null) {
      for (final entry in pendingChanges.entries) {
        changesPayload[entry.key] = entry.value.toJson();
      }
    }

    // Check the SyncQueue for additional pending items
    var queueItems = await _queue.getAllPending();

    // Auto-discard items that have exceeded max retries
    final validItems = <SyncQueueItem>[];
    for (final item in queueItems) {
      if (item.retryCount >= maxRetries) {
        await _queue.remove(item.id);
      } else {
        validItems.add(item);
      }
    }
    queueItems = validItems;

    // If nothing to push, return early
    if (queueItems.isEmpty &&
        (pendingChanges == null || pendingChanges.isEmpty)) {
      return const PushResult.empty();
    }

    for (final item in queueItems) {
      final tableName = item.targetTable;
      changesPayload.putIfAbsent(
        tableName,
        () => {'created': <Map<String, dynamic>>[], 'updated': <Map<String, dynamic>>[], 'deleted': <String>[]},
      );
      switch (item.operation) {
        case SyncOperation.create:
          (changesPayload[tableName]!['created'] as List<Map<String, dynamic>>)
              .add(item.data);
          break;
        case SyncOperation.update:
          (changesPayload[tableName]!['updated'] as List<Map<String, dynamic>>)
              .add(item.data);
          break;
        case SyncOperation.delete:
          (changesPayload[tableName]!['deleted'] as List<String>)
              .add(item.recordId);
          break;
      }
    }

    // Send push to server
    final response = await _remoteSource.push(changesPayload);
    final serverTimestamp = response['timestamp'] as int? ??
        DateTime.now().millisecondsSinceEpoch;

    // Mark all pushed records as synced
    await _localSource.markAllSynced();

    // Process per-item results from the push response.
    // If the response includes an 'errors' map, handle each queue item individually.
    // Items without an error entry are treated as successful.
    final itemErrors = response['errors'] as Map<String, dynamic>? ?? {};
    if (itemErrors.isEmpty) {
      // All items succeeded — remove all from queue
      for (final item in queueItems) {
        await _queue.remove(item.id);
      }
    } else {
      for (final item in queueItems) {
        final error = itemErrors[item.id] as Map<String, dynamic>?;
        if (error == null) {
          // Item succeeded — remove from queue
          await _queue.remove(item.id);
        } else {
          final statusCode = error['status'] as int? ?? 0;
          final errorMessage = error['message'] as String? ?? 'Unknown error';
          if (statusCode == 404) {
            // Orphaned record — discard silently
            await _queue.remove(item.id);
          } else {
            // Other error — increment retry count and store error message
            await _queue.markFailed(item.id, errorMessage);
          }
        }
      }
    }

    // Remove synced soft-deleted records
    await _localSource.cleanSyncedDeletions();

    // Update last pulled at with server timestamp
    await _localSource.setLastPulledAt(serverTimestamp);

    final syncStatusCount = pendingChanges?.values.fold<int>(
          0, (sum, c) => sum + c.created.length + c.updated.length + c.deleted.length) ?? 0;
    return PushResult(
      mutationsCount: queueItems.length + syncStatusCount,
    );
  }

  /// Pull all changes since the last sync timestamp.
  Future<PullResult> _pull() async {
    final lastPulledAt = await _localSource.getLastPulledAt();
    final response = await _remoteSource.pull(lastPulledAt);

    int totalRecords = 0;

    for (final entry in response.changes.entries) {
      final tableName = entry.key;
      final changes = entry.value;

      // Process created records
      for (final record in changes.created) {
        await _applyPullRecord(tableName, record);
        totalRecords++;
      }

      // Process updated records (with conflict resolution)
      for (final record in changes.updated) {
        await _applyPullRecord(tableName, record);
        totalRecords++;
      }

      // Process deleted records (soft delete)
      for (final id in changes.deleted) {
        await _localSource.softDeleteRecord(tableName, id);
        totalRecords++;
      }
    }

    // Save the new timestamp
    await _localSource.setLastPulledAt(response.timestamp);

    return PullResult(recordsCount: totalRecords, timestamp: response.timestamp);
  }

  /// Apply a pulled record with last-write-wins conflict resolution.
  Future<void> _applyPullRecord(
      String tableName, Map<String, dynamic> incoming) async {
    final incomingUpdatedAt = incoming['updated_at'] as int? ??
        incoming['updatedAt'] as int? ??
        0;
    final recordId = incoming['id'] as String;
    if (recordId.isEmpty) return;

    try {
      // Check if record exists locally and has pending changes
      final existing = await _db.customSelect(
        'SELECT "updated_at", "sync_status" FROM "$tableName" WHERE "id" = ?',
        variables: [Variable.withString(recordId)],
      ).get();

      if (existing.isNotEmpty) {
        final row = existing.first.data;
        final localStatus = row['sync_status'] as int? ?? 0;

        // Skip overwrite if local has pending changes (local is newer)
        if (localStatus != 0) {
          // Local has un-pushed changes — keep local version
          return;
        }

        final localUpdatedAt = row['updated_at'] as int? ?? 0;

        // Last-write-wins: skip if local is newer
        if (localUpdatedAt > incomingUpdatedAt) {
          return;
        }
      }

      // Upsert the incoming record
      await _localSource.upsertRecord(tableName, incoming);
    } catch (_) {
      // Table or record might not exist yet; attempt upsert directly
      try {
        await _localSource.upsertRecord(tableName, incoming);
      } catch (_) {
        // Silently skip records for tables that don't exist locally
      }
    }
  }

  /// Queue a local mutation for future push.
  Future<void> queueMutation({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    await _queue.add(SyncQueueItem(
      targetTable: tableName,
      recordId: recordId,
      operation: operation,
      data: data,
    ));

    // If online, try to push immediately (with debounce)
    if (_connectivity.isOnline) {
      Future.delayed(const Duration(seconds: 1), () => sync());
    } else {
      _emitStatus(SyncUiStatus.pending);
    }
  }

  /// Perform initial sync (fresh install — pull everything).
  Future<SyncResult> initialSync() async {
    if (!_connectivity.isOnline) {
      return const SyncResult.failure('Device is offline');
    }

    _emitStatus(SyncUiStatus.syncing);

    try {
      // Pull everything from the beginning of time
      final response = await _remoteSource.pull(0);

      int totalRecords = 0;

      for (final entry in response.changes.entries) {
        final tableName = entry.key;
        final changes = entry.value;

        for (final record in changes.created) {
          await _localSource.upsertRecord(tableName, record);
          totalRecords++;
        }
        // updated and deleted will be empty for lastPulledAt=0
      }

      await _localSource.setLastPulledAt(response.timestamp);
      _emitStatus(SyncUiStatus.synced);

      return SyncResult.success(
        pulledCount: totalRecords,
        timestamp: response.timestamp,
      );
    } catch (e) {
      _emitStatus(SyncUiStatus.error);
      return SyncResult.failure(e.toString());
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        // Grace period before syncing to avoid rapid cycles
        Future.delayed(const Duration(seconds: 2), () {
          if (_connectivity.isOnline) {
            sync();
          }
        });
      } else {
        _emitStatus(SyncUiStatus.offline);
      }
    });
  }

  void _emitStatus(SyncUiStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}
