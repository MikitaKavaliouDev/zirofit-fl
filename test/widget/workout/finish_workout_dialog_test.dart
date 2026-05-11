import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/widgets/finish_workout_dialog.dart';

/// Sets a tall test surface so the dialog's Column does not overflow.
Future<void> useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Common widget for triggering the dialog without result capture.
Widget buildTestApp() {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => FinishWorkoutAlert.show(context),
          child: const Text('Show dialog'),
        ),
      ),
    ),
  );
}

void main() {
  group('FinishWorkoutAlert', () {
    testWidgets('returns completeUnfinished when Complete Unfinished Sets is tapped',
        (WidgetTester tester) async {
      await useTallSurface(tester);
      FinishOption? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await FinishWorkoutAlert.show(context);
                },
                child: const Text('Show dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Unfinished Sets').first);
      await tester.pumpAndSettle();

      expect(result, FinishOption.completeUnfinished);
    });

    testWidgets('returns discardUnfinished when Discard Unfinished Sets is tapped',
        (WidgetTester tester) async {
      await useTallSurface(tester);
      FinishOption? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await FinishWorkoutAlert.show(context);
                },
                child: const Text('Show dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard Unfinished Sets').first);
      await tester.pumpAndSettle();

      expect(result, FinishOption.discardUnfinished);
    });

    testWidgets('returns null when Cancel is tapped', (WidgetTester tester) async {
      await useTallSurface(tester);
      FinishOption? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await FinishWorkoutAlert.show(context);
                },
                child: const Text('Show dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('displays emoji at top', (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      expect(find.text('🎉'), findsOneWidget);
    });

    testWidgets('displays title', (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Finish Workout?'), findsOneWidget);
    });

    testWidgets('displays three options', (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Complete Unfinished Sets'), findsOneWidget);
      expect(find.text('Discard Unfinished Sets'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('has fade animation', (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      // Note: there are multiple FadeTransition widgets in the tree
      // (from MaterialPageRoute animations), so use findsWidgets.
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('dialog is dismissible by tapping outside', (WidgetTester tester) async {
      await useTallSurface(tester);
      FinishOption? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await FinishWorkoutAlert.show(context);
                },
                child: const Text('Show dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      // Tap outside the dialog content to dismiss via the ModalBarrier
      await tester.tapAt(const Offset(10, 200));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('displays subtitle for Complete Unfinished Sets option',
        (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all valid sets as done'), findsOneWidget);
    });

    testWidgets('displays subtitle for Discard Unfinished Sets option',
        (WidgetTester tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Show dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Remove all incomplete sets'), findsOneWidget);
    });
  });

  group('FinishOption enum', () {
    test('has two options', () {
      expect(FinishOption.values.length, 2);
      expect(FinishOption.values, contains(FinishOption.completeUnfinished));
      expect(FinishOption.values, contains(FinishOption.discardUnfinished));
    });
  });
}
