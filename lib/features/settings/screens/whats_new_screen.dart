import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screen that shows "What's New" / release notes for the current version.
///
/// Displays the version number, a list of new features with icons,
/// and a dismiss button that marks the release notes as seen in
/// SharedPreferences.
class WhatsNewScreen extends StatefulWidget {
  final VoidCallback? onDismiss;

  const WhatsNewScreen({super.key, this.onDismiss});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${info.version}';
      });
    } catch (_) {
      setState(() => _version = '');
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final version = _version.isNotEmpty ? _version : 'seen';
    await prefs.setBool('whats_new_seen_$version', true);

    if (mounted) {
      widget.onDismiss?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _dismiss,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.new_releases_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "What's New",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_version.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _version,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Check out the latest features and improvements!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features list
              _buildFeatureItem(
                theme: theme,
                icon: Icons.checklist_outlined,
                title: 'Daily Targets',
                description:
                    'Set and track daily goals for steps, water, calories, '
                    'protein, sleep, and more.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.calendar_month_outlined,
                title: 'Quick Session Add',
                description:
                    'Quickly create workout sessions for your clients '
                    'with templates and scheduling.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.feedback_outlined,
                title: 'In-App Feedback',
                description:
                    'Submit feedback and feature requests directly from the app.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.insights_outlined,
                title: 'Session History',
                description:
                    'View detailed completed session data including '
                    'exercises, sets, reps, and volume.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.settings_outlined,
                title: 'Performance Improvements',
                description:
                    'Faster loading times, smoother animations, '
                    'and various bug fixes.',
              ),

              const SizedBox(height: 40),

              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _dismiss,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Checks whether the current version's release notes have been seen.
  // ignore: unused_element
  static Future<bool> hasBeenSeen() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = 'v${info.version}';
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('whats_new_seen_$version') ?? false;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('whats_new_seen_seen') ?? false;
    }
  }
}
