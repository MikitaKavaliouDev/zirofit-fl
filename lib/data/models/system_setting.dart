import 'package:zirofit_fl/core/utils/json_helpers.dart';

class SystemSetting {
  final String key;
  final String value;
  final String? description;
  final DateTime updatedAt;

  const SystemSetting({
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) =>
      SystemSetting(
        key: json['key'] as String,
        value: json['value'] as String,
        description: json['description'] as String?,
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'description': description,
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'SystemSetting(key: $key, value: $value, '
      'description: $description, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSetting &&
          key == other.key &&
          value == other.value &&
          description == other.description &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(key, value, description, updatedAt);
}
