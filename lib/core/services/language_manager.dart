import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// AppLanguage Enum — 7 supported languages
// =============================================================================

/// Maps language codes to display metadata (iOS parity: en, es, de, fr, pt, it, pl).
enum AppLanguage {
  english('en', '\u{1F1FA}\u{1F1F8}', 'English'),
  spanish('es', '\u{1F1EA}\u{1F1F8}', 'Spanish'),
  german('de', '\u{1F1E9}\u{1F1EA}', 'German'),
  french('fr', '\u{1F1EB}\u{1F1F7}', 'French'),
  portuguese('pt', '\u{1F1F5}\u{1F1F9}', 'Portuguese'),
  italian('it', '\u{1F1EE}\u{1F1F9}', 'Italian'),
  polish('pl', '\u{1F1F5}\u{1F1F1}', 'Polish');

  final String code;
  final String flag;
  final String name;

  const AppLanguage(this.code, this.flag, this.name);

  /// Look up an enum value by its language code. Falls back to English.
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => english,
    );
  }

  /// Resolve [Locale] for MaterialApp.
  Locale get locale => Locale(code);
}

// =============================================================================
// LanguageManager — singleton that persists language preference
// =============================================================================

/// Manages the app's language preference, backed by SharedPreferences.
///
/// Also exposes a [ChangeNotifier] so that MaterialApp can rebuild when the
/// locale changes.
class LanguageManager extends ChangeNotifier {
  static const _kLanguageKey = 'pref_language';

  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => _currentLanguage.locale;

  /// Load persisted language (called once at startup).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLanguageKey) ?? 'en';
    _currentLanguage = AppLanguage.fromCode(code);
    notifyListeners();
  }

  /// Persist a new language code and notify listeners.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _currentLanguage) return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language.code);
    notifyListeners();
  }

  /// Persist by raw code string.
  Future<void> setLanguageCode(String code) async {
    await setLanguage(AppLanguage.fromCode(code));
  }
}

// =============================================================================
// Riverpod Provider
// =============================================================================

final languageManagerProvider = ChangeNotifierProvider<LanguageManager>((ref) {
  return LanguageManager();
});

/// Convenience provider that exposes the current [Locale].
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(languageManagerProvider).currentLocale;
});
