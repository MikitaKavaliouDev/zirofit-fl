import 'package:dio/dio.dart';

/// Dio interceptor that automatically retries failed requests on transient
/// network errors using exponential backoff.
///
/// Retry behaviour:
/// - Only retries on **network-level** errors (timeouts, connection refused,
///   DNS failures, etc.). HTTP error responses (4xx, 5xx) are **not** retried.
/// - Exponential backoff: 2 s → 4 s → 8 s (configurable via [baseDelay]).
/// - Maximum [maxRetries] attempts (default 3).
/// - Requests marked with `extra['_noAuthRetry'] = true` are skipped (to avoid
///   retrying refresh-token calls).
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;

  /// Dio instance used to re-issue the failed request.
  Dio? _dio;

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 2),
    Dio? dio,
  }) : _dio = dio;

  /// Injected after construction to avoid circular dependencies.
  void attachDio(Dio dio) => _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry network-level errors.
    if (!_isNetworkError(err)) {
      handler.next(err);
      return;
    }

    // Never retry refresh-token calls.
    if (err.requestOptions.extra['_noAuthRetry'] == true) {
      handler.next(err);
      return;
    }

    // Check retry budget.
    final retryCount = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    // Exponential backoff: baseDelay * 2^retryCount
    final delay = baseDelay * (1 << retryCount);
    await Future<void>.delayed(delay);

    // Bump retry counter and re-issue.
    err.requestOptions.extra['_retryCount'] = retryCount + 1;

    if (_dio == null) {
      handler.next(err);
      return;
    }

    try {
      final response = await _dio!.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (retryErr) {
      handler.next(err);
    }
  }

  /// Returns `true` for errors caused by network connectivity issues (as
  /// opposed to HTTP error responses).
  bool _isNetworkError(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse => false,
      DioExceptionType.cancel => false,
      DioExceptionType.badCertificate => false,
      DioExceptionType.unknown => err.error is Exception,
    };
  }
}
