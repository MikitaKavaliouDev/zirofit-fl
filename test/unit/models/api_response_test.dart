import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/api_response.dart';

/// Simple concrete data class for testing generic [ApiResponse].
class _TestItem {
  final String id;
  final String name;

  const _TestItem({required this.id, required this.name});

  factory _TestItem.fromJson(Map<String, dynamic> json) => _TestItem(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestItem && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

void main() {
  group('ApiResponse model (generic)', () {
    group('ApiResponse.fromJson', () {
      test('parses success response with data', () {
        final json = <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'item-1',
            'name': 'Test Item',
          },
        };

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.isError, isFalse);
        expect(response.data, isNotNull);
        expect(response.data!.id, 'item-1');
        expect(response.data!.name, 'Test Item');
        expect(response.errorMessage, isNull);
        expect(response.errorCode, isNull);
        expect(response.statusCode, isNull);
      });

      test('parses error response with message', () {
        final json = <String, dynamic>{
          'error': <String, dynamic>{
            'message': 'Not found',
            'code': 'NOT_FOUND',
            'statusCode': 404,
          },
        };

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isFalse);
        expect(response.isError, isTrue);
        expect(response.data, isNull);
        expect(response.errorMessage, 'Not found');
        expect(response.errorCode, 'NOT_FOUND');
        expect(response.statusCode, 404);
      });

      test('parses error response with status_code (snake_case)', () {
        final json = <String, dynamic>{
          'error': <String, dynamic>{
            'message': 'Bad Request',
            'code': 'BAD_REQUEST',
            'status_code': 400,
          },
        };

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          _TestItem.fromJson,
        );

        expect(response.errorMessage, 'Bad Request');
        expect(response.statusCode, 400);
      });

      test('returns unknown format when neither data nor error key exists', () {
        final json = <String, dynamic>{'foo': 'bar'};

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          _TestItem.fromJson,
        );

        expect(response.isError, isTrue);
        expect(response.errorMessage, 'Unknown response format');
        expect(response.data, isNull);
      });

      test('returns unknown format when data key is null', () {
        final json = <String, dynamic>{'data': null};

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          _TestItem.fromJson,
        );

        expect(response.isError, isTrue);
        expect(response.errorMessage, 'Unknown response format');
        expect(response.data, isNull);
      });

      test('uses custom fromJsonT parser function', () {
        final json = <String, dynamic>{
          'data': <String, dynamic>{
            'id': 'custom-1',
            'name': 'Custom Parser',
          },
        };

        // Use a custom parser that transforms the name
        T customParser<T>(Map<String, dynamic> map) =>
            _TestItem.fromJson(map) as T;

        final response = ApiResponse<_TestItem>.fromJson(
          json,
          (map) => _TestItem(
            id: map['id'] as String,
            name: 'Parsed: ${map['name']}',
          ),
        );

        expect(response.data!.name, 'Parsed: Custom Parser');
      });
    });

    group('apiResponseListFromJson', () {
      test('parses data list containing multiple items', () {
        final json = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            {'id': 'item-1', 'name': 'First'},
            {'id': 'item-2', 'name': 'Second'},
          ],
        };

        final response = apiResponseListFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.data, hasLength(2));
        expect(response.data![0].id, 'item-1');
        expect(response.data![1].name, 'Second');
      });

      test('parses empty data list', () {
        final json = <String, dynamic>{
          'data': <Map<String, dynamic>>[],
        };

        final response = apiResponseListFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.data, isEmpty);
      });

      test('parses error response', () {
        final json = <String, dynamic>{
          'error': <String, dynamic>{
            'message': 'Server error',
            'code': 'SERVER_ERROR',
            'statusCode': 500,
          },
        };

        final response = apiResponseListFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isError, isTrue);
        expect(response.errorMessage, 'Server error');
        expect(response.errorCode, 'SERVER_ERROR');
        expect(response.statusCode, 500);
        expect(response.data, isNull);
      });
    });

    group('apiResponsePaginatedFromJson', () {
      test('parses paginated data with metadata', () {
        final json = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            {'id': 'item-1', 'name': 'First'},
            {'id': 'item-2', 'name': 'Second'},
          ],
          'total': 10,
          'page': 1,
          'perPage': 2,
          'totalPages': 5,
          'hasMore': true,
        };

        final response = apiResponsePaginatedFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!.items, hasLength(2));
        expect(response.data!.total, 10);
        expect(response.data!.page, 1);
        expect(response.data!.perPage, 2);
        expect(response.data!.totalPages, 5);
        expect(response.data!.hasMore, isTrue);
      });

      test('parses paginated data with empty items list', () {
        final json = <String, dynamic>{
          'data': <Map<String, dynamic>>[],
          'total': 0,
          'page': 1,
          'perPage': 10,
          'totalPages': 0,
          'hasMore': false,
        };

        final response = apiResponsePaginatedFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.data!.items, isEmpty);
        expect(response.data!.total, 0);
        expect(response.data!.hasMore, isFalse);
      });

      test('parses paginated data when data key is missing (empty items)', () {
        final json = <String, dynamic>{
          'total': 0,
          'page': 1,
          'perPage': 10,
          'totalPages': 0,
          'hasMore': false,
        };

        final response = apiResponsePaginatedFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isSuccess, isTrue);
        expect(response.data!.items, isEmpty);
      });

      test('parses error response for paginated', () {
        final json = <String, dynamic>{
          'error': <String, dynamic>{
            'message': 'Unauthorized',
            'code': 'UNAUTHORIZED',
            'statusCode': 401,
          },
        };

        final response = apiResponsePaginatedFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
        );

        expect(response.isError, isTrue);
        expect(response.errorMessage, 'Unauthorized');
        expect(response.errorCode, 'UNAUTHORIZED');
        expect(response.statusCode, 401);
        expect(response.data, isNull);
      });

      test('uses custom key names for pagination metadata', () {
        final json = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            {'id': 'item-1', 'name': 'First'},
          ],
          'total_count': 1,
          'current_page': 1,
          'items_per_page': 10,
          'page_count': 1,
          'has_next': false,
        };

        final response = apiResponsePaginatedFromJson<_TestItem>(
          json,
          _TestItem.fromJson,
          totalKey: 'total_count',
          pageKey: 'current_page',
          perPageKey: 'items_per_page',
          totalPagesKey: 'page_count',
          hasMoreKey: 'has_next',
        );

        expect(response.data!.total, 1);
        expect(response.data!.page, 1);
        expect(response.data!.perPage, 10);
        expect(response.data!.totalPages, 1);
        expect(response.data!.hasMore, isFalse);
      });
    });

    group('ApiResponse helpers', () {
      test('isSuccess returns true only when data is present and errorMessage is null', () {
        const success = ApiResponse(data: _TestItem(id: '1', name: 'Test'));
        expect(success.isSuccess, isTrue);
        expect(success.isError, isFalse);
      });

      test('isError returns true when errorMessage is present', () {
        const error = ApiResponse<_TestItem>(errorMessage: 'Error occurred');
        expect(error.isError, isTrue);
        expect(error.isSuccess, isFalse);
      });

      test('isSuccess returns false when both data and errorMessage are null', () {
        const empty = ApiResponse<_TestItem>();
        expect(empty.isSuccess, isFalse);
        expect(empty.isError, isFalse);
      });

      test('toException returns ApiException with error details', () {
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

      test('toException uses default message when errorMessage is null', () {
        const response = ApiResponse<_TestItem>(errorMessage: null);

        final exception = response.toException();

        expect(exception.message, 'Unknown error');
      });
    });
  });
}
