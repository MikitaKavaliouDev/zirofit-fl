import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/services/workout_toast_service.dart';

void main() {
  group('WorkoutToastService', () {
    test('static getters exist for testing', () {
      expect(WorkoutToastService.currentRecordToast, isNull);
      expect(WorkoutToastService.currentRestToast, isNull);
    });

    testWidgets('showNewRecordToast creates overlay entry and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      WorkoutToastService.showNewRecordToast(context, 'Bench Press');
      await tester.pump();

      expect(WorkoutToastService.currentRecordToast, isNotNull);

      // Advance past the 5s auto-dismiss timer so no pending timers remain
      await tester.pump(const Duration(seconds: 6));

      expect(WorkoutToastService.currentRecordToast, isNull);
    });

    testWidgets('showRestFinishedToast creates overlay entry and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      WorkoutToastService.showRestFinishedToast(context);
      await tester.pump();

      expect(WorkoutToastService.currentRestToast, isNotNull);

      // Advance past the 3s auto-dismiss timer so no pending timers remain
      await tester.pump(const Duration(seconds: 4));

      expect(WorkoutToastService.currentRestToast, isNull);
    });

    testWidgets('overlay toast shows text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      WorkoutToastService.showNewRecordToast(context, 'Squat');
      await tester.pump();

      expect(find.text('New Record! Squat'), findsOneWidget);

      // Advance past auto-dismiss so no pending timers
      await tester.pump(const Duration(seconds: 6));

      expect(WorkoutToastService.currentRecordToast, isNull);
    });

    testWidgets('rest toast shows text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      WorkoutToastService.showRestFinishedToast(context);
      await tester.pump();

      expect(find.text('Rest Complete!'), findsOneWidget);

      // Advance past auto-dismiss so no pending timers
      await tester.pump(const Duration(seconds: 4));

      expect(WorkoutToastService.currentRestToast, isNull);
    });
  });
}
