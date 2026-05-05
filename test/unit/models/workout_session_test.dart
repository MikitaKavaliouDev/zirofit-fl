import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

void main() {
  group('WorkoutSession model', () {
    final baseJson = <String, dynamic>{
      'id': 'session-1',
      'client_id': 'client-1',
      'name': 'Morning Cardio',
      'start_time': 1700000000000,
      'end_time': 1700003600000,
      'status': 'IN_PROGRESS',
      'notes': 'Focus on steady-state cardio',
      'rest_started_at': 1700001800000,
      'workout_template_id': 'template-1',
      'planned_date': 1699999200000,
      'client_package_id': 'pkg-1',
      'is_trainer_led': true,
      'reminder_time': 1699999200000,
      'trainer_reminder_sent': false,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final session = WorkoutSession.fromJson(baseJson);

      expect(session.id, 'session-1');
      expect(session.clientId, 'client-1');
      expect(session.name, 'Morning Cardio');
      expect(
        session.startTime,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(
        session.endTime,
        DateTime.fromMillisecondsSinceEpoch(1700003600000),
      );
      expect(session.status, WorkoutSessionStatus.inProgress);
      expect(session.notes, 'Focus on steady-state cardio');
      expect(
        session.restStartedAt,
        DateTime.fromMillisecondsSinceEpoch(1700001800000),
      );
      expect(session.workoutTemplateId, 'template-1');
      expect(
        session.plannedDate,
        DateTime.fromMillisecondsSinceEpoch(1699999200000),
      );
      expect(session.clientPackageId, 'pkg-1');
      expect(session.isTrainerLed, isTrue);
      expect(
        session.reminderTime,
        DateTime.fromMillisecondsSinceEpoch(1699999200000),
      );
      expect(session.trainerReminderSent, isFalse);
      expect(
        session.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(
        session.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(session.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final session = WorkoutSession.fromJson(baseJson);
      final output = session.toJson();

      expect(output['id'], 'session-1');
      expect(output['client_id'], 'client-1');
      expect(output['name'], 'Morning Cardio');
      expect(output['start_time'], 1700000000000);
      expect(output['end_time'], 1700003600000);
      expect(output['status'], 'IN_PROGRESS');
      expect(output['notes'], 'Focus on steady-state cardio');
      expect(output['rest_started_at'], 1700001800000);
      expect(output['workout_template_id'], 'template-1');
      expect(output['planned_date'], 1699999200000);
      expect(output['client_package_id'], 'pkg-1');
      expect(output['is_trainer_led'], isTrue);
      expect(output['reminder_time'], 1699999200000);
      expect(output['trainer_reminder_sent'], isFalse);
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000000000);
      expect(output.containsKey('deleted_at'), isTrue);
      expect(output['deleted_at'], isNull);
    });

    test('fromJson uses default status when status is null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('status');

      final session = WorkoutSession.fromJson(json);

      expect(session.status, WorkoutSessionStatus.inProgress);
    });

    test('fromJson parses all status variants correctly', () {
      final variants = <String, WorkoutSessionStatus>{
        'PLANNED': WorkoutSessionStatus.planned,
        'IN_PROGRESS': WorkoutSessionStatus.inProgress,
        'COMPLETED': WorkoutSessionStatus.completed,
      };

      for (final entry in variants.entries) {
        final json = Map<String, dynamic>.from(baseJson);
        json['status'] = entry.key;
        final session = WorkoutSession.fromJson(json);
        expect(
          session.status,
          entry.value,
          reason: 'Failed for status: ${entry.key}',
        );
      }
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('name');
      json.remove('notes');
      json.remove('rest_started_at');
      json.remove('workout_template_id');
      json.remove('planned_date');
      json.remove('client_package_id');
      json.remove('reminder_time');
      json['end_time'] = null;
      json['deleted_at'] = null;

      final session = WorkoutSession.fromJson(json);

      expect(session.name, isNull);
      expect(session.endTime, isNull);
      expect(session.notes, isNull);
      expect(session.restStartedAt, isNull);
      expect(session.workoutTemplateId, isNull);
      expect(session.plannedDate, isNull);
      expect(session.clientPackageId, isNull);
      expect(session.reminderTime, isNull);
      expect(session.deletedAt, isNull);
    });

    test('fromJson defaults isTrainerLed to false when null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('is_trainer_led');

      final session = WorkoutSession.fromJson(json);

      expect(session.isTrainerLed, isFalse);
    });

    test('fromJson defaults trainerReminderSent to false when null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('trainer_reminder_sent');

      final session = WorkoutSession.fromJson(json);

      expect(session.trainerReminderSent, isFalse);
    });

    test('fromJson handles completed session with no end_time', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['status'] = 'COMPLETED';
      json['end_time'] = null;

      final session = WorkoutSession.fromJson(json);

      expect(session.status, WorkoutSessionStatus.completed);
      expect(session.endTime, isNull);
    });

    test('equality works with same data', () {
      final s1 = WorkoutSession.fromJson(baseJson);
      final s2 = WorkoutSession.fromJson(baseJson);

      expect(s1, equals(s2));
    });

    test('sessions with different ids are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      json1['id'] = 'session-1';
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['id'] = 'session-2';

      final s1 = WorkoutSession.fromJson(json1);
      final s2 = WorkoutSession.fromJson(json2);

      expect(s1, isNot(equals(s2)));
    });

    test('toJson roundtrip produces matching data', () {
      final session = WorkoutSession.fromJson(baseJson);
      final output = session.toJson();

      expect(output['id'], baseJson['id']);
      expect(output['client_id'], baseJson['client_id']);
      expect(output['start_time'], baseJson['start_time']);
      expect(output['status'], baseJson['status']);
      expect(output['created_at'], baseJson['created_at']);
      expect(output['updated_at'], baseJson['updated_at']);
    });

    test(
      'full roundtrip fromJson -> toJson -> fromJson produces equal object',
      () {
        final original = WorkoutSession.fromJson(baseJson);
        final output = original.toJson();
        final restored = WorkoutSession.fromJson(output);

        expect(restored, equals(original));
      },
    );

    test('hashCode is consistent for equal objects', () {
      final s1 = WorkoutSession.fromJson(baseJson);
      final s2 = WorkoutSession.fromJson(baseJson);

      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('toString returns expected format', () {
      final session = WorkoutSession.fromJson(baseJson);
      final str = session.toString();

      expect(str, contains('session-1'));
      expect(str, contains('WorkoutSession('));
      expect(str, contains('Morning Cardio'));
    });

    test('fromJson handles nested client object (backend format)', () {
      // Backend returns: {"client":{"id":"client-1","name":"John Doe"}}
      final json = <String, dynamic>{
        'id': 'session-1',
        'client': <String, dynamic>{'id': 'client-nested', 'name': 'John Doe'},
        'start_time': 1700000000000,
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      final session = WorkoutSession.fromJson(json);

      expect(session.clientId, 'client-nested');
      expect(
        session.name,
        'John Doe',
      ); // Should also read from nested client if top-level name missing
    });

    test(
      'fromJson prefers flat client_id over nested client (forward compatibility)',
      () {
        // If both formats present, flat key takes precedence
        final json = <String, dynamic>{
          'id': 'session-1',
          'client_id': 'client-flat',
          'client': <String, dynamic>{'id': 'client-nested'},
          'start_time': 1700000000000,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        };

        final session = WorkoutSession.fromJson(json);

        expect(session.clientId, 'client-flat');
      },
    );
  });
}
