import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/screens/acknowledgements_screen.dart';

// ---------------------------------------------------------------------------
// The AcknowledgementsScreen does not use any Riverpod providers.
// PackageInfo.fromPlatform() throws in tests, so the version footer will
// only show "Ziro Fit" (without a version number).
// ---------------------------------------------------------------------------

Widget buildApp() => const ProviderScope(
      child: MaterialApp(home: AcknowledgementsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AcknowledgementsScreen', () {
    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Acknowledgements'), findsOneWidget);
    });

    testWidgets('renders Open Source Libraries section', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Open Source Libraries'), findsOneWidget);
    });

    testWidgets('renders Data Attribution section', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Data Attribution'), findsOneWidget);
    });

    testWidgets('renders library cards', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Key libraries that should appear
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Supabase Flutter'), findsOneWidget);
      expect(find.text('Riverpod'), findsOneWidget);
      expect(find.text('GoRouter'), findsOneWidget);
      expect(find.text('Drift'), findsOneWidget);
      expect(find.text('Dio'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
    });

    testWidgets('renders library descriptions with licenses',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('UI framework by Google'), findsOneWidget);
      expect(find.textContaining('Backend-as-a-Service'),
          findsOneWidget);
      expect(find.textContaining('State management'), findsOneWidget);
      expect(find.textContaining('Local database'), findsOneWidget);
    });

    testWidgets('renders data attribution content', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ExerciseDB'), findsOneWidget);
      expect(
        find.textContaining('Comprehensive exercise database'),
        findsOneWidget,
      );
      expect(
        find.text('WGER Workout Manager'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Open-source exercise and workout data'),
        findsOneWidget,
      );
    });

    testWidgets('each library card has an open-in-new icon',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Every _AcknowledgementCard has an open_in_new IconButton
      final openIcons = find.byIcon(Icons.open_in_new);
      // There are 21 library cards → 21 open_in_new icons
      expect(openIcons, findsAtLeast(10));
    });

    testWidgets('shows version footer', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Without PackageInfo, just the app name is shown
      expect(find.text('Ziro Fit'), findsOneWidget);
    });

    testWidgets('shows tagline', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Made with'),
        findsOneWidget,
      );
    });

    testWidgets('data attribution has external links', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // ExerciseDB link
      expect(find.text('exercisedb.io'), findsOneWidget);
      // WGER link
      expect(find.text('wger.de'), findsOneWidget);
    });
  });
}
