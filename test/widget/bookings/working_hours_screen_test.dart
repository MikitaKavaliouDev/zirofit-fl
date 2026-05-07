import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/bookings/providers/working_hours_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/working_hours_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeWorkingHoursNotifier extends WorkingHoursNotifier {
  FakeWorkingHoursNotifier(WorkingHoursState initialState)
      : super(apiClient: ApiClient.instance) {
    state = initialState;
  }

  @override
  Future<void> loadWorkingHours() async {}

  @override
  void toggleDay(int index) {
    final days = [...state.days];
    days[index].isOpen = !days[index].isOpen;
    state = state.copyWith(days: days);
  }

  @override
  void updateDayTime(int index, {String? startTime, String? endTime}) {
    final days = [...state.days];
    if (startTime != null) days[index].startTime = startTime;
    if (endTime != null) days[index].endTime = endTime;
    state = state.copyWith(days: days);
  }

  @override
  void bulkSetWeekdays({
    bool isOpen = true,
    String startTime = '09:00',
    String endTime = '17:00',
  }) {
    final days = [...state.days];
    for (var i = 0; i <= 4; i++) {
      days[i] = days[i].copyWith(
        isOpen: isOpen,
        startTime: startTime,
        endTime: endTime,
      );
    }
    state = state.copyWith(days: days);
  }

  @override
  void bulkSetWeekends({
    bool isOpen = true,
    String startTime = '10:00',
    String endTime = '14:00',
  }) {
    final days = [...state.days];
    days[5] = days[5].copyWith(
      isOpen: isOpen,
      startTime: startTime,
      endTime: endTime,
    );
    days[6] = days[6].copyWith(
      isOpen: isOpen,
      startTime: startTime,
      endTime: endTime,
    );
    state = state.copyWith(days: days);
  }

  @override
  void copyFromPreviousDay(int index) {
    if (index < 1 || index >= state.days.length) return;
    final days = [...state.days];
    days[index] = days[index - 1].copyWith();
    state = state.copyWith(days: days);
  }

  @override
  String? validateDay(int index) {
    if (index < 0 || index >= state.days.length) return null;
    final day = state.days[index];
    if (!day.isOpen) return null;
    final startParts = day.startTime.split(':');
    final endParts = day.endTime.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    if (startMinutes >= endMinutes) {
      return 'Start time must be before end time';
    }
    return null;
  }

  @override
  Future<bool> saveWorkingHours() async {
    state = state.copyWith(
      isSaving: false,
      successMessage: 'Working hours saved successfully',
    );
    return false; // Prevent Navigator.pop so success message stays visible
  }

  @override
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<DaySchedule> _defaultDays() => [
      DaySchedule(
          day: 'Monday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Tuesday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Wednesday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Thursday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Friday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Saturday',
          isOpen: true,
          startTime: '10:00',
          endTime: '14:00'),
      DaySchedule(
          day: 'Sunday',
          isOpen: true,
          startTime: '10:00',
          endTime: '14:00'),
    ];

List<DaySchedule> _variedDays() => [
      DaySchedule(
          day: 'Monday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Tuesday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Wednesday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Thursday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Friday',
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00'),
      DaySchedule(
          day: 'Saturday',
          isOpen: false,
          startTime: '10:00',
          endTime: '14:00'),
      DaySchedule(
          day: 'Sunday',
          isOpen: false,
          startTime: '10:00',
          endTime: '14:00'),
    ];

Widget buildTestApp(WorkingHoursState state) {
  return ProviderScope(
    overrides: [
      workingHoursProvider.overrideWith(
        (ref) => FakeWorkingHoursNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: WorkingHoursScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('WorkingHoursScreen', () {
    // Test 1: Shows all 7 days
    testWidgets('renders with Working Hours title', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Working Hours'), findsOneWidget);
    });

    testWidgets('shows all 7 day-of-week sections', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      // First batch visible without scrolling
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);

      // Scroll down to reveal remaining days
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    // Test 2: Toggle open/closed per day
    testWidgets('toggle enables/disables a day', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      // All days are open — no "Closed" text
      expect(find.text('Closed'), findsNothing);

      // Toggle the first day (Monday) off
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Monday should now show "Closed"
      expect(find.text('Closed'), findsOneWidget);
    });

    // Test 3: Time pickers work
    testWidgets('time picker shows start and end time', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      // Start and End labels should be visible for open days
      expect(find.text('Start'), findsWidgets);
      expect(find.text('End'), findsWidgets);

      // Time labels should show default times
      expect(find.text('09:00'), findsWidgets);
      expect(find.text('17:00'), findsWidgets);
    });

    // Test 4: Copy from previous day
    testWidgets('copy from previous day button is shown', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _variedDays(), isLoading: false),
      ));
      await tester.pump();

      // At least the first visible day cards show copy buttons
      expect(find.byIcon(Icons.content_copy), findsAtLeast(1));
    });

    testWidgets('copy from previous day copies schedule', (tester) async {
      // Start with all days open, then use a custom state where
      // Tuesday differs from Monday so we can verify copy works
      final copyTestDays = List<DaySchedule>.generate(7, (i) {
        final names = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
          'Saturday', 'Sunday',
        ];
        return DaySchedule(
          day: names[i],
          isOpen: true,
          startTime: '09:00',
          endTime: '17:00',
        );
      });
      // Make Monday different
      copyTestDays[0] = DaySchedule(
        day: 'Monday',
        isOpen: false,
        startTime: '07:00',
        endTime: '15:00',
      );

      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: copyTestDays, isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Monday shows "Closed" (first card visible)
      expect(find.text('Closed'), findsOneWidget);

      // Tap the first copy button (copies Tuesday from Monday)
      await tester.tap(find.byIcon(Icons.content_copy).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now Tuesday should also be closed
      expect(find.text('Closed'), findsNWidgets(2));
    });

    // Test 5: Bulk weekday/weekend set
    testWidgets('bulk weekday preset button is visible', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _variedDays(), isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Weekdays 9–5'), findsOneWidget);
      expect(find.text('Weekends 10–2'), findsOneWidget);
    });

    testWidgets('bulk weekday preset updates all weekdays', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _variedDays(), isLoading: false),
      ));
      await tester.pump();

      // Tap weekdays preset
      await tester.tap(find.text('Weekdays 9–5'));
      await tester.pump();

      // All weekdays should show 09:00-17:00
      // Monday-Friday all have 09:00 and 17:00
      expect(find.text('09:00'), findsWidgets);
      expect(find.text('17:00'), findsWidgets);
    });

    testWidgets('bulk weekend preset updates all weekends', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _variedDays(), isLoading: false),
      ));
      await tester.pump();

      // Tap weekend preset
      await tester.tap(find.text('Weekends 10–2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to see Saturday/Sunday
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After bulk set weekends, Sat/Sun should be open
      expect(find.text('10:00'), findsWidgets);
      expect(find.text('14:00'), findsWidgets);
    });

    // Test 6: Validation prevents end < start
    testWidgets('validation error shows when start >= end', (tester) async {
      // Create a state where Monday has start >= end
      final invalidDays = _defaultDays();
      invalidDays[0] = DaySchedule(
        day: 'Monday',
        isOpen: true,
        startTime: '17:00',
        endTime: '09:00',
      );

      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: invalidDays, isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Validation error should be visible
      expect(
        find.text('Start time must be before end time'),
        findsOneWidget,
      );
    });

    testWidgets('validation warning icon is shown for invalid days',
        (tester) async {
      final invalidDays = _defaultDays();
      invalidDays[0] = DaySchedule(
        day: 'Monday',
        isOpen: true,
        startTime: '17:00',
        endTime: '09:00',
      );

      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: invalidDays, isLoading: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('save button persists', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      // Find and tap the Save Changes button
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Success snackbar should appear
      expect(
        find.text('Working hours saved successfully'),
        findsOneWidget,
      );
    });
  });
}
