import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_settings_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/booking_window_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeBookingSettingsNotifier extends BookingSettingsNotifier {
  FakeBookingSettingsNotifier(BookingSettingsState initialState)
      : super(apiClient: ApiClient.instance) {
    state = initialState;
  }

  @override
  Future<void> loadSettings() async {}

  @override
  void updateAdvanceNotice(int hours) {
    state = state.copyWith(advanceNotice: hours.clamp(2, 72));
  }

  @override
  void updateBookingHorizon(int days) {
    state = state.copyWith(bookingHorizon: days.clamp(7, 90));
  }

  @override
  void updateBufferMinutes(int minutes) {
    state = state.copyWith(bufferMinutes: minutes.clamp(0, 120));
  }

  @override
  Future<bool> saveSettings() async {
    state = state.copyWith(
      isSaving: false,
      successMessage: 'Booking window settings saved',
    );
    return false; // Prevent Navigator.pop so message stays visible
  }

  @override
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildTestApp(BookingSettingsState state) {
  return ProviderScope(
    overrides: [
      bookingSettingsProvider.overrideWith(
        (ref) => FakeBookingSettingsNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: BookingWindowScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('BookingWindowScreen', () {
    testWidgets('shows title and description', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Booking Window'), findsOneWidget);
      expect(
        find.text(
          'Control how far in advance clients can book and how much time you need between sessions.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows all 3 pickers with current values', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Card titles
      expect(find.text('Advance Notice'), findsOneWidget);
      expect(find.text('Booking Horizon'), findsOneWidget);
      expect(find.text('Buffer Time'), findsOneWidget);

      // Values displayed
      expect(find.text('24'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Units
      expect(find.text('hours'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('change advance notice by tapping + button', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Tap the + button (first add_rounded icon)
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump();

      // Value should now be 25
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('change advance notice by tapping - button', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Tap the - button (first remove_rounded icon)
      await tester.tap(find.byIcon(Icons.remove_rounded).first);
      await tester.pump();

      // Value should now be 23
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('change booking horizon by tapping + button',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Tap the + button (second add_rounded icon — first is advance notice, second is horizon)
      await tester.tap(find.byIcon(Icons.add_rounded).at(1));
      await tester.pump();

      // Value should now be 31
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('change booking horizon by tapping - button',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Tap the - button (second remove_rounded icon)
      await tester.tap(find.byIcon(Icons.remove_rounded).at(1));
      await tester.pump();

      // Value should now be 29
      expect(find.text('29'), findsOneWidget);
    });

    testWidgets('buffer time picker increments by step of 5', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Scroll down to reveal buffer time card
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // Tap the + button for buffer time (third add_rounded icon)
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pump();

      // Buffer time should increment by 5 → 5
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('buffer time decrements by step of 5', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 10,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Scroll down to reveal buffer time card
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // Tap the - button for buffer time (last remove_rounded icon)
      await tester.tap(find.byIcon(Icons.remove_rounded).last);
      await tester.pump();

      // Buffer time should decrement by 5 → 5
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('save button calls provider and shows success',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(
          advanceNotice: 24,
          bookingHorizon: 30,
          bufferMinutes: 0,
          isLoading: false,
        ),
      ));
      await tester.pump();

      // Find and tap the Save Changes button
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Success message should appear
      expect(
        find.text('Booking window settings saved'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(isLoading: true),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('pickers disabled when loading', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const BookingSettingsState(isLoading: true),
      ));
      await tester.pump();

      // Picker cards should not be visible while loading
      expect(find.text('Advance Notice'), findsNothing);
      expect(find.text('Booking Horizon'), findsNothing);
      expect(find.text('Buffer Time'), findsNothing);
    });
  });
}
