import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/calendar/screens/calendar_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeCalendarNotifier extends CalendarNotifier {
  CalendarState _fakeState;

  FakeCalendarNotifier(this._fakeState)
      : super(apiClient: ApiClient.instance);

  @override
  CalendarState get state => _fakeState;

  @override
  Future<void> fetchEvents(DateTime start, DateTime end) async {
    // Do nothing for tests
  }

  @override
  Future<bool> createSession(Map<String, dynamic> data) async => true;

  @override
  Future<bool> updateSession(String id, Map<String, dynamic> data) async =>
      true;

  @override
  Future<bool> deleteSession(String id) async => true;

  @override
  Future<bool> sendReminder(String id) async => true;

  @override
  void setSelectedDate(DateTime date) {
    _fakeState = _fakeState.copyWith(selectedDate: date);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildTestApp(CalendarState state) {
  return ProviderScope(
    overrides: [
      calendarProvider.overrideWith((ref) => FakeCalendarNotifier(state)),
    ],
    child: const MaterialApp(
      home: CalendarScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows calendar screen with app bar', (tester) async {
    await tester.pumpWidget(buildTestApp(
      CalendarState(isLoading: false),
    ));
    await tester.pump();

    // Should show calendar title in app bar
    expect(find.byType(AppBar), findsOneWidget);
    // Should show navigation buttons
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('shows new session FAB', (tester) async {
    await tester.pumpWidget(buildTestApp(
      CalendarState(isLoading: false),
    ));
    await tester.pump();

    expect(find.text('New Session'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('shows weekday headers', (tester) async {
    await tester.pumpWidget(buildTestApp(
      CalendarState(isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(buildTestApp(
      CalendarState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      CalendarState(
        events: const [],
        isLoading: false,
        error: 'Network error',
      ),
    ));
    await tester.pump();

    expect(find.text('Failed to load sessions'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
