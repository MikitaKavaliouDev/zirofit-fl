import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/features/clients/providers/client_history_provider.dart';

// =============================================================================
// Screen
// =============================================================================

/// Displays a client's workout history with a volume progression chart,
/// date range filter chips, and a date-grouped session list.
///
/// Route: `/trainer/clients/:id/sessions`
class ClientHistoryScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientHistoryScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientHistoryScreen> createState() =>
      _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends ConsumerState<ClientHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(clientHistoryProvider(widget.clientId).notifier)
          .fetchHistory();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(clientHistoryProvider(widget.clientId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientHistoryProvider(widget.clientId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ClientHistoryState state, ThemeData theme) {
    if (state.isLoading && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.sessions.isEmpty) {
      return _ErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(clientHistoryProvider(widget.clientId).notifier).refresh(),
      );
    }

    if (!state.isLoading && state.sessions.isEmpty) {
      return _EmptyState(
        onRefresh: () =>
            ref.read(clientHistoryProvider(widget.clientId).notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientHistoryProvider(widget.clientId).notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Volume chart section
          SliverToBoxAdapter(
            child: _VolumeChartSection(
              volumeData: state.volumeData,
              theme: theme,
            ),
          ),

          // Date range filter chips
          SliverToBoxAdapter(
            child: _DateRangeChips(
              activeRange: state.dateRange,
              onRangeChanged: (range) {
                ref
                    .read(clientHistoryProvider(widget.clientId).notifier)
                    .setDateRange(range);
              },
            ),
          ),

          // Date-grouped session list
          ..._buildSessionGroups(state, theme),

          // Loading more indicator
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSessionGroups(ClientHistoryState state, ThemeData theme) {
    if (state.sessions.isEmpty) return [];

    // Group sessions by date (newest first)
    final grouped = <DateTime, List<SessionHistoryData>>{};
    for (final s in state.sessions) {
      final dayKey = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(s);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final date in sortedDates) {
      final daySessions = grouped[date]!;
      widgets.add(
        SliverToBoxAdapter(
          child: _DateHeader(date: date, sessionCount: daySessions.length),
        ),
      );

      for (final sessionData in daySessions) {
        widgets.add(
          SliverToBoxAdapter(
            child: _SessionRow(
              data: sessionData,
              onTap: () => _navigateToSessionDetail(sessionData.id),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void _navigateToSessionDetail(String sessionId) {
    // Navigate to session detail screen using the existing workout route pattern
    Navigator.of(context).pushNamed(
      '/workout/$sessionId',
      arguments: sessionId,
    );
  }
}

// =============================================================================
// Volume chart section
// =============================================================================

class _VolumeChartSection extends StatelessWidget {
  final List<VolumePoint> volumeData;
  final ThemeData theme;

  const _VolumeChartSection({
    required this.volumeData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Volume Progression',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: volumeData.length < 2
                    ? _ChartPlaceholder(theme: theme)
                    : _VolumeLineChart(
                        volumeData: volumeData,
                        theme: theme,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final ThemeData theme;

  const _ChartPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Log more sessions to see volume progression',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VolumeLineChart extends StatelessWidget {
  final List<VolumePoint> volumeData;
  final ThemeData theme;

  const _VolumeLineChart({
    required this.volumeData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = theme.colorScheme.primary;
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < volumeData.length; i++) {
      final vol = volumeData[i].volume;
      spots.add(FlSpot(i.toDouble(), vol));
      if (vol < minY) minY = vol;
      if (vol > maxY) maxY = vol;
    }

    final yPadding = (maxY - minY) * 0.15;
    final yMin = (minY - yPadding).clamp(0.0, double.infinity);
    final yMax = maxY + yPadding;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 30,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.2),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _calculateInterval(spots.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= volumeData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    volumeData[index].date.substring(5), // MM-DD
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  _formatVolume(value),
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        minY: yMin,
        maxY: yMax,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                final dateStr = index < volumeData.length
                    ? volumeData[index].date
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${_formatVolume(spot.y)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).ceilToDouble();
  }

  String _formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }
}

// =============================================================================
// Date range filter chips
// =============================================================================

class _DateRangeChips extends StatelessWidget {
  final HistoryDateRange activeRange;
  final ValueChanged<HistoryDateRange> onRangeChanged;

  const _DateRangeChips({
    required this.activeRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: HistoryDateRange.values.map((range) {
            final isActive = activeRange == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(range.label),
                selected: isActive,
                onSelected: (_) => onRangeChanged(range),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.outlineVariant,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// Date header
// =============================================================================

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int sessionCount;

  const _DateHeader({
    required this.date,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (dayKey == today) {
      dateLabel = 'Today';
    } else if (dayKey == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Yesterday';
    } else if (date.year == now.year) {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    } else {
      dateLabel = DateFormat('EEEE, MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sessionCount session${sessionCount == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Session row
// =============================================================================

class _SessionRow extends StatelessWidget {
  final SessionHistoryData data;
  final VoidCallback onTap;

  const _SessionRow({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = data.endTime?.difference(data.startTime);
    final durationStr = duration != null
        ? '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s'
        : 'In progress';
    final statusColor = _statusColor(data.status);
    final timeStr = DateFormat('HH:mm').format(data.startTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Session info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            durationStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (data.totalVolume > 0)
                      Text(
                        '${data.totalVolume.toStringAsFixed(0)} kg',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    if (data.totalVolume > 0) const SizedBox(height: 2),
                    Text(
                      '${data.totalSets} sets',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(WorkoutSessionStatus status) {
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

// =============================================================================
// Empty state
// =============================================================================

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No workout history yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Workout sessions will appear here\nonce the client starts training.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

// =============================================================================
// Error state
// =============================================================================

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
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
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
