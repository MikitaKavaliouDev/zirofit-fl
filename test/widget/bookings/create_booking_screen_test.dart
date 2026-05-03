import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/bookings/screens/create_booking_screen.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

void main() {
  late MockApiClient mockApiClient;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    // Mock the post call that CreateBookingScreen will make
    mockApiClient.mockPost(
      '/bookings',
      response: {'data': {'id': 'new-booking'}},
    );
  });

  group('CreateBookingScreen', () {
    testWidgets('renders form fields and button', (tester) async {
      await tester.pumpApp(
        const CreateBookingScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );

      // App bar title and button both have "Create Booking" text
      expect(find.text('Create Booking'), findsNWidgets(2));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      // Trainer ID field
      expect(find.widgetWithText(TextFormField, 'Trainer ID'), findsOneWidget);
      expect(find.text('Enter trainer ID'), findsOneWidget);

      // Date picker field
      expect(find.text('Date'), findsOneWidget);

      // Start time and end time fields
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);

      // Notes field
      expect(find.widgetWithText(TextFormField, 'Notes (optional)'), findsOneWidget);
      expect(find.text('Any additional information'), findsOneWidget);
    });

    testWidgets('validation shows error when trainer ID is empty',
        (tester) async {
      await tester.pumpApp(
        const CreateBookingScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );

      // Tap submit button
      await tester.tap(find.widgetWithText(FilledButton, 'Create Booking'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Trainer ID is required'), findsOneWidget);
    });

    testWidgets('validation passes when trainer ID is filled', (tester) async {
      await tester.pumpApp(
        const CreateBookingScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );

      // Enter trainer ID
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Trainer ID'), 'trainer-123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Booking'));
      await tester.pumpAndSettle();

      // No validation error for trainer ID
      expect(find.text('Trainer ID is required'), findsNothing);
    });
  });
}