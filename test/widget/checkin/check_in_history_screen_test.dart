import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_history_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/check_in_history_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier
// ---------------------------------------------------------------------------

class FakeCheckInHistoryNotifier extends CheckInHistoryNotifier {
  final CheckInHistoryState _state;

  /// Tracks whether refresh() was called (for pull-to-refresh test).
  bool refreshCalled = false;

  FakeCheckInHistoryNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  CheckInHistoryState get state => _state;

  @override
  Future<void> fetchHistory() async {}

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Test app builder
// ---------------------------------------------------------------------------

Widget buildApp(CheckInHistoryState state) {
  final fake = FakeCheckInHistoryNotifier(state);
  return ProviderScope(
    overrides: [
      checkInHistoryProvider.overrideWith((ref) => fake),
    ],
    child: const MaterialApp(home: CheckInHistoryScreen()),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CheckIn _createCheckIn({
  String id = 'ci-1',
  String clientId = 'client-1',
  String status = 'SUBMITTED',
  double? weight = 75.5,
  double? waistCm,
  double? sleepHours,
  int? energyLevel,
  int? stressLevel,
  int? hungerLevel,
  int? digestionLevel,
  String? nutritionCompliance,
  String? clientNotes,
  String? trainerResponse,
  DateTime? date,
}) {
  final now = DateTime.now();
  return CheckIn(
    id: id,
    clientId: clientId,
    date: date ?? now,
    status: status,
    weight: weight,
    waistCm: waistCm,
    sleepHours: sleepHours,
    energyLevel: energyLevel,
    stressLevel: stressLevel,
    hungerLevel: hungerLevel,
    digestionLevel: digestionLevel,
    nutritionCompliance: nutritionCompliance,
    clientNotes: clientNotes,
    trainerResponse: trainerResponse,
    createdAt: now,
    updatedAt: now,
  );
}

CheckInGroup _createGroup({
  required DateTime date,
  required List<CheckIn> checkIns,
}) {
  return CheckInGroup(date: date, checkIns: checkIns);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('CheckInHistoryScreen', () {
    // -----------------------------------------------------------------------
    // Test 1: Shows loading skeleton
    // -----------------------------------------------------------------------
    testWidgets('shows shimmer loading skeleton when loading and no data',
        (tester) async {
      final state = const CheckInHistoryState(isLoading: true);
      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      // Shimmer should be present
      expect(find.byType(Shimmer), findsOneWidget);
      // The list of skeleton items should be rendered inside Shimmer
      expect(find.byType(ListView), findsOneWidget);
      // Empty state text should NOT be visible
      expect(find.text('No check-ins yet'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Test 2: Shows grouped check-ins by date
    // -----------------------------------------------------------------------
    testWidgets('shows grouped check-ins by date with section headers',
        (tester) async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dateFormat = DateFormat('MMMM d, yyyy');

      final checkIn1 = _createCheckIn(
        id: 'ci-1',
        date: today,
        weight: 75.5,
        status: 'SUBMITTED',
        nutritionCompliance: 'ON_TRACK',
      );
      final checkIn2 = _createCheckIn(
        id: 'ci-2',
        date: yesterday,
        weight: 74.0,
        status: 'REVIEWED',
        nutritionCompliance: 'MOSTLY',
        trainerResponse: 'Great progress!',
      );

      final groups = [
        _createGroup(date: today, checkIns: [checkIn1]),
        _createGroup(date: yesterday, checkIns: [checkIn2]),
      ];

      final state = CheckInHistoryState(groups: groups);
      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      // Both date headers should be visible
      expect(find.text(dateFormat.format(today)), findsOneWidget);
      expect(find.text(dateFormat.format(yesterday)), findsOneWidget);

      // Weight values should be visible
      expect(find.text('75.5 kg'), findsOneWidget);
      expect(find.text('74.0 kg'), findsOneWidget);

      // Status badges should show
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);

      // Nutrition compliance values
      expect(find.text('On Track'), findsOneWidget);

      // Trainer response preview
      expect(find.text('Great progress!'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 3: Each row shows status badge
    // -----------------------------------------------------------------------
    testWidgets('each check-in row shows correct status badge',
        (tester) async {
      final now = DateTime.now();
      final pendingCheckIn = _createCheckIn(
        id: 'ci-pending',
        date: now,
        status: 'SUBMITTED',
        weight: 80.0,
      );
      final reviewedCheckIn = _createCheckIn(
        id: 'ci-reviewed',
        date: now,
        status: 'REVIEWED',
        weight: 79.0,
      );

      final groups = [
        _createGroup(date: now, checkIns: [pendingCheckIn, reviewedCheckIn]),
      ];

      final state = CheckInHistoryState(groups: groups);
      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      // Both status badges should be visible
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);

      // Both weight values
      expect(find.text('80.0 kg'), findsOneWidget);
      expect(find.text('79.0 kg'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 4: Tap expands detail
    // -----------------------------------------------------------------------
    testWidgets('tapping a check-in card expands detail with metrics',
        (tester) async {
      final now = DateTime.now();
      final checkIn = _createCheckIn(
        id: 'ci-expand',
        date: now,
        weight: 75.5,
        waistCm: 85.0,
        sleepHours: 7.5,
        energyLevel: 7,
        stressLevel: 4,
        hungerLevel: 5,
        digestionLevel: 8,
        nutritionCompliance: 'ON_TRACK',
        clientNotes: 'Feeling great this week!',
        trainerResponse: 'Keep it up!',
        status: 'REVIEWED',
      );

      final groups = [_createGroup(date: now, checkIns: [checkIn])];
      final state = CheckInHistoryState(groups: groups);

      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      // Initially the expanded detail should NOT be visible (collapse icons)
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);

      // Tap the card header
      await tester.tap(find.text('75.5 kg'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now expanded detail should be visible
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('85.0 cm'), findsOneWidget);
      expect(find.text('7.5 hrs'), findsOneWidget);
      expect(find.text('7/10'), findsOneWidget);
      expect(find.text('4/10'), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('Feeling great this week!'), findsOneWidget);
      // Trainer response appears in both collapsed preview and expanded detail
      expect(find.text('Keep it up!'), findsNWidgets(2));
    });

    // -----------------------------------------------------------------------
    // Test 5: Shows empty state when no check-ins
    // -----------------------------------------------------------------------
    testWidgets('shows empty state when no check-ins exist',
        (tester) async {
      final state = const CheckInHistoryState();
      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      expect(find.text('No check-ins yet'), findsOneWidget);
      expect(
        find.text(
          'Your weekly check-ins will appear here once submitted.',
        ),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // Test 6: Shows error state with retry
    // -----------------------------------------------------------------------
    testWidgets('shows error state with retry button', (tester) async {
      final state = const CheckInHistoryState(error: 'Network error');
      await tester.pumpWidget(buildApp(state));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 7: Pull-to-refresh calls provider
    // -----------------------------------------------------------------------
    testWidgets('pull-to-refresh triggers refresh on provider',
        (tester) async {
      final now = DateTime.now();
      final checkIn = _createCheckIn(
        id: 'ci-refresh',
        date: now,
        weight: 75.5,
        status: 'SUBMITTED',
      );

      final groups = [_createGroup(date: now, checkIns: [checkIn])];
      final state = CheckInHistoryState(groups: groups);

      // Create the notifier manually so we can inspect it
      final fake = FakeCheckInHistoryNotifier(state);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkInHistoryProvider.overrideWith((ref) => fake),
          ],
          child: const MaterialApp(home: CheckInHistoryScreen()),
        ),
      );
      await tester.pump();

      // Verify data is shown
      expect(find.text('75.5 kg'), findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // refresh should have been called
      expect(fake.refreshCalled, isTrue);
    });
  });
}
