import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

void main() {
  late WorkoutEnhancementNotifier notifier;

  setUp(() {
    notifier = WorkoutEnhancementNotifier();
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('rest timer defaults to 90 seconds', () {
      expect(notifier.state.restTimerSettings.defaultSeconds, 90);
    });

    test('rest timer presets are correct', () {
      expect(
        notifier.state.restTimerSettings.presets,
        [30, 60, 90, 120, 180],
      );
    });

    test('custom time is zero', () {
      expect(notifier.state.restTimerSettings.customMinutes, 0);
      expect(notifier.state.restTimerSettings.customSeconds, 0);
    });

    test('RPE state starts null and picker hidden', () {
      expect(notifier.state.rpeState.currentRpe, isNull);
      expect(notifier.state.rpeState.currentRir, isNull);
      expect(notifier.state.rpeState.showRpePicker, false);
    });

    test('superset groups is empty', () {
      expect(notifier.state.supersetGroups, isEmpty);
    });

    test('plate calculation is null', () {
      expect(notifier.state.plateCalculation, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Rest timer
  // ---------------------------------------------------------------------------

  group('rest timer', () {
    test('setDefaultSeconds changes default duration', () {
      notifier.setDefaultSeconds(120);
      expect(notifier.state.restTimerSettings.defaultSeconds, 120);
    });

    test('setCustomTime sets minutes and seconds', () {
      notifier.setCustomTime(1, 30);
      expect(notifier.state.restTimerSettings.customMinutes, 1);
      expect(notifier.state.restTimerSettings.customSeconds, 30);
    });

    test('setCustomTime updates defaultSeconds', () {
      notifier.setCustomTime(2, 0);
      expect(notifier.state.restTimerSettings.defaultSeconds, 120);
    });

    test('selectPreset sets defaultSeconds', () {
      notifier.selectPreset(60);
      expect(notifier.state.restTimerSettings.defaultSeconds, 60);
    });

    test('selectPreset toggles between presets', () {
      notifier.selectPreset(30);
      expect(notifier.state.restTimerSettings.defaultSeconds, 30);

      notifier.selectPreset(180);
      expect(notifier.state.restTimerSettings.defaultSeconds, 180);
    });
  });

  // ---------------------------------------------------------------------------
  // RPE
  // ---------------------------------------------------------------------------

  group('RPE', () {
    test('showRpePicker sets showRpePicker to true', () {
      notifier.showRpePicker();
      expect(notifier.state.rpeState.showRpePicker, true);
    });

    test('hideRpePicker sets showRpePicker to false', () {
      notifier.showRpePicker();
      notifier.hideRpePicker();
      expect(notifier.state.rpeState.showRpePicker, false);
    });

    test('setRpe stores the rpe value', () {
      notifier.setRpe(7.5);
      expect(notifier.state.rpeState.currentRpe, 7.5);
    });

    test('setRir stores the rir value', () {
      notifier.setRir(2);
      expect(notifier.state.rpeState.currentRir, 2);
    });

    test('setRpe does not clear existing rir', () {
      notifier.setRir(3);
      notifier.setRpe(8.0);
      expect(notifier.state.rpeState.currentRir, 3);
      expect(notifier.state.rpeState.currentRpe, 8.0);
    });

    test('setRir does not clear existing rpe', () {
      notifier.setRpe(8.5);
      notifier.setRir(1);
      expect(notifier.state.rpeState.currentRpe, 8.5);
      expect(notifier.state.rpeState.currentRir, 1);
    });

    test('showRpePicker does not clear existing values', () {
      notifier.setRpe(9.0);
      notifier.setRir(1);
      notifier.showRpePicker();
      expect(notifier.state.rpeState.currentRpe, 9.0);
      expect(notifier.state.rpeState.currentRir, 1);
    });

    test('hideRpePicker preserves values', () {
      notifier.setRpe(6.5);
      notifier.setRir(4);
      notifier.showRpePicker();
      notifier.hideRpePicker();
      expect(notifier.state.rpeState.currentRpe, 6.5);
      expect(notifier.state.rpeState.currentRir, 4);
      expect(notifier.state.rpeState.showRpePicker, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Superset groups
  // ---------------------------------------------------------------------------

  group('superset groups', () {
    test('createGroup adds a new group', () {
      notifier.createGroup('A');
      expect(notifier.state.supersetGroups.length, 1);
      expect(notifier.state.supersetGroups[0].key, 'A');
    });

    test('createGroup with existing key does not duplicate', () {
      notifier.createGroup('A');
      notifier.createGroup('A');
      expect(notifier.state.supersetGroups.length, 1);
    });

    test('multiple groups can be created', () {
      notifier.createGroup('A');
      notifier.createGroup('B');
      notifier.createGroup('C');
      expect(notifier.state.supersetGroups.length, 3);
    });

    test('addToGroup adds exercise to existing group', () {
      notifier.createGroup('A');
      notifier.addToGroup('A', 'ex-1');
      expect(notifier.state.supersetGroups[0].exerciseIds, ['ex-1']);
    });

    test('addToGroup does not duplicate exercise', () {
      notifier.createGroup('A');
      notifier.addToGroup('A', 'ex-1');
      notifier.addToGroup('A', 'ex-1');
      expect(notifier.state.supersetGroups[0].exerciseIds, ['ex-1']);
    });

    test('addToGroup adds multiple exercises', () {
      notifier.createGroup('A');
      notifier.addToGroup('A', 'ex-1');
      notifier.addToGroup('A', 'ex-2');
      expect(notifier.state.supersetGroups[0].exerciseIds, ['ex-1', 'ex-2']);
    });

    test('removeFromGroup removes an exercise', () {
      notifier.createGroup('A');
      notifier.addToGroup('A', 'ex-1');
      notifier.addToGroup('A', 'ex-2');
      notifier.removeFromGroup('A', 'ex-1');
      expect(notifier.state.supersetGroups[0].exerciseIds, ['ex-2']);
    });

    test('incrementCompleted increases completed sets', () {
      notifier.createGroup('A');
      notifier.incrementCompleted('A');
      expect(notifier.state.supersetGroups[0].completedSets, 1);
      notifier.incrementCompleted('A');
      expect(notifier.state.supersetGroups[0].completedSets, 2);
    });

    test('resetGroup resets completed sets to zero', () {
      notifier.createGroup('A');
      notifier.incrementCompleted('A');
      notifier.incrementCompleted('A');
      notifier.resetGroup('A');
      expect(notifier.state.supersetGroups[0].completedSets, 0);
    });

    test('operations on non-existent group do not throw', () {
      // Should not throw
      notifier.addToGroup('Z', 'ex-1');
      notifier.removeFromGroup('Z', 'ex-1');
      notifier.incrementCompleted('Z');
      notifier.resetGroup('Z');
    });
  });

  // ---------------------------------------------------------------------------
  // Plate calculator
  // ---------------------------------------------------------------------------

  group('plate calculator', () {
    test('calculateForWeight sets plate calculation', () {
      notifier.calculateForWeight(100);
      expect(notifier.state.plateCalculation, isNotNull);
      expect(notifier.state.plateCalculation!.totalWeight, 100);
      expect(notifier.state.plateCalculation!.platesPerSide, isNotEmpty);
    });

    test('calculateForWeightWithBar uses custom bar weight', () {
      notifier.calculateForWeightWithBar(50, barWeight: 15);
      expect(notifier.state.plateCalculation, isNotNull);
      expect(notifier.state.plateCalculation!.barWeight, 15);
      expect(notifier.state.plateCalculation!.totalWeight, 50);
    });

    test('clearPlateCalculation clears plate calculation', () {
      notifier.calculateForWeight(100);
      expect(notifier.state.plateCalculation, isNotNull);
      notifier.clearPlateCalculation();
      expect(notifier.state.plateCalculation, isNull);
    });

    test('calculateForWeight with low weight returns empty plates', () {
      notifier.calculateForWeight(10);
      expect(notifier.state.plateCalculation, isNotNull);
      expect(notifier.state.plateCalculation!.platesPerSide, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  group('reset', () {
    test('reset restores default state', () {
      // Set various values
      notifier.setDefaultSeconds(180);
      notifier.setRpe(8.0);
      notifier.createGroup('A');
      notifier.calculateForWeight(100);

      // Verify state is changed
      expect(notifier.state.restTimerSettings.defaultSeconds, 180);

      // Reset
      notifier.reset();

      // Verify defaults
      expect(notifier.state.restTimerSettings.defaultSeconds, 90);
      expect(notifier.state.rpeState.currentRpe, isNull);
      expect(notifier.state.supersetGroups, isEmpty);
      expect(notifier.state.plateCalculation, isNull);
    });
  });
}
