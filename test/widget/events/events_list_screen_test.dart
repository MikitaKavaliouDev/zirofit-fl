import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
import 'package:zirofit_fl/features/events/screens/events_list_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeEventsNotifier extends EventsNotifier {
  final EventsState _overriddenState;

  FakeEventsNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  EventsState get state => _overriddenState;

  @override
  Future<void> fetchEvents({int? page, String? category}) async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> joinEvent(String eventId) async => true;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Event _createEvent({
  String id = 'evt-1',
  String title = 'Morning Yoga',
  String? category = 'Class',
  double price = 0,
  int capacity = 20,
  int enrolledCount = 5,
}) {
  return Event(
    id: id,
    trainerId: 'trainer-1',
    title: title,
    startTime: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    endTime: DateTime.fromMillisecondsSinceEpoch(1700003600000),
    price: price,
    capacity: capacity,
    enrolledCount: enrolledCount,
    category: category,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

Widget buildTestApp(EventsState state) {
  return ProviderScope(
    overrides: [
      eventsProvider.overrideWith((ref) => FakeEventsNotifier(state)),
    ],
    child: const MaterialApp(
      home: EventsListScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const EventsState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows event cards when data is loaded', (tester) async {
    final events = [
      _createEvent(id: 'evt-1', title: 'Morning Yoga', price: 0),
      _createEvent(
        id: 'evt-2',
        title: 'HIIT Session',
        price: 29.99,
        capacity: 15,
        enrolledCount: 10,
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      EventsState(events: events, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Morning Yoga'), findsOneWidget);
    expect(find.text('HIIT Session'), findsOneWidget);
    // Free badge
    expect(find.text('Free'), findsOneWidget);
    // Category chips
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('shows empty state when no events', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const EventsState(events: [], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('No events found'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const EventsState(events: [], isLoading: false, error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Failed to load events'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
