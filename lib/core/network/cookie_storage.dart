import 'package:cookie_jar/cookie_jar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Role-scoped cookie storage that wraps separate [PersistCookieJar] instances
/// per role ("trainer" / "client").
///
/// Implements the [CookieJar] interface so it can be used directly with
/// [CookieManager] from `dio_cookie_manager`. Only the **active role**'s jar
/// responds to [loadForRequest] / [saveFromResponse]; other roles' cookies
/// remain untouched until their jar is activated.
///
/// Cookies are persisted to `<app-documents>/cookies/<role>/` so that closing
/// and reopening the app preserves the session for each role independently.
class CookieStorage implements CookieJar {
  String? _basePath;
  bool _initialized = false;

  String? _activeRole;
  PersistCookieJar? _trainerJar;
  PersistCookieJar? _clientJar;

  @override
  final bool ignoreExpires = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Ensures the base storage directory is resolved. Called automatically by
  /// [activateRole], [clearCookies] and [clearAllCookies].
  Future<void> _ensureInit() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _basePath = '${dir.path}/cookies';
    _initialized = true;
  }

  /// Activates cookie handling for [role] ("trainer" or "client").
  ///
  /// Subsequent [loadForRequest] / [saveFromResponse] calls will operate on
  /// this role's cookie jar. Call [deactivate] to stop cookie handling.
  Future<void> activateRole(String role) async {
    await _ensureInit();
    _activeRole = role;
    final path = p.join(_basePath!, role);
    if (role == 'trainer') {
      _trainerJar ??= PersistCookieJar(
        ignoreExpires: ignoreExpires,
        storage: FileStorage(path),
      );
    } else {
      _clientJar ??= PersistCookieJar(
        ignoreExpires: ignoreExpires,
        storage: FileStorage(path),
      );
    }
  }

  /// Stops cookie handling for the currently active role.
  void deactivate() {
    _activeRole = null;
  }

  // ---------------------------------------------------------------------------
  // CookieJar interface — delegates to the active role's jar
  // ---------------------------------------------------------------------------

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    final jar = _activeJar;
    if (jar == null) return <Cookie>[];
    return jar.loadForRequest(uri);
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    final jar = _activeJar;
    if (jar == null) return;
    await jar.saveFromResponse(uri, cookies);
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    final jar = _activeJar;
    if (jar == null) return;
    await jar.delete(uri, withDomainSharedCookie);
  }

  @override
  Future<void> deleteAll() async {
    // Delete ALL role-specific jars (not just the active one).
    await _ensureInit();
    for (final role in ['trainer', 'client']) {
      final path = p.join(_basePath!, role);
      final jar = PersistCookieJar(
        ignoreExpires: ignoreExpires,
        storage: FileStorage(path),
      );
      await jar.deleteAll();
    }
  }

  // ---------------------------------------------------------------------------
  // Role-scoped helpers (for explicit management from auth_provider etc.)
  // ---------------------------------------------------------------------------

  /// Persists [cookies] for [role] explicitly (outside the normal
  /// request/response flow).
  Future<void> saveCookies(String role, List<Cookie> cookies,
      {required Uri uri}) async {
    await _ensureInit();
    final jar = _jarForRole(role);
    await jar.saveFromResponse(uri, cookies);
  }

  /// Loads all cookies stored for [role].
  Future<List<Cookie>> loadCookies(String role,
      {required Uri uri}) async {
    await _ensureInit();
    final jar = _jarForRole(role);
    return jar.loadForRequest(uri);
  }

  /// Deletes all cookies stored for a single [role].
  Future<void> clearCookies(String role) async {
    await _ensureInit();
    final jar = _jarForRole(role);
    await jar.deleteAll();
  }

  /// Deletes cookies for every role.
  Future<void> clearAllCookies() async => deleteAll();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Returns the jar for the currently active role, or `null` if no role is
  /// active.
  PersistCookieJar? get _activeJar {
    if (!_initialized || _activeRole == null) return null;
    return _activeRole == 'trainer' ? _trainerJar : _clientJar;
  }

  PersistCookieJar _jarForRole(String role) {
    final path = p.join(_basePath!, role);
    return PersistCookieJar(
      ignoreExpires: ignoreExpires,
      storage: FileStorage(path),
    );
  }
}
