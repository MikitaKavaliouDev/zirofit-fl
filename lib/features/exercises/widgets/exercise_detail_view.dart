import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_stats_provider.dart';

// =============================================================================
// ExerciseDetailView — Full-screen tabbed exercise detail (About | History |
// Charts | Records), matching the iOS layout from WorkoutExerciseCard.swift.
// =============================================================================

/// A full-screen detail view for an [Exercise] with four tabs:
/// About, History, Charts, and Records.
///
/// Can be used both as a standalone Navigator page (via [show]) or embedded
/// inside a modal bottom sheet.
class ExerciseDetailView extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailView({super.key, required this.exercise});

  /// Pushes this view as a full-screen page route.
  static Future<void> show(BuildContext context, Exercise exercise) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailView(exercise: exercise),
      ),
    );
  }

  @override
  ConsumerState<ExerciseDetailView> createState() =>
      _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends ConsumerState<ExerciseDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = ['About', 'History', 'Charts', 'Records'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Kick off stats fetch so History / Charts / Records have data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseStatsProvider.notifier).fetchExerciseStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.themeColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.themeColors.backgroundPrimary,
        title: Text(
          widget.exercise.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: context.themeColors.accent,
          labelColor: context.themeColors.accent,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'History'),
            Tab(text: 'Charts'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AboutTab(exercise: widget.exercise),
          _HistoryTab(exerciseId: widget.exercise.id),
          _ChartsTab(exerciseId: widget.exercise.id),
          _RecordsTab(exerciseId: widget.exercise.id),
        ],
      ),
    );
  }
}

// =============================================================================
// About Tab
// =============================================================================

class _AboutTab extends StatelessWidget {
  final Exercise exercise;

  const _AboutTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise GIF / Video placeholder ──
          _MediaPlaceholder(
            imageUrl: exercise.imageUrl,
            videoUrl: exercise.videoUrl,
          ),
          const SizedBox(height: 24),

          // ── Info capsules (muscle group, equipment) ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (exercise.muscleGroup != null)
                _InfoCapsule(
                  icon: Icons.fitness_center_outlined,
                  label: exercise.muscleGroup!,
                  color: colors.accent,
                ),
              if (exercise.equipment != null)
                _InfoCapsule(
                  icon: Icons.handyman_outlined,
                  label: exercise.equipment!,
                  color: theme.colorScheme.secondary,
                ),
              if (exercise.category != null)
                _InfoCapsule(
                  icon: Icons.category_outlined,
                  label: exercise.category!,
                  color: theme.colorScheme.tertiary,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Divider ──
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),

          // ── Instructions ──
          Text(
            'Instructions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exercise.description ?? 'No instructions provided for this exercise.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── Details section ──
          if (exercise.recommendedRestSeconds != null ||
              exercise.isUnilateral) ...[
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (exercise.recommendedRestSeconds != null)
              _DetailRow(
                icon: Icons.timer_outlined,
                label: 'Recommended Rest',
                value: '${exercise.recommendedRestSeconds} seconds',
              ),
            if (exercise.isUnilateral)
              _DetailRow(
                icon: Icons.alt_route,
                label: 'Type',
                value: 'Unilateral',
              ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// History Tab
// =============================================================================

class _HistoryTab extends ConsumerWidget {
  final String exerciseId;

  const _HistoryTab({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final statsState = ref.watch(exerciseStatsProvider);

    // Loading state
    if (statsState.isLoading && !statsState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (statsState.error != null && !statsState.isLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48,
                  color: theme.colorScheme.error.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Could not load history',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                statsState.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get data for this exercise
    final lastSession = statsState.lastSessionData[exerciseId];
    final pr = statsState.prByExercise[exerciseId];
    final volume = statsState.volumeByExercise[exerciseId] ?? 0;

    // Empty state
    if (lastSession == null && pr == null) {
      return _EmptyStateView(
        icon: Icons.history,
        message: 'No history found for this exercise yet.',
      );
    }

    // History content
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary stats ──
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Volume',
                value: '${volume.toStringAsFixed(0)} kg',
                icon: Icons.bar_chart_outlined,
                color: colors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Sessions',
                value: '${pr != null ? '1+' : '0'}',
                icon: Icons.fitness_center_outlined,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Last session ──
        if (lastSession != null) ...[
          Text(
            'Last Session',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _HistorySessionCard(
            date: lastSession.date,
            bestWeight: lastSession.bestWeight,
            bestReps: lastSession.bestReps,
            totalVolume: lastSession.totalVolume,
            exerciseName: '',
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(lastSession.date)} — ${lastSession.bestWeight.toStringAsFixed(1)} kg best set',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // ── Personal best ──
        if (pr != null && (lastSession == null ||
            pr.date.isAfter(lastSession.date))) ...[
          const SizedBox(height: 20),
          Text(
            'Personal Best',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _HistorySessionCard(
            date: pr.date,
            bestWeight: pr.maxWeight,
            bestReps: pr.maxReps,
            totalVolume: pr.maxVolume,
            exerciseName: '',
          ),
        ],

        if (lastSession == null && pr != null) ...[
          const SizedBox(height: 20),
          Text(
            'Personal Best',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _HistorySessionCard(
            date: pr.date,
            bestWeight: pr.maxWeight,
            bestReps: pr.maxReps,
            totalVolume: pr.maxVolume,
            exerciseName: '',
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// =============================================================================
// Charts Tab
// =============================================================================

class _ChartsTab extends ConsumerWidget {
  final String exerciseId;

  const _ChartsTab({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final statsState = ref.watch(exerciseStatsProvider);
    final pr = statsState.prByExercise[exerciseId];

    if (statsState.isLoading && !statsState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pr == null) {
      return _EmptyStateView(
        icon: Icons.show_chart,
        message: 'Record at least 2 sessions to see progress charts.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Volume Progression chart placeholder ──
          Text(
            'Volume Progression',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: colors.accent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chart visualization coming soon',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current best volume: ${pr.maxVolume.toStringAsFixed(0)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Quick stats row ──
          Row(
            children: [
              _MiniStat(
                label: 'Best Set',
                value: '${pr.maxWeight.toStringAsFixed(0)} kg × ${pr.maxReps}',
                color: colors.accent,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Total Volume',
                value: '${pr.maxVolume.toStringAsFixed(0)} kg',
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Records Tab
// =============================================================================

class _RecordsTab extends ConsumerWidget {
  final String exerciseId;

  const _RecordsTab({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final statsState = ref.watch(exerciseStatsProvider);

    if (statsState.isLoading && !statsState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final pr = statsState.prByExercise[exerciseId];
    final volume = statsState.volumeByExercise[exerciseId] ?? 0;

    // Empty state - no records yet
    if (pr == null || (pr.maxWeight <= 0 && pr.maxReps <= 0)) {
      return _EmptyStateView(
        icon: Icons.emoji_events_outlined,
        message: 'Complete sets to log your first personal records!',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Estimated 1RM ──
          _RecordCard(
            title: 'Estimated 1RM',
            value: pr.estimated1RM != null
                ? '${pr.estimated1RM!.toStringAsFixed(1)} kg'
                : '—',
            icon: Icons.bolt,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),

          // ── Max Weight ──
          _RecordCard(
            title: 'Max Weight',
            value: '${pr.maxWeight.toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight_outlined,
            color: colors.accent,
          ),
          const SizedBox(height: 12),

          // ── Max Session Volume ──
          _RecordCard(
            title: 'Max Session Volume',
            value: '${pr.maxVolume.toStringAsFixed(0)} kg',
            icon: Icons.stacked_bar_chart,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),

          // ── Total Sessions ──
          _RecordCard(
            title: 'Lifetime Volume',
            value: '${volume.toStringAsFixed(0)} kg',
            icon: Icons.calendar_month_outlined,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// Media placeholder — shows the exercise image, a video/gif placeholder, or
/// a fallback icon when no media is available.
class _MediaPlaceholder extends StatelessWidget {
  final String? imageUrl;
  final String? videoUrl;

  const _MediaPlaceholder({this.imageUrl, this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = imageUrl ?? videoUrl;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      final isVideo = videoUrl != null && videoUrl!.isNotEmpty;
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => _imagePlaceholder(theme),
                errorWidget: (_, _, _) => _imagePlaceholder(theme),
              ),
              if (isVideo)
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_circle_fill,
                        size: 64, color: Colors.white),
                    onPressed: () {
                      final url = Uri.tryParse(videoUrl!);
                      if (url != null) {
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Fallback when no image/video
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.fitness_center,
        size: 60,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.fitness_center,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

/// A capsule-shaped info badge for muscle group / equipment / category.
class _InfoCapsule extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoCapsule({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple icon + label + value detail row.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state with icon + message.
class _EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateView({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary stat card for the History tab header.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// History session card showing date, sets info.
class _HistorySessionCard extends StatelessWidget {
  final DateTime date;
  final double bestWeight;
  final int bestReps;
  final double totalVolume;
  final String exerciseName;

  const _HistorySessionCard({
    required this.date,
    required this.bestWeight,
    required this.bestReps,
    required this.totalVolume,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 16,
                  color: context.themeColors.accent),
              const SizedBox(width: 8),
              Text(
                _formatDate(date),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SetInfo(label: 'Best Set',
                  value: '${bestWeight.toStringAsFixed(0)} kg × $bestReps'),
              const Spacer(),
              _SetInfo(label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SetInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SetInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A personal-record-style card used in the Records tab.
class _RecordCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _RecordCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Mini stat row used in Charts tab.
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
