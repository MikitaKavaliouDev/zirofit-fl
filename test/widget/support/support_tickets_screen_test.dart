import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';
import 'package:zirofit_fl/features/support/providers/support_ticket_provider.dart';
import 'package:zirofit_fl/features/support/screens/support_tickets_screen.dart';
import '../../helpers/test_setup.dart';

class FakeSupportTicketNotifier extends SupportTicketNotifier {
  FakeSupportTicketNotifier() : super();

  void setState(SupportTicketsState newState) {
    state = newState;
  }

  @override
  Future<void> fetchTickets() async {}
  @override
  Future<bool> createTicket(String category, String message) async => true;
}

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and no tickets', (tester) async {
    final notifier = FakeSupportTicketNotifier();
    notifier.setState(const SupportTicketsState(isLoading: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: SupportTicketsScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Support Tickets'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    final notifier = FakeSupportTicketNotifier();
    notifier.setState(const SupportTicketsState(error: 'Network error'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: SupportTicketsScreen()),
      ),
    );

    expect(find.text('Failed to load tickets'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows empty state when no tickets', (tester) async {
    final notifier = FakeSupportTicketNotifier();
    notifier.setState(const SupportTicketsState());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: SupportTicketsScreen()),
      ),
    );

    expect(find.text('No tickets yet'), findsOneWidget);
    expect(find.text('Tap + to create a support ticket'), findsOneWidget);
  });

  testWidgets('shows ticket list when tickets exist', (tester) async {
    final notifier = FakeSupportTicketNotifier();
    final ticket = SupportTicket(
      id: 'ticket-1',
      userId: 'user-1',
      category: SupportTicketCategory.bugReport,
      message: 'App crashes on startup',
      status: 'OPEN',
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );
    notifier.setState(SupportTicketsState(tickets: [ticket]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: SupportTicketsScreen()),
      ),
    );

    expect(find.text('App crashes on startup'), findsOneWidget);
  });

  testWidgets('has FAB for creating ticket', (tester) async {
    final notifier = FakeSupportTicketNotifier();
    notifier.setState(const SupportTicketsState());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: SupportTicketsScreen()),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
