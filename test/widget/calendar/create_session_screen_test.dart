import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/calendar/screens/create_session_screen.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// Fake CalendarNotifier that overrides createSession to avoid real API calls.
class FakeCalendarNotifier extends CalendarNotifier {
  FakeCalendarNotifier({required super.apiClient});

  Map<String, dynamic>? lastCreatedData;

  @override
  Future<bool> createSession(Map<String, dynamic> data) async {
    lastCreatedData = data;
    return true;
  }
}

void main() {
  late MockApiClient mockApiClient;
  late FakeCalendarNotifier fakeNotifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    fakeNotifier = FakeCalendarNotifier(apiClient: mockApiClient);
  });

  group('CreateSessionScreen', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );

      // App bar title
      expect(find.text('New Session'), findsOneWidget);

      // Title field
      expect(
        find.widgetWithText(TextFormField, 'Session Title'),
        findsOneWidget,
      );
      expect(find.text('Enter session title'), findsOneWidget);

      // Client dropdown
      expect(find.text('Select Client'), findsOneWidget);

      // Template dropdown (optional)
      expect(find.text('Workout Template (Optional)'), findsOneWidget);

      // Date & Time section
      expect(find.text('Date & Time'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);

      // Recurring switch
      expect(find.text('Recurring Session'), findsOneWidget);
      expect(find.text('Repeat this session'), findsOneWidget);

      // Notes field
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('title field shows validation error when empty on submit', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Submit without entering title
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(fakeNotifier.lastCreatedData, isNull);
    });

    testWidgets('client dropdown shows validation error when not selected', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Fill title but leave client unselected
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Session Title'),
        'Session without client',
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please select a client'), findsOneWidget);
      expect(fakeNotifier.lastCreatedData, isNull);
    });

    testWidgets('template dropdown selection is captured in submitted data', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Open template dropdown and select "Full Body Workout"
      await tester.tap(find.text('Workout Template (Optional)'));
      await tester.pump();
      await tester.tap(find.text('Full Body Workout').last);
      await tester.pump();

      // Fill required title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Session Title'),
        'Session with template',
      );
      await tester.pump();

      // Select client
      await tester.tap(find.text('Select Client'));
      await tester.pump();
      await tester.tap(find.text('John Doe').last);
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Create Session'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.lastCreatedData, isNotNull);
      expect(fakeNotifier.lastCreatedData!['templateId'], equals('template-1'));
      expect(
        fakeNotifier.lastCreatedData!['name'],
        equals('Session with template'),
      );
    });

    testWidgets('submitting without template does not include templateId', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Fill title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Session Title'),
        'No template session',
      );
      await tester.pump();

      // Select client
      await tester.tap(find.text('Select Client'));
      await tester.pump();
      await tester.tap(find.text('John Doe').last);
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Create Session'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.lastCreatedData, isNotNull);
      expect(fakeNotifier.lastCreatedData!.containsKey('templateId'), isFalse);
    });

    testWidgets('successful submission shows success SnackBar and pops', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Session Title'),
        'Successful session',
      );
      await tester.pump();

      await tester.tap(find.text('Select Client'));
      await tester.pump();
      await tester.tap(find.text('John Doe').last);
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Session'));
      await tester.pumpAndSettle();

      expect(find.text('Session created successfully'), findsOneWidget);
      // Navigator.pop(true) should have been called; in test we can't verify pop directly but we can check that the SnackBar is shown
    });

    testWidgets('failed submission shows error SnackBar', (tester) async {
      // Create a notifier that fails
      final failingNotifier = FakeFailingCalendarNotifier(
        apiClient: mockApiClient,
      );

      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => failingNotifier),
        ],
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Session Title'),
        'Will fail',
      );
      await tester.pump();

      await tester.tap(find.text('Select Client'));
      await tester.pump();
      await tester.tap(find.text('John Doe').last);
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Session'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to create session'), findsOneWidget);
    });

    testWidgets('recurring toggle reveals recurrence pattern dropdown', (
      tester,
    ) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Recurrence dropdown should not be visible initially: only 1 dropdown (template)
      expect(find.byType(DropdownButtonFormField), findsNWidgets(1));

      // Toggle recurrence on by tapping the SwitchListTile
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // Now recurrence pattern dropdown should appear: 2 dropdowns total
      expect(find.byType(DropdownButtonFormField), findsNWidgets(2));
      expect(
        find.widgetWithText(DropdownButtonFormField<String>, 'Daily'),
        findsOneWidget,
      );
    });

    testWidgets('template dropdown can be selected', (tester) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Open template dropdown
      await tester.tap(find.text('Workout Template (Optional)'));
      await tester.pump();

      // Verify all template options appear
      expect(find.text('Full Body Workout'), findsOneWidget);
      expect(find.text('Upper Body Focus'), findsOneWidget);
      expect(find.text('Lower Body Focus'), findsOneWidget);
      expect(find.text('Cardio Session'), findsOneWidget);

      // Select "Upper Body Focus"
      await tester.tap(find.text('Upper Body Focus'));
      await tester.pump();

      // Dropdown should now display selected value
      expect(find.text('Upper Body Focus'), findsOneWidget);
    });

    testWidgets('client dropdown can be selected', (tester) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith((ref) => fakeNotifier),
        ],
      );
      await tester.pump();

      // Open client dropdown
      await tester.tap(find.text('Select Client'));
      await tester.pump();

      // Verify client options
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Mike Johnson'), findsOneWidget);

      // Select Jane Smith
      await tester.tap(find.text('Jane Smith'));
      await tester.pump();

      // Dropdown should now display selected client name
      expect(find.text('Jane Smith'), findsOneWidget);
    });
  });
}

// Helper notifier for failure scenario
class FakeFailingCalendarNotifier extends CalendarNotifier {
  FakeFailingCalendarNotifier({required super.apiClient});

  @override
  Future<bool> createSession(Map<String, dynamic> data) async => false;
}
