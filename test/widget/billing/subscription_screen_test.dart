import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';
import 'package:zirofit_fl/features/billing/screens/subscription_screen.dart';
import '../../helpers/test_setup.dart';

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
  Future<void> fetchSubscription() async {}

  @override
  Future<String?> createCheckoutSession(String packageId) async => null;
}

Widget buildApp(BillingState state) {
  return ProviderScope(
    overrides: [
      billingProvider.overrideWith(
        (ref) => FakeBillingNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: SubscriptionScreen(),
    ),
  );
}

/// Scrolls the ListView down so that off-screen widgets become visible.
Future<void> scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -1000));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('SubscriptionScreen', () {
    testWidgets('shows loading indicator when isLoading and no status',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(error: 'Something went wrong')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows current plan card with active status', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // "Current Plan" appears as card title and as chip on Pro card
      expect(find.text('Current Plan'), findsAtLeast(1));
      expect(find.text('Pro Plan'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows current plan card with free (canceled) status',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // "Free Plan" appears once as the plan label in the current plan card
      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows all plan option cards', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Free and Pro plan names are visible without scrolling
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);

      // Scroll down to reveal Enterprise
      await scrollToBottom(tester);
      expect(find.text('Enterprise'), findsOneWidget);

      // Prices (visible after scroll)
      expect(find.textContaining('29/mo'), findsOneWidget);
      expect(find.textContaining('99/mo'), findsOneWidget);
    });

    testWidgets('shows Current Plan chip on card when canceled',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // "Current Plan" appears as the card title and as a chip on the Free plan
      expect(find.text('Current Plan'), findsAtLeast(1));
    });

    testWidgets('shows upgrade buttons for non-current plans', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Free is current (canceled == free), so no upgrade button for Free
      // Pro should have upgrade button
      final proUpgrade = find.widgetWithText(FilledButton, 'Upgrade to Pro');
      expect(proUpgrade, findsOneWidget);

      // Scroll to see Enterprise upgrade button
      await scrollToBottom(tester);
      final enterpriseUpgrade =
          find.widgetWithText(FilledButton, 'Upgrade to Enterprise');
      expect(enterpriseUpgrade, findsOneWidget);
    });

    testWidgets('shows Manage Subscription button when active',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'active',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      expect(find.text('Manage Subscription'), findsOneWidget);
    });

    testWidgets('does not show Manage Subscription when not active',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Subscription'), findsNothing);
    });

    testWidgets('shows features for each plan', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'canceled',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Free features (always visible)
      expect(find.text('Basic workout tracking'), findsOneWidget);
      expect(find.text('Limited client management'), findsOneWidget);
      expect(find.text('Community access'), findsOneWidget);

      // Pro features (always visible)
      expect(find.text('Unlimited workout tracking'), findsOneWidget);
      expect(find.text('Full client management'), findsOneWidget);
      expect(find.text('Advanced analytics'), findsOneWidget);
      expect(find.text('Priority support'), findsOneWidget);

      // Enterprise features (need scroll)
      await scrollToBottom(tester);
      expect(find.text('Everything in Pro'), findsOneWidget);
      expect(find.text('Team management'), findsOneWidget);
      expect(find.text('Custom branding'), findsOneWidget);
      expect(find.text('Dedicated account manager'), findsOneWidget);
      expect(find.text('API access'), findsOneWidget);
    });

    testWidgets('shows past due message for past_due status', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'past_due',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pro Plan (Past Due)'), findsOneWidget);
      expect(
        find.textContaining('Your payment is past due'),
        findsOneWidget,
      );
    });

    testWidgets('shows pending message for incomplete status', (tester) async {
      await tester.pumpWidget(
        buildApp(const BillingState(
          subscriptionStatus: 'incomplete',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Activation'), findsOneWidget);
      expect(
        find.textContaining('is being set up'),
        findsOneWidget,
      );
    });
  });
}
