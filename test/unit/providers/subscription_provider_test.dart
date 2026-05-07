import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/subscription_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late SubscriptionNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = SubscriptionNotifier(apiClient: mockApiClient);
  });

  group('SubscriptionNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has no subscription, not loading, no error', () {
      final state = notifier.state;
      expect(state.subscription, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchSubscription
    // ---------------------------------------------------------------------------
    test('fetchSubscription sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'plan_name': 'Trainer Pro',
              'price': 29.99,
              'currency': 'USD',
              'interval': 'month',
              'status': 'active',
              'next_billing_date': '2026-02-28',
              'features': [
                'Unlimited client management',
                'Advanced analytics',
              ],
            },
          });

      final future = notifier.fetchSubscription();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchSubscription returns subscription data on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'plan_name': 'Trainer Pro',
              'price': 29.99,
              'currency': 'USD',
              'interval': 'month',
              'status': 'active',
              'next_billing_date': '2026-02-28',
              'features': [
                'Unlimited client management',
                'Advanced analytics & reporting',
                'Custom storefront & branding',
              ],
            },
          });

      await notifier.fetchSubscription();

      final state = notifier.state;
      expect(state.subscription, isNotNull);
      expect(state.subscription!.planName, 'Trainer Pro');
      expect(state.subscription!.price, '29.99');
      expect(state.subscription!.currency, 'USD');
      expect(state.subscription!.interval, 'month');
      expect(state.subscription!.status, 'active');
      expect(state.subscription!.nextBillingDate, isNotNull);
      expect(state.subscription!.nextBillingDate!.year, 2026);
      expect(state.subscription!.nextBillingDate!.month, 2);
      expect(state.subscription!.nextBillingDate!.day, 28);
      expect(state.subscription!.features.length, 3);
      expect(state.subscription!.features[0], 'Unlimited client management');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchSubscription handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchSubscription();

      final state = notifier.state;
      expect(state.subscription, isNotNull);
      expect(state.subscription!.planName, 'Free Plan');
      expect(state.subscription!.status, 'inactive');
      expect(state.subscription!.nextBillingDate, isNull);
      expect(state.isLoading, false);
    });

    test('fetchSubscription handles past_due status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'plan_name': 'Trainer Pro',
              'price': 29.99,
              'status': 'past_due',
            },
          });

      await notifier.fetchSubscription();

      expect(notifier.state.subscription!.status, 'past_due');
      expect(notifier.state.subscription!.planName, 'Trainer Pro');
    });

    test('fetchSubscription handles canceled status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'plan_name': 'Free Plan',
              'price': 0,
              'status': 'canceled',
            },
          });

      await notifier.fetchSubscription();

      expect(notifier.state.subscription!.status, 'canceled');
      expect(notifier.state.subscription!.planName, 'Free Plan');
    });

    test('fetchSubscription sets error on DioException with error message',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.billingSubscription),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.billingSubscription),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Internal server error'},
          },
        ),
      ));

      await notifier.fetchSubscription();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Internal server error');
      expect(state.subscription, isNull);
    });

    test('fetchSubscription handles connection timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions:
            RequestOptions(path: ApiConstants.billingSubscription),
      ));

      await notifier.fetchSubscription();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    // ---------------------------------------------------------------------------
    // getPortalLink
    // ---------------------------------------------------------------------------
    test('getPortalLink sets loading true before completion', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.billingPortal,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'url': 'https://billing.stripe.com/test'},
          });

      final future = notifier.getPortalLink();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('getPortalLink returns URL on success', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.billingPortal,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'url': 'https://billing.stripe.com/portal_abc123'},
          });

      final url = await notifier.getPortalLink();

      expect(url, 'https://billing.stripe.com/portal_abc123');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('getPortalLink returns null when no URL in response', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.billingPortal,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{},
          });

      final url = await notifier.getPortalLink();

      expect(url, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('getPortalLink returns null and sets error on DioException',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.billingPortal,
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.billingPortal),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.billingPortal),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Portal creation failed'},
          },
        ),
      ));

      final url = await notifier.getPortalLink();

      expect(url, isNull);
      expect(notifier.state.error, 'Portal creation failed');
    });

    test('getPortalLink handles network error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.billingPortal,
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.billingPortal),
      ));

      final url = await notifier.getPortalLink();

      expect(url, isNull);
      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });
  });
}
