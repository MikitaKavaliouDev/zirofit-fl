import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/services/image_cache_service.dart';

/// An async image widget that checks [ImageCacheService] first for an instant
/// in-memory hit, then falls back to [CachedNetworkImage] (disk + network).
///
/// Mirrors the iOS `CachedAsyncImage` pattern:
///   - Checks the in-memory byte cache first (synchronous, no flicker).
///   - On miss, delegates to [CachedNetworkImage] which provides its own
///     disk / network caching via `flutter_cache_manager`.
///   - Supports placeholder, error, sizing, and fit — same API shape as the
///     iOS counterpart.
///
/// ### When to pre-cache via [ImageCacheService]
/// Use `ImageCacheService().set(url, bytes)` for images you know will be
/// needed soon (e.g. from a list detail screen). After pre-caching, any
/// [CachedAsyncImage] with that URL will render instantly without any
/// network or disk I/O.
///
/// {@tool snippet}
/// ```dart
/// CachedAsyncImage(
///   imageUrl: 'https://example.com/photo.jpg',
///   width: 120,
///   height: 120,
///   fit: BoxFit.cover,
///   placeholder: Shimmer(...),
///   errorWidget: Icon(Icons.person, color: Colors.grey),
/// )
/// ```
/// {@end-tool}
class CachedAsyncImage extends StatefulWidget {
  /// The image URL to load. When `null` or empty the [errorWidget] is shown.
  final String? imageUrl;

  /// Widget shown while the image is loading (only when falling back to
  /// [CachedNetworkImage] — an in-memory cache hit is effectively instant).
  final Widget? placeholder;

  /// Widget shown when the image fails to load.
  final Widget? errorWidget;

  /// Width constraint for the image.
  final double? width;

  /// Height constraint for the image.
  final double? height;

  /// How to inscribe the image into the space allotted during layout.
  final BoxFit fit;

  /// Alignment of the image within its bounds.
  final Alignment alignment;

  const CachedAsyncImage({
    super.key,
    this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  State<CachedAsyncImage> createState() => _CachedAsyncImageState();
}

class _CachedAsyncImageState extends State<CachedAsyncImage> {
  /// Non-null when the bytes for [widget.imageUrl] are already in
  /// [ImageCacheService], allowing instant rendering.
  Uint8List? _cachedBytes;

  /// Tracks whether we've checked the cache for the current URL so we don't
  /// re-check on every build (only on URL change).
  String? _lastCheckedUrl;

  @override
  void didUpdateWidget(CachedAsyncImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _cachedBytes = null;
      _lastCheckedUrl = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;

    // --- Check the in-memory cache if the URL has changed -------------------
    if (_lastCheckedUrl != url) {
      _lastCheckedUrl = url;
      _cachedBytes = (url != null && url.isNotEmpty)
          ? ImageCacheService().get(url)
          : null;
    }

    // --- Cache hit : render instantly from memory ---------------------------
    if (_cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, _, _) => _buildError(),
      );
    }

    // --- No URL : show error ------------------------------------------------
    if (url == null || url.isEmpty) {
      return _buildError();
    }

    // --- Cache miss : delegate to CachedNetworkImage ------------------------
    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      placeholder: (_, _) => _buildPlaceholder(),
      errorWidget: (_, _, _) => _buildError(),
      // Use the disk cache from flutter_cache_manager but DO NOT change the
      // cache key — the URL itself is the key.
      cacheKey: url,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildPlaceholder() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.placeholder ??
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.errorWidget ??
          const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }
}
