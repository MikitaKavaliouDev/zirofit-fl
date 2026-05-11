import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart';
import 'package:zirofit_fl/features/progress/screens/goal_setting_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake GoalsNotifier
// ---------------------------------------------------------------------------

/// A fake [GoalsNotifier] that avoids SharedPreferences initialization and
/// provides controllable state for widget tests.
///
/// This extends [GoalsNotifier] (rather than [StateNotifier]<[GoalsState]>
/// directly) so it can be used with [goalsProvider.overrideWith].
class FakeGoalsNotifier extends GoalsNotifier {
  FakeGoalsNotifier(GoalsState initialState) : super() {
    // Override the async-loaded state with the test state.
    // This runs after the super constructor starts _loadGoals but before the
    // SharedPreferences lookup completes, so the test state takes effect.
    state = initialState;
  }

  @override
  Future<void> setGoal(FitnessGoal goal) async {
    final goals = [...state.goals];
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    // Triggers Riverpod listeners so the UI rebuilds.
    state = state.copyWith(goals: goals);
  }

  @override
  Future<void> removeGoal(String goalId) async {
    final goals = state.goals.where((g) => g.id != goalId).toList();
    state = state.copyWith(goals: goals);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    configureTestApiClient();
    // Provide mock SharedPreferences so the GoalsNotifier super constructor's
    // _loadGoals async method does not crash.
    SharedPreferences.setMockInitialValues({});
  });

  group('GoalSettingScreen', () {
    testWidgets('renders app bar with title', (t) async {
      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(const GoalsState()),
          ),
        ],
      );

      expect(find.text('Set Goals'), findsOneWidget);
    });

    testWidgets('shows empty state when no goals exist', (t) async {
      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(const GoalsState()),
          ),
        ],
      );

      expect(find.text('No goals set'), findsOneWidget);
      expect(find.text('Create your first fitness goal!'), findsOneWidget);
    });

    testWidgets('displays existing goals as cards', (t) async {
      final goals = [
        FitnessGoal(
          id: 'g1',
          type: GoalType.sessions,
          targetValue: 4,
          startDate: DateTime(2026, 5, 1),
        ),
        FitnessGoal(
          id: 'g2',
          type: GoalType.volume,
          targetValue: 10000,
          startDate: DateTime(2026, 5, 1),
        ),
      ];

      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(GoalsState(goals: goals)),
          ),
        ],
      );
      await t.pump(const Duration(milliseconds: 100));

      // Each GoalCard shows the type label in its header.
      expect(find.text('Weekly Workouts'), findsOneWidget);
      expect(find.text('Weekly Volume'), findsOneWidget);
      // Empty state must NOT be shown.
      expect(find.text('No goals set'), findsNothing);
    });

    testWidgets('shows goal type selector', (t) async {
      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(const GoalsState()),
          ),
        ],
      );

      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('PR'), findsOneWidget);
      expect(find.byType(SegmentedButton<GoalType>), findsOneWidget);
    });

    testWidgets('creating a new goal adds to the list', (t) async {
      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(const GoalsState()),
          ),
        ],
      );

      // Initially the empty state is shown.
      expect(find.text('No goals set'), findsOneWidget);

      // Tap the "Save Goal" button with the default sessions type (target = 3).
      await t.tap(find.text('Save Goal'));

      // Let the async setGoal complete and the UI rebuild.
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // The goal card for the new Sessions goal should now be visible.
      expect(find.text('Weekly Workouts'), findsOneWidget);
      expect(find.text('No goals set'), findsNothing);
    });

    testWidgets('swipe to dismiss removes goal', (t) async {
      final goals = [
        FitnessGoal(
          id: 'g1',
          type: GoalType.sessions,
          targetValue: 4,
          startDate: DateTime(2026, 5, 1),
        ),
      ];

      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(GoalsState(goals: goals)),
          ),
        ],
      );
      await t.pump(const Duration(milliseconds: 100));

      // Verify the goal card is initially present.
      expect(find.text('Weekly Workouts'), findsOneWidget);

      // The goal card may be below the viewport because the form is tall.
      // Scroll to ensure it is visible before swiping.
      final dismissible = find.byType(Dismissible);
      await t.ensureVisible(dismissible);
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // Swipe the Dismissible leftward (endToStart).
      await t.drag(dismissible, const Offset(-500, 0));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // The confirm-dismiss AlertDialog should appear.
      expect(find.text('Delete Goal'), findsOneWidget);

      // Confirm deletion.
      await t.tap(find.text('Delete').last);

      // Let the dialog pop animation, Dismissible dismiss animation,
      // onDismissed callback, async state update, and UI rebuild complete.
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));
      await t.pump();

      // The goal card was removed, but the view may still be scrolled down
      // from the ensureVisible call.  Scroll back to the top so the empty
      // state becomes visible.
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, 600));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // The goal card should be removed and the empty state shown.
      expect(find.text('Weekly Workouts'), findsNothing);
      expect(find.text('No goals set'), findsOneWidget);
    });

    testWidgets('goal progress bar renders correctly', (t) async {
      // Sessions goal: 2 out of 4 → 50 % progress.
      final goal = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        currentValue: 2,
        startDate: DateTime(2026, 5, 1),
      );

      await t.pumpApp(
        const GoalSettingScreen(),
        overrides: [
          goalsProvider.overrideWith(
            (ref) => FakeGoalsNotifier(GoalsState(goals: [goal])),
          ),
        ],
      );
      // Allow the animated progress bar to reach its end value.
      await t.pump(const Duration(milliseconds: 600));

      // The percentage label should match 2/4 = 50 %.
      // It appears in two places: inside the animated progress bar label
      // and in the footer row of the GoalCard.
      expect(find.text('50%'), findsNWidgets(2));
    });
  });
}
