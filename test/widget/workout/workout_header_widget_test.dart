import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_header_widget.dart';

void main() {
  group('WorkoutHeaderWidget', () {
    testWidgets('renders personal session header when no client', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutHeaderWidget(
              clientName: null,
              sessionName: '10 Pack (1/10)',
              onMinimize: () {},
              onTapTimer: () {},
            ),
          ),
        ),
      );

      expect(find.text('PERSONAL SESSION'), findsOneWidget);
      expect(find.text('10 Pack (1/10)'), findsOneWidget);

      // Cleanup: replace widget tree to trigger dispose and cancel Timer.periodic
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders trainer session header with client name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutHeaderWidget(
              clientName: 'John Doe',
              sessionName: '10 Pack (1/10)',
              onMinimize: () {},
              onTapTimer: () {},
            ),
          ),
        ),
      );

      expect(find.text('LIVE SESSION WITH JOHN DOE'), findsOneWidget);
      expect(find.text('10 Pack (1/10)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders the timer widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutHeaderWidget(
              clientName: null,
              sessionName: 'Test Session',
              onMinimize: () {},
              onTapTimer: () {},
            ),
          ),
        ),
      );

      // Timer displays the formatted time from workoutTimerProvider (default "00:00")
      expect(find.text('00:00'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders rest progress', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutHeaderWidget(
              clientName: null,
              sessionName: 'Test Session',
              onMinimize: () {},
              onTapTimer: () {},
            ),
          ),
        ),
      );

      // Rest section renders when restTimerSettings.defaultSeconds > 0 (default is 90)
      expect(find.text('REST'), findsOneWidget);
      expect(find.text('REST 1:30'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
