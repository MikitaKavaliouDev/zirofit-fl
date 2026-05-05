import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';
import 'package:zirofit_fl/features/billing/screens/revenue_screen.dart';
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
}

Widget buildApp(BillingState state) => ProviderScope(
      overrides: [
        billingProvider.overrideWith((ref) => FakeBillingNotifier(state)),
      ],
      child: const MaterialApp(home: RevenueScreen()),
    );

/// Scrolls the ListView down so that off-screen widgets become visible.
Future<void> scrollTransactions(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('RevenueScreen', () {
    testWidgets('renders with Revenue title', (tester) async {
      await tester.pumpWidget(buildApp(const BillingState(isLoading: false)));
      await tester.pumpAndSettle();

      expect(find.text('Revenue'), findsOneWidget);
    });

    testWidgets('shows available balance and withdraw button', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          availableForPayout: 750.00,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available for Payout'), findsOneWidget);
      expect(find.text('\$750.00'), findsOneWidget);
      expect(find.text('Withdraw Now'), findsOneWidget);
    });

    testWidgets('shows revenue chart', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          monthlyGrowth: 12.5,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Earnings History'), findsOneWidget);
      // Growth percentage badge (also appears in Stats Grid Growth stat)
      expect(find.text('12.5%'), findsAtLeast(1));
      // Day labels - "T" appears for both Tue and Thu
      expect(find.text('M'), findsAtLeast(1));
      expect(find.text('W'), findsAtLeast(1));
      expect(find.text('F'), findsAtLeast(1));
      expect(find.text('S'), findsAtLeast(1));
    });

    testWidgets('shows stats grid (Lifetime, Last Payout, Growth)', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: false,
          totalEarned: 5000.00,
          lastPayout: 1200.00,
          monthlyGrowth: 8.3,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.text('\$5000.00'), findsOneWidget);
      expect(find.text('Last Payout'), findsOneWidget);
      expect(find.text('\$1200.00'), findsOneWidget);
      expect(find.text('Growth'), findsOneWidget);
      // 8.3% appears in both the Growth stat and the Earnings Chart badge
      expect(find.text('8.3%'), findsAtLeast(1));
    });

    testWidgets('shows transactions list', (tester) async {
      final transactions = [
        const RevenueTransaction(
          id: 't1',
          title: 'Package Sale - John',
          date: 'Jan 15, 2026',
          amount: 150.00,
          status: 'completed',
        ),
        const RevenueTransaction(
          id: 't2',
          title: 'Platform Fee',
          date: 'Jan 15, 2026',
          amount: -7.50,
          status: 'deducted',
          type: 'fee',
        ),
      ];

      await tester.pumpWidget(
        buildApp(BillingState(
          isLoading: false,
          transactions: transactions,
          totalEarned: 150.00,
          availableForPayout: 142.50,
        )),
      );
      await tester.pumpAndSettle();

      // Scroll down to see transactions section
      await scrollTransactions(tester);

      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Package Sale - John'), findsOneWidget);
      expect(find.text('Platform Fee'), findsOneWidget);
      expect(find.text('+\$150.00'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      // Scroll down to see empty transactions section
      await scrollTransactions(tester);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Revenue from your services and packages will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
