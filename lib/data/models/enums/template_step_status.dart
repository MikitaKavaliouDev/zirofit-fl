/// Enum representing the completion status of a template in the active program.
///
/// Wire values: `"COMPLETED"`, `"NEXT"`, `"PENDING"`
enum TemplateStepStatus {
  completed,
  next,
  pending;

  factory TemplateStepStatus.fromJson(String value) =>
      TemplateStepStatus.values.firstWhere(
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
