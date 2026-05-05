import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for auth tokens using platform Keychain/Keystore.
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
            synchronizable: false,
          ),
        );

  /// Test-only constructor that accepts a mock [FlutterSecureStorage].
  /// Not intended for production use.
  SecureStorage.test({required FlutterSecureStorage storage})
      : _storage = storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasTokens() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
