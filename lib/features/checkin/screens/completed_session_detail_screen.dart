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
  final List<CompletedExercise> exercises;

  const CompletedSessionDetail({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.notes,
    this.exercises = const [],
  });

  factory CompletedSessionDetail.fromJson(Map<String, dynamic> json) {
    final exercisesRaw = json['exercises'] as List<dynamic>? ?? [];
    final exercises = exercisesRaw
        .map((e) =>
            CompletedExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return CompletedSessionDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Workout Session',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      notes: json['notes'] as String?,
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
}

class CompletedExercise {
  final String name;
  final List<CompletedSet> sets;

  const CompletedExercise({
    required this.name,
    this.sets = const [],
  });

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    final setsRaw = json['sets'] as List<dynamic>? ?? [];
    final sets = setsRaw
        .map((s) => CompletedSet.fromJson(s as Map<String, dynamic>))
        .toList();

    return CompletedExercise(
      name: json['name'] as String? ?? json['exercise_name'] as String? ?? 'Exercise',
      sets: sets,
    );
  }
}

class CompletedSet {
  final int? reps;
  final double? weight;
  final int? setNumber;

  const CompletedSet({
    this.reps,
    this.weight,
    this.setNumber,
  });

  factory CompletedSet.fromJson(Map<String, dynamic> json) => CompletedSet(
        reps: json['reps'] as int?,
        weight: (json['weight'] as num?)?.toDouble(),
        setNumber: json['set_number'] as int? ??
            json['setNumber'] as int?,
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
      final detail = CompletedSessionDetail.fromJson(data);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.name ?? 'Session Details'),
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
            Card(
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
                  ],
                ),
              ),
            ),

            // Notes
            if (detail.notes != null && detail.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.notes!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Exercises
            if (detail.exercises.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...detail.exercises.map((exercise) => _buildExerciseCard(
                    theme,
                    exercise,
                  )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

  Widget _buildExerciseCard(ThemeData theme, CompletedExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (exercise.sets.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Header row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Set',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Weight',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Reps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 8),
              ...exercise.sets.asMap().entries.map((entry) {
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${set.setNumber ?? entry.key + 1}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          set.weight != null
                              ? '${set.weight!.toStringAsFixed(1)} kg'
                              : '—',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          set.reps != null ? '${set.reps}' : '—',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
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
