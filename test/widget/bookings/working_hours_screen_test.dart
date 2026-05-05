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
    testWidgets('renders with Working Hours title', (tester) async {
      await tester.pumpWidget(buildTestApp(
        WorkingHoursState(days: _defaultDays(), isLoading: false),
      ));
      await tester.pump();

      expect(find.text('Working Hours'), findsOneWidget);
    });

    testWidgets('shows day-of-week sections', (tester) async {
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
