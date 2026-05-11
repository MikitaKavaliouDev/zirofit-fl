import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_header_widget.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}

// ---------------------------------------------------------------------------
// Test notifier — overrides initial state without needing the real API chain
// ---------------------------------------------------------------------------

class _TestActiveWorkoutNotifier extends ActiveWorkoutNotifier {
  _TestActiveWorkoutNotifier({
    required super.remoteSource,
    required super.ref,
    ActiveWorkoutState initialState = const ActiveWorkoutState(),
  }) : super() {
    state = initialState;
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Wraps [child] in a [ProviderScope] that overrides
/// [activeWorkoutProvider] so it does not depend on a real ApiClient.
ProviderScope createTestWidget({
  required Widget child,
  ActiveWorkoutState workoutState = const ActiveWorkoutState(),
}) {
  final mockRemoteSource = _MockWorkoutRemoteSource();
  return ProviderScope(
    overrides: [
      activeWorkoutProvider.overrideWith((ref) {
        return _TestActiveWorkoutNotifier(
          remoteSource: mockRemoteSource,
          ref: ref,
          initialState: workoutState,
        );
      }),
    ],
    child: MaterialApp(home: child),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WorkoutHeaderWidget', () {
    testWidgets('renders personal session header when no client', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: WorkoutHeaderWidget(
          clientName: null,
          sessionName: '10 Pack (1/10)',
          onMinimize: () {},
          onTapTimer: () {},
        ),
      ));

      expect(find.text('PERSONAL SESSION'), findsOneWidget);
      expect(find.text('10 Pack (1/10)'), findsOneWidget);

      // Cleanup: replace widget tree to trigger dispose and cancel Timer.periodic
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders trainer session header with client name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: WorkoutHeaderWidget(
          clientName: 'John Doe',
          sessionName: '10 Pack (1/10)',
          onMinimize: () {},
          onTapTimer: () {},
        ),
      ));

      expect(find.text('LIVE SESSION WITH JOHN DOE'), findsOneWidget);
      expect(find.text('10 Pack (1/10)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders the timer widget', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: WorkoutHeaderWidget(
          clientName: null,
          sessionName: 'Test Session',
          onMinimize: () {},
          onTapTimer: () {},
        ),
      ));

      // Timer displays the formatted time from workoutTimerProvider (default "00:00")
      expect(find.text('00:00'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders rest progress', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: WorkoutHeaderWidget(
          clientName: null,
          sessionName: 'Test Session',
          onMinimize: () {},
          onTapTimer: () {},
        ),
        workoutState: const ActiveWorkoutState(
          isRestRunning: true,
          restSeconds: 90,
        ),
      ));

      // Rest section renders when isRestRunning is true and restSeconds > 0
      expect(find.text('REST'), findsOneWidget);
      expect(find.text('REST 1:30'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
