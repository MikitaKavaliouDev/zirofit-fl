import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ExternalLink {
  final String id;
  final String profileId;
  final String linkUrl;
  final String label;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ExternalLink({
    required this.id,
    required this.profileId,
    required this.linkUrl,
    required this.label,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ExternalLink.fromJson(Map<String, dynamic> json) => ExternalLink(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        linkUrl: json['link_url'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'link_url': linkUrl,
        'label': label,
        if (description != null) 'description': description,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  ExternalLink copyWith({
    String? id,
    String? profileId,
    String? linkUrl,
    String? label,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ExternalLink(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      linkUrl: linkUrl ?? this.linkUrl,
      label: label ?? this.label,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() =>
      'ExternalLink(id: $id, profileId: $profileId, linkUrl: $linkUrl, '
      'label: $label, description: $description, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalLink &&
          id == other.id &&
          profileId == other.profileId &&
          linkUrl == other.linkUrl &&
          label == other.label &&
          description == other.description &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        linkUrl,
        label,
        description,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
