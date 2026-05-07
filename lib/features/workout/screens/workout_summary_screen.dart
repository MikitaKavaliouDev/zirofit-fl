import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/features/workout/providers/workout_summary_provider.dart';

// ---------------------------------------------------------------------------
// Post-Workout Summary Screen
// ---------------------------------------------------------------------------

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final List<ClientExerciseLog> logs;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.logs,
  });

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  final _repaintKey = GlobalKey();
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // Defer provider modification to avoid modifying during widget tree build.
    Future.microtask(() => _initSummary());
  }

  void _initSummary() {
    final sets = _toWorkoutSets(widget.logs);
    final names = _buildExerciseNames(widget.logs);

    ref.read(workoutSummaryProvider.notifier).calculateSummary(
          widget.session,
          completedSets: sets,
          exerciseNamesByLogId: names,
        );

    // Show confetti if there are PRs
    if (mounted && ref.read(workoutSummaryProvider).personalRecords.isNotEmpty) {
      setState(() => _showConfetti = true);
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // Provider state is transient per screen — no explicit reset needed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workoutSummaryProvider);

    return Scaffold(
      body: RepaintBoundary(
        key: _repaintKey,
        child: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              slivers: [
                _buildTopSection(theme, state),
                if (state.personalRecords.isNotEmpty)
                  _buildPRSection(theme, state)
                else
                  _buildNoPRSection(theme),
                if (state.bestSet != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildBestSetCard(theme, state.bestSet!, state),
                    ),
                  ),
                if (state.exerciseSummaries.isNotEmpty)
                  _buildExerciseBreakdown(theme, state),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatsRow(theme, state),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: _buildActionButtons(theme),
                  ),
                ),
              ],
            ),

            // Confetti overlay
            if (_showConfetti && state.personalRecords.isNotEmpty)
              Positioned.fill(
                child: _ConfettiEffect(controller: _confettiController),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Section — Hero, name, date, duration badge, total volume
  // ---------------------------------------------------------------------------

  Widget _buildTopSection(ThemeData theme, WorkoutSummaryState state) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final durationStr = _formatDuration(state.duration);

    return SliverToBoxAdapter(
      child: Hero(
        tag: 'workout_summary_${widget.session.id}',
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                theme.colorScheme.surface,
              ],
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 56,
            left: 24,
            right: 24,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workout name
              Text(
                widget.session.name ?? 'Workout Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Date
              Text(
                dateFormat.format(widget.session.startTime),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Duration badge + total volume
              Row(
                children: [
                  _InfoBadge(
                    icon: Icons.timer_outlined,
                    label: durationStr,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _InfoBadge(
                    icon: Icons.fitness_center,
                    label: '${state.totalSets} sets',
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total volume (big number)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatVolume(state.totalVolume),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'kg total volume',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PR Section
  // ---------------------------------------------------------------------------

  Widget _buildPRSection(ThemeData theme, WorkoutSummaryState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading with trophy
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'New Personal Records!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PR list
                ...state.personalRecords.map(
                  (pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPRItem(theme, pr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPRItem(ThemeData theme, PersonalRecord pr) {
    final improvement = pr.value - pr.previousValue;
    final improvementStr = improvement > 0
        ? '+${improvement.toStringAsFixed(1)}'
        : improvement.toStringAsFixed(1);
    final typeLabel = pr.type == 'weight' ? 'Weight' : 'Volume';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.trending_up,
            color: Colors.amber.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pr.exerciseName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$typeLabel: ${pr.value.toStringAsFixed(1)} → $improvementStr',
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
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'NEW',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // No PR Section — shown when no personal records were set
  // ---------------------------------------------------------------------------

  Widget _buildNoPRSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No new personal records this time. Keep pushing!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Best Set Card
  // ---------------------------------------------------------------------------

  Widget _buildBestSetCard(
      ThemeData theme, WorkoutSet bestSet, WorkoutSummaryState state) {
    // Find the exercise name for the best set
    final exerciseName = state.exerciseSummaries
        .where((e) => e.exerciseId == bestSet.logId)
        .map((e) => e.exerciseName)
        .firstOrNull ?? 'Exercise';
    final e1rm = _calculateE1RM(bestSet.weight, bestSet.reps);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Best Set',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exerciseName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Metrics row
            Row(
              children: [
                _MetricTile(
                  label: 'Weight',
                  value: bestSet.weight != null
                      ? '${bestSet.weight!.toStringAsFixed(1)} kg'
                      : '—',
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _MetricTile(
                  label: 'Reps',
                  value: bestSet.reps != null ? '${bestSet.reps}' : '—',
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _MetricTile(
                  label: 'e1RM',
                  value: e1rm != null ? '${e1rm.toStringAsFixed(0)} kg' : '—',
                  theme: theme,
                ),
              ],
            ),
            if (bestSet.rpe != null) ...[
              const SizedBox(height: 8),
              Text(
                'RPE: ${bestSet.rpe!.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Breakdown
  // ---------------------------------------------------------------------------

  Widget _buildExerciseBreakdown(ThemeData theme, WorkoutSummaryState state) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final summary = state.exerciseSummaries[index];
            return _buildExerciseCard(theme, summary);
          },
          childCount: state.exerciseSummaries.length,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ThemeData theme, ExerciseSummary summary) {
    final bestWeightStr = summary.bestWeight != null
        ? ' · Best: ${summary.bestWeight!.toStringAsFixed(1)} kg'
        : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Exercise icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.exerciseName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.setsCompleted} sets · ${summary.totalReps} total reps$bestWeightStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Volume
            Text(
              '${summary.totalVolume.toStringAsFixed(0)} kg',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Row
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(ThemeData theme, WorkoutSummaryState state) {
    final avgRpe = _calculateAvgRpe(widget.logs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.repeat,
                value: '${state.totalSets}',
                label: 'Total Sets',
                theme: theme,
              ),
            ),
            _StatDivider(theme: theme),
            Expanded(
              child: _StatItem(
                icon: Icons.exposure,
                value: '${state.totalReps}',
                label: 'Total Reps',
                theme: theme,
              ),
            ),
            _StatDivider(theme: theme),
            Expanded(
              child: _StatItem(
                icon: Icons.speed,
                value: avgRpe != null ? avgRpe.toStringAsFixed(1) : '—',
                label: 'Avg RPE',
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Buttons
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _onDone,
            icon: const Icon(Icons.check_circle),
            label: const Text('Done'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _onSaveAsTemplate,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save as Template'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _onShare,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onDone() {
    // Pop back to dashboard
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onShare() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Screenshot captured!'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture screenshot'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onSaveAsTemplate() async {
    final name = await _showTemplateNameDialog();
    if (name == null || name.trim().isEmpty) return;

    try {
      await ref
          .read(workoutSummaryProvider.notifier)
          .saveAsTemplate(widget.session.id, name: name.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save template'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _showTemplateNameDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _TemplateNameDialog(
        initialName: widget.session.name ?? '',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<WorkoutSet> _toWorkoutSets(List<ClientExerciseLog> logs) {
    return logs
        .where((log) => log.isCompleted == true)
        .map((log) => WorkoutSet(
              id: log.id,
              logId: log.exerciseId,
              reps: log.reps,
              weight: log.weight,
              rpe: log.rpe,
              isCompleted: true,
            ))
        .toList();
  }

  Map<String, String> _buildExerciseNames(List<ClientExerciseLog> logs) {
    final names = <String, String>{};
    for (final log in logs) {
      if (log.exerciseName != null &&
          !names.containsKey(log.exerciseId)) {
        names[log.exerciseId] = log.exerciseName!;
      }
    }
    return names;
  }

  double? _calculateE1RM(double? weight, int? reps) {
    if (weight == null || reps == null || reps < 1 || weight <= 0) return null;
    // Epley formula: weight × (1 + reps / 30)
    return weight * (1 + reps / 30.0);
  }

  double? _calculateAvgRpe(List<ClientExerciseLog> logs) {
    final withRpe = logs.where((l) => l.rpe != null).toList();
    if (withRpe.isEmpty) return null;
    final total = withRpe.fold<double>(0, (sum, l) => sum + l.rpe!);
    return total / withRpe.length;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// Confetti Effect
// ---------------------------------------------------------------------------

class _ConfettiEffect extends StatefulWidget {
  final AnimationController controller;

  const _ConfettiEffect({required this.controller});

  @override
  State<_ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<_ConfettiEffect> {
  late final List<_ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      30,
      (i) => _ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.008 + _random.nextDouble() * 0.015,
        size: 4 + _random.nextDouble() * 6,
        color: [
          Colors.amber,
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.purple,
          Colors.orange,
        ][_random.nextInt(6)],
        delay: _random.nextDouble() * 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: widget.controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double delay;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final adjustedProgress = (progress - p.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final fadeOut = 1.0 - adjustedProgress;
      if (fadeOut <= 0) continue;

      final x = p.x * size.width;
      final y = p.y * size.height - adjustedProgress * size.height * 0.6;
      final wobble = sin(adjustedProgress * 20) * 8;

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x + wobble, y),
        p.size * (0.5 + fadeOut * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Template Name Dialog
// ---------------------------------------------------------------------------

class _TemplateNameDialog extends StatefulWidget {
  final String initialName;

  const _TemplateNameDialog({required this.initialName});

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as Template'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Template Name',
          hintText: 'Enter a name for this template',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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

class _StatDivider extends StatelessWidget {
  final ThemeData theme;

  const _StatDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: theme.colorScheme.outlineVariant,
    );
  }
}
