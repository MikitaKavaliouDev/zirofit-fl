import 'package:zirofit_fl/core/utils/json_helpers.dart';

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
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) =>
      CheckIn(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        date: dateTimeFromJson(json['date'] as int),
        status: (json['status'] as String?) ?? 'SUBMITTED',
        weight: (json['weight'] as num?)?.toDouble(),
        waistCm: (json['waist_cm'] as num?)?.toDouble(),
        sleepHours:
            (json['sleep_hours'] as num?)?.toDouble(),
        energyLevel: json['energy_level'] as int?,
        stressLevel: json['stress_level'] as int?,
        hungerLevel: json['hunger_level'] as int?,
        digestionLevel: json['digestion_level'] as int?,
        nutritionCompliance:
            json['nutrition_compliance'] as String?,
        clientNotes: json['client_notes'] as String?,
        trainerResponse: json['trainer_response'] as String?,
        reviewedAt: dateTimeFromJsonOrNull(
            json['reviewed_at'] as int?),
        reviewedByUserId:
            json['reviewed_by_user_id'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
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
