// -----------------------------------------------------------------------------
// Edge Case Data Integrity Tests
//
// Tests edge cases that real backend responses might throw at the Flutter
// model parsing layer. Covers 9 edge case categories with the full parse
// pipeline: mock JSON -> ApiResponse envelope -> model fromJson -> integrity
// verification.
//
// Pattern: Use Dio MockAdapter/wrapper via Response<Map<String, dynamic>>,
// then parse through ApiResponse.fromJson or direct model fromJson.
//
// Convention:
//   kTs = 1704067200000 (2024-01-01T00:00:00Z)
//   kTs2 = 1705276800000 (2024-01-15T00:00:00Z)
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/data/models/enums/user_tier.dart';
import 'package:zirofit_fl/data/models/enums/weight_unit.dart';

// =============================================================================
// Helpers
// =============================================================================

/// Shortcut for `{"data": value}`.
Map<String, dynamic> _data(Map<String, dynamic> value) => {'data': value};

/// A fixed Unix-ms timestamp (2024-01-01T00:00:00Z).
const int kTs = 1704067200000;

/// A second timestamp (2024-01-15T00:00:00Z).
const int kTs2 = 1705276800000;

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ===========================================================================
  // 1. Empty / null string fields
  // ===========================================================================
  group('1. Empty / null string fields', () {
    test('Profile nullable fields: empty string parses as String?', () {
      final json = _data({
        'id': 'p-1',
        'user_id': 'u-1',
        'certifications': '',
        'phone': '',
        'about_me': '',
        'philosophy': '',
        'methodology': '',
        'branding': '',
        'banner_image_path': '',
        'custom_domain': '',
        'profile_photo_path': '',
        'location': '',
        'location_normalized': '',
        'created_at': kTs,
        'updated_at': kTs,
      });
      final envelope =
          ApiResponse.fromJson(json, (m) => Profile.fromJson(m));
      expect(envelope.isSuccess, isTrue);
      final profile = envelope.data!;
      expect(profile.certifications, '');
      expect(profile.phone, '');
      expect(profile.aboutMe, '');
      expect(profile.philosophy, '');
      expect(profile.branding, '');
      expect(profile.bannerImagePath, '');
      expect(profile.profilePhotoPath, '');
      expect(profile.location, '');
      expect(profile.locationNormalized, '');
    });

    test('Profile nullable fields: null produces null for String?', () {
      final json = _data({
        'id': 'p-1',
        'user_id': 'u-1',
        'certifications': null,
        'phone': null,
        'about_me': null,
        'philosophy': null,
        'methodology': null,
        'branding': null,
        'banner_image_path': null,
        'custom_domain': null,
        'profile_photo_path': null,
        'location': null,
        'location_normalized': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      final envelope =
          ApiResponse.fromJson(json, (m) => Profile.fromJson(m));
      expect(envelope.isSuccess, isTrue);
      final profile = envelope.data!;
      expect(profile.certifications, isNull);
      expect(profile.phone, isNull);
      expect(profile.aboutMe, isNull);
      expect(profile.philosophy, isNull);
      expect(profile.methodology, isNull);
      expect(profile.branding, isNull);
      expect(profile.bannerImagePath, isNull);
      expect(profile.customDomain, isNull);
      expect(profile.profilePhotoPath, isNull);
      expect(profile.location, isNull);
      expect(profile.locationNormalized, isNull);
    });

    test('Profile nullable fields: absent keys produce null', () {
      final json = _data({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      final envelope =
          ApiResponse.fromJson(json, (m) => Profile.fromJson(m));
      expect(envelope.isSuccess, isTrue);
      final profile = envelope.data!;
      expect(profile.certifications, isNull);
      expect(profile.phone, isNull);
      expect(profile.aboutMe, isNull);
      expect(profile.philosophy, isNull);
      expect(profile.methodology, isNull);
      expect(profile.branding, isNull);
      expect(profile.bannerImagePath, isNull);
      expect(profile.customDomain, isNull);
      expect(profile.profilePhotoPath, isNull);
      expect(profile.location, isNull);
      expect(profile.locationNormalized, isNull);
    });

    test('User nullable strings: empty, null, absent — found in user model',
        () {
      // username, subscriptionStatus, stripeCustomerId, etc.
      final json = _data({
        'id': 'u-1',
        'name': 'Test',
        'email': 'test@test.com',
        'role': 'trainer',
        'username': '',
        'subscription_status': null,
        // stripe_customer_id absent
        'stripe_subscription_id': null,
        'stripe_subscription_status': '',
        'stripe_connect_account_id': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      final envelope =
          ApiResponse.fromJson(json, (m) => User.fromJson(m));
      expect(envelope.isSuccess, isTrue);
      final user = envelope.data!;
      expect(user.username, '');
      expect(user.subscriptionStatus, isNull);
      expect(user.stripeCustomerId, isNull);
      expect(user.stripeSubscriptionId, isNull);
      expect(user.stripeSubscriptionStatus, '');
      expect(user.stripeConnectAccountId, isNull);
    });
  });

  // ===========================================================================
  // 2. Empty vs null array handling
  // ===========================================================================
  group('2. Empty vs null array handling', () {
    // Profile.specialties uses: (json['specialties'] as List<dynamic>?)?.cast<String>() ?? []
    test('Profile.specialties: [] produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'specialties': <String>[],
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.specialties, isEmpty);
    });

    test('Profile.specialties: null produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'specialties': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.specialties, isEmpty);
    });

    test('Profile.specialties: absent key produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.specialties, isEmpty);
    });

    // Profile.trainingTypes uses: (json['training_types'] as List<dynamic>?)?.map(...).toList() ?? []
    test('Profile.trainingTypes: [] produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'training_types': <String>[],
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.trainingTypes, isEmpty);
    });

    test('Profile.trainingTypes: null produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'training_types': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.trainingTypes, isEmpty);
    });

    test('Profile.trainingTypes: absent key produces empty list', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.trainingTypes, isEmpty);
    });

    // User.pushTokens uses: (json['push_tokens'] as List<dynamic>?)?.cast<String>() ?? []
    test('User.pushTokens: [] produces empty list', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'push_tokens': <String>[],
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.pushTokens, isEmpty);
    });

    test('User.pushTokens: null produces empty list', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'push_tokens': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.pushTokens, isEmpty);
    });

    test('User.pushTokens: absent key produces empty list', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.pushTokens, isEmpty);
    });
  });

  // ===========================================================================
  // 3. Missing optional fields (comprehensive)
  // ===========================================================================
  group('3. Missing optional fields', () {
    test('User: all nullable fields absent — defaults applied', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': kTs,
        'updated_at': kTs,
      });
      // Non-nullable fields with defaults
      expect(user.defaultCheckInDay, 0);
      expect(user.defaultCheckInHour, 9);
      expect(user.tier, UserTier.starter);
      expect(user.hasCompletedOnboarding, false);
      expect(user.weightUnit, WeightUnit.kg);
      expect(user.pushTokens, isEmpty);
      expect(user.stripeCancelAtPeriodEnd, false);
      // Nullable fields
      expect(user.username, isNull);
      expect(user.emailVerifiedAt, isNull);
      expect(user.subscriptionStatus, isNull);
      expect(user.trialEndsAt, isNull);
      expect(user.stripeCustomerId, isNull);
      expect(user.stripeSubscriptionId, isNull);
      expect(user.stripeSubscriptionStatus, isNull);
      expect(user.stripeConnectAccountId, isNull);
      expect(user.stripeCurrentPeriodEnd, isNull);
      expect(user.stripeCancelAt, isNull);
    });

    test('Profile: all nullable fields absent — defaults applied', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.certifications, isNull);
      expect(profile.phone, isNull);
      expect(profile.aboutMe, isNull);
      expect(profile.philosophy, isNull);
      expect(profile.methodology, isNull);
      expect(profile.branding, isNull);
      expect(profile.bannerImagePath, isNull);
      expect(profile.customDomain, isNull);
      expect(profile.domainVerified, false);
      expect(profile.profilePhotoPath, isNull);
      expect(profile.specialties, isEmpty);
      expect(profile.trainingTypes, isEmpty);
      expect(profile.businessCurrency, 'PLN');
      expect(profile.averageRating, isNull);
      expect(profile.completionPercentage, 0);
      expect(profile.missingFields, isNull);
      expect(profile.isVerified, false);
      expect(profile.availability, isNull);
      expect(profile.minServicePrice, isNull);
      expect(profile.location, isNull);
      expect(profile.locationNormalized, isNull);
      expect(profile.latitude, isNull);
      expect(profile.longitude, isNull);
      expect(profile.deletedAt, isNull);
    });

    test('Booking: all nullable fields absent — defaults applied', () {
      final booking = Booking.fromJson({
        'id': 'b-1',
        'start_time': kTs,
        'end_time': kTs2,
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(booking.status, BookingStatus.pending);
      expect(booking.dataSharingApproved, isNull);
      expect(booking.dataSharingApprovedAt, isNull);
      expect(booking.clientId, isNull);
      expect(booking.clientName, isNull);
      expect(booking.clientEmail, isNull);
      expect(booking.clientNotes, isNull);
      expect(booking.deletedAt, isNull);
    });

    test('WorkoutSession: all nullable fields absent — defaults applied', () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.name, isNull);
      expect(session.endTime, isNull);
      expect(session.status, WorkoutSessionStatus.inProgress);
      expect(session.notes, isNull);
      expect(session.restStartedAt, isNull);
      expect(session.workoutTemplateId, isNull);
      expect(session.plannedDate, isNull);
      expect(session.clientPackageId, isNull);
      expect(session.isTrainerLed, false);
      expect(session.reminderTime, isNull);
      expect(session.trainerReminderSent, false);
      expect(session.deletedAt, isNull);
    });

    test('Exercise: all nullable fields absent — defaults applied', () {
      final exercise = Exercise.fromJson({
        'id': 'ex-1',
        'name': 'Bench Press',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(exercise.muscleGroup, isNull);
      expect(exercise.equipment, isNull);
      expect(exercise.category, isNull);
      expect(exercise.description, isNull);
      expect(exercise.videoUrl, isNull);
      expect(exercise.imageUrl, isNull);
      expect(exercise.createdById, isNull);
      expect(exercise.recommendedRestSeconds, isNull);
      expect(exercise.isUnilateral, false);
      expect(exercise.deletedAt, isNull);
    });

    test('ClientExerciseLog: all nullable fields absent — defaults applied',
        () {
      final log = ClientExerciseLog.fromJson({
        'id': 'log-1',
        'client_id': 'c-1',
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(log.reps, isNull);
      expect(log.weight, isNull);
      expect(log.isCompleted, isNull);
      expect(log.order, isNull);
      expect(log.tempo, isNull);
      expect(log.side, 'BOTH');
      expect(log.supersetKey, isNull);
      expect(log.orderInSuperset, isNull);
      expect(log.sets, isNull);
      expect(log.deletedAt, isNull);
    });
  });

  // ===========================================================================
  // 4. Extra unexpected fields (forward compatibility)
  // ===========================================================================
  group('4. Extra unexpected fields (forward compatibility)', () {
    test('User: extra fields are silently ignored', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'extra_field': 'should_not_crash',
        'another_extra': 123,
        'nested_extra': {'key': 'val'},
        'list_extra': [1, 2, 3],
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.id, 'u-1');
      expect(user.name, 'Test');
      expect(user.email, 't@t.com');
      expect(user.role, 'trainer');
    });

    test('Exercise: extra fields are silently ignored', () {
      final exercise = Exercise.fromJson({
        'id': 'ex-1',
        'name': 'Bench Press',
        'created_at': kTs,
        'updated_at': kTs,
        'unknown_column': 'some_value',
        'future_feature_flag': true,
        'version': 2,
      });
      expect(exercise.id, 'ex-1');
      expect(exercise.name, 'Bench Press');
    });

    test('WorkoutSession: extra fields are silently ignored', () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
        'unknown_metadata': {'key': 'val'},
        'extra_bool': true,
        'extra_int': 42,
      });
      expect(session.id, 'ws-1');
      expect(session.clientId, 'c-1');
    });

    test('ApiResponse: unexpected top-level envelope fields are ignored when '
        'data is present', () {
      final envelope = ApiResponse.fromJson(
        {
          'data': {'id': 'x1', 'name': 'item'},
          'serverTime': 12345,
          'version': '2.0',
        },
        (m) => m,
      );
      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['id'], 'x1');
    });
  });

  // ===========================================================================
  // 5. Decimal String vs num parsing
  // ===========================================================================
  group('5. Decimal String vs num parsing', () {
    // Service.price: (json['price'] as num?)?.toDouble()
    test('Service: price as num 80.5 parses correctly', () {
      final service = Service.fromJson({
        'id': 's-1',
        'profile_id': 'p-1',
        'title': 'Training',
        'description': '1-on-1',
        'price': 80.5,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(service.price, 80.5);
    });

    test('Service: price as int 100 parses via num → double', () {
      final service = Service.fromJson({
        'id': 's-1',
        'profile_id': 'p-1',
        'title': 'Training',
        'description': '1-on-1',
        'price': 100,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(service.price, 100.0);
    });

    test('Service: price as String "80.50" — as num? returns null '
        '(Prisma Decimal limitation)', () {
      // NOTE: (json['price'] as num?) on a String value throws TypeError
      // because String is not a subtype of num.
      expect(
        () => Service.fromJson({
          'id': 's-1',
          'profile_id': 'p-1',
          'title': 'Training',
          'description': '1-on-1',
          'price': '80.50',
          'created_at': kTs,
          'updated_at': kTs,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    // Package.price: (json['price'] as num?)?.toDouble() ?? 0
    test('Package: price as double 299.99 parses correctly', () {
      final pkg = Package.fromJson({
        'id': 'pkg-1',
        'name': '10 Sessions',
        'price': 299.99,
        'number_of_sessions': 10,
        'stripe_product_id': 'prod_1',
        'stripe_price_id': 'price_1',
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(pkg.price, 299.99);
    });

    test('Package: price as int 200 parses via num → double', () {
      final pkg = Package.fromJson({
        'id': 'pkg-1',
        'name': '10 Sessions',
        'price': 200,
        'number_of_sessions': 10,
        'stripe_product_id': 'prod_1',
        'stripe_price_id': 'price_1',
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(pkg.price, 200.0);
    });

    test('Package: price as String — as num? throws TypeError', () {
      expect(
        () => Package.fromJson({
          'id': 'pkg-1',
          'name': '10 Sessions',
          'price': '149.99',
          'number_of_sessions': 5,
          'stripe_product_id': 'prod_1',
          'stripe_price_id': 'price_1',
          'trainer_id': 'tr-1',
          'created_at': kTs,
          'updated_at': kTs,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    // Event.price: (json['price'] as num?)?.toDouble() ?? 0
    test('Event: price as double 29.99 parses correctly', () {
      final event = Event.fromJson({
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Workshop',
        'start_time': kTs,
        'end_time': kTs2,
        'price': 29.99,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(event.price, 29.99);
    });

    test('Event: price as int 50 parses via num → double', () {
      final event = Event.fromJson({
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Workshop',
        'start_time': kTs,
        'end_time': kTs2,
        'price': 50,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(event.price, 50.0);
    });

    // PersonalRecord.value: (json['value'] as num).toDouble()  (non-nullable)
    test('PersonalRecord: value as double 100.0 parses correctly', () {
      final pr = PersonalRecord.fromJson({
        'id': 'pr-1',
        'client_id': 'c-1',
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'record_type': 'weight',
        'value': 100.0,
        'achieved_at': kTs,
      });
      expect(pr.value, 100.0);
    });

    test('PersonalRecord: value as int 100 parses as 100.0 via num.toDouble()',
        () {
      final pr = PersonalRecord.fromJson({
        'id': 'pr-1',
        'client_id': 'c-1',
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'record_type': 'weight',
        'value': 100,
        'achieved_at': kTs,
      });
      expect(pr.value, 100.0);
      // Verify it's actually a double, not an int
      expect(pr.value.runtimeType, double);
    });

    test('PersonalRecord: value as String throws TypeError', () {
      expect(
        () => PersonalRecord.fromJson({
          'id': 'pr-1',
          'client_id': 'c-1',
          'exercise_id': 'ex-1',
          'workout_session_id': 'ws-1',
          'record_type': 'weight',
          'value': '100.0',
          'achieved_at': kTs,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    // Profile.averageRating: (json['average_rating'] as num?)?.toDouble()
    test('Profile.averageRating: double 4.5 parses correctly', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'average_rating': 4.5,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.averageRating, 4.5);
    });

    test('Profile.averageRating: int 5 parses as 5.0 via num.toDouble()', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'average_rating': 5,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.averageRating, 5.0);
    });
  });

  // ===========================================================================
  // 6. Extreme / edge timestamp values
  // ===========================================================================
  group('6. Extreme / edge timestamp values', () {
    test('created_at: 0 — epoch start parses to DateTime(1970, 1, 1)', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': 0,
        'updated_at': kTs,
      });
      expect(user.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('created_at: 253402300799000 — near year 9999', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(253402300799000);
      expect(dt.year, greaterThanOrEqualTo(9999));

      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': 253402300799000,
        'updated_at': kTs,
      });
      expect(user.createdAt, dt);
    });

    test('created_at: -2208988800000 — negative timestamp (year 1900)', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(-2208988800000);
      expect(dt.year, 1900);

      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': -2208988800000,
        'updated_at': kTs,
      });
      expect(user.createdAt, dt);
    });

    test('nullable created_at: null produces null', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
        'deleted_at': null,
      });
      expect(profile.deletedAt, isNull);
    });

    test('nullable created_at: absent key produces null', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.deletedAt, isNull);
    });

    test('Booking: null and absent dataSharingApprovedAt', () {
      // Explicit null
      final booking1 = Booking.fromJson({
        'id': 'b-1',
        'start_time': kTs,
        'end_time': kTs2,
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
        'data_sharing_approved_at': null,
      });
      expect(booking1.dataSharingApprovedAt, isNull);

      // Absent key
      final booking2 = Booking.fromJson({
        'id': 'b-2',
        'start_time': kTs,
        'end_time': kTs2,
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(booking2.dataSharingApprovedAt, isNull);
    });

    test('WorkoutSession: readDateTimeOrNull handles null and absent', () {
      // null end_time
      final s1 = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'end_time': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(s1.endTime, isNull);

      // absent end_time
      final s2 = WorkoutSession.fromJson({
        'id': 'ws-2',
        'client_id': 'c-1',
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(s2.endTime, isNull);
    });
  });

  // ===========================================================================
  // 7. Nested object fallback patterns
  // ===========================================================================
  group('7. Nested object fallback patterns', () {
    test('WorkoutSession: nested client object — clientId from client.id, '
        'name from client.name', () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client': {'id': 'c-1', 'name': 'John'},
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.clientId, 'c-1');
      expect(session.name, 'John');
    });

    test('WorkoutSession: flat client_id takes priority over nested client.id',
        () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'flat-id',
        'client': {'id': 'nested-id', 'name': 'Nested'},
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.clientId, 'flat-id');
      // name should still come from nested client because no flat name field
      expect(session.name, 'Nested');
    });

    test('WorkoutSession: flat name takes priority over nested client.name',
        () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'name': 'Flat Name',
        'client': {'id': 'c-1', 'name': 'Nested Name'},
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.name, 'Flat Name');
    });

    test('WorkoutSession: no client info at all throws FormatException', () {
      expect(
        () => WorkoutSession.fromJson({
          'id': 'ws-1',
          'start_time': kTs,
          'created_at': kTs,
          'updated_at': kTs,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('ClientExerciseLog: nested client object — clientId from client.id',
        () {
      final log = ClientExerciseLog.fromJson({
        'id': 'log-1',
        'client': {'id': 'c-1'},
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(log.clientId, 'c-1');
    });

    test('ClientExerciseLog: flat client_id takes priority over nested '
        'client.id', () {
      final log = ClientExerciseLog.fromJson({
        'id': 'log-1',
        'client_id': 'flat-id',
        'client': {'id': 'nested-id'},
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(log.clientId, 'flat-id');
    });

    test('ClientExerciseLog: no client info at all throws FormatException', () {
      expect(
        () => ClientExerciseLog.fromJson({
          'id': 'log-1',
          'exercise_id': 'ex-1',
          'workout_session_id': 'ws-1',
          'created_at': kTs,
          'updated_at': kTs,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('WorkoutSession: nested client object with camelCase clientId key',
        () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'clientId': 'camel-id',
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.clientId, 'camel-id');
    });
  });

  // ===========================================================================
  // 8. Boolean null safety
  // ===========================================================================
  group('8. Boolean null safety', () {
    // User.hasCompletedOnboarding: (json['has_completed_onboarding'] as bool?) ?? false
    test('User.hasCompletedOnboarding: null produces false', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'has_completed_onboarding': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.hasCompletedOnboarding, false);
    });

    test('User.hasCompletedOnboarding: absent key produces false', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.hasCompletedOnboarding, false);
    });

    test('User.hasCompletedOnboarding: true and false both work', () {
      final userT = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'has_completed_onboarding': true,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(userT.hasCompletedOnboarding, true);

      final userF = User.fromJson({
        'id': 'u-2',
        'name': 'Test2',
        'email': 't2@t.com',
        'role': 'trainer',
        'has_completed_onboarding': false,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(userF.hasCompletedOnboarding, false);
    });

    // Exercise.isUnilateral: readBool(json, 'is_unilateral', 'isUnilateral')
    test('Exercise.isUnilateral: null produces false via readBool', () {
      final exercise = Exercise.fromJson({
        'id': 'ex-1',
        'name': 'Bench Press',
        'is_unilateral': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(exercise.isUnilateral, false);
    });

    test('Exercise.isUnilateral: absent key produces false', () {
      final exercise = Exercise.fromJson({
        'id': 'ex-1',
        'name': 'Bench Press',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(exercise.isUnilateral, false);
    });

    test('Exercise.isUnilateral: true and false both work', () {
      final exT = Exercise.fromJson({
        'id': 'ex-1',
        'name': 'Bench Press',
        'is_unilateral': true,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(exT.isUnilateral, true);

      final exF = Exercise.fromJson({
        'id': 'ex-2',
        'name': 'Squat',
        'is_unilateral': false,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(exF.isUnilateral, false);
    });

    // WorkoutSession.isTrainerLed: readBool(json, 'is_trainer_led', 'isTrainerLed')
    test('WorkoutSession.isTrainerLed: null produces false', () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'is_trainer_led': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.isTrainerLed, false);
    });

    test('WorkoutSession.isTrainerLed: absent key produces false', () {
      final session = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(session.isTrainerLed, false);
    });

    test('WorkoutSession.isTrainerLed: true and false both work', () {
      final sT = WorkoutSession.fromJson({
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': kTs,
        'is_trainer_led': true,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(sT.isTrainerLed, true);

      final sF = WorkoutSession.fromJson({
        'id': 'ws-2',
        'client_id': 'c-1',
        'start_time': kTs,
        'is_trainer_led': false,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(sF.isTrainerLed, false);
    });

    // Package.isActive: (json['is_active'] as bool?) ?? true
    test('Package.isActive: null produces true (default)', () {
      final pkg = Package.fromJson({
        'id': 'pkg-1',
        'name': '10 Sessions',
        'price': 100,
        'number_of_sessions': 10,
        'stripe_product_id': 'prod_1',
        'stripe_price_id': 'price_1',
        'trainer_id': 'tr-1',
        'is_active': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(pkg.isActive, true);
    });

    test('Package.isActive: absent key produces true', () {
      final pkg = Package.fromJson({
        'id': 'pkg-1',
        'name': '10 Sessions',
        'price': 100,
        'number_of_sessions': 10,
        'stripe_product_id': 'prod_1',
        'stripe_price_id': 'price_1',
        'trainer_id': 'tr-1',
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(pkg.isActive, true);
    });

    // Event.isPromoted: (json['is_promoted'] as bool?) ?? false
    test('Event.isPromoted: null produces false', () {
      final event = Event.fromJson({
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Workshop',
        'start_time': kTs,
        'end_time': kTs2,
        'is_promoted': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(event.isPromoted, false);
    });

    test('Event.isPromoted: absent key produces false', () {
      final event = Event.fromJson({
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Workshop',
        'start_time': kTs,
        'end_time': kTs2,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(event.isPromoted, false);
    });

    test('Event.isPromoted: true and false both work', () {
      final eT = Event.fromJson({
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Workshop',
        'start_time': kTs,
        'end_time': kTs2,
        'is_promoted': true,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(eT.isPromoted, true);

      final eF = Event.fromJson({
        'id': 'ev-2',
        'trainer_id': 'tr-1',
        'title': 'Seminar',
        'start_time': kTs,
        'end_time': kTs2,
        'is_promoted': false,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(eF.isPromoted, false);
    });

    // Profile.isVerified: (json['is_verified'] as bool?) ?? false
    test('Profile.isVerified: null produces false', () {
      final profile = Profile.fromJson({
        'id': 'p-1',
        'user_id': 'u-1',
        'is_verified': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(profile.isVerified, false);
    });

    // User.stripeCancelAtPeriodEnd: (json['stripe_cancel_at_period_end'] as bool?) ?? false
    test('User.stripeCancelAtPeriodEnd: null produces false', () {
      final user = User.fromJson({
        'id': 'u-1',
        'name': 'Test',
        'email': 't@t.com',
        'role': 'trainer',
        'stripe_cancel_at_period_end': null,
        'created_at': kTs,
        'updated_at': kTs,
      });
      expect(user.stripeCancelAtPeriodEnd, false);
    });
  });

  // ===========================================================================
  // 9. Deeply nested pagination
  // ===========================================================================
  group('9. Deeply nested pagination', () {
    Map<String, dynamic> item(dynamic id) => {'id': 'item-$id', 'name': 'Item $id'};

    test('apiResponsePaginatedFromJson with default keys', () {
      final json = {
        'data': [item(1), item(2)],
        'total': 100,
        'page': 1,
        'perPage': 20,
        'totalPages': 5,
        'hasMore': true,
      };
      final envelope = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        json,
        (m) => m,
      );
      expect(envelope.isSuccess, isTrue);
      final paginated = envelope.data!;
      expect(paginated.items, hasLength(2));
      expect(paginated.items.first['id'], 'item-1');
      expect(paginated.total, 100);
      expect(paginated.page, 1);
      expect(paginated.perPage, 20);
      expect(paginated.totalPages, 5);
      expect(paginated.hasMore, isTrue);
    });

    test('apiResponsePaginatedFromJson with custom key names for all params',
        () {
      final json = _data({
        'items': [item(1)],
        'itemsTotal': 50,
        'currentPage': 2,
        'resultsPerPage': 10,
      });
      // Pass the inner data map to paginated parser
      final envelope = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        json['data'] as Map<String, dynamic>,
        (m) => m,
        dataKey: 'items',
        totalKey: 'itemsTotal',
        pageKey: 'currentPage',
        perPageKey: 'resultsPerPage',
      );
      expect(envelope.isSuccess, isTrue);
      final paginated = envelope.data!;
      expect(paginated.items, hasLength(1));
      expect(paginated.total, 50);
      expect(paginated.page, 2);
      expect(paginated.perPage, 10);
    });

    test('apiResponsePaginatedFromJson: empty data list with hasMore', () {
      final json = _data({
        'items': <Map<String, dynamic>>[],
        'total': 0,
        'page': 1,
        'hasMore': false,
      });
      final envelope = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        json['data'] as Map<String, dynamic>,
        (m) => m,
        dataKey: 'items',
      );
      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.items, isEmpty);
      expect(envelope.data!.total, 0);
      expect(envelope.data!.hasMore, isFalse);
    });

    test('apiResponsePaginatedFromJson: null data key produces empty items',
        () {
      final json = {
        'results': null,
        'total': 10,
        'page': 1,
      };
      final envelope = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        json,
        (m) => m,
        dataKey: 'results',
      );
      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.items, isEmpty);
      expect(envelope.data!.total, 10);
    });

    test('apiResponsePaginatedFromJson: missing data key produces empty items',
        () {
      final json = {
        'total': 10,
        'page': 1,
      };
      final envelope = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        json,
        (m) => m,
        dataKey: 'results',
      );
      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.items, isEmpty);
    });

    test('apiResponsePaginatedFromJson with nested data wrapper via envelope',
        () {
      // Simulate: ApiResponse wraps a paginated structure
      // Backend sends: {"data": {"items": [...], "total": 100, "page": 1}}
      final json = _data({
        'items': [item(1), item(2), item(3)],
        'total': 100,
        'page': 1,
        'hasMore': true,
      });
      // Step 1: parse ApiResponse envelope
      final envelope = ApiResponse.fromJson(
        json,
        (m) => m, // data is the raw pagination map
      );
      expect(envelope.isSuccess, isTrue);
      // Step 2: parse PaginatedData from the inner map
      final paginated = apiResponsePaginatedFromJson<Map<String, dynamic>>(
        envelope.data!,
        (m) => m,
        dataKey: 'items',
      );
      expect(paginated.isSuccess, isTrue);
      expect(paginated.data!.items, hasLength(3));
      expect(paginated.data!.total, 100);
      expect(paginated.data!.hasMore, isTrue);
    });

    test('apiResponsePaginatedFromJson: items parsed through model fromJson',
        () {
      // Parse items as Exercise models through the paginated pipeline
      final json = {
        'data': [
          {
            'id': 'ex-1',
            'name': 'Bench Press',
            'created_at': kTs,
            'updated_at': kTs,
          },
          {
            'id': 'ex-2',
            'name': 'Squat',
            'created_at': kTs,
            'updated_at': kTs,
          },
        ],
        'total': 2,
        'page': 1,
        'hasMore': false,
      };
      final envelope =
          apiResponsePaginatedFromJson<Exercise>(json, Exercise.fromJson);
      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.items, hasLength(2));
      expect(envelope.data!.items.first.name, 'Bench Press');
      expect(envelope.data!.items.last.name, 'Squat');
      expect(envelope.data!.total, 2);
      expect(envelope.data!.hasMore, isFalse);
    });
  });
}
