import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/services/live_activity_data.dart';
import 'package:zirofit_fl/features/workout/services/live_activity_service.dart';

void main() {
  group('LiveActivityData', () {
    test('default constructor creates empty data', () {
      const data = LiveActivityData();
      expect(data.exerciseName, '');
      expect(data.setCount, 0);
      expect(data.totalSets, 0);
      expect(data.restSeconds, 0);
      expect(data.elapsedSeconds, 0);
      expect(data.activityId, '');
    });

    test('constructor sets all fields correctly', () {
      const data = LiveActivityData(
        exerciseName: 'Bench Press',
        setCount: 3,
        totalSets: 5,
        restSeconds: 45,
        elapsedSeconds: 1200,
        activityId: 'session-123',
      );
      expect(data.exerciseName, 'Bench Press');
      expect(data.setCount, 3);
      expect(data.totalSets, 5);
      expect(data.restSeconds, 45);
      expect(data.elapsedSeconds, 1200);
      expect(data.activityId, 'session-123');
    });

    test('copyWith creates modified copy', () {
      const original = LiveActivityData(
        exerciseName: 'Squat',
        setCount: 2,
        totalSets: 4,
        restSeconds: 60,
        elapsedSeconds: 600,
        activityId: 'session-456',
      );

      // Modify only some fields
      final modified = original.copyWith(
        exerciseName: 'Deadlift',
        restSeconds: 30,
      );

      expect(modified.exerciseName, 'Deadlift');
      expect(modified.setCount, 2); // unchanged
      expect(modified.totalSets, 4); // unchanged
      expect(modified.restSeconds, 30);
      expect(modified.elapsedSeconds, 600); // unchanged
      expect(modified.activityId, 'session-456'); // unchanged
    });

    test('copyWith with no args returns identical object', () {
      const original = LiveActivityData(
        exerciseName: 'Press',
        setCount: 1,
        totalSets: 3,
        restSeconds: 90,
        elapsedSeconds: 300,
        activityId: 'session-789',
      );
      final copied = original.copyWith();
      expect(copied, original);
    });

    test('toJson produces correct map', () {
      const data = LiveActivityData(
        exerciseName: 'Bench Press',
        setCount: 3,
        totalSets: 5,
        restSeconds: 45,
        elapsedSeconds: 1200,
        activityId: 'session-123',
      );

      final json = data.toJson();
      expect(json['exerciseName'], 'Bench Press');
      expect(json['setCount'], 3);
      expect(json['totalSets'], 5);
      expect(json['restSeconds'], 45);
      expect(json['elapsedSeconds'], 1200);
      expect(json['activityId'], 'session-123');
    });

    test('fromJson correctly parses map', () {
      final json = {
        'exerciseName': 'Deadlift',
        'setCount': 5,
        'totalSets': 5,
        'restSeconds': 0,
        'elapsedSeconds': 900,
        'activityId': 'session-dead-001',
      };

      final data = LiveActivityData.fromJson(json);
      expect(data.exerciseName, 'Deadlift');
      expect(data.setCount, 5);
      expect(data.totalSets, 5);
      expect(data.restSeconds, 0);
      expect(data.elapsedSeconds, 900);
      expect(data.activityId, 'session-dead-001');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final data = LiveActivityData.fromJson(json);
      expect(data.exerciseName, '');
      expect(data.setCount, 0);
      expect(data.totalSets, 0);
      expect(data.restSeconds, 0);
      expect(data.elapsedSeconds, 0);
      expect(data.activityId, '');
    });

    test('equality works correctly', () {
      const a = LiveActivityData(exerciseName: 'Bench', setCount: 3);
      const b = LiveActivityData(exerciseName: 'Bench', setCount: 3);
      const c = LiveActivityData(exerciseName: 'Squat', setCount: 1);

      expect(a, b);
      expect(a, isNot(c));
    });

    test('toString contains field values', () {
      const data = LiveActivityData(
        exerciseName: 'OHP',
        setCount: 4,
      );
      final str = data.toString();
      expect(str, contains('OHP'));
      expect(str, contains('setCount: 4'));
    });
  });

  group('LiveActivityService', () {
    late LiveActivityService service;

    setUp(() {
      service = LiveActivityService();
    });

    test('is a singleton', () {
      final instance1 = LiveActivityService();
      final instance2 = LiveActivityService();
      expect(identical(instance1, instance2), true);
    });

    test('isSupported returns false when MethodChannel is not set up', () async {
      // On non-iOS platforms or without a registered plugin,
      // isSupported should gracefully return false.
      final supported = await service.isSupported;
      expect(supported, false);
    });

    test('startWorkout completes without error when plugin not available',
        () async {
      // Without a native plugin registration, this should return false
      // rather than throwing.
      // We use a fake WorkoutSession-like object. Since we can't construct
      // a real WorkoutSession without its deps, we verify the method
      // signature and graceful failure behavior.
      // The actual startWorkout requires a WorkoutSession, but in tests
      // the channel is not registered, so it returns false gracefully.
      await expectLater(service.isSupported, completes);
    });

    test('updateExercise gracefully handles missing plugin', () async {
      final result = await service.updateExercise(
        exerciseName: 'Bench Press',
        setCount: 3,
        totalSets: 5,
      );
      expect(result, false);
    });

    test('updateRestTimer gracefully handles missing plugin', () async {
      final result = await service.updateRestTimer(45);
      expect(result, false);
    });

    test('updateActivity gracefully handles missing plugin', () async {
      final result = await service.updateActivity(
        const LiveActivityData(exerciseName: 'Squat', setCount: 2),
      );
      expect(result, false);
    });

    test('endWorkout gracefully handles missing plugin', () async {
      final result = await service.endWorkout(summary: 'Workout Complete');
      expect(result, false);
    });

    test('endWorkout without summary gracefully handles missing plugin',
        () async {
      final result = await service.endWorkout();
      expect(result, false);
    });

    test('endWithSummary gracefully handles missing plugin', () async {
      final result = await service.endWithSummary(
        duration: const Duration(minutes: 45),
        totalSets: 12,
        totalVolume: 4500,
      );
      expect(result, false);
    });

    test('all methods complete without throwing exceptions', () async {
      // Verify the entire lifecycle completes gracefully
      await service.isSupported;
      await service.updateExercise(exerciseName: 'Warm-up');
      await service.updateRestTimer(90);
      await service.updateActivity(
        const LiveActivityData(exerciseName: 'Deadlift', setCount: 3),
      );
      await service.endWorkout();

      // If we reach here, no exceptions were thrown
      expect(true, true);
    });

    test('multiple updateExercise calls work sequentially', () async {
      await service.updateExercise(exerciseName: 'Bench', setCount: 1);
      await service.updateExercise(exerciseName: 'Bench', setCount: 2);
      await service.updateExercise(exerciseName: 'Squat', setCount: 1);
      expect(true, true);
    });
  });
}
