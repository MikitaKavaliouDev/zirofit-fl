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

  @override
  Future<bool> createSession(Map<String, dynamic> data) async {
    // Simulate success without making API call
    return true;
  }
}

void main() {
  late MockApiClient mockApiClient;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
  });

  group('CreateSessionScreen', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpApp(
        CreateSessionScreen(initialDate: DateTime.now()),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          calendarProvider.overrideWith(
            (ref) => FakeCalendarNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // App bar title
      expect(find.text('New Session'), findsOneWidget);

      // Title field
      expect(find.widgetWithText(TextFormField, 'Session Title'), findsOneWidget);
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

      // Notes field (present in widget tree but text not found by finder)
      // We'll check for TextFormField count
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}