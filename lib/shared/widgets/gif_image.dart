import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/services/image_cache_service.dart';

/// An animated GIF image widget with two-tier caching.
///
/// Internally delegates to [CachedNetworkImage] which natively handles animated
/// GIFs via `flutter_cache_manager`. If the raw GIF bytes have been pre-cached
/// via [ImageCacheService], the widget renders instantly with [Image.memory]
/// (Flutter's image decoder natively supports animated GIFs).
///
/// Mirrors the iOS `GIFImage` pattern which used `FLAnimatedImageView` or
/// UIKit's animated image data.
///
/// {@tool snippet}
/// ```dart
/// GifImage(
///   imageUrl: 'https://example.com/animation.gif',
///   width: 200,
///   height: 200,
///   fit: BoxFit.contain,
/// )
/// ```
/// {@end-tool}
class GifImage extends StatefulWidget {
  /// The URL of the GIF to display.
  final String? imageUrl;

  /// Widget shown while the GIF is loading (only on cache miss).
  final Widget? placeholder;

  /// Widget shown when the GIF fails to load.
  final Widget? errorWidget;

  /// Width constraint.
  final double? width;

  /// Height constraint.
  final double? height;

  /// How to inscribe the GIF into the space allotted during layout.
  final BoxFit fit;

  /// Alignment of the GIF within its bounds.
  final Alignment alignment;

  /// Whether the GIF should repeat indefinitely. Defaults to `true`.
  ///
  /// **Note:** This is a hint — Flutter's built-in GIF decoder always loops.
  /// Set to `false` to achieve a single-play effect via a GIF-editing tool,
  /// or use a custom [ImageProvider] for fine-grained control.
  final bool repeat;

  /// An optional progress indicator builder for fine-grained loading feedback
  /// (only used when falling back to [CachedNetworkImage]).
  final Widget Function(
    BuildContext context,
    String url,
    DownloadProgress progress,
  )? progressIndicatorBuilder;

  const GifImage({
    super.key,
    this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.progressIndicatorBuilder,
  });

  @override
  State<GifImage> createState() => _GifImageState();
}

class _GifImageState extends State<GifImage> {
  Uint8List? _cachedBytes;
  String? _lastCheckedUrl;

  @override
  void didUpdateWidget(GifImage oldWidget) {
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

    // --- Cache hit : render instantly from memory (GIF animates natively) ---
    if (_cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        // Flutter renders animated GIFs automatically via Image.memory.
        errorBuilder: (_, _, _) => _buildError(),
      );
    }

    // --- No URL : show error ------------------------------------------------
    if (url == null || url.isEmpty) {
      return _buildError();
    }

    // --- Cache miss : delegate to CachedNetworkImage ------------------------
    //
    // CachedNetworkImage auto-detects animated images and handles GIF frames
    // correctly via its underlying ImageProvider.
    if (widget.progressIndicatorBuilder != null) {
      return CachedNetworkImage(
        imageUrl: url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        progressIndicatorBuilder: widget.progressIndicatorBuilder,
        errorWidget: (_, _, _) => _buildError(),
        cacheKey: url,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      placeholder: (_, _) => _buildPlaceholder(),
      errorWidget: (_, _, _) => _buildError(),
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
