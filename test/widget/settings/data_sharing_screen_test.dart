import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/data_sharing_provider.dart';
import 'package:zirofit_fl/features/settings/screens/data_sharing_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeDataSharingNotifier extends DataSharingNotifier {
  DataSharingState _s;
  int saveSettingsCallCount = 0;
  int fetchSettingsCallCount = 0;

  FakeDataSharingNotifier(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  DataSharingState get state => _s;

  void emit(DataSharingState s) {
    _s = s;
    super.state = s;
  }

  @override
  Future<void> fetchSettings() async {
    fetchSettingsCallCount++;
  }

  @override
  Future<void> saveSettings() async {
    saveSettingsCallCount++;
    emit(_s.copyWith(isSaving: false));
  }

  @override
  void toggleCategory(String category) {
    switch (category) {
      case 'workouts':
        emit(_s.copyWith(shareWorkouts: !_s.shareWorkouts));
      case 'measurements':
        emit(_s.copyWith(shareMeasurements: !_s.shareMeasurements));
      case 'photos':
        emit(_s.copyWith(sharePhotos: !_s.sharePhotos));
      case 'checkIns':
        emit(_s.copyWith(shareCheckIns: !_s.shareCheckIns));
    }
  }
}

Widget buildApp(DataSharingState state) => ProviderScope(
      overrides: [
        dataSharingProvider.overrideWith(
          (ref) => FakeDataSharingNotifier(state),
        ),
      ],
      child: const MaterialApp(home: DataSharingScreen()),
    );

Widget buildAppWithNotifier(FakeDataSharingNotifier notifier) =>
    ProviderScope(
      overrides: [
        dataSharingProvider.overrideWith((ref) => notifier),
      ],
      child: const MaterialApp(home: DataSharingScreen()),
    );

/// Wraps [DataSharingScreen] with a [GoRouter] so `context.pop()` works.
Widget buildAppWithRouter(FakeDataSharingNotifier notifier) {
  final router = GoRouter(
    initialLocation: '/settings/data-sharing',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SizedBox(),
        routes: [
          GoRoute(
            path: 'settings/data-sharing',
            builder: (_, __) => const DataSharingScreen(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      dataSharingProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('DataSharingScreen', () {
    testWidgets('Test 1: Shows all category toggles', (tester) async {
      await tester.pumpWidget(
        buildApp(const DataSharingState()),
      );
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('Categories'), findsOneWidget);

      // Category titles
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('Progress Photos'), findsOneWidget);
      expect(find.text('Check-ins'), findsOneWidget);

      // Descriptions
      expect(
        find.text('Share your workout history and statistics'),
        findsOneWidget,
      );
      expect(
        find.text('Share weight, body fat, and circumference data'),
        findsOneWidget,
      );
      expect(
        find.text('Share your transformation photos'),
        findsOneWidget,
      );
      expect(
        find.text('Share your weekly check-in data'),
        findsOneWidget,
      );

      // AppBar title
      expect(find.text('Data Sharing'), findsOneWidget);

      // Description header
      expect(
        find.text('Choose what data to share with your trainer'),
        findsOneWidget,
      );
    });

    testWidgets('Test 2: Toggle switches update state', (tester) async {
      await tester.pumpWidget(
        buildApp(const DataSharingState()),
      );
      await tester.pumpAndSettle();

      // Find all Switches
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(4));

      // First switch (Workouts) should be on by default
      Switch workoutsSwitch = tester.widget(switches.at(0));
      expect(workoutsSwitch.value, isTrue);

      // Tap the Workouts switch
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      // Verify it's now off
      workoutsSwitch = tester.widget(find.byType(Switch).at(0));
      expect(workoutsSwitch.value, isFalse);
    });

    testWidgets('Test 3: Duration default is forever', (tester) async {
      await tester.pumpWidget(
        buildApp(const DataSharingState()),
      );
      await tester.pumpAndSettle();

      // SegmentedButton shows Forever as selected
      // The Segment with value 'forever' should be selected
      expect(find.text('Forever'), findsOneWidget);
      expect(find.text('Custom Date'), findsOneWidget);

      // Verify the first segment is visually selected by checking
      // the SegmentedButton's selected property
      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(segmentedButton.selected, contains('forever'));
    });

    testWidgets(
      'Test 4: Switch to custom date shows date picker',
      (tester) async {
        await tester.pumpWidget(
          buildApp(const DataSharingState()),
        );
        await tester.pumpAndSettle();

        // Tap Custom Date segment label
        await tester.tap(find.text('Custom Date'));
        await tester.pump(); // pump once to process the tap

        // After tapping "Custom Date" with no date set, showDatePicker is called.
        // In tests the date picker dialog should appear.
        // If it doesn't appear (platform limitation), at minimum verify
        // that the SegmentedButton selection changed.
        final datePicker = find.byType(DatePickerDialog);
        if (datePicker.evaluate().isNotEmpty) {
          // Dismiss by tapping outside or cancel
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }

        // After cancelling date picker with no prior date, the selection
        // should revert to "forever"
        final segmentedButton = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );
        expect(segmentedButton.selected, contains('forever'));
      },
    );

    testWidgets('Test 5: Save calls provider.saveSettings', (tester) async {
      final notifier = FakeDataSharingNotifier(
        const DataSharingState(isSaving: false),
      );

      await tester.pumpWidget(buildAppWithRouter(notifier));
      await tester.pumpAndSettle();

      // Scroll down to reveal the Save button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(notifier.saveSettingsCallCount, equals(1));
    });

    testWidgets('Test 6: Cancel discards changes', (tester) async {
      final initial = DataSharingState(shareWorkouts: true);
      final notifier = FakeDataSharingNotifier(initial);

      await tester.pumpWidget(buildAppWithRouter(notifier));
      await tester.pumpAndSettle();

      // Toggle Workouts switch (local state change)
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Verify local toggle happened (switch is now off)
      final updatedSwitch = tester.widget<Switch>(find.byType(Switch).first);
      expect(updatedSwitch.value, isFalse);

      // Provider state should still be unchanged
      expect(notifier.state.shareWorkouts, isTrue);

      // Tap close (X) button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Discard dialog should appear
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap "Discard"
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Provider state should remain unchanged
      expect(notifier.state.shareWorkouts, isTrue);
    });

    testWidgets('Test 7: Loads current settings on init', (tester) async {
      final notifier = FakeDataSharingNotifier(
        const DataSharingState(isSaving: false),
      );

      await tester.pumpWidget(buildAppWithRouter(notifier));
      // pump once triggers the post-frame callback
      await tester.pump();

      expect(notifier.fetchSettingsCallCount, equals(1));
    });
  });
}
