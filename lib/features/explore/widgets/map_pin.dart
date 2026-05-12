import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A cubic map pin widget displaying a trainer's photo with a white border
/// and a downward-pointing triangular pointer.
///
/// Used as a custom marker on map views to represent trainer locations.
///
/// {@tool dartpad}
/// ```dart
/// TrainerMapPin(photoUrl: 'https://example.com/photo.jpg')
/// ```
/// {@end-tool}
class TrainerMapPin extends StatelessWidget {
  const TrainerMapPin({
    super.key,
    this.photoUrl,
    this.size = 50,
  });

  /// URL of the trainer's profile photo.
  final String? photoUrl;

  /// Width and height of the pin body (default 50).
  final double size;

  @override
  Widget build(BuildContext context) {
    return _MapPin(
      photoUrl: photoUrl,
      borderColor: Colors.white,
      fallbackIcon: Icons.person,
      size: size,
    );
  }
}

/// A cubic map pin widget displaying an event's image with an accent-colored
/// border and a downward-pointing triangular pointer.
///
/// Used as a custom marker on map views to represent event locations.
///
/// The border uses [Theme.colorScheme.primary] to visually distinguish event
/// pins from trainer pins.
///
/// {@tool dartpad}
/// ```dart
/// EventMapPin(imageUrl: 'https://example.com/event.jpg')
/// ```
/// {@end-tool}
class EventMapPin extends StatelessWidget {
  const EventMapPin({
    super.key,
    this.imageUrl,
    this.size = 50,
  });

  /// URL of the event's image.
  final String? imageUrl;

  /// Width and height of the pin body (default 50).
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _MapPin(
      photoUrl: imageUrl,
      borderColor: theme.colorScheme.primary,
      fallbackIcon: Icons.event,
      size: size,
    );
  }
}

/// Internal shared implementation for cubic map pins.
///
/// Renders a rounded-square photo body with a colored border and a small
/// triangular pointer at the bottom, creating the classic map pin silhouette.
class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.photoUrl,
    required this.borderColor,
    required this.fallbackIcon,
    this.size = 50,
  });

  final String? photoUrl;
  final Color borderColor;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pointerWidth = size * 0.3;
    final pointerHeight = pointerWidth * 0.6;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin body: rounded square with photo, border, and shadow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _PhotoContent(
              photoUrl: photoUrl,
              fallbackIcon: fallbackIcon,
              iconSize: size * 0.5,
            ),
          ),
        ),
        // Triangular pointer extending the border color downward
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: pointerWidth,
            height: pointerHeight,
            color: borderColor,
          ),
        ),
      ],
    );
  }
}

/// Loads a network photo via [CachedNetworkImage] with a fallback icon.
class _PhotoContent extends StatelessWidget {
  const _PhotoContent({
    required this.photoUrl,
    required this.fallbackIcon,
    required this.iconSize,
  });

  final String? photoUrl;
  final IconData fallbackIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _buildFallback(context);
    }

    return CachedNetworkImage(
      imageUrl: photoUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => _buildFallback(context),
      errorWidget: (_, _, _) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Clips a downward-pointing isosceles triangle shape for the map pin pointer.
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
