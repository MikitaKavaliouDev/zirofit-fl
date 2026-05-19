import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/clients/providers/live_session_provider.dart';
import 'package:zirofit_fl/features/clients/screens/live_session_monitor_screen.dart';
import '../../helpers/test_setup.dart';

/// A fake [LiveSessionNotifier] that does not make real API calls.
class FakeLiveSessionNotifier extends LiveSessionNotifier {
  LiveSessionState _state;
  bool _disposed = false;

  FakeLiveSessionNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  LiveSessionState get state => _state;

  set testState(LiveSessionState s) {
    _state = s;
    super.state = s;
  }

  @override
  void startPolling(String clientId) {
    // no-op in tests
  }

  @override
  void stopPolling() {
    // no-op in tests
  }

  @override
  Future<void> refresh() async {
    // no-op in tests
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get isDisposed => _disposed;
}

Widget buildScreen(LiveSessionState state, {String? clientName}) {
  return ProviderScope(
    overrides: [
      liveSessionProvider.overrideWith(
        (ref) => FakeLiveSessionNotifier(state),
      ),
    ],
    child: MaterialApp(
      home: LiveSessionMonitorScreen(
        clientId: 'test-client',
        clientName: clientName ?? 'Test Client',
      ),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  final now = DateTime.now();

  WorkoutSession createSession() {
    return WorkoutSession(
      id: 'ws-1',
      clientId: 'test-client',
      startTime: now,
      status: WorkoutSessionStatus.inProgress,
      name: 'Morning Workout',
      createdAt: now,
      updatedAt: now,
    );
  }

  ClientExerciseLog createLog({
    String id = 'log-1',
    String exerciseName = 'Bench Press',
    bool? isCompleted,
  }) {
    return ClientExerciseLog(
      id: id,
      clientId: 'test-client',
      exerciseId: 'ex-1',
      workoutSessionId: 'ws-1',
      reps: 10,
      weight: 50.0,
      isCompleted: isCompleted,
      exerciseName: exerciseName,
      createdAt: now,
    );
  }

  group('LiveSessionMonitorScreen', () {
    testWidgets('shows loading indicator when isLoading and no session',
        (t) async {
      await t.pumpWidget(buildScreen(const LiveSessionState(
        isLoading: true,
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "No Active Workout" when session is null', (t) async {
      await t.pumpWidget(buildScreen(const LiveSessionState(
        isLoading: false,
      )));
      await t.pumpAndSettle();

      expect(find.text('No Active Workout'), findsOneWidget);
      expect(find.text('Check Again'), findsOneWidget);
    });

    testWidgets('shows session info card with active session', (t) async {
      final session = createSession();
      final logs = [
        createLog(id: 'log-1', exerciseName: 'Bench Press', isCompleted: true),
        createLog(id: 'log-2', exerciseName: 'Squat', isCompleted: false),
      ];

      await t.pumpWidget(buildScreen(LiveSessionState(
        session: session,
        exerciseLogs: logs,
        isLoading: false,
        isPolling: false, // avoids repeating animation from _LiveIndicator
        lastUpdated: now,
      )));
      await t.pumpAndSettle();

      // Session info
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsOneWidget);
      expect(find.text('2'), findsAtLeast(1)); // in stat items
      expect(find.text('1'), findsAtLeast(1)); // completed count

      // Exercise names
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // Section headers (one from _SectionHeader, also 'Completed' appears in _StatItem)
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsAtLeast(1));
    });

    testWidgets('shows error state with retry button', (t) async {
      await t.pumpWidget(buildScreen(const LiveSessionState(
        isLoading: false,
        error: 'Something went wrong',
      )));
      await t.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows last updated time', (t) async {
      final session = createSession();

      await t.pumpWidget(buildScreen(LiveSessionState(
        session: session,
        exerciseLogs: [],
        isLoading: false,
        isPolling: false,
        lastUpdated: now,
      )));
      await t.pumpAndSettle();

      expect(find.textContaining('Last updated'), findsOneWidget);
    });

    testWidgets('shows client name in AppBar', (t) async {
      await t.pumpWidget(buildScreen(
        const LiveSessionState(isLoading: false),
        clientName: 'John Doe',
      ));
      await t.pumpAndSettle();

      // The "No Active Workout" text is for the body, the title has "John Doe"
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('pull-to-refresh finds RefreshIndicator', (t) async {
      await t.pumpWidget(buildScreen(const LiveSessionState(
        isLoading: false,
      )));
      await t.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows LIVE indicator when polling', (t) async {
      final session = createSession();

      await t.pumpWidget(buildScreen(LiveSessionState(
        session: session,
        exerciseLogs: [],
        isLoading: false,
        isPolling: true,
        lastUpdated: now,
      )));
      await t.pump();

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('shows OFF indicator when not polling', (t) async {
      await t.pumpWidget(buildScreen(const LiveSessionState(
        isLoading: false,
      )));
      await t.pumpAndSettle();

      expect(find.text('OFF'), findsOneWidget);
    });
  });
}
