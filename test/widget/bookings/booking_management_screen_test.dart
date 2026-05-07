import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_management_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/booking_management_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeBookingManagementNotifier extends BookingManagementNotifier {
  FakeBookingManagementNotifier() : super(apiClient: ApiClient.instance);

  @override
  BookingManagementState get state => _overriddenState;
  set testState(BookingManagementState s) => _overriddenState = s;
  BookingManagementState _overriddenState = const BookingManagementState();

  @override
  Future<void> fetchAll() async {}

  @override
  Future<bool> approveBooking(String id) async => true;

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

Widget buildTestApp(BookingManagementState state) {
  return ProviderScope(
    overrides: [
      bookingManagementProvider.overrideWith(
        (ref) {
          final notifier = FakeBookingManagementNotifier();
          notifier.testState = state;
          return notifier;
        },
      ),
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
    // Test 1: Shows 3 tabs
    testWidgets('shows Pending / Confirmed / Declined tabs', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingManagementState(isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
    });

    // Test 2: Pending tab shows requests
    testWidgets('Pending tab shows booking requests', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          pendingBookings: [
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

      // Pending tab is shown by default
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });

    // Test 3: Approve action with confirmation
    testWidgets('Approve button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          pendingBookings: [
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

      // Tap Approve button
      await tester.tap(find.text('Approve'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Confirmation dialog should appear
      expect(find.text('Approve Booking'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    // Test 4: Decline action with confirmation
    testWidgets('Decline button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          pendingBookings: [
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

      // Confirmation dialog should appear
      expect(find.text('Decline Booking'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    // Test 5: Empty state per tab
    testWidgets('shows empty state for pending tab when no bookings',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingManagementState(isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Default tab is Pending
      expect(find.text('No pending bookings'), findsOneWidget);
      expect(find.text('New requests will appear here'), findsOneWidget);
    });

    testWidgets('shows empty state for confirmed tab', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingManagementState(isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to Confirmed tab
      await tester.tap(find.text('Confirmed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No confirmed bookings'), findsOneWidget);
      expect(find.text('Approved bookings will appear here'), findsOneWidget);
    });

    testWidgets('shows empty state for declined tab', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingManagementState(isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to Declined tab
      await tester.tap(find.text('Declined'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No declined bookings'), findsOneWidget);
      expect(find.text('Declined bookings will appear here'), findsOneWidget);
    });

    testWidgets('expanding a booking shows details and notes', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          pendingBookings: [
            _createBooking(
              id: 'bkg-1',
              clientName: 'John Doe',
              status: BookingStatus.pending,
              clientNotes: 'Looking forward to my session',
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially details should not be visible
      expect(find.text('Client Notes'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now details should be visible
      expect(find.text('Client Notes'), findsOneWidget);
      expect(find.text('Looking forward to my session'), findsOneWidget);
      // Action buttons visible for pending
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingManagementState(isLoading: true),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('confirmed tab shows confirmed bookings', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          confirmedBookings: [
            _createBooking(
              id: 'bkg-2',
              clientName: 'Jane Confirmed',
              status: BookingStatus.confirmed,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to Confirmed tab
      await tester.tap(find.text('Confirmed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Jane Confirmed'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      // No Approve/Decline buttons for confirmed bookings
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('declined tab shows declined bookings', (tester) async {
      await tester.pumpWidget(buildTestApp(
        BookingManagementState(
          declinedBookings: [
            _createBooking(
              id: 'bkg-3',
              clientName: 'Bob Declined',
              status: BookingStatus.cancelled,
            ),
          ],
          isLoading: false,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to Declined tab
      await tester.tap(find.text('Declined'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Bob Declined'), findsOneWidget);
      expect(find.text('DECLINED'), findsOneWidget);
    });
  });
}
