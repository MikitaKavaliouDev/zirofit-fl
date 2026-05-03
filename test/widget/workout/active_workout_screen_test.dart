import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/screens/active_workout_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends ActiveWorkoutNotifier {
  final ActiveWorkoutState _s;
  Fake(this._s) : super(remoteSource: WorkoutRemoteSource(apiClient: ApiClient.instance)) { super.state = _s; }
  @override ActiveWorkoutState get state => _s;
  @override Future<void> startWorkout({String? templateId}) async {}
  @override Future<void> loadActiveSession() async {}
  @override Future<void> logExercise({required String exerciseId, int? reps, double? weight}) async {}
  @override Future<void> completeSet(String logId) async {}
  @override Future<WorkoutSession?> finishWorkout() async => null;
  @override Future<void> cancelWorkout() async {}
  @override Future<void> startRest() async {}
  @override Future<void> endRest() async {}
  @override void clearError() {}
  @override void reset() {}
}

Widget b(ActiveWorkoutState s) => ProviderScope(overrides: [activeWorkoutProvider.overrideWith((ref) => Fake(s))], child: const MaterialApp(home: ActiveWorkoutScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();
  testWidgets('loading', (t) async { await t.pumpWidget(b(const ActiveWorkoutState(isLoading: true))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('idle', (t) async { await t.pumpWidget(b(const ActiveWorkoutState())); await t.pump(const Duration(milliseconds: 100)); expect(find.text('No active workout'), findsOneWidget); });
  testWidgets('active', (t) async {
    final sess = WorkoutSession(id: '1', clientId: 'c1', name: 'Morning Pump', startTime: now, status: WorkoutSessionStatus.inProgress, isTrainerLed: false, createdAt: now, updatedAt: now);
    await t.pumpWidget(b(ActiveWorkoutState(session: sess, isLoading: false)));
    await t.pump(); await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Morning Pump'), findsOneWidget);
    expect(find.text('Add Set'), findsOneWidget);
    expect(find.text('Finish Workout'), findsOneWidget);
  });
  testWidgets('rest timer', (t) async {
    final sess = WorkoutSession(id: '1', clientId: 'c1', name: 'Test', startTime: now, status: WorkoutSessionStatus.inProgress, isTrainerLed: false, createdAt: now, updatedAt: now);
    await t.pumpWidget(b(ActiveWorkoutState(session: sess, restSeconds: 75, isRestRunning: true, isLoading: false)));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('01:15'), findsOneWidget);
  });
  testWidgets('error', (t) async { await t.pumpWidget(b(const ActiveWorkoutState(isLoading: false, error: 'err'))); await t.pump(const Duration(milliseconds: 300)); expect(find.text('Retry'), findsOneWidget); });
}
