/// Enum representing weight measurement units.
///
/// Wire values: `"KG"`, `"LB"`
enum WeightUnit {
  kg,
  lb;

  factory WeightUnit.fromJson(String value) =>
      WeightUnit.values.firstWhere(
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
