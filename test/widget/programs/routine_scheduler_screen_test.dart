import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/routine_scheduler_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake ClientProgramsNotifier – controllable setActiveProgram
// ---------------------------------------------------------------------------

class FakeClientProgramsNotifier extends ClientProgramsNotifier {
  ClientProgramsState _state;

  bool setActiveProgramCalled = false;
  String? capturedProgramId;

  FakeClientProgramsNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ClientProgramsState get state => _state;

  @override
  Future<void> setActiveProgram(String programId) async {
    setActiveProgramCalled = true;
    capturedProgramId = programId;
  }

  @override
  Future<void> fetchPrograms() async {}

  @override
  Future<void> fetchTemplates() async {}

  @override
  Future<void> clearActiveProgram() async {}
}

// ---------------------------------------------------------------------------
// Test app builder
// ---------------------------------------------------------------------------

final _now = DateTime.now();

final _defaultRoutine = WorkoutProgram(
  id: 'routine-1',
  name: 'Weekly Push Routine',
  description: 'Push workout 3x a week',
  createdAt: _now,
  updatedAt: _now,
);

Widget buildApp({
  required FakeClientProgramsNotifier notifier,
  WorkoutProgram? routine,
}) {
  routine ??= _defaultRoutine;
  return ProviderScope(
    overrides: [
      clientProgramsProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      home: RoutineSchedulerScreen(routine: routine),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('RoutineSchedulerScreen', () {
    testWidgets('renders with Schedule Routine title', (tester) async {
      final notifier = FakeClientProgramsNotifier(
        const ClientProgramsState(),
      );

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      expect(find.text('Schedule Routine'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Routine info banner
      expect(find.text('Weekly Push Routine'), findsOneWidget);
      expect(find.text('Push workout 3x a week'), findsOneWidget);

      // Bottom actions
      expect(find.text('Save Schedule'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows day-of-week toggles (Mon-Sun)', (tester) async {
      // Increase surface so all 7 tiles are rendered
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = FakeClientProgramsNotifier(
        const ClientProgramsState(),
      );

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // All day labels should be present
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final label in dayLabels) {
        expect(find.text(label), findsOneWidget);
      }

      // Each day has a Switch
      expect(find.byType(Switch), findsNWidgets(7));

      // Header shows "0 selected"
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('can toggle days on/off', (tester) async {
      final notifier = FakeClientProgramsNotifier(
        const ClientProgramsState(),
      );

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Initially 0 selected
      expect(find.text('0 selected'), findsOneWidget);

      // Tap the Mon label to enable it
      await tester.tap(find.text('Mon'));
      await tester.pump();

      // Should now show 1 selected
      expect(find.text('1 selected'), findsOneWidget);

      // Tap Mon again to disable
      await tester.tap(find.text('Mon'));
      await tester.pump();

      // Back to 0
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('save schedule persists changes', (tester) async {
      final notifier = FakeClientProgramsNotifier(
        const ClientProgramsState(),
      );

      // Use navigatorKey + push so pop navigates back gracefully
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientProgramsProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(),
          ),
        ),
      );

      // Push the scheduler screen
      navKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => RoutineSchedulerScreen(routine: _defaultRoutine),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Toggle a day on
      await tester.tap(find.text('Mon'));
      await tester.pump();

      // Tap Save Schedule
      await tester.tap(find.text('Save Schedule'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the notifier was called
      expect(notifier.setActiveProgramCalled, isTrue);
      expect(notifier.capturedProgramId, 'routine-1');

      // Screen should be popped off the stack
      expect(find.byType(RoutineSchedulerScreen), findsNothing);
    });
  });
}
