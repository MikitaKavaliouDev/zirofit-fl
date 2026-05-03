import 'package:zirofit_fl/core/utils/json_helpers.dart';

class TransformationPhoto {
  final String id;
  final String profileId;
  final String imagePath;
  final String? caption;
  final String? clientName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TransformationPhoto({
    required this.id,
    required this.profileId,
    required this.imagePath,
    this.caption,
    this.clientName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory TransformationPhoto.fromJson(Map<String, dynamic> json) =>
      TransformationPhoto(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        imagePath: json['image_path'] as String,
        caption: json['caption'] as String?,
        clientName: json['client_name'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'image_path': imagePath,
        'caption': caption,
        'client_name': clientName,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'TransformationPhoto(id: $id, profileId: $profileId, '
      'imagePath: $imagePath, caption: $caption, clientName: $clientName, '
      'createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformationPhoto &&
          id == other.id &&
          profileId == other.profileId &&
          imagePath == other.imagePath &&
          caption == other.caption &&
          clientName == other.clientName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        imagePath,
        caption,
        clientName,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
