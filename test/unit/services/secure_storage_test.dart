import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorage.test(storage: mockStorage);
  });

  group('SecureStorage', () {
    // ===================================================================
    // saveTokens
    // ===================================================================

    group('saveTokens', () {
      test('writes access_token and refresh_token to secure storage', () async {
        const accessToken = 'access-token-123';
        const refreshToken = 'refresh-token-456';

        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await secureStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        verify(() => mockStorage.write(
              key: 'access_token',
              value: accessToken,
            )).called(1);

        verify(() => mockStorage.write(
              key: 'refresh_token',
              value: refreshToken,
            )).called(1);
      });
    });

    // ===================================================================
    // getAccessToken
    // ===================================================================

    group('getAccessToken', () {
      test('returns stored access token', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'my-access-token');

        final result = await secureStorage.getAccessToken();

        expect(result, equals('my-access-token'));
        verify(() => mockStorage.read(key: 'access_token')).called(1);
      });

      test('returns null when no access token is stored', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        final result = await secureStorage.getAccessToken();

        expect(result, isNull);
        verify(() => mockStorage.read(key: 'access_token')).called(1);
      });
    });

    // ===================================================================
    // getRefreshToken
    // ===================================================================

    group('getRefreshToken', () {
      test('returns stored refresh token', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'my-refresh-token');

        final result = await secureStorage.getRefreshToken();

        expect(result, equals('my-refresh-token'));
        verify(() => mockStorage.read(key: 'refresh_token')).called(1);
      });

      test('returns null when no refresh token is stored', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        final result = await secureStorage.getRefreshToken();

        expect(result, isNull);
        verify(() => mockStorage.read(key: 'refresh_token')).called(1);
      });
    });

    // ===================================================================
    // clearTokens
    // ===================================================================

    group('clearTokens', () {
      test('calls deleteAll on secure storage', () async {
        when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

        await secureStorage.clearTokens();

        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    // ===================================================================
    // hasTokens
    // ===================================================================

    group('hasTokens', () {
      test('returns true when access_token exists', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'some-token');

        final result = await secureStorage.hasTokens();

        expect(result, isTrue);
        verify(() => mockStorage.read(key: 'access_token')).called(1);
      });

      test('returns false when access_token is null', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        final result = await secureStorage.hasTokens();

        expect(result, isFalse);
        verify(() => mockStorage.read(key: 'access_token')).called(1);
      });
    });
  });
}
