import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zirofit_fl/features/progress/widgets/exercise_progress_widget.dart';

/// Creates a list of test data points simulating exercise progress.
List<ExerciseDataPoint> createTestDataPoints() {
  return [
    ExerciseDataPoint(
      date: DateTime(2025, 1, 1),
      weight: 60.0,
      volume: 1200,
    ),
    ExerciseDataPoint(
      date: DateTime(2025, 1, 8),
      weight: 62.5,
      volume: 1350,
    ),
    ExerciseDataPoint(
      date: DateTime(2025, 1, 15),
      weight: 65.0,
      volume: 1500,
    ),
    ExerciseDataPoint(
      date: DateTime(2025, 1, 22),
      weight: 67.5,
      volume: 1600,
    ),
    ExerciseDataPoint(
      date: DateTime(2025, 1, 29),
      weight: 70.0,
      volume: 1800,
    ),
  ];
}

void main() {
  group('ExerciseProgressWidget', () {
    // -------------------------------------------------------------------------
    // Test 1: Shows exercise selector
    // -------------------------------------------------------------------------
    testWidgets('shows exercise selector dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press', 'Squat', 'Deadlift'],
            ),
          ),
        ),
      );

      // The hint text "Select exercise" should be visible
      expect(find.text('Select exercise'), findsOneWidget);

      // Tap the dropdown field to open the menu
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // All exercise names should appear in the dropdown
      expect(find.text('Bench Press'), findsWidgets);
      expect(find.text('Squat'), findsWidgets);
      expect(find.text('Deadlift'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test 2: Line chart renders with data
    // -------------------------------------------------------------------------
    testWidgets('renders line chart when exercise is selected with data',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press'],
              dataPoints: createTestDataPoints(),
              exerciseId: 'Bench Press',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // LineChart should be rendered
      expect(find.byType(LineChart), findsOneWidget);

      // Toggle chips should be visible
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);

      // Date labels should appear on bottom axis
      expect(find.text('1/1'), findsWidgets);
      expect(find.text('1/29'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test 3: Toggle weight/volume view works
    // -------------------------------------------------------------------------
    testWidgets('toggle switches between weight and volume view',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press'],
              dataPoints: createTestDataPoints(),
              exerciseId: 'Bench Press',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially showing Weight view — LineChart exists
      expect(find.byType(LineChart), findsOneWidget);

      // Tap "Volume" toggle
      await tester.tap(find.text('Volume'));
      await tester.pumpAndSettle();

      // LineChart should still be present (just different data rendered)
      expect(find.byType(LineChart), findsOneWidget);

      // Tap "Weight" toggle to switch back
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();

      // LineChart still present
      expect(find.byType(LineChart), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: Empty state when no exercise selected
    // -------------------------------------------------------------------------
    testWidgets('shows prompt when no exercise is selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press', 'Squat'],
              // No exerciseId set — nothing pre-selected
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the prompt text
      expect(
        find.text('Select an exercise above to see progress'),
        findsOneWidget,
      );

      // No chart should be rendered
      expect(find.byType(LineChart), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 5: Loading state
    // -------------------------------------------------------------------------
    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press'],
              isLoading: true,
            ),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() because CircularProgressIndicator
      // animates indefinitely and would never settle.
      await tester.pump();

      // CircularProgressIndicator should be displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // The dropdown should NOT be visible while loading
      expect(find.text('Select exercise'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 6: Empty exercise names list
    // -------------------------------------------------------------------------
    testWidgets('shows no data message when exercise names list is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No exercise data available'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7: Shows no-data-for-exercise state
    // -------------------------------------------------------------------------
    testWidgets('shows empty data message when selected exercise has no data',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press'],
              dataPoints: [],
              exerciseId: 'Bench Press',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No progress data for Bench Press yet'),
        findsOneWidget,
      );
    });

    // -------------------------------------------------------------------------
    // Test 8: Handles less than 2 data points
    // -------------------------------------------------------------------------
    testWidgets('shows message when fewer than 2 data points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseProgressWidget(
              exerciseNames: ['Bench Press'],
              dataPoints: [
                ExerciseDataPoint(
                  date: DateTime(2025, 1, 1),
                  weight: 60.0,
                  volume: 1200,
                ),
              ],
              exerciseId: 'Bench Press',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Need at least 2 data points to show a chart.'),
        findsOneWidget,
      );
    });
  });
}
