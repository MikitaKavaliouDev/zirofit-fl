import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/services/apple_calendar_service.dart';
import 'package:zirofit_fl/features/bookings/providers/client_booking_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/client_booking_screen.dart';
import '../../helpers/test_setup.dart';

// A fake AppleCalendarService that doesn't touch any native plugins.
class FakeAppleCalendarService extends AppleCalendarService {
  FakeAppleCalendarService() : super(plugin: null, prefs: null);

  @override
  Future<bool> isSyncEnabled() async => false;

  @override
  Future<void> setSyncEnabled(bool enabled) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> hasPermission() async => true;
}

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeClientBookingNotifier extends ClientBookingNotifier {
  final ClientBookingState _overriddenState;
  bool shouldSucceed = true;
  String? returnedBookingId;

  FakeClientBookingNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  ClientBookingState get state => _overriddenState;

  @override
  Future<void> fetchTrainerAvailability(String trainerId, DateTime date) async {}

  @override
  Future<void> selectDate(DateTime date) async {
    // Simulate updating state with selected date (no API call)
    // In the fake we just keep the pre-set state
  }

  @override
  Future<String?> requestBooking(String trainerId, TimeSlot slot) async {
    if (shouldSucceed) {
      return returnedBookingId ?? 'bkg-123';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _trainer = Trainer(
  id: 'trainer-1',
  name: 'Jane Coach',
  avatarUrl: null,
  specialty: 'Strength & Conditioning',
  rating: 4.8,
);

final _baseDate = DateTime(2026, 6, 15, 9, 0);
final _availableSlots = [
  TimeSlot(
    start: _baseDate,
    end: _baseDate.add(const Duration(minutes: 30)),
  ),
  TimeSlot(
    start: _baseDate.add(const Duration(hours: 1)),
    end: _baseDate.add(const Duration(minutes: 90)),
  ),
  TimeSlot(
    start: _baseDate.add(const Duration(hours: 2)),
    end: _baseDate.add(const Duration(minutes: 150)),
  ),
];

Widget buildTestApp(ClientBookingState state) {
  return ProviderScope(
    overrides: [
      clientBookingProvider.overrideWith(
        (ref) => FakeClientBookingNotifier(state),
      ),
      appleCalendarServiceProvider.overrideWith(
        (ref) => FakeAppleCalendarService(),
      ),
    ],
    child: const MaterialApp(
      home: ClientBookingScreen(trainerId: 'trainer-1'),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    configureTestApiClient();
    SharedPreferences.setMockInitialValues({});
  });

  group('ClientBookingScreen', () {
    // -----------------------------------------------------------------------
    // Test 1: Shows trainer header
    // -----------------------------------------------------------------------
    testWidgets('shows trainer header with name, specialty, rating',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ClientBookingState(
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      expect(find.text('Jane Coach'), findsOneWidget);
      expect(find.text('Strength & Conditioning'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 2: Calendar renders month grid
    // -----------------------------------------------------------------------
    testWidgets('calendar renders month grid with day headers',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ClientBookingState(isLoading: false),
      ));
      await tester.pump();

      // Month/year header should be visible
      // Since current date is May 2026, the calendar shows "May 2026" or "June 2026"
      expect(find.text('Select Date'), findsOneWidget);

      // Day-of-week headers
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 3: Available slots shown for selected date
    // -----------------------------------------------------------------------
    testWidgets('available slots shown for selected date', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          availableSlots: _availableSlots,
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Date title should be visible
      expect(find.text('June 15, 2026'), findsOneWidget);

      // Slot time labels should be visible (09:00, 10:00, 11:00)
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 4: Tap slot selects it
    // -----------------------------------------------------------------------
    testWidgets('tapping an available slot selects it', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          availableSlots: _availableSlots,
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Initially no confirm button (no slot selected)
      expect(find.text('Confirm Booking'), findsNothing);

      // Ensure the slot is visible by scrolling
      await tester.ensureVisible(find.text('09:00'));
      await tester.pump();

      // Tap the first available slot (09:00)
      await tester.tap(find.text('09:00'));
      await tester.pump();

      // Confirm button should now appear
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 5: Confirm booking shows bottom sheet
    // -----------------------------------------------------------------------
    testWidgets('tapping confirm shows bottom sheet with details',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          availableSlots: _availableSlots,
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Ensure the slot is visible by scrolling
      await tester.ensureVisible(find.text('09:00'));
      await tester.pump();

      // Select a slot
      await tester.tap(find.text('09:00'));
      await tester.pump();

      // Tap confirm button
      await tester.tap(find.text('Confirm Booking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet should show booking summary
      expect(find.text('Confirm Booking'), findsAtLeast(2));
    });

    // -----------------------------------------------------------------------
    // Test 6: Submit calls provider.requestBooking
    // -----------------------------------------------------------------------
    testWidgets('confirming booking submits and shows success snackbar',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          availableSlots: _availableSlots,
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Ensure the slot is visible by scrolling
      await tester.ensureVisible(find.text('09:00'));
      await tester.pump();

      // Select a slot
      await tester.tap(find.text('09:00'));
      await tester.pump();

      // Open bottom sheet
      await tester.tap(find.text('Confirm Booking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

    // Tap the "Confirm Booking" button inside the bottom sheet
    // Use atLeast finder since there may be multiple instances
    await tester.tap(find.text('Confirm Booking').last);
    await tester.pumpAndSettle();

    // Verify success snackbar appears
    expect(find.text('Booking confirmed! ID: bkg-123'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 7: Error shows error state
    // -----------------------------------------------------------------------
    testWidgets('error state shows error message and retry button',
        (tester) async {
      const errorMessage = 'Unable to load schedule';

      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          trainerInfo: _trainer,
          isLoading: false,
          error: errorMessage,
        ),
      ));
      await tester.pump();

      // Error message should be displayed
      expect(find.text('Failed to load slots'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);

      // Retry button should appear
      expect(find.text('Retry'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 8: Loading state
    // -----------------------------------------------------------------------
    testWidgets('loading state shows progress indicator', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          isLoading: true,
        ),
      ));
      // Use pump() with a short duration instead of pumpAndSettle
      // because CircularProgressIndicator has a continuous animation
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 9: Empty slots state
    // -----------------------------------------------------------------------
    testWidgets('no available slots shows empty state', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ClientBookingState(
          selectedDate: _baseDate,
          availableSlots: const [],
          trainerInfo: _trainer,
          isLoading: false,
        ),
      ));
      await tester.pump();

      expect(find.text('No available slots'), findsOneWidget);
      expect(find.text('Try selecting a different date'), findsOneWidget);
    });
  });
}
