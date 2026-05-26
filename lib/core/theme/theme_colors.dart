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

  // -- Static brand colors (same in light & dark) --

  /// Accent color: iOS accent blue (#0083FF), static across themes.
  static const Color accentColor = Color(0xFF0083FF);

  /// Emerald green (#10B981) for progress bars / success states — NOT the accent.
  static const Color emeraldColor = Color(0xFF10B981);

  /// Secondary text color: iOS system gray (#8E8E93), static across themes.
  static const Color textSecondary = Color(0xFF8E8E93);

  // -- Dynamic colors (light / dark) --

  /// Primary text color: black in light mode, white in dark mode.
  Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF000000);

  /// Primary background: systemGray6 in light, systemGroupedBackground in dark.
  Color get backgroundPrimary =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F2);

  /// Secondary background: white in light, secondarySystemGroupedBackground in dark.
  Color get backgroundSecondary =>
      _isDark ? const Color(0xFF2C2C2E) : Colors.white;

  /// Tertiary background: slightly darker gray in light, tertiarySystemGroupedBackground in dark.
  Color get backgroundTertiary =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE6E6E6);

  /// Card background: white in light, secondarySystemGroupedBackground in dark.
  Color get cardBackground =>
      _isDark ? const Color(0xFF2C2C2E) : Colors.white;

  /// Content area background: systemGray6 in light, tertiarySystemGroupedBackground in dark.
  Color get contentBackground =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F2);

  /// Accent color: iOS accent blue (#0083FF), static across themes.
  Color get accent => accentColor;
}

// =============================================================================
// BuildContext Extension
// =============================================================================

/// Extension to access [ThemeColors] from any [BuildContext].
extension ThemeColorsX on BuildContext {
  /// Theme-aware color constants that adapt to light/dark mode.
  ThemeColors get themeColors => ThemeColors(this);
}
