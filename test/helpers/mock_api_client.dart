import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

/// A [Mock] implementation of [ApiClient] for use in unit tests.
class MockApiClient extends Mock implements ApiClient {
  void mockPost(
    String path, {
    int statusCode = 200,
    Map<String, dynamic>? body,
    Map<String, dynamic>? response,
  }) {
    when(() => post<Map<String, dynamic>>(path, body: any(named: 'body')))
        .thenAnswer((_) async => response ?? <String, dynamic>{});
  }

  void mockGet(
    String path, {
    int statusCode = 200,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? response,
  }) {
    when(() => get<Map<String, dynamic>>(path, queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => response ?? <String, dynamic>{});
  }

  void mockPut(
    String path, {
    int statusCode = 200,
    Map<String, dynamic>? body,
    Map<String, dynamic>? response,
  }) {
    when(() => put<Map<String, dynamic>>(path, body: any(named: 'body')))
        .thenAnswer((_) async => response ?? <String, dynamic>{});
  }

  void mockDelete(String path, {int statusCode = 200}) {
    when(() => delete(path)).thenAnswer((_) async => {});
  }

  void mockError(
    String path,
    DioExceptionType type, {
    String method = 'POST',
  }) {
    final exception = DioException(
      requestOptions: RequestOptions(path: path),
      type: type,
      error: 'Simulated $method error for $path',
    );
    switch (method.toUpperCase()) {
      case 'GET':
        when(() => get<Map<String, dynamic>>(path, queryParams: any(named: 'queryParams')))
            .thenThrow(exception);
        break;
      case 'PUT':
        when(() => put<Map<String, dynamic>>(path, body: any(named: 'body')))
            .thenThrow(exception);
        break;
      case 'DELETE':
        when(() => delete(path)).thenThrow(exception);
        break;
      default:
        when(() => post<Map<String, dynamic>>(path, body: any(named: 'body')))
            .thenThrow(exception);
    }
  }
}
