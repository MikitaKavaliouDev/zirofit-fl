import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _subscriptionJson({
  String status = 'active',
  String plan = 'premium',
}) => {
      'status': status,
      'plan': plan,
      'current_period_start': 1700000000000,
      'current_period_end': 1702592000000,
    };

Map<String, dynamic> _checkoutJson({String url = 'https://checkout.stripe.com/session_123'}) => {
      'url': url,
    };

Map<String, dynamic> _portalJson({String url = 'https://billing.stripe.com/portal_abc'}) => {
      'url': url,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      billingProvider.overrideWith(
        (ref) => BillingNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('BillingNotifier', () {
    test('initial state has null subscription, not loading, no error', () {
      final state = container.read(billingProvider);
      expect(state.subscriptionStatus, isNull);
      expect(state.checkoutUrl, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchSubscription populates the subscription status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _subscriptionJson(status: 'active', plan: 'premium'),
          });

      await container.read(billingProvider.notifier).fetchSubscription();

      final state = container.read(billingProvider);
      expect(state.subscriptionStatus, 'active');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchSubscription handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      await container.read(billingProvider.notifier).fetchSubscription();

      final state = container.read(billingProvider);
      expect(state.subscriptionStatus, isNull);
      expect(state.isLoading, isFalse);
    });

    test('fetchSubscription handles missing status in data', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{'plan': 'basic'},
          });

      await container.read(billingProvider.notifier).fetchSubscription();

      final state = container.read(billingProvider);
      expect(state.subscriptionStatus, isNull);
      expect(state.isLoading, isFalse);
    });

    test('fetchSubscription sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(Exception('API error'));

      await container.read(billingProvider.notifier).fetchSubscription();

      final state = container.read(billingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('createCheckoutSession returns the checkout URL', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkoutJson(),
          });

      final url = await container
          .read(billingProvider.notifier)
          .createCheckoutSession('package_premium');

      expect(url, 'https://checkout.stripe.com/session_123');

      final state = container.read(billingProvider);
      expect(state.checkoutUrl, 'https://checkout.stripe.com/session_123');
      expect(state.isLoading, isFalse);
    });

    test('createCheckoutSession handles null data gracefully', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      final url = await container
          .read(billingProvider.notifier)
          .createCheckoutSession('package_basic');

      expect(url, isNull);

      final state = container.read(billingProvider);
      expect(state.checkoutUrl, isNull);
      expect(state.isLoading, isFalse);
    });

    test('createCheckoutSession sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenThrow(Exception('Checkout failed'));

      final url = await container
          .read(billingProvider.notifier)
          .createCheckoutSession('package_premium');

      expect(url, isNull);

      final state = container.read(billingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
