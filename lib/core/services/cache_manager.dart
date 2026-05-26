import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File-based JSON cache manager.
///
/// Mirrors iOS `CacheManager` used by `ClientsViewModel` et al.
/// Each cache entry is a separate file in the app's document directory
/// named `{key}.json`, making it easy to inspect and debug.
///
/// Typical keys:
/// - `client_list` – cached client list for instant first-frame UI
class CacheManager {
  static final CacheManager _instance = CacheManager._();
  factory CacheManager() => _instance;
  CacheManager._();

  Directory? _cacheDir;

  /// Lazily resolve the cache directory (document directory).
  Future<Directory> get _directory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// File path for the given [key].
  Future<File> _file(String key) async {
    final dir = await _directory;
    return File('${dir.path}/$key.json');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads and decodes the JSON data cached under [key].
  ///
  /// Returns `null` if no cache file exists or decoding fails.
  Future<T?> load<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;

      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) return null;

      return fromJson(decoded);
    } catch (e, st) {
      debugPrint('CacheManager.load($key) error: $e\n$st');
      return null;
    }
  }

  /// Loads a list of items from the cache under [key].
  ///
  /// Returns `null` if no cache file exists or decoding fails.
  Future<List<T>?> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;

      final decoded = jsonDecode(contents);
      if (decoded is! List) return null;

      return decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('CacheManager.loadList($key) error: $e\n$st');
      return null;
    }
  }

  /// Saves [data] as JSON under [key].
  Future<void> save(String key, dynamic data) async {
    try {
      final file = await _file(key);
      final contents = const JsonEncoder.withIndent(null).convert(data);
      await file.writeAsString(contents);
    } catch (e, st) {
      debugPrint('CacheManager.save($key) error: $e\n$st');
    }
  }

  /// Removes the cache file for [key].
  Future<void> remove(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, st) {
      debugPrint('CacheManager.remove($key) error: $e\n$st');
    }
  }

  /// Removes all cache files.
  Future<void> clearAll() async {
    try {
      final dir = await _directory;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _cacheDir = null;
    } catch (e, st) {
      debugPrint('CacheManager.clearAll error: $e\n$st');
    }
  }
}
