import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/support/screens/create_ticket_screen.dart';
import 'package:zirofit_fl/features/support/providers/support_ticket_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// Fake SupportTicketNotifier that overrides createTicket to avoid real API calls.
class FakeSupportTicketNotifier extends SupportTicketNotifier {
  FakeSupportTicketNotifier({super.apiClient});

  @override
  Future<bool> createTicket(String category, String message) async {
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

  group('CreateTicketScreen', () {
    testWidgets('renders form fields and button', (tester) async {
      await tester.pumpApp(
        const CreateTicketScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          supportTicketsProvider.overrideWith(
            (ref) => FakeSupportTicketNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // App bar title
      expect(find.text('Create Ticket'), findsOneWidget);

      // Category dropdown
      expect(find.text('Category'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      // The selected value text should be visible
      expect(find.text('General Support'), findsOneWidget);

      // Message field
      expect(find.text('Message'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Describe your issue or request...'), findsOneWidget);

      // Submit button
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Submit Ticket'), findsOneWidget);
    });

    testWidgets('validation shows error when message is empty', (tester) async {
      await tester.pumpApp(
        const CreateTicketScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          supportTicketsProvider.overrideWith(
            (ref) => FakeSupportTicketNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Tap submit button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Expect validation error for message
      expect(find.text('Please enter a message'), findsOneWidget);
    });
  });
}
