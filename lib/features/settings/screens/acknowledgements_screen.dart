import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Acknowledgements Screen
// ---------------------------------------------------------------------------

/// Displays open-source library licenses, data attribution, and app version.
///
/// Mirrors the iOS `AcknowledgementsView` from the original Ziro Fit codebase.
class AcknowledgementsScreen extends ConsumerStatefulWidget {
  const AcknowledgementsScreen({super.key});

  @override
  ConsumerState<AcknowledgementsScreen> createState() =>
      _AcknowledgementsScreenState();
}

class _AcknowledgementsScreenState
    extends ConsumerState<AcknowledgementsScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVersion());
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {
      // Silently ignore if version can't be loaded
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acknowledgements'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------------
            // Open Source Libraries
            // ---------------------------------------------------------------
            const _SectionHeader(
              icon: Icons.auto_awesome,
              title: 'Open Source Libraries',
            ),
            const SizedBox(height: 12),

            _AcknowledgementCard(
              name: 'Flutter',
              description: 'UI framework by Google ● BSD-3-Clause',
              url: 'https://flutter.dev',
              onTap: () => _launchUrl('https://flutter.dev'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Supabase Flutter',
              description: 'Backend-as-a-Service client ● MIT',
              url: 'https://supabase.com/docs/reference/dart',
              onTap: () =>
                  _launchUrl('https://supabase.com/docs/reference/dart'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Riverpod',
              description: 'State management ● MIT',
              url: 'https://riverpod.dev',
              onTap: () => _launchUrl('https://riverpod.dev'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'GoRouter',
              description: 'Declarative routing ● MIT',
              url: 'https://pub.dev/packages/go_router',
              onTap: () => _launchUrl('https://pub.dev/packages/go_router'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Drift',
              description: 'Local database (SQLite ORM) ● MIT',
              url: 'https://drift.one',
              onTap: () => _launchUrl('https://drift.one'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Dio',
              description: 'HTTP networking library ● MIT',
              url: 'https://pub.dev/packages/dio',
              onTap: () => _launchUrl('https://pub.dev/packages/dio'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Google Sign-In',
              description: 'Google authentication ● Apache-2.0',
              url: 'https://pub.dev/packages/google_sign_in',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/google_sign_in'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Firebase',
              description: 'Core & Cloud Messaging ● Apache-2.0',
              url: 'https://firebase.flutter.dev',
              onTap: () => _launchUrl('https://firebase.flutter.dev'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Flutter Secure Storage',
              description: 'Encrypted data persistence ● BSD-3-Clause',
              url: 'https://pub.dev/packages/flutter_secure_storage',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/flutter_secure_storage'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'fl_chart',
              description: 'Beautiful charts & graphs ● MIT',
              url: 'https://pub.dev/packages/fl_chart',
              onTap: () => _launchUrl('https://pub.dev/packages/fl_chart'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Cached Network Image',
              description: 'Image loading & caching ● MIT',
              url: 'https://pub.dev/packages/cached_network_image',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/cached_network_image'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Shimmer',
              description: 'Loading placeholder effects ● MIT',
              url: 'https://pub.dev/packages/shimmer',
              onTap: () => _launchUrl('https://pub.dev/packages/shimmer'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'flutter_map',
              description: 'OpenStreetMap mapping ● BSD-3-Clause',
              url: 'https://pub.dev/packages/flutter_map',
              onTap: () => _launchUrl('https://pub.dev/packages/flutter_map'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Connectivity Plus',
              description: 'Network connectivity monitoring ● BSD-3-Clause',
              url: 'https://pub.dev/packages/connectivity_plus',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/connectivity_plus'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Freezed',
              description: 'Code generation for data classes ● MIT',
              url: 'https://pub.dev/packages/freezed',
              onTap: () => _launchUrl('https://pub.dev/packages/freezed'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Image Picker',
              description: 'Camera & gallery access ● BSD-3-Clause',
              url: 'https://pub.dev/packages/image_picker',
              onTap: () => _launchUrl('https://pub.dev/packages/image_picker'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'flutter_tts',
              description: 'Text-to-speech engine ● MIT',
              url: 'https://pub.dev/packages/flutter_tts',
              onTap: () => _launchUrl('https://pub.dev/packages/flutter_tts'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Permission Handler',
              description: 'Cross-platform permissions ● MIT',
              url: 'https://pub.dev/packages/permission_handler',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/permission_handler'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Intl',
              description: 'Internationalization & formatting ● BSD-3-Clause',
              url: 'https://pub.dev/packages/intl',
              onTap: () => _launchUrl('https://pub.dev/packages/intl'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Speech to Text',
              description: 'Voice recognition engine ● MIT',
              url: 'https://pub.dev/packages/speech_to_text',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/speech_to_text'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'URL Launcher',
              description: 'Open external links & apps ● BSD-3-Clause',
              url: 'https://pub.dev/packages/url_launcher',
              onTap: () => _launchUrl('https://pub.dev/packages/url_launcher'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Shared Preferences',
              description: 'Simple key-value storage ● BSD-3-Clause',
              url: 'https://pub.dev/packages/shared_preferences',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/shared_preferences'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'UUID',
              description: 'Universally unique identifiers ● MIT',
              url: 'https://pub.dev/packages/uuid',
              onTap: () => _launchUrl('https://pub.dev/packages/uuid'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'Device Calendar',
              description: 'Calendar integration ● MIT',
              url: 'https://pub.dev/packages/device_calendar',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/device_calendar'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'App Links',
              description: 'Deep link handling ● MIT',
              url: 'https://pub.dev/packages/app_links',
              onTap: () => _launchUrl('https://pub.dev/packages/app_links'),
            ),
            const SizedBox(height: 8),

            _AcknowledgementCard(
              name: 'JSON Serializable',
              description: 'JSON code generation ● BSD-3-Clause',
              url: 'https://pub.dev/packages/json_serializable',
              onTap: () =>
                  _launchUrl('https://pub.dev/packages/json_serializable'),
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Data Attribution
            // ---------------------------------------------------------------
            const _SectionHeader(
              icon: Icons.attribution,
              title: 'Data Attribution',
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ExerciseDB
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ExerciseDB',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Comprehensive exercise database '
                                'by Justinas Stankevičius.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _launchUrl(
                                  'https://exercisedb.io',
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.open_in_new,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'exercisedb.io',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    // WGER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.fitness_center_outlined,
                            size: 22,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WGER Workout Manager',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Open-source exercise and workout data.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () =>
                                    _launchUrl('https://wger.de'),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.open_in_new,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'wger.de',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ---------------------------------------------------------------
            // Version Footer
            // ---------------------------------------------------------------
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _appVersion != null
                        ? 'Ziro Fit v$_appVersion'
                        : 'Ziro Fit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for fitness professionals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Acknowledgement Card
// ---------------------------------------------------------------------------

class _AcknowledgementCard extends StatelessWidget {
  final String name;
  final String description;
  final String url;
  final VoidCallback onTap;

  const _AcknowledgementCard({
    required this.name,
    required this.description,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.code,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.open_in_new,
            size: 18,
            color: colorScheme.primary,
          ),
          onPressed: onTap,
          tooltip: 'Open $url',
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),
    );
  }
}
