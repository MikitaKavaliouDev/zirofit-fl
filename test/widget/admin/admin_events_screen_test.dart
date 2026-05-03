import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_events_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeAdminNotifier extends AdminNotifier {
  final AdminState _overriddenState;

  FakeAdminNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  AdminState get state => _overriddenState;

  @override
  Future<void> fetchPendingEvents() async {}

  @override
  Future<void> moderateEvent(String id, String action) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Event _createEvent({
  String id = 'evt-1',
  String title = 'Morning Yoga',
  String trainerId = 'trainer-1',
  String? description = 'A relaxing session',
  double price = 0,
  int capacity = 20,
  int enrolledCount = 5,
}) {
  return Event(
    id: id,
    trainerId: trainerId,
    title: title,
    description: description,
    startTime: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    endTime: DateTime.fromMillisecondsSinceEpoch(1700003600000),
    price: price,
    capacity: capacity,
    enrolledCount: enrolledCount,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and events empty',
      (tester) async {
    await tester.pumpApp(
      const AdminEventsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when error state with no events', (tester) async {
    await tester.pumpApp(
      const AdminEventsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(error: 'Something went wrong'),
            )),
      ],
    );
    await tester.pump();

    // Error is not displayed in this screen, but empty state should appear
    expect(find.text('No pending events'), findsOneWidget);
    // Ensure loading indicator is not shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows pending events when data loaded', (tester) async {
    final events = [
      _createEvent(id: 'evt-1', title: 'Morning Yoga'),
      _createEvent(id: 'evt-2', title: 'HIIT Session', description: null),
    ];

    await tester.pumpApp(
      const AdminEventsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(pendingEvents: events, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('Morning Yoga'), findsOneWidget);
    expect(find.text('HIIT Session'), findsOneWidget);
    // Check for trainer id
    expect(find.text('by trainer-1'), findsNWidgets(2));
    // Check for approve/reject buttons
    expect(find.text('Approve'), findsNWidgets(2));
    expect(find.text('Reject'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no pending events', (tester) async {
    await tester.pumpApp(
      const AdminEventsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(pendingEvents: [], isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No pending events'), findsOneWidget);
  });
}