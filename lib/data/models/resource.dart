import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Resource {
  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Resource({
    required this.id,
    required this.trainerId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) =>
      Resource(
        id: json['id'] as String,
        trainerId: json['trainer_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        fileUrl: json['file_url'] as String,
        fileType: json['file_type'] as String,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_type': fileType,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Resource(id: $id, trainerId: $trainerId, '
      'title: $title, description: $description, '
      'fileUrl: $fileUrl, fileType: $fileType, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          id == other.id &&
          trainerId == other.trainerId &&
          title == other.title &&
          description == other.description &&
          fileUrl == other.fileUrl &&
          fileType == other.fileType &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        trainerId,
        title,
        description,
        fileUrl,
        fileType,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
