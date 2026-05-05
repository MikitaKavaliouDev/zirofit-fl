/// Model representing a trainer as returned from search endpoints.
///
/// This is distinct from [Profile] because it is optimised for
/// discovery-oriented payloads that include distance, rating aggregates,
/// and a curated list of services / benefits rather than the full
/// trainer profile schema.
class TrainerSearchResult {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final String? location;
  final double? rating;
  final int? reviewCount;
  final double? distance; // km
  final List<String> specialties;
  final List<String>? services;
  final List<String>? benefits;
  final bool isConnected;

  const TrainerSearchResult({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.location,
    this.rating,
    this.reviewCount,
    this.distance,
    this.specialties = const [],
    this.services,
    this.benefits,
    this.isConnected = false,
  });

  factory TrainerSearchResult.fromJson(Map<String, dynamic> json) =>
      TrainerSearchResult(
        id: json['id'] as String,
        name: (json['name'] as String?) ??
            (json['about_me'] as String?) ??
            '',
        username: json['username'] as String?,
        avatarUrl: (json['avatar_url'] as String?) ??
            (json['profile_photo_path'] as String?),
        bannerUrl: (json['banner_url'] as String?) ??
            (json['banner_image_path'] as String?),
        bio: (json['bio'] as String?) ?? (json['about_me'] as String?),
        location: json['location'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ??
            (json['average_rating'] as num?)?.toDouble(),
        reviewCount:
            (json['review_count'] as int?) ?? (json['reviews_count'] as int?),
        distance: (json['distance'] as num?)?.toDouble(),
        specialties: (json['specialties'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        services: (json['services'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        benefits: (json['benefits'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        isConnected: (json['is_connected'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'bio': bio,
        'location': location,
        'rating': rating,
        'review_count': reviewCount,
        'distance': distance,
        'specialties': specialties,
        'services': services,
        'benefits': benefits,
        'is_connected': isConnected,
      };

  @override
  String toString() =>
      'TrainerSearchResult(id: $id, name: $name, username: $username, '
      'avatarUrl: $avatarUrl, bannerUrl: $bannerUrl, bio: $bio, '
      'location: $location, rating: $rating, reviewCount: $reviewCount, '
      'distance: $distance, specialties: $specialties, services: $services, '
      'benefits: $benefits, isConnected: $isConnected)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerSearchResult &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          avatarUrl == other.avatarUrl &&
          bannerUrl == other.bannerUrl &&
          bio == other.bio &&
          location == other.location &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          distance == other.distance &&
          specialties == other.specialties &&
          services == other.services &&
          benefits == other.benefits &&
          isConnected == other.isConnected;

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        username,
        avatarUrl,
        bannerUrl,
        bio,
        location,
        rating,
        reviewCount,
        distance,
        specialties,
        services,
        benefits,
        isConnected,
      ]);
}
