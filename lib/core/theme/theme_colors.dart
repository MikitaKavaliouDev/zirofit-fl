import 'package:flutter/material.dart';

// =============================================================================
// Theme Color Constants
// =============================================================================

/// Theme-aware color constants exposed via [BuildContext.themeColors].
///
/// Usage:
/// ```dart
/// final color = context.themeColors.textPrimary;
/// final bg = context.themeColors.backgroundPrimary;
/// ```
///
/// These adapt automatically based on the current brightness (light/dark mode),
/// matching the iOS Color.theme.textPrimary, Color.theme.backgroundPrimary, etc.
class ThemeColors {
  final BuildContext context;
  ThemeColors(this.context);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  /// Primary text color: near-black in light mode, white in dark mode.
  Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1F2937);

  /// Primary background: white in light mode, dark navy in dark mode.
  Color get backgroundPrimary =>
      _isDark ? const Color(0xFF12121E) : Colors.white;

  /// Secondary background: light gray in light mode, dark surface in dark mode.
  Color get backgroundSecondary =>
      _isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F6);

  /// Tertiary background: slightly darker gray in light mode, mid-tone in dark.
  Color get backgroundTertiary =>
      _isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB);

  /// Accent color: emerald green matching [AppTheme] brand colors.
  Color get accent =>
      _isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
}

// =============================================================================
// BuildContext Extension
// =============================================================================

/// Extension to access [ThemeColors] from any [BuildContext].
extension ThemeColorsX on BuildContext {
  /// Theme-aware color constants that adapt to light/dark mode.
  ThemeColors get themeColors => ThemeColors(this);
}
