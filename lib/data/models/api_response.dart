import 'package:zirofit_fl/core/network/api_exception.dart';

/// Generic wrapper around all API responses.
///
/// [T] is the parsed data type when the request succeeds.
/// On success, [data] is non-null and [errorMessage] is null.
/// On error, [errorMessage] is non-null and [data] is null.
class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final String? errorCode;
  final int? statusCode;

  const ApiResponse({
    this.data,
    this.errorMessage,
    this.errorCode,
    this.statusCode,
  });

  /// Whether the request succeeded.
  bool get isSuccess => data != null && errorMessage == null;

  /// Whether the request failed.
  bool get isError => errorMessage != null;

  /// Converts a failed response into an [ApiException].
  ApiException toException() {
    return ApiException(
      errorMessage ?? 'Unknown error',
      statusCode: statusCode,
      code: errorCode,
    );
  }

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Builds a response from a JSON map that contains a single `data` object
  /// or an `error` object.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    if (json.containsKey('data') && json['data'] != null) {
      return ApiResponse(
        data: fromJsonT(json['data'] as Map<String, dynamic>),
      );
    }
    if (json.containsKey('error') && json['error'] != null) {
      final error = json['error'] as Map<String, dynamic>;
      return ApiResponse(
        errorMessage: error['message'] as String?,
        errorCode: error['code'] as String?,
        statusCode: error['statusCode'] as int? ?? error['status_code'] as int?,
      );
    }
    return const ApiResponse(errorMessage: 'Unknown response format');
  }
}

/// Builds a response from a JSON map that contains a `data` list.
ApiResponse<List<T>> apiResponseListFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromJsonT,
) {
  if (json.containsKey('data') && json['data'] != null) {
    final dataList = (json['data'] as List)
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();
    return ApiResponse(data: dataList);
  }
  if (json.containsKey('error') && json['error'] != null) {
    final error = json['error'] as Map<String, dynamic>;
    return ApiResponse(
      errorMessage: error['message'] as String?,
      errorCode: error['code'] as String?,
      statusCode: error['statusCode'] as int? ?? error['status_code'] as int?,
    );
  }
  return const ApiResponse(errorMessage: 'Unknown response format');
}

/// Builds a paginated response from a JSON map.
ApiResponse<PaginatedData<T>> apiResponsePaginatedFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromJsonT, {
  String dataKey = 'data',
  String totalKey = 'total',
  String pageKey = 'page',
  String perPageKey = 'perPage',
  String totalPagesKey = 'totalPages',
  String hasMoreKey = 'hasMore',
}) {
  final hasError = json.containsKey('error') && json['error'] != null;

  if (hasError) {
    final error = json['error'] as Map<String, dynamic>;
    return ApiResponse(
      errorMessage: error['message'] as String?,
      errorCode: error['code'] as String?,
      statusCode: error['statusCode'] as int? ?? error['status_code'] as int?,
    );
  }

  final List<T> items;
  if (json.containsKey(dataKey) && json[dataKey] != null) {
    items = (json[dataKey] as List)
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();
  } else {
    items = [];
  }

  final paginatedData = PaginatedData<T>(
    items: items,
    total: json[totalKey] as int?,
    page: json[pageKey] as int?,
    perPage: json[perPageKey] as int?,
    totalPages: json[totalPagesKey] as int?,
    hasMore: json[hasMoreKey] as bool?,
  );

  return ApiResponse(data: paginatedData);
}

/// Holds pagination metadata along with the item list.
class PaginatedData<T> {
  final List<T> items;
  final int? total;
  final int? page;
  final int? perPage;
  final int? totalPages;
  final bool? hasMore;

  const PaginatedData({
    required this.items,
    this.total,
    this.page,
    this.perPage,
    this.totalPages,
    this.hasMore,
  });
}
