import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import 'package:zirofit_fl/features/dashboard/screens/daily_target_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeDailyTargetNotifier extends DailyTargetNotifier {
  FakeDailyTargetNotifier(DailyTargetState state) {
    // Set the state via super's state setter using loadTargets mock
    // Since we can't easily call super.state, we override the getter
    _testState = state;
  }

  DailyTargetState _testState = const DailyTargetState();

  @override
  DailyTargetState get state => _testState;

  @override
  set state(DailyTargetState value) {
    _testState = value;
  }

  // Track calls
  int addTargetCalls = 0;
  int toggleCompletedCalls = 0;
  int removeTargetCalls = 0;
  int updateProgressCalls = 0;
  int adjustProgressCalls = 0;
  int reorderCalls = 0;
  int startChallengeCalls = 0;
  int completeChallengeDayCalls = 0;

  @override
  Future<void> addTarget(DailyTarget target) async {
    addTargetCalls++;
    state = state.copyWith(targets: [...state.targets, target]);
  }

  @override
  Future<void> toggleCompleted(String id) async {
    toggleCompletedCalls++;
    state = state.copyWith(
      targets: state.targets.map((t) {
        if (t.id == id) return t.copyWith(isCompleted: !t.isCompleted);
        return t;
      }).toList(),
    );
  }

  @override
  Future<void> removeTarget(String id) async {
    removeTargetCalls++;
    state = state.copyWith(
      targets: state.targets.where((t) => t.id != id).toList(),
    );
  }

  @override
  Future<void> updateProgress(String id, double value) async {
    updateProgressCalls++;
    state = state.copyWith(
      targets: state.targets.map((t) {
        if (t.id == id) return t.copyWith(currentValue: value);
        return t;
      }).toList(),
    );
  }

  @override
  Future<void> adjustProgress(String id, double delta) async {
    adjustProgressCalls++;
  }

  @override
  Future<void> reorderTargets(int oldIndex, int newIndex) async {
    reorderCalls++;
  }

  @override
  Future<void> startChallenge({String title = '7-Day Streak'}) async {
    startChallengeCalls++;
    state = state.copyWith(
      challenge: DailyChallenge(
        id: 'challenge-1',
        title: title,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        totalDays: 7,
        completedDays: 0,
        isActive: true,
      ),
    );
  }

  @override
  Future<void> completeChallengeDay() async {
    completeChallengeDayCalls++;
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget buildTestApp(DailyTargetState state) {
  return ProviderScope(
    overrides: [
      dailyTargetProvider.overrideWith((ref) => FakeDailyTargetNotifier(state)),
    ],
    child: const MaterialApp(
      home: DailyTargetScreen(),
    ),
  );
}

DailyTarget mockTarget({
  required String id,
  String title = 'Test Target',
  String type = 'steps',
  double targetValue = 10000,
  double currentValue = 0,
  String unit = 'steps',
  bool isCompleted = false,
  int order = 0,
}) {
  return DailyTarget(
    id: id,
    title: title,
    type: type,
    targetValue: targetValue,
    currentValue: currentValue,
    unit: unit,
    date: DateTime.now(),
    isCompleted: isCompleted,
    order: order,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyTargetScreen', () {
    testWidgets('Test 1: Shows daily targets list', (tester) async {
      final targets = [
        mockTarget(id: '1', title: 'Morning Walk'),
        mockTarget(id: '2', title: 'Drink Water'),
      ];
      final state = DailyTargetState(targets: targets);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      expect(find.text('Morning Walk'), findsOneWidget);
      expect(find.text('Drink Water'), findsOneWidget);
      expect(find.text('Today\'s Targets'), findsOneWidget);
    });

    testWidgets('Test 2: Shows streak counter', (tester) async {
      const state = DailyTargetState(
        targets: [],
        streak: 5,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      expect(find.text('5-day streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('Test 3: Add target via bottom sheet', (tester) async {
      const state = DailyTargetState(targets: []);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bottom sheet should show
      expect(find.text('Add Daily Target'), findsOneWidget);

      // Fill form: name, target value, unit
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'New Target');
      await tester.enterText(textFields.at(1), '5000');
      await tester.enterText(textFields.at(2), 'steps');

      // Tap the last FilledButton (the one in the bottom sheet)
      // There's now only one "Add Target" FilledButton since we refactored
      await tester.tap(find.widgetWithText(FilledButton, 'Add Target').last);
      await tester.pump();
      await tester.pump();

      // Verify the notifier was called
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DailyTargetScreen)),
      );
      final notifier = container.read(dailyTargetProvider.notifier)
          as FakeDailyTargetNotifier;
      expect(notifier.addTargetCalls, greaterThan(0));
    });

    testWidgets('Test 4: Edit target value via slider', (tester) async {
      final targets = [
        mockTarget(id: '1', title: 'Steps', targetValue: 100, currentValue: 30),
      ];
      final state = DailyTargetState(targets: targets);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Slider should be present
      expect(find.byType(Slider), findsOneWidget);

      // Verify current value is displayed
      expect(find.textContaining('30 / 100'), findsOneWidget);

      // Drag the slider thumb
      final slider = find.byType(Slider);
      final slideTarget = tester.getCenter(slider);
      await tester.timedDragFrom(
        slideTarget,
        const Offset(50, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      await tester.pump();

      // Verify the notifier's updateProgress was called
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DailyTargetScreen)),
      );
      final notifier = container.read(dailyTargetProvider.notifier)
          as FakeDailyTargetNotifier;
      expect(notifier.updateProgressCalls, greaterThan(0));
    });

    testWidgets('Test 5: Toggle completion checkbox', (tester) async {
      final targets = [
        mockTarget(id: '1', title: 'Test Target', isCompleted: false),
      ];
      final state = DailyTargetState(targets: targets);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Tap the checkbox using its unique key
      await tester.tap(find.byKey(const ValueKey('checkbox_1')));
      await tester.pump();
      await tester.pump();

      // Verify toggleCompleted was called
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DailyTargetScreen)),
      );
      final notifier = container.read(dailyTargetProvider.notifier)
          as FakeDailyTargetNotifier;
      expect(notifier.toggleCompletedCalls, greaterThan(0));
    });

    testWidgets('Test 6: Delete target (swipe)', (tester) async {
      final targets = [
        mockTarget(id: '1', title: 'To Delete'),
      ];
      final state = DailyTargetState(targets: targets);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Verify target is initially visible
      expect(find.text('To Delete'), findsOneWidget);

      // Find the Dismissible widget and drag it to dismiss
      final dismissibleFinder = find.byType(Dismissible).first;
      await tester.ensureVisible(dismissibleFinder);
      await tester.pump();

      // Use fling for a more reliable swipe gesture
      await tester.fling(
        dismissibleFinder,
        const Offset(-500, 0),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // After dismiss, the target card should be removed
      expect(find.text('To Delete'), findsNothing);
    });

    testWidgets('Test 7: Start challenge', (tester) async {
      const state = DailyTargetState(targets: []);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Challenge card should show "Start" button
      expect(find.text('Daily Challenge'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Tap Start
      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pump();

      // Verify startChallenge was called
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DailyTargetScreen)),
      );
      final notifier = container.read(dailyTargetProvider.notifier)
          as FakeDailyTargetNotifier;
      expect(notifier.startChallengeCalls, greaterThan(0));
    });

    testWidgets('Test 8: Active challenge shows countdown', (tester) async {
      final challenge = DailyChallenge(
        id: 'c1',
        title: '7-Day Streak',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        totalDays: 7,
        completedDays: 2,
        isActive: true,
      );
      final state = DailyTargetState(targets: [], challenge: challenge);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Should show challenge details
      expect(find.text('7-Day Streak'), findsOneWidget);
      expect(find.text('Day 2 of 7'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
      expect(find.textContaining('% complete'), findsOneWidget);
    });

    testWidgets('Test 9: Empty state when no targets', (tester) async {
      const state = DailyTargetState(targets: []);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      // Should show inline empty message (challenge is always visible now)
      expect(find.text('Daily Challenge'), findsOneWidget);
      expect(find.text('Tap to add your first target'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });
  });
}
