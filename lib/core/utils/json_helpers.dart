// JSON serialization helpers for all data models.
//
// Conventions:
// - DateTime ↔ int (Unix ms) on the wire
// - Lists: wire omits empty arrays → Dart gets []

/// Converts a [DateTime] to a Unix millisecond timestamp (or null).
int? dateTimeToJson(DateTime? dt) => dt?.millisecondsSinceEpoch;

/// Converts a Unix millisecond timestamp to [DateTime].
DateTime dateTimeFromJson(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

/// Converts a nullable Unix millisecond timestamp to nullable [DateTime].
DateTime? dateTimeFromJsonOrNull(int? ms) =>
    ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

/// Safely extracts a nested [Map<String, dynamic>] from JSON.
Map<String, dynamic>? mapFromJson(Map<String, dynamic>? json, String key) =>
    json?[key] as Map<String, dynamic>?;

/// Safely casts a JSON list to a typed Dart list.
List<T> listFromJson<T>(List? json, T Function(dynamic) fromJson) =>
    (json ?? []).map(fromJson).toList();

// ---------------------------------------------------------------------------
// Flexible key readers — try snake_case first, then camelCase.
// This lets us parse both legacy (snake_case int ms) and new (camelCase ISO
// 8601) backend payloads without breaking existing test fixtures.
// ---------------------------------------------------------------------------

/// Reads a [String] value from [json] by trying [snakeKey] then [camelKey].
String readString(Map<String, dynamic> json, String snakeKey, String camelKey) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is String) return value;
  throw ArgumentError(
    'Expected String for $snakeKey/$camelKey, got ${value?.runtimeType}',
  );
}

/// Reads a nullable [String] value from [json].
String? readStringOrNull(
  Map<String, dynamic> json,
  String snakeKey,
  String camelKey,
) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is String) return value;
  return null;
}

/// Reads a nullable [int] value from [json].
int? readIntOrNull(
  Map<String, dynamic> json,
  String snakeKey,
  String camelKey,
) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is int) return value;
  return null;
}

/// Reads a [bool] value from [json], defaulting to [fallback] when absent.
bool readBool(
  Map<String, dynamic> json,
  String snakeKey,
  String camelKey, {
  bool fallback = false,
}) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is bool) return value;
  return fallback;
}

/// Reads a [DateTime] from [json].
///
/// Supports both:
///   - `int` (Unix ms, legacy snake_case payloads)
///   - `String` (ISO 8601, new camelCase payloads)
DateTime readDateTime(
  Map<String, dynamic> json,
  String snakeKey,
  String camelKey,
) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  throw ArgumentError(
    'Expected int or String for $snakeKey/$camelKey, got ${value?.runtimeType}',
  );
}

/// Reads a nullable [DateTime] from [json].
DateTime? readDateTimeOrNull(
  Map<String, dynamic> json,
  String snakeKey,
  String camelKey,
) {
  final value = json[snakeKey] ?? json[camelKey];
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  return null;
}
