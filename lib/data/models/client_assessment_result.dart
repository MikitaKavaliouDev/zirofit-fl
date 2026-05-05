import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientAssessmentResult {
  final String id;
  final String clientId;
  final String assessmentId;
  final String? assessmentName;
  final double value;
  final String unit;
  final String? notes;
  final DateTime assessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientAssessmentResult({
    required this.id,
    required this.clientId,
    required this.assessmentId,
    this.assessmentName,
    required this.value,
    required this.unit,
    this.notes,
    required this.assessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientAssessmentResult.fromJson(Map<String, dynamic> json) =>
      ClientAssessmentResult(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        assessmentId: json['assessment_id'] as String,
        assessmentName: json['assessment_name'] as String?,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        notes: json['notes'] as String?,
        assessedAt: dateTimeFromJson(json['assessed_at'] as int),
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'assessment_id': assessmentId,
        'assessment_name': assessmentName,
        'value': value,
        'unit': unit,
        'notes': notes,
        'assessed_at': dateTimeToJson(assessedAt),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'ClientAssessmentResult(id: $id, clientId: $clientId, '
      'assessmentId: $assessmentId, assessmentName: $assessmentName, '
      'value: $value, unit: $unit, notes: $notes, '
      'assessedAt: $assessedAt, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAssessmentResult &&
          id == other.id &&
          clientId == other.clientId &&
          assessmentId == other.assessmentId &&
          assessmentName == other.assessmentName &&
          value == other.value &&
          unit == other.unit &&
          notes == other.notes &&
          assessedAt == other.assessedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        assessmentId,
        assessmentName,
        value,
        unit,
        notes,
        assessedAt,
        createdAt,
        updatedAt,
      );
}
