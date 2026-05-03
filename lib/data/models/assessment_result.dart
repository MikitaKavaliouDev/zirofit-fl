import 'package:zirofit_fl/core/utils/json_helpers.dart';

class AssessmentResult {
  final String id;
  final String assessmentId;
  final String clientId;
  final double value;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const AssessmentResult({
    required this.id,
    required this.assessmentId,
    required this.clientId,
    required this.value,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory AssessmentResult.fromJson(
          Map<String, dynamic> json) =>
      AssessmentResult(
        id: json['id'] as String,
        assessmentId: json['assessment_id'] as String,
        clientId: json['client_id'] as String,
        value: (json['value'] as num).toDouble(),
        date: dateTimeFromJson(json['date'] as int),
        notes: json['notes'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessment_id': assessmentId,
        'client_id': clientId,
        'value': value,
        'date': dateTimeToJson(date),
        'notes': notes,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'AssessmentResult(id: $id, assessmentId: $assessmentId, '
      'clientId: $clientId, value: $value, date: $date, '
      'notes: $notes, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentResult &&
          id == other.id &&
          assessmentId == other.assessmentId &&
          clientId == other.clientId &&
          value == other.value &&
          date == other.date &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        assessmentId,
        clientId,
        value,
        date,
        notes,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
