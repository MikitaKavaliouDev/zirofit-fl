import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/core/network/auth_interceptor.dart';
import 'package:zirofit_fl/core/network/cookie_storage.dart';
import 'package:zirofit_fl/core/network/retry_interceptor.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

/// Singleton Dio-based HTTP client for the Ziro Fit API.
///
/// Usage:
/// ```dart
/// // Bootstrap (once at app startup)
/// ApiClient.configure(
///   secureStorage: SecureStorage(),
///   onUnauthorized: (mode) => GoRouter.of(context).go('/login'),
/// );
///
/// // Anywhere else
/// final client = ApiClient.instance;
/// final response = await client.get<ApiResponse<User>>(
///   ApiConstants.me,
///   fromJson: (json) => ApiResponse.fromJson(json, User.fromJson),
/// );
/// ```
class ApiClient {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static ApiClient? _instance;

  /// Returns the configured singleton instance.
  ///
  /// Throws a [StateError] if [configure] has not been called yet.
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError(
        'ApiClient not initialized. Call ApiClient.configure() first.',
      );
    }
    return _instance!;
  }

  /// Initialises the singleton with the given dependencies.
  ///
  /// [isTrainer] sets the initial auth mode. When `true` the client uses
  /// cookie-based auth (trainer mode); when `false` (default) the existing
  /// Bearer-token auth is used (client mode). The mode can be changed later
  /// via [setMode].
  ///
  /// [onUnauthorized] is called with the failing mode ('trainer' or 'client')
  /// when a 401 response cannot be resolved by a token refresh. The receiver
  /// should surgically clear only that mode's tokens and show a session-expired
  /// message.
  ///
  /// Safe to call multiple times – only the first call takes effect.
  static void configure({
    required SecureStorage secureStorage,
    void Function(String mode)? onUnauthorized,
    bool isTrainer = false,
  }) {
    if (_instance != null) return;
    _instance = ApiClient._(
      secureStorage: secureStorage,
      onUnauthorized: onUnauthorized,
      isTrainer: isTrainer,
    );
  }

  /// Resets the singleton (primarily for testing).
  @visibleForTesting
  static void reset() => _instance = null;

  // ---------------------------------------------------------------------------
  // Public members
  // ---------------------------------------------------------------------------

  /// The underlying Dio instance. Exposed for advanced scenarios (e.g.,
  /// downloading files, custom streams).
  final Dio dio;

  /// Exposed for testing / inspection.
  final AuthInterceptor authInterceptor;
  final RetryInterceptor retryInterceptor;

  /// Role-scoped cookie jar. Non-null when the client was configured with
  /// cookie support; `null` in configurations that disable cookies entirely.
  final CookieStorage? cookieStorage;

  /// Cookie-manager interceptor. Added to [dio] only while in trainer mode;
  /// removed when switching to client mode.
  CookieManager? _cookieManager;

  // ---------------------------------------------------------------------------
  // Private constructor
  // ---------------------------------------------------------------------------

  ApiClient._({
    required SecureStorage secureStorage,
    void Function(String mode)? onUnauthorized,
    bool isTrainer = false,
  })  : authInterceptor = AuthInterceptor(
          secureStorage: secureStorage,
          onUnauthorized: onUnauthorized,
        ),
        retryInterceptor = RetryInterceptor(),
        cookieStorage = CookieStorage(),
        dio = Dio() {
    // -- Create cookie infrastructure --------------------------------------
    _cookieManager = CookieManager(cookieStorage!);

    // Wire the Dio instance into the auth interceptor for token-refresh requests.
    authInterceptor.attachDio(dio);

    // -- Base configuration ------------------------------------------------
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = ApiConstants.connectTimeout;
    dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    dio.options.contentType = 'application/json';
    dio.options.headers = {
      'Accept': 'application/json',
    };

    // -- Wire up interceptors that need to make retry calls ----------------
    authInterceptor.attachDio(dio);
    retryInterceptor.attachDio(dio);

    // -- Register interceptors --------------------------------------------
    // Order matters:
    //   Request:  CookieManager → Retry → Auth → Log
    //   Error:    Log           → Auth → Retry → CookieManager
    //
    // AuthInterceptor handles 401s first (refresh + retry). For non-401
    // errors RetryInterceptor retries transient network failures.
    // CookieManager is only added when trainer mode is active.
    dio.interceptors.addAll([
      retryInterceptor,
      authInterceptor,
    ]);

    // Attach the CookieManager interceptor if the initial mode is trainer.
    // We insert it at index 0 so it runs before Retry on request and after
    // Retry on error/response (Dio executes response interceptors in reverse).
    if (isTrainer) {
      _insertCookieManager();
    }

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    // Sync auth-interceptor mode with the initial setting.
    authInterceptor.setMode(isTrainer);
  }

  // ---------------------------------------------------------------------------
  // Mode switching
  // ---------------------------------------------------------------------------

  /// Switches the client between **trainer mode** (cookie-based auth) and
  /// **client mode** (Bearer-token auth).
  ///
  /// In trainer mode a [CookieManager] interceptor is inserted at the front of
  /// the interceptor chain so that cookies are attached to every request and
  /// `Set-Cookie` headers are captured from every response. The auth
  /// interceptor also stops attaching Bearer tokens.
  ///
  /// In client mode the [CookieManager] is removed and the existing Bearer-
  /// token logic takes over.
  void setMode(bool isTrainer) {
    authInterceptor.setMode(isTrainer);

    if (isTrainer) {
      // Activate the trainer cookie jar so loadForRequest/saveFromResponse
      // operate on the correct role scope.
      cookieStorage!.activateRole('trainer');
      _insertCookieManager();
    } else {
      cookieStorage!.deactivate();
      _removeCookieManager();
    }
  }

  /// Inserts the [CookieManager] interceptor at the front of the chain if it
  /// is not already present.
  void _insertCookieManager() {
    if (_cookieManager == null) return;
    if (!dio.interceptors.contains(_cookieManager)) {
      dio.interceptors.insert(0, _cookieManager!);
    }
  }

  /// Removes the [CookieManager] interceptor from the chain if present.
  void _removeCookieManager() {
    if (_cookieManager == null) return;
    if (dio.interceptors.contains(_cookieManager)) {
      dio.interceptors.remove(_cookieManager);
    }
  }

  // ---------------------------------------------------------------------------
  // Cookie management
  // ---------------------------------------------------------------------------

  /// Deletes all cookies stored for [role].
  Future<void> clearCookiesForRole(String role) async {
    await cookieStorage?.clearCookies(role);
  }

  /// Deletes cookies for every role.
  Future<void> clearAllCookies() async {
    await cookieStorage?.clearAllCookies();
  }

  // ---------------------------------------------------------------------------
  // HTTP verb methods
  // ---------------------------------------------------------------------------

  /// Sends a GET request to [path].
  ///
  /// If [fromJson] is provided, its return value is used as [T]. Otherwise
  /// the raw response data map is cast to [T].
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParams,
    );
    return _processResponse(response, fromJson: fromJson);
  }

  /// Sends a POST request to [path] with an optional [body].
  Future<T> post<T>(
    String path, {
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _processResponse(response, fromJson: fromJson);
  }

  /// Sends a PUT request to [path] with an optional [body].
  Future<T> put<T>(
    String path, {
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await dio.put<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _processResponse(response, fromJson: fromJson);
  }

  /// Sends a PATCH request to [path] with an optional [body].
  Future<T> patch<T>(
    String path, {
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _processResponse(response, fromJson: fromJson);
  }

  /// Sends a DELETE request to [path].
  Future<void> delete(String path) async {
    await dio.delete(path);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Processes a successful Dio response by either applying [fromJson] or
  /// casting the data map directly to [T].
  T _processResponse<T>(
    Response<Map<String, dynamic>> response, {
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    final data = response.data;

    if (data == null) {
      throw ApiException(
        'Server returned an empty response',
        statusCode: response.statusCode,
      );
    }

    if (fromJson != null) {
      try {
        return fromJson(data);
      } catch (e, st) {
        debugPrint('❌ JSON PARSING ERROR in ${T.toString()}:');
        debugPrint('Error: $e');
        debugPrint('Stack Trace: $st');
        rethrow;
      }
    }

    // When no parser is provided the caller expects the raw map.
    return data as T;
  }
}
