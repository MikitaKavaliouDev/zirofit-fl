import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/data/models/enums/habit_frequency.dart';
import 'package:zirofit_fl/features/habits/providers/habits_provider.dart';
import 'package:zirofit_fl/features/habits/screens/habits_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeHabitsNotifier extends HabitsNotifier {
  final HabitsState _overriddenState;

  FakeHabitsNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  HabitsState get state => _overriddenState;

  @override
  Future<void> fetchHabits() async {}

  @override
  Future<void> logHabit(
    String habitId,
    DateTime date,
    bool isCompleted, {
    String? note,
  }) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DailyHabit _createHabit({
  String id = 'habit-1',
  String title = 'Drink 8 glasses of water',
  String? description,
}) {
  return DailyHabit(
    id: id,
    clientId: 'client-1',
    trainerId: 'trainer-1',
    title: title,
    description: description,
    frequency: HabitFrequency.daily,
    isActive: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

Widget buildTestApp(HabitsState state) {
  return ProviderScope(
    overrides: [
      habitsProvider.overrideWith((ref) => FakeHabitsNotifier(state)),
    ],
    child: const MaterialApp(
      home: HabitsScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const HabitsState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows habits list and progress card when data is loaded',
      (tester) async {
    final habits = [
      _createHabit(
          id: 'habit-1', title: 'Drink 8 glasses of water'),
      _createHabit(
          id: 'habit-2',
          title: 'Walk 10,000 steps',
          description: 'Use a pedometer'),
    ];

    await tester.pumpWidget(buildTestApp(
      HabitsState(habits: habits, isLoading: false),
    ));
    await tester.pump();

    // Progress card
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);

    // Habit tiles
    expect(find.text('Drink 8 glasses of water'), findsOneWidget);
    expect(find.text('Walk 10,000 steps'), findsOneWidget);
    expect(find.text('Use a pedometer'), findsOneWidget);

    // Switches
    expect(find.byType(Switch), findsNWidgets(2));
  });

  testWidgets('shows empty state when no habits', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const HabitsState(habits: [], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('No habits yet'), findsOneWidget);
    expect(
      find.text('Your trainer will assign habits for you.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const HabitsState(
          habits: [], isLoading: false, error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Failed to load habits'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('toggling a habit shows checked state', (tester) async {
    final habits = [
      _createHabit(id: 'habit-1', title: 'Drink water'),
    ];

    await tester.pumpWidget(buildTestApp(
      HabitsState(habits: habits, isLoading: false),
    ));
    await tester.pump();

    // Initially unchecked
    expect(find.text('0 / 1'), findsOneWidget);

    // Tap the switch
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // Progress should still show 0 / 1 because the FakeNotifier doesn't
    // change the state, but the local _completedToday set is updated,
    // which is a local state change in the ConsumerStatefulWidget.
    // In the FakeNotifier the state doesn't change, but setState is
    // called locally. However, the progress card reads from state.habits
    // and _completedToday, not from HabitsState. So it should update.
    // Actually wait - the progress card shows completedCount / totalCount
    // where completedCount is from _completedToday (local setState).
    // So yes, it should update.
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('shows error banner when saving fails', (tester) async {
    final habits = [
      _createHabit(id: 'habit-1', title: 'Drink water'),
    ];

    await tester.pumpWidget(buildTestApp(
      HabitsState(habits: habits, isLoading: false, error: 'Save failed'),
    ));
    await tester.pump();

    // Error text should be visible as a banner
    expect(find.text('Save failed'), findsOneWidget);
  });
}
