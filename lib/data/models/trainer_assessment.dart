import 'package:zirofit_fl/core/utils/json_helpers.dart';

class TrainerAssessment {
  final String id;
  final String name;
  final String? description;
  final String unit;
  final String? trainerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainerAssessment({
    required this.id,
    required this.name,
    this.description,
    required this.unit,
    this.trainerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerAssessment.fromJson(Map<String, dynamic> json) =>
      TrainerAssessment(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        unit: json['unit'] as String,
        trainerId: json['trainer_id'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'unit': unit,
        'trainer_id': trainerId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  TrainerAssessment copyWith({
    String? id,
    String? name,
    String? description,
    String? unit,
    String? trainerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerAssessment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      trainerId: trainerId ?? this.trainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TrainerAssessment(id: $id, name: $name, '
      'description: $description, unit: $unit, '
      'trainerId: $trainerId, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerAssessment &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          unit == other.unit &&
          trainerId == other.trainerId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        unit,
        trainerId,
        createdAt,
        updatedAt,
      );
}
