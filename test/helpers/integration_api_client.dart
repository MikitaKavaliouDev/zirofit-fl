import 'package:dio/dio.dart';

/// Test API client that points to localhost:3321 for integration testing.
///
/// Usage:
/// ```dart
/// late TestApiClient testClient;
/// setUpAll(() async {
///   testClient = TestApiClient();
///   await testClient.loginAsTrainer();
/// });
/// ```
///
/// Prerequisites:
/// - Next.js server running on localhost:3321
/// - Database seeded (prisma/seed.ts)
class TestApiClient {
  late final Dio dio;
  String? _accessToken;

  TestApiClient() : dio = Dio() {
    dio.options.baseUrl = 'http://localhost:3321/api';
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.contentType = 'application/json';
    // Allow all status codes to be checked in tests
    dio.options.validateStatus = (status) => true;
  }

  /// Login to get auth tokens.
  /// Returns true if login successful.
  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        _accessToken = data?['accessToken'] as String?;

        if (_accessToken != null) {
          dio.options.headers['Authorization'] = 'Bearer $_accessToken';
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Login as trainer using seeded credentials.
  /// Returns true if successful.
  Future<bool> loginAsTrainer() async {
    // Use seeded trainer credentials from prisma/seed.ts
    final credentials = [
      ('nyc.trainer@example.com', 'password123'),
      ('sarah.london@example.com', 'password123'),
      ('waw.trainer@example.com', 'password123'),
      ('krk.trainer@example.com', 'password123'),
    ];

    for (final cred in credentials) {
      if (await login(cred.$1, cred.$2)) {
        return true;
      }
    }
    return false;
  }

  /// Login as admin using seeded credentials.
  Future<bool> loginAsAdmin() async {
    final credentials = [('admin@ziro.fit', 'password123')];

    for (final cred in credentials) {
      if (await login(cred.$1, cred.$2)) {
        return true;
      }
    }
    return false;
  }

  /// GET request to the API.
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) {
    return dio.get<T>(path, queryParameters: queryParams);
  }

  /// POST request to the API.
  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  /// PUT request to the API.
  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  /// DELETE request to the API.
  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }

  /// Cleanup tokens.
  void logout() {
    _accessToken = null;
    dio.options.headers.remove('Authorization');
  }

  /// Check if authenticated.
  bool get isAuthenticated => _accessToken != null;
}

/// Creates authenticated trainer client.
Future<TestApiClient> createAuthenticatedTrainerClient() async {
  final client = TestApiClient();
  await client.loginAsTrainer();
  return client;
}

/// Creates authenticated admin client.
Future<TestApiClient> createAuthenticatedAdminClient() async {
  final client = TestApiClient();
  await client.loginAsAdmin();
  return client;
}
