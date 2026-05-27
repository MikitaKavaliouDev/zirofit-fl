import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// Data model for the trainer profile returned by the invitation endpoint.
///
/// This is intentionally distinct from [Profile] because the invitation API
/// returns a lightweight subset of trainer info: name, avatar, banner,
/// location, specialties, and bio.
class TrainerInvitationData {
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? location;
  final List<String> specialties;
  final String? bio;

  const TrainerInvitationData({
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    this.location,
    this.specialties = const [],
    this.bio,
  });

  factory TrainerInvitationData.fromJson(Map<String, dynamic> json) {
    return TrainerInvitationData(
      name: readString(json, 'name', 'name'),
      avatarUrl: readStringOrNull(json, 'avatar_url', 'avatarUrl'),
      bannerUrl: readStringOrNull(json, 'banner_url', 'bannerUrl'),
      location: readStringOrNull(json, 'location', 'location'),
      specialties: (json['specialties'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      bio: readStringOrNull(json, 'bio', 'bio'),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (location != null) 'location': location,
        'specialties': specialties,
        if (bio != null) 'bio': bio,
      };

  @override
  String toString() =>
      'TrainerInvitationData(name: $name, location: $location, '
      'specialties: $specialties, bio: $bio)';
}
