import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientMeasurement {
  final String id;
  final String clientId;
  final DateTime measurementDate;
  final double? weightKg;
  final double? bodyFatPercentage;
  final String? notes;
  final List<dynamic>? customMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientMeasurement({
    required this.id,
    required this.clientId,
    required this.measurementDate,
    this.weightKg,
    this.bodyFatPercentage,
    this.notes,
    this.customMetrics,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientMeasurement.fromJson(Map<String, dynamic> json) =>
      ClientMeasurement(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        measurementDate:
            dateTimeFromJson(json['measurement_date'] as int),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        bodyFatPercentage:
            (json['body_fat_percentage'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        customMetrics:
            json['custom_metrics'] as List<dynamic>?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'measurement_date': DateTime(
                measurementDate.year,
                measurementDate.month,
                measurementDate.day)
            .millisecondsSinceEpoch,
        'weight_kg': weightKg,
        'body_fat_percentage': bodyFatPercentage,
        'notes': notes,
        'custom_metrics': customMetrics,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'ClientMeasurement(id: $id, clientId: $clientId, '
      'measurementDate: $measurementDate, weightKg: $weightKg, '
      'bodyFatPercentage: $bodyFatPercentage, notes: $notes, '
      'customMetrics: $customMetrics, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientMeasurement &&
          id == other.id &&
          clientId == other.clientId &&
          measurementDate == other.measurementDate &&
          weightKg == other.weightKg &&
          bodyFatPercentage == other.bodyFatPercentage &&
          notes == other.notes &&
          customMetrics == other.customMetrics &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        measurementDate,
        weightKg,
        bodyFatPercentage,
        notes,
        customMetrics,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
