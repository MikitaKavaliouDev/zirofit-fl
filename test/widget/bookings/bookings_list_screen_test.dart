import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/bookings/providers/bookings_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/bookings_list_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeBookingsNotifier extends BookingsNotifier {
  final BookingsState _overriddenState;

  FakeBookingsNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  BookingsState get state => _overriddenState;

  @override
  Future<void> fetchBookings() async {}

  @override
  Future<bool> confirmBooking(String id) async => true;

  @override
  Future<bool> declineBooking(String id) async => true;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Booking _createBooking({
  String id = 'bkg-1',
  String clientName = 'John Doe',
  String clientEmail = 'john@example.com',
  BookingStatus status = BookingStatus.pending,
  String? clientNotes,
}) {
  return Booking(
    id: id,
    startTime: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    endTime: DateTime.fromMillisecondsSinceEpoch(1700003600000),
    status: status,
    trainerId: 'trainer-1',
    clientId: 'client-1',
    clientName: clientName,
    clientEmail: clientEmail,
    clientNotes: clientNotes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

Widget buildTestApp(BookingsState state) {
  return ProviderScope(
    overrides: [
      bookingsProvider.overrideWith((ref) => FakeBookingsNotifier(state)),
    ],
    child: const MaterialApp(
      home: BookingsListScreen(),
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
      const BookingsState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows tabs and booking cards when data is loaded',
      (tester) async {
    final bookings = [
      _createBooking(
          id: 'bkg-1',
          clientName: 'John Doe',
          status: BookingStatus.pending),
      _createBooking(
          id: 'bkg-2',
          clientName: 'Jane Smith',
          status: BookingStatus.confirmed),
      _createBooking(
          id: 'bkg-3',
          clientName: 'Bob Brown',
          status: BookingStatus.cancelled),
    ];

    await tester.pumpWidget(buildTestApp(
      BookingsState(bookings: bookings, isLoading: false),
    ));
    await tester.pump();

    // Tabs
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);

    // Pending tab is shown by default
    expect(find.text('John Doe'), findsOneWidget);
    // Confirm and Decline buttons should be visible for pending bookings
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('shows empty state for tab with no bookings', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BookingsState(bookings: [], isLoading: false),
    ));
    await tester.pump();

    // Default tab is pending — no pending bookings
    expect(find.text('No pending bookings'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BookingsState(
          bookings: [], isLoading: false, error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Failed to load bookings'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('shows booking notes when present', (tester) async {
    final bookings = [
      _createBooking(
        id: 'bkg-1',
        clientName: 'John Doe',
        status: BookingStatus.pending,
        clientNotes: 'Looking forward to it',
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      BookingsState(bookings: bookings, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Looking forward to it'), findsOneWidget);
  });

  testWidgets('switching tabs shows different bookings', (tester) async {
    final bookings = [
      _createBooking(
          id: 'bkg-1',
          clientName: 'Pending Client',
          status: BookingStatus.pending),
      _createBooking(
          id: 'bkg-2',
          clientName: 'Confirmed Client',
          status: BookingStatus.confirmed),
    ];

    await tester.pumpWidget(buildTestApp(
      BookingsState(bookings: bookings, isLoading: false),
    ));
    await tester.pump();

    // Pending tab is shown first
    expect(find.text('Pending Client'), findsOneWidget);

    // Tap Confirmed tab
    await tester.tap(find.text('Confirmed'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmed Client'), findsOneWidget);
    expect(find.text('Pending Client'), findsNothing);
  });
}
