import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_calendar_sheet.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(
      () => ref.read(workoutHistoryProvider.notifier).fetchHistory(),
    );
    // Listen for scroll-to-end pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(workoutHistoryProvider.notifier).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(workoutHistoryProvider.notifier).setSearchQuery(value);
    });
  }

  void _showCalendar() {
    final state = ref.read(workoutHistoryProvider);
    final completedDates = state.sessions.map((s) {
      return DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
    }).toSet();

    WorkoutCalendarSheet.show(
      context: context,
      completedDates: completedDates,
      onDateSelected: (date) {
        final dayStart = DateTime(date.year, date.month, date.day);
        ref.read(workoutHistoryProvider.notifier).setDateRange(
              DateRange(
                start: dayStart,
                end: dayStart,
                preset: DateRangePreset.custom,
              ),
            );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (picked != null && mounted) {
      ref.read(workoutHistoryProvider.notifier).setDateRange(
            DateRange(
              start: picked.start,
              end: picked.end,
              preset: DateRangePreset.custom,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Browse by date',
            onPressed: _showCalendar,
          ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(WorkoutHistoryState state, ThemeData theme) {
    // Initial loading
    if (state.isLoading && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(workoutHistoryProvider.notifier).fetchHistory(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // No sessions at all (not just filtered)
    if (state.sessions.isEmpty && !state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No workouts yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your first workout to see it here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(workoutHistoryProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Has sessions — build full UI with search + filter
    return Column(
      children: [
        // Search bar
        _buildSearchBar(theme),
        // Date range filter chips
        _buildFilterChips(state, theme),
        // Content
        Expanded(child: _buildContent(state, theme)),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by exercise or notes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(workoutHistoryProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(WorkoutHistoryState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChipButton(
              label: 'All',
              selected: state.dateRange == null,
              onTap: () =>
                  ref.read(workoutHistoryProvider.notifier).setDateRange(null),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: '7D',
              selected: state.dateRange?.preset == DateRangePreset.last7Days,
              onTap: () => ref
                  .read(workoutHistoryProvider.notifier)
                  .setDateRange(DateRange.last7Days()),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: '30D',
              selected: state.dateRange?.preset == DateRangePreset.last30Days,
              onTap: () => ref
                  .read(workoutHistoryProvider.notifier)
                  .setDateRange(DateRange.last30Days()),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: '3M',
              selected: state.dateRange?.preset == DateRangePreset.last3Months,
              onTap: () => ref
                  .read(workoutHistoryProvider.notifier)
                  .setDateRange(DateRange.last3Months()),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: 'Custom',
              selected: state.dateRange?.preset == DateRangePreset.custom,
              onTap: _showDateRangePicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WorkoutHistoryState state, ThemeData theme) {
    final filtered = state.filteredSessions;

    // Empty filtered results
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No matches found',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.searchQuery.isNotEmpty && state.dateRange != null
                    ? 'Try adjusting your search or filters.'
                    : state.searchQuery.isNotEmpty
                        ? 'No workouts match "${
                            state.searchQuery.length > 20
                                ? '${state.searchQuery.substring(0, 20)}…'
                                : state.searchQuery
                          }".'
                        : 'No workouts in this date range.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(workoutHistoryProvider.notifier).setSearchQuery('');
                  ref.read(workoutHistoryProvider.notifier).setDateRange(null);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }

    // Group by date
    final grouped = _groupByDate(filtered);
    final entries = grouped.entries.toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(workoutHistoryProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length + (state.hasMore && _isNoActiveFilter(state) ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator for pagination (only when no active filter)
          if (index == entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = entries[index];
          final dateStr = entry.key;
          final sessions = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date section header
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _formatDateHeader(dateStr),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Session cards for this date
              ...sessions.map(
                (session) => _WorkoutHistoryCard(
                  session: session,
                  onTap: () => _showWorkoutSummary(context, session),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isNoActiveFilter(WorkoutHistoryState state) {
    return state.searchQuery.isEmpty && state.dateRange == null;
  }

  /// Groups sessions by their date (yyyy-MM-dd).
  Map<String, List<WorkoutSession>> _groupByDate(
    List<WorkoutSession> sessions,
  ) {
    final grouped = <String, List<WorkoutSession>>{};
    for (final session in sessions) {
      final key = DateFormat('yyyy-MM-dd').format(session.startTime);
      grouped.putIfAbsent(key, () => []).add(session);
    }
    return grouped;
  }

  /// Formats a yyyy-MM-dd date string into a human-readable header.
  String _formatDateHeader(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == yesterday) return 'Yesterday';

    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  void _showWorkoutSummary(BuildContext context, WorkoutSession session) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.name ?? 'Workout',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(session.startTime),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.schedule,
                  label:
                      '${timeFormat.format(session.startTime)}${session.endTime != null ? ' – ${timeFormat.format(session.endTime!)}' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  label: session.endTime != null
                      ? _formatDuration(session.startTime, session.endTime!)
                      : 'In progress',
                ),
                const SizedBox(width: 8),
                if (session.endTime != null) ...[
                  const SizedBox(width: 8),
                  _SummaryChip(
                    icon: Icons.check_circle,
                    label: session.status.name == 'completed'
                        ? 'Completed'
                        : session.status.name,
                  ),
                ],
              ],
            ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// ---------------------------------------------------------------------------
// Filter Chip Button
// ---------------------------------------------------------------------------

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout History Card
// ---------------------------------------------------------------------------

class _WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;

  const _WorkoutHistoryCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    session.startTime.day.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name ?? 'Workout',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(session.startTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(session.startTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Duration / status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (session.endTime != null)
                    Text(
                      _formatDuration(session.startTime, session.endTime!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: session.status.name == 'completed'
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.status.name == 'completed'
                          ? 'Done'
                          : session.status.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: session.status.name == 'completed'
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// ---------------------------------------------------------------------------
// Summary Chip
// ---------------------------------------------------------------------------

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
