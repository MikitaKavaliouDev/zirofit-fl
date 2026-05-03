import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late BillingNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = BillingNotifier(apiClient: mockApiClient);
  });

  group('BillingNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has no subscription, not loading, no error', () {
      final state = notifier.state;
      expect(state.subscriptionStatus, isNull);
      expect(state.checkoutUrl, isNull);
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
            'data': {'status': 'active'},
          });

      final future = notifier.fetchSubscription();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchSubscription populates status on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'status': 'active'},
          });

      await notifier.fetchSubscription();

      final state = notifier.state;
      expect(state.subscriptionStatus, 'active');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchSubscription handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchSubscription();

      final state = notifier.state;
      expect(state.subscriptionStatus, isNull);
      expect(state.isLoading, false);
    });

    test('fetchSubscription handles past_due status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'status': 'past_due'},
          });

      await notifier.fetchSubscription();

      expect(notifier.state.subscriptionStatus, 'past_due');
    });

    test('fetchSubscription handles canceled status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'status': 'canceled'},
          });

      await notifier.fetchSubscription();

      expect(notifier.state.subscriptionStatus, 'canceled');
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
      expect(state.subscriptionStatus, isNull);
    });

    test('fetchSubscription sets error on DioException with message field',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.billingSubscription),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.billingSubscription),
          statusCode: 400,
          data: <String, dynamic>{'message': 'Bad request'},
        ),
      ));

      await notifier.fetchSubscription();

      expect(notifier.state.error, 'Bad request');
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

    test('fetchSubscription handles network error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.billingSubscription),
      ));

      await notifier.fetchSubscription();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('fetchSubscription handles non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.billingSubscription,
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchSubscription();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // createCheckoutSession
    // ---------------------------------------------------------------------------

    test('createCheckoutSession sets loading true before completion',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'url': 'https://checkout.stripe.com/test'},
          });

      final future = notifier.createCheckoutSession('pro');
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('createCheckoutSession returns URL and updates state on success',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'url': 'https://checkout.stripe.com/session_123'},
          });

      final url = await notifier.createCheckoutSession('pro');

      expect(url, 'https://checkout.stripe.com/session_123');
      expect(notifier.state.checkoutUrl,
          'https://checkout.stripe.com/session_123');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('createCheckoutSession sends correct packageId in body', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as Map<String, dynamic>;
        expect(body['packageId'], 'pro');
        return <String, dynamic>{
          'data': {'url': 'https://checkout.stripe.com/session_123'},
        };
      });

      await notifier.createCheckoutSession('pro');
    });

    test('createCheckoutSession sends enterprise packageId', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as Map<String, dynamic>;
        expect(body['packageId'], 'enterprise');
        return <String, dynamic>{
          'data': {'url': 'https://checkout.stripe.com/session_456'},
        };
      });

      await notifier.createCheckoutSession('enterprise');
    });

    test('createCheckoutSession handles null URL gracefully', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{},
          });

      final url = await notifier.createCheckoutSession('pro');

      expect(url, isNull);
      expect(notifier.state.checkoutUrl, isNull);
    });

    test('createCheckoutSession returns null and sets error on DioException',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.createCheckoutSession),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.createCheckoutSession),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Checkout creation failed'},
          },
        ),
      ));

      final url = await notifier.createCheckoutSession('pro');

      expect(url, isNull);
      expect(notifier.state.error, 'Checkout creation failed');
    });

    test('createCheckoutSession handles network error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.createCheckoutSession,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions:
            RequestOptions(path: ApiConstants.createCheckoutSession),
      ));

      final url = await notifier.createCheckoutSession('pro');

      expect(url, isNull);
      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });
  });
}
