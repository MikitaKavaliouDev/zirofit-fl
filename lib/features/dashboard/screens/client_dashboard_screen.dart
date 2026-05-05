import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}

class _ClientDashboardScreenState
    extends ConsumerState<ClientDashboardScreen> {
  bool _findCoachDismissed = false;
  bool _checkInBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientDashboardProvider.notifier).fetchDashboard();
      ref.read(clientProgramsProvider.notifier).fetchPrograms();
      ref.read(dailyTargetProvider.notifier).loadTargets(DateTime.now());
      ref.read(workoutHistoryProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(clientDashboardProvider);
    final programsState = ref.watch(clientProgramsProvider);
    final dailyTargetState = ref.watch(dailyTargetProvider);
    final historyState = ref.watch(workoutHistoryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(clientDashboardProvider.notifier).refresh(),
            ref.read(clientProgramsProvider.notifier).fetchPrograms(),
            ref.read(workoutHistoryProvider.notifier).refresh(),
          ]);
          await ref
              .read(dailyTargetProvider.notifier)
              .loadTargets(DateTime.now());
        },
        child: _buildBody(
          theme,
          authState,
          dashboardState,
          programsState,
          dailyTargetState,
          historyState,
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AuthState authState,
    ClientDashboardState dashboardState,
    ClientProgramsState programsState,
    DailyTargetState dailyTargetState,
    WorkoutHistoryState historyState,
  ) {
    if (dashboardState.isLoading && dashboardState.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.hasError && dashboardState.data == null) {
      return _buildErrorState(theme, dashboardState.error!);
    }

    final data = dashboardState.data;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar.large(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                authState.user?.name ?? 'Athlete',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Streak Banner
              if (data.progress.workoutStreak > 0) ...[
                _buildStreakBanner(theme, data.progress.workoutStreak),
                const SizedBox(height: 16),
              ],

              // 2. Coach Card / Find a Coach
              if (data.trainerName != null) ...[
                _buildCoachCard(theme, data.trainerName!),
                const SizedBox(height: 16),
              ] else if (!_findCoachDismissed) ...[
                _buildFindCoachBanner(theme),
                const SizedBox(height: 16),
              ],

              // 3. Check-In Banner (enhanced)
              if (!_checkInBannerDismissed) ...[
                if (data.checkInStatus.isCompleted)
                  _buildCheckInCompleteBanner(theme)
                else if (data.checkInStatus.isDueToday)
                  _buildCheckInPendingBanner(theme)
                else
                  _buildCheckInUpcomingBanner(theme),
                const SizedBox(height: 16),
              ],

              // 4. Active Routine / Program
              if (programsState.activeProgram != null) ...[
                _buildActiveProgramCard(
                  theme,
                  programsState.activeProgram!,
                  programsState.templates,
                ),
                const SizedBox(height: 16),
              ],

              // 5. Upcoming Sessions (horizontal scroll)
              _buildUpcomingSessions(theme, data.upcomingSessions),
              const SizedBox(height: 24),

              // 6. Daily Targets
              _buildDailyTargets(theme, dailyTargetState),
              const SizedBox(height: 24),

              // 7. Quick Actions
              _buildQuickActions(theme, data),
              const SizedBox(height: 24),

              // 8. Last Workout
              _buildSectionHeader(theme, 'Last Workout'),
              const SizedBox(height: 12),
              _buildLastWorkoutCard(theme, data.lastWorkout),
              const SizedBox(height: 24),

              // 9. Progress Summary
              _buildSectionHeader(theme, 'Your Progress'),
              const SizedBox(height: 12),
              _buildProgressCard(theme, data.progress),
              const SizedBox(height: 24),

              // 10. Recent History
              _buildRecentHistory(theme, historyState),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Streak Banner
  // ---------------------------------------------------------------------------

  Widget _buildStreakBanner(ThemeData theme, int streak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "You're on fire! Keep it up.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HOT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Coach Card
  // ---------------------------------------------------------------------------

  Widget _buildCoachCard(ThemeData theme, String trainerName) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // TODO: Navigate to trainer profile
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.blue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trainerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Find a Coach Banner
  // ---------------------------------------------------------------------------

  Widget _buildFindCoachBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to trainer discovery
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need a Coach?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse pro trainers or try our AI.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _findCoachDismissed = true;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Check-In Banners
  // ---------------------------------------------------------------------------

  Widget _buildCheckInPendingBanner(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to check-in screen
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.orange, Color(0xFFE91E63)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Check-in',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your progress with your trainer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCompleteBanner(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _checkInBannerDismissed = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.green,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in Complete',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Great job! Your trainer will review it shortly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInUpcomingBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.checklist,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Check-in is not due yet. Keep up the great work!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active Program Widget
  // ---------------------------------------------------------------------------

  Widget _buildActiveProgramCard(
    ThemeData theme,
    WorkoutProgram program,
    List<WorkoutTemplate> templates,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Program',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        program.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (templates.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: templates.length > 4 ? 4 : templates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _TemplateChip(
                      template: template,
                      onTap: () {
                        // TODO: Start session with this template
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Start session with active program
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upcoming Sessions (horizontal cards)
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingSessions(
    ThemeData theme,
    List<WorkoutSession> sessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Upcoming Sessions'),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming sessions',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trainer will schedule sessions for you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _UpcomingSessionCard(session: sessions[index]);
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Daily Targets
  // ---------------------------------------------------------------------------

  Widget _buildDailyTargets(ThemeData theme, DailyTargetState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Daily Targets'),
        const SizedBox(height: 12),
        if (state.targets.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // TODO: Add daily target
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No daily targets set',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set a Daily Target',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Column(
            children: state.targets.map((target) {
              return _DailyTargetCard(
                target: target,
                onToggle: () {
                  ref
                      .read(dailyTargetProvider.notifier)
                      .toggleCompleted(target.id);
                },
                onDelete: () {
                  ref
                      .read(dailyTargetProvider.notifier)
                      .removeTarget(target.id);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(ThemeData theme, ClientDashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.bolt,
            label: 'Quick Start',
            color: Colors.blue,
            onTap: () {
              // TODO: Quick start workout
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.grid_view_rounded,
            label: 'Templates',
            color: Colors.purple,
            onTap: () {
              // TODO: Browse templates
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recent History
  // ---------------------------------------------------------------------------

  Widget _buildRecentHistory(ThemeData theme, WorkoutHistoryState state) {
    final recentSessions = state.sessions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Recent History'),
        const SizedBox(height: 12),
        if (state.isLoading && recentSessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentSessions.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No workouts logged yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: recentSessions.map((session) {
              return _RecentHistoryTile(session: session);
            }).toList(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(clientDashboardProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLastWorkoutCard(ThemeData theme, LastWorkoutSummary workout) {
    final dateFormat = DateFormat('EEEE, MMM d');
    final durationMinutes = workout.duration.inMinutes;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(workout.date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WorkoutStat(
                  icon: Icons.check_circle_outline,
                  value:
                      '${workout.exercisesCompleted}/${workout.totalExercises}',
                  label: 'Exercises',
                ),
                _WorkoutStat(
                  icon: Icons.timer_outlined,
                  value: '${durationMinutes}m',
                  label: 'Duration',
                ),
                _WorkoutStat(
                  icon: Icons.local_fire_department_outlined,
                  value: '${workout.caloriesBurned}',
                  label: 'Calories',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: workout.exercisesCompleted / workout.totalExercises,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, ProgressSummary progress) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  '${progress.workoutStreak} Day Streak!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(
                    label: 'Weight Change',
                    value:
                        '${progress.weightChange > 0 ? '+' : ''}${progress.weightChange.toStringAsFixed(1)} kg',
                    icon: progress.weightChange < 0
                        ? Icons.trending_down
                        : Icons.trending_up,
                    color: progress.weightChange < 0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ProgressStat(
                    label: 'This Month',
                    value: '${progress.totalWorkoutsThisMonth} workouts',
                    icon: Icons.calendar_month,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (progress.currentWeight != null &&
                progress.startingWeight != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${progress.startingWeight!.toStringAsFixed(1)} kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Current',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${progress.currentWeight!.toStringAsFixed(1)} kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Action Card
// ---------------------------------------------------------------------------

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout Stat
// ---------------------------------------------------------------------------

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WorkoutStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Stat
// ---------------------------------------------------------------------------

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Session Card (horizontal scroll)
// ---------------------------------------------------------------------------

class _UpcomingSessionCard extends StatelessWidget {
  final WorkoutSession session;

  const _UpcomingSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');
    final isTrainerLed = session.isTrainerLed;

    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isTrainerLed ? Colors.blue : Colors.deepPurple,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Navigate to session details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dateFormat.format(session.startTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isTrainerLed ? Icons.person : Icons.self_improvement,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  session.name ?? 'Workout Session',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Template Chip (small horizontal chip for active program)
// ---------------------------------------------------------------------------

class _TemplateChip extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              template.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Target Card
// ---------------------------------------------------------------------------

class _DailyTargetCard extends StatelessWidget {
  final DailyTarget target;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _DailyTargetCard({
    required this.target,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        target.targetValue > 0 ? target.currentValue / target.targetValue : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: target.isCompleted
                      ? Colors.green
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: target.isCompleted
                      ? null
                      : Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: target.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: target.isCompleted ? Colors.green : null,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${target.currentValue.toStringAsFixed(0)} / ${target.targetValue.toStringAsFixed(0)} ${target.unit}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent History Tile
// ---------------------------------------------------------------------------

class _RecentHistoryTile extends StatelessWidget {
  final WorkoutSession session;

  const _RecentHistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM');
    final dayFormat = DateFormat('d');
    final durationText = session.endTime != null
        ? '${session.endTime!.difference(session.startTime).inMinutes} min'
        : 'In progress';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to session details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 44,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateFormat.format(session.startTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      dayFormat.format(session.startTime),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name ?? 'Workout',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durationText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
