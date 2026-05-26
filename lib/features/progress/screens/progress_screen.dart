import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_event_bus.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';
import 'package:zirofit_fl/features/progress/utils/trend_calculator.dart';

import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart' hide VolumePoint;
import 'package:zirofit_fl/features/progress/providers/widget_config_provider.dart';
import 'package:zirofit_fl/features/progress/screens/manage_widgets_screen.dart';
import 'package:zirofit_fl/features/progress/screens/widget_detail_screen.dart';
import 'package:zirofit_fl/features/progress/widgets/activity_heatmap_widget.dart';
import 'package:zirofit_fl/features/progress/widgets/analytics_skeleton.dart';
import 'package:zirofit_fl/features/progress/widgets/consistency_card.dart';
import 'package:zirofit_fl/features/progress/widgets/fitness_goal_card.dart';
import 'package:zirofit_fl/features/progress/widgets/muscle_focus_chart.dart';
import 'package:zirofit_fl/features/progress/widgets/performance_summary_widget.dart';
import 'package:zirofit_fl/features/progress/widgets/personal_insights_card.dart';
import 'package:zirofit_fl/features/progress/widgets/personal_records_list.dart';
import 'package:zirofit_fl/features/progress/widgets/volume_progression_chart.dart';
import 'package:zirofit_fl/features/progress/widgets/weight_history_chart.dart';
import 'package:zirofit_fl/features/progress/widgets/recovery_widget.dart';
import 'package:zirofit_fl/features/progress/widgets/workouts_per_week_chart.dart';
import 'package:zirofit_fl/features/progress/widgets/exercise_progress_widget.dart';

/// Full personal analytics screen replacing the old stub ProgressScreen.
///
/// Mirrors iOS PersonalAnalyticsView with configurable widget grid,
/// performance summary, shimmer loading skeletons, and pull-to-refresh.
class PersonalAnalyticsScreen extends ConsumerStatefulWidget {
  const PersonalAnalyticsScreen({super.key});

  @override
  ConsumerState<PersonalAnalyticsScreen> createState() =>
      _PersonalAnalyticsScreenState();
}

class _PersonalAnalyticsScreenState
    extends ConsumerState<PersonalAnalyticsScreen> {
  bool _initialLoadDone = false;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsEventBus().onWorkoutCompleted.addListener(_onAutoRefresh);
      AnalyticsEventBus().onCheckInSubmitted.addListener(_onAutoRefresh);
    });
  }

  @override
  void dispose() {
    AnalyticsEventBus().onWorkoutCompleted.removeListener(_onAutoRefresh);
    AnalyticsEventBus().onCheckInSubmitted.removeListener(_onAutoRefresh);
    super.dispose();
  }

  Future<void> _onAutoRefresh() async {
    await ref.read(analyticsProvider.notifier).loadAll(days: _selectedDays);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      final state = ref.read(analyticsProvider);
      if (!state.hasData && !state.isLoading) {
        // Defer to after the current frame to avoid modifying provider state
        // during widget tree building, which Riverpod forbids.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(analyticsProvider.notifier).loadAll(days: _selectedDays);
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(analyticsProvider.notifier).loadAll(days: _selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final goalsState = ref.watch(goalsProvider);
    final widgetConfigs = ref.watch(widgetConfigProvider);

    final analytics = analyticsState.analytics;
    final progress = analyticsState.progress;
    final isLoading = analyticsState.isLoading;
    final error = analyticsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Date range segment selector
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '7', label: Text('7D')),
                ButtonSegment(value: '14', label: Text('14D')),
                ButtonSegment(value: '30', label: Text('30D')),
                ButtonSegment(value: '90', label: Text('90D')),
              ],
              selected: {_selectedDays.toString()},
              onSelectionChanged: (value) {
                final days = int.parse(value.first);
                setState(() => _selectedDays = days);
                ref
                    .read(analyticsProvider.notifier)
                    .loadAll(days: days);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Measurements',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Measurements coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Manage Widgets',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageWidgetsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(context, analyticsState, analytics, progress, goalsState,
          widgetConfigs, isLoading, error),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsState analyticsState,
    ClientAnalytics? analytics,
    ClientProgress? progress,
    GoalsState goalsState,
    List<AnalyticsWidgetConfig> widgetConfigs,
    bool isLoading,
    String? error,
  ) {
    // Error state
    if (error != null && !analyticsState.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load analytics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state (no data yet)
    if (isLoading && !analyticsState.hasData) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: AnalyticsSkeleton(),
      );
    }

    // Empty state
    if (!analyticsState.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No analytics data yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete a workout to see your analytics.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Content loaded
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Summary (always shown when data exists)
            if (analytics != null &&
                analytics.volumeHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: PerformanceSummaryWidget(
                  volumeData: analytics.volumeHistory,
                  consistency: analytics.consistency,
                  currentStreak: _calculateStreak(analytics.heatmapDates),
                  longestStreak: _calculateLongestStreak(
                      analytics.heatmapDates),
                  volumeTrend:
                      TrendCalculator.calculateVolumeTrend(
                          analytics.volumeHistory, 0.1, _selectedDays),
                  consistencyTrend: 0,
                  frequencyTrend:
                      TrendCalculator.calculateFrequencyTrend(
                          analytics.volumeHistory, 0.1, _selectedDays),
                  averageVolumeTrend:
                      TrendCalculator.calculateAvgVolumeTrend(
                          analytics.volumeHistory, 0.1, _selectedDays),
                ),
              ),

            // Loading overlay for refresh (data exists, still refreshing)
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),

            // Widgets in configured order
            ...widgetConfigs
                .where((wc) => wc.isVisible)
                .map((wc) => _buildWidgetCard(context, wc, analytics,
                    progress, goalsState, isLoading)),

            // Bottom padding for safe area
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCard(
    BuildContext context,
    AnalyticsWidgetConfig config,
    ClientAnalytics? analytics,
    ClientProgress? progress,
    GoalsState goalsState,
    bool isLoading,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WidgetDetailScreen(
                type: config.type,
                volumeData: analytics?.volumeHistory ?? [],
                muscleData: analytics?.muscleDistribution ?? [],
                prData: analytics?.recentPRs ?? [],
                heatmapDates: analytics?.heatmapDates ?? [],
                consistency: analytics?.consistency.toDouble() ?? 0,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Widget header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.type.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_widgetSubtitle(config.type) != null)
                            Text(
                              _widgetSubtitle(config.type)!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz,
                          color: Colors.grey.shade500, size: 20),
                      onSelected: (value) {
                        if (value == 'remove') {
                          ref
                              .read(widgetConfigProvider.notifier)
                              .removeWidget(config.type);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove Widget'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Trend badge
                if (analytics != null) ...[
                  const SizedBox(height: 6),
                  _buildTrendBadge(config.type, analytics),
                ],
                const SizedBox(height: 12),
                // Widget content
                _buildWidgetContent(context, config.type, analytics,
                    progress, goalsState, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _widgetSubtitle(AnalyticsWidgetType type) {
    switch (type) {
      case AnalyticsWidgetType.workoutsPerWeek:
        return 'Workouts per week';
      case AnalyticsWidgetType.consistency:
        return 'Last 30 days';
      case AnalyticsWidgetType.volumeProgression:
        return null;
      case AnalyticsWidgetType.muscleFocus:
        return null;
      case AnalyticsWidgetType.prs:
        return 'Personal Records';
      case AnalyticsWidgetType.heatMap:
        return 'Activity overview';
      case AnalyticsWidgetType.weightHistory:
        return 'Progress from check-ins';
      case AnalyticsWidgetType.insights:
        return null;
      case AnalyticsWidgetType.goal:
        return null;
      case AnalyticsWidgetType.recovery:
        return null;
      case AnalyticsWidgetType.exerciseProgress:
        return 'Weight & volume trends';
    }
  }

  Widget _buildWidgetContent(
    BuildContext context,
    AnalyticsWidgetType type,
    ClientAnalytics? analytics,
    ClientProgress? progress,
    GoalsState goalsState,
    bool isLoading,
  ) {
    switch (type) {
      case AnalyticsWidgetType.workoutsPerWeek:
        return SizedBox(
          height: 150,
          child: WorkoutsPerWeekChart(
            volumeData: analytics?.volumeHistory ?? [],
          ),
        );

      case AnalyticsWidgetType.consistency:
        return ConsistencyCard(
          consistency: analytics?.consistency.toDouble() ?? 0,
        );

      case AnalyticsWidgetType.volumeProgression:
        return SizedBox(
          height: 180,
          child: VolumeProgressionChart(
            volumeData: analytics?.volumeHistory ?? [],
          ),
        );

      case AnalyticsWidgetType.muscleFocus:
        return const MuscleFocusChart();

      case AnalyticsWidgetType.prs:
        return PersonalRecordsList(
          prs: analytics?.recentPRs ?? [],
          onTapExercise: (exerciseName) =>
              context.push('/movement/$exerciseName'),
        );

      case AnalyticsWidgetType.heatMap:
        return ActivityHeatMapWidget(
          activeDates: analytics?.heatmapDates ?? [],
        );

      case AnalyticsWidgetType.weightHistory:
        return SizedBox(
          height: 180,
          child: WeightHistoryChart(
            weightData: progress?.weight ?? [],
          ),
        );

      case AnalyticsWidgetType.insights:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: PersonalInsightsCard(
            volumeData: analytics?.volumeHistory ?? [],
          ),
        );

      case AnalyticsWidgetType.goal:
        if (goalsState.goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.track_changes,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Set fitness goals to track your progress.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final goals = goalsState.goals;
        return Column(
          children: [
            ...goals.asMap().entries.map((entry) {
              final idx = entry.key;
              final goal = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: idx > 0 ? 16 : 0),
                child: Column(
                  children: [
                    if (idx > 0)
                      const Divider(),
                    FitnessGoalCard(
                      title: goal.type.name.toUpperCase(),
                      subtitle: goal.exerciseName ?? 'Weekly Tracking',
                      currentValue: goal.currentValue,
                      targetValue: goal.targetValue,
                      progress: goal.progress,
                      unitLabel: _goalUnitLabel(goal.type),
                    ),
                  ],
                ),
              );
            }),
            if (goals.length < GoalType.values.length) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Goal setting coming soon')),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Another Goal'),
              ),
            ],
          ],
        );

      case AnalyticsWidgetType.recovery:
        return const RecoveryWidget();

      case AnalyticsWidgetType.exerciseProgress:
        return ExerciseProgressWidget(
          exerciseNames: progress?.exercisePerformance
                  .map((e) => e.exercise)
                  .toList() ??
              [],
          dataPoints: const [],
          isLoading: isLoading,
        );
    }
  }

  String _goalUnitLabel(GoalType type) {
    switch (type) {
      case GoalType.sessions:
        return 'workouts';
      case GoalType.volume:
        return 'kg';
      case GoalType.pr:
        return 'kg';
    }
  }

  /// Computes a trend value and display color for the given widget type.
  ///
  /// Returns `null` for widget types that do not have a meaningful trend.
  /// Positive trends are shown in green, negative in red, zero in grey.
  ({double? value, Color? color})? _computeWidgetTrend(
    AnalyticsWidgetType type,
    ClientAnalytics? analytics,
  ) {
    if (analytics == null) return null;

    double? trendValue;
    switch (type) {
      case AnalyticsWidgetType.volumeProgression:
        trendValue = TrendCalculator.calculateVolumeTrend(
            analytics.volumeHistory, 0, _selectedDays);
        break;
      case AnalyticsWidgetType.workoutsPerWeek:
        trendValue = TrendCalculator.calculateFrequencyTrend(
            analytics.volumeHistory, 0, _selectedDays);
        break;
      case AnalyticsWidgetType.consistency:
        trendValue = TrendCalculator.calculateAvgVolumeTrend(
            analytics.volumeHistory, 0, _selectedDays);
        break;
      default:
        return null;
    }

    if (trendValue == 0) return (value: 0.0, color: Colors.grey);
    return (
      value: trendValue,
      color: trendValue > 0 ? Colors.green : Colors.red,
    );
  }

  /// Builds a small pill-shaped trend badge for the given widget type.
  ///
  /// Mirrors iOS [AnalyticsWidgetContainer]'s trend label styling:
  /// green for positive, red for negative, grey for zero.
  Widget _buildTrendBadge(AnalyticsWidgetType type, ClientAnalytics analytics) {
    final trend = _computeWidgetTrend(type, analytics);
    if (trend == null || trend.value == null) return const SizedBox.shrink();

    final trendStr = trend.value! >= 0
        ? '+${trend.value!.toInt()}%'
        : '${trend.value!.toInt()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trend.color!.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        trendStr,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: trend.color,
        ),
      ),
    );
  }

  // ---- Helper calculations (mirroring iOS logic) ----

  int _calculateStreak(List<String> heatmapDates) {
    if (heatmapDates.isEmpty) return 0;
    final sorted = heatmapDates
        .map((d) => DateTime.tryParse(d))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    int streak = 0;
    final now = DateTime.now();
    var expected = DateTime(now.year, now.month, now.day);

    for (final date in sorted) {
      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized == expected ||
          (streak == 0 &&
              normalized == expected.subtract(const Duration(days: 1)))) {
        if (streak == 0 && normalized == expected.subtract(const Duration(days: 1))) {
          // Workout was yesterday, streak starts from yesterday
        }
        streak++;
        expected = normalized.subtract(const Duration(days: 1));
      } else if (normalized.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<String> heatmapDates) {
    if (heatmapDates.isEmpty) return 0;
    final sorted = heatmapDates
        .map((d) => DateTime.tryParse(d))
        .whereType<DateTime>()
        .toList()
      ..sort();

    int longest = 0;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
      } else {
        longest = current > longest ? current : longest;
        current = 1;
      }
    }
    longest = current > longest ? current : longest;
    return longest;
  }


}
