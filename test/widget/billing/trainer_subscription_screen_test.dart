import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';
import 'package:zirofit_fl/features/billing/screens/trainer_subscription_screen.dart';
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
      child: const MaterialApp(home: TrainerSubscriptionScreen()),
    );

/// Scrolls the ListView down so that off-screen widgets become visible.
Future<void> scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -800));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerSubscriptionScreen', () {
    testWidgets('renders with subscription title', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Subscription'), findsOneWidget);
    });

    testWidgets('renders current plan info - active', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trainer Pro'), findsOneWidget);
      expect(find.text('\$29.99 / month'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      // Next billing date
      expect(find.text('Next billing date'), findsOneWidget);
    });

    testWidgets('renders current plan info - canceled', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('CANCELED'), findsOneWidget);
    });

    testWidgets('shows plan features for active plan', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan Features'), findsOneWidget);
      expect(find.text('Unlimited client management'), findsOneWidget);
      expect(find.text('Advanced analytics & reporting'), findsOneWidget);
      expect(find.text('Custom storefront & branding'), findsOneWidget);
      expect(find.text('Stripe Connect payouts'), findsOneWidget);
      expect(find.text('Priority support'), findsOneWidget);
      expect(find.text('Marketplace listing'), findsOneWidget);
    });

    testWidgets('shows plan features for free plan', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan Features'), findsOneWidget);
      expect(find.text('Basic client management'), findsOneWidget);
      expect(find.text('Standard workout tracking'), findsOneWidget);
      expect(find.text('Community access'), findsOneWidget);
      expect(find.text('Limited storefront'), findsOneWidget);
    });

    testWidgets('shows upgrade options', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Upgrade Plan button
      expect(find.text('Upgrade Plan'), findsOneWidget);
      // Billing History button
      expect(find.text('Billing History'), findsOneWidget);
      // Cancel Subscription button
      expect(find.text('Cancel Subscription'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          isLoading: true,
        )),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          error: 'Network error',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
