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
        id: readString(json, 'id', 'id'),
        userId: readString(json, 'user_id', 'userId'),
        certifications: readStringOrNull(json, 'certifications', 'certifications'),
        phone: readStringOrNull(json, 'phone', 'phone'),
        aboutMe: readStringOrNull(json, 'about_me', 'aboutMe'),
        philosophy: readStringOrNull(json, 'philosophy', 'philosophy'),
        methodology: readStringOrNull(json, 'methodology', 'methodology'),
        branding: readStringOrNull(json, 'branding', 'branding'),
        bannerImagePath:
            readStringOrNull(json, 'banner_image_path', 'bannerImagePath'),
        customDomain: readStringOrNull(json, 'custom_domain', 'customDomain'),
        domainVerified: readBool(json, 'domain_verified', 'domainVerified'),
        profilePhotoPath:
            readStringOrNull(json, 'profile_photo_path', 'profilePhotoPath'),
        specialties: (json['specialties'] as List<dynamic>?)?.cast<String>() ??
            const [],
        trainingTypes: (json['training_types'] ?? json['trainingTypes'] as List<dynamic>?)
                ?.map((e) => TrainingType.fromJson(e as String))
                .toList() ??
            const [],
        businessCurrency:
            readStringOrNull(json, 'business_currency', 'businessCurrency') ??
                'PLN',
        averageRating: (json['average_rating'] ?? json['averageRating'] as num?)
            ?.toDouble(),
        completionPercentage:
            (json['completion_percentage'] ?? json['completionPercentage'] as int?) ??
                0,
        missingFields: json['missing_fields'] ?? json['missingFields']
            as List<dynamic>?,
        isVerified: readBool(json, 'is_verified', 'isVerified'),
        availability: (json['availability'] ?? json['availability'])
            as Map<String, dynamic>?,
        minServicePrice:
            (json['min_service_price'] ?? json['minServicePrice'] as num?)
                ?.toDouble(),
        location: readStringOrNull(json, 'location', 'location'),
        locationNormalized: readStringOrNull(
            json, 'location_normalized', 'locationNormalized'),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
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
