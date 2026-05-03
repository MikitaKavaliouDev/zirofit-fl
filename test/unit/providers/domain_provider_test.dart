import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/domain_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late DomainNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = DomainNotifier(apiClient: mockApiClient);
  });

  group('DomainNotifier', () {
    // ---------------------------------------------------------------------------
    // DomainState – initial state & copyWith
    // ---------------------------------------------------------------------------

    test('initial state has default values', () {
      expect(notifier.state.domain, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isVerified, false);
      expect(notifier.state.isAdding, false);
    });

    test('copyWith clearError removes error', () {
      const state = DomainState(error: 'some error');
      final updated = state.copyWith(clearError: true);
      expect(updated.error, isNull);
      // Other fields remain unaffected
      expect(updated.domain, isNull);
      expect(updated.isLoading, false);
      expect(updated.isVerified, false);
      expect(updated.isAdding, false);
    });

    test('copyWith clearDomain clears domain', () {
      const state = DomainState(domain: 'example.com');
      final updated = state.copyWith(clearDomain: true);
      expect(updated.domain, isNull);
      // Other fields remain unaffected
      expect(updated.isLoading, false);
      expect(updated.error, isNull);
      expect(updated.isVerified, false);
      expect(updated.isAdding, false);
    });

    // ---------------------------------------------------------------------------
    // addDomain
    // ---------------------------------------------------------------------------

    test('addDomain sets isAdding to true during call', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final future = notifier.addDomain('example.com');

      // During call
      expect(notifier.state.isAdding, true);

      await future;
    });

    test('addDomain on success with nested response data sets domain, isVerified, isAdding false, returns true',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'domain': 'example.com', 'verified': true},
          });

      final result = await notifier.addDomain('example.com');

      expect(result, true);
      expect(notifier.state.domain, 'example.com');
      expect(notifier.state.isVerified, true);
      expect(notifier.state.isAdding, false);
      expect(notifier.state.error, isNull);
    });

    test('addDomain on success without nested data sets domain, isAdding false, returns true',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'message': 'Domain added',
          });

      final result = await notifier.addDomain('example.com');

      expect(result, true);
      expect(notifier.state.domain, 'example.com');
      expect(notifier.state.isAdding, false);
      expect(notifier.state.error, isNull);
    });

    test('addDomain on DioException connectionTimeout sets error, isAdding false, returns false',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await notifier.addDomain('example.com');

      expect(result, false);
      expect(notifier.state.isAdding, false);
      expect(notifier.state.error, isNotNull);
    });

    test('addDomain on generic Exception sets error, isAdding false, returns false',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenThrow(Exception('Something went wrong'));

      final result = await notifier.addDomain('example.com');

      expect(result, false);
      expect(notifier.state.isAdding, false);
      expect(notifier.state.error, isNotNull);
    });

    test('addDomain calls correct endpoint with body containing domain', () async {
      Map<String, dynamic>? capturedBody;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
        return <String, dynamic>{'data': {'domain': 'example.com', 'verified': true}};
      });

      await notifier.addDomain('example.com');

      expect(capturedBody, isNotNull);
      expect(capturedBody!['domain'], 'example.com');
      expect(notifier.state.isAdding, false);
    });

    // ---------------------------------------------------------------------------
    // verifyDomain
    // ---------------------------------------------------------------------------

    test('verifyDomain sets isLoading to true during call', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'verified': true},
          });

      final future = notifier.verifyDomain();

      // During call
      expect(notifier.state.isLoading, true);

      await future;
    });

    test('verifyDomain on success with verified=true sets isVerified, isLoading false, returns true',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'verified': true},
          });

      final result = await notifier.verifyDomain();

      expect(result, true);
      expect(notifier.state.isVerified, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('verifyDomain on success with nested data verified=false sets isVerified false, isLoading false',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'verified': false},
          });

      final result = await notifier.verifyDomain();

      expect(result, false);
      expect(notifier.state.isVerified, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('verifyDomain on success with no nested data defaults verified=true', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => <String, dynamic>{
            'message': 'success',
          });

      final result = await notifier.verifyDomain();

      // When 'data' is absent, verified defaults to true
      expect(result, true);
      expect(notifier.state.isVerified, true);
      expect(notifier.state.isLoading, false);
    });

    test('verifyDomain on DioException connectionError sets error, isLoading false, returns false',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      final result = await notifier.verifyDomain();

      expect(result, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    test('verifyDomain calls correct endpoint', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'verified': true},
          });

      await notifier.verifyDomain();

      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.domainVerify,
      )).called(1);
    });

    // ---------------------------------------------------------------------------
    // reset
    // ---------------------------------------------------------------------------

    test('reset restores initial state after state changes', () async {
      // First make some state changes
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'domain': 'example.com', 'verified': true},
          });

      await notifier.addDomain('example.com');
      expect(notifier.state.domain, 'example.com');
      expect(notifier.state.isAdding, false);
      expect(notifier.state.isVerified, true);

      notifier.reset();

      expect(notifier.state.domain, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isVerified, false);
      expect(notifier.state.isAdding, false);
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage (tested indirectly through addDomain)
    // ---------------------------------------------------------------------------

    test('addDomain extracts error.message from DioException with nested error map',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'error': {'message': 'Custom domain error'}},
        ),
      ));

      await notifier.addDomain('example.com');

      expect(notifier.state.error, contains('Custom domain error'));
      expect(notifier.state.isAdding, false);
    });
  });
}
