// JSON serialization helpers for all data models.
//
// Conventions:
// - DateTime ↔ int (Unix ms) on the wire
// - Lists: wire omits empty arrays → Dart gets []

/// Converts a [DateTime] to a Unix millisecond timestamp (or null).
int? dateTimeToJson(DateTime? dt) => dt?.millisecondsSinceEpoch;

/// Converts a Unix millisecond timestamp to [DateTime].
DateTime dateTimeFromJson(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms);

/// Converts a nullable Unix millisecond timestamp to nullable [DateTime].
DateTime? dateTimeFromJsonOrNull(int? ms) =>
    ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

/// Safely extracts a nested [Map<String, dynamic>] from JSON.
Map<String, dynamic>? mapFromJson(Map<String, dynamic>? json, String key) =>
    json?[key] as Map<String, dynamic>?;

/// Safely casts a JSON list to a typed Dart list.
List<T> listFromJson<T>(List? json, T Function(dynamic) fromJson) =>
    (json ?? []).map(fromJson).toList();
