import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/active_program_progress.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/data/models/active_program_template.dart';
import 'package:zirofit_fl/data/models/enums/template_step_status.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/providers/measurement_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/screens/client_dashboard_screen.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

/// A fake [ClientDashboardNotifier] whose `build()` never completes,
/// keeping the provider in [AsyncLoading] permanently.
class LoadingClientDashboardNotifier extends ClientDashboardNotifier {
  @override
  Future<ClientDashboardData> build() async =>
      // ignore: literal_only_expression
      Completer<ClientDashboardData>().future;

  @override
  Future<void> refresh() async {}

  @override
  void markCheckInCompleted() {}
}

/// Holds the desired test state for [DataClientDashboardNotifier].
/// Set before each test via [buildTestWidget].
AsyncValue<ClientDashboardData>? _testDashboardState;

/// A fake [ClientDashboardNotifier] that completes `build()` with the
/// value stored in [_testDashboardState].
class DataClientDashboardNotifier extends ClientDashboardNotifier {
  @override
  Future<ClientDashboardData> build() async {
    final s = _testDashboardState!;
    return s.maybeWhen(
      data: (d) => d,
      orElse: () => throw (s is AsyncError
          ? (s as AsyncError).error
          : Exception('Unknown state')),
    );
  }

  @override
  Future<void> refresh() async {}

  @override
  void markCheckInCompleted() {}
}

class FakeAuth extends AuthNotifier {
  final AuthState _s;
  FakeAuth(this._s)
      : super(
          apiClient: ApiClient.instance,
          secureStorage: FakeSecureStorage(),
        ) {
    super.state = _s;
  }
  @override
  AuthState get state => _s;
}

class FakeDailyTarget extends DailyTargetNotifier {
  final DailyTargetState _s;
  FakeDailyTarget(this._s) {
    _testState = _s;
  }
  DailyTargetState _testState = const DailyTargetState();
  @override
  DailyTargetState get state => _testState;
  @override
  set state(DailyTargetState value) => _testState = value;
  @override
  Future<void> loadTargets(DateTime date) async {}
  @override
  Future<void> addTarget(DailyTarget target) async {}
  @override
  Future<void> toggleCompleted(String id) async {}
  @override
  Future<void> removeTarget(String id) async {}
  @override
  Future<void> updateProgress(String id, double value) async {}
}

class FakePrograms extends ClientProgramsNotifier {
  final ClientProgramsState _s;
  FakePrograms(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  ClientProgramsState get state => _s;
  @override
  Future<void> fetchPrograms() async {}
}

class FakeHistory extends WorkoutHistoryNotifier {
  final WorkoutHistoryState _s;
  FakeHistory(this._s)
      : super(
          remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance),
        ) {
    super.state = _s;
  }
  @override
  WorkoutHistoryState get state => _s;
  @override
  Future<void> fetchHistory() async {}
  @override
  Future<void> refresh() async {}
}

class FakeMeasurement extends ClientMeasurementNotifier {
  final ClientMeasurementState _s;
  FakeMeasurement(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  ClientMeasurementState get state => _s;
  @override
  Future<void> fetchMeasurements() async {}
  @override
  Future<String?> addMeasurement({
    required double? weightKg,
    required double? bodyFatPercentage,
    DateTime? measurementDate,
    String? notes,
  }) async => null;
}

// ---------------------------------------------------------------------------
// Navigator observer
// ---------------------------------------------------------------------------

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

// ---------------------------------------------------------------------------
// State/Data helpers
// ---------------------------------------------------------------------------

AuthState get defaultAuth => const AuthState(
  status: AuthStatus.authenticated,
  user: User(id: '1', email: 'c@t.com', name: 'TC'),
);

ClientProgramsState get activeProgramState {
  final now = DateTime.now();
  final program = WorkoutProgram(
    id: 'prog-1',
    name: 'Test Program',
    createdAt: now,
    updatedAt: now,
  );

  const progress = ActiveProgramProgress(
    completedCount: 0,
    totalCount: 1,
    progressPercentage: 0,
  );

  final activeTemplate = ActiveProgramTemplate(
    id: 't1',
    name: 'Template 1',
    programId: 'prog-1',
    order: 0,
    status: TemplateStepStatus.pending,
    createdAt: now,
    updatedAt: now,
  );

  final response = ActiveProgramResponse(
    program: program,
    progress: progress,
    templates: [activeTemplate],
  );

  return ClientProgramsState(
    activeProgramResponse: response,
    isLoading: false,
  );
}

/// Constructs a [ClientDashboardData] with realistic test values.
ClientDashboardData createTestDashboardData({
  bool checkInCompleted = false,
}) {
  final now = DateTime(2026, 5, 5);
  final today = DateTime(now.year, now.month, now.day);

  return ClientDashboardData(
    lastWorkout: LastWorkoutSummary(
      date: now.subtract(const Duration(days: 1)),
      exercisesCompleted: 8,
      totalExercises: 10,
      duration: const Duration(minutes: 45),
      caloriesBurned: 0,
    ),
    upcomingSessions: [
      WorkoutSession(
        id: '1',
        clientId: 'my-client-id',
        name: 'Upper Body Strength',
        startTime: today.add(const Duration(days: 1, hours: 10)),
        status: WorkoutSessionStatus.planned,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
      WorkoutSession(
        id: '2',
        clientId: 'my-client-id',
        name: 'Cardio & Core',
        startTime: today.add(const Duration(days: 2, hours: 14)),
        status: WorkoutSessionStatus.planned,
        isTrainerLed: false,
        createdAt: now,
        updatedAt: now,
      ),
      WorkoutSession(
        id: '3',
        clientId: 'my-client-id',
        name: 'Full Body HIIT',
        startTime: today.add(const Duration(days: 4, hours: 9)),
        status: WorkoutSessionStatus.planned,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    checkInStatus: CheckInStatus(
      isDueToday: !checkInCompleted,
      isCompleted: checkInCompleted,
      lastCheckInDate: checkInCompleted ? DateTime(2026, 5, 1) : null,
      nextCheckInDate: null,
    ),
    progress: const ProgressSummary(
      weightChange: -2.5,
      workoutStreak: 7,
      totalWorkoutsThisMonth: 12,
      currentWeight: 75.0,
      startingWeight: 77.5,
    ),
    trainerName: 'Coach Sarah',
  );
}

AsyncValue<ClientDashboardData> get loadedState =>
    AsyncData(createTestDashboardData());

AsyncValue<ClientDashboardData> get completedCheckInState =>
    AsyncData(createTestDashboardData(checkInCompleted: true));

WorkoutSession get historySession {
  final now = DateTime.now();
  return WorkoutSession(
    id: 'hist-1',
    clientId: 'c1',
    name: 'Past Workout',
    startTime: now.subtract(const Duration(days: 1)),
    endTime: now.subtract(const Duration(days: 1, hours: -1)),
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Test router & widget builder
// ---------------------------------------------------------------------------

/// A test route widget with a unique label used for verifying destination.
class _TestRoute extends StatelessWidget {
  final String label;
  const _TestRoute({required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label, style: const TextStyle(fontSize: 24))),
    );
  }
}

GoRouter _createTestRouter(Widget dashboardScreen) {
  return GoRouter(
    initialLocation: '/client/dashboard',
    routes: [
      GoRoute(
        path: '/client/dashboard',
        builder: (_, _) => dashboardScreen,
      ),
      GoRoute(
        path: '/client/workout',
        builder: (_, _) => const _TestRoute(label: 'Workout Screen'),
      ),
      GoRoute(
        path: '/client/daily-targets',
        builder: (_, _) => const _TestRoute(label: 'Daily Targets Screen'),
      ),
      GoRoute(
        path: '/client/check-in',
        builder: (_, _) => const _TestRoute(label: 'Check-in'),
        routes: [
          GoRoute(
            path: 'history',
            builder: (_, _) =>
                const _TestRoute(label: 'Check-in History Screen'),
          ),
        ],
      ),
    ],
  );
}

Widget buildTestWidget({
  required AsyncValue<ClientDashboardData> dashboardState,
  ClientProgramsState? programsState,
  DailyTargetState? dailyTargetState,
  WorkoutHistoryState? historyState,
  AuthState? authState,
}) {
  _testDashboardState = dashboardState;
  final router = _createTestRouter(const ClientDashboardScreen());

  return ProviderScope(
    overrides: [
      clientDashboardProvider.overrideWith(
        () => DataClientDashboardNotifier(),
      ),
      authProvider.overrideWith((ref) => FakeAuth(authState ?? defaultAuth)),
      dailyTargetProvider.overrideWith(
        (ref) => FakeDailyTarget(dailyTargetState ?? const DailyTargetState()),
      ),
      clientProgramsProvider.overrideWith(
        (ref) => FakePrograms(programsState ?? const ClientProgramsState()),
      ),
      workoutHistoryProvider.overrideWith(
        (ref) => FakeHistory(historyState ?? const WorkoutHistoryState()),
      ),
      clientMeasurementProvider.overrideWith(
        (ref) => FakeMeasurement(const ClientMeasurementState()),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Use a large surface so all dashboard sections are visible + tappable.
  /// Sets SharedPreferences to suppress the educational overlay by default.
  Future<void> pumpApp(WidgetTester t, Widget widget, {bool showOverlay = false}) async {
    if (!showOverlay) {
      SharedPreferences.setMockInitialValues({'dashboard_education_seen': true});
    }
    await t.binding.setSurfaceSize(const Size(800, 4000));
    await t.pumpWidget(widget);
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
  }

  // -----------------------------------------------------------------------
  // 1. Existing tests (regression)
  // -----------------------------------------------------------------------

  testWidgets('loading state shows spinner', (t) async {
    _testDashboardState = null; // ensure no stale state
    final router = _createTestRouter(const ClientDashboardScreen());
    await pumpApp(t, ProviderScope(
      overrides: [
        clientDashboardProvider.overrideWith(
          () => LoadingClientDashboardNotifier(),
        ),
        authProvider.overrideWith((ref) => FakeAuth(defaultAuth)),
        dailyTargetProvider.overrideWith(
          (ref) => FakeDailyTarget(const DailyTargetState()),
        ),
        clientProgramsProvider.overrideWith(
          (ref) => FakePrograms(const ClientProgramsState()),
        ),
        workoutHistoryProvider.overrideWith(
          (ref) => FakeHistory(const WorkoutHistoryState()),
        ),
        clientMeasurementProvider.overrideWith(
          (ref) => FakeMeasurement(const ClientMeasurementState()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loaded state shows dashboard content', (t) async {
    await pumpApp(t, buildTestWidget(
      dashboardState: loadedState,
      programsState: activeProgramState,
      historyState: WorkoutHistoryState(
        sessions: [historySession],
        isLoading: false,
        hasMore: false,
      ),
    ));

    expect(find.text('Hello,'), findsAtLeastNWidgets(1));
    expect(find.text('Start Session'), findsOneWidget);
    expect(find.text('Last Workout'), findsOneWidget);
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
  });

  testWidgets('error state shows retry button', (t) async {
    await pumpApp(t, buildTestWidget(
      dashboardState: AsyncError<ClientDashboardData>(
        Exception('Something went wrong'),
        StackTrace.current,
      ),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });

  // -----------------------------------------------------------------------
  // 2. Quick Start → /client/workout
  // -----------------------------------------------------------------------

  testWidgets('Quick Start navigates to empty workout', (t) async {
    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    final qs = find.text('Quick Start');
    await t.ensureVisible(qs);
    await t.pump();
    await t.tap(qs);
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Workout Screen'), findsAtLeastNWidgets(1));
  });

  // -----------------------------------------------------------------------
  // 3. Templates → Navigator.push
  // -----------------------------------------------------------------------

  testWidgets('Templates navigates to template picker', (t) async {
    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    final templates = find.text('Templates');
    await t.ensureVisible(templates);
    await t.pump();
    await t.tap(templates);
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Workout Templates'), findsOneWidget);
  });

  // -----------------------------------------------------------------------
  // 4. Daily Target "Add" → /client/daily-targets
  // -----------------------------------------------------------------------

  testWidgets('Daily target Add navigates to management screen', (t) async {
    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    final cta = find.text('Set a Daily Target');
    await t.ensureVisible(cta);
    await t.pump();
    await t.tap(cta);

    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Daily Targets Screen'), findsAtLeastNWidgets(1));
  });

  // -----------------------------------------------------------------------
  // 5. Check-in Complete → View History → /client/check-in/history
  // -----------------------------------------------------------------------

  testWidgets('Check-in complete banner shows View History link', (t) async {
    await pumpApp(t, buildTestWidget(
      dashboardState: completedCheckInState,
    ));

    expect(find.text('Check-in Complete'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
  });

  testWidgets('View History link navigates to check-in history', (t) async {
    await pumpApp(t, buildTestWidget(
      dashboardState: completedCheckInState,
    ));

    final vh = find.text('View History');
    await t.ensureVisible(vh);
    await t.pump();
    await t.tap(vh);

    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Check-in History Screen'), findsAtLeastNWidgets(1));
  });

  // -----------------------------------------------------------------------
  // 6. Session tap → detail screen
  // -----------------------------------------------------------------------

  testWidgets('Upcoming session tap navigates to session detail', (t) async {
    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    final sn = find.text('Upper Body Strength');
    await t.ensureVisible(sn);
    await t.pump();
    await t.tap(sn);
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Session Details'), findsOneWidget);
  });

  testWidgets('Recent history tile tap navigates to session detail',
      (t) async {
    await pumpApp(t, buildTestWidget(
      dashboardState: loadedState,
      historyState: WorkoutHistoryState(
        sessions: [historySession],
        isLoading: false,
        hasMore: false,
      ),
    ));

    final pw = find.text('Past Workout');
    await t.ensureVisible(pw);
    await t.pump();
    await t.tap(pw);
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Session Details'), findsOneWidget);
  });

  // -----------------------------------------------------------------------
  // 7 – 8. Educational overlay
  // -----------------------------------------------------------------------

  testWidgets('educational overlay shows on first visit', (t) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(t, buildTestWidget(dashboardState: loadedState), showOverlay: true);

    expect(find.text('Welcome to Your Dashboard'), findsOneWidget);
    expect(find.text('Got it!'), findsOneWidget);
  });

  testWidgets('educational overlay not shown after dismiss', (t) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(t, buildTestWidget(dashboardState: loadedState), showOverlay: true);

    expect(find.text('Welcome to Your Dashboard'), findsOneWidget);

    await t.tap(find.text('Got it!'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);

    // Rebuild — overlay persists via SharedPrefs
    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);
  });

  testWidgets('educational overlay not shown when already seen', (t) async {
    SharedPreferences.setMockInitialValues({
      'dashboard_education_seen': true,
    });

    await pumpApp(t, buildTestWidget(dashboardState: loadedState));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);
    expect(find.text('Got it!'), findsNothing);
  });
}
