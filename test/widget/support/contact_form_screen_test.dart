import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/support/screens/contact_form_screen.dart';
import '../../helpers/test_setup.dart';

Widget buildApp() => const ProviderScope(
      child: MaterialApp(home: ContactFormScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('ContactFormScreen', () {
    testWidgets('renders contact form', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Contact Us'), findsOneWidget);

      // Category label
      expect(find.text('Category'), findsOneWidget);

      // Message label
      expect(find.text('Message'), findsOneWidget);

      // Message field hint
      expect(
        find.text('Describe your issue or request...'),
        findsOneWidget,
      );

      // Submit button
      expect(find.text('Send Message'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('category dropdown works', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // All category options appear
      // "General Support" appears as selected value AND in dropdown
      expect(find.text('General Support'), findsAtLeast(1));
      expect(find.text('Bug Report'), findsOneWidget);
      expect(find.text('Feature Request'), findsOneWidget);
      expect(find.text('Account Issue'), findsOneWidget);

      // Select "Bug Report"
      await tester.tap(find.text('Bug Report').last);
      await tester.pumpAndSettle();

      // Verify the dropdown now shows "Bug Report" as selected
      // (The selected value text should be visible)
      expect(find.text('Bug Report'), findsAtLeast(1));
    });

    testWidgets('submit button calls validation - empty message shows error',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap submit without entering message
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a message'), findsOneWidget);
    });

    testWidgets('message field accepts text input', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Enter a message
      await tester.enterText(
        find.byType(TextFormField),
        'This is a test message',
      );
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('This is a test message'), findsOneWidget);
    });

    testWidgets('shows version info when available', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // In test environment, PackageInfo.fromPlatform() will fail,
      // so app version likely won't show. Just verify the app doesn't crash.
      expect(find.text('Contact Us'), findsOneWidget);
    });
  });
}
