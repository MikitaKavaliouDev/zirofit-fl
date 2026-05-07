import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import 'package:zirofit_fl/features/workout/screens/workout_history_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends WorkoutHistoryNotifier {
  WorkoutHistoryState _s;
  bool refreshCalled = false;
  Fake(this._s)
    : super(remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance)) {
    super.state = _s;
  }
  @override
  WorkoutHistoryState get state => _s;
  void emit(WorkoutHistoryState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchHistory() async {}
  @override
  Future<void> fetchMore() async {}
  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  void clearError() {}

  @override
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  @override
  void setDateRange(DateRange? range) {
    emit(state.copyWith(dateRange: range));
  }
}

Widget b(WorkoutHistoryState s) => ProviderScope(
  overrides: [workoutHistoryProvider.overrideWith((ref) => Fake(s))],
  child: const MaterialApp(home: WorkoutHistoryScreen()),
);

class FakeWithFetchMoreTracking extends Fake {
  bool fetchMoreCalled = false;
  FakeWithFetchMoreTracking(WorkoutHistoryState s) : super(s);
  @override
  Future<void> fetchMore() async {
    fetchMoreCalled = true;
  }
}

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  testWidgets('loading', (t) async {
    await t.pumpWidget(b(const WorkoutHistoryState(isLoading: true)));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  testWidgets('empty', (t) async {
    await t.pumpWidget(b(const WorkoutHistoryState(isLoading: false)));
    await t.pumpAndSettle();
    expect(find.text('No workouts yet'), findsOneWidget);
  });
  testWidgets('data', (t) async {
    final ss = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(sessions: ss, isLoading: false, hasMore: false)),
    );
    await t.pumpAndSettle();
    expect(find.text('Upper'), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(
      b(const WorkoutHistoryState(isLoading: false, error: 'err')),
    );
    await t.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });
  testWidgets('pull-to-refresh triggers refresh', (t) async {
    // Enough sessions to make the list scrollable so RefreshIndicator activates
    final now = DateTime.now();
    final sessions = List.generate(
      10,
      (i) => WorkoutSession(
        id: '$i',
        clientId: 'c1',
        name: 'Workout $i',
        startTime: now.subtract(Duration(hours: 2 + i)),
        endTime: now.subtract(Duration(hours: 1 + i)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();
    // Fling down to trigger the RefreshIndicator (drag does not work)
    await t.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(fake.refreshCalled, isTrue);
  });

  testWidgets('pagination loading indicator', (t) async {
    final now = DateTime.now();
    // Spread sessions across multiple dates so date grouping creates enough entries
    // to keep the pagination spinner off-screen initially.
    final sessions = List.generate(
      15,
      (i) => WorkoutSession(
        id: '$i',
        clientId: 'c1',
        name: 'Workout $i',
        startTime: now.subtract(Duration(days: i)),
        endTime: now.subtract(Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await t.pumpWidget(
      b(WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        hasMore: true,
      )),
    );
    await t.pumpAndSettle();

    // Initially no CircularProgressIndicator (loading spinner gone, pagination not built)
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Scroll to bottom to build the pagination spinner
    // Use vertical Scrollable finder to avoid collision with filter chips' horizontal Scrollable
    await t.scrollUntilVisible(
      find.byType(CircularProgressIndicator),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );

    // Pagination spinner should now be visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('session card tap opens bottom sheet', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        hasMore: false,
      )),
    );
    await t.pumpAndSettle();

    // Tap on the session card
    await t.tap(find.text('Upper'));
    await t.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('bottom sheet shows session details', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        notes: 'Great session!',
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        hasMore: false,
      )),
    );
    await t.pumpAndSettle();

    // Tap card
    await t.tap(find.text('Upper'));
    await t.pumpAndSettle();

    // Bottom sheet is present
    expect(find.byType(BottomSheet), findsOneWidget);

    // Session name appears in both card and bottom sheet title
    expect(find.text('Upper'), findsNWidgets(2));

    // Duration: 1h 0m (appears in both card and bottom sheet)
    expect(find.text('1h 0m'), findsAtLeastNWidgets(1));

    // Status chip in bottom sheet: 'Completed'
    expect(find.text('Completed'), findsOneWidget);

    // Notes
    expect(find.text('Great session!'), findsOneWidget);

    // Close button (only in bottom sheet)
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('scroll to bottom triggers fetchMore', (t) async {
    final now = DateTime.now();
    final sessions = List.generate(
      15,
      (i) => WorkoutSession(
        id: '$i',
        clientId: 'c1',
        name: 'Workout $i',
        startTime: now.subtract(Duration(days: i)),
        endTime: now.subtract(Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final fake = FakeWithFetchMoreTracking(
      WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        hasMore: true,
      ),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Scroll to bottom where pagination spinner is
    await t.scrollUntilVisible(
      find.byType(CircularProgressIndicator),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await t.pump();

    // Verify fetchMore was called by _onScroll
    expect(fake.fetchMoreCalled, isTrue);
  });

  testWidgets('LoadingMore shows spinner at bottom', (t) async {
    final now = DateTime.now();
    final sessions = List.generate(
      3,
      (i) => WorkoutSession(
        id: '$i',
        clientId: 'c1',
        name: 'Workout $i',
        startTime: now.subtract(Duration(hours: 2 + i)),
        endTime: now.subtract(Duration(hours: 1 + i)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await t.pumpWidget(
      b(WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        isLoadingMore: true,
        hasMore: true,
      )),
    );
    await t.pump();

    // Pagination spinner should be visible at the bottom
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Search & Filter Tests
  // ---------------------------------------------------------------------------

  testWidgets('search bar is visible when sessions exist', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false)),
    );
    await t.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search by exercise or notes...'), findsOneWidget);
  });

  testWidgets('filter chips are visible', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false)),
    );
    await t.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('3M'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('typing in search filters sessions dynamically', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper Body',
        notes: 'Great push workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
      WorkoutSession(
        id: '2',
        clientId: 'c1',
        name: 'Leg Day',
        notes: 'Squats day',
        startTime: now.subtract(const Duration(hours: 5)),
        endTime: now.subtract(const Duration(hours: 4)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Both sessions visible initially
    expect(find.text('Upper Body'), findsOneWidget);
    expect(find.text('Leg Day'), findsOneWidget);

    // Type in search bar to filter
    await t.enterText(find.byType(TextField), 'Leg');
    // Wait for debounce (300ms)
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();

    // Only "Leg Day" should remain
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('Upper Body'), findsNothing);
  });

  testWidgets('search by notes filters sessions', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper Body',
        notes: 'Great push workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
      WorkoutSession(
        id: '2',
        clientId: 'c1',
        name: 'Leg Day',
        notes: 'Squats and deadlifts',
        startTime: now.subtract(const Duration(hours: 5)),
        endTime: now.subtract(const Duration(hours: 4)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Search by notes content
    await t.enterText(find.byType(TextField), 'deadlifts');
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();

    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('Upper Body'), findsNothing);
  });

  testWidgets('date range chip selects and filters', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Recent',
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
      WorkoutSession(
        id: '2',
        clientId: 'c1',
        name: 'Old',
        startTime: now.subtract(const Duration(days: 60)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Both visible initially
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Old'), findsOneWidget);

    // Tap "7D" chip
    await t.tap(find.text('7D'));
    await t.pumpAndSettle();

    // Only "Recent" should remain (within 7 days)
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Old'), findsNothing);
  });

  testWidgets('empty search results shows no matches state', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper Body',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Search for something that won't match
    await t.enterText(find.byType(TextField), 'zzzzzzz');
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();

    // Should show "No matches found"
    expect(find.text('No matches found'), findsOneWidget);
    // Original session should not be visible
    expect(find.text('Upper Body'), findsNothing);
  });

  testWidgets('empty search shows clear filters button', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper Body',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Get into empty results state
    await t.enterText(find.byType(TextField), 'zzzzzzz');
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();

    // Clear filters button should be visible
    expect(find.text('Clear filters'), findsOneWidget);

    // Tap clear filters
    await t.tap(find.text('Clear filters'));
    await t.pumpAndSettle();

    // All sessions should be restored
    expect(find.text('Upper Body'), findsOneWidget);
  });

  testWidgets('search bar clear icon resets query', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper Body',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final fake = Fake(
      WorkoutHistoryState(sessions: sessions, isLoading: false, hasMore: false),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [workoutHistoryProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Type to filter
    await t.enterText(find.byType(TextField), 'Upper');
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();
    expect(find.text('Upper Body'), findsOneWidget);

    // Clear button should be visible (suffix icon)
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap the clear button
    await t.tap(find.byIcon(Icons.clear));
    await t.pumpAndSettle();

    // Session should still be visible after clear
    expect(find.text('Upper Body'), findsOneWidget);
  });

  testWidgets('error with existing data', (t) async {
    final now = DateTime.now();
    final sessions = [
      WorkoutSession(
        id: '1',
        clientId: 'c1',
        name: 'Upper',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        isTrainerLed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(WorkoutHistoryState(
        sessions: sessions,
        isLoading: false,
        error: 'Something went wrong',
        hasMore: false,
      )),
    );
    await t.pumpAndSettle();

    // Sessions should still be shown
    expect(find.text('Upper'), findsOneWidget);
    // Full error screen with Retry should NOT appear (only when sessions.isEmpty)
    expect(find.text('Retry'), findsNothing);
  });
}
