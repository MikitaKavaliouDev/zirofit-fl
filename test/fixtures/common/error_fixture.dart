/// Factory for generating common API error response payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class ErrorFixture {
  /// 400 Bad Request.
  static Map<String, dynamic> badRequest({
    String message = 'Bad request.',
    String code = 'BAD_REQUEST',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 400,
        },
      };

  /// 401 Unauthorized.
  static Map<String, dynamic> unauthorized({
    String message = 'Unauthorized.',
    String code = 'UNAUTHORIZED',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 401,
        },
      };

  /// 403 Forbidden.
  static Map<String, dynamic> forbidden({
    String message = 'Forbidden.',
    String code = 'FORBIDDEN',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 403,
        },
      };

  /// 404 Not Found.
  static Map<String, dynamic> notFound({
    String message = 'Resource not found.',
    String code = 'NOT_FOUND',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 404,
        },
      };

  /// 409 Conflict.
  static Map<String, dynamic> conflict({
    String message = 'Resource conflict.',
    String code = 'CONFLICT',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 409,
        },
      };

  /// 422 Validation Error.
  static Map<String, dynamic> validationError({
    String message = 'Validation failed.',
    String code = 'VALIDATION_ERROR',
    Map<String, List<String>>? errors,
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 422,
          'errors': errors?.map((k, v) => MapEntry(k, v)),
        },
      };

  /// 429 Too Many Requests.
  static Map<String, dynamic> rateLimited({
    String message = 'Too many requests. Please try again later.',
    String code = 'RATE_LIMITED',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 429,
        },
      };

  /// 500 Internal Server Error.
  static Map<String, dynamic> serverError({
    String message = 'Internal server error.',
    String code = 'SERVER_ERROR',
  }) =>
      {
        'error': {
          'message': message,
          'code': code,
          'status_code': 500,
        },
      };

  /// Generic network / connectivity error (no HTTP response).
  static Map<String, dynamic> networkError({
    String message = 'No internet connection.',
  }) =>
      {
        'error': {
          'message': message,
          'code': 'NETWORK_ERROR',
          'status_code': 0,
        },
      };
}
