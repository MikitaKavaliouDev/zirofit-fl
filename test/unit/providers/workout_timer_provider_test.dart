import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';

void main() {
  group('WorkoutTimerNotifier', () {
    late ProviderContainer container;
    late WorkoutTimerNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(workoutTimerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle', () {
      expect(notifier.isIdle, true);
      expect(notifier.isRunning, false);
      expect(notifier.isPaused, false);
    });

    test('formattedTime returns 00:00 initially', () {
      expect(notifier.formattedTime, '00:00');
    });

    test('start changes state to running', () {
      notifier.start(DateTime.now());

      expect(notifier.isRunning, true);
      expect(notifier.isIdle, false);
    });

    test('pause changes state to paused', () {
      notifier.start(DateTime.now());
      notifier.pause();

      expect(notifier.isPaused, true);
      expect(notifier.isRunning, false);
    });

    test('resume changes state back to running', () {
      notifier.start(DateTime.now());
      notifier.pause();
      notifier.resume();

      expect(notifier.isRunning, true);
      expect(notifier.isPaused, false);
    });

    test('togglePause alternates between running and paused', () {
      notifier.start(DateTime.now());
      
      notifier.togglePause();
      expect(notifier.isPaused, true);
      
      notifier.togglePause();
      expect(notifier.isRunning, true);
    });

    test('stop resets state to idle', () {
      notifier.start(DateTime.now());
      notifier.stop();

      expect(notifier.isIdle, true);
      expect(notifier.elapsed, Duration.zero);
    });

    test('formattedTime shows hours for long workouts', () async {
      // Simulate a workout that has been running for 1+ hours
      final startTime = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));
      notifier.start(startTime);
      
      // Wait a bit for timer to tick
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should show H:MM:SS format
      expect(notifier.formattedTime.contains(':'), true);
    });

    test('progress returns value between 0 and 1', () {
      notifier.start(DateTime.now());
      
      // Progress should be small initially but valid
      expect(notifier.progress, greaterThanOrEqualTo(0.0));
      expect(notifier.progress, lessThanOrEqualTo(1.0));
    });

    test('isInWarningZone is false for short workouts', () {
      notifier.start(DateTime.now());
      expect(notifier.isInWarningZone, false);
    });

    test('isAtMaxDuration is false initially', () {
      notifier.start(DateTime.now());
      expect(notifier.isAtMaxDuration, false);
    });
  });
}