import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/core/network/auth_interceptor.dart';
import 'package:zirofit_fl/core/network/retry_interceptor.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

/// Singleton Dio-based HTTP client for the Ziro Fit API.
///
/// Usage:
/// ```dart
/// // Bootstrap (once at app startup)
/// ApiClient.configure(
///   secureStorage: SecureStorage(),
///   onLogout: () => GoRouter.of(context).go('/login'),
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
  /// Safe to call multiple times – only the first call takes effect.
  static void configure({
    required SecureStorage secureStorage,
    void Function()? onLogout,
  }) {
    if (_instance != null) return;
    _instance = ApiClient._(
      secureStorage: secureStorage,
      onLogout: onLogout,
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

  // ---------------------------------------------------------------------------
  // Private constructor
  // ---------------------------------------------------------------------------

  ApiClient._({
    required SecureStorage secureStorage,
    void Function()? onLogout,
  })  : authInterceptor = AuthInterceptor(
          secureStorage: secureStorage,
          onLogout: onLogout,
        ),
        retryInterceptor = RetryInterceptor(),
        dio = Dio() {
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
    //   Request:  Retry → Auth → Log
    //   Error:    Log   → Auth → Retry
    //
    // AuthInterceptor handles 401s first (refresh + retry). For non-401
    // errors RetryInterceptor retries transient network failures.
    dio.interceptors.addAll([
      retryInterceptor,
      authInterceptor,
    ]);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
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
