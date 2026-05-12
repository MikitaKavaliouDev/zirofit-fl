import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zirofit_fl/shared/widgets/ziro_blur.dart';

/// A circular dismiss button matching iOS [ZiroDismissButton].
///
/// Features a 32px circle with ultra-thin material blur, an xmark (close)
/// icon, and haptic feedback ([HapticFeedback.lightImpact]) on tap.
///
/// Use this for closing modal sheets, popups, or overlays.
///
/// {@tool dartpad}
/// ```dart
/// ZiroDismissButton(
///   action: () => Navigator.of(context).pop(),
/// )
/// ```
/// {@end-tool}
class ZiroDismissButton extends StatelessWidget {
  /// Called with haptic feedback when the button is tapped.
  final VoidCallback action;

  /// Icon color. Defaults to [Colors.grey].
  final Color color;

  const ZiroDismissButton({
    super.key,
    required this.action,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        action();
      },
      child: ZiroBlur(
        blurStyle: ZiroBlurStyle.systemUltraThinMaterial,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(
              Icons.close,
              size: 14,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
