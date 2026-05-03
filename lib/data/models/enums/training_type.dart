/// Enum representing the type of training session.
///
/// Wire values: `"IN_PERSON"`, `"ONLINE"`
enum TrainingType {
  inPerson,
  online;

  factory TrainingType.fromJson(String value) =>
      TrainingType.values.firstWhere(
        (e) => e.name == _toDartName(value),
      );

  String toJson() => _toApiName(name);
}

String _toDartName(String api) {
  final parts = api.split('_');
  return parts[0].toLowerCase() +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase()).join();
}

String _toApiName(String dart) {
  return dart.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)}').toUpperCase();
}
