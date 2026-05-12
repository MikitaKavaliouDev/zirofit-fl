import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

enum _FeatureCategory { new_, improved, fixed }

enum _FeatureScope {
  workoutTracking,
  clientManagement,
  progressAnalytics,
  trainerTools,
  performance,
  general,
}

/// A single feature entry within a release version.
class _ReleaseFeature {
  final String title;
  final String description;
  final _FeatureCategory category;
  final _FeatureScope scope;

  const _ReleaseFeature({
    required this.title,
    required this.description,
    required this.category,
    required this.scope,
  });

  IconData get icon {
    return switch (scope) {
      _FeatureScope.workoutTracking => Icons.fitness_center_outlined,
      _FeatureScope.clientManagement => Icons.people_outlined,
      _FeatureScope.progressAnalytics => Icons.trending_up_outlined,
      _FeatureScope.trainerTools => Icons.build_outlined,
      _FeatureScope.performance => Icons.bolt_outlined,
      _FeatureScope.general => Icons.star_outlined,
    };
  }

  String get categoryLabel {
    return switch (category) {
      _FeatureCategory.new_ => 'New',
      _FeatureCategory.improved => 'Improved',
      _FeatureCategory.fixed => 'Fixed',
    };
  }

  Color categoryColor(ThemeData theme) {
    return switch (category) {
      _FeatureCategory.new_ => theme.colorScheme.primary,
      _FeatureCategory.improved => theme.colorScheme.tertiary,
      _FeatureCategory.fixed => theme.colorScheme.secondary,
    };
  }

  Color categoryBackground(ThemeData theme) {
    return switch (category) {
      _FeatureCategory.new_ => theme.colorScheme.primaryContainer,
      _FeatureCategory.improved => theme.colorScheme.tertiaryContainer,
      _FeatureCategory.fixed => theme.colorScheme.secondaryContainer,
    };
  }
}

/// A single release version with its features and metadata.
class _ReleaseVersion {
  final String version;
  final DateTime date;
  final String title;
  final List<_ReleaseFeature> features;
  final bool isCurrent;

  const _ReleaseVersion({
    required this.version,
    required this.date,
    required this.title,
    required this.features,
    this.isCurrent = false,
  });
}

// ---------------------------------------------------------------------------
// Release Data
// ---------------------------------------------------------------------------

/// The complete release history. The first entry is treated as the current
/// version and gets special visual treatment.
List<_ReleaseVersion> _releaseHistory(String currentVersion) {
  return [
    _ReleaseVersion(
      version: currentVersion,
      date: DateTime(2026, 5, 10),
      title: 'Smart Tracking & Insights',
      isCurrent: true,
      features: const [
        _ReleaseFeature(
          category: _FeatureCategory.new_,
          scope: _FeatureScope.workoutTracking,
          title: 'Daily Targets',
          description:
              'Set and track daily goals for steps, water, calories, protein, sleep, and more at a glance.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.new_,
          scope: _FeatureScope.clientManagement,
          title: 'Quick Session Add',
          description:
              'Create workout sessions for clients instantly with smart templates and one-tap scheduling.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.improved,
          scope: _FeatureScope.progressAnalytics,
          title: 'Session History',
          description:
              'View detailed completed session data including exercises, sets, reps, volume, and progress trends.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.new_,
          scope: _FeatureScope.general,
          title: 'In-App Feedback',
          description:
              'Submit feedback and feature requests directly from the app to help shape future updates.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.improved,
          scope: _FeatureScope.performance,
          title: 'Performance Improvements',
          description:
              'Faster loading times, smoother animations, and various stability fixes throughout the app.',
        ),
      ],
    ),
    _ReleaseVersion(
      version: '1.0.3',
      date: DateTime(2026, 4, 22),
      title: 'Calendar & Connectivity',
      features: const [
        _ReleaseFeature(
          category: _FeatureCategory.new_,
          scope: _FeatureScope.trainerTools,
          title: 'Calendar Sync',
          description:
              'Two-way sync with Apple Calendar and Google Calendar for seamless session scheduling.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.improved,
          scope: _FeatureScope.clientManagement,
          title: 'Client Check-Ins',
          description:
              'Redesigned check-in flow with customizable templates and automated reminders.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.fixed,
          scope: _FeatureScope.performance,
          title: 'Offline Reliability',
          description:
              'Improved offline queue handling with better conflict resolution when connectivity resumes.',
        ),
      ],
    ),
    _ReleaseVersion(
      version: '1.0.2',
      date: DateTime(2026, 4, 8),
      title: 'Analytics & Reporting',
      features: const [
        _ReleaseFeature(
          category: _FeatureCategory.new_,
          scope: _FeatureScope.progressAnalytics,
          title: 'Progress Charts',
          description:
              'Interactive charts showing client progress over time with customizable date ranges and metrics.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.improved,
          scope: _FeatureScope.workoutTracking,
          title: 'Exercise Library',
          description:
              'Expanded exercise library with video demonstrations and detailed form instructions.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.fixed,
          scope: _FeatureScope.general,
          title: 'UI Refinements',
          description:
              'Polished navigation, improved empty states, and better accessibility throughout the app.',
        ),
      ],
    ),
    _ReleaseVersion(
      version: '1.0.1',
      date: DateTime(2026, 3, 20),
      title: 'Launch Improvements',
      features: const [
        _ReleaseFeature(
          category: _FeatureCategory.improved,
          scope: _FeatureScope.trainerTools,
          title: 'Client Onboarding',
          description:
              'Streamlined client intake process with digital waivers and automated welcome messages.',
        ),
        _ReleaseFeature(
          category: _FeatureCategory.fixed,
          scope: _FeatureScope.performance,
          title: 'Bug Fixes',
          description:
              'Fixed crash on workout completion, resolved sync conflicts, and improved notification delivery.',
        ),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// What's New Screen
// ---------------------------------------------------------------------------

/// An enhanced "What's New" / release notes screen with version history
/// timeline, categorized feature highlights, and "New" badges.
///
/// Displays the current version's features prominently followed by a
/// scrollable history of previous releases. Each version card includes
/// release date, feature category chips, and scope-based icons.
///
/// Uses [SharedPreferences] to track whether release notes have been seen
/// for the current app version.
class WhatsNewScreen extends StatefulWidget {
  final VoidCallback? onDismiss;

  const WhatsNewScreen({super.key, this.onDismiss});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();

  /// Checks whether the current version's release notes have been seen.
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

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  String _version = '';
  bool _showAllVersions = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _version = '');
      }
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
    final releases = _releaseHistory(_version.isNotEmpty ? _version : '1.0.4');
    final currentRelease = releases.first;
    final previousReleases = releases.skip(1).toList();
    final displayedPrevious = _showAllVersions
        ? previousReleases
        : previousReleases.take(2).toList();

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Section ────────────────────────────────────────
              _HeroSection(
                version: _version,
                releaseTitle: currentRelease.title,
              ),
              const SizedBox(height: 28),

              // ── Current Version Features ────────────────────────────
              const _SectionLabel(
                label: 'Latest Features',
                icon: Icons.auto_awesome,
              ),
              const SizedBox(height: 12),
              ...currentRelease.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FeatureCard(feature: feature),
                ),
              ),

              // ── Previous Versions ───────────────────────────────────
              if (previousReleases.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    const _SectionLabel(
                      label: 'Previous Updates',
                      icon: Icons.history,
                    ),
                    const Spacer(),
                    if (!_showAllVersions && previousReleases.length > 2)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showAllVersions = true);
                        },
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: const Text('Show all'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Timeline
                Stack(
                  children: [
                    // Timeline connector line
                    Positioned(
                      left: 15,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: 2,
                        child: Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    Column(
                      children:
                          displayedPrevious.asMap().entries.map((entry) {
                        final index = entry.key;
                        final release = entry.value;
                        final isLast =
                            index == displayedPrevious.length - 1 &&
                                !_showAllVersions;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 16,
                          ),
                          child: _VersionTimelineCard(
                            release: release,
                            isLast: isLast,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // "Show more" at bottom of timeline
                if (!_showAllVersions && previousReleases.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _showAllVersions = true);
                        },
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text(
                          'Show ${previousReleases.length - 2} more '
                          'update${previousReleases.length - 2 == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 36),

              // ── Dismiss Button ──────────────────────────────────────
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
}

// ---------------------------------------------------------------------------
// Hero Section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final String version;
  final String releaseTitle;

  const _HeroSection({
    required this.version,
    required this.releaseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // App icon with pulse ring
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring decoration
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer,
                    width: 2,
                  ),
                ),
              ),
              // Inner icon circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.new_releases_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          "What's New",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        // Version badge + NEW pill
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (version.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  version,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),

        // Release title
        const SizedBox(height: 8),
        Text(
          releaseTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle
        const SizedBox(height: 4),
        Text(
          'Check out the latest features and improvements.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section Label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Card
// ---------------------------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  final _ReleaseFeature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: feature.categoryBackground(theme)
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature.icon,
                size: 22,
                color: feature.categoryColor(theme),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: feature.categoryBackground(theme)
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          feature.categoryLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: feature.categoryColor(theme),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Version Timeline Card
// ---------------------------------------------------------------------------

class _VersionTimelineCard extends StatelessWidget {
  final _ReleaseVersion release;
  final bool isLast;

  const _VersionTimelineCard({
    required this.release,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted = DateFormat.MMMd().format(release.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.outlineVariant,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          // Card content
          Expanded(
            child: Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Version + date
                    Row(
                      children: [
                        Text(
                          release.version,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateFormatted,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (release.title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        release.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (release.features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      ...release.features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                feature.icon,
                                size: 16,
                                color: feature.categoryColor(theme),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature.title,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
