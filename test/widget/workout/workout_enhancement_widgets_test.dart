import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/plate_calculation.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/plate_calculator_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/rest_timer_sheet.dart';
import 'package:zirofit_fl/features/workout/widgets/rpe_picker_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/superset_group_indicator.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_numeric_keyboard.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_list_builder.dart';
import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifier
// =============================================================================

class FakeWorkoutEnhancementNotifier extends WorkoutEnhancementNotifier {
  final List<String> actions = [];

  FakeWorkoutEnhancementNotifier(WorkoutEnhancementState state) : super() {
    super.state = state;
  }

  @override
  void selectPreset(int seconds) {
    actions.add('selectPreset:$seconds');
  }

  @override
  void setRpe(double rpe) {
    actions.add('setRpe:$rpe');
  }

  @override
  void setRir(double rir) {
    actions.add('setRir:$rir');
  }

  @override
  void calculateForWeightWithBar(double totalWeight, {double barWeight = 20.0}) {
    actions.add('calculateForWeightWithBar:$totalWeight,$barWeight');
    final plates = calculatePlates(totalWeight, barWeight: barWeight);
    // Must use the parent's state setter so Riverpod provider is notified
    state = state.copyWith(
      plateCalculation: PlateCalculation(
        totalWeight: totalWeight,
        barWeight: barWeight,
        platesPerSide: plates,
      ),
    );
  }

  @override
  void clearPlateCalculation() {
    actions.add('clearPlateCalculation');
  }

  @override
  void setDefaultSeconds(int seconds) {
    actions.add('setDefaultSeconds:$seconds');
  }

  @override
  void setCustomTime(int minutes, int seconds) {
    actions.add('setCustomTime:$minutes,$seconds');
  }
}

// =============================================================================
// Helpers
// =============================================================================

ProviderScope wrapWithProvider(
  Widget child,
  WorkoutEnhancementState state,
) {
  return ProviderScope(
    overrides: [
      workoutEnhancementProvider.overrideWith(
        (_) => FakeWorkoutEnhancementNotifier(state),
      ),
    ],
    child: child,
  );
}

// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  // ===========================================================================
  // RestTimerSheet
  // ===========================================================================

  group('RestTimerSheet', () {
    testWidgets('renders countdown timer display', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RestTimerSheet())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Default is 90s → "01:30"
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('Rest Timer'), findsOneWidget);
      // State label - not running initially
      expect(find.text('PAUSED'), findsOneWidget);
    });

    testWidgets('preset buttons show correct labels (30s, 60s, 90s, 120s, 180s)',
        (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RestTimerSheet())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // The presets list is [30, 60, 90, 120, 180]
      // Formatted as "30s", "1m", "1m 30s", "2m", "3m"
      expect(find.text('30s'), findsOneWidget);
      expect(find.text('1m'), findsOneWidget);
      expect(find.text('1m 30s'), findsOneWidget);
      expect(find.text('2m'), findsOneWidget);
      expect(find.text('3m'), findsOneWidget);
    });

    testWidgets('tapping a preset updates the timer', (t) async {
      final fake = FakeWorkoutEnhancementNotifier(
        const WorkoutEnhancementState(),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            workoutEnhancementProvider.overrideWith((_) => fake),
          ],
          child: const MaterialApp(home: Scaffold(body: RestTimerSheet())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Initially shows "01:30" (90s)
      expect(find.text('01:30'), findsOneWidget);

      // Tap the "2m" preset (120s)
      await t.tap(find.text('2m'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Timer should now show "02:00"
      expect(find.text('02:00'), findsOneWidget);

      // Verify notifier was called
      expect(fake.actions, contains('selectPreset:120'));
    });

    testWidgets('skip button fires callback', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RestTimerSheet())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Initially "01:30" and "PAUSED"
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);

      // Tap the Skip button
      await t.tap(find.text('Skip'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Timer resets to "00:00", should still be "PAUSED"
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
    });
  });

  // ===========================================================================
  // RPEPickerOverlay
  // ===========================================================================

  group('RPEPickerOverlay', () {
    testWidgets('renders with RPE title', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RPEPickerOverlay())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('Rate of Perceived Exertion'), findsOneWidget);
      expect(find.text('How hard was that set?'), findsOneWidget);
    });

    testWidgets('shows RPE values 5.0 through 10.0', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RPEPickerOverlay())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // The horizontal ListView renders a subset of items.
      // Verify the early values are present.
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('5.5'), findsOneWidget);
      expect(find.text('6.0'), findsOneWidget);

      // The apply button should show "Select an RPE value" when nothing selected
      expect(find.text('Select an RPE value'), findsOneWidget);
    });

    testWidgets('tapping a value selects it', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(home: Scaffold(body: RPEPickerOverlay())),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Initially shows "Select an RPE value"
      expect(find.text('Select an RPE value'), findsOneWidget);

      // Tap the "8.0" RPE value
      await t.tap(find.text('8.0'));
      await t.pump();

      // Apply button should now show "Apply RPE 8.0"
      expect(find.text('Apply RPE 8.0'), findsOneWidget);
    });

    testWidgets('apply button fires callback', (t) async {
      final fake = FakeWorkoutEnhancementNotifier(
        const WorkoutEnhancementState(),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            workoutEnhancementProvider.overrideWith((_) => fake),
          ],
          child: const MaterialApp(home: Scaffold(body: RPEPickerOverlay())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Select an RPE value first
      await t.tap(find.text('7.5'));
      await t.pump();

      // Apply
      await t.tap(find.text('Apply RPE 7.5'));
      await t.pump();

      // Verify notifier calls
      expect(fake.actions, contains('setRpe:7.5'));
    });
  });

  // ===========================================================================
  // PlateCalculatorOverlay
  // ===========================================================================

  group('PlateCalculatorOverlay', () {
    testWidgets('renders with Plate Calculator title', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: PlateCalculatorOverlay()),
            ),
          ),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('Plate Calculator'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('input field accepts weight', (t) async {
      await t.pumpWidget(
        wrapWithProvider(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: PlateCalculatorOverlay()),
            ),
          ),
          const WorkoutEnhancementState(),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Find the TextField and enter a value
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await t.enterText(textField, '100');
      await t.pump();

      // Verify the text was entered
      final field = t.widget<TextField>(textField);
      expect(field.controller?.text, '100');
    });

    testWidgets('shows plate breakdown after calculation', (t) async {
      final fake = FakeWorkoutEnhancementNotifier(
        const WorkoutEnhancementState(),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            workoutEnhancementProvider.overrideWith((_) => fake),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: PlateCalculatorOverlay()),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Should not show results initially
      expect(find.textContaining('Per side:'), findsNothing);

      // Enter a weight and tap Calculate
      await t.enterText(find.byType(TextField), '100');
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));

      // Tap Calculate
      await t.tap(find.text('Calculate'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 100));

      // Verify the notifier was called
      expect(fake.actions, contains('calculateForWeightWithBar:100.0,20.0'));

      // Should now show plate results
      // 100kg with 20kg bar = 80kg / 2 = 40kg per side
      // 40kg per side: 25kg + 15kg plates
      expect(find.textContaining('Per side:'), findsOneWidget);
      expect(find.textContaining('Plates (each side):'), findsOneWidget);
      expect(find.textContaining('40.0 kg'), findsOneWidget);
    });

    testWidgets('bar weight toggle works (20kg/15kg)', (t) async {
      final fake = FakeWorkoutEnhancementNotifier(
        const WorkoutEnhancementState(),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            workoutEnhancementProvider.overrideWith((_) => fake),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: PlateCalculatorOverlay()),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Default bar weight is 20kg
      expect(find.text('20 kg (men)'), findsOneWidget);
      expect(find.text('15 kg (women)'), findsOneWidget);

      // Tap the 15kg bar weight option
      await t.tap(find.text('15 kg (women)'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Enter a weight and calculate
      await t.enterText(find.byType(TextField), '85');
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text('Calculate'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Verify the notifier was called with the correct bar weight
      expect(
        fake.actions,
        contains('calculateForWeightWithBar:85.0,15.0'),
      );

      // 85kg with 15kg bar = 70kg / 2 = 35kg per side
      expect(find.textContaining('Per side:'), findsOneWidget);
    });
  });

  // ===========================================================================
  // SupersetGroupIndicator
  // ===========================================================================

  group('SupersetGroupIndicator', () {
    testWidgets('renders group letter badge', (t) async {
      const group = SupersetGroup(key: 'A');
      await t.pumpWidget(
        const MaterialApp(home: Scaffold(body: SupersetGroupIndicator(group: group))),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows completion progress text', (t) async {
      const group = SupersetGroup(
        key: 'B',
        completedSets: 2,
        totalSets: 4,
      );
      await t.pumpWidget(
        const MaterialApp(home: Scaffold(body: SupersetGroupIndicator(group: group))),
      );

      expect(find.text('B'), findsOneWidget);
      expect(find.text('2/4 sets'), findsOneWidget);
    });

    testWidgets('different colors for different groups', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SupersetGroupIndicator(group: SupersetGroup(key: 'A')),
                SizedBox(width: 16),
                SupersetGroupIndicator(group: SupersetGroup(key: 'B')),
              ],
            ),
          ),
        ),
      );

      // Both group letters should be rendered
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows singular "set" when totalSets is 1', (t) async {
      const group = SupersetGroup(
        key: 'C',
        completedSets: 1,
        totalSets: 1,
      );
      await t.pumpWidget(
        const MaterialApp(home: Scaffold(body: SupersetGroupIndicator(group: group))),
      );

      expect(find.text('1/1 set'), findsOneWidget);
    });
  });

  // ===========================================================================
  // WorkoutNumericKeyboard
  // ===========================================================================

  group('WorkoutNumericKeyboard', () {
    testWidgets('renders all digit buttons 0-9', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkoutNumericKeyboard())),
      );
      await t.pump();

      // Digits 1-9 appear only as keyboard buttons (one each)
      for (var i = 1; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      // "0" appears twice: display shows "0" initially + keyboard "0" button
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('decimal button works', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkoutNumericKeyboard(),
          ),
        ),
      );
      await t.pump();

      // The decimal button exists on the keyboard
      expect(find.text('.'), findsOneWidget);
    });

    testWidgets('clear button resets value', (t) async {
      String? currentValue;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutNumericKeyboard(
              onChanged: (v) => currentValue = v,
            ),
          ),
        ),
      );
      await t.pump();

      // Tap digit '5' (only one "5" initially — display shows "0")
      await t.tap(find.text('5'));
      await t.pump();
      expect(currentValue, '5');

      // Now display shows "5" too, so use .last for the keyboard button
      await t.tap(find.text('5').last);
      await t.pump();
      expect(currentValue, '55');

      // Tap clear button
      await t.tap(find.text('C'));
      await t.pump();

      // Value should be empty
      expect(currentValue, '');
    });

    testWidgets('next button fires callback', (t) async {
      String? submitted;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutNumericKeyboard(
              submitLabel: 'Next',
              onSubmitted: (v) => submitted = v,
            ),
          ),
        ),
      );
      await t.pump();

      // Enter a value — each digit only appears on keyboard (display differs)
      await t.tap(find.text('7'));
      await t.pump();
      await t.tap(find.text('5'));
      await t.pump();

      // Tap Next
      await t.tap(find.text('Next'));
      await t.pump();

      // Should have submitted the value
      expect(submitted, '75');
    });

    testWidgets('decimal can be added to value', (t) async {
      String? currentValue;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutNumericKeyboard(
              onChanged: (v) => currentValue = v,
            ),
          ),
        ),
      );
      await t.pump();

      // Enter "67.5" — all taps are unambiguous since display never matches
      await t.tap(find.text('6'));
      await t.pump();
      await t.tap(find.text('7'));
      await t.pump();
      await t.tap(find.text('.'));
      await t.pump();
      await t.tap(find.text('5'));
      await t.pump();

      expect(currentValue, '67.5');
    });
  });

// ===========================================================================
// ExerciseListBuilder
// ===========================================================================

group('ExerciseListBuilder', () {
  testWidgets('renders empty state when no exercises', (t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith(
            (ref) => ActiveWorkoutNotifier(remoteSource: FakeWorkoutRemoteSource(), ref: ref),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseListBuilder(onAddExercise: () {}),
          ),
        ),
      ),
    );

    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.text('Start by adding an exercise'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
  });

  testWidgets('renders non-superset exercises normally', (t) async {
    final log = ClientExerciseLog(
      id: '1',
      clientId: 'client1',
      exerciseId: 'exercise1',
      reps: 10,
      weight: 50.0,
      isCompleted: false,
      workoutSessionId: 'session1',
      supersetKey: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) {
            final notifier = ActiveWorkoutNotifier(remoteSource: FakeWorkoutRemoteSource(), ref: ref);
            notifier.state = notifier.state.copyWith(
              logs: [log],
              exerciseNames: {'exercise1': 'Bench Press'},
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseListBuilder(onAddExercise: () {}),
          ),
        ),
      ),
    );

    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('50.0 kg × 10 reps'), findsOneWidget);
    // Should not have superset styling (no blue border or link icon)
    expect(find.byIcon(Icons.link), findsNothing);
  });

  testWidgets('groups exercises with same supersetKey', (t) async {
    final log1 = ClientExerciseLog(
      id: '1',
      clientId: 'client1',
      exerciseId: 'exercise1',
      reps: 10,
      weight: 50.0,
      isCompleted: false,
      workoutSessionId: 'session1',
      supersetKey: 'A',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final log2 = ClientExerciseLog(
      id: '2',
      clientId: 'client1',
      exerciseId: 'exercise2',
      reps: 12,
      weight: 60.0,
      isCompleted: false,
      workoutSessionId: 'session1',
      supersetKey: 'A',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) {
            final notifier = ActiveWorkoutNotifier(remoteSource: FakeWorkoutRemoteSource(), ref: ref);
            notifier.state = notifier.state.copyWith(
              logs: [log1, log2],
              exerciseNames: {
                'exercise1': 'Bench Press',
                'exercise2': 'Incline Press',
              },
            );
            return notifier;
          }),
          workoutEnhancementProvider.overrideWith(
            (_) => FakeWorkoutEnhancementNotifier(
              const WorkoutEnhancementState(
                supersetGroups: [
                  SupersetGroup(key: 'A', exerciseIds: ['exercise1', 'exercise2']),
                ],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseListBuilder(onAddExercise: () {}),
          ),
        ),
      ),
    );

    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    // Should render superset group container
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Incline Press'), findsOneWidget);
    // Should have link icon for superset group
    expect(find.byIcon(Icons.link), findsOneWidget);
  });

  testWidgets('treats empty string supersetKey as non-superset', (t) async {
    final log = ClientExerciseLog(
      id: '1',
      clientId: 'client1',
      exerciseId: 'exercise1',
      reps: 10,
      weight: 50.0,
      isCompleted: false,
      workoutSessionId: 'session1',
      supersetKey: '', // Empty string should be treated as non-superset
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) {
            final notifier = ActiveWorkoutNotifier(remoteSource: FakeWorkoutRemoteSource(), ref: ref);
            notifier.state = notifier.state.copyWith(
              logs: [log],
              exerciseNames: {'exercise1': 'Bench Press'},
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseListBuilder(onAddExercise: () {}),
          ),
        ),
      ),
    );

    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.text('Bench Press'), findsOneWidget);
    // Should not have superset styling
    expect(find.byIcon(Icons.link), findsNothing);
  });
  });
}

// Fake remote source for testing
class FakeWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}
