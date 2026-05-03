import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

/// A fake [SecureStorage] that never touches actual platform keychain.
class FakeSecureStorage extends SecureStorage {
  Future<void> write(String key, String value) async {}

  Future<String?> read(String key) async => null;

  Future<void> delete(String key) async {}

  Future<void> clear() async {}
}

/// Configures the [ApiClient] singleton with a [FakeSecureStorage].
///
/// Call in `setUpAll` (or `setUp`) before any test that creates a notifier
/// whose super constructor touches [ApiClient.instance].
void configureTestApiClient() {
  ApiClient.configure(secureStorage: FakeSecureStorage());
}
