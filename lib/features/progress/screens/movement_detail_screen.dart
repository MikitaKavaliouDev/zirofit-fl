import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/features/progress/providers/movement_detail_provider.dart';
import 'package:zirofit_fl/features/progress/widgets/movement_stat_card.dart';
import 'package:zirofit_fl/shared/widgets/charts/interactive_line_chart.dart';
import 'package:zirofit_fl/shared/widgets/charts/models.dart';
import 'package:zirofit_fl/shared/widgets/ziro_header.dart';

/// Detailed analytics screen for a specific exercise / movement.
///
/// Mirrors iOS [MovementDetailView].
class MovementDetailScreen extends ConsumerStatefulWidget {
  final String exerciseName;

  const MovementDetailScreen({super.key, required this.exerciseName});

  @override
  ConsumerState<MovementDetailScreen> createState() =>
      _MovementDetailScreenState();
}

class _MovementDetailScreenState
    extends ConsumerState<MovementDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(movementDetailProvider(widget.exerciseName).notifier)
          .loadHistory(),
    );
  }

  Future<void> _onRefresh() async {
    await ref
        .read(movementDetailProvider(widget.exerciseName).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementDetailProvider(widget.exerciseName));
    final themeColors = context.themeColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- ZiroHeader ----
            ZiroHeader<Widget, Widget>(
              title: widget.exerciseName,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // ---- Body ----
            Expanded(
              child: _buildBody(state, themeColors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MovementDetailState state, ThemeColors themeColors) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildError(state.error!, themeColors);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // --- Stats Grid ---
          _buildStatsGrid(state, themeColors),
          const SizedBox(height: 24),

          // --- 1RM Progression ---
          _buildProgressionSection(
            title: 'Estimated 1RM Progression',
            subtitle: 'Based on weight and reps (Brzycki Formula)',
            data: state.oneRMHistory,
            color: Colors.orange,
            themeColors: themeColors,
          ),
          const SizedBox(height: 24),

          // --- Volume Progression ---
          _buildProgressionSection(
            title: 'Volume Progression',
            subtitle: 'Total weight moved per session',
            data: state.volumeHistory,
            color: Colors.blue,
            themeColors: themeColors,
          ),
          const SizedBox(height: 24),

          // --- Top Historical Sets ---
          _buildBestSetsSection(state, themeColors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(String error, ThemeColors themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: themeColors.textPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Grid (2×2)
  // ---------------------------------------------------------------------------

  Widget _buildStatsGrid(MovementDetailState state, ThemeColors themeColors) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        MovementStatCard(
          title: 'Max Weight',
          value: '${state.stats.maxWeight.toInt()} kg',
          icon: Icons.monitor_weight_outlined,
          color: Colors.orange,
        ),
        MovementStatCard(
          title: 'Max Volume',
          value: '${state.stats.maxVolume.toInt()} kg',
          icon: Icons.grid_view_rounded,
          color: Colors.blue,
        ),
        MovementStatCard(
          title: 'Total Reps',
          value: '${state.stats.totalReps}',
          icon: Icons.repeat,
          color: Colors.purple,
        ),
        MovementStatCard(
          title: 'Total Sets',
          value: '${state.stats.totalSets}',
          icon: Icons.format_list_bulleted,
          color: Colors.green,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Progression Chart Section
  // ---------------------------------------------------------------------------

  Widget _buildProgressionSection({
    required String title,
    required String subtitle,
    required List<VolumeData> data,
    required Color color,
    required ThemeColors themeColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        data.length < 2
            ? _buildEmptyChart(themeColors)
            : SizedBox(
                height: 220,
                child: InteractiveLineChart(
                  data: data,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  fillGradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.35),
                      color.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyChart(ThemeColors themeColors) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Not enough data for chart',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Historical Sets
  // ---------------------------------------------------------------------------

  Widget _buildBestSetsSection(
      MovementDetailState state, ThemeColors themeColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Top Historical Sets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (state.bestSets.isEmpty)
          _buildEmptyBestSets(themeColors)
        else
          Container(
            decoration: BoxDecoration(
              color: themeColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(state.bestSets.length, (index) {
                final set = state.bestSets[index];
                final isLast = index == state.bestSets.length - 1;
                return _buildBestSetRow(set, isLast);
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyBestSets(ThemeColors themeColors) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No sets logged yet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildBestSetRow(HistoricalSet set, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Left: weight × reps + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${set.weight.toInt()} kg × ${set.reps}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(set.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Right: estimated 1RM
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${set.estimated1RM.toInt()} kg',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Est. 1RM',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
