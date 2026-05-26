import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/services/language_manager.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// Language Settings Screen
// ---------------------------------------------------------------------------

/// Displays a list of available languages with flag icons and a checkmark
/// on the currently selected language. Tapping a language immediately
/// persists the choice via [preferencesProvider] and [LanguageManager].
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
                for (final language in AppLanguage.values) ...[
                  if (language != AppLanguage.values.first)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  _LanguageTile(
                    language: language,
                    isSelected: language.code == currentLanguage,
                    onTap: () {
                      // Persist via preferences provider
                      ref
                          .read(preferencesProvider.notifier)
                          .setLanguage(language.code);
                      // Also update the LanguageManager for immediate locale effect
                      ref
                          .read(languageManagerProvider.notifier)
                          .setLanguage(language);
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
  final AppLanguage language;
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
