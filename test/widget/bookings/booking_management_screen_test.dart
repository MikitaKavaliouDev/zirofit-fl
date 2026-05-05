import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/bookings/providers/bookings_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/booking_management_screen.dart';
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
      home: BookingManagementScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('BookingManagementScreen', () {
    testWidgets('renders with Booking Management title', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingsState(isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Booking Management'), findsOneWidget);
    });

    testWidgets('shows All/Pending/Confirmed/Declined filter tabs',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingsState(
          bookings: [
            _createBooking(
              id: 'bkg-1',
              clientName: 'John Doe',
              status: BookingStatus.pending,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
    });

    testWidgets('expanding a booking shows details', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingsState(
          bookings: [
            _createBooking(
              id: 'bkg-1',
              clientName: 'John Doe',
              status: BookingStatus.pending,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially the details should not be visible
      expect(find.text('Booking ID'), findsNothing);

      // Tap on the booking card to expand (tap on client name)
      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now details should be visible
      expect(find.text('Booking ID'), findsOneWidget);
      expect(find.text('bkg-1'), findsOneWidget);
    });

    testWidgets('confirm button calls accept action', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingsState(
          bookings: [
            _createBooking(
              id: 'bkg-1',
              clientName: 'John Doe',
              status: BookingStatus.pending,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand the card
      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Confirm button
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // SnackBar should confirm the action
      expect(find.text('Booking confirmed'), findsOneWidget);
    });

    testWidgets('decline button calls reject action', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingsState(
          bookings: [
            _createBooking(
              id: 'bkg-1',
              clientName: 'John Doe',
              status: BookingStatus.pending,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand the card
      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Decline button
      await tester.tap(find.text('Decline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // SnackBar should confirm the action
      expect(find.text('Booking declined'), findsOneWidget);
    });

    testWidgets('empty state when no bookings', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingsState(bookings: [], isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The default "All" tab shows "No bookings yet"
      expect(find.text('No bookings yet'), findsOneWidget);
      expect(find.text('Create a new booking to get started'), findsOneWidget);
    });
  });
}
