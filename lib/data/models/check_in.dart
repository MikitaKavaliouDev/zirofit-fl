import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'client_model.dart';

class CheckIn {
  final String id;
  final String clientId;
  final DateTime date;
  final String status;
  final double? weight;
  final double? waistCm;
  final double? sleepHours;
  final int? energyLevel;
  final int? stressLevel;
  final int? hungerLevel;
  final int? digestionLevel;
  final String? nutritionCompliance;
  final String? clientNotes;
  final String? trainerResponse;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Client? client;

  const CheckIn({
    required this.id,
    required this.clientId,
    required this.date,
    this.status = 'SUBMITTED',
    this.weight,
    this.waistCm,
    this.sleepHours,
    this.energyLevel,
    this.stressLevel,
    this.hungerLevel,
    this.digestionLevel,
    this.nutritionCompliance,
    this.clientNotes,
    this.trainerResponse,
    this.reviewedAt,
    this.reviewedByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.client,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: readString(json, 'id', 'id'),
        clientId: readString(json, 'client_id', 'clientId'),
        date: readDateTime(json, 'date', 'date'),
        status: readString(json, 'status', 'status'),
        weight: (json['weight'] as num?)?.toDouble(),
        waistCm: (json['waist_cm'] ?? json['waistCm'] as num?)?.toDouble(),
        sleepHours: (json['sleep_hours'] ?? json['sleepHours'] as num?)?.toDouble(),
        energyLevel: (json['energy_level'] ?? json['energyLevel']) as int?,
        stressLevel: (json['stress_level'] ?? json['stressLevel']) as int?,
        hungerLevel: (json['hunger_level'] ?? json['hungerLevel']) as int?,
        digestionLevel: (json['digestion_level'] ?? json['digestionLevel']) as int?,
        nutritionCompliance: readStringOrNull(json, 'nutrition_compliance', 'nutritionCompliance'),
        clientNotes: readStringOrNull(json, 'client_notes', 'clientNotes'),
        trainerResponse: readStringOrNull(json, 'trainer_response', 'trainerResponse'),
        reviewedAt: readDateTimeOrNull(json, 'reviewed_at', 'reviewedAt'),
        reviewedByUserId: readStringOrNull(json, 'reviewed_by_user_id', 'reviewedByUserId'),
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        client: json['client'] != null ? Client.fromJson(json['client'] as Map<String, dynamic>) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'date': dateTimeToJson(date),
        'status': status,
        'weight': weight,
        'waist_cm': waistCm,
        'sleep_hours': sleepHours,
        'energy_level': energyLevel,
        'stress_level': stressLevel,
        'hunger_level': hungerLevel,
        'digestion_level': digestionLevel,
        'nutrition_compliance': nutritionCompliance,
        'client_notes': clientNotes,
        'trainer_response': trainerResponse,
        'reviewed_at': dateTimeToJson(reviewedAt),
        'reviewed_by_user_id': reviewedByUserId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'CheckIn(id: $id, clientId: $clientId, date: $date, '
      'status: $status, weight: $weight, waistCm: $waistCm, '
      'sleepHours: $sleepHours, energyLevel: $energyLevel, '
      'stressLevel: $stressLevel, hungerLevel: $hungerLevel, '
      'digestionLevel: $digestionLevel, '
      'nutritionCompliance: $nutritionCompliance, '
      'clientNotes: $clientNotes, '
      'trainerResponse: $trainerResponse, '
      'reviewedAt: $reviewedAt, '
      'reviewedByUserId: $reviewedByUserId, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckIn &&
          id == other.id &&
          clientId == other.clientId &&
          date == other.date &&
          status == other.status &&
          weight == other.weight &&
          waistCm == other.waistCm &&
          sleepHours == other.sleepHours &&
          energyLevel == other.energyLevel &&
          stressLevel == other.stressLevel &&
          hungerLevel == other.hungerLevel &&
          digestionLevel == other.digestionLevel &&
          nutritionCompliance == other.nutritionCompliance &&
          clientNotes == other.clientNotes &&
          trainerResponse == other.trainerResponse &&
          reviewedAt == other.reviewedAt &&
          reviewedByUserId == other.reviewedByUserId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        date,
        status,
        weight,
        waistCm,
        sleepHours,
        energyLevel,
        stressLevel,
        hungerLevel,
        digestionLevel,
        nutritionCompliance,
        clientNotes,
        trainerResponse,
        reviewedAt,
        reviewedByUserId,
        createdAt,
        updatedAt,
      );
}
