import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/screens/permissions_settings_screen.dart';

// ---------------------------------------------------------------------------
// The PermissionsSettingsScreen does not use any Riverpod providers – it
// relies on permission_handler directly.  In the test environment the
// permission status calls throw MissingPluginException, which the screen
// handles gracefully: it shows an error banner AND the permission tiles
// (with "Denied" status) plus the "Open System Settings" button.
// ---------------------------------------------------------------------------

Widget buildApp() => const ProviderScope(
      child: MaterialApp(home: PermissionsSettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PermissionsSettingsScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildApp());
      // After just one pump the _checkAll post-frame callback hasn't
      // completed yet → isLoading is still true
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders AppBar title after load', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Permissions'), findsOneWidget);
    });

    testWidgets('shows error banner after permission check failure',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // In tests permission_handler throws MissingPluginException
      // The screen catches it and sets _error
      expect(
        find.text('Failed to load permission statuses.'),
        findsOneWidget,
      );
    });

    testWidgets('shows System Access section header', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('System Access'), findsOneWidget);
    });

    testWidgets('shows all four permission tiles', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Health Data'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('shows permission descriptions', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Access to take photos and record video'),
        findsOneWidget,
      );
      expect(
        find.text('Access to your photo library'),
        findsOneWidget,
      );
      expect(
        find.text('Read and write health metrics'),
        findsOneWidget,
      );
      expect(
        find.text('Access to your location while using the app'),
        findsOneWidget,
      );
    });

    testWidgets('shows Denied status badge on all tiles', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // When permissions can't be checked, the default is Denied
      // There should be 4 "Denied" badges (one per tile)
      expect(find.text('Denied'), findsNWidgets(4));
    });

    testWidgets('shows Open System Settings button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, 'Open System Settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows hint text below button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Permission changes take effect immediately.'),
        findsOneWidget,
      );
    });

    testWidgets('Open System Settings is tappable', (tester) async {
      // We can't verify settings are opened (platform channel), but
      // verify the button doesn't throw when tapped.
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(
        OutlinedButton,
        'Open System Settings',
      );
      await tester.tap(button);
      await tester.pumpAndSettle();

      // No crash is the assertion
      expect(find.text('Permissions'), findsOneWidget);
    });

    testWidgets('error banner has dismiss icon', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // The error banner has a close button to retry
      final closeIcons = find.byIcon(Icons.close);
      expect(closeIcons, findsAtLeast(1));
    });
  });
}
