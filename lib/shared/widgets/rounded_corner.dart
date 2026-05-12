import 'package:flutter/material.dart';

/// An enum representing a corner of a rectangle.
///
/// Used with [roundedCorners] extension to specify which corners
/// should be rounded.
enum Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  /// All four corners.
  static const List<Corner> all = [
    Corner.topLeft,
    Corner.topRight,
    Corner.bottomLeft,
    Corner.bottomRight,
  ];

  /// The top two corners.
  static const List<Corner> top = [
    Corner.topLeft,
    Corner.topRight,
  ];

  /// The bottom two corners.
  static const List<Corner> bottom = [
    Corner.bottomLeft,
    Corner.bottomRight,
  ];

  /// The left two corners.
  static const List<Corner> left = [
    Corner.topLeft,
    Corner.bottomLeft,
  ];

  /// The right two corners.
  static const List<Corner> right = [
    Corner.topRight,
    Corner.bottomRight,
  ];
}

/// A custom [ShapeBorder] that applies rounded corners to specific corners
/// of a rectangle, similar to iOS `RoundedCorner` shape.
///
/// This can be used with [Material.shape], [ClipPath], or any widget that
/// accepts a [ShapeBorder].
///
/// ```dart
/// Material(
///   shape: RoundedCornerClipper(
///     radius: 12,
///     corners: [Corner.topLeft, Corner.topRight],
///   ),
///   child: ...
/// )
/// ```
class RoundedCornerClipper extends ShapeBorder {
  /// The corner radius to apply.
  final double radius;

  /// The list of corners to round. Defaults to [Corner.all].
  final List<Corner> corners;

  const RoundedCornerClipper({
    this.radius = 0,
    this.corners = Corner.all,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();

    // Convert corner list to a set of radii for each corner
    final tl = corners.contains(Corner.topLeft) ? radius : 0.0;
    final tr = corners.contains(Corner.topRight) ? radius : 0.0;
    final bl = corners.contains(Corner.bottomLeft) ? radius : 0.0;
    final br = corners.contains(Corner.bottomRight) ? radius : 0.0;

    path.addRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(tl),
        topRight: Radius.circular(tr),
        bottomLeft: Radius.circular(bl),
        bottomRight: Radius.circular(br),
      ),
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // No paint needed — this is a clipping-only shape.
  }

  @override
  ShapeBorder scale(double t) {
    return RoundedCornerClipper(
      radius: radius * t,
      corners: corners,
    );
  }
}

/// Extension on [Widget] to easily apply specific corner rounding.
///
/// Usage:
/// ```dart
/// Container(
///   width: 100,
///   height: 100,
///   color: Colors.blue,
/// ).roundedCorners(
///   12,
///   corners: [Corner.topLeft, Corner.topRight],
/// )
/// ```
extension RoundedCornersExtension on Widget {
  /// Wraps this widget in a [ClipRRect] that only rounds the specified [corners].
  ///
  /// By default, all corners are rounded with the given [radius].
  /// Pass a subset of [Corner] values to round only specific corners.
  Widget roundedCorners(
    double radius, {
    List<Corner> corners = Corner.all,
  }) {
    // Resolve individual corner radii
    final tl = corners.contains(Corner.topLeft) ? radius : 0.0;
    final tr = corners.contains(Corner.topRight) ? radius : 0.0;
    final bl = corners.contains(Corner.bottomLeft) ? radius : 0.0;
    final br = corners.contains(Corner.bottomRight) ? radius : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(tl),
        topRight: Radius.circular(tr),
        bottomLeft: Radius.circular(bl),
        bottomRight: Radius.circular(br),
      ),
      child: this,
    );
  }
}
