import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/completed_session_detail_screen.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/quick_weight_log.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/workout_templates_screen.dart';
import 'package:zirofit_fl/features/programs/screens/my_routines_screen.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/shared/widgets/ziro_data_view.dart';
import 'package:zirofit_fl/features/clients/widgets/trainer_details_bottom_sheet.dart';
import 'package:zirofit_fl/features/dashboard/widgets/recent_workout_row.dart';

/// SharedPreferences key for the educational overlay.
const _kEducationOverlayKey = 'dashboard_education_seen';

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
  bool _showEducationOverlay = false;
  bool _educationOverlayLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Note: clientDashboardProvider auto-fetches via AsyncNotifier
      // Only need to fetch other providers that don't use AsyncValue pattern yet
      ref.read(clientProgramsProvider.notifier).fetchPrograms();
      ref.read(dailyTargetProvider.notifier).loadTargets(DateTime.now());
      ref.read(workoutHistoryProvider.notifier).fetchHistory();
      _checkEducationOverlay();
    });
  }

  Future<void> _checkEducationOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_kEducationOverlayKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showEducationOverlay = !seen;
      _educationOverlayLoaded = true;
    });
  }

  Future<void> _dismissEducationOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEducationOverlayKey, true);
    if (!mounted) return;
    setState(() {
      _showEducationOverlay = false;
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              // Invalidate triggers refetch for AsyncNotifier providers
              ref.invalidate(clientDashboardProvider);
              await Future.wait([
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
          if (_showEducationOverlay && _educationOverlayLoaded)
            _buildEducationOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AuthState authState,
    AsyncValue<ClientDashboardData> dashboardState,
    ClientProgramsState programsState,
    DailyTargetState dailyTargetState,
    WorkoutHistoryState historyState,
  ) {
    return ZiroDataView<ClientDashboardData>(
      state: dashboardState,
      onRetry: () => ref.invalidate(clientDashboardProvider),
      dataBuilder: (data) => _buildDashboardContent(
        theme,
        authState,
        data,
        programsState,
        dailyTargetState,
        historyState,
      ),
    );
  }

  Widget _buildDashboardContent(
    ThemeData theme,
    AuthState authState,
    ClientDashboardData data,
    ClientProgramsState programsState,
    DailyTargetState dailyTargetState,
    WorkoutHistoryState historyState,
  ) {
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
                context.push('/client/notifications');
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

              // 2. Quick Actions
              _buildQuickActions(theme, data),
              const SizedBox(height: 24),

              // 3. Quick Weight Log
              const QuickWeightLogWidget(),
              const SizedBox(height: 16),

              // 4. Coach Card / Find a Coach
              if (data.trainerName != null) ...[
                _buildCoachCard(theme, data.trainerName!),
                const SizedBox(height: 16),
              ] else if (!_findCoachDismissed) ...[
                _buildFindCoachBanner(theme),
                const SizedBox(height: 16),
              ],

              // 5. Check-In Banner (enhanced)
              if (!_checkInBannerDismissed) ...[
                if (data.checkInStatus.isCompleted)
                  _buildCheckInCompleteBanner(theme)
                else if (data.checkInStatus.isDueToday)
                  _buildCheckInPendingBanner(theme)
                else
                  _buildCheckInUpcomingBanner(theme),
                const SizedBox(height: 16),
              ],

              // 6. Active Routine / Program
              if (programsState.activeProgramResponse != null) ...[
                _buildActiveProgramCard(
                  theme,
                  programsState.activeProgramResponse!,
                ),
                const SizedBox(height: 16),
              ],

              // 7. Upcoming Sessions (horizontal scroll)
              _buildUpcomingSessions(theme, data.upcomingSessions),
              const SizedBox(height: 24),

              // 8. Daily Targets
              _buildDailyTargets(theme, dailyTargetState),
              const SizedBox(height: 24),

              // 9. Last Workout
              _buildSectionHeader(theme, 'Last Workout'),
              const SizedBox(height: 12),
              _buildLastWorkoutCard(theme, data.lastWorkout),
              const SizedBox(height: 24),

              // 10. Progress Summary
              _buildSectionHeader(theme, 'Your Progress'),
              const SizedBox(height: 12),
              _buildProgressCard(theme, data.progress),
              const SizedBox(height: 24),

              // 11. Recent History
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
          TrainerDetailsBottomSheet.show(context);
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
                TrainerDetailsBottomSheet.show(context);
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
        context.go('/client/check-in');
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.green,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    _checkInBannerDismissed = true;
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                context.push('/client/check-in/history');
              },
              icon: const Icon(Icons.history, color: Colors.white, size: 18),
              label: Text(
                'View History',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
    ActiveProgramResponse activeResponse,
  ) {
    final program = activeResponse.program;
    final templates = activeResponse.templates;
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
                    return _ActiveTemplateChip(
                      name: template.name,
                      onTap: () {
                        context.go('/client/workout');
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
                  context.go('/client/workout');
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
                final session = sessions[index];
                return _UpcomingSessionCard(
                  session: session,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CompletedSessionDetailScreen(
                          sessionId: session.id,
                        ),
                      ),
                    );
                  },
                );
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
                context.push('/client/daily-targets');
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
  // Quick Actions: Quick Start, Templates, Programs
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(ThemeData theme, ClientDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bolt,
                label: 'Quick Start',
                subtitle: 'Empty session',
                color: Colors.blue,
                onTap: () async {
                  await ref.read(activeWorkoutProvider.notifier).startWorkout();
                  if (context.mounted) {
                    context.go('/client/workout');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.grid_view_rounded,
                label: 'Templates',
                subtitle: 'Pre-built workouts',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkoutTemplatesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.fitness_center_outlined,
                label: 'Programs',
                subtitle: 'My routines',
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyRoutinesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
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
              return RecentWorkoutRow(
                session: session,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompletedSessionDetailScreen(
                        sessionId: session.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Educational Onboarding Overlay
  // ---------------------------------------------------------------------------

  Widget _buildEducationOverlay(ThemeData theme) {
    return GestureDetector(
      onTap: () {}, // block taps through
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Center(
                          child: Icon(
                            Icons.explore_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Welcome to Your Dashboard',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Here\'s a quick tour of what you can do:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Section explanations
                        const _EducationItem(
                          icon: Icons.bolt,
                          title: 'Quick Start',
                          description:
                              'Jump straight into an empty workout session.',
                          color: Colors.blue,
                        ),
                        const _EducationItem(
                          icon: Icons.grid_view_rounded,
                          title: 'Templates',
                          description:
                              'Browse and pick a pre-made workout template.',
                          color: Colors.purple,
                        ),
                        const _EducationItem(
                          icon: Icons.monitor_weight,
                          title: 'Quick Weight Log',
                          description:
                              'Tap to log your current weight in seconds.',
                          color: Colors.green,
                        ),
                        const _EducationItem(
                          icon: Icons.checklist,
                          title: 'Check-in',
                          description:
                              'Share your weekly progress with your trainer.',
                          color: Colors.orange,
                        ),
                        _EducationItem(
                          icon: Icons.fitness_center,
                          title: 'Active Program',
                          description:
                              'View and start your current workout program.',
                          color: theme.colorScheme.primary,
                        ),
                        const _EducationItem(
                          icon: Icons.calendar_month,
                          title: 'Upcoming Sessions',
                          description:
                              'See scheduled sessions at a glance.',
                          color: Colors.deepPurple,
                        ),
                        _EducationItem(
                          icon: Icons.track_changes_outlined,
                          title: 'Daily Targets',
                          description:
                              'Set and track your daily fitness goals.',
                          color: theme.colorScheme.secondary,
                        ),
                        const _EducationItem(
                          icon: Icons.history,
                          title: 'Recent History',
                          description:
                              'Review your past workouts and progress.',
                          color: Colors.teal,
                        ),

                        const SizedBox(height: 24),

                        // Got it button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _dismissEducationOverlay,
                            child: const Text('Got it!'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

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
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.subtitle,
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
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
  final VoidCallback? onTap;

  const _UpcomingSessionCard({required this.session, this.onTap});

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
          onTap: onTap,
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
// Active program template chip
// ---------------------------------------------------------------------------

class _ActiveTemplateChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ActiveTemplateChip({
    required this.name,
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
              name,
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
// Education Item (onboarding overlay)
// ---------------------------------------------------------------------------

class _EducationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _EducationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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


