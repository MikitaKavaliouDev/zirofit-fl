/// Enum representing the type of a workout step.
///
/// Wire values: `"EXERCISE"`, `"REST"`
enum StepType {
  exercise,
  rest;

  factory StepType.fromJson(String value) =>
      StepType.values.firstWhere(
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
