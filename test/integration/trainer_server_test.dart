import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple server connectivity test - verifies Next.js server is running.
///
/// Run with: flutter test test/integration/trainer_server_test.dart
void main() {
  group('Server Connectivity', () {
    test('Server is running and responding', () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:3321/api',
          validateStatus: (status) => true,
        ),
      );

      final response = await dio.get('/auth/login');

      // Should get a response (401 or 200) not connection error
      expect(response.statusCode, isNotNull);
    });

    test('Server health check', () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:3321',
          validateStatus: (status) => true,
        ),
      );

      final response = await dio.get('/');

      // Next.js home page returns 200
      expect(response.statusCode, anyOf(200, 404));
    });
  });
}
