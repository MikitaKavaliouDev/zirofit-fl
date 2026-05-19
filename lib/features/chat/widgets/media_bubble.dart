import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Displays an image or video thumbnail inside a chat bubble.
///
/// * Images are rendered via [CachedNetworkImage] with rounded corners.
/// * Videos show a thumbnail placeholder with a play icon overlay.
class MediaBubble extends StatelessWidget {
  /// The URL of the media file.
  final String mediaUrl;

  /// The MIME type of the media (e.g. `image/jpeg`, `video/mp4`).
  final String? mediaType;

  /// Maximum width constraint (defaults to 75% of screen width).
  final double? maxWidth;

  /// Whether this message is sent by the current user (affects styling).
  final bool isSentByMe;

  const MediaBubble({
    super.key,
    required this.mediaUrl,
    this.mediaType,
    this.maxWidth,
    this.isSentByMe = false,
  });

  bool get _isVideo {
    if (mediaType == null) return false;
    return mediaType!.startsWith('video/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMaxWidth =
        maxWidth ?? MediaQuery.of(context).size.width * 0.65;

    return Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
          bottomRight: Radius.circular(isSentByMe ? 4 : 16),
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isVideo ? _buildVideoThumbnail() : _buildImage(),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const AspectRatio(
        aspectRatio: 1,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => const AspectRatio(
        aspectRatio: 1,
        child: Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video thumbnail via cached network image
        CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black26,
              child: const Icon(Icons.videocam, size: 48),
            ),
          ),
        ),
        // Play icon overlay
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
        ),
      ],
    );
  }
}
