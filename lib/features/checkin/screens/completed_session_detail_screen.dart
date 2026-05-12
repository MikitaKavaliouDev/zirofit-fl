import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Data models for the completed session detail
// ---------------------------------------------------------------------------

/// Represents a completed session fetched from the API.
class CompletedSessionDetail {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final int? caloriesBurned;
  final List<CompletedExercise> exercises;

  const CompletedSessionDetail({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.notes,
    this.caloriesBurned,
    this.exercises = const [],
  });

  factory CompletedSessionDetail.fromJson(Map<String, dynamic> json) {
    // API returns exerciseLogs (camelCase) with nested exercise objects
    final exercisesRaw = json['exerciseLogs'] as List<dynamic>? ??
        json['exercises'] as List<dynamic>? ??
        [];
    final exercises = exercisesRaw
        .map((e) =>
            CompletedExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return CompletedSessionDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Workout Session',
      startTime: DateTime.parse(
        (json['startTime'] ?? json['start_time']) as String,
      ),
      endTime: (json['endTime'] ?? json['end_time']) != null
          ? DateTime.parse(
              (json['endTime'] ?? json['end_time']) as String,
            )
          : null,
      notes: json['notes'] as String?,
      caloriesBurned: json['caloriesBurned'] as int? ??
          json['calories'] as int?,
      exercises: exercises,
    );
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  double get totalVolume {
    double volume = 0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        volume += (set.weight ?? 0) * (set.reps ?? 0);
      }
    }
    return volume;
  }

  int get totalSets {
    int count = 0;
    for (final exercise in exercises) {
      count += exercise.sets.length;
    }
    return count;
  }
}

class CompletedExercise {
  final String name;
  final List<CompletedSet> sets;
  final bool isPersonalRecord;
  final String? prLabel;

  const CompletedExercise({
    required this.name,
    this.sets = const [],
    this.isPersonalRecord = false,
    this.prLabel,
  });

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    final setsRaw = json['sets'] as List<dynamic>? ?? [];
    final sets = setsRaw
        .map((s) => CompletedSet.fromJson(s as Map<String, dynamic>))
        .toList();

    // API returns exerciseLogs with nested exercise object:
    // { id, sets: [...], exercise: { id, name } }
    final exerciseObj = json['exercise'] as Map<String, dynamic>?;
    final name = exerciseObj?['name'] as String? ??
        json['exercise_name'] as String? ??
        json['name'] as String? ??
        'Exercise';

    return CompletedExercise(
      name: name,
      sets: sets,
      isPersonalRecord: json['is_personal_record'] as bool? ??
          json['isPR'] as bool? ??
          false,
      prLabel: json['pr_label'] as String? ?? json['record_type'] as String?,
    );
  }
}

class CompletedSet {
  final int? reps;
  final double? weight;
  final int? setNumber;
  final bool isCompleted;

  const CompletedSet({
    this.reps,
    this.weight,
    this.setNumber,
    this.isCompleted = true,
  });

  factory CompletedSet.fromJson(Map<String, dynamic> json) => CompletedSet(
        reps: json['reps'] as int?,
        weight: (json['weight'] as num?)?.toDouble(),
        setNumber: json['set_number'] as int? ??
            json['setNumber'] as int?,
        isCompleted: json['is_completed'] as bool? ??
            json['isCompleted'] as bool? ??
            true,
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CompletedSessionDetailState {
  final bool isLoading;
  final String? error;
  final CompletedSessionDetail? detail;

  const CompletedSessionDetailState({
    this.isLoading = false,
    this.error,
    this.detail,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CompletedSessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const CompletedSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<CompletedSessionDetailScreen> createState() =>
      _CompletedSessionDetailScreenState();
}

class _CompletedSessionDetailScreenState
    extends ConsumerState<CompletedSessionDetailScreen> {
  bool _isLoading = true;
  String? _error;
  CompletedSessionDetail? _detail;
  final Set<int> _expandedExercises = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final Map<String, dynamic> response = await api.get(
        ApiConstants.workoutSessionDetail(widget.sessionId),
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      // API wraps session inside data.session (camelCase)
      final sessionJson =
          data['session'] as Map<String, dynamic>? ?? data;
      final detail = CompletedSessionDetail.fromJson(sessionJson);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
        // Auto-expand first exercise
        if (detail.exercises.isNotEmpty) {
          _expandedExercises.add(0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _toggleExercise(int index) {
    setState(() {
      if (_expandedExercises.contains(index)) {
        _expandedExercises.remove(index);
      } else {
        _expandedExercises.add(index);
      }
    });
  }

  void _onEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit session — coming soon')),
    );
  }

  void _onShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share session — coming soon')),
    );
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session deleted')),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.name ?? 'Session Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _onEdit();
                  break;
                case 'share':
                  _onShare();
                  break;
                case 'delete':
                  _onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
              'Failed to load session details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session info card
            _buildSessionInfoCard(theme, detail, dateFormat, timeFormat),

            // Summary stats
            const SizedBox(height: 16),
            _buildSummaryStats(theme, detail),

            // Personal Records section
            if (detail.exercises.any((e) => e.isPersonalRecord)) ...[
              const SizedBox(height: 20),
              _buildPersonalRecordsSection(theme, detail),
            ],

            // Notes section
            if (detail.notes != null && detail.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesSection(theme, detail),
            ],

            // Exercises header
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${detail.totalSets} sets',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exercise list
            if (detail.exercises.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No exercises recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...detail.exercises.asMap().entries.map((entry) =>
                  _buildExerciseCard(theme, entry.value, entry.key)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Session Info Card
  // ---------------------------------------------------------------------------

  Widget _buildSessionInfoCard(
    ThemeData theme,
    CompletedSessionDetail detail,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Date & Time
            _infoRow(
              Icons.calendar_today,
              dateFormat.format(detail.startTime),
            ),
            const SizedBox(height: 4),
            _infoRow(
              Icons.access_time,
              '${timeFormat.format(detail.startTime)}'
              '${detail.endTime != null ? ' — ${timeFormat.format(detail.endTime!)}' : ''}',
            ),

            // Duration
            if (detail.duration != null) ...[
              const SizedBox(height: 4),
              _infoRow(
                Icons.timer_outlined,
                _formatDuration(detail.duration!),
              ),
            ],

            // Total volume
            if (detail.totalVolume > 0) ...[
              const SizedBox(height: 4),
              _infoRow(
                Icons.fitness_center,
                'Total Volume: ${detail.totalVolume.toStringAsFixed(0)} kg',
              ),
            ],

            // Exercises count
            const SizedBox(height: 4),
            _infoRow(
              Icons.repeat,
              '${detail.exercises.length} exercises, ${detail.totalSets} sets',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Stats
  // ---------------------------------------------------------------------------

  Widget _buildSummaryStats(ThemeData theme, CompletedSessionDetail detail) {
    final stats = <_StatItem>[
      _StatItem(
        icon: Icons.timer_outlined,
        value: detail.duration != null ? _formatDuration(detail.duration!) : '—',
        label: 'Duration',
        color: theme.colorScheme.primary,
      ),
      _StatItem(
        icon: Icons.monitor_weight_outlined,
        value: detail.totalVolume > 0
            ? '${detail.totalVolume.toStringAsFixed(0)} kg'
            : '—',
        label: 'Volume',
        color: const Color(0xFFF59E0B), // amber
      ),
      _StatItem(
        icon: Icons.local_fire_department,
        value: detail.caloriesBurned != null
            ? '${detail.caloriesBurned} kcal'
            : '—',
        label: 'Calories',
        color: const Color(0xFFEF4444), // red
      ),
      _StatItem(
        icon: Icons.repeat,
        value: '${detail.totalSets}',
        label: 'Total Sets',
        color: const Color(0xFF3B82F6), // blue
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat.icon, size: 20, color: stat.color),
                  const SizedBox(height: 4),
                  Text(
                    stat.value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Personal Records Section
  // ---------------------------------------------------------------------------

  Widget _buildPersonalRecordsSection(
    ThemeData theme,
    CompletedSessionDetail detail,
  ) {
    final prExercises =
        detail.exercises.where((e) => e.isPersonalRecord).toList();

    return Card(
      color: Colors.amber.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Personal Records',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E), // dark amber
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prExercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Gold star
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exercise.prLabel ?? 'PR',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes Section with timestamp
  // ---------------------------------------------------------------------------

  Widget _buildNotesSection(ThemeData theme, CompletedSessionDetail detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, h:mm a').format(detail.startTime),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detail.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Card (expandable)
  // ---------------------------------------------------------------------------

  Widget _buildExerciseCard(ThemeData theme, CompletedExercise exercise, int index) {
    final isExpanded = _expandedExercises.contains(index);
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Exercise header (tappable expand header)
          InkWell(
            onTap: () => _toggleExercise(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // PR badge
                  if (exercise.isPersonalRecord)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message: 'Personal Record',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Exercise name
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Set count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$completedSets/${exercise.sets.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Expand icon with rotation
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Expandable sets detail
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExerciseDetail(theme, exercise),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(ThemeData theme, CompletedExercise exercise) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.15),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            Row(
              children: [
                _setHeaderCell(theme, 'Set', flex: 1),
                _setHeaderCell(theme, 'Weight', flex: 2),
                _setHeaderCell(theme, 'Reps', flex: 2),
                _setHeaderCell(theme, 'Status', flex: 2),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 4),

            // Set rows
            ...exercise.sets.asMap().entries.map((entry) {
              final set = entry.value;
              final isCompleted = set.isCompleted;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Set number
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${set.setNumber ?? entry.key + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Weight
                    Expanded(
                      flex: 2,
                      child: Text(
                        set.weight != null
                            ? '${set.weight!.toStringAsFixed(1)} kg'
                            : '—',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    // Reps
                    Expanded(
                      flex: 2,
                      child: Text(
                        set.reps != null ? '${set.reps}' : '—',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    // Status indicator
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isCompleted
                                ? const Color(0xFF10B981) // green
                                : const Color(0xFF3B82F6), // blue
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Done' : 'Skipped',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _setHeaderCell(ThemeData theme, String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _infoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// ---------------------------------------------------------------------------
// Internal model for stats grid
// ---------------------------------------------------------------------------

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}
