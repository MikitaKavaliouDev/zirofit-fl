import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart' show Cookie;
import 'package:dio/dio.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/cookie_storage.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

/// Dio interceptor that attaches a Bearer token from secure storage to every
/// request (except public endpoints) and transparently handles 401 responses
/// by attempting a token refresh.
///
/// In **trainer mode** the interceptor suppresses the Bearer token and instead
/// relies on [CookieManager] (from `dio_cookie_manager`) to attach cookies.
/// In **client mode** the existing Bearer-token logic is unchanged.
///
/// JWT expiry pre-check: before any request is dispatched the interceptor
/// decodes the stored access token, checks its `exp` claim, and automatically
/// refreshes the token if it will expire within 60 seconds.
///
/// If the refresh succeeds the original request is retried automatically. If
/// the refresh fails (e.g. the refresh token is expired) the [onUnauthorized]
/// callback is invoked with the failing mode so the app can surgically clear
/// only that mode's tokens.
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final void Function(String mode)? onUnauthorized;
  final CookieStorage? _cookieStorage;

  /// Buffer in seconds before JWT expiry to consider the token "expired"
  /// and trigger a pre-emptive refresh.
  static const int _jwtBufferSeconds = 60;

  /// Dio instance used for token-refresh calls and retries. Injected after
  /// construction to avoid circular dependencies.
  Dio? _dio;

  /// Whether a token-refresh is already in progress.
  bool _isRefreshing = false;

  /// Requests that arrived while a refresh was in flight.
  final _pendingRequests = <_QueuedRequest>[];

  /// When `true` the interceptor skips Bearer-token attachment (cookies are
  /// assumed to be managed by [CookieManager]).
  bool _isTrainerMode = false;

  AuthInterceptor({
    required SecureStorage secureStorage,
    this.onUnauthorized,
    Dio? dio,
    CookieStorage? cookieStorage,
  })  : _secureStorage = secureStorage,
        _dio = dio,
        _cookieStorage = cookieStorage;

  /// Call right after the main [Dio] instance has been created so the
  /// interceptor can use it for refresh / retry calls.
  void attachDio(Dio dio) => _dio = dio;

  /// Switches between cookie-based (trainer) and token-based (client) auth.
  void setMode(bool isTrainer) {
    _isTrainerMode = isTrainer;
  }

  // ---------------------------------------------------------------------------
  // JWT helpers
  // ---------------------------------------------------------------------------

  /// Decodes the payload segment of a JWT (base64-encoded JSON) and returns
  /// it as a [Map]. Returns an empty map on failure.
  static Map<String, dynamic> decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      // Base64-decode the payload (second segment).
      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(
        normalized.length + ((4 - normalized.length % 4) % 4),
        '=',
      );
      final decoded = utf8.decode(base64.decode(padded));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Returns `true` if the stored access token is expired or will expire
  /// within [_jwtBufferSeconds].
  Future<bool> isAccessTokenExpired() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return true;
    return _isTokenExpired(token, bufferSeconds: _jwtBufferSeconds);
  }

  /// Returns `true` if [token]'s `exp` claim is past (or within
  /// [bufferSeconds] of) the current time.
  static bool _isTokenExpired(String token, {int bufferSeconds = 0}) {
    final payload = decodeJwtPayload(token);
    final exp = payload['exp'];
    if (exp is! int) return false; // Can't determine — assume valid.
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return now >= (exp - bufferSeconds);
  }

  // ---------------------------------------------------------------------------
  // onRequest (with JWT expiry pre-check)
  // ---------------------------------------------------------------------------

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    if (_isTrainerMode) {
      // Trainer mode: cookies are managed by CookieManager. Do NOT attach a
      // Bearer token — the backend authenticates via session cookie instead.
      // JWT expiry pre-check is not applicable for cookie-based auth.
      handler.next(options);
      return;
    }

    // Client mode: pre-check JWT expiry and auto-refresh if needed.
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        if (_isTokenExpired(token)) {
          // Token is expired or about to expire — attempt a refresh before
          // proceeding with the original request.
          final refreshed = await _tryPreemptiveRefresh();
          if (refreshed) {
            // Attach the new token.
            final newToken = await _secureStorage.getAccessToken();
            if (newToken != null && newToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $newToken';
            }
            handler.next(options);
            return;
          }
          // Refresh failed — continue without token (the backend will return
          // 401 and the onError handler will deal with it).
        } else {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {
      // Storage unavailable — continue without token.
    }

    handler.next(options);
  }

  /// Tries to refresh the access token before it expires. Returns `true` on
  /// success. Does NOT call [onUnauthorized] on failure — the 401 handler in
  /// [onError] takes care of that.
  Future<bool> _tryPreemptiveRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty || _dio == null) {
      return false;
    }

    try {
      final response = await _dio!.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_Keys.noAuthRetry: true}),
      );

      final newToken = response.data?['accessToken'] as String?;
      if (newToken == null || newToken.isEmpty) return false;

      // Persist the new access token (keep the same refresh token).
      await _secureStorage.saveTokens(
        accessToken: newToken,
        refreshToken: refreshToken,
      );

      // Also persist under the current role key for account switching.
      final role = _isTrainerMode ? 'trainer' : 'client';
      await _secureStorage.saveRoleTokens(
        role,
        accessToken: newToken,
        refreshToken: refreshToken,
      );

      return true;
    } catch (_) {
      return false;
    }
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
      // Refresh itself failed – fail all queued requests and notify.
      final queued = List<_QueuedRequest>.from(_pendingRequests);
      _pendingRequests.clear();
      for (final q in queued) {
        q.completer.complete(false);
      }

      // Determine which mode's session expired.
      final failingMode = _isTrainerMode ? 'trainer' : 'client';
      onUnauthorized?.call(failingMode);

      await _clearStorage();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Retry the original [err] request with the (presumably fresh) token.
  Future<void> _retryOriginal(
      DioException err, ErrorInterceptorHandler handler) async {
    if (_dio == null) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;
    opts.extra[_Keys.noAuthRetry] = true;

    // Attach the latest token (only for client mode — trainer mode relies on
    // cookies that are already managed by CookieManager on the Dio instance).
    if (!_isTrainerMode) {
      try {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
    }

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
  ///
  /// In trainer mode any `Set-Cookie` headers in the response are also
  /// persisted to [CookieStorage] as a safety net (the [CookieManager]
  /// interceptor on the same Dio instance should already capture them, but we
  /// do it explicitly here to guarantee cookie freshness).
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

    // Also persist under the current role key for account switching.
    final role = _isTrainerMode ? 'trainer' : 'client';
    await _secureStorage.saveRoleTokens(
      role,
      accessToken: newToken,
      refreshToken: refreshToken,
    );

    // Trainer mode: persist cookies returned by the refresh endpoint.
    if (_isTrainerMode && _cookieStorage != null) {
      await _saveCookiesFromResponse(response);
    }
  }

  /// Extracts `Set-Cookie` headers from [response] and stores them in the
  /// active cookie jar.
  Future<void> _saveCookiesFromResponse(Response<dynamic> response) async {
    final setCookieValues = response.headers.map['set-cookie'];
    if (setCookieValues == null || setCookieValues.isEmpty) return;

    final cookies = <Cookie>[];
    for (final value in setCookieValues) {
      try {
        cookies.add(Cookie.fromSetCookieValue(value));
      } catch (_) {
        // Malformed cookie value — skip.
      }
    }

    if (cookies.isNotEmpty) {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refresh}');
      await _cookieStorage!.saveFromResponse(uri, cookies);
    }
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
        path == ApiConstants.signout ||
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
