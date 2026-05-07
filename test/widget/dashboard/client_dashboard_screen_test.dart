import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
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

class FakeCD extends ClientDashboardNotifier {
  final ClientDashboardState _s;
  FakeCD(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  ClientDashboardState get state => _s;
  @override
  Future<void> fetchDashboard() async {}
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
  return ClientProgramsState(
    activeProgram: WorkoutProgram(
      id: 'prog-1',
      name: 'Test Program',
      createdAt: now,
      updatedAt: now,
    ),
    templates: [
      WorkoutTemplate(
        id: 't1',
        name: 'Template 1',
        programId: 'prog-1',
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

ClientDashboardState get loadedState => ClientDashboardState(
  status: ClientDashboardStatus.loaded,
  data: ClientDashboardData.mock(),
);

ClientDashboardState get completedCheckInState {
  final mock = ClientDashboardData.mock();
  final completedStatus = CheckInStatus(
    isDueToday: false,
    isCompleted: true,
    lastCheckInDate: DateTime(2026, 5, 1),
    nextCheckInDate: DateTime(2026, 5, 8),
  );
  final data = ClientDashboardData(
    lastWorkout: mock.lastWorkout,
    upcomingSessions: mock.upcomingSessions,
    checkInStatus: completedStatus,
    progress: mock.progress,
    trainerName: mock.trainerName,
  );
  return ClientDashboardState(
    status: ClientDashboardStatus.loaded,
    data: data,
  );
}

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
        builder: (_, __) => dashboardScreen,
      ),
      GoRoute(
        path: '/client/workout',
        builder: (_, __) => const _TestRoute(label: 'Workout Screen'),
      ),
      GoRoute(
        path: '/client/daily-targets',
        builder: (_, __) => const _TestRoute(label: 'Daily Targets Screen'),
      ),
      GoRoute(
        path: '/client/check-in',
        builder: (_, __) => const _TestRoute(label: 'Check-in'),
        routes: [
          GoRoute(
            path: 'history',
            builder: (_, __) =>
                const _TestRoute(label: 'Check-in History Screen'),
          ),
        ],
      ),
    ],
  );
}

Widget buildTestWidget({
  required ClientDashboardState dashboardState,
  ClientProgramsState? programsState,
  DailyTargetState? dailyTargetState,
  WorkoutHistoryState? historyState,
  AuthState? authState,
}) {
  final router = _createTestRouter(const ClientDashboardScreen());

  return ProviderScope(
    overrides: [
      clientDashboardProvider.overrideWith((ref) => FakeCD(dashboardState)),
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
  Future<void> _pumpApp(WidgetTester t, Widget widget, {bool showOverlay = false}) async {
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
    await _pumpApp(t, buildTestWidget(
      dashboardState: const ClientDashboardState(
        status: ClientDashboardStatus.loading,
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loaded state shows dashboard content', (t) async {
    await _pumpApp(t, buildTestWidget(
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
    await t.pumpWidget(buildTestWidget(
      dashboardState: const ClientDashboardState(
        status: ClientDashboardStatus.error,
        error: 'Something went wrong',
      ),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });

  // -----------------------------------------------------------------------
  // 2. Quick Start → /client/workout
  // -----------------------------------------------------------------------

  testWidgets('Quick Start navigates to empty workout', (t) async {
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

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
  // 3. Templates → template picker (Navigator.push)
  // -----------------------------------------------------------------------

  testWidgets('Templates navigates to template picker', (t) async {
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

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
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

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
    await _pumpApp(t, buildTestWidget(
      dashboardState: completedCheckInState,
    ));

    expect(find.text('Check-in Complete'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
  });

  testWidgets('View History link navigates to check-in history', (t) async {
    await _pumpApp(t, buildTestWidget(
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
  // 6. Session tap → detail screen (Navigator.push)
  // -----------------------------------------------------------------------

  testWidgets('Upcoming session tap navigates to session detail', (t) async {
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

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
    await _pumpApp(t, buildTestWidget(
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
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState), showOverlay: true);

    expect(find.text('Welcome to Your Dashboard'), findsOneWidget);
    expect(find.text('Got it!'), findsOneWidget);
  });

  testWidgets('educational overlay not shown after dismiss', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState), showOverlay: true);

    expect(find.text('Welcome to Your Dashboard'), findsOneWidget);

    await t.tap(find.text('Got it!'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);

    // Rebuild — overlay persists via SharedPrefs
    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);
  });

  testWidgets('educational overlay not shown when already seen', (t) async {
    SharedPreferences.setMockInitialValues({
      'dashboard_education_seen': true,
    });

    await _pumpApp(t, buildTestWidget(dashboardState: loadedState));

    expect(find.text('Welcome to Your Dashboard'), findsNothing);
    expect(find.text('Got it!'), findsNothing);
  });
}
