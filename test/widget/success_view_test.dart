import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/shared/widgets/success_view.dart';

void main() {
  group('SuccessView', () {
    testWidgets('shows success icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Success!',
            onDismiss: () {},
          ),
        ),
      );
      // Let animation play out
      await tester.pump(const Duration(seconds: 2));

      // Title is displayed
      expect(find.text('Success!'), findsOneWidget);

      // Checkmark icon is shown
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Dismiss button is present
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('shows optional message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Saved!',
            message: 'Your changes have been saved.',
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Saved!'), findsOneWidget);
      expect(find.text('Your changes have been saved.'), findsOneWidget);
    });

    testWidgets('optional action button works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Done!',
            actionLabel: 'Continue',
            onAction: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('hides action button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Done!',
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('calls onDismiss when dismiss button is tapped',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Test',
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('calls onAction and onDismiss when action button is tapped',
        (tester) async {
      bool actionCalled = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessView(
            title: 'Test',
            actionLabel: 'Go',
            onAction: () => actionCalled = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(actionCalled, isTrue);
      expect(dismissed, isTrue);
    });
  });
}
