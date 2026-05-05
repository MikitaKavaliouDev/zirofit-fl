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
}
