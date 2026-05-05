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
    final sessions = List.generate(
      15,
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
        hasMore: true,
      )),
    );
    await t.pumpAndSettle();

    // Initially no CircularProgressIndicator (loading spinner gone, pagination not built)
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Scroll to bottom to build the pagination spinner
    await t.scrollUntilVisible(
      find.byType(CircularProgressIndicator),
      200,
      scrollable: find.byType(Scrollable),
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
        startTime: now.subtract(Duration(hours: 2 + i)),
        endTime: now.subtract(Duration(hours: 1 + i)),
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
      scrollable: find.byType(Scrollable),
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
