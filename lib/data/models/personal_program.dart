import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/personal_template.dart';

class PersonalProgram {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? trainerId;
  final String source;
  final List<PersonalTemplate> templates;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalProgram({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.trainerId,
    this.source = 'self',
    this.templates = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalProgram.fromJson(Map<String, dynamic> json) =>
      PersonalProgram(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        trainerId: readStringOrNull(json, 'trainer_id', 'trainerId'),
        source: (json['source'] as String?) ?? 'self',
        templates: (json['templates'] as List<dynamic>?)
                ?.map(
                    (e) => PersonalTemplate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'trainer_id': trainerId,
        'source': source,
        'templates': templates.map((t) => t.toJson()).toList(),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'PersonalProgram(id: $id, name: $name, '
      'description: $description, category: $category, '
      'trainerId: $trainerId, source: $source, '
      'templates: $templates, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalProgram &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          trainerId == other.trainerId &&
          source == other.source &&
          templates == other.templates &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        category,
        trainerId,
        source,
        Object.hashAll(templates),
        createdAt,
        updatedAt,
      );
}
