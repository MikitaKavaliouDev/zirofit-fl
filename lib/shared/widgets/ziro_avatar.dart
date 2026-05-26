import 'package:flutter/material.dart';
import 'package:zirofit_fl/shared/widgets/cached_async_image.dart';

/// A circular avatar widget that displays a network image with initials
/// fallback, modeled after iOS contact avatars.
///
/// The widget first attempts to load the image from [imageUrl]. If the URL is
/// `null`, empty, or the image fails to load, it falls back to a colored
/// circle displaying [initials]. The background color is deterministically
/// chosen from a 10-color palette based on the initials hash, matching the
/// iOS contact avatar pattern.
///
/// {@tool snippet}
/// ```dart
/// ZiroAvatar(
///   imageUrl: user.profilePhotoPath,
///   initials: user.name?.substring(0, 2).toUpperCase(),
///   size: 56,
///   onTap: () => _showProfile(),
/// )
/// ```
/// {@end-tool}
class ZiroAvatar extends StatelessWidget {
  /// The network image URL to load.
  ///
  /// When `null` or empty, the [initials] fallback is shown instead.
  final String? imageUrl;

  /// Fallback text (1–2 characters) shown when no image is available or the
  /// image fails to load.
  ///
  /// When `null` or empty, a question mark `?` is displayed.
  final String? initials;

  /// The diameter of the avatar circle.
  ///
  /// Defaults to `48.0`.
  final double size;

  /// The font size for the initials text.
  ///
  /// When `null`, defaults to [size] * 0.4.
  final double? fontSize;

  /// Optional tap handler.
  ///
  /// When provided, the avatar is wrapped in an [InkWell] that produces a
  /// circular ripple effect.
  final VoidCallback? onTap;

  /// Predefined palette of 10 colors, mirroring the iOS contact avatar palette.
  static const List<Color> _palette = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.green,
    Colors.cyan,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  const ZiroAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48.0,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarContent = _buildContent();
    final clip = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarContent,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: clip,
        ),
      );
    }

    return clip;
  }

  /// Builds the inner content: either a network image or the fallback circle.
  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedAsyncImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: _buildInitialsCircle(),
      );
    }

    return _buildInitialsCircle();
  }

  /// Builds the colored initials fallback circle with deterministic color.
  Widget _buildInitialsCircle() {
    final displayInitials = (initials != null && initials!.isNotEmpty)
        ? initials!
        : '?';
    final color = _deterministicColor(displayInitials);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayInitials,
          style: TextStyle(
            fontSize: fontSize ?? size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Deterministically picks a color from [_palette] based on [value].
  ///
  /// The same [value] always produces the same color, ensuring stable
  /// per-user avatar colors (matching iOS behaviour).
  static Color _deterministicColor(String value) {
    // Double-modulo to handle negative hashCode results safely.
    final index =
        (value.hashCode % _palette.length + _palette.length) % _palette.length;
    return _palette[index];
  }
}
