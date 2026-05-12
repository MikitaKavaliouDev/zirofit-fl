import 'dart:ui';

import 'package:flutter/material.dart';

/// Blur styles matching iOS [UIBlurEffect.Style] values.
///
/// Maps to different sigma values for [ImageFilter.blur]:
/// - [systemMaterial] — standard blur (sigma 10)
/// - [systemUltraThinMaterial] — very subtle blur (sigma 3)
/// - [systemThinMaterial] — moderate blur (sigma 6)
/// - [systemChromeMaterial] — heavy blur (sigma 20)
enum ZiroBlurStyle {
  systemMaterial,
  systemUltraThinMaterial,
  systemThinMaterial,
  systemChromeMaterial,
}

/// A widget that applies a [BackdropFilter] with [ImageFilter.blur]
/// to blur the content behind it, matching iOS [UIBlurEffect] behavior.
///
/// {@tool dartpad}
/// ```dart
/// ZiroBlur(
///   blurStyle: ZiroBlurStyle.systemMaterial,
///   child: Text('Hello'),
/// )
/// ```
/// {@end-tool}
class ZiroBlur extends StatelessWidget {
  /// The child widget placed on top of the blurred backdrop.
  final Widget child;

  /// The blur style that controls sigma intensity.
  ///
  /// Defaults to [ZiroBlurStyle.systemMaterial].
  final ZiroBlurStyle blurStyle;

  /// Optional background color tint applied on top of the blur.
  /// If null, a default semi-transparent surface color is used.
  final Color? backgroundColor;

  /// Optional sigma override. When provided, [blurStyle] is ignored.
  final double? sigmaX;

  /// Optional sigma override. When provided, [blurStyle] is ignored.
  final double? sigmaY;

  /// Border radius applied via [ClipRRect] around the blur area.
  final BorderRadiusGeometry? borderRadius;

  const ZiroBlur({
    super.key,
    required this.child,
    this.blurStyle = ZiroBlurStyle.systemMaterial,
    this.backgroundColor,
    this.sigmaX,
    this.sigmaY,
    this.borderRadius,
  });

  /// Returns the blur sigma for the X axis based on [blurStyle] or
  /// the explicit override.
  double get _sigmaX => sigmaX ?? _sigmaForStyle;

  /// Returns the blur sigma for the Y axis based on [blurStyle] or
  /// the explicit override.
  double get _sigmaY => sigmaY ?? _sigmaForStyle;

  /// Resolves the sigma value from [blurStyle].
  double get _sigmaForStyle => switch (blurStyle) {
        ZiroBlurStyle.systemMaterial => 10.0,
        ZiroBlurStyle.systemUltraThinMaterial => 3.0,
        ZiroBlurStyle.systemThinMaterial => 6.0,
        ZiroBlurStyle.systemChromeMaterial => 20.0,
      };

  /// Returns the opacity tint for the background overlay based on blur style.
  double get _backgroundOpacity => switch (blurStyle) {
        ZiroBlurStyle.systemMaterial => 0.5,
        ZiroBlurStyle.systemUltraThinMaterial => 0.3,
        ZiroBlurStyle.systemThinMaterial => 0.4,
        ZiroBlurStyle.systemChromeMaterial => 0.6,
      };

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        Theme.of(context).colorScheme.surface.withValues(alpha: _backgroundOpacity);

    Widget blur = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _sigmaX, sigmaY: _sigmaY),
        child: Container(color: bgColor, child: child),
      ),
    );

    return blur;
  }
}
