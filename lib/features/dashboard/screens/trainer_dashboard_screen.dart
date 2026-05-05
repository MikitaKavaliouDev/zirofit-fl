import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/dashboard_prompt_card.dart';
import 'package:zirofit_fl/features/dashboard/widgets/quick_add_session_dialog.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() =>
      _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState
    extends ConsumerState<TrainerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerDashboardProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(trainerDashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trainerDashboardProvider.notifier).refresh();
        },
        child: _buildBody(theme, authState, dashboardState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickAddSession(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AuthState authState,
    TrainerDashboardState dashboardState,
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
                'Welcome back,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                authState.user?.name ?? 'Trainer',
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
              // Stats Cards
              _buildStatsSection(theme, data.stats),
              const SizedBox(height: 24),

              // Dashboard Prompts
              _buildPromptsSection(theme, data),
              const SizedBox(height: 20),

              // Quick Actions Bar
              _buildQuickActionsBar(theme),
              const SizedBox(height: 24),

              // Upcoming Sessions
              _buildSectionHeader(theme, 'Upcoming Sessions', () {}),
              const SizedBox(height: 12),
              _buildUpcomingSessions(theme, data.upcomingSessions),
              const SizedBox(height: 24),

              // Recent Activity
              _buildSectionHeader(theme, 'Recent Activity', () {}),
              const SizedBox(height: 12),
              _buildRecentActivity(theme, data.recentActivity),
              const SizedBox(height: 24),

              // Active Clients Preview
              _buildSectionHeader(theme, 'Active Clients', () {}),
              const SizedBox(height: 12),
              _buildActiveClientsPreview(theme, data.activeClients),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard Prompts
  // ---------------------------------------------------------------------------

  Widget _buildPromptsSection(ThemeData theme, TrainerDashboardData data) {
    final prompts = <DashboardPrompt>[
      // Prompt: pending check-ins
      if (data.stats.pendingCheckIns > 0)
        DashboardPrompt(
          id: 'pending_checkins_${data.stats.pendingCheckIns}',
          type: DashboardPromptType.overdueCheckin,
          title: data.stats.pendingCheckIns == 1
              ? 'You have 1 pending check-in to review'
              : 'You have ${data.stats.pendingCheckIns} pending check-ins to review',
          actionLabel: 'View Check-ins',
          onAction: () {
            // TODO: navigate to check-ins tab
          },
        ),

      // Prompt: new clients (from recent activity)
      if (data.recentActivity
          .any((a) => a.type == ActivityType.client))
        DashboardPrompt(
          id: 'new_client_activity',
          type: DashboardPromptType.newClient,
          title: 'A new client joined — say hello!',
          actionLabel: 'View Clients',
          onAction: () {
            // TODO: navigate to clients tab
          },
        ),

      // Prompt: upcoming session reminder
      if (data.upcomingSessions.isNotEmpty)
        DashboardPrompt(
          id: 'upcoming_sessions_${data.upcomingSessions.length}',
          type: DashboardPromptType.upcomingSession,
          title: 'You have ${data.upcomingSessions.length} session${data.upcomingSessions.length == 1 ? '' : 's'} today',
          actionLabel: 'View Calendar',
          onAction: () {
            // TODO: navigate to calendar tab
          },
        ),
    ];

    if (prompts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: prompts.map((p) => DashboardPromptCard(prompt: p)).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActionsBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionChip(
            icon: Icons.add_circle_outline,
            label: 'Quick Add',
            onTap: () => _quickAddSession(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionChip(
            icon: Icons.people_outline,
            label: 'New Client',
            onTap: () {
              // TODO: navigate to add client
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionChip(
            icon: Icons.calendar_month_outlined,
            label: 'View Calendar',
            onTap: () {
              // TODO: navigate to calendar
            },
          ),
        ),
      ],
    );
  }

  Future<void> _quickAddSession(BuildContext context) async {
    final created = await QuickAddSessionDialog.show(context);
    if (created == true && mounted) {
      ref.read(trainerDashboardProvider.notifier).refresh();
    }
  }

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
                ref.read(trainerDashboardProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, TrainerDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Revenue',
              value: NumberFormat.currency(symbol: '\$').format(stats.revenue),
              icon: Icons.attach_money,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Active Clients',
              value: stats.activeClients.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Today\'s Sessions',
              value: stats.todaySessions.toString(),
              icon: Icons.calendar_today,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Pending Check-ins',
              value: stats.pendingCheckIns.toString(),
              icon: Icons.pending_actions,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions(
    ThemeData theme,
    List<WorkoutSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return Card(
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
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _SessionListTile(session: session);
        },
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme, List<ActivityItem> activities) {
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length.clamp(0, 5),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _ActivityListTile(activity: activity);
        },
      ),
    );
  }

  Widget _buildActiveClientsPreview(ThemeData theme, List<Client> clients) {
    if (clients.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active clients',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length.clamp(0, 6),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final client = clients[index];
          return _ClientAvatarCard(client: client);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Card Widget
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session List Tile
// ---------------------------------------------------------------------------

class _SessionListTile extends StatelessWidget {
  final WorkoutSession session;

  const _SessionListTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateFormat.format(session.startTime),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 10,
                ),
              ),
              Text(
                timeFormat.format(session.startTime),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        session.name ?? 'Training Session',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        session.isTrainerLed ? 'Trainer-led' : 'Self-guided',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        // TODO: Navigate to session details
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Activity List Tile
// ---------------------------------------------------------------------------

class _ActivityListTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityListTile({required this.activity});

  IconData _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.checkIn:
        return Icons.check_circle_outline;
      case ActivityType.session:
        return Icons.fitness_center;
      case ActivityType.client:
        return Icons.person_add;
      case ActivityType.payment:
        return Icons.payment;
      case ActivityType.other:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(ActivityType type, ThemeData theme) {
    switch (type) {
      case ActivityType.checkIn:
        return Colors.green;
      case ActivityType.session:
        return Colors.blue;
      case ActivityType.client:
        return Colors.purple;
      case ActivityType.payment:
        return Colors.orange;
      case ActivityType.other:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColorForType(activity.type, theme);
    final timeAgo = _getTimeAgo(activity.timestamp);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getIconForType(activity.type),
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        activity.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        activity.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        timeAgo,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// ---------------------------------------------------------------------------
// Client Avatar Card
// ---------------------------------------------------------------------------

class _ClientAvatarCard extends StatelessWidget {
  final Client client;

  const _ClientAvatarCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            client.name.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: Text(
            client.name.split(' ').first,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Action Chip
// ---------------------------------------------------------------------------

/// A compact tappable chip for the quick actions bar on the dashboard.
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
