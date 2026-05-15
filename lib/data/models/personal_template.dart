import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';

class PersonalTemplate {
  final String id;
  final String name;
  final String? description;
  final String programId;
  final int order;
  final int exerciseCount;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.programId,
    this.order = 0,
    this.exerciseCount = 0,
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalTemplate.fromJson(Map<String, dynamic> json) =>
      PersonalTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        programId: readString(json, 'program_id', 'programId'),
        order: (json['order'] as int?) ?? 0,
        exerciseCount: () {
          final count = json['_count'];
          if (count is Map) return (count['exercises'] as int?) ?? 0;
          return 0;
        }(),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map(
                    (e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'program_id': programId,
        'order': order,
        '_count': {'exercises': exerciseCount},
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'PersonalTemplate(id: $id, name: $name, '
      'description: $description, programId: $programId, '
      'order: $order, exerciseCount: $exerciseCount, '
      'exercises: $exercises, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalTemplate &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          programId == other.programId &&
          order == other.order &&
          exerciseCount == other.exerciseCount &&
          exercises == other.exercises &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        programId,
        order,
        exerciseCount,
        exercises,
        createdAt,
        updatedAt,
      );
}
