/// Represents the changes for a single table in a sync payload.
class SyncChanges {
  final List<Map<String, dynamic>> created;
  final List<Map<String, dynamic>> updated;
  final List<String> deleted;

  const SyncChanges({
    this.created = const [],
    this.updated = const [],
    this.deleted = const [],
  });

  factory SyncChanges.fromJson(Map<String, dynamic> json) => SyncChanges(
        created: (json['created'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        updated: (json['updated'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        deleted: (json['deleted'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'created': created,
        'updated': updated,
        'deleted': deleted,
      };
}

/// The full payload received from a pull or push sync operation.
class SyncPayload {
  final Map<String, SyncChanges> changes;
  final int timestamp;

  const SyncPayload({
    this.changes = const {},
    required this.timestamp,
  });

  factory SyncPayload.fromJson(Map<String, dynamic> json) {
    final changesMap = <String, SyncChanges>{};
    if (json['changes'] != null) {
      (json['changes'] as Map<String, dynamic>).forEach((key, value) {
        changesMap[key] =
            SyncChanges.fromJson(value as Map<String, dynamic>);
      });
    }
    return SyncPayload(
      changes: changesMap,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'changes': changes.map((k, v) => MapEntry(k, v.toJson())),
        'timestamp': timestamp,
      };
}

/// UI-facing status of the sync engine.
enum SyncUiStatus {
  synced,
  syncing,
  pending,
  error,
  offline,
}

/// The type of mutation operation in the sync queue.
enum SyncOperation { create, update, delete }

/// Result of a full sync cycle.
class SyncResult {
  final bool isSuccess;
  final String? error;
  final int pushedCount;
  final int pulledCount;
  final int? timestamp;

  const SyncResult.success({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.timestamp,
  })  : isSuccess = true,
        error = null;

  const SyncResult.failure(this.error)
      : isSuccess = false,
        pushedCount = 0,
        pulledCount = 0,
        timestamp = null;

  static const empty = SyncResult.success();
}

/// Result of a push operation.
class PushResult {
  final int mutationsCount;

  const PushResult({required this.mutationsCount});
  const PushResult.empty() : mutationsCount = 0;
}

/// Result of a pull operation.
class PullResult {
  final int recordsCount;
  final int timestamp;

  const PullResult({required this.recordsCount, required this.timestamp});
}
