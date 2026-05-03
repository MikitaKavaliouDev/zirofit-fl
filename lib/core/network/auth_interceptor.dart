import 'dart:async';

import 'package:dio/dio.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

/// Dio interceptor that attaches a Bearer token from secure storage to every
/// request (except public endpoints) and transparently handles 401 responses
/// by attempting a token refresh.
///
/// If the refresh succeeds the original request is retried automatically. If
/// the refresh fails (e.g. the refresh token is expired) the [onLogout]
/// callback is invoked so the app can navigate to the login screen.
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final void Function()? onLogout;

  /// Dio instance used for token-refresh calls and retries. Injected after
  /// construction to avoid circular dependencies.
  Dio? _dio;

  /// Whether a token-refresh is already in progress.
  bool _isRefreshing = false;

  /// Requests that arrived while a refresh was in flight.
  final _pendingRequests = <_QueuedRequest>[];

  AuthInterceptor({
    required SecureStorage secureStorage,
    this.onLogout,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  /// Call right after the main [Dio] instance has been created so the
  /// interceptor can use it for refresh / retry calls.
  void attachDio(Dio dio) => _dio = dio;

  // ---------------------------------------------------------------------------
  // onRequest
  // ---------------------------------------------------------------------------

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Storage unavailable — continue without token.
    }

    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // onError
  // ---------------------------------------------------------------------------

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only intercept 401 responses.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Prevent infinite loops: if this request was already retried by us, bail.
    if (err.requestOptions.extra[_Keys.noAuthRetry] == true) {
      handler.next(err);
      return;
    }

    // Public endpoints should never return 401; if they do, pass through.
    if (_isPublicEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    // ------------------------------------------------------------------
    // A refresh is already in flight – queue this request and wait.
    // ------------------------------------------------------------------
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _pendingRequests.add(_QueuedRequest(
        error: err,
        handler: handler,
        completer: completer,
      ));
      final success = await completer.future;
      if (success) {
        await _retryOriginal(err, handler);
      } else {
        handler.next(err);
      }
      return;
    }

    // ------------------------------------------------------------------
    // First 401 – attempt a token refresh, then retry everything.
    // ------------------------------------------------------------------
    _isRefreshing = true;
    try {
      await _refreshToken();

      // Retry the request that triggered the refresh.
      await _retryOriginal(err, handler);

      // Resolve all queued requests so they retry as well.
      final queued = List<_QueuedRequest>.from(_pendingRequests);
      _pendingRequests.clear();
      for (final q in queued) {
        q.completer.complete(true);
      }
    } catch (_) {
      // Refresh itself failed – fail all queued requests and trigger logout.
      final queued = List<_QueuedRequest>.from(_pendingRequests);
      _pendingRequests.clear();
      for (final q in queued) {
        q.completer.complete(false);
      }

      await _clearStorage();
      onLogout?.call();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Retry the original [err] request with the (presumably fresh) token.
  Future<void> _retryOriginal(DioException err, ErrorInterceptorHandler handler) async {
    if (_dio == null) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;
    opts.extra[_Keys.noAuthRetry] = true;

    // Attach the latest token.
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}

    try {
      final response = await _dio!.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      // Retry failed – pass the *original* error through.
      handler.next(err);
    }
  }

  /// Calls `/auth/refresh` with the stored refresh token and persists the new
  /// access token on success.
  Future<void> _refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty || _dio == null) {
      throw StateError('No refresh token available');
    }

    final response = await _dio!.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {_Keys.noAuthRetry: true}),
    );

    final newToken = response.data?['accessToken'] as String?;
    if (newToken == null || newToken.isEmpty) {
      throw StateError('Refresh response missing accessToken');
    }

    await _secureStorage.saveTokens(
      accessToken: newToken,
      refreshToken: refreshToken,
    );
  }

  /// Clears all auth tokens from secure storage.
  Future<void> _clearStorage() async {
    try {
      await _secureStorage.clearTokens();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Checks whether [path] is a public endpoint that does not need a Bearer
  /// token.
  bool _isPublicEndpoint(String path) {
    return path == ApiConstants.login ||
        path == ApiConstants.register ||
        path == ApiConstants.refresh ||
        path == ApiConstants.forgotPassword ||
        path == '/auth/mobile-signin' ||
        path == '/system/config' ||
        path.startsWith('/explore/') ||
        path.startsWith('/blog/') ||
        path.startsWith('/public/') ||
        path.startsWith('/events') ||
        path == '/contact' ||
        path == '/openapi';
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Keys used with [RequestOptions.extra] to control interceptor behaviour.
class _Keys {
  _Keys._();
  static const String noAuthRetry = '_noAuthRetry';
}

/// A request that arrived while a token refresh was already in progress.
class _QueuedRequest {
  final DioException error;
  final ErrorInterceptorHandler handler;
  final Completer<bool> completer;

  _QueuedRequest({
    required this.error,
    required this.handler,
    required this.completer,
  });
}
