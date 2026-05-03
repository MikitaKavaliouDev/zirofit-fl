import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/events/screens/create_event_screen.dart';
import 'package:zirofit_fl/features/events/providers/trainer_events_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// Fake TrainerEventsNotifier that overrides createEvent to avoid real API calls.
class FakeTrainerEventsNotifier extends TrainerEventsNotifier {
  FakeTrainerEventsNotifier({required super.apiClient});

  @override
  Future<bool> createEvent(Map<String, dynamic> data) async {
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

  group('CreateEventScreen', () {
    testWidgets('renders form fields and button', (tester) async {
      await tester.pumpApp(
        const CreateEventScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          trainerEventsProvider.overrideWith(
            (ref) => FakeTrainerEventsNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // App bar title and button both have "Create Event" text
      expect(find.text('Create Event'), findsNWidgets(2));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      // Title field
      expect(find.widgetWithText(TextFormField, 'Event Title'), findsOneWidget);
      expect(find.text('Enter event title'), findsOneWidget);

      // Description field
      expect(find.widgetWithText(TextFormField, 'Description (optional)'), findsOneWidget);
      expect(find.text('Describe your event'), findsOneWidget);

      // Category dropdown
      expect(find.text('Category'), findsOneWidget);

      // Start date & time fields
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);

      // End date & time fields
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);

      // Location, address, city fields
      expect(find.widgetWithText(TextFormField, 'Location Name (optional)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Address (optional)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'City (optional)'), findsOneWidget);

      // Price and capacity fields
      expect(find.widgetWithText(TextFormField, 'Price'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Capacity'), findsOneWidget);
    });


  });
}