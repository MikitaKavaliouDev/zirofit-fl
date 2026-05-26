import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Theme Mode Enum
// =============================================================================

/// Mirrors iOS [AppTheme] enum: system / light / dark.
/// Use [toThemeMode] to convert to Flutter's [ThemeMode].
enum AppThemeMode {
  system,
  light,
  dark;

  /// Display title matching iOS: "System", "Light", "Dark".
  String get title {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Convert to Flutter's [ThemeMode].
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Parse from a stored string (e.g. SharedPreferences).
  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

// =============================================================================
// Theme Manager
// =============================================================================

/// Persists the user's theme preference via SharedPreferences (iOS parity).
class ThemeManager {
  static const _kThemeModeKey = 'app_theme_mode';

  AppThemeMode _currentTheme = AppThemeMode.system;

  /// Currently selected theme mode.
  AppThemeMode get currentTheme => _currentTheme;

  /// Load the persisted theme mode from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeModeKey);
    _currentTheme =
        stored != null ? AppThemeMode.fromString(stored) : AppThemeMode.system;
  }

  /// Persist and apply a new theme mode.
  Future<void> setTheme(AppThemeMode mode) async {
    _currentTheme = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  /// Convenience: resolve to a Flutter [ThemeMode] from the current selection.
  ThemeMode get themeMode => _currentTheme.toThemeMode();
}

// =============================================================================
// BuildContext Extensions
// =============================================================================

/// Shortcut extensions on [BuildContext] for common theme queries.
extension ThemeContextExtensions on BuildContext {
  /// Whether the app is currently in dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shortcut to [Theme.of(this).colorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shortcut to [Theme.of(this).textTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;
}

// =============================================================================
// Theme Color Constants
// =============================================================================

/// Theme-aware color constants exposed via [BuildContext].
class _AppThemeColors {
  final BuildContext context;
  _AppThemeColors(this.context);

  bool get _isDark => context.isDarkMode;

  static const Color accentColor = Color(0xFF0083FF);

  Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF000000);

  Color get backgroundPrimary =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F2);

  Color get backgroundSecondary =>
      _isDark ? const Color(0xFF2C2C2E) : Colors.white;

  Color get backgroundTertiary =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE6E6E6);

  Color get cardBackground =>
      _isDark ? const Color(0xFF2C2C2E) : Colors.white;

  Color get contentBackground =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F2);

  Color get accent => accentColor;
}

/// Extension to access theme color constants.
extension ThemeColorsExtension on BuildContext {
  _AppThemeColors get themeColors => _AppThemeColors(this);
}

// =============================================================================
// Centralized Theme Definitions
// =============================================================================

/// Centralized theme definitions for the Ziro Fit app.
class AppTheme {
  AppTheme._();

  // -- Brand Colors --
  static const Color _primaryLight = Color(0xFF0083FF); // iOS accent blue
  static const Color _primaryDark = Color(0xFF0083FF); // Static accent
  static const Color _secondaryLight = Color(0xFF3B82F6); // Blue accent
  static const Color _secondaryDark = Color(0xFF60A5FA);
  static const Color _surfaceDark = Color(0xFF2C2C2E); // backgroundSecondary dark
  static const Color _backgroundDark = Color(0xFF1C1C1E); // backgroundPrimary dark

  /// Named emerald color (#10B981) for progress bars / success states.
  static const Color emeraldColor = Color(0xFF10B981);

  // -- Light Theme --
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryLight,
          brightness: Brightness.light,
          secondary: _secondaryLight,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.grey.shade300),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          selectedItemColor: _primaryLight,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: _primaryLight.withValues(alpha: 0.15),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // -- Dark Theme --
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryDark,
          brightness: Brightness.dark,
          secondary: _secondaryDark,
          surface: _surfaceDark,
        ),
        scaffoldBackgroundColor: _backgroundDark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: _backgroundDark,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          color: _surfaceDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.grey.shade600),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: _primaryDark.withValues(alpha: 0.2),
          backgroundColor: _surfaceDark,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
