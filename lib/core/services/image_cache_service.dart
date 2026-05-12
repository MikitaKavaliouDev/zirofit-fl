import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// In-memory LRU image cache service that stores raw image bytes.
///
/// Provides a singleton [ImageCacheService] with a configurable maximum size
/// (default 50 MB). Entries are evicted in LRU order when the total exceeds
/// the limit. This is a memory-level cache; consider pairing with a disk cache
/// (e.g. [CachedNetworkImage]'s built-in cache manager) for a complete solution.
///
/// Example usage:
/// ```dart
/// final cache = ImageCacheService();
/// cache.set('https://example.com/image.png', bytes);
/// final bytes = cache.get('https://example.com/image.png');
/// cache.remove('https://example.com/image.png');
/// cache.clear();
/// ```
class ImageCacheService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Default maximum cache size: 50 MB.
  static const int defaultMaxSizeBytes = 50 * 1024 * 1024;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  /// LRU cache: insertion order is maintained so the eldest entry (least
  /// recently used) is evicted first. Each `get` promotes the entry by
  /// re-inserting it.
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  /// Tracks the byte size of each cached entry so eviction decisions can be
  /// made without recalculating.
  final Map<String, int> _sizes = {};

  int _maxSizeBytes = defaultMaxSizeBytes;
  int _currentSizeBytes = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the cached bytes for [url], or `null` if not present.
  ///
  /// Promotes the entry to most-recently-used on access.
  Uint8List? get(String url) {
    if (!_cache.containsKey(url)) return null;

    // Promote to MRU by re-inserting.
    final bytes = _cache.remove(url)!;
    _cache[url] = bytes;
    return bytes;
  }

  /// Stores [bytes] for [url] in the cache.
  ///
  /// If [bytes] exceeds [_maxSizeBytes] the entry is silently dropped. If the
  /// cache is full the least-recently-used entries are evicted until space is
  /// available.
  void set(String url, Uint8List bytes) {
    final size = bytes.lengthInBytes;

    // Single item too large — don't cache.
    if (size > _maxSizeBytes) return;

    // Remove existing entry so we can re-insert (updates LRU order + size).
    if (_cache.containsKey(url)) {
      _currentSizeBytes -= _sizes[url]!;
      _cache.remove(url);
      _sizes.remove(url);
    }

    // Evict LRU entries until there is room.
    while (_currentSizeBytes + size > _maxSizeBytes && _cache.isNotEmpty) {
      final eldest = _cache.keys.first;
      _currentSizeBytes -= _sizes[eldest]!;
      _cache.remove(eldest);
      _sizes.remove(eldest);
    }

    _cache[url] = bytes;
    _sizes[url] = size;
    _currentSizeBytes += size;

    debugPrint(
      '[ImageCacheService] Cached: $url '
      '(${_formatBytes(size)}) — total: ${_formatBytes(_currentSizeBytes)}',
    );
  }

  /// Removes the entry for [url] from the cache, if present.
  void remove(String url) {
    if (!_cache.containsKey(url)) return;

    _currentSizeBytes -= _sizes[url]!;
    _cache.remove(url);
    _sizes.remove(url);

    debugPrint('[ImageCacheService] Removed: $url');
  }

  /// Clears all entries from the cache.
  void clear() {
    _cache.clear();
    _sizes.clear();
    _currentSizeBytes = 0;

    debugPrint('[ImageCacheService] Cache cleared');
  }

  /// Returns `true` if [url] is present in the cache.
  bool contains(String url) => _cache.containsKey(url);

  /// Reports the number of cached entries.
  int get count => _cache.length;

  /// Reports the current total byte size of all cached entries.
  int get currentSizeBytes => _currentSizeBytes;

  /// The maximum allowed cache size in bytes.
  int get maxSizeBytes => _maxSizeBytes;

  /// Updates the maximum cache size. If the current total exceeds the new
  /// limit, the oldest entries are evicted until the cache fits.
  set maxSizeBytes(int value) {
    _maxSizeBytes = value;
    _evictUntilWithinLimit();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Evicts the oldest entries until [_currentSizeBytes] ≤ [_maxSizeBytes].
  void _evictUntilWithinLimit() {
    while (_currentSizeBytes > _maxSizeBytes && _cache.isNotEmpty) {
      final eldest = _cache.keys.first;
      _currentSizeBytes -= _sizes[eldest]!;
      _cache.remove(eldest);
      _sizes.remove(eldest);
    }
  }

  /// Formats a byte count into a human-readable string (e.g. "4.2 MB").
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
