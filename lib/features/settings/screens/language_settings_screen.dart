import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// Language Picker Enum
// ---------------------------------------------------------------------------

/// Maps language codes to display metadata for the language picker.
enum AppLanguagePicker {
  english('en', '\u{1F1FA}\u{1F1F8}', 'English'),
  spanish('es', '\u{1F1EA}\u{1F1F8}', 'Spanish'),
  french('fr', '\u{1F1EB}\u{1F1F7}', 'French'),
  german('de', '\u{1F1E9}\u{1F1EA}', 'German'),
  portuguese('pt', '\u{1F1F5}\u{1F1F9}', 'Portuguese'),
  italian('it', '\u{1F1EE}\u{1F1F9}', 'Italian'),
  japanese('ja', '\u{1F1EF}\u{1F1F5}', 'Japanese'),
  chinese('zh', '\u{1F1E8}\u{1F1F3}', 'Chinese');

  final String code;
  final String flag;
  final String name;

  const AppLanguagePicker(this.code, this.flag, this.name);

  /// Look up an enum value by its language code.
  static AppLanguagePicker fromCode(String code) {
    return AppLanguagePicker.values.firstWhere(
      (l) => l.code == code,
      orElse: () => english,
    );
  }
}

// ---------------------------------------------------------------------------
// Language Settings Screen
// ---------------------------------------------------------------------------

/// Displays a list of available languages with flag icons and a checkmark
/// on the currently selected language. Tapping a language immediately
/// persists the choice via [preferencesProvider].
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    final currentLanguage = preferences.language;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Selection list in a single grouped Card (iOS-style)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final language in AppLanguagePicker.values) ...[
                  if (language != AppLanguagePicker.values.first)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  _LanguageTile(
                    language: language,
                    isSelected: language.code == currentLanguage,
                    onTap: () {
                      ref
                          .read(preferencesProvider.notifier)
                          .setLanguage(language.code);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Hint text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Changing the language will update the app interface text.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language Tile
// ---------------------------------------------------------------------------

class _LanguageTile extends StatelessWidget {
  final AppLanguagePicker language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Flag
            Text(
              language.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            // Language name
            Expanded(
              child: Text(
                language.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
            // Checkmark for selected language
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
