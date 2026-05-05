import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';

// =============================================================================
// TimelineItem model
// =============================================================================

/// Discriminated type for each entry in the combined timeline.
enum TimelineItemType { workout, checkIn, measurement }

/// Active filter for the timeline list.
enum TimelineFilter { all, workouts, checkIns, measurements }

/// A single entry in the combined client activity timeline.
@immutable
class TimelineItem {
  final String id;
  final DateTime date;
  final TimelineItemType type;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> data;

  const TimelineItem({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.data,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineItem &&
          id == other.id &&
          type == other.type &&
          date == other.date;

  @override
  int get hashCode => Object.hash(id, type, date);
}

// =============================================================================
// Screen
// =============================================================================

/// Displays a combined timeline of a client's activity: workout sessions,
/// check-ins, and measurements — sorted newest-first with filter chips,
/// pagination, pull-to-refresh, and expandable detail cards.
class ClientHistoryScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientHistoryScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientHistoryScreen> createState() =>
      _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends ConsumerState<ClientHistoryScreen> {
  TimelineFilter _activeFilter = TimelineFilter.all;
  int _visibleCount = 20;
  static const int _pageSize = 20;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(clientDetailProvider(widget.clientId).notifier).fetchAll();
      ref.read(trainerCheckInsProvider.notifier).fetchCheckIns();
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a combined, sorted timeline from all data sources.
  List<TimelineItem> _buildTimeline(
    ClientDetailState clientState,
    TrainerCheckInsState checkInState,
  ) {
    final items = <TimelineItem>[];

    // Workout sessions
    for (final session in clientState.sessions) {
      final date = session.endTime ?? session.startTime;
      final duration = session.endTime?.difference(session.startTime);
      final durationStr = duration != null
          ? '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s'
          : null;

      items.add(TimelineItem(
        id: 'workout_${session.id}',
        date: date,
        type: TimelineItemType.workout,
        title: session.name ?? 'Workout Session',
        subtitle: [
          ?durationStr,
          if (session.status == WorkoutSessionStatus.completed) 'Completed',
          if (session.status == WorkoutSessionStatus.planned) 'Planned',
        ].join(' • '),
        icon: Icons.fitness_center,
        color: const Color(0xFF3B82F6),
        data: {'session': session},
      ));
    }

    // Measurements
    for (final m in clientState.measurements) {
      final parts = <String>[];
      if (m.weightKg != null) {
        parts.add('Weight: ${m.weightKg!.toStringAsFixed(1)} kg');
      }
      if (m.bodyFatPercentage != null) {
        parts.add('Body Fat: ${m.bodyFatPercentage!.toStringAsFixed(1)}%');
      }

      items.add(TimelineItem(
        id: 'measurement_${m.id}',
        date: m.measurementDate,
        type: TimelineItemType.measurement,
        title: parts.isNotEmpty
            ? parts.join(', ')
            : 'Measurements recorded',
        subtitle: m.notes,
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFF10B981),
        data: {'measurement': m},
      ));
    }

    // Check-ins (filtered by this client)
    final clientCheckIns =
        checkInState.checkIns.where((c) => c.clientId == widget.clientId);
    for (final ci in clientCheckIns) {
      final metrics = <String>[];
      if (ci.weight != null) {
        metrics.add('${ci.weight!.toStringAsFixed(1)} kg');
      }
      if (ci.waistCm != null) {
        metrics.add('Waist: ${ci.waistCm!.toStringAsFixed(1)} cm');
      }

      items.add(TimelineItem(
        id: 'checkin_${ci.id}',
        date: ci.date,
        type: TimelineItemType.checkIn,
        title: 'Weekly Check-in',
        subtitle: metrics.isNotEmpty ? metrics.join(' • ') : ci.status,
        icon: Icons.task_alt,
        color: const Color(0xFFF59E0B),
        data: {'checkIn': ci},
      ));
    }

    // Sort newest first
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Applies the current filter and pagination.
  List<TimelineItem> _applyFilter(
    List<TimelineItem> all,
    TimelineFilter filter,
  ) {
    if (filter == TimelineFilter.all) return all;
    return all.where((item) {
      switch (filter) {
        case TimelineFilter.workouts:
          return item.type == TimelineItemType.workout;
        case TimelineFilter.checkIns:
          return item.type == TimelineItemType.checkIn;
        case TimelineFilter.measurements:
          return item.type == TimelineItemType.measurement;
        default:
          return true;
      }
    }).toList();
  }

  bool get _hasMore =>
      _applyFilter(
        _buildTimeline(
          ref.read(clientDetailProvider(widget.clientId)),
          ref.read(trainerCheckInsProvider),
        ),
        _activeFilter,
      ).length >
      _visibleCount;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientDetailProvider(widget.clientId));
    final checkInState = ref.watch(trainerCheckInsProvider);
    final theme = Theme.of(context);

    final clientName = clientState.client?.name ?? 'Client';
    final isLoading =
        clientState.isLoading && clientState.client == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: isLoading
          ? const _ShimmerLoading()
          : _buildBody(theme, clientState, checkInState, clientName),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ClientDetailState clientState,
    TrainerCheckInsState checkInState,
    String clientName,
  ) {
    final allItems = _buildTimeline(clientState, checkInState);
    final filteredItems = _applyFilter(allItems, _activeFilter);
    final visibleItems =
        filteredItems.take(_visibleCount).toList();

    if (allItems.isEmpty && !clientState.isLoading) {
      return _EmptyHistory(
        onRefresh: () async {
          await ref
              .read(clientDetailProvider(widget.clientId).notifier)
              .fetchAll();
          await ref
              .read(trainerCheckInsProvider.notifier)
              .fetchCheckIns();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(clientDetailProvider(widget.clientId).notifier)
            .fetchAll();
        await ref
            .read(trainerCheckInsProvider.notifier)
            .fetchCheckIns();
        setState(() {
          _visibleCount = _pageSize;
          _expandedIds.clear();
        });
      },
      child: Column(
        children: [
          // Filter chips
          _FilterChipRow(
            activeFilter: _activeFilter,
            onFilterChanged: (filter) {
              setState(() {
                _activeFilter = filter;
                _visibleCount = _pageSize;
                _expandedIds.clear();
              });
            },
          ),

          // Timeline list
          Expanded(
            child: visibleItems.isEmpty
                ? _buildEmptyFilterResult(theme)
                : _buildTimelineList(theme, visibleItems),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterResult(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items match this filter',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeFilter = TimelineFilter.all;
                  _visibleCount = _pageSize;
                });
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear filter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList(ThemeData theme, List<TimelineItem> items) {
    // Group items by date
    final grouped = <DateTime, List<TimelineItem>>{};
    for (final item in items) {
      final dayKey = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(item);
    }

    // Sort date groups newest-first
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedDates.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedDates.length) {
          // Load more button
          return _LoadMoreButton(
            onTap: () {
              setState(() {
                _visibleCount += _pageSize;
              });
            },
          );
        }

        final date = sortedDates[index];
        final dayItems = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            _DateHeader(date: date),
            // Timeline items for this date
            ...dayItems.map((item) {
              final isExpanded = _expandedIds.contains(item.id);
              return _TimelineItemCard(
                item: item,
                isExpanded: isExpanded,
                isLast: dayItems.last == item,
                onToggleExpand: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(item.id);
                    } else {
                      _expandedIds.add(item.id);
                    }
                  });
                },
              );
            }),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Filter chip row
// =============================================================================

class _FilterChipRow extends StatelessWidget {
  final TimelineFilter activeFilter;
  final ValueChanged<TimelineFilter> onFilterChanged;

  const _FilterChipRow({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              theme: theme,
              label: 'All',
              filter: TimelineFilter.all,
            ),
            const SizedBox(width: 8),
            _buildChip(
              theme: theme,
              label: 'Workouts',
              filter: TimelineFilter.workouts,
              icon: Icons.fitness_center,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            _buildChip(
              theme: theme,
              label: 'Check-ins',
              filter: TimelineFilter.checkIns,
              icon: Icons.task_alt,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            _buildChip(
              theme: theme,
              label: 'Measurements',
              filter: TimelineFilter.measurements,
              icon: Icons.monitor_weight_outlined,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required ThemeData theme,
    required String label,
    required TimelineFilter filter,
    IconData? icon,
    Color? color,
  }) {
    final isActive = activeFilter == filter;
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      selected: isActive,
      label: Text(label),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : chipColor,
            )
          : null,
      onSelected: (_) => onFilterChanged(filter),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isActive ? chipColor : theme.colorScheme.outlineVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// =============================================================================
// Date header
// =============================================================================

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          // Timeline line connector
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Vertical line extending down
          Expanded(
            child: Text(
              dateLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Timeline item card
// =============================================================================

class _TimelineItemCard extends StatelessWidget {
  final TimelineItem item;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onToggleExpand;

  const _TimelineItemCard({
    required this.item,
    required this.isExpanded,
    required this.isLast,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color,
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: 16,
                bottom: isLast ? 8 : 4,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: isExpanded ? 2 : 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Type icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 20,
                                  color: item.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title & subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.subtitle != null &&
                                        item.subtitle!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Time
                              Text(
                                DateFormat('HH:mm').format(item.date),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Expand icon
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),

                        // Expanded detail
                        if (isExpanded) ...[
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
          _buildExpandedContent(theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    switch (item.type) {
      case TimelineItemType.workout:
        return _WorkoutDetail(
          session: item.data['session'] as WorkoutSession,
          theme: theme,
        );
      case TimelineItemType.checkIn:
        return _CheckInDetail(
          checkIn: item.data['checkIn'] as CheckIn,
          theme: theme,
        );
      case TimelineItemType.measurement:
        return _MeasurementDetail(
          measurement: item.data['measurement'] as ClientMeasurement,
          theme: theme,
        );
    }
  }
}

// =============================================================================
// Expanded detail widgets
// =============================================================================

class _WorkoutDetail extends StatelessWidget {
  final WorkoutSession session;
  final ThemeData theme;

  const _WorkoutDetail({
    required this.session,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final duration = session.endTime?.difference(session.startTime);
    final durationStr = duration != null
        ? '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s'
        : 'In progress';
    final statusColor = _sessionStatusColor(session.status);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _DetailStat(
                label: 'Status',
                value: session.status.name.toUpperCase(),
                color: statusColor,
              ),
              const SizedBox(width: 16),
              _DetailStat(
                label: 'Duration',
                value: durationStr,
                color: theme.colorScheme.primary,
              ),
            ],
          ),

          // Notes
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
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

class _CheckInDetail extends StatelessWidget {
  final CheckIn checkIn;
  final ThemeData theme;

  const _CheckInDetail({
    required this.checkIn,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics grid
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  label: 'Weight',
                  value: checkIn.weight != null
                      ? '${checkIn.weight!.toStringAsFixed(1)} kg'
                      : '--',
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  label: 'Waist',
                  value: checkIn.waistCm != null
                      ? '${checkIn.waistCm!.toStringAsFixed(1)} cm'
                      : '--',
                  color: theme.colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  label: 'Sleep',
                  value: checkIn.sleepHours != null
                      ? '${checkIn.sleepHours!.toStringAsFixed(1)} hrs'
                      : '--',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wellness row
          Row(
            children: [
              _WellnessChip(
                label: 'Energy',
                value: checkIn.energyLevel,
                icon: Icons.bolt,
              ),
              const SizedBox(width: 6),
              _WellnessChip(
                label: 'Stress',
                value: checkIn.stressLevel,
                icon: Icons.psychology,
              ),
              const SizedBox(width: 6),
              _WellnessChip(
                label: 'Hunger',
                value: checkIn.hungerLevel,
                icon: Icons.restaurant,
              ),
              const SizedBox(width: 6),
              _WellnessChip(
                label: 'Digestion',
                value: checkIn.digestionLevel,
                icon: Icons.monitor_heart_outlined,
              ),
            ],
          ),

          // Nutrition compliance
          if (checkIn.nutritionCompliance != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.restaurant_menu,
              label: 'Nutrition',
              value: _formatNutrition(checkIn.nutritionCompliance!),
            ),
          ],

          // Client notes
          if (checkIn.clientNotes != null &&
              checkIn.clientNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                checkIn.clientNotes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          // Trainer response
          if (checkIn.trainerResponse != null &&
              checkIn.trainerResponse!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 14,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trainer Response',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checkIn.trainerResponse!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Status badge
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: checkIn.status == 'SUBMITTED'
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                checkIn.status == 'SUBMITTED' ? 'Pending Review' : 'Reviewed',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: checkIn.status == 'SUBMITTED'
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatNutrition(String value) {
    switch (value) {
      case 'ON_TRACK':
        return 'On Track';
      case 'MOSTLY':
        return 'Mostly';
      case 'OFF_TRACK':
        return 'Off Track';
      default:
        return value;
    }
  }
}

class _MeasurementDetail extends StatelessWidget {
  final ClientMeasurement measurement;
  final ThemeData theme;

  const _MeasurementDetail({
    required this.measurement,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (measurement.weightKg != null)
                Expanded(
                  child: _DetailStat(
                    label: 'Weight',
                    value: '${measurement.weightKg!.toStringAsFixed(1)} kg',
                    color: theme.colorScheme.primary,
                  ),
                ),
              if (measurement.bodyFatPercentage != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _DetailStat(
                    label: 'Body Fat',
                    value:
                        '${measurement.bodyFatPercentage!.toStringAsFixed(1)}%',
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),

          // Notes
          if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                measurement.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          // Recorded date
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(measurement.measurementDate),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable small widgets
// =============================================================================

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessChip extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;

  const _WellnessChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    final displayValue = v != null ? '$v/10' : '--';

    Color? chipColor;
    if (v != null) {
      if (v <= 3) {
        chipColor = Colors.red;
      } else if (v <= 6) {
        chipColor = Colors.orange;
      } else {
        chipColor = Colors.green;
      }
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: chipColor?.withValues(alpha: 0.1) ??
              theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 14,
              color: chipColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: chipColor,
                fontSize: 11,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Load more button
// =============================================================================

class _LoadMoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LoadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.expand_more, size: 18),
          label: const Text('Load More'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Empty history
// =============================================================================

class _EmptyHistory extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyHistory({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
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
                      Icons.history_toggle_off,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history available yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Workout sessions, check-ins, and measurements\nwill appear here once available.',
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
// Shimmer loading placeholder
// =============================================================================

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.grey.shade800
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Card placeholder
                Expanded(
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
