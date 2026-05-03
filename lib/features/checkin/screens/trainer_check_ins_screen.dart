import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TrainerCheckInsScreen extends ConsumerStatefulWidget {
  const TrainerCheckInsScreen({super.key});

  @override
  ConsumerState<TrainerCheckInsScreen> createState() =>
      _TrainerCheckInsScreenState();
}

class _TrainerCheckInsScreenState
    extends ConsumerState<TrainerCheckInsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerCheckInsProvider.notifier).fetchCheckIns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerCheckInsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Check-Ins'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(trainerCheckInsProvider.notifier).fetchCheckIns(),
          ),
        ],
      ),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, TrainerCheckInsState state) {
    if (state.isLoading && state.checkIns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.checkIns.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    if (state.checkIns.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerCheckInsProvider.notifier).fetchCheckIns(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pending check-ins
          if (state.pendingCheckIns.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Pending Review',
                count: state.pendingCheckIns.length,
                color: Colors.orange),
            const SizedBox(height: 8),
            ...state.pendingCheckIns.map(
              (ci) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CheckInCard(checkIn: ci),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reviewed check-ins
          if (state.reviewedCheckIns.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Reviewed',
                count: state.reviewedCheckIns.length,
                color: Colors.green),
            const SizedBox(height: 8),
            ...state.reviewedCheckIns.map(
              (ci) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CheckInCard(checkIn: ci),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title, {
    int? count,
    Color? color,
  }) {
    return Row(
      children: [
        if (color != null) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
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
              Icons.task_alt,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No check-ins yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check-ins from your clients will appear here',
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
            Text('Something went wrong',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(trainerCheckInsProvider.notifier).fetchCheckIns(),
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
// Check-In Card
// ---------------------------------------------------------------------------

class _CheckInCard extends ConsumerStatefulWidget {
  final CheckIn checkIn;

  const _CheckInCard({required this.checkIn});

  @override
  ConsumerState<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<_CheckInCard> {
  bool _expanded = false;
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ci = widget.checkIn;
    final dateFormat = DateFormat('MMM d, yyyy');
    final isPending = ci.status == 'SUBMITTED';
    final trainerState = ref.watch(trainerCheckInsProvider);

    return Card(
      elevation: _expanded ? 3 : 1,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator
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
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in ${dateFormat.format(ci.date)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (ci.weight != null) ...[
                              Text(
                                '${ci.weight!.toStringAsFixed(1)} kg',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ci.status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isPending
                                      ? Colors.orange.shade800
                                      : Colors.green.shade700,
                                ),
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metric cards row
                  _buildMetricRow(theme, ci),
                  const SizedBox(height: 16),

                  // Wellness metrics
                  _buildWellnessRow(theme, ci),
                  const SizedBox(height: 16),

                  // Nutrition compliance
                  _buildInfoRow(
                    theme,
                    label: 'Nutrition Compliance',
                    value: ci.nutritionCompliance != null
                        ? _formatNutritionCompliance(
                            ci.nutritionCompliance!)
                        : 'Not provided',
                    icon: Icons.restaurant_menu,
                  ),
                  const SizedBox(height: 8),

                  // Client notes
                  if (ci.clientNotes != null &&
                      ci.clientNotes!.isNotEmpty) ...[
                    _buildNotesCard(theme, ci.clientNotes!),
                    const SizedBox(height: 16),
                  ],

                  // Trainer response (existing)
                  if (ci.trainerResponse != null &&
                      ci.trainerResponse!.isNotEmpty) ...[
                    _buildExistingResponse(theme, ci.trainerResponse!),
                    const SizedBox(height: 16),
                  ],

                  // Response form (for pending check-ins)
                  if (isPending) ...[
                    _buildResponseForm(theme, ci, trainerState),
                  ],

                  // Error
                  if (trainerState.reviewError != null &&
                      isPending) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trainerState.reviewError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Metric Row
  // -----------------------------------------------------------------------

  Widget _buildMetricRow(ThemeData theme, CheckIn ci) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
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
          child: _MetricCard(
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
          child: _MetricCard(
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
          child: _WellnessChip(
            label: 'Energy',
            value: ci.energyLevel,
            icon: Icons.bolt,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessChip(
            label: 'Stress',
            value: ci.stressLevel,
            icon: Icons.psychology,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessChip(
            label: 'Hunger',
            value: ci.hungerLevel,
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WellnessChip(
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
    required String label,
    required String value,
    required IconData icon,
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

  Widget _buildNotesCard(ThemeData theme, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Client Notes',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingResponse(ThemeData theme, String response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply,
                  size: 16, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 6),
              Text(
                'Your Response',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            response,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseForm(
    ThemeData theme,
    CheckIn ci,
    TrainerCheckInsState trainerState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Response',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _responseController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Provide feedback to your client...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: trainerState.isReviewing
                ? null
                : () => _submitReview(ci.id),
            icon: trainerState.isReviewing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(
              trainerState.isReviewing
                  ? 'Submitting...'
                  : 'Submit Response',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReview(String checkInId) async {
    final text = _responseController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response')),
      );
      return;
    }

    await ref.read(trainerCheckInsProvider.notifier).submitReview(
          checkInId: checkInId,
          responseText: text,
        );

    if (!mounted) return;

    final state = ref.read(trainerCheckInsProvider);
    if (state.reviewError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _responseController.clear();
    }
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
// Metric Card (used in expanded detail)
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellness Chip (1-10 rating)
// ---------------------------------------------------------------------------

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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: chipColor?.withValues(alpha: 0.1) ??
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: chipColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 2),
          Text(
            displayValue,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: chipColor,
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
