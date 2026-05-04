import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

void main() {
  group('ApiClient', () {
    setUp(() {
      ApiClient.reset();
    });

    test('configure sets up the singleton', () {
      final storage = SecureStorage();
      ApiClient.configure(secureStorage: storage);
      expect(ApiClient.instance, isA<ApiClient>());
    });

    test('configure is idempotent (first call wins)', () {
      final storage = SecureStorage();
      ApiClient.configure(secureStorage: storage);
      final firstInstance = ApiClient.instance;
      ApiClient.configure(secureStorage: SecureStorage());
      expect(ApiClient.instance, same(firstInstance));
    });

    test('instance throws StateError before configure', () {
      expect(
        () => ApiClient.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('configured client has Dio with correct base URL', () {
      final storage = SecureStorage();
      ApiClient.configure(secureStorage: storage);
      final client = ApiClient.instance;
      expect(client.dio.options.baseUrl, ApiConstants.baseUrl);
      expect(client.dio.options.connectTimeout, ApiConstants.connectTimeout);
      expect(client.dio.options.receiveTimeout, ApiConstants.receiveTimeout);
    });

    test('configured client has auth and retry interceptors', () {
      final storage = SecureStorage();
      ApiClient.configure(secureStorage: storage);
      final client = ApiClient.instance;
      expect(client.authInterceptor, isA<Interceptor>());
      expect(client.retryInterceptor, isA<Interceptor>());
    });
  });
}
