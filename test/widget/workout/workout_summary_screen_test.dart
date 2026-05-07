import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/features/workout/providers/workout_summary_provider.dart';
import 'package:zirofit_fl/features/workout/screens/workout_summary_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier — returns a pre-configured state and ignores mutations
// ---------------------------------------------------------------------------

class FakeWorkoutSummaryNotifier extends WorkoutSummaryNotifier {
  FakeWorkoutSummaryNotifier(WorkoutSummaryState state) : super() {
    super.state = state;
  }

  @override
  void calculateSummary(
    WorkoutSession session, {
    required List<WorkoutSet> completedSets,
    Map<String, String>? exerciseNamesByLogId,
  }) {}

  @override
  void updatePersonalRecords(List<PersonalRecord> records) {}

  @override
  void reset() {}

  @override
  Future<void> saveAsTemplate(String sessionId, {String? name}) async {
    // No-op: pretends the API call succeeded
  }
}

// ---------------------------------------------------------------------------
// Widget builder helpers
// ---------------------------------------------------------------------------

Widget buildScreen(
  WorkoutSummaryState state, {
  WorkoutSession? session,
  List<ClientExerciseLog>? logs,
}) {
  final now = DateTime.now();
  final sess = session ??
      WorkoutSession(
        id: 's1',
        clientId: 'c1',
        name: 'Morning Pump',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        status: WorkoutSessionStatus.completed,
        isTrainerLed: false,
        createdAt: now,
        updatedAt: now,
      );

  return ProviderScope(
    overrides: [
      workoutSummaryProvider.overrideWith((ref) => FakeWorkoutSummaryNotifier(state)),
    ],
    child: MaterialApp(
      home: WorkoutSummaryScreen(
        session: sess,
        logs: logs ?? [],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

WorkoutSession createSession({
  String id = 's1',
  String name = 'Morning Pump',
  DateTime? startTime,
  DateTime? endTime,
}) {
  final now = DateTime.now();
  return WorkoutSession(
    id: id,
    clientId: 'c1',
    name: name,
    startTime: startTime ?? now.subtract(const Duration(hours: 1)),
    endTime: endTime ?? now,
    status: WorkoutSessionStatus.completed,
    isTrainerLed: false,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('WorkoutSummaryScreen', () {
    testWidgets('Test 1: Shows workout name and date', (t) async {
      final now = DateTime.now();
      final session = createSession(startTime: now, endTime: now);
      final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
      final expectedDate = dateFormat.format(now);

      await t.pumpWidget(
        buildScreen(
          const WorkoutSummaryState(),
          session: session,
        ),
      );
      // Let post-frame callback run
      await t.pump();

      // Workout name
      expect(find.text('Morning Pump'), findsOneWidget);

      // Date
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('Test 2: Shows total volume', (t) async {
      const state = WorkoutSummaryState(
        totalVolume: 5000,
        totalSets: 10,
        totalReps: 80,
      );

      await t.pumpWidget(buildScreen(state));
      await t.pump();

      // Volume displayed (as "5.0k" or "5000")
      expect(find.textContaining('5.0k'), findsOneWidget);
    });

    testWidgets('Test 3: Shows PRs when detected', (t) async {
      final prs = <PersonalRecord>[
        const PersonalRecord(
          exerciseName: 'Bench Press',
          type: 'weight',
          value: 100.0,
          previousValue: 90.0,
        ),
        const PersonalRecord(
          exerciseName: 'Squat',
          type: 'volume',
          value: 3000.0,
          previousValue: 2700.0,
        ),
      ];

      final state = WorkoutSummaryState(
        personalRecords: prs,
        totalSets: 8,
        totalReps: 60,
      );

      await t.pumpWidget(buildScreen(state));
      // Post-frame triggers setState + confetti animation
      await t.pump();
      // Allow confetti to start
      await t.pump(const Duration(milliseconds: 100));

      // PR section heading
      expect(find.text('New Personal Records!'), findsOneWidget);

      // PR exercise names
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // NEW badges
      expect(find.text('NEW'), findsNWidgets(2));
    });

    testWidgets('Test 4: Shows no-PR message when none detected', (t) async {
      const state = WorkoutSummaryState(
        personalRecords: [],
        totalSets: 5,
        totalReps: 40,
      );

      await t.pumpWidget(buildScreen(state));
      await t.pump();

      expect(
        find.text('No new personal records this time. Keep pushing!'),
        findsOneWidget,
      );

      // PR section heading should NOT be present
      expect(find.text('New Personal Records!'), findsNothing);
    });

    testWidgets('Test 5: Shows best set card', (t) async {
      final bestSet = WorkoutSet(
        id: 'best-1',
        logId: 'ex-bench',
        reps: 8,
        weight: 100.0,
        rpe: 8.5,
        isCompleted: true,
      );

      final summaries = <ExerciseSummary>[
        const ExerciseSummary(
          exerciseId: 'ex-bench',
          exerciseName: 'Bench Press',
          setsCompleted: 3,
          totalReps: 24,
          totalVolume: 2400,
          bestWeight: 100.0,
        ),
      ];

      final state = WorkoutSummaryState(
        bestSet: bestSet,
        exerciseSummaries: summaries,
        totalSets: 3,
        totalReps: 24,
        totalVolume: 2400,
      );

      await t.pumpWidget(buildScreen(state));
      await t.pump();

      // Best set label
      expect(find.text('Best Set'), findsOneWidget);

      // Exercise name appears in best set card AND exercise breakdown
      expect(find.text('Bench Press'), findsAtLeastNWidgets(1));

      // Metrics: weight, reps, e1RM
      expect(find.textContaining('100.0'), findsAtLeastNWidgets(1));
      expect(find.textContaining('8'), findsAtLeastNWidgets(1));

      // RPE
      expect(find.textContaining('8.5'), findsOneWidget);
    });

    testWidgets('Test 6: Shows exercise breakdown', (t) async {
      final summaries = <ExerciseSummary>[
        const ExerciseSummary(
          exerciseId: 'ex-bench',
          exerciseName: 'Bench Press',
          setsCompleted: 3,
          totalReps: 24,
          totalVolume: 1800,
          bestWeight: 80.0,
        ),
        const ExerciseSummary(
          exerciseId: 'ex-squat',
          exerciseName: 'Squat',
          setsCompleted: 4,
          totalReps: 32,
          totalVolume: 4000,
          bestWeight: 120.0,
        ),
      ];

      final state = WorkoutSummaryState(
        exerciseSummaries: summaries,
        totalSets: 7,
        totalReps: 56,
        totalVolume: 5800,
      );

      await t.pumpWidget(buildScreen(state));
      await t.pump();

      // Exercise names visible
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // Set counts
      expect(find.textContaining('3 sets'), findsOneWidget);
      expect(find.textContaining('4 sets'), findsOneWidget);

      // Volume per exercise
      expect(find.textContaining('1800'), findsOneWidget);
      expect(find.textContaining('4000'), findsOneWidget);
    });

    testWidgets('Test 7: Done navigates to dashboard (pops to first route)',
        (t) async {
      final session = createSession();
      final state = const WorkoutSummaryState(
        totalSets: 5,
        totalReps: 40,
      );

      // Create a navigator with two routes: home → summary
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSummaryProvider
                .overrideWith((ref) => FakeWorkoutSummaryNotifier(state)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutSummaryScreen(
                        session: session,
                        logs: [],
                      ),
                    ),
                  ),
                  child: const Text('Show Summary'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      // Navigate to summary screen
      await t.tap(find.text('Show Summary'));
      await t.pumpAndSettle();

      // Verify we're on the summary screen
      expect(find.text('Done'), findsOneWidget);

      // Tap Done
      await t.tap(find.widgetWithText(FilledButton, 'Done'));
      await t.pumpAndSettle();

      // Verify we're back on the home screen (summary widgets gone)
      expect(find.text('Show Summary'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('Test 8: Shows "Save as Template" button', (t) async {
      await t.pumpWidget(buildScreen(const WorkoutSummaryState()));
      await t.pump();

      expect(find.text('Save as Template'), findsOneWidget);
    });

    testWidgets('Test 9: Tapping "Save as Template" shows name prompt',
        (t) async {
      await t.pumpWidget(buildScreen(const WorkoutSummaryState()));
      await t.pump();

      await t.tap(find.text('Save as Template'));
      await t.pump();

      // Dialog elements
      expect(find.text('Save as Template'), findsAtLeastNWidgets(1));
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('Test 10: Successful save shows snackbar', (t) async {
      await t.pumpWidget(buildScreen(const WorkoutSummaryState()));
      await t.pump();

      // Open dialog
      await t.tap(find.text('Save as Template'));
      await t.pump();

      // Enter a template name
      await t.enterText(find.byType(TextField), 'My Template');

      // Tap Save
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await t.pump();

      // Snackbar should appear
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });
  });
}
