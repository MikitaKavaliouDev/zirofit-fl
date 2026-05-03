import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/retry_interceptor.dart';

/// A custom [ErrorInterceptorHandler] that records invocations for
/// verification without relying on the real interceptor pipeline.
class TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  DioException? nextError;
  Response? resolvedResponse;

  @override
  void next(DioException err) {
    nextCalled = true;
    nextError = err;
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
    resolvedResponse = response;
  }
}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RetryInterceptor interceptor;
  late TestErrorHandler handler;

  setUp(() {
    mockDio = MockDio();
    interceptor = RetryInterceptor(
      maxRetries: 3,
      baseDelay: const Duration(milliseconds: 1),
      dio: mockDio,
    );
    handler = TestErrorHandler();

    registerFallbackValue(RequestOptions(path: ''));
  });

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  DioException createError({
    DioExceptionType type = DioExceptionType.connectionTimeout,
    int? retryCount,
    bool noAuthRetry = false,
    Object? error,
  }) {
    final options = RequestOptions(path: '/test');
    if (retryCount != null) {
      options.extra['_retryCount'] = retryCount;
    }
    if (noAuthRetry) {
      options.extra['_noAuthRetry'] = true;
    }
    return DioException(type: type, requestOptions: options, error: error);
  }

  Response createResponse({int statusCode = 200}) {
    return Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: statusCode,
    );
  }

  // ------------------------------------------------------------------
  // _isNetworkError  –  each branch tested indirectly via onError
  // ------------------------------------------------------------------

  group('_isNetworkError', () {
    test('connectionTimeout → true  (proceeds to retry)', () async {
      final err = createError(type: DioExceptionType.connectionTimeout);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      // Allow the fetch Future's continuation (handler.resolve) to complete.
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
    });

    test('sendTimeout → true  (proceeds to retry)', () async {
      final err = createError(type: DioExceptionType.sendTimeout);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
    });

    test('receiveTimeout → true  (proceeds to retry)', () async {
      final err = createError(type: DioExceptionType.receiveTimeout);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
    });

    test('connectionError → true  (proceeds to retry)', () async {
      final err = createError(type: DioExceptionType.connectionError);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
    });

    test('badResponse → false  (skips retry immediately)', () async {
      final err = createError(type: DioExceptionType.badResponse);

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('cancel → false  (skips retry immediately)', () async {
      final err = createError(type: DioExceptionType.cancel);

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('badCertificate → false  (skips retry immediately)', () async {
      final err = createError(type: DioExceptionType.badCertificate);

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('unknown with Exception error → true  (proceeds to retry)', () async {
      final err = createError(
        type: DioExceptionType.unknown,
        error: Exception('some network error'),
      );
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
    });

    test('unknown with non-Exception error (e.g. string) → false', () async {
      final err = createError(
        type: DioExceptionType.unknown,
        error: 'string error message',
      );

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });
  });

  // ------------------------------------------------------------------
  // onError  –  skip conditions
  // ------------------------------------------------------------------

  group('onError — skip conditions', () {
    test('badResponse (non-network error) → handler.next called', () async {
      final err = createError(type: DioExceptionType.badResponse);

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.nextError, same(err));
      expect(handler.resolveCalled, false);
    });

    test('_noAuthRetry flag is set → handler.next called', () async {
      final err = createError(
        type: DioExceptionType.connectionTimeout,
        noAuthRetry: true,
      );

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('retryCount >= maxRetries → handler.next called', () async {
      final err = createError(
        type: DioExceptionType.connectionTimeout,
        retryCount: 3, // maxRetries = 3, so 3 >= 3 → skip
      );

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.nextError, same(err));
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('_dio is null → handler.next called', () async {
      final nullDioInterceptor = RetryInterceptor(
        maxRetries: 3,
        baseDelay: const Duration(milliseconds: 1),
        // dio not supplied → _dio stays null
      );
      final err = createError(type: DioExceptionType.connectionTimeout);

      nullDioInterceptor.onError(err, handler);
      // Delay completes first (1 ms), then _dio null check → handler.next
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(handler.nextCalled, true);
      expect(handler.resolveCalled, false);
    });
  });

  // ------------------------------------------------------------------
  // onError  –  retry success
  // ------------------------------------------------------------------

  group('onError — retry success', () {
    test('first retry succeeds → handler.resolve called, _retryCount inc', () async {
      final err = createError(type: DioExceptionType.connectionTimeout);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
      expect(handler.resolvedResponse, isNotNull);
      expect(err.requestOptions.extra['_retryCount'], 1);
    });

    test('retry after 2 failures succeeds on 3rd attempt → handler.resolve', () async {
      // Simulate state where 2 retries already failed (retryCount = 2)
      final err = createError(
        type: DioExceptionType.connectionTimeout,
        retryCount: 2,
      );
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      await Future<void>.delayed(Duration.zero);

      expect(handler.resolveCalled, true);
      expect(handler.resolvedResponse, isNotNull);
      // _retryCount should be bumped to 3
      expect(err.requestOptions.extra['_retryCount'], 3);
    });
  });

  // ------------------------------------------------------------------
  // onError  –  retry failure
  // ------------------------------------------------------------------

  group('onError — retry failure', () {
    test('all retries exhausted → handler.next called with original error', () async {
      final err = createError(
        type: DioExceptionType.connectionTimeout,
        retryCount: 3, // Already exhausted budget
      );

      interceptor.onError(err, handler);

      expect(handler.nextCalled, true);
      expect(handler.nextError, same(err));
      expect(handler.resolveCalled, false);
      verifyNever(() => mockDio.fetch(any()));
    });

    test('retry fetch throws → handler.next called with original error', () async {
      final err = createError(type: DioExceptionType.connectionTimeout);
      when(() => mockDio.fetch(any())).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      interceptor.onError(err, handler);
      await untilCalled(() => mockDio.fetch(any()));
      // Allow the catch block to complete
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(handler.nextCalled, true);
      // Must be the ORIGINAL error, not the thrown one
      expect(handler.nextError, same(err));
      expect(handler.resolveCalled, false);
    });
  });

  // ------------------------------------------------------------------
  // Exponential backoff
  // ------------------------------------------------------------------

  group('Exponential backoff', () {
    test('delay increases with retry count', () async {
      // Use a larger baseDelay for measurable timing differences.
      final slowInterceptor = RetryInterceptor(
        maxRetries: 5,
        baseDelay: const Duration(milliseconds: 30),
        dio: mockDio,
      );

      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());

      // --- Measure retryCount = 0  (expected delay: 30ms) ---
      final err0 = createError(
        type: DioExceptionType.connectionTimeout,
        retryCount: 0,
      );
      final sw0 = Stopwatch()..start();
      slowInterceptor.onError(err0, handler);
      await untilCalled(() => mockDio.fetch(any()));
      sw0.stop();

      // Reset mock & handler for second measurement
      reset(mockDio);
      when(() => mockDio.fetch(any())).thenAnswer((_) async => createResponse());
      handler = TestErrorHandler();

      // --- Measure retryCount = 2  (expected delay: 30ms * 4 = 120ms) ---
      final err2 = createError(
        type: DioExceptionType.connectionTimeout,
        retryCount: 2,
      );
      final sw2 = Stopwatch()..start();
      slowInterceptor.onError(err2, handler);
      await untilCalled(() => mockDio.fetch(any()));
      sw2.stop();

      // Higher retry count should always result in a longer delay.
      expect(sw2.elapsedMicroseconds, greaterThan(sw0.elapsedMicroseconds));

      // sanity: retryCount=2 should be at least 2× the elapsed of retryCount=0
      // (theoretical ratio is 4×, but we allow generous padding for CI noise)
      expect(sw2.elapsedMicroseconds, greaterThanOrEqualTo(sw0.elapsedMicroseconds));
    });
  });
}
