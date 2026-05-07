import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/subscription_provider.dart';
import 'package:zirofit_fl/features/billing/screens/trainer_subscription_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeSubscriptionNotifier extends SubscriptionNotifier {
  SubscriptionState _state;
  bool getPortalLinkCalled = false;
  String? portalLinkResult;

  FakeSubscriptionNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  SubscriptionState get state => _state;

  void emit(SubscriptionState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchSubscription() async {}

  @override
  Future<String?> getPortalLink() async {
    getPortalLinkCalled = true;
    return portalLinkResult;
  }
}

Widget buildApp(SubscriptionState state) => ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) => FakeSubscriptionNotifier(state),
        ),
      ],
      child: const MaterialApp(home: TrainerSubscriptionScreen()),
    );

/// Scrolls the ListView down so that off-screen widgets become visible.
Future<void> scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -800));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TrainerSubscription _activeSubscription({
  DateTime? nextBillingDate,
}) {
  return TrainerSubscription(
    planName: 'Trainer Pro',
    price: '29.99',
    currency: 'USD',
    interval: 'month',
    status: 'active',
    nextBillingDate:
        nextBillingDate ?? DateTime(2026, 2, 28),
    features: const [
      'Unlimited client management',
      'Advanced analytics & reporting',
      'Custom storefront & branding',
      'Stripe Connect payouts',
      'Priority support',
      'Marketplace listing',
    ],
  );
}

TrainerSubscription _canceledSubscription() {
  return const TrainerSubscription(
    planName: 'Free Plan',
    price: '0.00',
    currency: 'USD',
    interval: 'month',
    status: 'canceled',
    nextBillingDate: null,
    features: [],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerSubscriptionScreen', () {
    testWidgets('renders with subscription title', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Subscription'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Test 1: Shows current plan
    // ---------------------------------------------------------------------------
    testWidgets('shows current plan name and tier badge when active',
        (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Plan name
      expect(find.text('Trainer Pro'), findsOneWidget);
      // Price
      expect(find.text('\$29.99 / month'), findsOneWidget);
      // Tier badge (ACTIVE)
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('shows current plan info when canceled', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _canceledSubscription(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('CANCELED'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Test 2: Shows billing date
    // ---------------------------------------------------------------------------
    testWidgets('shows next billing date when active', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(
            nextBillingDate: DateTime(2026, 2, 28),
          ),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next billing date'), findsOneWidget);
      // Formatted date using the same pattern as the screen
      final formatted = DateFormat.yMMMd().format(DateTime(2026, 2, 28));
      expect(find.text(formatted), findsOneWidget);
    });

    testWidgets('does not show billing date when not active', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _canceledSubscription(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next billing date'), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // Plan features
    // ---------------------------------------------------------------------------
    testWidgets('shows plan features for active plan', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
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

    testWidgets('shows default features when no subscription data',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const SubscriptionState(
          subscription: null,
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

    // ---------------------------------------------------------------------------
    // Action buttons
    // ---------------------------------------------------------------------------
    testWidgets('shows action buttons when active', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
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

    // ---------------------------------------------------------------------------
    // Test 3: Upgrade button calls getPortalLink
    // ---------------------------------------------------------------------------
    testWidgets('upgrade button calls getPortalLink when tapped',
        (tester) async {
      final notifier = FakeSubscriptionNotifier(
        SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: false,
        ),
      );
      notifier.portalLinkResult = 'https://billing.stripe.com/portal';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: TrainerSubscriptionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Upgrade Plan button
      await tester.tap(find.text('Upgrade Plan'));
      await tester.pumpAndSettle();

      expect(notifier.getPortalLinkCalled, isTrue);
    });

    testWidgets('billing history button calls getPortalLink when tapped',
        (tester) async {
      final notifier = FakeSubscriptionNotifier(
        SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: false,
        ),
      );
      notifier.portalLinkResult = 'https://billing.stripe.com/portal';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: TrainerSubscriptionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Billing History button
      await tester.tap(find.text('Billing History'));
      await tester.pumpAndSettle();

      expect(notifier.getPortalLinkCalled, isTrue);
    });

    // ---------------------------------------------------------------------------
    // Test 4: Loading state
    // ---------------------------------------------------------------------------
    testWidgets('shows loading indicator when loading and no subscription',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const SubscriptionState(
          isLoading: true,
        )),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading when subscription already loaded',
        (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: true, // still loading but we have data
        )),
      );
      await tester.pumpAndSettle();

      // Should show content, not full-screen loader
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Trainer Pro'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Error state
    // ---------------------------------------------------------------------------
    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        buildApp(const SubscriptionState(
          error: 'Network error',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Cancel subscription confirmation
    // ---------------------------------------------------------------------------
    testWidgets('shows cancel confirmation dialog', (tester) async {
      await tester.pumpWidget(
        buildApp(SubscriptionState(
          subscription: _activeSubscription(),
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Scroll to make Cancel Subscription visible
      final cancelButton = find.text('Cancel Subscription');
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();

      // Tap Cancel Subscription
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.textContaining('Are you sure'), findsOneWidget);
      expect(find.text('Keep Subscription'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
