import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/auth_interceptor.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

// ---------------------------------------------------------------------------
// Custom handler subclasses
// ---------------------------------------------------------------------------

class TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  bool rejectCalled = false;
  RequestOptions? nextOptions;
  dynamic resolveData;
  dynamic rejectError;

  @override
  void next(RequestOptions options) {
    nextCalled = true;
    nextOptions = options;
  }

  @override
  void resolve(Response response, [bool? triggerError]) {
    resolveCalled = true;
    resolveData = response.data;
  }

  @override
  void reject(DioException error, [bool? triggerError]) {
    rejectCalled = true;
    rejectError = error;
  }
}

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

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSecureStorage extends Mock implements SecureStorage {}

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DioException _dioException({
  required int statusCode,
  required String path,
  Map<String, dynamic>? extra,
}) {
  final opts = RequestOptions(path: path, extra: extra ?? {});
  return DioException(
    requestOptions: opts,
    response: Response(requestOptions: opts, statusCode: statusCode),
    type: DioExceptionType.badResponse,
  );
}

/// All paths that [AuthInterceptor] treats as public.
const _publicPaths = [
  ApiConstants.login,
  ApiConstants.register,
  ApiConstants.refresh,
  ApiConstants.forgotPassword,
  '/auth/mobile-signin',
  '/system/config',
  '/explore/featured',
  '/explore/popular',
  '/blog/latest',
  '/blog/hello-world',
  '/public/avatar.png',
  '/events',
  '/events/upcoming',
  '/contact',
  '/openapi',
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSecureStorage mockSecureStorage;
  late MockDio mockDio;
  late void Function(String) onUnauthorized;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockDio = MockDio();
    onUnauthorized = (mode) {};
  });

  group('AuthInterceptor', () {
    // ===================================================================
    // onRequest – token injection
    // ===================================================================

    group('onRequest', () {
      test('all public endpoints skip Authorization header', () async {
        for (final path in _publicPaths) {
          final interceptor = AuthInterceptor(
            secureStorage: mockSecureStorage,
          );
          final handler = TestRequestHandler();
          final opts = RequestOptions(path: path);

          interceptor.onRequest(opts, handler);

          expect(handler.nextCalled, isTrue,
              reason: 'expected handler.next() for $path');
          expect(handler.nextOptions, same(opts),
              reason: 'expected same options for $path');
          expect(
            handler.nextOptions?.headers.containsKey('Authorization'),
            isFalse,
            reason: 'expected no Authorization header for public path $path',
          );
        }
      });

      test('non-public endpoint attaches Bearer token when token exists',
          () async {
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'my-test-token');

        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final handler = TestRequestHandler();
        final opts = RequestOptions(path: '/some/protected/route');

        interceptor.onRequest(opts, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(
          handler.nextOptions?.headers['Authorization'],
          equals('Bearer my-test-token'),
        );
      });

      test('non-public endpoint skips auth header when token is null',
          () async {
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => null);

        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final handler = TestRequestHandler();
        final opts = RequestOptions(path: '/some/protected/route');

        interceptor.onRequest(opts, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(
          handler.nextOptions?.headers.containsKey('Authorization'),
          isFalse,
        );
      });

      test('non-public endpoint skips auth header when token is empty',
          () async {
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => '');

        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final handler = TestRequestHandler();
        final opts = RequestOptions(path: '/some/protected/route');

        interceptor.onRequest(opts, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(
          handler.nextOptions?.headers.containsKey('Authorization'),
          isFalse,
        );
      });

      test('storage exception does not crash and calls handler.next',
          () async {
        when(() => mockSecureStorage.getAccessToken())
            .thenThrow(Exception('Storage unavailable'));

        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final handler = TestRequestHandler();
        final opts = RequestOptions(path: '/some/protected/route');

        interceptor.onRequest(opts, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(
          handler.nextOptions?.headers.containsKey('Authorization'),
          isFalse,
        );
      });
    });

    // ===================================================================
    // onError – passthrough conditions
    // ===================================================================

    group('onError – passthrough', () {
      test('non-401 status code (404) passes through to handler.next',
          () {
        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final err = _dioException(statusCode: 404, path: '/some/route');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError, same(err));
      });

      test('request with _noAuthRetry flag passes through to handler.next',
          () {
        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final err = _dioException(
          statusCode: 401,
          path: '/some/route',
          extra: {'_noAuthRetry': true},
        );
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError, same(err));
      });

      test('401 on public endpoint passes through to handler.next', () {
        final interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
        final err = _dioException(
          statusCode: 401,
          path: ApiConstants.login,
        );
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.nextError, same(err));
      });
    });

    // ===================================================================
    // onError – refresh flow
    // ===================================================================

    group('onError – refresh flow', () {
      test('successful refresh retries original request and resolves handler',
          () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'new-access-token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiConstants.refresh),
              statusCode: 200,
              data: {'accessToken': 'new-access-token'},
            ));
        when(() => mockDio.fetch(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/original/path'),
              statusCode: 200,
              data: {'result': 'ok'},
            ));

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(handler.resolveCalled, isTrue);
        expect(handler.resolvedResponse?.data, equals({'result': 'ok'}));
        expect(handler.nextCalled, isFalse);
      });

      test('refresh retry uses updated Authorization header', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'brand-new-token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiConstants.refresh),
              statusCode: 200,
              data: {'accessToken': 'brand-new-token'},
            ));

        RequestOptions? capturedOpts;
        when(() => mockDio.fetch(any())).thenAnswer((invocation) async {
          capturedOpts = invocation.positionalArguments[0] as RequestOptions;
          return Response(
            requestOptions: capturedOpts!,
            statusCode: 200,
          );
        });

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(capturedOpts, isNotNull);
        expect(
          capturedOpts!.headers['Authorization'],
          equals('Bearer brand-new-token'),
        );
        expect(capturedOpts!.extra['_noAuthRetry'], isTrue);
      });

      test('refresh fails without refresh token triggers logout', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => null);
        when(() => mockSecureStorage.clearTokens())
            .thenAnswer((_) async {});

        var logoutCalled = false;
        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
          onUnauthorized: (mode) => logoutCalled = true,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(logoutCalled, isTrue);
        verify(() => mockSecureStorage.clearTokens()).called(1);
      });

      test('refresh fails with DioException triggers logout', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.clearTokens())
            .thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.refresh),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        var logoutCalled = false;
        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
          onUnauthorized: (mode) => logoutCalled = true,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(logoutCalled, isTrue);
        verify(() => mockSecureStorage.clearTokens()).called(1);
      });

      test('refresh response missing accessToken triggers logout', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.clearTokens())
            .thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiConstants.refresh),
              statusCode: 200,
              data: <String, dynamic>{}, // no accessToken key
            ));

        var logoutCalled = false;
        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
          onUnauthorized: (mode) => logoutCalled = true,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(logoutCalled, isTrue);
        verify(() => mockSecureStorage.clearTokens()).called(1);
      });

      test('null _dio degrades gracefully (calls handler.next)', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.clearTokens())
            .thenAnswer((_) async {});

        var logoutCalled = false;
        // Intentionally no dio (null) passed.
        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          onUnauthorized: (mode) => logoutCalled = true,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        expect(handler.nextCalled, isTrue);
        expect(logoutCalled, isTrue);
      });

      test('retry fetch failure calls handler.next with original error',
          () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'new-token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiConstants.refresh),
              statusCode: 200,
              data: {'accessToken': 'new-token'},
            ));
        // Simulate a fetch failure on retry.
        when(() => mockDio.fetch(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/original/path'),
            type: DioExceptionType.connectionError,
          ),
        );

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );
        final err = _dioException(statusCode: 401, path: '/original/path');
        final handler = TestErrorHandler();

        interceptor.onError(err, handler);
        await Future.delayed(Duration.zero);

        // Retry fetch threw → handler.next(err) with the *original* error.
        expect(handler.nextCalled, isTrue);
        expect(handler.nextError, same(err));
      });
    });

    // ===================================================================
    // onError – concurrent request queuing
    // ===================================================================

    group('onError – concurrent request queuing', () {
      test('second concurrent 401 gets queued while refresh in progress',
          () async {
        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) => refreshCompleter.future);
        when(() => mockDio.fetch(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/path'),
              statusCode: 200,
            ));

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );

        final err1 = _dioException(statusCode: 401, path: '/resource/1');
        final handler1 = TestErrorHandler();
        final err2 = _dioException(statusCode: 401, path: '/resource/2');
        final handler2 = TestErrorHandler();

        // Fire first 401 — this hits await _refreshToken() and suspends.
        interceptor.onError(err1, handler1);
        await Future.delayed(Duration.zero);

        // Second 401 should now be queued since _isRefreshing is true.
        interceptor.onError(err2, handler2);
        await Future.delayed(Duration.zero);

        // Neither should be resolved until the refresh completes.
        expect(handler1.resolveCalled, isFalse);
        expect(handler1.nextCalled, isFalse);
        expect(handler2.resolveCalled, isFalse);
        expect(handler2.nextCalled, isFalse);

        // Complete the refresh.
        refreshCompleter.complete(Response(
          requestOptions: RequestOptions(path: ApiConstants.refresh),
          statusCode: 200,
          data: {'accessToken': 'new-token'},
        ));

        // Let all pending microtasks drain.
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // Both should now be resolved.
        expect(handler1.resolveCalled, isTrue);
        expect(handler2.resolveCalled, isTrue);
      });

      test(
          'successful refresh resolves original and all queued requests',
          () async {
        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'new-token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) => refreshCompleter.future);
        when(() => mockDio.fetch(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/path'),
              statusCode: 200,
              data: {'retried': true},
            ));

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );

        final err1 = _dioException(statusCode: 401, path: '/resource/1');
        final handler1 = TestErrorHandler();
        final err2 = _dioException(statusCode: 401, path: '/resource/2');
        final handler2 = TestErrorHandler();
        final err3 = _dioException(statusCode: 401, path: '/resource/3');
        final handler3 = TestErrorHandler();

        // Fire all three — first triggers refresh, others queue.
        interceptor.onError(err1, handler1);
        await Future.delayed(Duration.zero);
        interceptor.onError(err2, handler2);
        interceptor.onError(err3, handler3);
        await Future.delayed(Duration.zero);

        // None resolved yet.
        expect(handler1.resolveCalled, isFalse);
        expect(handler2.resolveCalled, isFalse);
        expect(handler3.resolveCalled, isFalse);

        // Let refresh succeed.
        refreshCompleter.complete(Response(
          requestOptions: RequestOptions(path: ApiConstants.refresh),
          statusCode: 200,
          data: {'accessToken': 'new-token'},
        ));

        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // All three retried and resolved.
        expect(handler1.resolveCalled, isTrue);
        expect(handler2.resolveCalled, isTrue);
        expect(handler3.resolveCalled, isTrue);
      });

      test('failed refresh rejects all queued requests and calls logout',
          () async {
        final refreshCompleter = Completer<Response<Map<String, dynamic>>>();

        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'token');
        when(() => mockSecureStorage.clearTokens())
            .thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) => refreshCompleter.future);
        when(() => mockDio.fetch(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/path'),
              statusCode: 200,
            ));

        var logoutCalled = false;
        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
          onUnauthorized: (mode) => logoutCalled = true,
        );

        final err1 = _dioException(statusCode: 401, path: '/resource/1');
        final handler1 = TestErrorHandler();
        final err2 = _dioException(statusCode: 401, path: '/resource/2');
        final handler2 = TestErrorHandler();

        // Fire both.
        interceptor.onError(err1, handler1);
        await Future.delayed(Duration.zero);
        interceptor.onError(err2, handler2);
        await Future.delayed(Duration.zero);

        // Fail the refresh.
        refreshCompleter.completeError(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.refresh),
            type: DioExceptionType.badResponse,
          ),
        );

        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // First handler gets next(err).
        expect(handler1.nextCalled, isTrue);
        expect(handler1.nextError, same(err1));

        // Second handler (queued) also gets next(err).
        expect(handler2.nextCalled, isTrue);

        // Logout called.
        expect(logoutCalled, isTrue);
        verify(() => mockSecureStorage.clearTokens()).called(1);
      });

      test('after refresh completes, new 401 triggers a new refresh', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'refresh-token');
        when(() => mockSecureStorage.getAccessToken())
            .thenAnswer((_) async => 'token');
        when(() => mockSecureStorage.saveTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ApiConstants.refresh),
              statusCode: 200,
              data: {'accessToken': 'token-2'},
            ));
        when(() => mockDio.fetch(any())).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/path'),
              statusCode: 200,
            ));

        final interceptor = AuthInterceptor(
          secureStorage: mockSecureStorage,
          dio: mockDio,
        );

        // First 401 — triggers refresh, completes successfully.
        final err1 = _dioException(statusCode: 401, path: '/resource/1');
        final handler1 = TestErrorHandler();
        interceptor.onError(err1, handler1);
        await Future.delayed(Duration.zero);
        expect(handler1.resolveCalled, isTrue);

        // Second 401 — should trigger a NEW refresh (not queued).
        final err2 = _dioException(statusCode: 401, path: '/resource/2');
        final handler2 = TestErrorHandler();
        interceptor.onError(err2, handler2);
        await Future.delayed(Duration.zero);

        // Both should have been retried separately (second triggered a new refresh).
        expect(handler2.resolveCalled, isTrue);
        // Verify refresh was called twice.
        verify(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).called(2);
      });
    });
  });
}
