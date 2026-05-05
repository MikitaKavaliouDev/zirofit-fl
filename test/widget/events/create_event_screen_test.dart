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

// Spy TrainerEventsNotifier that records the last event data for verification.
class SpyTrainerEventsNotifier extends TrainerEventsNotifier {
  Map<String, dynamic>? lastCreatedEvent;

  SpyTrainerEventsNotifier({required super.apiClient});

  @override
  Future<bool> createEvent(Map<String, dynamic> data) async {
    lastCreatedEvent = data;
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

    testWidgets('shows validation error when title is empty', (tester) async {
      await tester.pumpApp(
        const CreateEventScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          trainerEventsProvider.overrideWith(
            (ref) => FakeTrainerEventsNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Scroll to and tap submit without filling required fields
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Event'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create Event'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('selects a category from the dropdown', (tester) async {
      await tester.pumpApp(
        const CreateEventScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          trainerEventsProvider.overrideWith(
            (ref) => FakeTrainerEventsNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Tap the category dropdown to open the menu
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Workshop' from the dropdown items
      await tester.tap(find.text('Workshop'));
      await tester.pumpAndSettle();

      // Verify the selected category is displayed
      expect(find.text('Workshop'), findsOneWidget);
    });

    testWidgets('submits form with correct data', (tester) async {
      final spyNotifier = SpyTrainerEventsNotifier(apiClient: mockApiClient);

      await tester.pumpApp(
        const CreateEventScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          trainerEventsProvider.overrideWith((ref) => spyNotifier),
        ],
      );

      // Fill in text fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Title'),
        'My Test Event',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        'A great event description',
      );

      // Select category from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workshop'));
      await tester.pumpAndSettle();

      // Fill location fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location Name (optional)'),
        'Ziro Fit Studio',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (optional)'),
        '123 Main St',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'City (optional)'),
        'Warsaw',
      );

      // Fill price and capacity
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '49.99',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Capacity'),
        '30',
      );

      // Scroll to and submit the form
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Event'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create Event'));
      await tester.pump();
      await tester.pump();

      // Verify success snackbar
      expect(find.text('Event created successfully!'), findsOneWidget);

      // Verify the correct data was passed to createEvent
      expect(spyNotifier.lastCreatedEvent, isNotNull);
      expect(spyNotifier.lastCreatedEvent!['title'], 'My Test Event');
      expect(
        spyNotifier.lastCreatedEvent!['description'],
        'A great event description',
      );
      expect(spyNotifier.lastCreatedEvent!['category'], 'Workshop');
      expect(spyNotifier.lastCreatedEvent!['locationName'], 'Ziro Fit Studio');
      expect(spyNotifier.lastCreatedEvent!['address'], '123 Main St');
      expect(spyNotifier.lastCreatedEvent!['city'], 'Warsaw');
      expect(spyNotifier.lastCreatedEvent!['price'], 49.99);
      expect(spyNotifier.lastCreatedEvent!['capacity'], 30);
    });
  });
}