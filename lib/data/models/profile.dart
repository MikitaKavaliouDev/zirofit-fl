import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/training_type.dart';

class Profile {
  final String id;
  final String userId;
  final String? certifications;
  final String? phone;
  final String? aboutMe;
  final String? philosophy;
  final String? methodology;
  final String? branding;
  final String? bannerImagePath;
  final String? customDomain;
  final bool domainVerified;
  final String? profilePhotoPath;
  final List<String> specialties;
  final List<TrainingType> trainingTypes;
  final String businessCurrency;
  final double? averageRating;
  final int completionPercentage;
  final List<dynamic>? missingFields;
  final bool isVerified;
  final Map<String, dynamic>? availability;
  final double? minServicePrice;
  final String? location;
  final String? locationNormalized;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Profile({
    required this.id,
    required this.userId,
    this.certifications,
    this.phone,
    this.aboutMe,
    this.philosophy,
    this.methodology,
    this.branding,
    this.bannerImagePath,
    this.customDomain,
    this.domainVerified = false,
    this.profilePhotoPath,
    this.specialties = const [],
    this.trainingTypes = const [],
    this.businessCurrency = 'PLN',
    this.averageRating,
    this.completionPercentage = 0,
    this.missingFields,
    this.isVerified = false,
    this.availability,
    this.minServicePrice,
    this.location,
    this.locationNormalized,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        certifications: json['certifications'] as String?,
        phone: json['phone'] as String?,
        aboutMe: json['about_me'] as String?,
        philosophy: json['philosophy'] as String?,
        methodology: json['methodology'] as String?,
        branding: json['branding'] as String?,
        bannerImagePath: json['banner_image_path'] as String?,
        customDomain: json['custom_domain'] as String?,
        domainVerified: (json['domain_verified'] as bool?) ?? false,
        profilePhotoPath: json['profile_photo_path'] as String?,
        specialties: (json['specialties'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        trainingTypes: (json['training_types'] as List<dynamic>?)
                ?.map((e) => TrainingType.fromJson(e as String))
                .toList() ??
            const [],
        businessCurrency:
            (json['business_currency'] as String?) ?? 'PLN',
        averageRating:
            (json['average_rating'] as num?)?.toDouble(),
        completionPercentage:
            (json['completion_percentage'] as int?) ?? 0,
        missingFields:
            json['missing_fields'] as List<dynamic>?,
        isVerified: (json['is_verified'] as bool?) ?? false,
        availability:
            json['availability'] as Map<String, dynamic>?,
        minServicePrice:
            (json['min_service_price'] as num?)?.toDouble(),
        location: json['location'] as String?,
        locationNormalized: json['location_normalized'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'certifications': certifications,
        'phone': phone,
        'about_me': aboutMe,
        'philosophy': philosophy,
        'methodology': methodology,
        'branding': branding,
        'banner_image_path': bannerImagePath,
        'custom_domain': customDomain,
        'domain_verified': domainVerified,
        'profile_photo_path': profilePhotoPath,
        'specialties': specialties,
        'training_types':
            trainingTypes.map((e) => e.toJson()).toList(),
        'business_currency': businessCurrency,
        'average_rating': averageRating,
        'completion_percentage': completionPercentage,
        'missing_fields': missingFields,
        'is_verified': isVerified,
        'availability': availability,
        'min_service_price': minServicePrice,
        'location': location,
        'location_normalized': locationNormalized,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Profile(id: $id, userId: $userId, certifications: $certifications, '
      'phone: $phone, aboutMe: $aboutMe, philosophy: $philosophy, '
      'methodology: $methodology, branding: $branding, '
      'bannerImagePath: $bannerImagePath, customDomain: $customDomain, '
      'domainVerified: $domainVerified, profilePhotoPath: $profilePhotoPath, '
      'specialties: $specialties, trainingTypes: $trainingTypes, '
      'businessCurrency: $businessCurrency, averageRating: $averageRating, '
      'completionPercentage: $completionPercentage, missingFields: $missingFields, '
      'isVerified: $isVerified, availability: $availability, '
      'minServicePrice: $minServicePrice, location: $location, '
      'locationNormalized: $locationNormalized, latitude: $latitude, '
      'longitude: $longitude, createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          id == other.id &&
          userId == other.userId &&
          certifications == other.certifications &&
          phone == other.phone &&
          aboutMe == other.aboutMe &&
          philosophy == other.philosophy &&
          methodology == other.methodology &&
          branding == other.branding &&
          bannerImagePath == other.bannerImagePath &&
          customDomain == other.customDomain &&
          domainVerified == other.domainVerified &&
          profilePhotoPath == other.profilePhotoPath &&
          specialties == other.specialties &&
          trainingTypes == other.trainingTypes &&
          businessCurrency == other.businessCurrency &&
          averageRating == other.averageRating &&
          completionPercentage == other.completionPercentage &&
          missingFields == other.missingFields &&
          isVerified == other.isVerified &&
          availability == other.availability &&
          minServicePrice == other.minServicePrice &&
          location == other.location &&
          locationNormalized == other.locationNormalized &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        certifications,
        phone,
        aboutMe,
        philosophy,
        methodology,
        branding,
        bannerImagePath,
        customDomain,
        domainVerified,
        profilePhotoPath,
        specialties,
        trainingTypes,
        businessCurrency,
        averageRating,
        completionPercentage,
        missingFields,
        isVerified,
        availability,
        minServicePrice,
        location,
        locationNormalized,
        latitude,
        longitude,
        createdAt,
        updatedAt,
        deletedAt,
      ]);
}
