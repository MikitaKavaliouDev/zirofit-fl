import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ExternalLink {
  final String id;
  final String profileId;
  final String linkUrl;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ExternalLink({
    required this.id,
    required this.profileId,
    required this.linkUrl,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ExternalLink.fromJson(Map<String, dynamic> json) => ExternalLink(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        linkUrl: json['link_url'] as String,
        label: json['label'] as String,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'link_url': linkUrl,
        'label': label,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'ExternalLink(id: $id, profileId: $profileId, linkUrl: $linkUrl, '
      'label: $label, createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalLink &&
          id == other.id &&
          profileId == other.profileId &&
          linkUrl == other.linkUrl &&
          label == other.label &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        linkUrl,
        label,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
