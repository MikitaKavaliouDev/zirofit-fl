// -----------------------------------------------------------------------------
// Comprehensive round-trip serialization tests for ALL data models.
//
// Every test verifies:
//   1. toJson() produces snake_case JSON keys with int (Unix ms) timestamps
//   2. fromJson() can parse that same output back to an equal instance
//   3. Nullable fields survive null / missing-key / absent-value
//   4. Empty-list defaults are applied correctly
//   5. (Tier 1) camelCase + ISO 8601 alternate payloads also parse correctly
//   6. (WorkoutSession / ClientExerciseLog) nested client object fallback
//
// Backend convention:
//   - JSON keys are snake_case
//   - Timestamps are int (Unix milliseconds)
//   - Lists are omitted on wire when empty → Dart defaults to []
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

void main() {
  // ===========================================================================
  //  ENUMS — serialise to wire (UPPER_SCREAMING) and back
  // ===========================================================================
  group('BookingStatus', () {
    for (final value in BookingStatus.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(BookingStatus.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('EventStatus', () {
    for (final value in EventStatus.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(EventStatus.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('HabitFrequency', () {
    for (final value in HabitFrequency.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(HabitFrequency.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('StepType', () {
    for (final value in StepType.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(StepType.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('SupportTicketCategory', () {
    for (final value in SupportTicketCategory.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(
          SupportTicketCategory.fromJson(value.toJson()),
          equals(value),
        );
      });
    }
  });

  group('TrainingType', () {
    for (final value in TrainingType.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(TrainingType.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('UserTier', () {
    for (final value in UserTier.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(UserTier.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('WeightUnit', () {
    for (final value in WeightUnit.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(WeightUnit.fromJson(value.toJson()), equals(value));
      });
    }
  });

  group('WorkoutSessionStatus', () {
    for (final value in WorkoutSessionStatus.values) {
      test('toJson/fromJson round-trip for ${value.name}', () {
        expect(
          WorkoutSessionStatus.fromJson(value.toJson()),
          equals(value),
        );
      });
    }
  });

  // ===========================================================================
  //  Assessment
  //  Backend: {"id","name","description","unit","trainer_id","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Assessment', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final a = Assessment(
        id: 'a-1',
        name: 'Sit & Reach',
        description: 'Flexibility test',
        unit: 'cm',
        trainerId: 'trainer-1',
        createdAt: t,
        updatedAt: t,
      );
      expect(Assessment.fromJson(a.toJson()), equals(a));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"a-1","name":"Sit & Reach","description":"Flexibility test","unit":"cm","trainer_id":"trainer-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'a-1',
        'name': 'Sit & Reach',
        'unit': 'cm',
        'created_at': ms,
        'updated_at': ms,
      };
      final a = Assessment.fromJson(json);
      expect(a.id, 'a-1');
      expect(a.name, 'Sit & Reach');
      expect(a.unit, 'cm');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'a-2',
        'name': 'Push-up Test',
        'unit': 'reps',
        'created_at': ms,
        'updated_at': ms,
      };
      final a = Assessment.fromJson(json);
      expect(a.description, isNull);
      expect(a.trainerId, isNull);
      expect(a.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  AssessmentResult
  //  Backend: {"id","assessment_id","client_id","value","date","notes","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('AssessmentResult', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final ar = AssessmentResult(
        id: 'ar-1',
        assessmentId: 'a-1',
        clientId: 'c-1',
        value: 25.5,
        date: t,
        notes: 'Good effort',
        createdAt: t,
        updatedAt: t,
      );
      expect(AssessmentResult.fromJson(ar.toJson()), equals(ar));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"ar-1","assessment_id":"a-1","client_id":"c-1","value":25.5,"date":1700000000000,"notes":"Good effort","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'ar-1',
        'assessment_id': 'a-1',
        'client_id': 'c-1',
        'value': 25.5,
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ar = AssessmentResult.fromJson(json);
      expect(ar.id, 'ar-1');
      expect(ar.value, 25.5);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ar-2',
        'assessment_id': 'a-2',
        'client_id': 'c-2',
        'value': 30.0,
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ar = AssessmentResult.fromJson(json);
      expect(ar.notes, isNull);
      expect(ar.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  Benefit
  //  Backend: {"id","profile_id","icon_name","icon_style","title","description","order_column","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Benefit', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final b = Benefit(
        id: 'b-1',
        profileId: 'p-1',
        iconName: 'dumbbell',
        iconStyle: 'fas',
        title: 'Free Weights',
        description: 'Full access',
        orderColumn: 1,
        createdAt: t,
        updatedAt: t,
      );
      expect(Benefit.fromJson(b.toJson()), equals(b));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"b-1","profile_id":"p-1","icon_name":"dumbbell","icon_style":"fas","title":"Free Weights","description":"Full access","order_column":1,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'b-1',
        'profile_id': 'p-1',
        'title': 'Free Weights',
        'created_at': ms,
        'updated_at': ms,
      };
      final b = Benefit.fromJson(json);
      expect(b.id, 'b-1');
      expect(b.title, 'Free Weights');
      expect(b.orderColumn, 0); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'b-2',
        'profile_id': 'p-2',
        'title': 'Yoga Mats',
        'created_at': ms,
        'updated_at': ms,
      };
      final b = Benefit.fromJson(json);
      expect(b.iconName, isNull);
      expect(b.iconStyle, isNull);
      expect(b.description, isNull);
      expect(b.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  BlogPost
  //  Backend: {"id","title","slug","content","excerpt","cover_image","published","author_id","created_at","updated_at","published_at"}
  // ===========================================================================
  group('BlogPost', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final bp = BlogPost(
        id: 'bp-1',
        title: 'My Post',
        slug: 'my-post',
        content: 'Hello world',
        excerpt: 'A teaser',
        coverImage: 'https://example.com/img.jpg',
        published: true,
        authorId: 'auth-1',
        createdAt: t,
        updatedAt: t,
        publishedAt: t,
      );
      expect(BlogPost.fromJson(bp.toJson()), equals(bp));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"bp-1","title":"My Post","slug":"my-post","content":"Hello world","author_id":"auth-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'bp-1',
        'title': 'My Post',
        'slug': 'my-post',
        'content': 'Hello world',
        'author_id': 'auth-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final bp = BlogPost.fromJson(json);
      expect(bp.title, 'My Post');
      expect(bp.published, false); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'bp-2',
        'title': 'Second Post',
        'slug': 'second-post',
        'content': 'More content',
        'author_id': 'auth-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final bp = BlogPost.fromJson(json);
      expect(bp.excerpt, isNull);
      expect(bp.coverImage, isNull);
      expect(bp.publishedAt, isNull);
    });
  });

  // ===========================================================================
  //  Booking
  //  Backend: {"id","start_time","end_time","status","data_sharing_approved","data_sharing_approved_at","trainer_id","client_id","client_name","client_email","client_notes","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Booking', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final b = Booking(
        id: 'b-1',
        startTime: t,
        endTime: t,
        status: BookingStatus.confirmed,
        dataSharingApproved: true,
        dataSharingApprovedAt: t,
        trainerId: 'tr-1',
        clientId: 'cl-1',
        clientName: 'John',
        clientEmail: 'john@test.com',
        clientNotes: 'First session',
        createdAt: t,
        updatedAt: t,
      );
      expect(Booking.fromJson(b.toJson()), equals(b));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"b-1","start_time":1700000000000,"end_time":1700000000000,"status":"CONFIRMED","trainer_id":"tr-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'b-1',
        'start_time': ms,
        'end_time': ms,
        'status': 'CONFIRMED',
        'trainer_id': 'tr-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final b = Booking.fromJson(json);
      expect(b.status, BookingStatus.confirmed);
      expect(b.trainerId, 'tr-1');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'b-2',
        'start_time': ms,
        'end_time': ms,
        'trainer_id': 'tr-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final b = Booking.fromJson(json);
      expect(b.clientId, isNull);
      expect(b.clientName, isNull);
      expect(b.clientEmail, isNull);
      expect(b.clientNotes, isNull);
      expect(b.dataSharingApproved, isNull);
      expect(b.dataSharingApprovedAt, isNull);
      expect(b.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  CheckIn
  //  Backend: {"id","client_id","date","status","weight","waist_cm","sleep_hours","energy_level","stress_level","hunger_level","digestion_level","nutrition_compliance","client_notes","trainer_response","reviewed_at","reviewed_by_user_id","created_at","updated_at"}
  // ===========================================================================
  group('CheckIn', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final ci = CheckIn(
        id: 'ci-1',
        clientId: 'c-1',
        date: t,
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
        reviewedAt: t,
        reviewedByUserId: 'tr-1',
        createdAt: t,
        updatedAt: t,
      );
      expect(CheckIn.fromJson(ci.toJson()), equals(ci));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"ci-1","client_id":"c-1","date":1700000000000,"status":"SUBMITTED","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'ci-1',
        'client_id': 'c-1',
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ci = CheckIn.fromJson(json);
      expect(ci.clientId, 'c-1');
      expect(ci.status, 'SUBMITTED');
      expect(ci.weight, isNull);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ci-2',
        'client_id': 'c-2',
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ci = CheckIn.fromJson(json);
      expect(ci.weight, isNull);
      expect(ci.waistCm, isNull);
      expect(ci.sleepHours, isNull);
      expect(ci.energyLevel, isNull);
      expect(ci.stressLevel, isNull);
      expect(ci.hungerLevel, isNull);
      expect(ci.digestionLevel, isNull);
      expect(ci.nutritionCompliance, isNull);
      expect(ci.clientNotes, isNull);
      expect(ci.trainerResponse, isNull);
      expect(ci.reviewedAt, isNull);
      expect(ci.reviewedByUserId, isNull);
    });
  });

  // ===========================================================================
  //  Client (client_model.dart)
  //  Backend: {"id","trainer_id","user_id","name","email","phone","avatar_path","status","date_of_birth","goals","health_notes","emergency_contact_name","emergency_contact_phone","check_in_day","check_in_hour","data_sharing_expires_at","sharing_settings","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Client', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final c = Client(
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
        dataSharingExpiresAt: t,
        sharingSettings: {'show_weight': true},
        createdAt: t,
        updatedAt: t,
      );
      expect(Client.fromJson(c.toJson()), equals(c));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cl-1","name":"John Doe","status":"active","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'cl-1',
        'name': 'John Doe',
        'created_at': ms,
        'updated_at': ms,
      };
      final c = Client.fromJson(json);
      expect(c.id, 'cl-1');
      expect(c.status, 'active');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'cl-2',
        'name': 'Jane',
        'created_at': ms,
        'updated_at': ms,
      };
      final c = Client.fromJson(json);
      expect(c.trainerId, isNull);
      expect(c.userId, isNull);
      expect(c.email, isNull);
      expect(c.phone, isNull);
      expect(c.avatarPath, isNull);
      expect(c.dateOfBirth, isNull);
      expect(c.goals, isNull);
      expect(c.healthNotes, isNull);
      expect(c.emergencyContactName, isNull);
      expect(c.emergencyContactPhone, isNull);
      expect(c.checkInDay, isNull);
      expect(c.checkInHour, isNull);
      expect(c.dataSharingExpiresAt, isNull);
      expect(c.sharingSettings, isNull);
      expect(c.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  ClientExerciseLog  (Tier 1 — also test camelCase/ISO 8601 + nested client)
  //  Backend: {"id","client_id","exercise_id","reps","weight","is_completed","order","tempo","side","workout_session_id","superset_key","order_in_superset","sets","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ClientExerciseLog', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final log = ClientExerciseLog(
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
        createdAt: t,
        updatedAt: t,
      );
      expect(ClientExerciseLog.fromJson(log.toJson()), equals(log));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"log-1","client_id":"cl-1","exercise_id":"ex-1","workout_session_id":"ws-1","side":"LEFT","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'log-1',
        'client_id': 'cl-1',
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final log = ClientExerciseLog.fromJson(json);
      expect(log.clientId, 'cl-1');
      expect(log.exerciseId, 'ex-1');
      expect(log.side, 'BOTH'); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'log-2',
        'client_id': 'cl-2',
        'exercise_id': 'ex-2',
        'workout_session_id': 'ws-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final log = ClientExerciseLog.fromJson(json);
      expect(log.reps, isNull);
      expect(log.weight, isNull);
      expect(log.isCompleted, isNull);
      expect(log.order, isNull);
      expect(log.tempo, isNull);
      expect(log.supersetKey, isNull);
      expect(log.orderInSuperset, isNull);
      expect(log.sets, isNull);
      expect(log.deletedAt, isNull);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      // New backend format may send camelCase + ISO 8601 strings
      final json = {
        'id': 'log-camel',
        'clientId': 'cl-camel',
        'exerciseId': 'ex-1',
        'workoutSessionId': 'ws-1',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final log = ClientExerciseLog.fromJson(json);
      expect(log.clientId, 'cl-camel');
      expect(log.createdAt, DateTime(2024, 1, 1));
    });

    test('fromJson handles nested client object (backend format)', () {
      // Backend returns: {"client":{"id":"client-nested"}}
      final json = {
        'id': 'log-nested',
        'client': {'id': 'client-nested'},
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final log = ClientExerciseLog.fromJson(json);
      expect(log.clientId, 'client-nested');
    });

    test('fromJson prefers flat client_id over nested client', () {
      final json = {
        'id': 'log-mixed',
        'client_id': 'client-flat',
        'client': {'id': 'client-nested'},
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final log = ClientExerciseLog.fromJson(json);
      expect(log.clientId, 'client-flat');
    });
  });

  // ===========================================================================
  //  ClientMeasurement
  //  Backend: {"id","client_id","measurement_date","weight_kg","body_fat_percentage","notes","custom_metrics","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ClientMeasurement', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final cm = ClientMeasurement(
        id: 'cm-1',
        clientId: 'c-1',
        measurementDate: DateTime(2024, 1, 1),
        weightKg: 75.0,
        bodyFatPercentage: 15.5,
        notes: 'Morning measurement',
        customMetrics: [{'name': 'chest', 'value': 100}],
        createdAt: t,
        updatedAt: t,
      );
      expect(ClientMeasurement.fromJson(cm.toJson()), equals(cm));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cm-1","client_id":"c-1","measurement_date":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'cm-1',
        'client_id': 'c-1',
        'measurement_date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final cm = ClientMeasurement.fromJson(json);
      expect(cm.clientId, 'c-1');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'cm-2',
        'client_id': 'c-2',
        'measurement_date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final cm = ClientMeasurement.fromJson(json);
      expect(cm.weightKg, isNull);
      expect(cm.bodyFatPercentage, isNull);
      expect(cm.notes, isNull);
      expect(cm.customMetrics, isNull);
      expect(cm.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  ClientPackage
  //  Backend: {"id","client_id","package_id","sessions_remaining","purchase_date","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ClientPackage', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final cp = ClientPackage(
        id: 'cp-1',
        clientId: 'c-1',
        packageId: 'pkg-1',
        sessionsRemaining: 10,
        purchaseDate: t,
        createdAt: t,
        updatedAt: t,
      );
      expect(ClientPackage.fromJson(cp.toJson()), equals(cp));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cp-1","client_id":"c-1","package_id":"pkg-1","sessions_remaining":10,"purchase_date":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'cp-1',
        'client_id': 'c-1',
        'package_id': 'pkg-1',
        'purchase_date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final cp = ClientPackage.fromJson(json);
      expect(cp.sessionsRemaining, 0); // default
    });
  });

  // ===========================================================================
  //  ClientProgramAssignment
  //  Backend: {"id","client_id","program_id","start_date","is_active","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ClientProgramAssignment', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final cpa = ClientProgramAssignment(
        id: 'cpa-1',
        clientId: 'c-1',
        programId: 'prog-1',
        startDate: t,
        isActive: true,
        createdAt: t,
        updatedAt: t,
      );
      expect(ClientProgramAssignment.fromJson(cpa.toJson()), equals(cpa));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cpa-1","client_id":"c-1","program_id":"prog-1","start_date":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'cpa-1',
        'client_id': 'c-1',
        'program_id': 'prog-1',
        'start_date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final cpa = ClientProgramAssignment.fromJson(json);
      expect(cpa.isActive, true); // default
    });
  });

  // ===========================================================================
  //  ClientProgressPhoto
  //  Backend: {"id","client_id","photo_date","image_path","caption","check_in_id","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ClientProgressPhoto', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final cpp = ClientProgressPhoto(
        id: 'cpp-1',
        clientId: 'c-1',
        photoDate: DateTime(2024, 1, 1),
        imagePath: '/photos/front.jpg',
        caption: 'Before photo',
        checkInId: 'ci-1',
        createdAt: t,
        updatedAt: t,
      );
      expect(ClientProgressPhoto.fromJson(cpp.toJson()), equals(cpp));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cpp-1","client_id":"c-1","photo_date":1700000000000,"image_path":"/photos/front.jpg","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'cpp-1',
        'client_id': 'c-1',
        'photo_date': ms,
        'image_path': '/photos/front.jpg',
        'created_at': ms,
        'updated_at': ms,
      };
      final cpp = ClientProgressPhoto.fromJson(json);
      expect(cpp.imagePath, '/photos/front.jpg');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'cpp-2',
        'client_id': 'c-2',
        'photo_date': ms,
        'image_path': '/photos/side.jpg',
        'created_at': ms,
        'updated_at': ms,
      };
      final cpp = ClientProgressPhoto.fromJson(json);
      expect(cpp.caption, isNull);
      expect(cpp.checkInId, isNull);
      expect(cpp.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  ClientResource
  //  Backend: {"id","resource_id","client_id","created_at"}
  // ===========================================================================
  group('ClientResource', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final cr = ClientResource(
        id: 'cr-1',
        resourceId: 'res-1',
        clientId: 'c-1',
        createdAt: t,
      );
      expect(ClientResource.fromJson(cr.toJson()), equals(cr));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"cr-1","resource_id":"res-1","client_id":"c-1","created_at":1700000000000}
      final json = {
        'id': 'cr-1',
        'resource_id': 'res-1',
        'client_id': 'c-1',
        'created_at': ms,
      };
      final cr = ClientResource.fromJson(json);
      expect(cr.resourceId, 'res-1');
      expect(cr.clientId, 'c-1');
    });
  });

  // ===========================================================================
  //  Conversation
  //  Backend: {"id","trainer_id","client_id","last_message_at","created_at","updated_at"}
  // ===========================================================================
  group('Conversation', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final conv = Conversation(
        id: 'conv-1',
        trainerId: 'tr-1',
        clientId: 'c-1',
        lastMessageAt: t,
        createdAt: t,
        updatedAt: t,
      );
      expect(Conversation.fromJson(conv.toJson()), equals(conv));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"conv-1","trainer_id":"tr-1","client_id":"c-1","last_message_at":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'conv-1',
        'trainer_id': 'tr-1',
        'client_id': 'c-1',
        'last_message_at': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final conv = Conversation.fromJson(json);
      expect(conv.trainerId, 'tr-1');
      expect(conv.clientId, 'c-1');
    });
  });

  // ===========================================================================
  //  DailyHabit
  //  Backend: {"id","client_id","trainer_id","title","description","frequency","is_active","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('DailyHabit', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final dh = DailyHabit(
        id: 'dh-1',
        clientId: 'c-1',
        trainerId: 'tr-1',
        title: 'Drink water',
        description: '8 glasses',
        frequency: HabitFrequency.daily,
        isActive: true,
        createdAt: t,
        updatedAt: t,
      );
      expect(DailyHabit.fromJson(dh.toJson()), equals(dh));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"dh-1","client_id":"c-1","trainer_id":"tr-1","title":"Drink water","frequency":"DAILY","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'dh-1',
        'client_id': 'c-1',
        'trainer_id': 'tr-1',
        'title': 'Drink water',
        'created_at': ms,
        'updated_at': ms,
      };
      final dh = DailyHabit.fromJson(json);
      expect(dh.frequency, HabitFrequency.daily);
      expect(dh.isActive, true);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'dh-2',
        'client_id': 'c-2',
        'trainer_id': 'tr-2',
        'title': 'Exercise',
        'created_at': ms,
        'updated_at': ms,
      };
      final dh = DailyHabit.fromJson(json);
      expect(dh.description, isNull);
      expect(dh.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  Event
  //  Backend: {"id","trainer_id","title","description","start_time","end_time","location_name","address","city","latitude","longitude","price","currency","capacity","enrolled_count","category","image_url","is_promoted","status","rejection_reason","created_at","updated_at"}
  // ===========================================================================
  group('Event', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final e = Event(
        id: 'ev-1',
        trainerId: 'tr-1',
        title: 'Bootcamp',
        description: 'Outdoor session',
        startTime: t,
        endTime: t,
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
        rejectionReason: null,
        createdAt: t,
        updatedAt: t,
      );
      expect(Event.fromJson(e.toJson()), equals(e));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"ev-1","trainer_id":"tr-1","title":"Bootcamp","start_time":1700000000000,"end_time":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'ev-1',
        'trainer_id': 'tr-1',
        'title': 'Bootcamp',
        'start_time': ms,
        'end_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final e = Event.fromJson(json);
      expect(e.title, 'Bootcamp');
      expect(e.status, EventStatus.pending); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ev-2',
        'trainer_id': 'tr-2',
        'title': 'Yoga',
        'start_time': ms,
        'end_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final e = Event.fromJson(json);
      expect(e.description, isNull);
      expect(e.locationName, isNull);
      expect(e.address, isNull);
      expect(e.city, isNull);
      expect(e.latitude, isNull);
      expect(e.longitude, isNull);
      expect(e.category, isNull);
      expect(e.imageUrl, isNull);
      expect(e.rejectionReason, isNull);
    });
  });

  // ===========================================================================
  //  EventBooking
  //  Backend: {"id","event_id","user_id","status","payment_status","amount_paid","created_at","updated_at"}
  // ===========================================================================
  group('EventBooking', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final eb = EventBooking(
        id: 'eb-1',
        eventId: 'ev-1',
        userId: 'u-1',
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
        amountPaid: 50.0,
        createdAt: t,
        updatedAt: t,
      );
      expect(EventBooking.fromJson(eb.toJson()), equals(eb));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"eb-1","event_id":"ev-1","user_id":"u-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'eb-1',
        'event_id': 'ev-1',
        'user_id': 'u-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final eb = EventBooking.fromJson(json);
      expect(eb.status, 'CONFIRMED'); // default
      expect(eb.paymentStatus, 'FREE'); // default
    });
  });

  // ===========================================================================
  //  Exercise  (Tier 1 — also test camelCase/ISO 8601)
  //  Backend: {"id","name","muscle_group","equipment","category","description","video_url","image_url","created_by_id","recommended_rest_seconds","is_unilateral","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Exercise', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final ex = Exercise(
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
        createdAt: t,
        updatedAt: t,
      );
      expect(Exercise.fromJson(ex.toJson()), equals(ex));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"ex-1","name":"Bench Press","muscle_group":"Chest","equipment":"Barbell","category":"Strength","is_unilateral":false,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'ex-1',
        'name': 'Bench Press',
        'muscle_group': 'Chest',
        'equipment': 'Barbell',
        'category': 'Strength',
        'is_unilateral': false,
        'created_at': ms,
        'updated_at': ms,
      };
      final ex = Exercise.fromJson(json);
      expect(ex.muscleGroup, 'Chest');
      expect(ex.equipment, 'Barbell');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ex-2',
        'name': 'Squat',
        'created_at': ms,
        'updated_at': ms,
      };
      final ex = Exercise.fromJson(json);
      expect(ex.muscleGroup, isNull);
      expect(ex.equipment, isNull);
      expect(ex.category, isNull);
      expect(ex.description, isNull);
      expect(ex.videoUrl, isNull);
      expect(ex.imageUrl, isNull);
      expect(ex.createdById, isNull);
      expect(ex.recommendedRestSeconds, isNull);
      expect(ex.deletedAt, isNull);
      expect(ex.isUnilateral, false);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'ex-camel',
        'name': 'Deadlift',
        'muscleGroup': 'Back',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final ex = Exercise.fromJson(json);
      expect(ex.muscleGroup, 'Back');
      expect(ex.createdAt, DateTime(2024, 1, 1));
    });
  });

  // ===========================================================================
  //  ExternalLink
  //  Backend: {"id","profile_id","link_url","label","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('ExternalLink', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final el = ExternalLink(
        id: 'el-1',
        profileId: 'p-1',
        linkUrl: 'https://example.com',
        label: 'My Website',
        createdAt: t,
        updatedAt: t,
      );
      expect(ExternalLink.fromJson(el.toJson()), equals(el));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"el-1","profile_id":"p-1","link_url":"https://example.com","label":"My Website","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'el-1',
        'profile_id': 'p-1',
        'link_url': 'https://example.com',
        'label': 'My Website',
        'created_at': ms,
        'updated_at': ms,
      };
      final el = ExternalLink.fromJson(json);
      expect(el.label, 'My Website');
    });
  });

  // ===========================================================================
  //  HabitLog
  //  Backend: {"id","habit_id","client_id","date","is_completed","note","created_at","updated_at"}
  // ===========================================================================
  group('HabitLog', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final hl = HabitLog(
        id: 'hl-1',
        habitId: 'dh-1',
        clientId: 'c-1',
        date: t,
        isCompleted: true,
        note: 'Done!',
        createdAt: t,
        updatedAt: t,
      );
      expect(HabitLog.fromJson(hl.toJson()), equals(hl));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"hl-1","habit_id":"dh-1","client_id":"c-1","date":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'hl-1',
        'habit_id': 'dh-1',
        'client_id': 'c-1',
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final hl = HabitLog.fromJson(json);
      expect(hl.isCompleted, false); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'hl-2',
        'habit_id': 'dh-2',
        'client_id': 'c-2',
        'date': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final hl = HabitLog.fromJson(json);
      expect(hl.note, isNull);
    });
  });

  // ===========================================================================
  //  Location
  //  Backend: {"id","profile_id","address","normalized_address","latitude","longitude","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Location', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final loc = Location(
        id: 'loc-1',
        profileId: 'p-1',
        address: '123 Main St',
        normalizedAddress: '123 Main St, Warsaw',
        latitude: 52.0,
        longitude: 21.0,
        createdAt: t,
        updatedAt: t,
      );
      expect(Location.fromJson(loc.toJson()), equals(loc));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"loc-1","profile_id":"p-1","address":"123 Main St","normalized_address":"123 Main St, Warsaw","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'loc-1',
        'profile_id': 'p-1',
        'address': '123 Main St',
        'normalized_address': '123 Main St, Warsaw',
        'created_at': ms,
        'updated_at': ms,
      };
      final loc = Location.fromJson(json);
      expect(loc.normalizedAddress, '123 Main St, Warsaw');
    });
  });

  // ===========================================================================
  //  Message
  //  Backend: {"id","conversation_id","sender_id","content","media_url","media_type","is_system_message","workout_session_id","read_at","created_at"}
  // ===========================================================================
  group('Message', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'u-1',
        content: 'Hello!',
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: 'image',
        isSystemMessage: false,
        workoutSessionId: 'ws-1',
        readAt: t,
        createdAt: t,
      );
      expect(Message.fromJson(msg.toJson()), equals(msg));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"msg-1","conversation_id":"conv-1","content":"Hello!","created_at":1700000000000}
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'content': 'Hello!',
        'created_at': ms,
      };
      final msg = Message.fromJson(json);
      expect(msg.content, 'Hello!');
      expect(msg.isSystemMessage, false);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-2',
        'content': 'Hi',
        'created_at': ms,
      };
      final msg = Message.fromJson(json);
      expect(msg.senderId, isNull);
      expect(msg.mediaUrl, isNull);
      expect(msg.mediaType, isNull);
      expect(msg.workoutSessionId, isNull);
      expect(msg.readAt, isNull);
    });
  });

  // ===========================================================================
  //  Notification (notification_model.dart)
  //  Backend: {"id","user_id","message","type","read_status","metadata","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Notification', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final n = Notification(
        id: 'notif-1',
        userId: 'u-1',
        message: 'You have a new booking',
        type: 'booking',
        readStatus: false,
        metadata: {'booking_id': 'b-1'},
        createdAt: t,
        updatedAt: t,
      );
      expect(Notification.fromJson(n.toJson()), equals(n));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"notif-1","user_id":"u-1","message":"You have a new booking","type":"booking","read_status":false,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'notif-1',
        'user_id': 'u-1',
        'message': 'You have a new booking',
        'type': 'booking',
        'created_at': ms,
        'updated_at': ms,
      };
      final n = Notification.fromJson(json);
      expect(n.readStatus, false);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'notif-2',
        'user_id': 'u-2',
        'message': 'Reminder',
        'type': 'reminder',
        'created_at': ms,
        'updated_at': ms,
      };
      final n = Notification.fromJson(json);
      expect(n.metadata, isNull);
      expect(n.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  Package
  //  Backend: {"id","name","description","price","number_of_sessions","is_active","stripe_product_id","stripe_price_id","trainer_id","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Package', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final pkg = Package(
        id: 'pkg-1',
        name: '10 Sessions',
        description: 'Best value',
        price: 200.0,
        numberOfSessions: 10,
        isActive: true,
        stripeProductId: 'prod_123',
        stripePriceId: 'price_123',
        trainerId: 'tr-1',
        createdAt: t,
        updatedAt: t,
      );
      expect(Package.fromJson(pkg.toJson()), equals(pkg));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"pkg-1","name":"10 Sessions","price":200.0,"number_of_sessions":10,"stripe_product_id":"prod_123","stripe_price_id":"price_123","trainer_id":"tr-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'pkg-1',
        'name': '10 Sessions',
        'stripe_product_id': 'prod_123',
        'stripe_price_id': 'price_123',
        'trainer_id': 'tr-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final pkg = Package.fromJson(json);
      expect(pkg.price, 0); // default
      expect(pkg.isActive, true); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'pkg-2',
        'name': '5 Sessions',
        'stripe_product_id': 'prod_456',
        'stripe_price_id': 'price_456',
        'trainer_id': 'tr-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final pkg = Package.fromJson(json);
      expect(pkg.description, isNull);
      expect(pkg.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  PersonalRecord
  //  Backend: {"id","client_id","exercise_id","workout_session_id","record_type","value","achieved_at","deleted_at"}
  // ===========================================================================
  group('PersonalRecord', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final pr = PersonalRecord(
        id: 'pr-1',
        clientId: 'c-1',
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        recordType: '1RM',
        value: 100.0,
        achievedAt: t,
      );
      expect(PersonalRecord.fromJson(pr.toJson()), equals(pr));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"pr-1","client_id":"c-1","exercise_id":"ex-1","workout_session_id":"ws-1","record_type":"1RM","value":100.0,"achieved_at":1700000000000}
      final json = {
        'id': 'pr-1',
        'client_id': 'c-1',
        'exercise_id': 'ex-1',
        'workout_session_id': 'ws-1',
        'record_type': '1RM',
        'value': 100.0,
        'achieved_at': ms,
      };
      final pr = PersonalRecord.fromJson(json);
      expect(pr.recordType, '1RM');
      expect(pr.value, 100.0);
    });
  });

  // ===========================================================================
  //  Product
  //  Backend: {"id","recipe_id","name","brand","amount","is_recommended"}
  // ===========================================================================
  group('Product', () {
    test('toJson -> fromJson round-trip', () {
      final prod = Product(
        id: 'prod-1',
        recipeId: 'rec-1',
        name: 'Whey Protein',
        brand: 'BrandX',
        amount: '30g',
        isRecommended: true,
      );
      expect(Product.fromJson(prod.toJson()), equals(prod));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"prod-1","recipe_id":"rec-1","name":"Whey Protein","brand":"BrandX","amount":"30g","is_recommended":true}
      final json = {
        'id': 'prod-1',
        'recipe_id': 'rec-1',
        'name': 'Whey Protein',
        'is_recommended': true,
      };
      final prod = Product.fromJson(json);
      expect(prod.name, 'Whey Protein');
      expect(prod.isRecommended, true);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'prod-2',
        'recipe_id': 'rec-2',
        'name': 'Creatine',
      };
      final prod = Product.fromJson(json);
      expect(prod.brand, isNull);
      expect(prod.amount, isNull);
      expect(prod.isRecommended, false); // default
    });
  });

  // ===========================================================================
  //  Profile
  //  Backend: {"id","user_id","certifications","phone","about_me","philosophy","methodology","branding","banner_image_path","custom_domain","domain_verified","profile_photo_path","specialties","training_types","business_currency","average_rating","completion_percentage","missing_fields","is_verified","availability","min_service_price","location","location_normalized","latitude","longitude","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Profile', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final p = Profile(
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
        specialties: const ['Weight loss', 'Muscle gain'],
        trainingTypes: const [TrainingType.inPerson, TrainingType.online],
        businessCurrency: 'USD',
        averageRating: 4.5,
        completionPercentage: 80,
        missingFields: ['availability'],
        isVerified: true,
        availability: const {'monday': '9-17'},
        minServicePrice: 50.0,
        location: 'Warsaw',
        locationNormalized: 'Warsaw, Poland',
        latitude: 52.0,
        longitude: 21.0,
        createdAt: t,
        updatedAt: t,
      );
      final restored = Profile.fromJson(p.toJson());
      // Compare serialized output to avoid List/Map identity issues
      expect(restored.toJson(), equals(p.toJson()));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"prof-1","user_id":"u-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'prof-1',
        'user_id': 'u-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final p = Profile.fromJson(json);
      expect(p.userId, 'u-1');
      expect(p.businessCurrency, 'PLN'); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'prof-2',
        'user_id': 'u-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final p = Profile.fromJson(json);
      expect(p.certifications, isNull);
      expect(p.phone, isNull);
      expect(p.aboutMe, isNull);
      expect(p.philosophy, isNull);
      expect(p.methodology, isNull);
      expect(p.branding, isNull);
      expect(p.bannerImagePath, isNull);
      expect(p.customDomain, isNull);
      expect(p.profilePhotoPath, isNull);
      expect(p.averageRating, isNull);
      expect(p.missingFields, isNull);
      expect(p.availability, isNull);
      expect(p.minServicePrice, isNull);
      expect(p.location, isNull);
      expect(p.locationNormalized, isNull);
      expect(p.latitude, isNull);
      expect(p.longitude, isNull);
      expect(p.deletedAt, isNull);
      expect(p.specialties, isEmpty);
      expect(p.trainingTypes, isEmpty);
      expect(p.businessCurrency, 'PLN');
      expect(p.completionPercentage, 0);
      expect(p.isVerified, false);
    });

    test('fromJson parses empty list defaults', () {
      final json = {
        'id': 'prof-3',
        'user_id': 'u-3',
        'created_at': ms,
        'updated_at': ms,
      };
      final p = Profile.fromJson(json);
      expect(p.specialties, isA<List>());
      expect(p.specialties, isEmpty);
      expect(p.trainingTypes, isA<List>());
      expect(p.trainingTypes, isEmpty);
    });

    test('fromJson handles training_types enum parsing', () {
      final json = {
        'id': 'prof-4',
        'user_id': 'u-4',
        'training_types': ['IN_PERSON', 'ONLINE'],
        'created_at': ms,
        'updated_at': ms,
      };
      final p = Profile.fromJson(json);
      expect(p.trainingTypes, contains(TrainingType.inPerson));
      expect(p.trainingTypes, contains(TrainingType.online));
    });
  });

  // ===========================================================================
  //  Recipe
  //  Backend: {"id","trainer_id","name","description","instructions","protein_g","carbs_g","fat_g","calories","difficulty","prep_time","cook_time","is_published","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Recipe', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final r = Recipe(
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
        createdAt: t,
        updatedAt: t,
      );
      expect(Recipe.fromJson(r.toJson()), equals(r));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"rec-1","trainer_id":"tr-1","name":"Protein Shake","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'rec-1',
        'trainer_id': 'tr-1',
        'name': 'Protein Shake',
        'created_at': ms,
        'updated_at': ms,
      };
      final r = Recipe.fromJson(json);
      expect(r.name, 'Protein Shake');
      expect(r.isPublished, false); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'rec-2',
        'trainer_id': 'tr-2',
        'name': 'Oatmeal',
        'created_at': ms,
        'updated_at': ms,
      };
      final r = Recipe.fromJson(json);
      expect(r.description, isNull);
      expect(r.instructions, isNull);
      expect(r.proteinG, isNull);
      expect(r.carbsG, isNull);
      expect(r.fatG, isNull);
      expect(r.calories, isNull);
      expect(r.difficulty, isNull);
      expect(r.prepTime, isNull);
      expect(r.cookTime, isNull);
      expect(r.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  RecipeTag
  //  Backend: {"id","recipe_id","name"}
  // ===========================================================================
  group('RecipeTag', () {
    test('toJson -> fromJson round-trip', () {
      final rt = RecipeTag(
        id: 'rt-1',
        recipeId: 'rec-1',
        name: 'high-protein',
      );
      expect(RecipeTag.fromJson(rt.toJson()), equals(rt));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"rt-1","recipe_id":"rec-1","name":"high-protein"}
      final json = {
        'id': 'rt-1',
        'recipe_id': 'rec-1',
        'name': 'high-protein',
      };
      final rt = RecipeTag.fromJson(json);
      expect(rt.name, 'high-protein');
    });
  });

  // ===========================================================================
  //  Resource
  //  Backend: {"id","trainer_id","title","description","file_url","file_type","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Resource', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final res = Resource(
        id: 'res-1',
        trainerId: 'tr-1',
        title: 'Workout Plan',
        description: 'Full body PDF',
        fileUrl: 'https://example.com/plan.pdf',
        fileType: 'pdf',
        createdAt: t,
        updatedAt: t,
      );
      expect(Resource.fromJson(res.toJson()), equals(res));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"res-1","trainer_id":"tr-1","title":"Workout Plan","file_url":"https://example.com/plan.pdf","file_type":"pdf","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'res-1',
        'trainer_id': 'tr-1',
        'title': 'Workout Plan',
        'file_url': 'https://example.com/plan.pdf',
        'file_type': 'pdf',
        'created_at': ms,
        'updated_at': ms,
      };
      final res = Resource.fromJson(json);
      expect(res.fileType, 'pdf');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'res-2',
        'trainer_id': 'tr-2',
        'title': 'Nutrition Guide',
        'file_url': 'https://example.com/guide.pdf',
        'file_type': 'pdf',
        'created_at': ms,
        'updated_at': ms,
      };
      final res = Resource.fromJson(json);
      expect(res.description, isNull);
      expect(res.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  Service
  //  Backend: {"id","profile_id","title","description","price","currency","duration","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Service', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final s = Service(
        id: 'svc-1',
        profileId: 'p-1',
        title: '1-on-1 Training',
        description: 'Personal training session',
        price: 100.0,
        currency: 'PLN',
        duration: 60,
        createdAt: t,
        updatedAt: t,
      );
      expect(Service.fromJson(s.toJson()), equals(s));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"svc-1","profile_id":"p-1","title":"1-on-1 Training","description":"Personal training session","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'svc-1',
        'profile_id': 'p-1',
        'title': '1-on-1 Training',
        'description': 'Personal training session',
        'created_at': ms,
        'updated_at': ms,
      };
      final s = Service.fromJson(json);
      expect(s.title, '1-on-1 Training');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'svc-2',
        'profile_id': 'p-2',
        'title': 'Group Class',
        'description': 'Small group',
        'created_at': ms,
        'updated_at': ms,
      };
      final s = Service.fromJson(json);
      expect(s.price, isNull);
      expect(s.currency, isNull);
      expect(s.duration, isNull);
      expect(s.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  SocialLink
  //  Backend: {"id","profile_id","platform","username","profile_url","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('SocialLink', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final sl = SocialLink(
        id: 'sl-1',
        profileId: 'p-1',
        platform: 'instagram',
        username: '@coach',
        profileUrl: 'https://instagram.com/coach',
        createdAt: t,
        updatedAt: t,
      );
      expect(SocialLink.fromJson(sl.toJson()), equals(sl));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"sl-1","profile_id":"p-1","platform":"instagram","username":"@coach","profile_url":"https://instagram.com/coach","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'sl-1',
        'profile_id': 'p-1',
        'platform': 'instagram',
        'username': '@coach',
        'profile_url': 'https://instagram.com/coach',
        'created_at': ms,
        'updated_at': ms,
      };
      final sl = SocialLink.fromJson(json);
      expect(sl.platform, 'instagram');
    });
  });

  // ===========================================================================
  //  SupportTicket
  //  Backend: {"id","user_id","category","message","app_version","os_version","status","created_at","updated_at"}
  // ===========================================================================
  group('SupportTicket', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final st = SupportTicket(
        id: 'st-1',
        userId: 'u-1',
        category: SupportTicketCategory.bugReport,
        message: 'App crashes on login',
        appVersion: '1.0.0',
        osVersion: 'iOS 17',
        status: 'OPEN',
        createdAt: t,
        updatedAt: t,
      );
      expect(SupportTicket.fromJson(st.toJson()), equals(st));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"st-1","user_id":"u-1","category":"BUG_REPORT","message":"App crashes on login","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'st-1',
        'user_id': 'u-1',
        'category': 'BUG_REPORT',
        'message': 'App crashes on login',
        'created_at': ms,
        'updated_at': ms,
      };
      final st = SupportTicket.fromJson(json);
      expect(st.category, SupportTicketCategory.bugReport);
      expect(st.status, 'OPEN');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'st-2',
        'user_id': 'u-2',
        'category': 'FEATURE_REQUEST',
        'message': 'Add dark mode',
        'created_at': ms,
        'updated_at': ms,
      };
      final st = SupportTicket.fromJson(json);
      expect(st.appVersion, isNull);
      expect(st.osVersion, isNull);
    });
  });

  // ===========================================================================
  //  SystemError
  //  Backend: {"id","message","stack","path","method","status_code","user_id","is_read","error_type","severity","metadata","created_at","updated_at"}
  // ===========================================================================
  group('SystemError', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final se = SystemError(
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
        createdAt: t,
        updatedAt: t,
      );
      expect(SystemError.fromJson(se.toJson()), equals(se));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"err-1","message":"Null pointer","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'err-1',
        'message': 'Null pointer',
        'created_at': ms,
        'updated_at': ms,
      };
      final se = SystemError.fromJson(json);
      expect(se.message, 'Null pointer');
      expect(se.severity, 'error'); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'err-2',
        'message': 'Timeout',
        'created_at': ms,
        'updated_at': ms,
      };
      final se = SystemError.fromJson(json);
      expect(se.stack, isNull);
      expect(se.path, isNull);
      expect(se.method, isNull);
      expect(se.statusCode, isNull);
      expect(se.userId, isNull);
      expect(se.errorType, isNull);
      expect(se.metadata, isNull);
    });
  });

  // ===========================================================================
  //  SystemSetting
  //  Backend: {"key","value","description","updated_at"}
  // ===========================================================================
  group('SystemSetting', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final ss = SystemSetting(
        key: 'maintenance_mode',
        value: 'false',
        description: 'Enable maintenance',
        updatedAt: t,
      );
      expect(SystemSetting.fromJson(ss.toJson()), equals(ss));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"key":"maintenance_mode","value":"false","description":"Enable maintenance","updated_at":1700000000000}
      final json = {
        'key': 'maintenance_mode',
        'value': 'false',
        'updated_at': ms,
      };
      final ss = SystemSetting.fromJson(json);
      expect(ss.key, 'maintenance_mode');
      expect(ss.value, 'false');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'key': 'app_version',
        'value': '1.0.0',
        'updated_at': ms,
      };
      final ss = SystemSetting.fromJson(json);
      expect(ss.description, isNull);
    });
  });

  // ===========================================================================
  //  TemplateExercise  (Tier 1 — also test camelCase/ISO 8601)
  //  Backend: {"id","template_id","type","exercise_id","target_reps","target_rir","tempo","enable_rpe","duration_seconds","notes","order","superset_group_id","superset_order","target_sets","target_rest","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('TemplateExercise', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final te = TemplateExercise(
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
        createdAt: t,
        updatedAt: t,
      );
      expect(TemplateExercise.fromJson(te.toJson()), equals(te));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"te-1","template_id":"wt-1","type":"EXERCISE","exercise_id":"ex-1","order":1,"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'te-1',
        'template_id': 'wt-1',
        'type': 'EXERCISE',
        'exercise_id': 'ex-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final te = TemplateExercise.fromJson(json);
      expect(te.exerciseId, 'ex-1');
      expect(te.type, StepType.exercise);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'te-2',
        'template_id': 'wt-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final te = TemplateExercise.fromJson(json);
      expect(te.type, isNull);
      expect(te.exerciseId, isNull);
      expect(te.targetReps, isNull);
      expect(te.targetRIR, isNull);
      expect(te.tempo, isNull);
      expect(te.durationSeconds, isNull);
      expect(te.notes, isNull);
      expect(te.supersetGroupId, isNull);
      expect(te.supersetOrder, isNull);
      expect(te.targetSets, isNull);
      expect(te.targetRest, isNull);
      expect(te.deletedAt, isNull);
      expect(te.enableRpe, false);
      expect(te.order, 0);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'te-camel',
        'templateId': 'wt-camel',
        'exerciseId': 'ex-camel',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final te = TemplateExercise.fromJson(json);
      expect(te.templateId, 'wt-camel');
      expect(te.exerciseId, 'ex-camel');
      expect(te.createdAt, DateTime(2024, 1, 1));
    });

    test('fromJson handles empty list defaults for superset fields', () {
      final json = {
        'id': 'te-3',
        'template_id': 'wt-3',
        'created_at': ms,
        'updated_at': ms,
      };
      final te = TemplateExercise.fromJson(json);
      expect(te.supersetOrder, isNull);
      expect(te.supersetGroupId, isNull);
    });
  });

  // ===========================================================================
  //  Testimonial
  //  Backend: {"id","profile_id","client_name","testimonial_text","rating","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('Testimonial', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final tm = Testimonial(
        id: 'tm-1',
        profileId: 'p-1',
        clientName: 'John Doe',
        testimonialText: 'Great coach!',
        rating: 5,
        createdAt: t,
        updatedAt: t,
      );
      expect(Testimonial.fromJson(tm.toJson()), equals(tm));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"tm-1","profile_id":"p-1","client_name":"John Doe","testimonial_text":"Great coach!","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'tm-1',
        'profile_id': 'p-1',
        'client_name': 'John Doe',
        'testimonial_text': 'Great coach!',
        'created_at': ms,
        'updated_at': ms,
      };
      final tm = Testimonial.fromJson(json);
      expect(tm.testimonialText, 'Great coach!');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'tm-2',
        'profile_id': 'p-2',
        'client_name': 'Jane Doe',
        'testimonial_text': 'Amazing',
        'created_at': ms,
        'updated_at': ms,
      };
      final tm = Testimonial.fromJson(json);
      expect(tm.rating, isNull);
      expect(tm.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  TransformationPhoto
  //  Backend: {"id","profile_id","image_path","caption","client_name","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('TransformationPhoto', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final tp = TransformationPhoto(
        id: 'tp-1',
        profileId: 'p-1',
        imagePath: '/photos/transform.jpg',
        caption: '3 month progress',
        clientName: 'John',
        createdAt: t,
        updatedAt: t,
      );
      expect(TransformationPhoto.fromJson(tp.toJson()), equals(tp));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"tp-1","profile_id":"p-1","image_path":"/photos/transform.jpg","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'tp-1',
        'profile_id': 'p-1',
        'image_path': '/photos/transform.jpg',
        'created_at': ms,
        'updated_at': ms,
      };
      final tp = TransformationPhoto.fromJson(json);
      expect(tp.imagePath, '/photos/transform.jpg');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'tp-2',
        'profile_id': 'p-2',
        'image_path': '/photos/progress.jpg',
        'created_at': ms,
        'updated_at': ms,
      };
      final tp = TransformationPhoto.fromJson(json);
      expect(tp.caption, isNull);
      expect(tp.clientName, isNull);
      expect(tp.deletedAt, isNull);
    });
  });

  // ===========================================================================
  //  User
  //  Backend: {"id","name","email","username","role","email_verified_at","default_check_in_day","default_check_in_hour","tier","subscription_status","trial_ends_at","has_completed_onboarding","stripe_customer_id","stripe_subscription_id","stripe_subscription_status","stripe_connect_account_id","weight_unit","push_tokens","stripe_cancel_at_period_end","stripe_current_period_end","stripe_cancel_at","created_at","updated_at"}
  // ===========================================================================
  group('User', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final u = User(
        id: 'u-1',
        name: 'Test Trainer',
        email: 'trainer@ziro.fit',
        username: 'testtrainer',
        role: 'trainer',
        emailVerifiedAt: t,
        defaultCheckInDay: 1,
        defaultCheckInHour: 9,
        tier: UserTier.pro,
        subscriptionStatus: 'active',
        trialEndsAt: t,
        hasCompletedOnboarding: true,
        stripeCustomerId: 'cus_123',
        stripeSubscriptionId: 'sub_123',
        stripeSubscriptionStatus: 'active',
        stripeConnectAccountId: 'acct_123',
        weightUnit: WeightUnit.kg,
        pushTokens: const ['token1', 'token2'],
        stripeCancelAtPeriodEnd: false,
        stripeCurrentPeriodEnd: t,
        stripeCancelAt: null,
        createdAt: t,
        updatedAt: t,
      );
      final restored = User.fromJson(u.toJson());
      // Compare serialized output to avoid List identity issues (pushTokens)
      expect(restored.toJson(), equals(u.toJson()));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"u-1","name":"Test Trainer","email":"trainer@ziro.fit","role":"trainer","tier":"PRO","weight_unit":"KG","push_tokens":[],"created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'u-1',
        'name': 'Test Trainer',
        'email': 'trainer@ziro.fit',
        'username': 'testtrainer',
        'role': 'trainer',
        'tier': 'PRO',
        'has_completed_onboarding': true,
        'weight_unit': 'KG',
        'push_tokens': <String>[],
        'stripe_cancel_at_period_end': false,
        'default_check_in_day': 0,
        'default_check_in_hour': 9,
        'created_at': ms,
        'updated_at': ms,
      };
      final u = User.fromJson(json);
      expect(u.name, 'Test Trainer');
      expect(u.tier, UserTier.pro);
      expect(u.weightUnit, WeightUnit.kg);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'u-2',
        'name': 'Another User',
        'email': 'user@test.com',
        'role': 'client',
        'tier': 'STARTER',
        'weight_unit': 'KG',
        'has_completed_onboarding': false,
        'push_tokens': <String>[],
        'stripe_cancel_at_period_end': false,
        'default_check_in_day': 0,
        'default_check_in_hour': 9,
        'created_at': ms,
        'updated_at': ms,
      };
      final u = User.fromJson(json);
      expect(u.username, isNull);
      expect(u.emailVerifiedAt, isNull);
      expect(u.subscriptionStatus, isNull);
      expect(u.trialEndsAt, isNull);
      expect(u.stripeCustomerId, isNull);
      expect(u.stripeSubscriptionId, isNull);
      expect(u.stripeSubscriptionStatus, isNull);
      expect(u.stripeConnectAccountId, isNull);
      expect(u.stripeCurrentPeriodEnd, isNull);
      expect(u.stripeCancelAt, isNull);
    });

    test('fromJson with empty list defaults', () {
      final json = {
        'id': 'u-3',
        'name': 'User Three',
        'email': 'u3@test.com',
        'role': 'trainer',
        'tier': 'ELITE',
        'weight_unit': 'LB',
        'has_completed_onboarding': false,
        'stripe_cancel_at_period_end': false,
        'default_check_in_day': 0,
        'default_check_in_hour': 9,
        'created_at': ms,
        'updated_at': ms,
      };
      final u = User.fromJson(json);
      expect(u.pushTokens, isA<List>());
      expect(u.pushTokens, isEmpty);
    });
  });

  // ===========================================================================
  //  WorkoutProgram  (Tier 1 — also test camelCase/ISO 8601)
  //  Backend: {"id","name","description","trainer_id","category","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('WorkoutProgram', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final wp = WorkoutProgram(
        id: 'wp-1',
        name: 'Beginner Program',
        description: 'Great for starters',
        trainerId: 'tr-1',
        category: 'Strength',
        createdAt: t,
        updatedAt: t,
      );
      expect(WorkoutProgram.fromJson(wp.toJson()), equals(wp));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"wp-1","name":"Beginner Program","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'wp-1',
        'name': 'Beginner Program',
        'created_at': ms,
        'updated_at': ms,
      };
      final wp = WorkoutProgram.fromJson(json);
      expect(wp.name, 'Beginner Program');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'wp-2',
        'name': 'Advanced Program',
        'created_at': ms,
        'updated_at': ms,
      };
      final wp = WorkoutProgram.fromJson(json);
      expect(wp.description, isNull);
      expect(wp.trainerId, isNull);
      expect(wp.category, isNull);
      expect(wp.deletedAt, isNull);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'wp-camel',
        'name': 'Camel Program',
        'trainerId': 'tr-camel',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final wp = WorkoutProgram.fromJson(json);
      expect(wp.trainerId, 'tr-camel');
      expect(wp.createdAt, DateTime(2024, 1, 1));
    });
  });

  // ===========================================================================
  //  WorkoutSession  (Tier 1 — also test camelCase/ISO 8601 + nested client)
  //  Backend: {"id","client_id","name","start_time","end_time","status","notes","rest_started_at","workout_template_id","planned_date","client_package_id","is_trainer_led","reminder_time","trainer_reminder_sent","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('WorkoutSession', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final ws = WorkoutSession(
        id: 'ws-1',
        clientId: 'c-1',
        name: 'Morning Workout',
        startTime: t,
        endTime: t,
        status: WorkoutSessionStatus.completed,
        notes: 'Great session',
        restStartedAt: t,
        workoutTemplateId: 'wt-1',
        plannedDate: t,
        clientPackageId: 'pkg-1',
        isTrainerLed: true,
        reminderTime: t,
        trainerReminderSent: true,
        createdAt: t,
        updatedAt: t,
      );
      expect(WorkoutSession.fromJson(ws.toJson()), equals(ws));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"ws-1","client_id":"c-1","start_time":1700000000000,"status":"IN_PROGRESS","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'ws-1',
        'client_id': 'c-1',
        'start_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ws = WorkoutSession.fromJson(json);
      expect(ws.clientId, 'c-1');
      expect(ws.status, WorkoutSessionStatus.inProgress); // default
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ws-2',
        'client_id': 'c-2',
        'start_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ws = WorkoutSession.fromJson(json);
      expect(ws.name, isNull);
      expect(ws.endTime, isNull);
      expect(ws.notes, isNull);
      expect(ws.restStartedAt, isNull);
      expect(ws.workoutTemplateId, isNull);
      expect(ws.plannedDate, isNull);
      expect(ws.clientPackageId, isNull);
      expect(ws.reminderTime, isNull);
      expect(ws.deletedAt, isNull);
      expect(ws.isTrainerLed, false);
      expect(ws.trainerReminderSent, false);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'ws-camel',
        'clientId': 'c-camel',
        'startTime': '2024-01-01T00:00:00.000',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final ws = WorkoutSession.fromJson(json);
      expect(ws.clientId, 'c-camel');
      expect(ws.startTime, DateTime(2024, 1, 1));
    });

    test('fromJson handles nested client object (backend format)', () {
      // Backend returns: {"client":{"id":"client-nested","name":"John Doe"}}
      final json = {
        'id': 'ws-nested',
        'client': {'id': 'client-nested', 'name': 'John Doe'},
        'start_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ws = WorkoutSession.fromJson(json);
      expect(ws.clientId, 'client-nested');
      expect(ws.name, 'John Doe');
    });

    test('fromJson prefers flat client_id over nested client', () {
      final json = {
        'id': 'ws-mixed',
        'client_id': 'client-flat',
        'client': {'id': 'client-nested'},
        'start_time': ms,
        'created_at': ms,
        'updated_at': ms,
      };
      final ws = WorkoutSession.fromJson(json);
      expect(ws.clientId, 'client-flat');
    });

    test('fromJson handles all status variants', () {
      for (final entry in {
        'PLANNED': WorkoutSessionStatus.planned,
        'IN_PROGRESS': WorkoutSessionStatus.inProgress,
        'COMPLETED': WorkoutSessionStatus.completed,
      }.entries) {
        final json = {
          'id': 'ws-status',
          'client_id': 'c-1',
          'start_time': ms,
          'status': entry.key,
          'created_at': ms,
          'updated_at': ms,
        };
        final ws = WorkoutSession.fromJson(json);
        expect(ws.status, entry.value);
      }
    });
  });

  // ===========================================================================
  //  WorkoutSessionComment  (Tier 1 — also test camelCase/ISO 8601)
  //  Backend: {"id","text","workout_session_id","user_id","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('WorkoutSessionComment', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final wsc = WorkoutSessionComment(
        id: 'wsc-1',
        text: 'Great job!',
        workoutSessionId: 'ws-1',
        userId: 'u-1',
        createdAt: t,
        updatedAt: t,
      );
      expect(WorkoutSessionComment.fromJson(wsc.toJson()), equals(wsc));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"wsc-1","text":"Great job!","workout_session_id":"ws-1","user_id":"u-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'wsc-1',
        'text': 'Great job!',
        'workout_session_id': 'ws-1',
        'user_id': 'u-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final wsc = WorkoutSessionComment.fromJson(json);
      expect(wsc.text, 'Great job!');
      expect(wsc.workoutSessionId, 'ws-1');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'wsc-2',
        'text': 'Keep going',
        'workout_session_id': 'ws-2',
        'user_id': 'u-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final wsc = WorkoutSessionComment.fromJson(json);
      expect(wsc.deletedAt, isNull);
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'wsc-camel',
        'text': 'Camel comment',
        'workoutSessionId': 'ws-camel',
        'userId': 'u-camel',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final wsc = WorkoutSessionComment.fromJson(json);
      expect(wsc.workoutSessionId, 'ws-camel');
      expect(wsc.userId, 'u-camel');
      expect(wsc.createdAt, DateTime(2024, 1, 1));
    });
  });

  // ===========================================================================
  //  WorkoutTemplate  (Tier 1 — also test camelCase/ISO 8601)
  //  Backend: {"id","name","description","program_id","order","created_at","updated_at","deleted_at"}
  // ===========================================================================
  group('WorkoutTemplate', () {
    final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final wt = WorkoutTemplate(
        id: 'wt-1',
        name: 'Full Body',
        description: 'Full body workout',
        programId: 'prog-1',
        order: 1,
        createdAt: t,
        updatedAt: t,
      );
      expect(WorkoutTemplate.fromJson(wt.toJson()), equals(wt));
    });

    test('fromJson parses backend response shape (snake_case)', () {
      // Backend returns: {"id":"wt-1","name":"Full Body","program_id":"prog-1","created_at":1700000000000,"updated_at":1700000000000}
      final json = {
        'id': 'wt-1',
        'name': 'Full Body',
        'program_id': 'prog-1',
        'created_at': ms,
        'updated_at': ms,
      };
      final wt = WorkoutTemplate.fromJson(json);
      expect(wt.name, 'Full Body');
      expect(wt.programId, 'prog-1');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'wt-2',
        'name': 'Upper Body',
        'program_id': 'prog-2',
        'created_at': ms,
        'updated_at': ms,
      };
      final wt = WorkoutTemplate.fromJson(json);
      expect(wt.description, isNull);
      expect(wt.deletedAt, isNull);
      expect(wt.order, 0); // default
    });

    test('fromJson parses camelCase keys and ISO 8601 dates', () {
      final json = {
        'id': 'wt-camel',
        'name': 'Camel Workout',
        'programId': 'prog-camel',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };
      final wt = WorkoutTemplate.fromJson(json);
      expect(wt.programId, 'prog-camel');
      expect(wt.createdAt, DateTime(2024, 1, 1));
    });
  });

  // ===========================================================================
  //  SyncChanges (sync_models.dart)
  //  Backend: {"created": [...], "updated": [...], "deleted": [...]}
  // ===========================================================================
  group('SyncChanges', () {
    test('toJson -> fromJson round-trip', () {
      final sc = SyncChanges(
        created: const [{'id': '1', 'name': 'new'}],
        updated: const [{'id': '2', 'name': 'changed'}],
        deleted: const ['3', '4'],
      );
      final restored = SyncChanges.fromJson(sc.toJson());
      expect(restored.created, sc.created);
      expect(restored.updated, sc.updated);
      expect(restored.deleted, sc.deleted);
    });

    test('fromJson parses backend response shape', () {
      // Backend returns: {"created":[{"id":"1"}],"updated":[{"id":"2"}],"deleted":["3"]}
      final json = {
        'created': [{'id': '1'}],
        'updated': [{'id': '2'}],
        'deleted': ['3'],
      };
      final sc = SyncChanges.fromJson(json);
      expect(sc.created, hasLength(1));
      expect(sc.updated, hasLength(1));
      expect(sc.deleted, hasLength(1));
      expect(sc.deleted.first, '3');
    });

    test('fromJson defaults to empty lists when keys are missing', () {
      final sc = SyncChanges.fromJson({});
      expect(sc.created, isEmpty);
      expect(sc.updated, isEmpty);
      expect(sc.deleted, isEmpty);
    });
  });

  // ===========================================================================
  //  SyncPayload (sync_models.dart)
  //  Backend: {"changes": {"table_name": {"created":[...],"updated":[...],"deleted":[...]}}, "timestamp": 1700000000000}
  // ===========================================================================
  group('SyncPayload', () {
    final ms = 1700000000000;

    test('toJson -> fromJson round-trip', () {
      final sp = SyncPayload(
        changes: const {
          'exercises': SyncChanges(
            created: [{'id': 'ex-1'}],
          ),
        },
        timestamp: ms,
      );
      final restored = SyncPayload.fromJson(sp.toJson());
      expect(restored.timestamp, sp.timestamp);
      expect(restored.changes.keys, sp.changes.keys);
      expect(
        restored.changes['exercises']!.created,
        sp.changes['exercises']!.created,
      );
    });

    test('fromJson parses backend response shape', () {
      // Backend returns: {"changes":{"exercises":{"created":[{"id":"ex-1"}],"updated":[],"deleted":[]}},"timestamp":1700000000000}
      final json = {
        'changes': {
          'exercises': {
            'created': [{'id': 'ex-1'}],
            'updated': <Map<String, dynamic>>[],
            'deleted': <String>[],
          },
        },
        'timestamp': ms,
      };
      final sp = SyncPayload.fromJson(json);
      expect(sp.changes.containsKey('exercises'), isTrue);
      expect(sp.timestamp, ms);
      expect(sp.changes['exercises']!.created.first['id'], 'ex-1');
    });

    test('fromJson handles empty changes map', () {
      final json = {
        'changes': <String, dynamic>{},
        'timestamp': ms,
      };
      final sp = SyncPayload.fromJson(json);
      expect(sp.changes, isEmpty);
      expect(sp.timestamp, ms);
    });
  });
}
