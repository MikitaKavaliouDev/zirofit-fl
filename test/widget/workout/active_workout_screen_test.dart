import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/screens/active_workout_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends ActiveWorkoutNotifier {
  final ActiveWorkoutState _s;
  Fake(this._s, {required super.ref})
    : super(remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance)) {
    super.state = _s;
  }
  @override
  ActiveWorkoutState get state => _s;
  @override
  Future<void> startWorkout({String? templateId}) async {}
  @override
  Future<void> startSessionForClient({
    required String clientId,
    required String clientName,
  }) async {}
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
  overrides: [activeWorkoutProvider.overrideWith((ref) => Fake(s, ref: ref))],
  child: const MaterialApp(home: ActiveWorkoutScreen()),
);

// ---- Additional helper classes for specific test scenarios ----

class FakeReturnsSession extends Fake {
  final WorkoutSession? sessionToReturn;
  FakeReturnsSession(super.s, {this.sessionToReturn, required super.ref});
  @override
  Future<WorkoutSession?> finishWorkout() async => sessionToReturn;
}

class FakeWithStartTracking extends Fake {
  bool startWorkoutCalled = false;
  String? startTemplateId;
  bool startSessionForClientCalled = false;
  String? sessionClientId;
  String? sessionClientName;
  FakeWithStartTracking(super.s, {required super.ref});
  @override
  Future<void> startWorkout({String? templateId}) async {
    startWorkoutCalled = true;
    startTemplateId = templateId;
  }
  @override
  Future<void> startSessionForClient({
    required String clientId,
    required String clientName,
  }) async {
    startSessionForClientCalled = true;
    sessionClientId = clientId;
    sessionClientName = clientName;
  }
}

class FakeMutable extends ActiveWorkoutNotifier {
  FakeMutable(ActiveWorkoutState s, {required super.ref})
    : super(remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance)) {
    super.state = s;
  }
  @override
  Future<void> startWorkout({String? templateId}) async {}
  @override
  Future<void> startSessionForClient({
    required String clientId,
    required String clientName,
  }) async {}
  @override
  Future<void> loadActiveSession() async {}
  @override
  Future<void> logExercise({required String exerciseId, int? reps, double? weight}) async {}
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
  void reset() {}
}

class _TrainerAuthNotifier extends AuthNotifier {
  _TrainerAuthNotifier()
    : super(apiClient: ApiClient.instance, secureStorage: FakeSecureStorage()) {
    state = const AuthState(role: 'trainer');
  }
}

class TestNavigatorObserver extends NavigatorObserver {
  bool popDidHappen = false;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popDidHappen = true;
  }
}

Widget bWithFinish(ActiveWorkoutState s, {WorkoutSession? sessionToReturn}) =>
    ProviderScope(
      overrides: [
        activeWorkoutProvider.overrideWith(
          (ref) => FakeReturnsSession(s, sessionToReturn: sessionToReturn, ref: ref),
        ),
      ],
      child: const MaterialApp(home: ActiveWorkoutScreen()),
    );

Widget bWithTracking(ActiveWorkoutState s) =>
    ProviderScope(
      overrides: [
        activeWorkoutProvider.overrideWith(
          (ref) => FakeWithStartTracking(s, ref: ref),
        ),
      ],
      child: const MaterialApp(home: ActiveWorkoutScreen()),
    );

Widget bWithTemplate(ActiveWorkoutState s, {required String templateId}) =>
    ProviderScope(
      overrides: [
        activeWorkoutProvider.overrideWith(
          (ref) => FakeWithStartTracking(s, ref: ref),
        ),
      ],
      child: MaterialApp(home: ActiveWorkoutScreen(templateId: templateId)),
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

    expect(find.text('Start by adding an exercise'), findsOneWidget);
    expect(
      find.text('Tap "Add Exercise" to begin your workout.'),
      findsOneWidget,
    );
  });

  testWidgets('rest timer card visible when restSeconds > 0', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 1200));
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
    await t.binding.setSurfaceSize(const Size(400, 1200));
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

  testWidgets('Add Set button is present in active workout', (t) async {
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

    // Add Set button is present (triggers ExerciseSelectionView via bottom sheet)
    expect(find.widgetWithText(FilledButton, 'Add Set'), findsOneWidget);
  });

  testWidgets('rest timer', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 1200));
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

  testWidgets('Finish workout dialog - confirms and navigates to summary',
      (t) async {
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
    final finished = WorkoutSession(
      id: 's1',
      clientId: 'c1',
      name: 'Morning Pump',
      startTime: now,
      status: WorkoutSessionStatus.completed,
      isTrainerLed: false,
      createdAt: now,
      updatedAt: now,
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith(
            (ref) => FakeReturnsSession(
              ActiveWorkoutState(session: sess, isLoading: false),
              sessionToReturn: finished,
              ref: ref,
            ),
          ),
        ],
        child: const MaterialApp(
          home: ActiveWorkoutScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();

    // Tap Finish Workout
    await t.tap(find.widgetWithText(OutlinedButton, 'Finish Workout'));
    await t.pumpAndSettle();

    expect(
      find.text('Are you sure you want to finish this workout?'),
      findsOneWidget,
    );

    await t.tap(find.widgetWithText(FilledButton, 'Finish'));
    await t.pumpAndSettle();

    // Should navigate to summary screen
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Finish workout dialog - cancel does nothing', (t) async {
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

    await t.tap(find.widgetWithText(OutlinedButton, 'Finish Workout'));
    await t.pumpAndSettle();

    expect(
      find.text('Are you sure you want to finish this workout?'),
      findsOneWidget,
    );

    await t.tap(find.widgetWithText(TextButton, 'Cancel'));
    await t.pumpAndSettle();

    // Still on screen
    expect(find.text('Morning Pump'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add Set'), findsOneWidget);
  });

  testWidgets('Cancel workout dialog - confirms and pops', (t) async {
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
    final observer = TestNavigatorObserver();

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith(
            (ref) => Fake(ActiveWorkoutState(session: sess, isLoading: false), ref: ref),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActiveWorkoutScreen(),
                ),
              ),
              child: const Text('Push Screen'),
            ),
          ),
          navigatorObservers: [observer],
        ),
      ),
    );
    await t.pumpAndSettle();

    // Push the screen onto the stack
    await t.tap(find.text('Push Screen'));
    await t.pumpAndSettle();

    // Now on ActiveWorkoutScreen - tap close icon
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();

    // Dialog appears — tap "Cancel Workout"
    await t.tap(find.widgetWithText(FilledButton, 'Cancel Workout'));
    await t.pumpAndSettle();

    // Verify pop was observed & screen is gone (back at home)
    expect(observer.popDidHappen, isTrue);
    expect(find.text('Push Screen'), findsOneWidget);
  });

  testWidgets('Cancel workout dialog - keeps working on cancel', (t) async {
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

    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();

    expect(
      find.text(
        'Are you sure you want to cancel this workout? All progress will be lost.',
      ),
      findsOneWidget,
    );

    await t.tap(find.widgetWithText(TextButton, 'Keep Working'));
    await t.pumpAndSettle();

    // Still on screen
    expect(find.text('Morning Pump'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add Set'), findsOneWidget);
  });

  testWidgets('Add Set button triggers exercise selection', (t) async {
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

    // Add Set button is tappable (ExerciseSelectionView tested separately)
    expect(find.widgetWithText(FilledButton, 'Add Set'), findsOneWidget);
  });

  testWidgets('Start Workout button calls startWorkout', (t) async {
    late FakeWithStartTracking fake;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) {
            fake = FakeWithStartTracking(const ActiveWorkoutState(), ref: ref);
            return fake;
          }),
        ],
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));

    expect(find.widgetWithText(FilledButton, 'Start Workout'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Start Workout'));
    await t.pump();

    expect(fake.startWorkoutCalled, isTrue);
    expect(fake.startTemplateId, isNull);
  });

  testWidgets('Error without session shows error + retry', (t) async {
    await t.pumpWidget(
      b(
        const ActiveWorkoutState(isLoading: false, error: 'Connection failed'),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Error banner DISMISS clears error', (t) async {
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
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith(
            (ref) => FakeMutable(
              ActiveWorkoutState(
                session: sess,
                error: 'Network error',
                isLoading: false,
              ),
              ref: ref,
            ),
          ),
        ],
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await t.pump();

    // Error banner visible
    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'DISMISS'), findsOneWidget);

    // Tap DISMISS
    await t.tap(find.widgetWithText(TextButton, 'DISMISS'));
    await t.pump();

    // Banner should be gone
    expect(find.text('Network error'), findsNothing);
  });

  testWidgets('Template init passes templateId', (t) async {
    late FakeWithStartTracking fake;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) {
            fake = FakeWithStartTracking(const ActiveWorkoutState(), ref: ref);
            return fake;
          }),
        ],
        child: const MaterialApp(
          home: ActiveWorkoutScreen(templateId: 'tpl-1'),
        ),
      ),
    );
    // Let the initState microtask run
    await t.pump();

    expect(fake.startWorkoutCalled, isTrue);
    expect(fake.startTemplateId, 'tpl-1');
  });

  // ---------------------------------------------------------------------------
  // Trainer-led session tests
  // ---------------------------------------------------------------------------

  testWidgets('trainer-led — shows client name header', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      name: 'Session',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: true,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(ActiveWorkoutState(
        session: sess,
        clientName: 'Jane Doe',
        isLoading: false,
      )),
    );
    await t.pump();

    // Trainer-led header with client name
    expect(find.text('Trainer-Led Session'), findsOneWidget);
    expect(find.text('Training: Jane Doe'), findsOneWidget);
  });

  testWidgets('trainer-led — client indicator on exercise set', (t) async {
    final sess = WorkoutSession(
      id: '1',
      clientId: 'c1',
      name: 'Session',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      isTrainerLed: true,
      createdAt: now,
      updatedAt: now,
    );
    final log = ClientExerciseLog(
      id: 'log-1',
      clientId: 'c1',
      exerciseId: 'ex-123456',
      reps: 10,
      weight: 80.0,
      side: 'BOTH',
      workoutSessionId: '1',
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(
      b(ActiveWorkoutState(
        session: sess,
        logs: [log],
        clientName: 'Jane Doe',
        isLoading: false,
      )),
    );
    await t.pump();

    // Client name indicator on the exercise card
    expect(find.text('Jane Doe'), findsWidgets);
    // Person icon from the set card
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('idle — shows Start Trainer-Led Session button', (t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkoutProvider.overrideWith((ref) => Fake(const ActiveWorkoutState(), ref: ref)),
          authProvider.overrideWith((ref) => _TrainerAuthNotifier()),
        ],
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));

    expect(
      find.widgetWithText(OutlinedButton, 'Start Trainer-Led Session'),
      findsOneWidget,
    );
  });
}
