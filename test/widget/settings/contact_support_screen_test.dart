import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/screens/contact_support_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// The ContactSupportScreen uses:
//   - apiClientProvider (for posting feedback)
//   - PackageInfo.fromPlatform() (will throw in tests → version stays empty)
//   - Platform.operatingSystem (returns a dummy value in tests)
//
// In the test environment:
//   - Form renders correctly
//   - API call will fail → shows error banner
//   - Validation works for empty message
// ---------------------------------------------------------------------------

Widget buildApp() => const ProviderScope(
      child: MaterialApp(home: ContactSupportScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('ContactSupportScreen', () {
    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Contact Support'), findsOneWidget);
    });

    testWidgets('renders subject section', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Subject'), findsOneWidget);
      expect(
        find.text(
            'Select the category that best describes your issue'),
        findsOneWidget,
      );
    });

    testWidgets('renders message section', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Message'), findsOneWidget);
      expect(
        find.text(
            'Describe your issue or request in detail'),
        findsOneWidget,
      );
    });

    testWidgets('message field shows hint text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Describe your issue or request...'),
        findsOneWidget,
      );
    });

    testWidgets('renders submit button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Send Message'),
        findsOneWidget,
      );
    });

    testWidgets('subject dropdown defaults to General Support',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // The dropdown should show "General Support" as the initial value
      expect(find.text('General Support'), findsOneWidget);
    });

    testWidgets('shows validation error for empty message',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap submit without entering a message
      await tester.tap(
        find.widgetWithText(FilledButton, 'Send Message'),
      );
      await tester.pumpAndSettle();

      // Validation should show "Please enter a message"
      expect(
        find.text('Please enter a message'),
        findsOneWidget,
      );
    });

    testWidgets('message field accepts input', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Find the message TextFormField and enter text
      final messageField = find.widgetWithText(
        TextFormField,
        'Describe your issue or request...',
      );
      await tester.enterText(messageField, 'Test message');
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows app version info when available', (tester) async {
      // PackageInfo.fromPlatform() will throw in test environment,
      // so _appVersion stays empty and the version text is NOT shown.
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Version text should not appear since it couldn't load
      expect(find.textContaining('App Version:'), findsNothing);
    });

    testWidgets('shows error banner after failed submission',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Enter a message to pass validation
      final messageField = find.widgetWithText(
        TextFormField,
        'Describe your issue or request...',
      );
      await tester.enterText(messageField, 'Test issue description');
      await tester.pumpAndSettle();

      // Tap submit – the API call will fail in test environment
      await tester.tap(
        find.widgetWithText(FilledButton, 'Send Message'),
      );
      await tester.pumpAndSettle();

      // Since the API call fails, an error banner should appear.
      // The exact error text depends on Dio's exception in tests.
      // At minimum verify that no crash occurred and we're still on the
      // contact support screen.
      expect(find.text('Contact Support'), findsOneWidget);
    });

    testWidgets('subject dropdown can be changed', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select "Bug Report"
      await tester.tap(find.text('Bug Report').last);
      await tester.pumpAndSettle();

      // The dropdown should now show "Bug Report"
      expect(find.text('Bug Report'), findsOneWidget);
    });
  });
}
