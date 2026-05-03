import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Location {
  final String id;
  final String profileId;
  final String address;
  final String normalizedAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Location({
    required this.id,
    required this.profileId,
    required this.address,
    required this.normalizedAddress,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        address: json['address'] as String,
        normalizedAddress: json['normalized_address'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'address': address,
        'normalized_address': normalizedAddress,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Location(id: $id, profileId: $profileId, address: $address, '
      'normalizedAddress: $normalizedAddress, latitude: $latitude, '
      'longitude: $longitude, createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          id == other.id &&
          profileId == other.profileId &&
          address == other.address &&
          normalizedAddress == other.normalizedAddress &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        address,
        normalizedAddress,
        latitude,
        longitude,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
