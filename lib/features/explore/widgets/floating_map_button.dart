import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A floating action button for map view matching iOS [FloatingMapButton].
///
/// Positioned at the bottom-right of the screen, intended to sit above the tab
/// bar. Tapping the button triggers [onTap] to open a map or location picker.
///
/// {@tool dartpad}
/// ```dart
/// Stack(
///   children: [
///     // ... map content
///     const FloatingMapButton(
///       onTap: _openMap,
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
class FloatingMapButton extends StatelessWidget {
  /// Called when the button is tapped.
  final VoidCallback? onTap;

  const FloatingMapButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Positioned(
      right: 16,
      bottom: 16,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: themeColors.accent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: const Icon(
              Icons.map,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
