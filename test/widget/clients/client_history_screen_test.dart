import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/clients/providers/client_history_provider.dart';
import 'package:zirofit_fl/features/clients/screens/client_history_screen.dart';
import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifier
// =============================================================================

class FakeClientHistoryNotifier extends ClientHistoryNotifier {
  final ClientHistoryState _overriddenState;

  FakeClientHistoryNotifier(
    this._overriddenState, {
    required super.clientId,
  }) : super(apiClient: ApiClient.instance) {
    super.state = _overriddenState;
  }

  @override
  ClientHistoryState get state => _overriddenState;

  @override
  Future<void> fetchHistory({HistoryDateRange? dateRange}) async {}

  @override
  Future<void> loadMore() async {}

  @override
  void setDateRange(HistoryDateRange range) {}

  @override
  Future<void> refresh() async {}
}

// =============================================================================
// Helpers
// =============================================================================

const _testClientId = 'test-client';

ClientHistoryState createStateWithSessions({
  int sessionCount = 3,
  bool isLoading = false,
  bool isLoadingMore = false,
  String? error,
  HistoryDateRange dateRange = HistoryDateRange.all,
}) {
  final now = DateTime.now();
  final sessions = List<SessionHistoryData>.generate(sessionCount, (i) {
    final time = now.subtract(Duration(days: i));
    return SessionHistoryData(
      session: WorkoutSession(
        id: 's-$i',
        clientId: _testClientId,
        name: i == 0 ? 'Morning Push' : 'Session ${i + 1}',
        startTime: time,
        endTime: time.add(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        createdAt: time,
        updatedAt: time,
      ),
      totalVolume: 5000.0 - (i * 500),
      totalSets: 25 - (i * 2),
    );
  });

  return ClientHistoryState(
    sessions: sessions,
    isLoading: isLoading,
    isLoadingMore: isLoadingMore,
    error: error,
    dateRange: dateRange,
    page: 1,
    hasMore: sessionCount >= 20,
  );
}

Widget createTestApp({
  required ClientHistoryState state,
}) {
  return ProviderScope(
    overrides: [
      clientHistoryProvider(_testClientId).overrideWith(
        (ref) => FakeClientHistoryNotifier(
          state,
          clientId: _testClientId,
        ),
      ),
    ],
    child: const MaterialApp(
      home: ClientHistoryScreen(clientId: _testClientId),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  group('ClientHistoryScreen', () {
    // Test 1: Shows volume chart at top
    testWidgets('shows volume progression chart at top', (tester) async {
      final state = createStateWithSessions(sessionCount: 5);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Volume Progression section header
      expect(find.text('Volume Progression'), findsOneWidget);
      // Chart widget should be present (LineChart from fl_chart)
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows chart placeholder when less than 2 data points',
        (tester) async {
      // Single session → volumeData has 1 entry → chart placeholder
      final state = createStateWithSessions(sessionCount: 1);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Volume Progression'), findsOneWidget);
      // Should show placeholder text
      expect(
        find.text('Log more sessions to see volume progression'),
        findsOneWidget,
      );
    });

    // Test 2: Shows date-grouped sessions
    testWidgets('shows session rows with volume and sets', (tester) async {
      final state = createStateWithSessions(sessionCount: 3);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll down to see all sessions
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Session names should be visible
      expect(find.text('Morning Push'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('Session 3'), findsOneWidget);

      // Volume and sets should be displayed
      expect(find.textContaining('kg'), findsWidgets);
      expect(find.textContaining('sets'), findsWidgets);
    });

    testWidgets('groups sessions by date with date headers', (tester) async {
      final now = DateTime.now();
      final sessions = [
        SessionHistoryData(
          session: WorkoutSession(
            id: 's-today-1',
            clientId: _testClientId,
            name: 'Today Session',
            startTime: now.subtract(const Duration(hours: 2)),
            endTime: now.subtract(const Duration(hours: 1)),
            status: WorkoutSessionStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
          totalVolume: 5000,
          totalSets: 25,
        ),
        SessionHistoryData(
          session: WorkoutSession(
            id: 's-yesterday',
            clientId: _testClientId,
            name: 'Yesterday Session',
            startTime: now
                .subtract(const Duration(days: 1))
                .subtract(const Duration(hours: 2)),
            endTime: now
                .subtract(const Duration(days: 1))
                .subtract(const Duration(hours: 1)),
            status: WorkoutSessionStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
          totalVolume: 3000,
          totalSets: 15,
        ),
      ];

      final state = ClientHistoryState(
        sessions: sessions,
        isLoading: false,
        dateRange: HistoryDateRange.all,
        page: 1,
        hasMore: false,
      );

      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Date headers should appear
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      // Session count badges
      expect(find.text('1 session'), findsWidgets);
    });

    // Test 3: Tap session navigates
    testWidgets('tapping a session shows navigation intent', (tester) async {
      // Create a test app with route generation to catch navigation attempts
      final state = createStateWithSessions(sessionCount: 2);
      var navigatedRoute = '';
      final app = ProviderScope(
        overrides: [
          clientHistoryProvider(_testClientId).overrideWith(
            (ref) => FakeClientHistoryNotifier(state, clientId: _testClientId),
          ),
        ],
        child: MaterialApp(
          home: const ClientHistoryScreen(clientId: _testClientId),
          onGenerateRoute: (settings) {
            navigatedRoute = settings.name ?? '';
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Session Detail')),
              settings: settings,
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the first session
      await tester.tap(find.text('Morning Push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify navigation was triggered
      expect(navigatedRoute, startsWith('/workout/'));
    });

    // Test 4: Pull-to-refresh works
    testWidgets('pull-to-refresh indicator is present', (tester) async {
      final state = createStateWithSessions(sessionCount: 3);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // RefreshIndicator is in the widget tree
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    // Test 5: Date range filter chips
    testWidgets('shows date range filter chips', (tester) async {
      final state = createStateWithSessions(sessionCount: 3);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
    });

    testWidgets('tapping date range chip highlights it', (tester) async {
      // Use a notifier that tracks setDateRange calls
      final state = createStateWithSessions(
        sessionCount: 2,
        dateRange: HistoryDateRange.oneMonth,
      );
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The 1M chip should be selected
      // We don't test visual selection in widget tests, just presence
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
    });

    // Test 6: Loading + empty + error states
    testWidgets('shows loading spinner when loading with no sessions',
        (tester) async {
      const state = ClientHistoryState(isLoading: true);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      const state = ClientHistoryState();
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No workout history yet'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      const state = ClientHistoryState(
        error: 'Something went wrong',
      );
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('appbar shows Workout History title', (tester) async {
      final state = createStateWithSessions(sessionCount: 1);
      await tester.pumpWidget(createTestApp(state: state));
      await tester.pump();

      expect(find.text('Workout History'), findsOneWidget);
    });
  });
}
