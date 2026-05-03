/// Enum representing user subscription tiers.
///
/// Wire values: `"STARTER"`, `"PRO"`, `"ELITE"`
enum UserTier {
  starter,
  pro,
  elite;

  factory UserTier.fromJson(String value) =>
      UserTier.values.firstWhere(
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
