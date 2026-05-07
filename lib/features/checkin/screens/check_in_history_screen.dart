import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_history_provider.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Displays the client's check-in history grouped by date with expandable
/// detail cards, pull-to-refresh, loading skeleton, empty, and error states.
class CheckInHistoryScreen extends ConsumerStatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  ConsumerState<CheckInHistoryScreen> createState() =>
      _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends ConsumerState<CheckInHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(checkInHistoryProvider.notifier).fetchHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(checkInHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in History'),
        centerTitle: true,
      ),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, CheckInHistoryState state) {
    // Loading skeleton (initial load)
    if (state.isLoading && state.groups.isEmpty) {
      return _ShimmerLoading(theme: theme);
    }

    // Error with no data
    if (state.error != null && state.groups.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    // Empty
    if (state.groups.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Data
    return RefreshIndicator(
      onRefresh: () => ref.read(checkInHistoryProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.groups.length,
        itemBuilder: (context, index) {
          final group = state.groups[index];
          return _DateGroupCard(
            group: group,
            isLast: index == state.groups.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rtl,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No check-ins yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your weekly check-ins will appear here once submitted.',
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

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
              onPressed: () =>
                  ref.read(checkInHistoryProvider.notifier).fetchHistory(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date group card (section header + check-in cards)
// ---------------------------------------------------------------------------

class _DateGroupCard extends ConsumerStatefulWidget {
  final CheckInGroup group;
  final bool isLast;

  const _DateGroupCard({
    required this.group,
    this.isLast = false,
  });

  @override
  ConsumerState<_DateGroupCard> createState() => _DateGroupCardState();
}

class _DateGroupCardState extends ConsumerState<_DateGroupCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date section header
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.isLast ? 8 : 20, 16, 8),
          child: Row(
            children: [
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
              Text(
                dateFormat.format(group.date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Check-in cards for this date
        ...group.checkIns.map((checkIn) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CheckInHistoryCard(checkIn: checkIn),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable check-in card
// ---------------------------------------------------------------------------

class _CheckInHistoryCard extends ConsumerStatefulWidget {
  final CheckIn checkIn;

  const _CheckInHistoryCard({required this.checkIn});

  @override
  ConsumerState<_CheckInHistoryCard> createState() =>
      _CheckInHistoryCardState();
}

class _CheckInHistoryCardState extends ConsumerState<_CheckInHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ci = widget.checkIn;
    final isPending = ci.status == 'SUBMITTED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: _expanded ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Header (always visible)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: _expanded ? Radius.zero : const Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Status icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPending
                            ? Icons.pending_outlined
                            : Icons.check_circle_outline,
                        color: isPending ? Colors.orange : Colors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weight row
                          Row(
                            children: [
                              if (ci.weight != null) ...[
                                Text(
                                  '${ci.weight!.toStringAsFixed(1)} kg',
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Status badge
                              _StatusBadge(isPending: isPending),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Nutrition compliance + trainer response preview
                          Row(
                            children: [
                              if (ci.nutritionCompliance != null) ...[
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 14,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatNutritionCompliance(
                                        ci.nutritionCompliance!),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (ci.nutritionCompliance != null &&
                                  ci.trainerResponse != null &&
                                  ci.trainerResponse!.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (ci.trainerResponse != null &&
                                  ci.trainerResponse!.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    ci.trainerResponse!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expand indicator
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded detail
            if (_expanded) ...[
              Divider(
                height: 1,
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              _buildExpandedDetail(theme, ci),
            ],
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Expanded detail content
  // -----------------------------------------------------------------------

  Widget _buildExpandedDetail(ThemeData theme, CheckIn ci) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric cards row
          _buildMetricRow(theme, ci),
          const SizedBox(height: 12),

          // Wellness row
          _buildWellnessRow(theme, ci),
          const SizedBox(height: 12),

          // Nutrition compliance
          _buildInfoRow(
            theme,
            icon: Icons.restaurant_menu,
            label: 'Nutrition',
            value: ci.nutritionCompliance != null
                ? _formatNutritionCompliance(ci.nutritionCompliance!)
                : 'Not provided',
          ),
          if (ci.clientNotes != null ||
              (ci.trainerResponse != null &&
                  ci.trainerResponse!.isNotEmpty))
            const SizedBox(height: 12),

          // Client notes
          if (ci.clientNotes != null && ci.clientNotes!.isNotEmpty) ...[
            _buildNotesCard(theme, ci.clientNotes!, 'Your Notes'),
            const SizedBox(height: 12),
          ],

          // Trainer response
          if (ci.trainerResponse != null &&
              ci.trainerResponse!.isNotEmpty)
            _buildNotesCard(
              theme,
              ci.trainerResponse!,
              'Trainer Response',
              isResponse: true,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, CheckIn ci) {
    return Row(
      children: [
        Expanded(
          child: _MetricBadge(
            label: 'Weight',
            value: ci.weight != null
                ? '${ci.weight!.toStringAsFixed(1)} kg'
                : '--',
            icon: Icons.monitor_weight_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricBadge(
            label: 'Waist',
            value: ci.waistCm != null
                ? '${ci.waistCm!.toStringAsFixed(1)} cm'
                : '--',
            icon: Icons.straighten_outlined,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricBadge(
            label: 'Sleep',
            value: ci.sleepHours != null
                ? '${ci.sleepHours!.toStringAsFixed(1)} hrs'
                : '--',
            icon: Icons.bedtime_outlined,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessRow(ThemeData theme, CheckIn ci) {
    return Row(
      children: [
        Expanded(
          child: _WellnessBadge(
            label: 'Energy',
            value: ci.energyLevel,
            icon: Icons.bolt,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessBadge(
            label: 'Stress',
            value: ci.stressLevel,
            icon: Icons.psychology,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessBadge(
            label: 'Hunger',
            value: ci.hungerLevel,
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessBadge(
            label: 'Digestion',
            value: ci.digestionLevel,
            icon: Icons.monitor_heart_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(
    ThemeData theme,
    String text,
    String title, {
    bool isResponse = false,
  }) {
    final bgColor = isResponse
        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isResponse ? Icons.reply : Icons.notes,
                size: 16,
                color: isResponse
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isResponse
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isResponse
                  ? theme.colorScheme.onSecondaryContainer
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNutritionCompliance(String value) {
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

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final bool isPending;

  const _StatusBadge({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPending ? Colors.orange : Colors.green;
    final label = isPending ? 'Pending' : 'Reviewed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isPending ? Colors.orange.shade800 : Colors.green.shade700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric badge (used in expanded detail)
// ---------------------------------------------------------------------------

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
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

// ---------------------------------------------------------------------------
// Wellness badge (1-10 rating)
// ---------------------------------------------------------------------------

class _WellnessBadge extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;

  const _WellnessBadge({
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

    return Container(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------

class _ShimmerLoading extends StatelessWidget {
  final ThemeData theme;

  const _ShimmerLoading({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header placeholder
                Container(
                  width: 160,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Card placeholder
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
