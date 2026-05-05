import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// A single body-part circumference measurement.
///
/// Stored locally via SharedPreferences since the backend does not expose
/// a dedicated CRUD endpoint for body-part measurements.
class BodyMeasurement {
  final String id;
  final String clientId;
  final String type; // e.g. 'neck', 'shoulders', 'chest', 'left_bicep'
  final String typeName; // human-readable display name
  final double valueCm;
  final String unit; // default 'cm'
  final DateTime measuredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BodyMeasurement({
    required this.id,
    required this.clientId,
    required this.type,
    required this.typeName,
    required this.valueCm,
    this.unit = 'cm',
    required this.measuredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        type: json['type'] as String,
        typeName: json['type_name'] as String,
        valueCm: (json['value_cm'] as num).toDouble(),
        unit: (json['unit'] as String?) ?? 'cm',
        measuredAt: dateTimeFromJson(json['measured_at'] as int),
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'type': type,
        'type_name': typeName,
        'value_cm': valueCm,
        'unit': unit,
        'measured_at': dateTimeToJson(measuredAt),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  BodyMeasurement copyWith({
    String? id,
    String? clientId,
    String? type,
    String? typeName,
    double? valueCm,
    String? unit,
    DateTime? measuredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      typeName: typeName ?? this.typeName,
      valueCm: valueCm ?? this.valueCm,
      unit: unit ?? this.unit,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'BodyMeasurement(id: $id, clientId: $clientId, type: $type, '
      'typeName: $typeName, valueCm: $valueCm, unit: $unit, '
      'measuredAt: $measuredAt, createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurement &&
          id == other.id &&
          clientId == other.clientId &&
          type == other.type &&
          typeName == other.typeName &&
          valueCm == other.valueCm &&
          unit == other.unit &&
          measuredAt == other.measuredAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        type,
        typeName,
        valueCm,
        unit,
        measuredAt,
        createdAt,
        updatedAt,
      );
}

/// Describes a known measurement type.
///
/// [category] can be 'core' (waist, hips) or 'bodyPart' (biceps, thighs, etc.).
class MeasurementType {
  final String id;
  final String name;
  final String category;
  final String? icon;
  final String unit;

  const MeasurementType({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.unit = 'cm',
  });

  factory MeasurementType.fromJson(Map<String, dynamic> json) =>
      MeasurementType(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        icon: json['icon'] as String?,
        unit: (json['unit'] as String?) ?? 'cm',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'icon': icon,
        'unit': unit,
      };

  /// Default set of body measurement types.
  static const List<MeasurementType> defaults = [
    MeasurementType(
      id: 'neck',
      name: 'Neck',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'shoulders',
      name: 'Shoulders',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'chest',
      name: 'Chest',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'left_bicep',
      name: 'Left Bicep',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'right_bicep',
      name: 'Right Bicep',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'left_forearm',
      name: 'Left Forearm',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'right_forearm',
      name: 'Right Forearm',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'waist',
      name: 'Waist',
      category: 'core',
    ),
    MeasurementType(
      id: 'hips',
      name: 'Hips',
      category: 'core',
    ),
    MeasurementType(
      id: 'left_thigh',
      name: 'Left Thigh',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'right_thigh',
      name: 'Right Thigh',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'left_calf',
      name: 'Left Calf',
      category: 'bodyPart',
    ),
    MeasurementType(
      id: 'right_calf',
      name: 'Right Calf',
      category: 'bodyPart',
    ),
  ];

  @override
  String toString() =>
      'MeasurementType(id: $id, name: $name, category: $category, '
      'icon: $icon, unit: $unit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          icon == other.icon &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(id, name, category, icon, unit);
}
