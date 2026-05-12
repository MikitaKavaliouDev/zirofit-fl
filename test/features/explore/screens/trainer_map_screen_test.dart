import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/trainer_map_screen.dart';
import '../../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class _FakeExploreNotifier extends ExploreNotifier {
  _FakeExploreNotifier(ExploreState overriddenState) : super() {
    state = overriddenState;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp(ExploreState state) {
  return ProviderScope(
    overrides: [
      exploreProvider
          .overrideWith((ref) => _FakeExploreNotifier(state)),
    ],
    child: const MaterialApp(
      home: TrainerMapScreen(),
    ),
  );
}

/// Creates a [Profile] for test purposes. Returns it WITHOUT lat/lng
/// by default to avoid creating map markers (which trigger FlutterMap
/// and cause UnsupportedError in the test environment).
Profile _trainer({
  required String id,
  String? aboutMe = 'Trainer',
  double? latitude,
  double? longitude,
}) {
  return Profile(
    id: id,
    userId: 'user-$id',
    aboutMe: aboutMe,
    latitude: latitude,
    longitude: longitude,
    specialties: const [],
    businessCurrency: 'PLN',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerMapScreen', () {
    // =====================================================================
    // Test: Screen renders without crashing (empty state)
    // =====================================================================
    testWidgets('renders without crashing with empty state', (tester) async {
      await tester.pumpWidget(_buildApp(const ExploreState()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Explore Map'), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
    });

    // =====================================================================
    // Test: Map view shown by default when no markers (isListView = false)
    // =====================================================================
    testWidgets('shows map view by default when isListView is false',
        (tester) async {
      await tester.pumpWidget(_buildApp(const ExploreState()));
      await tester.pump();

      // Empty map view text
      expect(
        find.text('No trainers or events with locations'),
        findsOneWidget,
      );
      // List empty state should NOT be present
      expect(find.text('No trainers with locations'), findsNothing);
    });

    // =====================================================================
    // Test: List view shows when toggled (isListView = true)
    // =====================================================================
    testWidgets('shows list view when toggled from map view', (tester) async {
      await tester.pumpWidget(_buildApp(const ExploreState()));
      await tester.pump();

      // Tap toggle button (Icons.list)
      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();

      // List view empty state shown
      expect(find.text('No trainers with locations'), findsOneWidget);

      // Toggle button changed
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    // =====================================================================
    // Test: Toggle switches back to map view
    // =====================================================================
    testWidgets('toggle switches back to map view from list view',
        (tester) async {
      await tester.pumpWidget(_buildApp(const ExploreState()));
      await tester.pump();

      // Switch to list view
      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();

      // Switch back to map view
      await tester.tap(find.byIcon(Icons.map));
      await tester.pump();

      // Back to map view
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(
        find.text('No trainers or events with locations'),
        findsOneWidget,
      );
    });

    // =====================================================================
    // Test: List view shows trainer names (trainers WITHOUT lat/lng)
    //
    // We use trainers without lat/lng so no map markers are created,
    // avoiding FlutterMap rendering issues in the test environment.
    // =====================================================================
    testWidgets('list view shows trainer names when trainers exist',
        (tester) async {
      final trainers = [
        _trainer(id: 't1', aboutMe: 'Alice'),
        _trainer(id: 't2', aboutMe: 'Bob'),
      ];

      await tester.pumpWidget(
        _buildApp(ExploreState(trainers: trainers)),
      );
      await tester.pump();

      // Tap toggle to switch to list view
      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();

      // Trainer names should appear in the list
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Empty text should be gone
      expect(find.text('No trainers with locations'), findsNothing);
    });
  });
}
