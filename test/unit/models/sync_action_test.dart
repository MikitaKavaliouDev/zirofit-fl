import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/sync_action.dart';

void main() {
  group('SyncActionType', () {
    test('fromJson returns correct type', () {
      expect(SyncActionType.fromJson('log_set'), SyncActionType.logSet);
      expect(SyncActionType.fromJson('finish_workout'), SyncActionType.finishWorkout);
      expect(SyncActionType.fromJson('add_exercise'), SyncActionType.addExercise);
      expect(SyncActionType.fromJson('remove_exercise'), SyncActionType.removeExercise);
      expect(SyncActionType.fromJson('upload_media'), SyncActionType.uploadMedia);
    });

    test('fromJson defaults to logSet for unknown', () {
      expect(SyncActionType.fromJson(null), SyncActionType.logSet);
      expect(SyncActionType.fromJson('unknown'), SyncActionType.logSet);
    });

    test('toJson returns correct string', () {
      expect(SyncActionType.logSet.toJson(), 'logSet');
      expect(SyncActionType.finishWorkout.toJson(), 'finishWorkout');
    });
  });

  group('SyncAction', () {
    final baseJson = <String, dynamic>{
      'id': 'sync-1',
      'action_type': 'log_set',
      'payload': {'session_id': 'sess-1', 'exercise_id': 'ex-1'},
      'created_at': 1700000000000,
      'retry_count': 0,
      'is_processed': false,
    };

    test('fromJson parses all fields correctly', () {
      final action = SyncAction.fromJson(baseJson);

      expect(action.id, 'sync-1');
      expect(action.actionType, SyncActionType.logSet);
      expect(action.payload['session_id'], 'sess-1');
      expect(action.retryCount, 0);
      expect(action.isProcessed, false);
    });

    test('toJson produces correct output', () {
      final action = SyncAction.fromJson(baseJson);
      final json = action.toJson();

      expect(json['id'], 'sync-1');
      expect(json['action_type'], 'logSet');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = SyncAction.fromJson(baseJson);
      final updated = original.copyWith(retryCount: 2, isProcessed: true);

      expect(updated.id, original.id);
      expect(updated.retryCount, 2);
      expect(updated.isProcessed, true);
    });
  });

  group('LogSetPayload', () {
    test('toJson produces correct output', () {
      final payload = LogSetPayload(
        sessionId: 'sess-1',
        exerciseId: 'ex-1',
        exerciseName: 'Squat',
        reps: 10,
        weight: 100.0,
        rpe: 8.0,
        isCompleted: true,
      );

      final json = payload.toJson();

      expect(json['session_id'], 'sess-1');
      expect(json['exercise_id'], 'ex-1');
      expect(json['exercise_name'], 'Squat');
      expect(json['reps'], 10);
      expect(json['weight'], 100.0);
      expect(json['rpe'], 8.0);
      expect(json['is_completed'], true);
    });

    test('toJson omits null optional fields', () {
      final payload = LogSetPayload(
        sessionId: 'sess-1',
        exerciseId: 'ex-1',
      );

      final json = payload.toJson();

      expect(json.containsKey('reps'), false);
      expect(json.containsKey('weight'), false);
      expect(json.containsKey('rpe'), false);
    });
  });

  group('FinishWorkoutPayload', () {
    test('toJson produces correct output', () {
      final payload = FinishWorkoutPayload(
        sessionId: 'sess-1',
        completeUnfinished: true,
        notes: 'Great workout!',
      );

      final json = payload.toJson();

      expect(json['session_id'], 'sess-1');
      expect(json['complete_unfinished'], true);
      expect(json['notes'], 'Great workout!');
    });

    test('toJson handles default values', () {
      final payload = FinishWorkoutPayload(sessionId: 'sess-1');
      final json = payload.toJson();

      expect(json['complete_unfinished'], false);
      expect(json.containsKey('notes'), false);
    });
  });

  group('SetStatus (sync_action)', () {
    test('fromJson returns correct type', () {
      expect(SetStatus.fromJson('normal'), SetStatus.normal);
      expect(SetStatus.fromJson('warm_up'), SetStatus.warmUp);
      expect(SetStatus.fromJson('drop_set'), SetStatus.dropSet);
      expect(SetStatus.fromJson('failure'), SetStatus.failure);
    });

    test('fromJson defaults to normal for null', () {
      expect(SetStatus.fromJson(null), SetStatus.normal);
    });
  });
}