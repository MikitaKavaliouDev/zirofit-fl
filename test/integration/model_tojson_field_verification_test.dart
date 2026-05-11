// -----------------------------------------------------------------------------
// toJson() Format Verification Integration Test for ALL data models.
//
// This file verifies that toJson() produces the correct output format for every
// model, catching regressions where JSON keys use wrong casing (e.g. camelCase
// instead of snake_case), timestamps have wrong types, enum values have wrong
// casing, etc.
//
// Conventions verified:
//   - JSON keys are snake_case (regex: ^[a-z][a-z0-9_]*$)
//   - Timestamps are int (Unix ms) — never String or DateTime
//   - Enum values are String in UPPER_SCREAMING_CASE
//   - List fields are never null (default to [])
//   - bool fields remain bool, double fields remain double (from num? casting)
//   - Nullable fields appear as null in JSON (not omitted)
//
// NOTE: This is NOT a round-trip test. The existing
// test/unit/models/model_serialization_test.dart covers round-trip behavior.
// This test is purely about toJson() OUTPUT FORMAT.
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/assessment.dart';
import 'package:zirofit_fl/data/models/assessment_result.dart';
import 'package:zirofit_fl/data/models/benefit.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/client_package.dart';
import 'package:zirofit_fl/data/models/client_program_assignment.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/client_resource.dart';
import 'package:zirofit_fl/data/models/conversation.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/data/models/enums/event_status.dart';
import 'package:zirofit_fl/data/models/enums/habit_frequency.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';
import 'package:zirofit_fl/data/models/enums/training_type.dart';
import 'package:zirofit_fl/data/models/enums/user_tier.dart';
import 'package:zirofit_fl/data/models/enums/weight_unit.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/event_booking.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/data/models/habit_log.dart';
import 'package:zirofit_fl/data/models/location.dart';
import 'package:zirofit_fl/data/models/message.dart';
import 'package:zirofit_fl/data/models/notification_model.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';
import 'package:zirofit_fl/data/models/product.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import 'package:zirofit_fl/data/models/recipe_tag.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/system_error.dart';
import 'package:zirofit_fl/data/models/system_setting.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/transformation_photo.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_session_comment.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';

// =============================================================================
//  Helpers
// =============================================================================

/// Regex for valid snake_case keys: start with lowercase letter, then only
/// lowercase letters, digits, and underscores.
final _snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');

/// Verifies ALL keys in [map] match snake_case.
void _verifySnakeCaseKeys(Map<String, dynamic> map, String modelName) {
  for (final key in map.keys) {
    expect(key, matches(_snakeCase),
        reason: '$modelName.toJson() key "$key" is not snake_case');
  }
}

/// Verifies a timestamp field is int (or null).
void _verifyTimestampField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    final value = json[key];
    if (value != null) {
      expect(value, isA<int>(), reason: '$key should be int ms timestamp');
    }
  }
}

/// Verifies a list field is a non-null List.
void _verifyListField(Map<String, dynamic> json, String key) {
  expect(json.containsKey(key), isTrue,
      reason: 'Expected key "$key" to be present in JSON');
  expect(json[key], isA<List>(), reason: '$key should be a List');
}

/// Verifies a bool field is a bool.
void _verifyBoolField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] != null) {
    expect(json[key], isA<bool>(), reason: '$key should be bool');
  }
}

/// Verifies a double field is a double (may be null).
void _verifyDoubleField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] != null) {
    expect(json[key], isA<double>(), reason: '$key should be double');
  }
}

/// Verifies an enum (String) field is a String and matches UPPER_CASE pattern.
void _verifyEnumStringField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] != null) {
    expect(json[key], isA<String>(), reason: '$key should be a String (enum)');
    expect(json[key], matches(RegExp(r'^[A-Z][A-Z0-9_]*$')),
        reason: '$key enum value should be UPPER_SCREAMING_CASE');
  }
}

/// Verifies an int field is an int.
void _verifyIntField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] != null) {
    expect(json[key], isA<int>(), reason: '$key should be int');
  }
}

// =============================================================================
//  Test Data
// =============================================================================

/// Common timestamp (milliseconds) used for all test instances.
const _ms = 1700000000000;
final _dt = DateTime.fromMillisecondsSinceEpoch(_ms);

// =============================================================================
//  Tests
// =============================================================================

void main() {
  // ===========================================================================
  //  Assessment
  // ===========================================================================
  group('Assessment', () {
    test('toJson() produces correct format', () {
      final obj = Assessment(
        id: 'a-1',
        name: 'Sit & Reach',
        description: 'Flexibility test',
        unit: 'cm',
        trainerId: 'trainer-1',
        createdAt: _dt,
        updatedAt: _dt,
        deletedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Assessment');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      // All fields present including nulls
      expect(json.keys, containsAll([
        'id', 'name', 'description', 'unit', 'trainer_id',
        'created_at', 'updated_at', 'deleted_at',
      ]));
    });
  });

  // ===========================================================================
  //  AssessmentResult
  // ===========================================================================
  group('AssessmentResult', () {
    test('toJson() produces correct format', () {
      final obj = AssessmentResult(
        id: 'ar-1',
        assessmentId: 'a-1',
        clientId: 'c-1',
        value: 25.5,
        date: _dt,
        notes: 'Good effort',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'AssessmentResult');
      _verifyTimestampField(json, 'date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyDoubleField(json, 'value');
      expect(json['value'], 25.5);
    });
  });

  // ===========================================================================
  //  Benefit
  // ===========================================================================
  group('Benefit', () {
    test('toJson() produces correct format', () {
      final obj = Benefit(
        id: 'b-1',
        profileId: 'p-1',
        iconName: 'dumbbell',
        iconStyle: 'fas',
        title: 'Free Weights',
        description: 'Full access',
        orderColumn: 1,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Benefit');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyIntField(json, 'order_column');
    });
  });

  // ===========================================================================
  //  BlogPost
  // ===========================================================================
  group('BlogPost', () {
    test('toJson() produces correct format', () {
      final obj = BlogPost(
        id: 'bp-1',
        title: 'My Post',
        slug: 'my-post',
        content: 'Hello world',
        excerpt: 'A teaser',
        coverImage: 'https://example.com/img.jpg',
        published: true,
        authorId: 'auth-1',
        createdAt: _dt,
        updatedAt: _dt,
        publishedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'BlogPost');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'published_at');
      _verifyBoolField(json, 'published');
      expect(json['published'], isTrue);
    });
  });

  // ===========================================================================
  //  Booking
  // ===========================================================================
  group('Booking', () {
    test('toJson() produces correct format', () {
      final obj = Booking(
        id: 'b-1',
        startTime: _dt,
        endTime: _dt,
        status: BookingStatus.confirmed,
        dataSharingApproved: true,
        dataSharingApprovedAt: _dt,
        trainerId: 'tr-1',
        clientId: 'cl-1',
        clientName: 'John',
        clientEmail: 'john@test.com',
        clientNotes: 'First session',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Booking');
      _verifyTimestampField(json, 'start_time');
      _verifyTimestampField(json, 'end_time');
      _verifyTimestampField(json, 'data_sharing_approved_at');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyEnumStringField(json, 'status');
      _verifyBoolField(json, 'data_sharing_approved');
    });
  });

  // ===========================================================================
  //  CheckIn
  // ===========================================================================
  group('CheckIn', () {
    test('toJson() produces correct format', () {
      final obj = CheckIn(
        id: 'ci-1',
        clientId: 'c-1',
        date: _dt,
        status: 'SUBMITTED',
        weight: 75.0,
        waistCm: 85.0,
        sleepHours: 7.5,
        energyLevel: 7,
        stressLevel: 4,
        hungerLevel: 5,
        digestionLevel: 6,
        nutritionCompliance: '80%',
        clientNotes: 'Feeling good',
        trainerResponse: 'Keep it up',
        reviewedAt: _dt,
        reviewedByUserId: 'tr-1',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'CheckIn');
      _verifyTimestampField(json, 'date');
      _verifyTimestampField(json, 'reviewed_at');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyDoubleField(json, 'weight');
      _verifyDoubleField(json, 'waist_cm');
      _verifyDoubleField(json, 'sleep_hours');
    });
  });

  // ===========================================================================
  //  Client (client_model.dart)
  // ===========================================================================
  group('Client', () {
    test('toJson() produces correct format', () {
      final obj = Client(
        id: 'cl-1',
        trainerId: 'tr-1',
        userId: 'u-1',
        name: 'John Doe',
        email: 'john@test.com',
        phone: '+48123456789',
        avatarPath: '/avatars/john.jpg',
        status: 'active',
        dateOfBirth: DateTime(1990, 1, 1),
        goals: 'Lose weight',
        healthNotes: 'None',
        emergencyContactName: 'Jane Doe',
        emergencyContactPhone: '+48987654321',
        checkInDay: 1,
        checkInHour: 9,
        dataSharingExpiresAt: _dt,
        sharingSettings: {'show_weight': true},
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Client');
      _verifyTimestampField(json, 'date_of_birth');
      _verifyTimestampField(json, 'data_sharing_expires_at');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyIntField(json, 'check_in_day');
      _verifyIntField(json, 'check_in_hour');
      // date_of_birth is stored as midnight epoch (date only, not full DateTime)
      // but should still be int
      expect(json['date_of_birth'], isA<int>());
    });
  });

  // ===========================================================================
  //  ClientExerciseLog
  // ===========================================================================
  group('ClientExerciseLog', () {
    test('toJson() produces correct format', () {
      final obj = ClientExerciseLog(
        id: 'log-1',
        clientId: 'cl-1',
        exerciseId: 'ex-1',
        reps: 10,
        weight: 50.5,
        isCompleted: true,
        order: 1,
        tempo: '2-0-2-0',
        side: 'LEFT',
        workoutSessionId: 'ws-1',
        supersetKey: 'ss-1',
        orderInSuperset: 1,
        sets: [{'reps': 10, 'weight': 50.5}],
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientExerciseLog');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'is_completed');
      _verifyDoubleField(json, 'weight');
      _verifyIntField(json, 'reps');
      _verifyIntField(json, 'order');
      _verifyIntField(json, 'order_in_superset');
      _verifyListField(json, 'sets');
      expect(json['sets'], isA<List>());
    });
  });

  // ===========================================================================
  //  ClientMeasurement
  // ===========================================================================
  group('ClientMeasurement', () {
    test('toJson() produces correct format', () {
      final obj = ClientMeasurement(
        id: 'cm-1',
        clientId: 'c-1',
        measurementDate: DateTime(2024, 1, 1),
        weightKg: 75.0,
        bodyFatPercentage: 15.5,
        notes: 'Morning measurement',
        customMetrics: [{'name': 'chest', 'value': 100}],
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientMeasurement');
      _verifyTimestampField(json, 'measurement_date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyDoubleField(json, 'weight_kg');
      _verifyDoubleField(json, 'body_fat_percentage');
      _verifyListField(json, 'custom_metrics');
    });
  });

  // ===========================================================================
  //  ClientPackage
  // ===========================================================================
  group('ClientPackage', () {
    test('toJson() produces correct format', () {
      final obj = ClientPackage(
        id: 'cp-1',
        clientId: 'c-1',
        packageId: 'pkg-1',
        sessionsRemaining: 10,
        purchaseDate: _dt,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientPackage');
      _verifyTimestampField(json, 'purchase_date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyIntField(json, 'sessions_remaining');
    });
  });

  // ===========================================================================
  //  ClientProgramAssignment
  // ===========================================================================
  group('ClientProgramAssignment', () {
    test('toJson() produces correct format', () {
      final obj = ClientProgramAssignment(
        id: 'cpa-1',
        clientId: 'c-1',
        programId: 'prog-1',
        startDate: _dt,
        isActive: true,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientProgramAssignment');
      _verifyTimestampField(json, 'start_date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'is_active');
    });
  });

  // ===========================================================================
  //  ClientProgressPhoto
  // ===========================================================================
  group('ClientProgressPhoto', () {
    test('toJson() produces correct format', () {
      final obj = ClientProgressPhoto(
        id: 'cpp-1',
        clientId: 'c-1',
        photoDate: DateTime(2024, 1, 1),
        imagePath: '/photos/front.jpg',
        caption: 'Before photo',
        checkInId: 'ci-1',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientProgressPhoto');
      _verifyTimestampField(json, 'photo_date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  ClientResource
  // ===========================================================================
  group('ClientResource', () {
    test('toJson() produces correct format', () {
      final obj = ClientResource(
        id: 'cr-1',
        resourceId: 'res-1',
        clientId: 'c-1',
        createdAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ClientResource');
      _verifyTimestampField(json, 'created_at');
      expect(json.keys, hasLength(4)); // Only 4 fields
    });
  });

  // ===========================================================================
  //  Conversation
  // ===========================================================================
  group('Conversation', () {
    test('toJson() produces correct format', () {
      final obj = Conversation(
        id: 'conv-1',
        trainerId: 'tr-1',
        clientId: 'c-1',
        lastMessageAt: _dt,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Conversation');
      _verifyTimestampField(json, 'last_message_at');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
    });
  });

  // ===========================================================================
  //  DailyHabit
  // ===========================================================================
  group('DailyHabit', () {
    test('toJson() produces correct format', () {
      final obj = DailyHabit(
        id: 'dh-1',
        clientId: 'c-1',
        trainerId: 'tr-1',
        title: 'Drink water',
        description: '8 glasses',
        frequency: HabitFrequency.daily,
        isActive: true,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'DailyHabit');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyEnumStringField(json, 'frequency');
      _verifyBoolField(json, 'is_active');
    });
  });

  // ===========================================================================
  //  Event
  // ===========================================================================
  group('Event', () {
    test('toJson() produces correct format', () {
      final obj = Event(
        id: 'ev-1',
        trainerId: 'tr-1',
        title: 'Bootcamp',
        description: 'Outdoor session',
        startTime: _dt,
        endTime: _dt,
        locationName: 'Park',
        address: '123 Main St',
        city: 'Warsaw',
        latitude: 52.0,
        longitude: 21.0,
        price: 50.0,
        currency: 'PLN',
        capacity: 20,
        enrolledCount: 5,
        category: 'Fitness',
        imageUrl: 'https://example.com/img.jpg',
        isPromoted: true,
        status: EventStatus.approved,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Event');
      _verifyTimestampField(json, 'start_time');
      _verifyTimestampField(json, 'end_time');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyEnumStringField(json, 'status');
      _verifyBoolField(json, 'is_promoted');
      _verifyDoubleField(json, 'latitude');
      _verifyDoubleField(json, 'longitude');
      _verifyDoubleField(json, 'price');
      _verifyIntField(json, 'capacity');
      _verifyIntField(json, 'enrolled_count');
    });
  });

  // ===========================================================================
  //  EventBooking
  // ===========================================================================
  group('EventBooking', () {
    test('toJson() produces correct format', () {
      final obj = EventBooking(
        id: 'eb-1',
        eventId: 'ev-1',
        userId: 'u-1',
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
        amountPaid: 50.0,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'EventBooking');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyDoubleField(json, 'amount_paid');
    });
  });

  // ===========================================================================
  //  Exercise
  // ===========================================================================
  group('Exercise', () {
    test('toJson() produces correct format', () {
      final obj = Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        category: 'Strength',
        description: 'Lie down and press',
        videoUrl: 'https://example.com/vid.mp4',
        imageUrl: 'https://example.com/img.jpg',
        createdById: 'tr-1',
        recommendedRestSeconds: 90,
        isUnilateral: false,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Exercise');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'is_unilateral');
      _verifyIntField(json, 'recommended_rest_seconds');
    });
  });

  // ===========================================================================
  //  ExternalLink
  // ===========================================================================
  group('ExternalLink', () {
    test('toJson() produces correct format', () {
      final obj = ExternalLink(
        id: 'el-1',
        profileId: 'p-1',
        linkUrl: 'https://example.com',
        label: 'My Website',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'ExternalLink');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  HabitLog
  // ===========================================================================
  group('HabitLog', () {
    test('toJson() produces correct format', () {
      final obj = HabitLog(
        id: 'hl-1',
        habitId: 'dh-1',
        clientId: 'c-1',
        date: _dt,
        isCompleted: true,
        note: 'Done!',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'HabitLog');
      _verifyTimestampField(json, 'date');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyBoolField(json, 'is_completed');
    });
  });

  // ===========================================================================
  //  Location
  // ===========================================================================
  group('Location', () {
    test('toJson() produces correct format', () {
      final obj = Location(
        id: 'loc-1',
        profileId: 'p-1',
        address: '123 Main St',
        normalizedAddress: '123 Main St, Warsaw',
        latitude: 52.0,
        longitude: 21.0,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Location');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyDoubleField(json, 'latitude');
      _verifyDoubleField(json, 'longitude');
    });
  });

  // ===========================================================================
  //  Message
  // ===========================================================================
  group('Message', () {
    test('toJson() produces correct format', () {
      final obj = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'u-1',
        content: 'Hello!',
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: 'image',
        isSystemMessage: false,
        workoutSessionId: 'ws-1',
        readAt: _dt,
        createdAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Message');
      _verifyTimestampField(json, 'read_at');
      _verifyTimestampField(json, 'created_at');
      _verifyBoolField(json, 'is_system_message');
    });
  });

  // ===========================================================================
  //  Notification (notification_model.dart)
  // ===========================================================================
  group('Notification', () {
    test('toJson() produces correct format', () {
      final obj = Notification(
        id: 'notif-1',
        userId: 'u-1',
        message: 'You have a new booking',
        type: 'booking',
        readStatus: false,
        metadata: {'booking_id': 'b-1'},
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Notification');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'read_status');
      expect(json['metadata'], isA<Map>());
    });
  });

  // ===========================================================================
  //  Package
  // ===========================================================================
  group('Package', () {
    test('toJson() produces correct format', () {
      final obj = Package(
        id: 'pkg-1',
        name: '10 Sessions',
        description: 'Best value',
        price: 200.0,
        numberOfSessions: 10,
        isActive: true,
        stripeProductId: 'prod_123',
        stripePriceId: 'price_123',
        trainerId: 'tr-1',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Package');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'is_active');
      _verifyDoubleField(json, 'price');
      _verifyIntField(json, 'number_of_sessions');
    });
  });

  // ===========================================================================
  //  PersonalRecord
  // ===========================================================================
  group('PersonalRecord', () {
    test('toJson() produces correct format', () {
      final obj = PersonalRecord(
        id: 'pr-1',
        clientId: 'c-1',
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        recordType: '1RM',
        value: 100.0,
        achievedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'PersonalRecord');
      _verifyTimestampField(json, 'achieved_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyDoubleField(json, 'value');
    });
  });

  // ===========================================================================
  //  Product
  // ===========================================================================
  group('Product', () {
    test('toJson() produces correct format', () {
      const obj = Product(
        id: 'prod-1',
        recipeId: 'rec-1',
        name: 'Whey Protein',
        brand: 'BrandX',
        amount: '30g',
        isRecommended: true,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Product');
      _verifyBoolField(json, 'is_recommended');
      // No timestamps in Product
      expect(json.keys, containsAll(['id', 'recipe_id', 'name', 'brand', 'amount', 'is_recommended']));
    });
  });

  // ===========================================================================
  //  Profile
  // ===========================================================================
  group('Profile', () {
    test('toJson() produces correct format', () {
      final obj = Profile(
        id: 'prof-1',
        userId: 'u-1',
        certifications: 'CPT',
        phone: '+48123456789',
        aboutMe: 'Fitness coach',
        philosophy: 'No pain no gain',
        methodology: 'Progressive overload',
        branding: 'Beast mode',
        bannerImagePath: '/banners/bg.jpg',
        customDomain: 'coach.example.com',
        domainVerified: true,
        profilePhotoPath: '/photos/profile.jpg',
        specialties: ['Weight loss', 'Muscle gain'],
        trainingTypes: [TrainingType.inPerson, TrainingType.online],
        businessCurrency: 'USD',
        averageRating: 4.5,
        completionPercentage: 80,
        missingFields: ['availability'],
        isVerified: true,
        availability: {'monday': '9-17'},
        minServicePrice: 50.0,
        location: 'Warsaw',
        locationNormalized: 'Warsaw, Poland',
        latitude: 52.0,
        longitude: 21.0,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Profile');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'domain_verified');
      _verifyBoolField(json, 'is_verified');
      _verifyListField(json, 'specialties');
      _verifyListField(json, 'training_types');
      _verifyDoubleField(json, 'average_rating');
      _verifyDoubleField(json, 'min_service_price');
      _verifyDoubleField(json, 'latitude');
      _verifyDoubleField(json, 'longitude');
      _verifyIntField(json, 'completion_percentage');
      // training_types items should be enum strings (UPPER_SCREAMING_CASE)
      for (final tt in json['training_types'] as List) {
        expect(tt, isA<String>());
        expect(tt, matches(RegExp(r'^[A-Z][A-Z0-9_]*$')));
      }
      // Optional list fields
      if (json.containsKey('missing_fields') && json['missing_fields'] != null) {
        expect(json['missing_fields'], isA<List>());
      }
    });
  });

  // ===========================================================================
  //  Recipe
  // ===========================================================================
  group('Recipe', () {
    test('toJson() produces correct format', () {
      final obj = Recipe(
        id: 'rec-1',
        trainerId: 'tr-1',
        name: 'Protein Shake',
        description: 'Quick post-workout',
        instructions: 'Mix and drink',
        proteinG: 30.0,
        carbsG: 20.0,
        fatG: 5.0,
        calories: 250,
        difficulty: 'easy',
        prepTime: 5,
        cookTime: 0,
        isPublished: true,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Recipe');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'is_published');
      _verifyDoubleField(json, 'protein_g');
      _verifyDoubleField(json, 'carbs_g');
      _verifyDoubleField(json, 'fat_g');
      _verifyIntField(json, 'calories');
      _verifyIntField(json, 'prep_time');
      _verifyIntField(json, 'cook_time');
    });
  });

  // ===========================================================================
  //  RecipeTag
  // ===========================================================================
  group('RecipeTag', () {
    test('toJson() produces correct format', () {
      const obj = RecipeTag(
        id: 'rt-1',
        recipeId: 'rec-1',
        name: 'high-protein',
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'RecipeTag');
      // No timestamps in RecipeTag
      expect(json.keys, containsAll(['id', 'recipe_id', 'name']));
    });
  });

  // ===========================================================================
  //  Resource
  // ===========================================================================
  group('Resource', () {
    test('toJson() produces correct format', () {
      final obj = Resource(
        id: 'res-1',
        trainerId: 'tr-1',
        title: 'Workout Plan',
        description: 'Full body PDF',
        fileUrl: 'https://example.com/plan.pdf',
        fileType: 'pdf',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Resource');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  Service
  // ===========================================================================
  group('Service', () {
    test('toJson() produces correct format', () {
      final obj = Service(
        id: 'svc-1',
        profileId: 'p-1',
        title: '1-on-1 Training',
        description: 'Personal training session',
        price: 100.0,
        currency: 'PLN',
        duration: 60,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Service');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyDoubleField(json, 'price');
      _verifyIntField(json, 'duration');
    });
  });

  // ===========================================================================
  //  SocialLink
  // ===========================================================================
  group('SocialLink', () {
    test('toJson() produces correct format', () {
      final obj = SocialLink(
        id: 'sl-1',
        profileId: 'p-1',
        platform: 'instagram',
        username: '@coach',
        profileUrl: 'https://instagram.com/coach',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SocialLink');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  SupportTicket
  // ===========================================================================
  group('SupportTicket', () {
    test('toJson() produces correct format', () {
      final obj = SupportTicket(
        id: 'st-1',
        userId: 'u-1',
        category: SupportTicketCategory.bugReport,
        message: 'App crashes on login',
        appVersion: '1.0.0',
        osVersion: 'iOS 17',
        status: 'OPEN',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SupportTicket');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyEnumStringField(json, 'category');
    });
  });

  // ===========================================================================
  //  SystemError
  // ===========================================================================
  group('SystemError', () {
    test('toJson() produces correct format', () {
      final obj = SystemError(
        id: 'err-1',
        message: 'Null pointer',
        stack: 'line 42',
        path: '/api/test',
        method: 'GET',
        statusCode: 500,
        userId: 'u-1',
        isRead: false,
        errorType: 'NullError',
        severity: 'critical',
        metadata: {'detail': 'something'},
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SystemError');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyBoolField(json, 'is_read');
      _verifyIntField(json, 'status_code');
    });
  });

  // ===========================================================================
  //  SystemSetting
  // ===========================================================================
  group('SystemSetting', () {
    test('toJson() produces correct format', () {
      final obj = SystemSetting(
        key: 'maintenance_mode',
        value: 'false',
        description: 'Enable maintenance',
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SystemSetting');
      _verifyTimestampField(json, 'updated_at');
      // Note: 'key' is not snake_case per se but is a single lowercase word
      // which is allowed by our regex. The field naming in the model uses
      // the literal JSON key name 'key' directly from the backend.
    });
  });

  // ===========================================================================
  //  TemplateExercise
  // ===========================================================================
  group('TemplateExercise', () {
    test('toJson() produces correct format', () {
      final obj = TemplateExercise(
        id: 'te-1',
        templateId: 'wt-1',
        type: StepType.exercise,
        exerciseId: 'ex-1',
        targetReps: '8-12',
        targetRIR: 1,
        tempo: '2-0-2-0',
        enableRpe: true,
        durationSeconds: 60,
        notes: 'Focus on form',
        order: 1,
        supersetGroupId: 'ss-1',
        supersetOrder: 1,
        targetSets: 3,
        targetRest: 90,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'TemplateExercise');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyBoolField(json, 'enable_rpe');
      _verifyIntField(json, 'order');
      _verifyIntField(json, 'target_rir');
      _verifyIntField(json, 'duration_seconds');
      _verifyIntField(json, 'superset_order');
      _verifyIntField(json, 'target_sets');
      _verifyIntField(json, 'target_rest');
      // type is nullable StepType enum -> String or null
      if (json['type'] != null) {
        expect(json['type'], isA<String>());
        expect(json['type'], matches(RegExp(r'^[A-Z][A-Z0-9_]*$')));
      }
    });
  });

  // ===========================================================================
  //  Testimonial
  // ===========================================================================
  group('Testimonial', () {
    test('toJson() produces correct format', () {
      final obj = Testimonial(
        id: 'tm-1',
        profileId: 'p-1',
        clientName: 'John Doe',
        testimonialText: 'Great coach!',
        rating: 5,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'Testimonial');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyIntField(json, 'rating');
    });
  });

  // ===========================================================================
  //  TransformationPhoto
  // ===========================================================================
  group('TransformationPhoto', () {
    test('toJson() produces correct format', () {
      final obj = TransformationPhoto(
        id: 'tp-1',
        profileId: 'p-1',
        imagePath: '/photos/transform.jpg',
        caption: '3 month progress',
        clientName: 'John',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'TransformationPhoto');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  User
  // ===========================================================================
  group('User', () {
    test('toJson() produces correct format', () {
      final obj = User(
        id: 'u-1',
        name: 'Test Trainer',
        email: 'trainer@ziro.fit',
        username: 'testtrainer',
        role: 'trainer',
        emailVerifiedAt: _dt,
        defaultCheckInDay: 1,
        defaultCheckInHour: 9,
        tier: UserTier.pro,
        subscriptionStatus: 'active',
        trialEndsAt: _dt,
        hasCompletedOnboarding: true,
        stripeCustomerId: 'cus_123',
        stripeSubscriptionId: 'sub_123',
        stripeSubscriptionStatus: 'active',
        stripeConnectAccountId: 'acct_123',
        weightUnit: WeightUnit.kg,
        pushTokens: ['token1', 'token2'],
        stripeCancelAtPeriodEnd: false,
        stripeCurrentPeriodEnd: _dt,
        stripeCancelAt: null,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'User');
      _verifyTimestampField(json, 'email_verified_at');
      _verifyTimestampField(json, 'trial_ends_at');
      _verifyTimestampField(json, 'stripe_current_period_end');
      _verifyTimestampField(json, 'stripe_cancel_at');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyBoolField(json, 'has_completed_onboarding');
      _verifyBoolField(json, 'stripe_cancel_at_period_end');
      _verifyListField(json, 'push_tokens');
      _verifyEnumStringField(json, 'tier');
      _verifyEnumStringField(json, 'weight_unit');
      _verifyIntField(json, 'default_check_in_day');
      _verifyIntField(json, 'default_check_in_hour');
      // push_tokens should be a List<String>
      expect(json['push_tokens'], isA<List>());
    });
  });

  // ===========================================================================
  //  WorkoutProgram
  // ===========================================================================
  group('WorkoutProgram', () {
    test('toJson() produces correct format', () {
      final obj = WorkoutProgram(
        id: 'wp-1',
        name: 'Beginner Program',
        description: 'Great for starters',
        trainerId: 'tr-1',
        category: 'Strength',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'WorkoutProgram');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  WorkoutSession
  // ===========================================================================
  group('WorkoutSession', () {
    test('toJson() produces correct format', () {
      final obj = WorkoutSession(
        id: 'ws-1',
        clientId: 'c-1',
        name: 'Morning Workout',
        startTime: _dt,
        endTime: _dt,
        status: WorkoutSessionStatus.completed,
        notes: 'Great session',
        restStartedAt: _dt,
        workoutTemplateId: 'wt-1',
        plannedDate: _dt,
        clientPackageId: 'pkg-1',
        isTrainerLed: true,
        reminderTime: _dt,
        trainerReminderSent: true,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'WorkoutSession');
      _verifyTimestampField(json, 'start_time');
      _verifyTimestampField(json, 'end_time');
      _verifyTimestampField(json, 'rest_started_at');
      _verifyTimestampField(json, 'planned_date');
      _verifyTimestampField(json, 'reminder_time');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyEnumStringField(json, 'status');
      _verifyBoolField(json, 'is_trainer_led');
      _verifyBoolField(json, 'trainer_reminder_sent');
    });
  });

  // ===========================================================================
  //  WorkoutSessionComment
  // ===========================================================================
  group('WorkoutSessionComment', () {
    test('toJson() produces correct format', () {
      final obj = WorkoutSessionComment(
        id: 'wsc-1',
        text: 'Great job!',
        workoutSessionId: 'ws-1',
        userId: 'u-1',
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'WorkoutSessionComment');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
    });
  });

  // ===========================================================================
  //  WorkoutTemplate
  // ===========================================================================
  group('WorkoutTemplate', () {
    test('toJson() produces correct format', () {
      final obj = WorkoutTemplate(
        id: 'wt-1',
        name: 'Full Body',
        description: 'Full body workout',
        programId: 'prog-1',
        order: 1,
        createdAt: _dt,
        updatedAt: _dt,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'WorkoutTemplate');
      _verifyTimestampField(json, 'created_at');
      _verifyTimestampField(json, 'updated_at');
      _verifyTimestampField(json, 'deleted_at');
      _verifyIntField(json, 'order');
    });
  });

  // ===========================================================================
  //  SyncChanges (sync_models.dart)
  //
  //  NOTE: SyncChanges.toJson() produces a flat map with keys "created",
  //  "updated", and "deleted". These keys are already snake_case. The values
  //  are nested lists/objects, not flat scalar fields like other models.
  // ===========================================================================
  group('SyncChanges', () {
    test('toJson() produces correct format', () {
      const obj = SyncChanges(
        created: [{'id': '1', 'name': 'new'}],
        updated: [{'id': '2', 'name': 'changed'}],
        deleted: ['3', '4'],
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SyncChanges');
      _verifyListField(json, 'created');
      _verifyListField(json, 'updated');
      _verifyListField(json, 'deleted');
      // Verify the nested structure: created/updated are List<Map>, deleted is List<String>
      expect(json['created'], isA<List>());
      expect(json['updated'], isA<List>());
      expect(json['deleted'], isA<List>());
      for (final item in json['created'] as List) {
        expect(item, isA<Map<String, dynamic>>());
      }
      for (final item in json['deleted'] as List) {
        expect(item, isA<String>());
      }
    });
  });

  // ===========================================================================
  //  SyncPayload (sync_models.dart)
  //
  //  NOTE: SyncPayload.toJson() produces nested "changes" map and "timestamp"
  //  int field. The "changes" value is a Map<String, Map<String, dynamic>>
  //  (from SyncChanges.toJson()), not a flat field. The "timestamp" is an int
  //  representing Unix ms.
  // ===========================================================================
  group('SyncPayload', () {
    test('toJson() produces correct format', () {
      const obj = SyncPayload(
        changes: {
          'exercises': SyncChanges(
            created: [{'id': 'ex-1'}],
          ),
        },
        timestamp: _ms,
      );
      final json = obj.toJson();
      _verifySnakeCaseKeys(json, 'SyncPayload');
      _verifyTimestampField(json, 'timestamp');
      expect(json['timestamp'], _ms);
      expect(json['changes'], isA<Map>());
      // Verify nested changes structure
      final changes = json['changes'] as Map<String, dynamic>;
      expect(changes.containsKey('exercises'), isTrue);
      expect(changes['exercises'], isA<Map<String, dynamic>>());
      final exercisesChanges = changes['exercises'] as Map<String, dynamic>;
      _verifySnakeCaseKeys(exercisesChanges, 'SyncChanges (nested)');
    });
  });
}
