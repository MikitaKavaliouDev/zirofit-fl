import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/clients/providers/live_session_provider.dart';

class LiveSessionMonitorScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String? clientName;

  const LiveSessionMonitorScreen({
    super.key,
    required this.clientId,
    this.clientName,
  });

  @override
  ConsumerState<LiveSessionMonitorScreen> createState() =>
      _LiveSessionMonitorScreenState();
}

class _LiveSessionMonitorScreenState
    extends ConsumerState<LiveSessionMonitorScreen> {
  LiveSessionNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _notifier = ref.read(liveSessionProvider.notifier);
      _notifier!.startPolling(widget.clientId);
    });
  }

  @override
  void dispose() {
    _notifier?.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName ?? 'Live Session'),
        actions: [
          _LiveIndicator(isPolling: state.isPolling),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(liveSessionProvider.notifier).refresh(),
        child: _buildBody(state, theme),
      ),
    );
  }

  Widget _buildBody(LiveSessionState state, ThemeData theme) {
    if (state.isLoading && state.session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(liveSessionProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.session == null) {
      return _buildNoActiveSession(theme);
    }

    final session = state.session!;
    final completedLogs =
        state.exerciseLogs.where((l) => l.isCompleted == true).toList();
    final inProgressLogs =
        state.exerciseLogs.where((l) => l.isCompleted != true).toList();

    return CustomScrollView(
      slivers: [
        // Session info card
        SliverToBoxAdapter(
          child: _SessionInfoCard(
            session: session,
            totalExercises: state.exerciseLogs.length,
            completedExercises: completedLogs.length,
            theme: theme,
          ),
        ),

        // Current / in-progress exercises
        if (inProgressLogs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'In Progress', theme: theme),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ExerciseLogTile(
                log: inProgressLogs[i],
                isCompleted: false,
                theme: theme,
              ),
              childCount: inProgressLogs.length,
            ),
          ),
        ],

        // Completed exercises
        if (completedLogs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Completed', theme: theme),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ExerciseLogTile(
                log: completedLogs[i],
                isCompleted: true,
                theme: theme,
              ),
              childCount: completedLogs.length,
            ),
          ),
        ],

        // Last updated footer
        if (state.lastUpdated != null)
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _LastUpdatedFooter(
                lastUpdated: state.lastUpdated!,
                isPolling: state.isPolling,
                theme: theme,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoActiveSession(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Workout',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.clientName ?? 'This client'} does not have an active workout session right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(liveSessionProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live Indicator (pulsing dot)
// ---------------------------------------------------------------------------

class _LiveIndicator extends StatefulWidget {
  final bool isPolling;

  const _LiveIndicator({required this.isPolling});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPolling) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPolling && !oldWidget.isPolling) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPolling && oldWidget.isPolling) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (_, child) => Opacity(
            opacity: _animation.value,
            child: child,
          ),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.isPolling ? 'LIVE' : 'OFF',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Session Info Card
// ---------------------------------------------------------------------------

class _SessionInfoCard extends StatelessWidget {
  final WorkoutSession session;
  final int totalExercises;
  final int completedExercises;
  final ThemeData theme;

  const _SessionInfoCard({
    required this.session,
    required this.totalExercises,
    required this.completedExercises,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(session);
    final statusColor = _sessionStatusColor(session.status);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name ?? 'Active Workout',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Started ${DateFormat('MMM dd, HH:mm').format(session.startTime)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(session.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _StatItem(
                  icon: Icons.fitness_center,
                  label: 'Exercises',
                  value: '$totalExercises',
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: '$completedExercises',
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: duration,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(WorkoutSession session) {
    final start = session.startTime;
    final end = session.endTime ?? DateTime.now();
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _statusLabel(WorkoutSessionStatus status) {
    switch (status) {
      case WorkoutSessionStatus.inProgress:
        return 'IN_PROGRESS';
      case WorkoutSessionStatus.completed:
        return 'COMPLETED';
      case WorkoutSessionStatus.planned:
        return 'PLANNED';
    }
  }

  Color _sessionStatusColor(WorkoutSessionStatus status) {
    switch (status) {
      case WorkoutSessionStatus.completed:
        return Colors.green;
      case WorkoutSessionStatus.inProgress:
        return Colors.blue;
      case WorkoutSessionStatus.planned:
        return Colors.grey;
    }
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Log Tile
// ---------------------------------------------------------------------------

class _ExerciseLogTile extends StatelessWidget {
  final ClientExerciseLog log;
  final bool isCompleted;
  final ThemeData theme;

  const _ExerciseLogTile({
    required this.log,
    required this.isCompleted,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final name = log.exerciseName ?? log.exerciseId;
    final setsInfo = log.sets != null ? '${log.sets!.length} sets' : null;
    final repsInfo = log.reps != null ? '${log.reps} reps' : null;
    final weightInfo = log.weight != null ? '${log.weight!.toStringAsFixed(1)} kg' : null;
    final details = [setsInfo, repsInfo, weightInfo]
        .where((s) => s != null)
        .join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.fiber_manual_record,
          color: isCompleted ? Colors.green : Colors.orange,
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: details.isNotEmpty ? Text(details) : null,
        trailing: log.isCompleted == true
            ? null
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ACTIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Item
// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Last Updated Footer
// ---------------------------------------------------------------------------

class _LastUpdatedFooter extends StatelessWidget {
  final DateTime lastUpdated;
  final bool isPolling;
  final ThemeData theme;

  const _LastUpdatedFooter({
    required this.lastUpdated,
    required this.isPolling,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('HH:mm:ss').format(lastUpdated);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPolling)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          if (isPolling) const SizedBox(width: 8),
          Text(
            'Last updated: $formatted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
