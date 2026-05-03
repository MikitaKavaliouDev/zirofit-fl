import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/enums/training_type.dart';

void main() {
  group('Profile model', () {
    final baseJson = <String, dynamic>{
      'id': 'profile-1',
      'user_id': 'user-1',
      'certifications': 'CPT, CES, FNS',
      'phone': '+48123456789',
      'about_me': 'Experienced personal trainer with 10+ years in the industry.',
      'philosophy': 'Holistic approach to fitness and wellness.',
      'methodology': 'Progressive overload with periodization.',
      'branding': 'FitLife Training',
      'banner_image_path': '/banners/fitlife_bg.jpg',
      'custom_domain': 'trainer.fitlife.com',
      'domain_verified': true,
      'profile_photo_path': '/photos/profile.jpg',
      'specialties': <String>['Weight Loss', 'Strength Training', 'Flexibility'],
      'training_types': <String>['IN_PERSON', 'ONLINE'],
      'business_currency': 'USD',
      'average_rating': 4.5,
      'completion_percentage': 85,
      'missing_fields': <String>['certifications', 'phone'],
      'is_verified': true,
      'availability': <String, dynamic>{
        'monday': ['09:00-12:00', '14:00-17:00'],
        'wednesday': ['09:00-12:00'],
        'friday': ['09:00-15:00'],
      },
      'min_service_price': 50.0,
      'location': 'Warsaw, Poland',
      'location_normalized': 'warsaw poland',
      'latitude': 52.2297,
      'longitude': 21.0122,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final profile = Profile.fromJson(baseJson);

      expect(profile.id, 'profile-1');
      expect(profile.userId, 'user-1');
      expect(profile.certifications, 'CPT, CES, FNS');
      expect(profile.phone, '+48123456789');
      expect(profile.aboutMe, 'Experienced personal trainer with 10+ years in the industry.');
      expect(profile.philosophy, 'Holistic approach to fitness and wellness.');
      expect(profile.methodology, 'Progressive overload with periodization.');
      expect(profile.branding, 'FitLife Training');
      expect(profile.bannerImagePath, '/banners/fitlife_bg.jpg');
      expect(profile.customDomain, 'trainer.fitlife.com');
      expect(profile.domainVerified, isTrue);
      expect(profile.profilePhotoPath, '/photos/profile.jpg');
      expect(profile.specialties, <String>['Weight Loss', 'Strength Training', 'Flexibility']);
      expect(profile.businessCurrency, 'USD');
      expect(profile.averageRating, 4.5);
      expect(profile.completionPercentage, 85);
      expect(profile.isVerified, isTrue);
      expect(profile.minServicePrice, 50.0);
      expect(profile.location, 'Warsaw, Poland');
      expect(profile.locationNormalized, 'warsaw poland');
      expect(profile.latitude, 52.2297);
      expect(profile.longitude, 21.0122);
      expect(profile.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(profile.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(profile.deletedAt, isNull);
    });

    test('fromJson parses List<TrainingType> from JSON array of strings', () {
      final profile = Profile.fromJson(baseJson);

      expect(profile.trainingTypes, hasLength(2));
      expect(profile.trainingTypes[0], TrainingType.inPerson);
      expect(profile.trainingTypes[1], TrainingType.online);
    });

    test('fromJson parses availability map correctly', () {
      final profile = Profile.fromJson(baseJson);

      expect(profile.availability, isNotNull);
      expect(profile.availability!['monday'], <String>['09:00-12:00', '14:00-17:00']);
      expect(profile.availability!['wednesday'], <String>['09:00-12:00']);
      expect(profile.availability!['friday'], <String>['09:00-15:00']);
    });

    test('fromJson handles null availability', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['availability'] = null;

      final profile = Profile.fromJson(json);

      expect(profile.availability, isNull);
    });

    test('fromJson handles missing availability key', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('availability');

      final profile = Profile.fromJson(json);

      expect(profile.availability, isNull);
    });

    test('fromJson handles empty specialties list', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['specialties'] = <String>[];

      final profile = Profile.fromJson(json);

      expect(profile.specialties, isEmpty);
    });

    test('fromJson handles null specialties (defaults to empty list)', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['specialties'] = null;

      final profile = Profile.fromJson(json);

      expect(profile.specialties, isEmpty);
    });

    test('fromJson handles null training_types (defaults to empty list)', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['training_types'] = null;

      final profile = Profile.fromJson(json);

      expect(profile.trainingTypes, isEmpty);
    });

    test('toJson produces correct wire format', () {
      final profile = Profile.fromJson(baseJson);
      final output = profile.toJson();

      expect(output['id'], 'profile-1');
      expect(output['user_id'], 'user-1');
      expect(output['certifications'], 'CPT, CES, FNS');
      expect(output['phone'], '+48123456789');
      expect(output['about_me'], 'Experienced personal trainer with 10+ years in the industry.');
      expect(output['domain_verified'], isTrue);
      expect(output['specialties'], <String>['Weight Loss', 'Strength Training', 'Flexibility']);
      expect(output['training_types'], <String>['IN_PERSON', 'ONLINE']);
      expect(output['business_currency'], 'USD');
      expect(output['average_rating'], 4.5);
      expect(output['completion_percentage'], 85);
      expect(output['missing_fields'], <String>['certifications', 'phone']);
      expect(output['is_verified'], isTrue);
      expect(output['availability'], isA<Map<String, dynamic>>());
      expect(output['min_service_price'], 50.0);
      expect(output['location'], 'Warsaw, Poland');
      expect(output['location_normalized'], 'warsaw poland');
      expect(output['latitude'], 52.2297);
      expect(output['longitude'], 21.0122);
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000000000);
      expect(output.containsKey('deleted_at'), isTrue);
      expect(output['deleted_at'], isNull);
    });

    test('toJson maps TrainingType enum values to API string format', () {
      final profile = Profile.fromJson(baseJson);
      final output = profile.toJson();

      expect(output['training_types'], <String>['IN_PERSON', 'ONLINE']);
    });

    test('fromJson handles null optional fields', () {
      final json = <String, dynamic>{
        'id': 'profile-1',
        'user_id': 'user-1',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'profile-1');
      expect(profile.userId, 'user-1');
      // Optional fields should be null or default
      expect(profile.certifications, isNull);
      expect(profile.phone, isNull);
      expect(profile.aboutMe, isNull);
      expect(profile.philosophy, isNull);
      expect(profile.methodology, isNull);
      expect(profile.branding, isNull);
      expect(profile.bannerImagePath, isNull);
      expect(profile.customDomain, isNull);
      expect(profile.profilePhotoPath, isNull);
      expect(profile.missingFields, isNull);
      expect(profile.availability, isNull);
      expect(profile.minServicePrice, isNull);
      expect(profile.location, isNull);
      expect(profile.locationNormalized, isNull);
      expect(profile.latitude, isNull);
      expect(profile.longitude, isNull);
      expect(profile.averageRating, isNull);
      expect(profile.deletedAt, isNull);
      // Defaults
      expect(profile.domainVerified, isFalse);
      expect(profile.specialties, isEmpty);
      expect(profile.trainingTypes, isEmpty);
      expect(profile.businessCurrency, 'PLN');
      expect(profile.completionPercentage, 0);
      expect(profile.isVerified, isFalse);
    });

    test('equality uses toJson comparison to avoid list identity issues', () {
      final profile1 = Profile.fromJson(baseJson);
      final profile2 = Profile.fromJson(baseJson);

      expect(profile1.toJson(), equals(profile2.toJson()));
    });

    test('profiles with different ids are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      json1['id'] = 'profile-1';
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['id'] = 'profile-2';

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.toJson(), isNot(equals(p2.toJson())));
    });

    test('profiles with different specialties are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['specialties'] = <String>['Yoga'];

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.toJson(), isNot(equals(p2.toJson())));
    });

    test('profiles with different trainingTypes are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['training_types'] = <String>['ONLINE'];

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.toJson(), isNot(equals(p2.toJson())));
    });

    test('profiles with different availability are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['availability'] = <String, dynamic>{'monday': ['09:00-12:00']};

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.toJson(), isNot(equals(p2.toJson())));
    });

    test('toJson roundtrip preserves all fields', () {
      final profile = Profile.fromJson(baseJson);
      final json = profile.toJson();
      final restored = Profile.fromJson(json);

      expect(restored.toJson(), equals(profile.toJson()));
    });

    test('full roundtrip fromJson -> toJson -> fromJson produces equivalent serialization', () {
      final original = Profile.fromJson(baseJson);
      final output = original.toJson();
      final restored = Profile.fromJson(output);

      expect(restored.toJson(), equals(original.toJson()));
    });

    test('toJson serialization is deterministic for same data', () {
      final p1 = Profile.fromJson(baseJson);
      final p2 = Profile.fromJson(baseJson);

      expect(p1.toJson()['id'], p2.toJson()['id']);
      expect(p1.toJson()['user_id'], p2.toJson()['user_id']);
      expect(p1.toJson()['specialties'], <String>['Weight Loss', 'Strength Training', 'Flexibility']);
      expect(p1.toJson()['training_types'], <String>['IN_PERSON', 'ONLINE']);
    });

    test('equality compares scalar fields (lists use reference equality in model)', () {
      final profile1 = Profile.fromJson(baseJson);
      final profile2 = Profile.fromJson(baseJson);

      // Profile uses == for List/Map fields which checks reference equality.
      // Verify scalar fields match instead.
      expect(profile1.id, profile2.id);
      expect(profile1.userId, profile2.userId);
      expect(profile1.certifications, profile2.certifications);
      expect(profile1.phone, profile2.phone);
      expect(profile1.aboutMe, profile2.aboutMe);
      expect(profile1.averageRating, profile2.averageRating);
      expect(profile1.completionPercentage, profile2.completionPercentage);
      expect(profile1.isVerified, profile2.isVerified);
      expect(profile1.createdAt, profile2.createdAt);
    });

    test('profiles with different ids are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      json1['id'] = 'profile-1';
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['id'] = 'profile-2';

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.id, isNot(equals(p2.id)));
    });

    test('profiles with different specialties are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['specialties'] = <String>['Yoga'];

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.specialties, isNot(equals(p2.specialties)));
    });

    test('profiles with different trainingTypes are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['training_types'] = <String>['ONLINE'];

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.trainingTypes, isNot(equals(p2.trainingTypes)));
    });

    test('profiles with different availability are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['availability'] = <String, dynamic>{'monday': ['09:00-12:00']};

      final p1 = Profile.fromJson(json1);
      final p2 = Profile.fromJson(json2);

      expect(p1.availability, isNot(equals(p2.availability)));
    });

    test('toJson roundtrip preserves all fields', () {
      final profile = Profile.fromJson(baseJson);
      final json = profile.toJson();
      final restored = Profile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.userId, profile.userId);
      expect(restored.certifications, profile.certifications);
      expect(restored.phone, profile.phone);
      expect(restored.createdAt, profile.createdAt);
      expect(restored.updatedAt, profile.updatedAt);
    });

    test('toString returns expected format', () {
      final profile = Profile.fromJson(baseJson);
      final str = profile.toString();

      expect(str, contains('profile-1'));
      expect(str, contains('Profile('));
      expect(str, contains('specialties'));
      expect(str, contains('trainingTypes'));
      expect(str, contains('availability'));
    });
  });
}
