import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/services/live_activity_data.dart';
import 'package:zirofit_fl/features/workout/services/live_activity_service.dart';

void main() {
  group('LiveActivityData', () {
    test('default constructor creates empty data', () {
      const data = LiveActivityData();
      expect(data.currentExercise, isNull);
      expect(data.currentExerciseIndex, 0);
      expect(data.totalExercisesCount, 0);
      expect(data.currentSetIndex, 0);
      expect(data.totalSetsCount, 0);
      expect(data.currentReps, 0.0);
      expect(data.currentWeight, 0.0);
      expect(data.isResting, false);
      expect(data.restSeconds, 0);
      expect(data.totalRestSeconds, 0);
      expect(data.restFormattedTime, '00:00');
      expect(data.nextExerciseName, isNull);
      expect(data.isWorkoutComplete, false);
      expect(data.isLastSet, false);
      expect(data.isPaused, false);
      expect(data.clientName, isNull);
      expect(data.startTime, isNull);
      expect(data.workoutMode, isNull);
    });

    test('constructor sets all fields correctly', () {
      final startTime = DateTime(2026, 5, 11, 10, 0, 0);
      const data = LiveActivityData(
        currentExercise: 'Bench Press',
        currentExerciseIndex: 2,
        totalExercisesCount: 8,
        currentSetIndex: 3,
        totalSetsCount: 5,
        setInfo: 'Working set',
        currentReps: 10.0,
        currentWeight: 80.0,
        isResting: true,
        restSeconds: 45,
        totalRestSeconds: 90,
        restFormattedTime: '00:45',
        nextExerciseName: 'Incline Dumbbell Press',
        isWorkoutComplete: false,
        isLastSet: false,
        isPaused: false,
        clientName: 'Personal Workout',
        workoutMode: 'personal',
      );
      expect(data.currentExercise, 'Bench Press');
      expect(data.currentExerciseIndex, 2);
      expect(data.totalExercisesCount, 8);
      expect(data.currentSetIndex, 3);
      expect(data.totalSetsCount, 5);
      expect(data.setInfo, 'Working set');
      expect(data.currentReps, 10.0);
      expect(data.currentWeight, 80.0);
      expect(data.isResting, true);
      expect(data.restSeconds, 45);
      expect(data.totalRestSeconds, 90);
      expect(data.restFormattedTime, '00:45');
      expect(data.nextExerciseName, 'Incline Dumbbell Press');
      expect(data.isWorkoutComplete, false);
      expect(data.isLastSet, false);
      expect(data.isPaused, false);
      expect(data.clientName, 'Personal Workout');
      expect(data.workoutMode, 'personal');
    });

    test('copyWith creates modified copy', () {
      const original = LiveActivityData(
        currentExercise: 'Squat',
        currentExerciseIndex: 1,
        totalExercisesCount: 6,
        currentSetIndex: 2,
        totalSetsCount: 4,
        currentReps: 5.0,
        currentWeight: 120.0,
        isResting: false,
        restSeconds: 0,
        totalRestSeconds: 0,
        restFormattedTime: '00:00',
      );

      final modified = original.copyWith(
        currentExercise: 'Deadlift',
        currentReps: 5.0,
        currentWeight: 140.0,
        restSeconds: 90,
        isResting: true,
      );

      expect(modified.currentExercise, 'Deadlift');
      expect(modified.currentExerciseIndex, 1); // unchanged
      expect(modified.totalExercisesCount, 6); // unchanged
      expect(modified.currentSetIndex, 2); // unchanged
      expect(modified.totalSetsCount, 4); // unchanged
      expect(modified.currentReps, 5.0); // unchanged
      expect(modified.currentWeight, 140.0);
      expect(modified.isResting, true);
      expect(modified.restSeconds, 90);
      expect(modified.totalRestSeconds, 0); // unchanged
      expect(modified.restFormattedTime, '00:00'); // unchanged
    });

    test('copyWith with no args returns identical object', () {
      const original = LiveActivityData(
        currentExercise: 'Press',
        currentSetIndex: 1,
        totalSetsCount: 3,
        restSeconds: 90,
      );
      final copied = original.copyWith();
      expect(copied, original);
    });

    test('toJson produces correct map', () {
      const data = LiveActivityData(
        currentExercise: 'Bench Press',
        currentExerciseIndex: 2,
        totalExercisesCount: 8,
        currentSetIndex: 3,
        totalSetsCount: 5,
        setInfo: 'Working set',
        currentReps: 10.0,
        currentWeight: 80.0,
        isResting: true,
        restSeconds: 45,
        totalRestSeconds: 90,
        restFormattedTime: '00:45',
        nextExerciseName: 'Incline Dumbbell Press',
        isWorkoutComplete: false,
        isLastSet: false,
        isPaused: false,
        clientName: 'Personal Workout',
        workoutMode: 'personal',
      );

      final json = data.toJson();
      expect(json['currentExercise'], 'Bench Press');
      expect(json['currentExerciseIndex'], 2);
      expect(json['totalExercisesCount'], 8);
      expect(json['currentSetIndex'], 3);
      expect(json['totalSetsCount'], 5);
      expect(json['setInfo'], 'Working set');
      expect(json['currentReps'], 10.0);
      expect(json['currentWeight'], 80.0);
      expect(json['isResting'], true);
      expect(json['restSeconds'], 45);
      expect(json['totalRestSeconds'], 90);
      expect(json['restFormattedTime'], '00:45');
      expect(json['nextExerciseName'], 'Incline Dumbbell Press');
      expect(json['isWorkoutComplete'], false);
      expect(json['isLastSet'], false);
      expect(json['isPaused'], false);
      expect(json['clientName'], 'Personal Workout');
      expect(json['workoutMode'], 'personal');
      // workoutStartDate and startTime should be absent since null
      expect(json.containsKey('workoutStartDate'), false);
      expect(json.containsKey('startTime'), false);
    });

    test('toJson includes date fields when present', () {
      final startTime = DateTime(2026, 5, 11, 10, 0, 0);
      final data = LiveActivityData(
        workoutStartDate: startTime,
        startTime: startTime,
      );
      final json = data.toJson();
      expect(json['workoutStartDate'], startTime.millisecondsSinceEpoch);
      expect(json['startTime'], startTime.millisecondsSinceEpoch);
    });

    test('fromJson correctly parses map', () {
      final json = {
        'currentExercise': 'Deadlift',
        'currentExerciseIndex': 1,
        'totalExercisesCount': 6,
        'currentSetIndex': 5,
        'totalSetsCount': 5,
        'setInfo': 'Top set',
        'currentReps': 3.0,
        'currentWeight': 180.0,
        'isResting': false,
        'restSeconds': 0,
        'totalRestSeconds': 0,
        'restFormattedTime': '00:00',
        'nextExerciseName': 'Romanian Deadlift',
        'isWorkoutComplete': false,
        'isLastSet': true,
        'isPaused': false,
        'clientName': 'Trainer Session',
        'workoutMode': 'trainer',
        'workoutStartDate': 1715421600000,
        'startTime': 1715421600000,
      };

      final data = LiveActivityData.fromJson(json);
      expect(data.currentExercise, 'Deadlift');
      expect(data.currentExerciseIndex, 1);
      expect(data.totalExercisesCount, 6);
      expect(data.currentSetIndex, 5);
      expect(data.totalSetsCount, 5);
      expect(data.setInfo, 'Top set');
      expect(data.currentReps, 3.0);
      expect(data.currentWeight, 180.0);
      expect(data.isResting, false);
      expect(data.restSeconds, 0);
      expect(data.totalRestSeconds, 0);
      expect(data.restFormattedTime, '00:00');
      expect(data.nextExerciseName, 'Romanian Deadlift');
      expect(data.isWorkoutComplete, false);
      expect(data.isLastSet, true);
      expect(data.isPaused, false);
      expect(data.clientName, 'Trainer Session');
      expect(data.workoutMode, 'trainer');
      expect(data.workoutStartDate, DateTime.fromMillisecondsSinceEpoch(1715421600000));
      expect(data.startTime, DateTime.fromMillisecondsSinceEpoch(1715421600000));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final data = LiveActivityData.fromJson(json);
      expect(data.currentExercise, isNull);
      expect(data.currentExerciseIndex, 0);
      expect(data.totalExercisesCount, 0);
      expect(data.currentSetIndex, 0);
      expect(data.totalSetsCount, 0);
      expect(data.currentReps, 0.0);
      expect(data.currentWeight, 0.0);
      expect(data.isResting, false);
      expect(data.restSeconds, 0);
      expect(data.totalRestSeconds, 0);
      expect(data.restFormattedTime, '00:00');
      expect(data.isWorkoutComplete, false);
      expect(data.isLastSet, false);
      expect(data.isPaused, false);
    });

    test('equality works correctly', () {
      const a = LiveActivityData(currentExercise: 'Bench', currentSetIndex: 3);
      const b = LiveActivityData(currentExercise: 'Bench', currentSetIndex: 3);
      const c = LiveActivityData(currentExercise: 'Squat', currentSetIndex: 1);

      expect(a, b);
      expect(a, isNot(c));
    });

    test('toString contains field values', () {
      const data = LiveActivityData(
        currentExercise: 'OHP',
        currentSetIndex: 4,
      );
      final str = data.toString();
      expect(str, contains('OHP'));
      expect(str, contains('set: 4'));
    });

    test('numeric fields accept num types from JSON', () {
      // Simulate JSON where numbers come as doubles
      final json = {
        'currentExerciseIndex': 2.0,
        'totalExercisesCount': 8.0,
        'currentSetIndex': 3.0,
        'totalSetsCount': 5.0,
        'currentReps': 10,
        'currentWeight': 80,
        'restSeconds': 45.0,
        'totalRestSeconds': 90.0,
      };
      final data = LiveActivityData.fromJson(json);
      expect(data.currentExerciseIndex, 2);
      expect(data.totalExercisesCount, 8);
      expect(data.currentSetIndex, 3);
      expect(data.totalSetsCount, 5);
      expect(data.currentReps, 10.0);
      expect(data.currentWeight, 80.0);
      expect(data.restSeconds, 45);
      expect(data.totalRestSeconds, 90);
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
      final supported = await service.isSupported;
      expect(supported, false);
    });

    test('startActivity gracefully handles missing plugin', () async {
      final result = await service.startActivity(
        const LiveActivityData(currentExercise: 'Bench Press'),
      );
      expect(result, false);
    });

    test('updateActivity gracefully handles missing plugin', () async {
      final result = await service.updateActivity(
        const LiveActivityData(currentExercise: 'Squat', currentSetIndex: 2),
      );
      expect(result, false);
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

    test('setRestTimer gracefully handles missing plugin', () async {
      final result = await service.setRestTimer(
        secondsRemaining: 90,
        totalSeconds: 120,
        nextExerciseName: 'Squat',
      );
      expect(result, false);
    });

    test('endActivity gracefully handles missing plugin', () async {
      final result = await service.endActivity(summary: 'Workout Complete');
      expect(result, false);
    });

    test('endActivity without summary gracefully handles missing plugin',
        () async {
      final result = await service.endActivity();
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
      await service.isSupported;
      await service.startActivity(
        const LiveActivityData(currentExercise: 'Warm-up', currentSetIndex: 1),
      );
      await service.updateExercise(exerciseName: 'Bench Press', setCount: 1);
      await service.updateRestTimer(90);
      await service.setRestTimer(
        secondsRemaining: 60,
        totalSeconds: 90,
        nextExerciseName: 'Squat',
      );
      await service.updateActivity(
        const LiveActivityData(currentExercise: 'Deadlift', currentSetIndex: 3),
      );
      await service.endActivity();

      expect(true, true);
    });

    test('multiple update calls work sequentially', () async {
      await service.updateExercise(exerciseName: 'Bench', setCount: 1);
      await service.updateExercise(exerciseName: 'Bench', setCount: 2);
      await service.updateExercise(exerciseName: 'Squat', setCount: 1);
      expect(true, true);
    });

    test('endWorkout is an alias for endActivity', () async {
      // Both should return false without throwing on missing plugin
      final endWorkoutResult = await service.endWorkout();
      final endActivityResult = await service.endActivity();
      expect(endWorkoutResult, endActivityResult);
    });
  });
}
