import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final stats = state.stats;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).fetchStats(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Admin Dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading && stats == null)
            const Center(child: CircularProgressIndicator())
          else
            _buildStatsGrid(context, stats, theme),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    Map<String, dynamic>? stats,
    ThemeData theme,
  ) {
    final items = <_StatCard>[
      _StatCard(
        icon: Icons.people,
        label: 'Total Users',
        value: _intValue(stats?['totalUsers']),
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.fitness_center,
        label: 'Total Trainers',
        value: _intValue(stats?['totalTrainers']),
        color: Colors.green,
      ),
      _StatCard(
        icon: Icons.person,
        label: 'Total Clients',
        value: _intValue(stats?['totalClients']),
        color: Colors.orange,
      ),
      _StatCard(
        icon: Icons.event,
        label: 'Total Events',
        value: _intValue(stats?['totalEvents']),
        color: Colors.purple,
      ),
      _StatCard(
        icon: Icons.pending_actions,
        label: 'Pending Events',
        value: _intValue(stats?['pendingEvents']),
        color: Colors.red,
      ),
      _StatCard(
        icon: Icons.article,
        label: 'Blog Posts',
        value: _intValue(stats?['totalBlogPosts']),
        color: Colors.teal,
      ),
      _StatCard(
        icon: Icons.confirmation_number,
        label: 'Open Tickets',
        value: _intValue(stats?['openTickets']),
        color: Colors.indigo,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _intValue(dynamic value) {
    if (value is int) return value.toString();
    if (value is String) return value;
    return '0';
  }
}

class _StatCard {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
