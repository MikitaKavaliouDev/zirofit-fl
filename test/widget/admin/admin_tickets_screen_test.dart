import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_tickets_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeAdminNotifier extends AdminNotifier {
  final AdminState _overriddenState;

  FakeAdminNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  AdminState get state => _overriddenState;

  @override
  Future<void> fetchTickets() async {}

  @override
  Future<void> updateTicketStatus(String id, String status) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SupportTicket _createTicket({
  String id = 'ticket-1',
  String userId = 'user-1',
  SupportTicketCategory category = SupportTicketCategory.bugReport,
  String message = 'App crashes on startup',
  String status = 'OPEN',
}) {
  return SupportTicket(
    id: id,
    userId: userId,
    category: category,
    message: message,
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and tickets empty',
      (tester) async {
    await tester.pumpApp(
      const AdminTicketsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when error state with no tickets', (tester) async {
    await tester.pumpApp(
      const AdminTicketsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(error: 'Something went wrong'),
            )),
      ],
    );
    await tester.pump();

    // Error is not displayed in this screen, but empty state should appear
    expect(find.text('No support tickets'), findsOneWidget);
    // Ensure loading indicator is not shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows tickets when data loaded', (tester) async {
    final tickets = [
      _createTicket(id: 'ticket-1', message: 'App crashes on startup', status: 'OPEN'),
      _createTicket(id: 'ticket-2', message: 'Feature request: dark mode', status: 'IN_PROGRESS', category: SupportTicketCategory.featureRequest),
    ];

    await tester.pumpApp(
      const AdminTicketsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(tickets: tickets, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('App crashes on startup'), findsOneWidget);
    expect(find.text('Feature request: dark mode'), findsOneWidget);
    // Check for status chips
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('IN_PROGRESS'), findsOneWidget);
    // Check for user id
    expect(find.text('user-1'), findsNWidgets(2));
    // Check for action chips (status change buttons)
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolve'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no tickets', (tester) async {
    await tester.pumpApp(
      const AdminTicketsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(tickets: [], isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No support tickets'), findsOneWidget);
  });
}