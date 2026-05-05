import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/screens/active_workout_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends ActiveWorkoutNotifier {
  final ActiveWorkoutState _s;
  Fake(this._s)
    : super(remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance)) {
    super.state = _s;
  }
  @override
  ActiveWorkoutState get state => _s;
  @override
  Future<void> startWorkout({String? templateId}) async {}
  @override
  Future<void> loadActiveSession() async {}
  @override
  Future<void> logExercise({
    required String exerciseId,
    int? reps,
    double? weight,
  }) async {}
  @override
  Future<void> completeSet(String logId) async {}
  @override
  Future<WorkoutSession?> finishWorkout() async => null;
  @override
  Future<void> cancelWorkout() async {}
  @override
  Future<void> startRest() async {}
  @override
  Future<void> endRest() async {}
  @override
  void clearError() {}
  @override
  void reset() {}
}

Widget b(ActiveWorkoutState s) => ProviderScope(
  overrides: [activeWorkoutProvider.overrideWith((ref) => Fake(s))],
  child: const MaterialApp(home: ActiveWorkoutScreen()),
);

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  testWidgets('loading', (t) async {
    await t.pumpWidget(b(const ActiveWorkoutState(isLoading: true)));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('idle', (t) async {
    await t.pumpWidget(b(const ActiveWorkoutState()));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('No active workout'), findsOneWidget);
    expect(find.text('Start a new workout to begin tracking.'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start Workout'), findsOneWidget);
  });

  testWidgets('active — shows session name and action buttons', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      name: 'Morning Pump',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(b(ActiveWorkoutState(session: sess, isLoading: false)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    // AppBar title
    expect(find.text('Morning Pump'), findsOneWidget);
    // Bottom action buttons
    expect(find.widgetWithText(FilledButton, 'Add Set'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Finish Workout'),
      findsOneWidget,
    );
  });

  testWidgets('active — shows cancel button in AppBar', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(b(ActiveWorkoutState(session: sess, isLoading: false)));
    await t.pump();

    // IconButton with Icons.close should be present (tooltip 'Cancel workout')
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byTooltip('Cancel workout'), findsOneWidget);
  });

  testWidgets('active with logs — renders exercise log list', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    // Use exerciseId with at least 8 chars for _formatExerciseName
    final log = ClientExerciseLog(
      id: 'log-1',
      clientId: 'c1',
      exerciseId: 'ex-123456', // 9 chars → displayed as 'ex-12345…'
      reps: 10,
      weight: 80.0,
      side: 'BOTH',
      workoutSessionId: '1',
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(ActiveWorkoutState(session: sess, logs: [log], isLoading: false)),
    );
    await t.pump();

    // Log list item appears with truncated exercise ID (first 8 chars + ellipsis)
    expect(find.text('Exercise: ex-12345…'), findsOneWidget);
    expect(find.text('80.0 kg × 10 reps'), findsOneWidget);
    // Completed should be false → outline icon
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    // Complete set button
    expect(find.byTooltip('Complete set'), findsOneWidget);
  });

  testWidgets('completed log — shows checkmark icon', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    // Use exerciseId with at least 8 chars to avoid substring error
    final completedLog = ClientExerciseLog(
      id: 'log-1',
      clientId: 'c1',
      exerciseId: 'ex-abcdefg', // 9 chars
      reps: 10,
      weight: 80.0,
      isCompleted: true,
      side: 'BOTH',
      workoutSessionId: '1',
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(
        ActiveWorkoutState(
          session: sess,
          logs: [completedLog],
          isLoading: false,
        ),
      ),
    );
    await t.pump();

    // Completed indicator
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });

  testWidgets('empty logs — renders empty state', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(ActiveWorkoutState(session: sess, logs: const [], isLoading: false)),
    );
    await t.pump();

    expect(find.text('Log your first set'), findsOneWidget);
    expect(
      find.text('Tap "Add Set" to log an exercise with weight and reps.'),
      findsOneWidget,
    );
  });

  testWidgets('rest timer card visible when restSeconds > 0', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(
        ActiveWorkoutState(
          session: sess,
          restSeconds: 90,
          isRestRunning: false,
          isLoading: false,
        ),
      ),
    );
    await t.pump();

    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget); // 90 seconds
    expect(find.widgetWithText(FilledButton, 'Start'), findsOneWidget);
  });

  testWidgets('rest timer running shows End button', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(
        ActiveWorkoutState(
          session: sess,
          restSeconds: 45,
          isRestRunning: true,
          isLoading: false,
        ),
      ),
    );
    await t.pump();

    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('00:45'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'End'), findsOneWidget);
  });

  testWidgets('error banner shows when error present', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(
        ActiveWorkoutState(
          session: sess,
          error: 'Network error',
          isLoading: false,
        ),
      ),
    );
    await t.pump();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'DISMISS'), findsOneWidget);
  });

  testWidgets('Add Set button opens dialog', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(b(ActiveWorkoutState(session: sess, isLoading: false)));
    await t.pump();

    // Tap Add Set
    await t.tap(find.widgetWithText(FilledButton, 'Add Set'));
    await t.pumpAndSettle();

    // Dialog appears
    expect(find.text('Log Exercise Set'), findsOneWidget);
    expect(find.text('Exercise ID'), findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log Set'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('rest timer', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      name: 'Test',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(
        ActiveWorkoutState(
          session: sess,
          restSeconds: 75,
          isRestRunning: true,
          isLoading: false,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('01:15'), findsOneWidget);
  });

  testWidgets('error', (t) async {
    await t.pumpWidget(
      b(const ActiveWorkoutState(isLoading: false, error: 'err')),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Retry'), findsOneWidget);
  });
}
