import 'dart:ui';

import 'package:flutter/material.dart';

/// A widget that wraps its child with a bottom-sheet-style background
/// featuring rounded top corners and an ultra-thin material blur effect.
///
/// Matches the iOS [ZiroSheetBackground] modifier which applies:
/// - [Color.theme.backgroundPrimary] base color
/// - `.ultraThinMaterial` blur overlay
///
/// Use this as the container for modal bottom sheets or any overlay that
/// needs a frosted-glass appearance with rounded top corners.
///
/// {@tool dartpad}
/// ```dart
/// ZiroSheetBackground(
///   child: Column(children: [Text('Sheet content')]),
/// )
/// ```
/// {@end-tool}
class ZiroSheetBackground extends StatelessWidget {
  /// The content to display inside the sheet background.
  final Widget child;

  /// Border radius for the top corners. Defaults to 20.
  final double topRadius;

  /// Blur sigma value. Defaults to 3 (ultra-thin material equivalent).
  final double blurSigma;

  /// The background color base (before blur overlay).
  /// Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  const ZiroSheetBackground({
    super.key,
    required this.child,
    this.topRadius = 20,
    this.blurSigma = 3,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          color: bgColor.withValues(alpha: 0.85),
          child: child,
        ),
      ),
    );
  }
}

/// Extension on [Widget] to apply the Ziro sheet background as a modifier.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => Column(
///     children: [Text('Content')],
///   ).ziroSheetBackground(),
/// );
/// ```
extension ZiroSheetBackgroundExtension on Widget {
  /// Wraps this widget in a [ZiroSheetBackground] with the specified
  /// [topRadius], [blurSigma], and [backgroundColor].
  ///
  /// This provides a frosted-glass look with rounded top corners,
  /// matching the iOS bottom sheet visual style.
  Widget ziroSheetBackground({
    double topRadius = 20,
    double blurSigma = 3,
    Color? backgroundColor,
  }) {
    return ZiroSheetBackground(
      topRadius: topRadius,
      blurSigma: blurSigma,
      backgroundColor: backgroundColor,
      child: this,
    );
  }
}
