import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';
import 'package:zirofit_fl/features/billing/screens/payouts_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeBillingNotifier extends BillingNotifier {
  BillingState _state;
  FakeBillingNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  BillingState get state => _state;

  void emit(BillingState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchPayouts() async {}

  @override
  Future<void> fetchRevenue() async {}

  @override
  Future<void> fetchSubscription() async {}

  @override
  Future<String?> fetchStripeOnboardingUrl() async => null;

  @override
  Future<String?> createCheckoutSession(String packageId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchStripeStatus() async => null;

  @override
  Future<String?> getStripeOnboardingUrl() async =>
      'https://connect.stripe.com/onboard/test';
}

Widget buildApp(BillingState state) => ProviderScope(
      overrides: [
        billingProvider.overrideWith((ref) => FakeBillingNotifier(state)),
      ],
      child: const MaterialApp(home: PayoutsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('PayoutsScreen', () {
    testWidgets('renders with Payouts title', (tester) async {
      await tester.pumpWidget(buildApp(const BillingState(isLoading: false)));
      await tester.pumpAndSettle();

      expect(find.text('Payouts'), findsOneWidget);
    });

    testWidgets('shows summary cards (Total, Pending, Paid)', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          totalEarned: 1500.00,
          pendingAmount: 500.00,
          paidOutAmount: 1000.00,
        )),
      );
      await tester.pumpAndSettle();

      // Summary header
      expect(find.text('Earnings Summary'), findsOneWidget);

      // Summary values
      expect(find.text('\$1500.00'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('\$1000.00'), findsOneWidget);

      // Summary labels
      expect(find.text('Total Earned'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Paid Out'), findsOneWidget);

      // Summary icons
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows Stripe Connect card', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stripe Connect'), findsOneWidget);
      expect(find.text('Connect Stripe'), findsOneWidget);
    });

    testWidgets('lists payout history', (tester) async {
      final payouts = [
        Payout(
          id: 'p1',
          amount: 200.00,
          currency: 'USD',
          status: 'paid',
          createdAt: DateTime(2026, 1, 15),
        ),
        Payout(
          id: 'p2',
          amount: 150.00,
          currency: 'USD',
          status: 'pending',
          createdAt: DateTime(2026, 1, 10),
        ),
      ];

      await tester.pumpWidget(
        buildApp(BillingState(
          isLoading: false,
          payouts: payouts,
          totalEarned: 350.00,
          pendingAmount: 150.00,
          paidOutAmount: 200.00,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payout History'), findsOneWidget);
      // Amounts shown in payout cards
      expect(find.text('\$200.00'), findsOneWidget);
      expect(find.text('\$150.00'), findsOneWidget);
      // Status chips
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(error: 'Failed to load')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows empty payout state', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No payouts yet'), findsOneWidget);
      expect(
        find.text('Payouts will appear here once processed'),
        findsOneWidget,
      );
    });

    // ---------------------------------------------------------------------------
    // Stripe Connect States
    // ---------------------------------------------------------------------------

    testWidgets('shows "Not Started" when stripeStatus is null', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: false, stripeStatus: null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stripe Connect'), findsOneWidget);
      expect(find.text('Not Started'), findsOneWidget);
      expect(find.text('Connect Stripe'), findsOneWidget);
    });

    testWidgets('shows "Not Started" when details not submitted', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          stripeStatus: <String, dynamic>{
            'charges_enabled': false,
            'details_submitted': false,
          },
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not Started'), findsOneWidget);
      expect(find.text('Connect Stripe'), findsOneWidget);
    });

    testWidgets('shows "Pending" when details submitted but not enabled',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          stripeStatus: <String, dynamic>{
            'charges_enabled': false,
            'details_submitted': true,
          },
        )),
      );
      await tester.pumpAndSettle();

      // "Pending" appears in the summary row label and the Stripe status
      expect(find.text('Pending'), findsAtLeast(1));
      expect(find.text('Connect Stripe'), findsOneWidget);
    });

    testWidgets('shows "Complete" with account ID when fully onboarded',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          stripeStatus: <String, dynamic>{
            'charges_enabled': true,
            'details_submitted': true,
            'stripe_user_id': 'acct_789',
            'payouts_enabled': true,
          },
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Account: acct_789'), findsOneWidget);
      expect(find.text('Manage Stripe Account'), findsOneWidget);
      expect(find.text('Open Stripe Dashboard'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows refresh is disabled while loading', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: true)),
      );
      await tester.pump();

      // Should show a CircularProgressIndicator instead of refresh icon
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}
