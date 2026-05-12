import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// App Language Enum
// =============================================================================

/// Supported languages with ISO code, flag emoji, and display name.
/// Superset merging iOS (EN, ES, DE, FR, PT, IT, PL) with existing
/// onboarding languages (EN, ES, FR, DE, PT, IT, JA, ZH).
enum AppLanguage {
  english('en', '\u{1F1FA}\u{1F1F8}', 'English'),
  spanish('es', '\u{1F1EA}\u{1F1F8}', 'Spanish'),
  french('fr', '\u{1F1EB}\u{1F1F7}', 'French'),
  german('de', '\u{1F1E9}\u{1F1EA}', 'German'),
  portuguese('pt', '\u{1F1F5}\u{1F1F9}', 'Portuguese'),
  italian('it', '\u{1F1EE}\u{1F1F9}', 'Italian'),
  polish('pl', '\u{1F1F5}\u{1F1F1}', 'Polish'),
  japanese('ja', '\u{1F1EF}\u{1F1F5}', 'Japanese'),
  chinese('zh', '\u{1F1E8}\u{1F1F3}', 'Chinese');

  /// ISO 639-1 language code (e.g. 'en', 'es', 'pl').
  final String code;

  /// Flag emoji string (e.g. '\u{1F1FA}\u{1F1F8}' for US flag).
  final String flag;

  /// English display name (e.g. 'English', 'Spanish').
  final String name;

  const AppLanguage(this.code, this.flag, this.name);

  /// Look up an [AppLanguage] by its ISO [code].
  /// Returns [english] as fallback when not found.
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => english,
    );
  }
}

// =============================================================================
// Language Manager
// =============================================================================

/// Persists the user's language preference via SharedPreferences (iOS parity).
class LanguageManager {
  static const _kLanguageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.english;

  /// Currently selected language.
  AppLanguage get currentLanguage => _currentLanguage;

  /// Load the persisted language from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLanguageKey);
    _currentLanguage =
        stored != null ? AppLanguage.fromCode(stored) : AppLanguage.english;
  }

  /// Persist and apply a new language.
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language.code);
  }

  /// Look up a localized string for the current language.
  /// Falls back to the [defaultLanguage] (English) if no translation exists.
  String localize(String key, {AppLanguage? defaultLanguage}) {
    final fallback = defaultLanguage ?? AppLanguage.english;
    final translationMap = _translations[key];

    if (translationMap == null) return key;

    return translationMap[_currentLanguage.code] ??
        translationMap[fallback.code] ??
        key;
  }
}

// =============================================================================
// Built-in Translations Map
// =============================================================================
//
// Format: Map<english_key, Map<language_code, translated_string>>
//
// To add a new string add it to _baseTranslations below.
// The [LanguageManager.localize] method looks up by current language code.

const Map<String, Map<String, String>> _translations = {
  // -- General --
  'cancel': {
    'en': 'Cancel',
    'es': 'Cancelar',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'pt': 'Cancelar',
    'it': 'Annulla',
    'pl': 'Anuluj',
    'ja': 'キャンセル',
    'zh': '取消',
  },
  'save': {
    'en': 'Save',
    'es': 'Guardar',
    'fr': 'Enregistrer',
    'de': 'Speichern',
    'pt': 'Salvar',
    'it': 'Salva',
    'pl': 'Zapisz',
    'ja': '保存',
    'zh': '保存',
  },
  'delete': {
    'en': 'Delete',
    'es': 'Eliminar',
    'fr': 'Supprimer',
    'de': 'Löschen',
    'pt': 'Excluir',
    'it': 'Elimina',
    'pl': 'Usuń',
    'ja': '削除',
    'zh': '删除',
  },
  'confirm': {
    'en': 'Confirm',
    'es': 'Confirmar',
    'fr': 'Confirmer',
    'de': 'Bestätigen',
    'pt': 'Confirmar',
    'it': 'Conferma',
    'pl': 'Potwierdź',
    'ja': '確認',
    'zh': '确认',
  },
  'settings': {
    'en': 'Settings',
    'es': 'Ajustes',
    'fr': 'Paramètres',
    'de': 'Einstellungen',
    'pt': 'Configurações',
    'it': 'Impostazioni',
    'pl': 'Ustawienia',
    'ja': '設定',
    'zh': '设置',
  },
  'language': {
    'en': 'Language',
    'es': 'Idioma',
    'fr': 'Langue',
    'de': 'Sprache',
    'pt': 'Idioma',
    'it': 'Lingua',
    'pl': 'Język',
    'ja': '言語',
    'zh': '语言',
  },
  'theme': {
    'en': 'Theme',
    'es': 'Tema',
    'fr': 'Thème',
    'de': 'Design',
    'pt': 'Tema',
    'it': 'Tema',
    'pl': 'Motyw',
    'ja': 'テーマ',
    'zh': '主题',
  },
  'light': {
    'en': 'Light',
    'es': 'Claro',
    'fr': 'Clair',
    'de': 'Hell',
    'pt': 'Claro',
    'it': 'Chiaro',
    'pl': 'Jasny',
    'ja': 'ライト',
    'zh': '浅色',
  },
  'dark': {
    'en': 'Dark',
    'es': 'Oscuro',
    'fr': 'Sombre',
    'de': 'Dunkel',
    'pt': 'Escuro',
    'it': 'Scuro',
    'pl': 'Ciemny',
    'ja': 'ダーク',
    'zh': '深色',
  },
  'system': {
    'en': 'System',
    'es': 'Sistema',
    'fr': 'Système',
    'de': 'System',
    'pt': 'Sistema',
    'it': 'Sistema',
    'pl': 'System',
    'ja': 'システム',
    'zh': '跟随系统',
  },
  'ok': {
    'en': 'OK',
    'es': 'OK',
    'fr': 'OK',
    'de': 'OK',
    'pt': 'OK',
    'it': 'OK',
    'pl': 'OK',
    'ja': 'OK',
    'zh': '确定',
  },
  'error': {
    'en': 'Error',
    'es': 'Error',
    'fr': 'Erreur',
    'de': 'Fehler',
    'pt': 'Erro',
    'it': 'Errore',
    'pl': 'Błąd',
    'ja': 'エラー',
    'zh': '错误',
  },
  'loading': {
    'en': 'Loading...',
    'es': 'Cargando...',
    'fr': 'Chargement...',
    'de': 'Laden...',
    'pt': 'Carregando...',
    'it': 'Caricamento...',
    'pl': 'Ładowanie...',
    'ja': '読み込み中...',
    'zh': '加载中...',
  },
  'no_internet': {
    'en': 'No internet connection',
    'es': 'Sin conexión a internet',
    'fr': 'Pas de connexion internet',
    'de': 'Keine Internetverbindung',
    'pt': 'Sem conexão com a internet',
    'it': 'Nessuna connessione internet',
    'pl': 'Brak połączenia z internetem',
    'ja': 'インターネット接続がありません',
    'zh': '没有网络连接',
  },
  'retry': {
    'en': 'Retry',
    'es': 'Reintentar',
    'fr': 'Réessayer',
    'de': 'Wiederholen',
    'pt': 'Tentar novamente',
    'it': 'Riprova',
    'pl': 'Spróbuj ponownie',
    'ja': '再試行',
    'zh': '重试',
  },
};
