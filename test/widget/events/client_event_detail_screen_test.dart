import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/client_events_provider.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
import 'package:zirofit_fl/features/events/screens/client_event_detail_screen.dart';
import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifiers
// =============================================================================

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

class FakeClientEventsNotifier extends ClientEventsNotifier {
  final ClientEventsState _s;

  FakeClientEventsNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  ClientEventsState get state => _s;

  @override
  Future<bool> joinEvent(String eventId) async => true;

  @override
  Future<bool> cancelBooking(String bookingId) async => true;

  @override
  Future<void> fetchBookedEvents() async {}
}

// =============================================================================
// Helpers
// =============================================================================

const _eventId = 'evt-1';

Event _createEvent({
  String id = _eventId,
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

Widget buildTestApp({
  required EventsState eventsState,
  required ClientEventsState clientEventsState,
  String eventId = _eventId,
}) {
  return ProviderScope(
    overrides: [
      eventsProvider.overrideWith((ref) => FakeEventsNotifier(eventsState)),
      clientEventsProvider
          .overrideWith((ref) => FakeClientEventsNotifier(clientEventsState)),
    ],
    child: MaterialApp(
      home: ClientEventDetailScreen(eventId: eventId),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  group('ClientEventDetailScreen', () {
    testWidgets('renders event title and description', (tester) async {
      final event = _createEvent();
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(),
      ));
      await tester.pump();

      // Title appears in both AppBar and body
      expect(find.text('Morning Yoga'), findsAtLeast(1));
      // Description
      expect(find.text('A relaxing morning yoga session.'), findsOneWidget);
      // Category badge
      expect(find.text('Class'), findsOneWidget);
    });

    testWidgets('shows date, time, and location', (tester) async {
      final event = _createEvent();
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(),
      ));
      await tester.pump();

      // Date
      final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
      expect(
        find.text(dateFormat.format(event.startTime)),
        findsOneWidget,
      );
      // Time
      final timeFormat = DateFormat('HH:mm');
      expect(
        find.text(
          '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
        ),
        findsOneWidget,
      );
      // Location name
      expect(find.text('Ziro Fit Studio'), findsOneWidget);
      // Address
      expect(find.text('123 Main St'), findsOneWidget);
      // City
      expect(find.text('Warsaw'), findsOneWidget);

      // InfoRow icons present
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('join button is visible for non-enrolled', (tester) async {
      final event = _createEvent(enrolledCount: 5, capacity: 20);
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(),
      ));
      await tester.pump();

      // Join button should be present (not enrolled)
      expect(find.text('Join Event'), findsOneWidget);
      // Spots remaining text
      expect(find.text('15 spots remaining'), findsOneWidget);
      // Cancel button should NOT be present
      expect(find.text('Cancel Booking'), findsNothing);
    });

    testWidgets('cancel booking visible when enrolled', (tester) async {
      final event = _createEvent(enrolledCount: 5, capacity: 20);
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: ClientEventsState(
          bookedEvents: [event],
        ),
      ));
      await tester.pump();

      // Cancel button should be present
      expect(find.text('Cancel Booking'), findsOneWidget);
      // Join button should NOT be present
      expect(find.text('Join Event'), findsNothing);
    });

    testWidgets('loading state shows spinner', (tester) async {
      final event = _createEvent();
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(isLoading: true),
      ));
      await tester.pump();

      // Loading state: either "Joining..." or "Cancelling..." text
      // For non-enrolled: shows "Joining..." with CircularProgressIndicator
      expect(find.text('Joining...'), findsOneWidget);
      // CircularProgressIndicator in the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('event not found when id is missing', (tester) async {
      final event = _createEvent(id: 'evt-other');
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(),
        eventId: 'nonexistent',
      ));
      await tester.pump();

      expect(find.text('Event not found'), findsOneWidget);
    });

    testWidgets('full event shows Event Full button', (tester) async {
      final event = _createEvent(enrolledCount: 20, capacity: 20);
      await tester.pumpWidget(buildTestApp(
        eventsState: EventsState(events: [event]),
        clientEventsState: const ClientEventsState(),
      ));
      await tester.pump();

      expect(find.text('Event is full'), findsOneWidget);
      expect(find.text('Event Full'), findsOneWidget);
    });
  });
}
