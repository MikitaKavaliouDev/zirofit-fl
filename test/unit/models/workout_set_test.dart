import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';

void main() {
  group('SetStatus', () {
    test('fromJson returns normal for null', () {
      expect(SetStatus.fromJson(null), SetStatus.normal);
    });

    test('fromJson parses warmUp variants', () {
      expect(SetStatus.fromJson('warm_up'), SetStatus.warmUp);
      expect(SetStatus.fromJson('WARMUP'), SetStatus.warmUp);
      expect(SetStatus.fromJson('warmup'), SetStatus.warmUp);
    });

    test('fromJson parses dropSet', () {
      expect(SetStatus.fromJson('drop_set'), SetStatus.dropSet);
      expect(SetStatus.fromJson('DROPSET'), SetStatus.dropSet);
    });

    test('fromJson parses failure', () {
      expect(SetStatus.fromJson('failure'), SetStatus.failure);
      expect(SetStatus.fromJson('FAILURE'), SetStatus.failure);
    });

    test('toJson returns correct string', () {
      expect(SetStatus.normal.toJson(), 'normal');
      expect(SetStatus.warmUp.toJson(), 'warmUp');
      expect(SetStatus.dropSet.toJson(), 'dropSet');
      expect(SetStatus.failure.toJson(), 'failure');
    });
  });

  group('FocusMetric', () {
    test('fromJson returns none for null', () {
      expect(FocusMetric.fromJson(null), FocusMetric.none);
    });

    test('fromJson parses all variants', () {
      expect(FocusMetric.fromJson('volume'), FocusMetric.volume);
      expect(FocusMetric.fromJson('max_weight'), FocusMetric.maxWeight);
      expect(FocusMetric.fromJson('MAXWEIGHT'), FocusMetric.maxWeight);
      expect(FocusMetric.fromJson('max_reps'), FocusMetric.maxReps);
      expect(FocusMetric.fromJson('MAXREPS'), FocusMetric.maxReps);
    });

    test('toJson returns correct string', () {
      expect(FocusMetric.none.toJson(), 'none');
      expect(FocusMetric.volume.toJson(), 'volume');
      expect(FocusMetric.maxWeight.toJson(), 'maxWeight');
      expect(FocusMetric.maxReps.toJson(), 'maxReps');
    });
  });

  group('WorkoutSet', () {
    final baseJson = <String, dynamic>{
      'id': 'set-1',
      'log_id': 'log-1',
      'reps': 10,
      'weight': 80.5,
      'rpe': 8.0,
      'is_completed': true,
      'status': 'normal',
      'rest_duration': 90,
      'focus_metric': 'volume',
      'completed_at': 1700001800000,
    };

    test('fromJson parses all fields correctly', () {
      final set = WorkoutSet.fromJson(baseJson);

      expect(set.id, 'set-1');
      expect(set.logId, 'log-1');
      expect(set.reps, 10);
      expect(set.weight, 80.5);
      expect(set.rpe, 8.0);
      expect(set.isCompleted, true);
      expect(set.status, SetStatus.normal);
      expect(set.restDuration, 90);
      expect(set.focusMetric, FocusMetric.volume);
    });

    test('toJson produces correct output', () {
      final set = WorkoutSet.fromJson(baseJson);
      final json = set.toJson();

      expect(json['id'], 'set-1');
      expect(json['log_id'], 'log-1');
      expect(json['reps'], 10);
      expect(json['weight'], 80.5);
    });

    test('hasData returns true when reps > 0', () {
      final set = WorkoutSet(id: 's1', logId: 'l1', reps: 10);
      expect(set.hasData, true);
    });

    test('hasData returns true when weight > 0', () {
      final set = WorkoutSet(id: 's1', logId: 'l1', weight: 50.0);
      expect(set.hasData, true);
    });

    test('hasData returns false when no data', () {
      final set = WorkoutSet(id: 's1', logId: 'l1');
      expect(set.hasData, false);
    });

    test('canComplete returns true when hasData', () {
      final set = WorkoutSet(id: 's1', logId: 'l1', reps: 10);
      expect(set.canComplete, true);
    });

    test('canComplete returns false when no data', () {
      final set = WorkoutSet(id: 's1', logId: 'l1');
      expect(set.canComplete, false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = WorkoutSet.fromJson(baseJson);
      final updated = original.copyWith(reps: 12, isCompleted: false);

      expect(updated.id, original.id);
      expect(updated.reps, 12);
      expect(updated.isCompleted, false);
      expect(updated.weight, original.weight);
    });
  });

  group('WorkoutSet edge cases', () {
    test('handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'set-1',
        'log_id': 'log-1',
      };

      final set = WorkoutSet.fromJson(json);

      expect(set.id, 'set-1');
      expect(set.reps, null);
      expect(set.weight, null);
      expect(set.isCompleted, false);
      expect(set.status, SetStatus.normal);
    });

    test('handles null values gracefully', () {
      final set = WorkoutSet(
        id: 'set-1',
        logId: 'log-1',
        reps: null,
        weight: null,
      );

      expect(set.hasData, false);
    });
  });
}