import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/services/apple_calendar_service.dart';
import 'package:zirofit_fl/features/workout/providers/upcoming_session_provider.dart';

// ---------------------------------------------------------------------------
// UpcomingSessionDetailScreen
// ---------------------------------------------------------------------------

class UpcomingSessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const UpcomingSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<UpcomingSessionDetailScreen> createState() =>
      _UpcomingSessionDetailScreenState();
}

class _UpcomingSessionDetailScreenState
    extends ConsumerState<UpcomingSessionDetailScreen> {
  bool _addedToCalendar = false;
  bool _isAddingToCalendar = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(upcomingSessionProvider(widget.sessionId).notifier)
          .fetch();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _addToCalendar({
    required String? title,
    required DateTime start,
    required DateTime? end,
    required String? notes,
  }) async {
    setState(() => _isAddingToCalendar = true);

    try {
      final calendarService = ref.read(appleCalendarServiceProvider);

      // Request permission first
      final hasPermission = await calendarService.hasPermission();
      if (!hasPermission) {
        final granted = await calendarService.requestPermission();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Calendar permission denied. Please enable it in Settings.',
              ),
            ),
          );
          setState(() => _isAddingToCalendar = false);
          return;
        }
      }

      final result = await calendarService.createEvent(
        title: title ?? 'Workout Session',
        start: start,
        end: end ?? start.add(const Duration(hours: 1)),
        notes: notes,
      );

      if (result != null && mounted) {
        setState(() => _addedToCalendar = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session added to your calendar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add event to calendar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(upcomingSessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(theme, state),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, UpcomingSessionState state) {
    switch (state) {
      case UpcomingSessionInitial():
        return const SizedBox.shrink();

      case UpcomingSessionLoading():
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );

      case UpcomingSessionError():
        return _buildErrorState(theme, state);

      case UpcomingSessionLoaded():
        return _buildContent(theme, state);
    }
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(ThemeData theme, UpcomingSessionError state) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Could not load session details.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(upcomingSessionProvider(widget.sessionId).notifier)
                    .fetch();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content (loaded state)
  // ---------------------------------------------------------------------------

  Widget _buildContent(ThemeData theme, UpcomingSessionLoaded state) {
    final session = state.session;
    final exercises = state.exercises;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildHeaderCard(theme, state, dateFormat, timeFormat),

          // Duration
          if (session.endTime != null) ...[
            const SizedBox(height: 12),
            _buildDurationChip(theme, session),
          ],

          // Exercise list section
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildExercisesSection(theme, exercises),
          ],

          // Add to Calendar button
          const SizedBox(height: 24),
          _buildAddToCalendarButton(theme, state),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header Card
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(
    ThemeData theme,
    UpcomingSessionLoaded state,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final session = state.session;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name ?? 'Workout Session',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(session.startTime)} at ${timeFormat.format(session.startTime)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.fitness_center,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),

            // Trainer info
            if (state.clientName != null &&
                state.clientName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trainer: ${state.clientName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Duration
            if (session.endTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(
                      session.endTime!.difference(session.startTime),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Session notes preview
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Duration Chip
  // ---------------------------------------------------------------------------

  Widget _buildDurationChip(ThemeData theme, dynamic session) {
    final duration = _formatDuration(
      session.endTime!.difference(session.startTime),
    );
    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          duration,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Exercises Section
  // ---------------------------------------------------------------------------

  Widget _buildExercisesSection(
    ThemeData theme,
    List<dynamic> exercises,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...exercises.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < exercises.length - 1 ? 10 : 0,
                ),
                child: _buildExerciseCard(
                  theme,
                  entry.value as dynamic,
                ),
              ),
            ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Card
  // ---------------------------------------------------------------------------

  Widget _buildExerciseCard(ThemeData theme, dynamic log) {
    final exerciseName = log.exerciseName ?? 'Exercise';
    final reps = log.reps as int?;
    final weight = log.weight as double?;
    final tempo = log.tempo as String?;
    final rpe = log.rpe as double?;
    final notes = log.notes as String?;
    final videoUrl = log.videoUrl as String?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name + reps badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (reps != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$reps reps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            // Weight
            if (weight != null) ...[
              const SizedBox(height: 6),
              Text(
                '${weight.toStringAsFixed(1)} kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Tempo
            if (tempo != null && tempo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tempo: $tempo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // RPE
            if (rpe != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'RPE: ${rpe.toStringAsFixed(1)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Coaching cues / notes
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Watch Coaching Video button
            if (videoUrl != null && videoUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () => _openVideoUrl(videoUrl),
                  icon: Icon(
                    Icons.play_circle_fill,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  label: Text(
                    'Watch Coaching Video',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add to Calendar Button
  // ---------------------------------------------------------------------------

  Widget _buildAddToCalendarButton(
    ThemeData theme,
    UpcomingSessionLoaded state,
  ) {
    final isAdded = _addedToCalendar;
    final isAdding = _isAddingToCalendar;
    final session = state.session;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: isAdded || isAdding
            ? null
            : () => _addToCalendar(
                  title: session.name,
                  start: session.startTime,
                  end: session.endTime,
                  notes: session.notes,
                ),
        icon: isAdding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isAdded
                ? Icons.check_circle
                : Icons.calendar_month_outlined),
        label: Text(
          isAdded
              ? 'Added to Calendar'
              : isAdding
                  ? 'Adding…'
                  : 'Add to My Calendar',
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
              isAdded ? const Color(0xFF10B981) : theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _openVideoUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes.remainder(60);
      return '${hours}h ${remaining}m';
    }
    return '$minutes minutes';
  }
}
