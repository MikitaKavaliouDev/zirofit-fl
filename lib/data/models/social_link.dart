import 'package:zirofit_fl/core/utils/json_helpers.dart';

class SocialLink {
  final String id;
  final String profileId;
  final String platform;
  final String username;
  final String profileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SocialLink({
    required this.id,
    required this.profileId,
    required this.platform,
    required this.username,
    required this.profileUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        platform: json['platform'] as String,
        username: json['username'] as String,
        profileUrl: json['profile_url'] as String,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'platform': platform,
        'username': username,
        'profile_url': profileUrl,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'SocialLink(id: $id, profileId: $profileId, platform: $platform, '
      'username: $username, profileUrl: $profileUrl, '
      'createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialLink &&
          id == other.id &&
          profileId == other.profileId &&
          platform == other.platform &&
          username == other.username &&
          profileUrl == other.profileUrl &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        platform,
        username,
        profileUrl,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
