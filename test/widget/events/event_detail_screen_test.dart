import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';
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
  Future<bool> joinEvent(String eventId) async => true;

  @override
  Future<void> fetchEvents({int? page, String? category}) async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Event _createEvent({
  String id = 'evt-1',
  String title = 'Morning Yoga',
  String? description = 'A relaxing morning yoga session.',
  String? category = 'Class',
  String? locationName = 'Ziro Fit Studio',
  String? address = '123 Main St',
  String? city = 'Warsaw',
  double price = 0,
  int capacity = 20,
  int enrolledCount = 5,
}) {
  return Event(
    id: id,
    trainerId: 'trainer-1',
    title: title,
    description: description,
    startTime: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    endTime: DateTime.fromMillisecondsSinceEpoch(1700003600000),
    locationName: locationName,
    address: address,
    city: city,
    price: price,
    capacity: capacity,
    enrolledCount: enrolledCount,
    category: category,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

Widget buildTestApp(EventsState state, {String eventId = 'evt-1'}) {
  return ProviderScope(
    overrides: [
      eventsProvider.overrideWith((ref) => FakeEventsNotifier(state)),
    ],
    child: MaterialApp(
      home: EventDetailScreen(eventId: eventId),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows event details when event is found', (tester) async {
    final event = _createEvent();
    await tester.pumpWidget(buildTestApp(
      EventsState(events: [event], isLoading: false),
    ));
    await tester.pump();

    // Title (appears in both AppBar title and heading, so at least 1)
    expect(find.text('Morning Yoga'), findsAtLeast(1));
    // Category
    expect(find.text('Class'), findsOneWidget);
    // Description
    expect(find.text('A relaxing morning yoga session.'), findsOneWidget);
    // Location
    expect(find.text('Ziro Fit Studio'), findsOneWidget);
    // Address
    expect(find.text('123 Main St'), findsOneWidget);
    // City
    expect(find.text('Warsaw'), findsOneWidget);
    // Free price
    expect(find.text('Free'), findsOneWidget);
    // Enrolled count
    expect(find.text('5 / 20 enrolled'), findsOneWidget);
    // Join button
    expect(find.text('Join Event'), findsOneWidget);
  });

  testWidgets('shows event full when no spots left', (tester) async {
    final event = _createEvent(enrolledCount: 20, capacity: 20);
    await tester.pumpWidget(buildTestApp(
      EventsState(events: [event], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Event is full'), findsOneWidget);
    expect(find.text('Event Full'), findsOneWidget);
    expect(find.text('Event is full'), findsOneWidget);
  });

  testWidgets('shows event not found when id missing', (tester) async {
    final event = _createEvent(id: 'evt-other');
    await tester.pumpWidget(buildTestApp(
      EventsState(events: [event], isLoading: false),
      eventId: 'evt-nonexistent',
    ));
    await tester.pump();

    expect(find.text('Event not found'), findsOneWidget);
  });

  testWidgets('shows paid event price correctly', (tester) async {
    final event = _createEvent(price: 49.99);
    await tester.pumpWidget(buildTestApp(
      EventsState(events: [event], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('49.99 PLN'), findsOneWidget);
  });
}
