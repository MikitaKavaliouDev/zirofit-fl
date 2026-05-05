import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/data/models/api_response.dart';

/// Helper to build error JSON responses.
Map<String, dynamic> _errorResponse({
  required String message,
  String? code,
  int? statusCode,
  bool useSnakeCase = false,
  Map<String, dynamic>? details,
}) {
  final error = <String, dynamic>{'message': message};
  if (code != null) error['code'] = code;
  if (statusCode != null) {
    error[useSnakeCase ? 'status_code' : 'statusCode'] = statusCode;
  }
  if (details != null) error['details'] = details;
  return {'error': error};
}

/// Simple test item for generic ApiResponse tests.
class _TestItem {
  final String id;
  final String name;
  const _TestItem({required this.id, required this.name});
  factory _TestItem.fromJson(Map<String, dynamic> json) => _TestItem(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

void main() {
  // ===========================================================================
  // Group 1: ApiResponse.fromJson success smoke test
  // ===========================================================================
  group('ApiResponse.fromJson success (smoke)', () {
    test('parses {data: {...}} with a simple model', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{'id': 'x1', 'name': 'Smoke'},
      };
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isSuccess, isTrue);
      expect(response.data, isA<_TestItem>());
      expect(response.data!.id, 'x1');
      expect(response.data!.name, 'Smoke');
      expect(response.errorMessage, isNull);
    });

    test('uses custom fromJsonT parser', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{'id': 'c1', 'name': 'Original'},
      };
      final response = ApiResponse<_TestItem>.fromJson(
        json,
        (m) => _TestItem(id: m['id'] as String, name: 'Custom: ${m['name']}'),
      );
      expect(response.data!.name, 'Custom: Original');
    });
  });

  // ===========================================================================
  // Group 2: Error format parsing (core variants)
  // ===========================================================================
  group('Error format parsing', () {
    test('full error with message, code, and camelCase statusCode', () {
      final json = _errorResponse(
        message: 'Not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isSuccess, isFalse);
      expect(response.isError, isTrue);
      expect(response.data, isNull);
      expect(response.errorMessage, 'Not found');
      expect(response.errorCode, 'NOT_FOUND');
      expect(response.statusCode, 404);
    });

    test('error with snake_case status_code', () {
      final json = _errorResponse(
        message: 'Bad Request',
        code: 'BAD_REQUEST',
        statusCode: 400,
        useSnakeCase: true,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.errorMessage, 'Bad Request');
      expect(response.errorCode, 'BAD_REQUEST');
      expect(response.statusCode, 400);
    });

    test('error with camelCase statusCode', () {
      final json = _errorResponse(
        message: 'Server Error',
        statusCode: 500,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.errorMessage, 'Server Error');
      expect(response.statusCode, 500);
    });

    test('error without code or statusCode', () {
      final json = _errorResponse(message: 'Unauthorized');
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.errorMessage, 'Unauthorized');
      expect(response.errorCode, isNull);
      expect(response.statusCode, isNull);
    });

    test('error with code but no statusCode', () {
      final json = _errorResponse(message: 'Forbidden', code: 'FORBIDDEN');
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.errorMessage, 'Forbidden');
      expect(response.errorCode, 'FORBIDDEN');
      expect(response.statusCode, isNull);
    });

    test('error with details field', () {
      final json = _errorResponse(
        message: 'Validation failed',
        details: {'field': 'email'},
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.errorMessage, 'Validation failed');
      expect(response.errorCode, isNull);
      expect(response.statusCode, isNull);
      // details is accepted but not stored in ApiResponse fields directly
    });
  });

  // ===========================================================================
  // Group 3: HTTP status code tests (400–500)
  // ===========================================================================
  group('HTTP status codes', () {
    test('400 Bad Request', () {
      final json = _errorResponse(
        message: 'Bad Request',
        code: 'BAD_REQUEST',
        statusCode: 400,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 400);
      expect(response.errorMessage, 'Bad Request');
    });

    test('401 Unauthorized (invalid token)', () {
      final json = _errorResponse(
        message: 'Invalid or expired token',
        code: 'INVALID_TOKEN',
        statusCode: 401,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 401);
      expect(response.errorCode, 'INVALID_TOKEN');
      expect(response.errorMessage, 'Invalid or expired token');
    });

    test('401 Unauthorized (expired token variant)', () {
      final json = _errorResponse(
        message: 'Token has expired',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 401);
      expect(response.errorCode, 'TOKEN_EXPIRED');
    });

    test('403 Forbidden (wrong role)', () {
      final json = _errorResponse(
        message: 'Insufficient permissions. Required role: admin',
        code: 'FORBIDDEN',
        statusCode: 403,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 403);
      expect(response.errorCode, 'FORBIDDEN');
      expect(response.errorMessage, contains('Insufficient permissions'));
    });

    test('404 Not Found', () {
      final json = _errorResponse(
        message: 'Resource not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 404);
      expect(response.errorCode, 'NOT_FOUND');
      expect(response.errorMessage, 'Resource not found');
    });

    test('409 Conflict (email already in use)', () {
      final json = _errorResponse(
        message: 'Email already in use',
        code: 'EMAIL_EXISTS',
        statusCode: 409,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 409);
      expect(response.errorCode, 'EMAIL_EXISTS');
      expect(response.errorMessage, 'Email already in use');
    });

    test('422 Validation Error (Zod validation)', () {
      final json = _errorResponse(
        message: 'Validation failed',
        code: 'VALIDATION_ERROR',
        statusCode: 422,
        details: {'field': 'email', 'issue': 'invalid format'},
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 422);
      expect(response.errorCode, 'VALIDATION_ERROR');
      expect(response.errorMessage, 'Validation failed');
    });

    test('500 Internal Server Error', () {
      final json = _errorResponse(
        message: 'Internal server error',
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.statusCode, 500);
      expect(response.errorCode, 'INTERNAL_ERROR');
      expect(response.errorMessage, 'Internal server error');
    });
  });

  // ===========================================================================
  // Group 4: Edge case response handling
  // ===========================================================================
  group('Edge case responses', () {
    test('unknown format: {"unexpected": true}', () {
      final json = <String, dynamic>{'unexpected': true};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });

    test('empty response: {}', () {
      final json = <String, dynamic>{};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });

    test('null data: {"data": null}', () {
      final json = <String, dynamic>{'data': null};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });

    test('null error: {"error": null}', () {
      final json = <String, dynamic>{'error': null};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });

    test('empty error object: {"error": {}} — errorMessage is null', () {
      // When error is {} but has no 'message' key, errorMessage stays null.
      // isError returns false because errorMessage == null.
      // This edge case documents that a malformed error object is treated as
      // neither success nor error.
      final json = <String, dynamic>{'error': <String, dynamic>{}};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isFalse);
      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, isNull);
      expect(response.errorCode, isNull);
      expect(response.statusCode, isNull);
    });

    test('missing both data and error keys: {"foo": "bar"}', () {
      final json = <String, dynamic>{'foo': 'bar'};
      final response = ApiResponse<_TestItem>.fromJson(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });
  });

  // ===========================================================================
  // Group 5: apiResponseListFromJson error handling
  // ===========================================================================
  group('apiResponseListFromJson error handling', () {
    test('error response with message, code, statusCode', () {
      final json = _errorResponse(
        message: 'Server error',
        code: 'SERVER_ERROR',
        statusCode: 500,
      );
      final response = apiResponseListFromJson<_TestItem>(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Server error');
      expect(response.errorCode, 'SERVER_ERROR');
      expect(response.statusCode, 500);
      expect(response.data, isNull);
    });

    test('error response with snake_case status_code', () {
      final json = _errorResponse(
        message: 'List fetch failed',
        code: 'FETCH_ERROR',
        statusCode: 400,
        useSnakeCase: true,
      );
      final response = apiResponseListFromJson<_TestItem>(json, _TestItem.fromJson);
      expect(response.errorMessage, 'List fetch failed');
      expect(response.statusCode, 400);
      expect(response.data, isNull);
    });

    test('unknown format falls back to Unknown response format', () {
      final json = <String, dynamic>{'foo': 'bar'};
      final response = apiResponseListFromJson<_TestItem>(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unknown response format');
      expect(response.data, isNull);
    });
  });

  // ===========================================================================
  // Group 6: apiResponsePaginatedFromJson error handling
  // ===========================================================================
  group('apiResponsePaginatedFromJson error handling', () {
    test('error response with message, code, statusCode', () {
      final json = _errorResponse(
        message: 'Unauthorized',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
      final response =
          apiResponsePaginatedFromJson<_TestItem>(json, _TestItem.fromJson);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Unauthorized');
      expect(response.errorCode, 'UNAUTHORIZED');
      expect(response.statusCode, 401);
      expect(response.data, isNull);
    });

    test('error with snake_case status_code in paginated', () {
      final json = _errorResponse(
        message: 'Forbidden paginated access',
        code: 'FORBIDDEN',
        statusCode: 403,
        useSnakeCase: true,
      );
      final response =
          apiResponsePaginatedFromJson<_TestItem>(json, _TestItem.fromJson);
      expect(response.statusCode, 403);
      expect(response.errorCode, 'FORBIDDEN');
      expect(response.data, isNull);
    });

    test('error with custom key names still returns error', () {
      final json = _errorResponse(
        message: 'Custom key error',
        code: 'CUSTOM_ERR',
        statusCode: 422,
      );
      final response = apiResponsePaginatedFromJson<_TestItem>(
        json,
        _TestItem.fromJson,
        dataKey: 'items',
        totalKey: 'total_count',
      );
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Custom key error');
      expect(response.errorCode, 'CUSTOM_ERR');
      expect(response.statusCode, 422);
      expect(response.data, isNull);
    });
  });

  // ===========================================================================
  // Group 7: ApiException tests
  // ===========================================================================
  group('ApiException', () {
    test('creation from error response fields', () {
      const response = ApiResponse<_TestItem>(
        errorMessage: 'Not found',
        errorCode: 'NOT_FOUND',
        statusCode: 404,
      );
      final exception = response.toException();
      expect(exception.message, 'Not found');
      expect(exception.code, 'NOT_FOUND');
      expect(exception.statusCode, 404);
    });

    test('creation with only message', () {
      const exception = ApiException('Something went wrong');
      expect(exception.message, 'Something went wrong');
      expect(exception.code, isNull);
      expect(exception.statusCode, isNull);
    });

    test('toString() includes status code when available', () {
      const exception = ApiException('Not found', statusCode: 404, code: 'NOT_FOUND');
      final str = exception.toString();
      expect(str, 'ApiException(404): Not found');
      expect(str, contains('404'));
    });

    test('toString() without status code', () {
      const exception = ApiException('Unauthorized');
      final str = exception.toString();
      expect(str, 'ApiException: Unauthorized');
      expect(str, isNot(contains('(')));
    });

    test('toString() with code but no statusCode', () {
      const exception = ApiException('Forbidden', code: 'FORBIDDEN');
      final str = exception.toString();
      expect(str, 'ApiException: Forbidden');
    });

    test('== operator: same fields are equal', () {
      const a = ApiException('Error', statusCode: 400, code: 'BAD');
      const b = ApiException('Error', statusCode: 400, code: 'BAD');
      expect(a, equals(b));
      expect(a == b, isTrue);
    });

    test('== operator: different message not equal', () {
      const a = ApiException('Error A', statusCode: 400);
      const b = ApiException('Error B', statusCode: 400);
      expect(a == b, isFalse);
      expect(a, isNot(equals(b)));
    });

    test('== operator: different statusCode not equal', () {
      const a = ApiException('Error', statusCode: 400);
      const b = ApiException('Error', statusCode: 500);
      expect(a == b, isFalse);
    });

    test('== operator: different code not equal', () {
      const a = ApiException('Error', code: 'A');
      const b = ApiException('Error', code: 'B');
      expect(a == b, isFalse);
    });

    test('== operator: identical objects are equal', () {
      const a = ApiException('Same');
      // ignore: identical_comparison
      expect(a == a, isTrue);
    });

    test('== operator: different type not equal', () {
      const a = ApiException('Error');
      expect(a == Object(), isFalse);
    });

    test('hashCode consistency: equal objects have same hash', () {
      const a = ApiException('Error', statusCode: 400, code: 'BAD');
      const b = ApiException('Error', statusCode: 400, code: 'BAD');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode: different objects have different hash', () {
      const a = ApiException('Error A', statusCode: 400);
      const b = ApiException('Error B', statusCode: 500);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  // ===========================================================================
  // Group 8: DioException / network error handling
  // ===========================================================================
  group('DioException network errors', () {
    test('DioException with connectionTimeout', () {
      final dioException = DioException(
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
        requestOptions: RequestOptions(path: '/api/test'),
      );
      expect(dioException.type, DioExceptionType.connectionTimeout);
      expect(dioException.message, contains('Connection timed out'));
    });

    test('DioException with badResponse wrapping ApiResponse error', () {
      final errorJson = _errorResponse(
        message: 'Internal server error',
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      final response = Response(
        data: errorJson,
        statusCode: 500,
        requestOptions: RequestOptions(path: '/api/data'),
      );
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: response,
        message: 'HTTP connection threw an error: 500',
        requestOptions: RequestOptions(path: '/api/data'),
      );

      expect(dioException.type, DioExceptionType.badResponse);
      expect(dioException.response!.statusCode, 500);

      // Parse the response data as an ApiResponse
      final parsed = ApiResponse<_TestItem>.fromJson(
        dioException.response!.data as Map<String, dynamic>,
        _TestItem.fromJson,
      );
      expect(parsed.errorMessage, 'Internal server error');
      expect(parsed.errorCode, 'INTERNAL_ERROR');
      expect(parsed.statusCode, 500);
    });

    test('DioException with badResponse and 400 error', () {
      final errorJson = _errorResponse(
        message: 'Bad request',
        code: 'BAD_REQUEST',
        statusCode: 400,
      );
      final response = Response(
        data: errorJson,
        statusCode: 400,
        requestOptions: RequestOptions(path: '/api/create'),
      );
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: response,
        requestOptions: RequestOptions(path: '/api/create'),
      );

      final parsed = ApiResponse<_TestItem>.fromJson(
        dioException.response!.data as Map<String, dynamic>,
        _TestItem.fromJson,
      );
      expect(parsed.errorMessage, 'Bad request');
      expect(parsed.statusCode, 400);
    });

    test('DioException with badResponse and 401 error (snake_case)', () {
      final errorJson = _errorResponse(
        message: 'Token expired',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
        useSnakeCase: true,
      );
      final response = Response(
        data: errorJson,
        statusCode: 401,
        requestOptions: RequestOptions(path: '/api/protected'),
      );
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: response,
        requestOptions: RequestOptions(path: '/api/protected'),
      );

      final parsed = ApiResponse<_TestItem>.fromJson(
        dioException.response!.data as Map<String, dynamic>,
        _TestItem.fromJson,
      );
      expect(parsed.errorMessage, 'Token expired');
      expect(parsed.statusCode, 401);
      expect(parsed.errorCode, 'TOKEN_EXPIRED');
    });

    test('DioException with connectionError', () {
      final dioException = DioException(
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
        requestOptions: RequestOptions(path: '/api/test'),
      );
      expect(dioException.type, DioExceptionType.connectionError);
      expect(dioException.message, contains('Connection refused'));
    });

    test('DioException error message extraction from various types', () {
      // connectionTimeout
      final timeoutErr = DioException(
        type: DioExceptionType.connectionTimeout,
        message: 'timeout',
        requestOptions: RequestOptions(path: '/'),
      );
      expect(timeoutErr.message, 'timeout');

      // receiveTimeout
      final receiveErr = DioException(
        type: DioExceptionType.receiveTimeout,
        message: 'receive timeout',
        requestOptions: RequestOptions(path: '/'),
      );
      expect(receiveErr.message, 'receive timeout');

      // cancel
      final cancelErr = DioException(
        type: DioExceptionType.cancel,
        message: 'Request was cancelled',
        requestOptions: RequestOptions(path: '/'),
      );
      expect(cancelErr.message, 'Request was cancelled');

      // unknown
      final unknownErr = DioException(
        type: DioExceptionType.unknown,
        message: 'Unexpected error occurred',
        requestOptions: RequestOptions(path: '/'),
      );
      expect(unknownErr.message, 'Unexpected error occurred');
    });

    test('DioException to ApiResponse pipeline integration', () {
      // Simulate a full pipeline: DioException -> extract data -> ApiResponse -> toException
      final errorJson = _errorResponse(
        message: 'Not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
      final response = Response(
        data: errorJson,
        statusCode: 404,
        requestOptions: RequestOptions(path: '/api/resource/999'),
      );
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: response,
        requestOptions: RequestOptions(path: '/api/resource/999'),
      );

      // Parse the error response
      final apiResponse = ApiResponse<_TestItem>.fromJson(
        dioException.response!.data as Map<String, dynamic>,
        _TestItem.fromJson,
      );

      // Convert to ApiException
      final exception = apiResponse.toException();

      expect(exception.message, 'Not found');
      expect(exception.code, 'NOT_FOUND');
      expect(exception.statusCode, 404);
      expect(exception.toString(), 'ApiException(404): Not found');
    });
  });
}
