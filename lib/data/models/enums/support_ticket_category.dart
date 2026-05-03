/// Enum representing the category of a support ticket.
///
/// Wire values: `"BUG_REPORT"`, `"FEATURE_REQUEST"`, `"GENERAL_SUPPORT"`
enum SupportTicketCategory {
  bugReport,
  featureRequest,
  generalSupport;

  factory SupportTicketCategory.fromJson(String value) =>
      SupportTicketCategory.values.firstWhere(
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
