import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/data/models/enums/event_status.dart';
import 'package:zirofit_fl/data/models/enums/habit_frequency.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';
import 'package:zirofit_fl/data/models/enums/training_type.dart';
import 'package:zirofit_fl/data/models/enums/user_tier.dart';
import 'package:zirofit_fl/data/models/enums/weight_unit.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

void main() {
  group('BookingStatus', () {
    for (final value in BookingStatus.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = BookingStatus.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => BookingStatus.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('EventStatus', () {
    for (final value in EventStatus.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = EventStatus.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => EventStatus.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('HabitFrequency', () {
    for (final value in HabitFrequency.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = HabitFrequency.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => HabitFrequency.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('StepType', () {
    for (final value in StepType.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = StepType.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => StepType.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('SupportTicketCategory', () {
    test('bugReport serializes to BUG_REPORT', () {
      expect(SupportTicketCategory.bugReport.toJson(), equals('BUG_REPORT'));
    });

    test('featureRequest serializes to FEATURE_REQUEST', () {
      expect(
        SupportTicketCategory.featureRequest.toJson(),
        equals('FEATURE_REQUEST'),
      );
    });

    test('generalSupport serializes to GENERAL_SUPPORT', () {
      expect(
        SupportTicketCategory.generalSupport.toJson(),
        equals('GENERAL_SUPPORT'),
      );
    });

    test('BUG_REPORT deserializes to bugReport', () {
      expect(
        SupportTicketCategory.fromJson('BUG_REPORT'),
        equals(SupportTicketCategory.bugReport),
      );
    });

    test('FEATURE_REQUEST deserializes to featureRequest', () {
      expect(
        SupportTicketCategory.fromJson('FEATURE_REQUEST'),
        equals(SupportTicketCategory.featureRequest),
      );
    });

    test('GENERAL_SUPPORT deserializes to generalSupport', () {
      expect(
        SupportTicketCategory.fromJson('GENERAL_SUPPORT'),
        equals(SupportTicketCategory.generalSupport),
      );
    });

    test('roundtrip for all values', () {
      for (final value in SupportTicketCategory.values) {
        final json = value.toJson();
        final restored = SupportTicketCategory.fromJson(json);
        expect(restored, equals(value));
      }
    });

    test('fromJson throws StateError for unknown wire value', () {
      expect(
        () => SupportTicketCategory.fromJson('UNKNOWN'),
        throwsStateError,
      );
    });
  });

  group('TrainingType', () {
    test('inPerson serializes to IN_PERSON', () {
      expect(TrainingType.inPerson.toJson(), equals('IN_PERSON'));
    });

    test('online serializes to ONLINE', () {
      expect(TrainingType.online.toJson(), equals('ONLINE'));
    });

    test('IN_PERSON deserializes to inPerson', () {
      expect(
        TrainingType.fromJson('IN_PERSON'),
        equals(TrainingType.inPerson),
      );
    });

    test('ONLINE deserializes to online', () {
      expect(TrainingType.fromJson('ONLINE'), equals(TrainingType.online));
    });

    test('roundtrip for all values', () {
      for (final value in TrainingType.values) {
        final json = value.toJson();
        final restored = TrainingType.fromJson(json);
        expect(restored, equals(value));
      }
    });

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => TrainingType.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('UserTier', () {
    for (final value in UserTier.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = UserTier.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => UserTier.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('WeightUnit', () {
    for (final value in WeightUnit.values) {
      test('toJson/fromJson roundtrip for ${value.name}', () {
        final json = value.toJson();
        expect(json, equals(value.name.toUpperCase()));
        final restored = WeightUnit.fromJson(json);
        expect(restored, equals(value));
      });
    }

    test('fromJson throws StateError for unknown wire value', () {
      expect(() => WeightUnit.fromJson('UNKNOWN'), throwsStateError);
    });
  });

  group('WorkoutSessionStatus', () {
    test('planned serializes to PLANNED', () {
      expect(WorkoutSessionStatus.planned.toJson(), equals('PLANNED'));
    });

    test('inProgress serializes to IN_PROGRESS', () {
      expect(
        WorkoutSessionStatus.inProgress.toJson(),
        equals('IN_PROGRESS'),
      );
    });

    test('completed serializes to COMPLETED', () {
      expect(WorkoutSessionStatus.completed.toJson(), equals('COMPLETED'));
    });

    test('PLANNED deserializes to planned', () {
      expect(
        WorkoutSessionStatus.fromJson('PLANNED'),
        equals(WorkoutSessionStatus.planned),
      );
    });

    test('IN_PROGRESS deserializes to inProgress', () {
      expect(
        WorkoutSessionStatus.fromJson('IN_PROGRESS'),
        equals(WorkoutSessionStatus.inProgress),
      );
    });

    test('COMPLETED deserializes to completed', () {
      expect(
        WorkoutSessionStatus.fromJson('COMPLETED'),
        equals(WorkoutSessionStatus.completed),
      );
    });

    test('roundtrip for all values', () {
      for (final value in WorkoutSessionStatus.values) {
        final json = value.toJson();
        final restored = WorkoutSessionStatus.fromJson(json);
        expect(restored, equals(value));
      }
    });

    test('fromJson throws StateError for unknown wire value', () {
      expect(
        () => WorkoutSessionStatus.fromJson('UNKNOWN'),
        throwsStateError,
      );
    });
  });
}
