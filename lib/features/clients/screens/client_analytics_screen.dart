import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

// =============================================================================
// Provider
// =============================================================================

final clientAnalyticsProvider = StateNotifierProvider.family<
    _ClientAnalyticsNotifier,
    _ClientAnalyticsState,
    String>(
  (ref, clientId) => _ClientAnalyticsNotifier(clientId),
);

// =============================================================================
// State
// =============================================================================

class _ClientAnalyticsState {
  final bool isLoading;
  final String? error;
  final List<_SessionData> sessions;
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;
  final List<_WeeklyVolume> weeklyVolumes;
  final List<_MuscleVolume> muscleDistribution;
  final List<_PrEntry> personalRecords;
  final List<String> heatmapDates;

  const _ClientAnalyticsState({
    this.isLoading = false,
    this.error,
    this.sessions = const [],
    this.totalWorkouts = 0,
    this.totalSets = 0,
    this.totalVolume = 0,
    this.weeklyVolumes = const [],
    this.muscleDistribution = const [],
    this.personalRecords = const [],
    this.heatmapDates = const [],
  });

  bool get hasData => sessions.isNotEmpty;

  _ClientAnalyticsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<_SessionData>? sessions,
    int? totalWorkouts,
    int? totalSets,
    double? totalVolume,
    List<_WeeklyVolume>? weeklyVolumes,
    List<_MuscleVolume>? muscleDistribution,
    List<_PrEntry>? personalRecords,
    List<String>? heatmapDates,
  }) {
    return _ClientAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sessions: sessions ?? this.sessions,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalSets: totalSets ?? this.totalSets,
      totalVolume: totalVolume ?? this.totalVolume,
      weeklyVolumes: weeklyVolumes ?? this.weeklyVolumes,
      muscleDistribution: muscleDistribution ?? this.muscleDistribution,
      personalRecords: personalRecords ?? this.personalRecords,
      heatmapDates: heatmapDates ?? this.heatmapDates,
    );
  }
}

// =============================================================================
// Data models (private to this screen)
// =============================================================================

class _SessionData {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final WorkoutSessionStatus status;
  final List<_ExerciseLogData> exerciseLogs;

  const _SessionData({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.exerciseLogs = const [],
  });
}

class _ExerciseLogData {
  final String exerciseName;
  final double weight;
  final int reps;
  final bool isCompleted;

  const _ExerciseLogData({
    required this.exerciseName,
    this.weight = 0,
    this.reps = 0,
    this.isCompleted = false,
  });

  double get volume => weight * reps;
}

class _WeeklyVolume {
  final DateTime weekStart;
  final Map<String, double> bodyPartVolumes;

  const _WeeklyVolume({
    required this.weekStart,
    required this.bodyPartVolumes,
  });
}

class _MuscleVolume {
  final String bodyPart;
  final double volume;

  const _MuscleVolume({
    required this.bodyPart,
    required this.volume,
  });
}

class _PrEntry {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const _PrEntry({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });
}

// =============================================================================
// Notifier
// =============================================================================

class _ClientAnalyticsNotifier
    extends StateNotifier<_ClientAnalyticsState> {
  final String clientId;

  _ClientAnalyticsNotifier(this.clientId)
      : super(const _ClientAnalyticsState());

  Future<void> loadAnalytics({int days = 3650}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '${ApiConstants.clients}/$clientId/sessions',
        queryParams: {'limit': 100},
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final rawSessions =
          (data['sessions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];

      final result = _processSessions(rawSessions, days);
      state = state.copyWith(
        isLoading: false,
        sessions: result.sessions,
        totalWorkouts: result.totalWorkouts,
        totalSets: result.totalSets,
        totalVolume: result.totalVolume,
        weeklyVolumes: result.weeklyVolumes,
        muscleDistribution: result.muscleDistribution,
        personalRecords: result.personalRecords,
        heatmapDates: result.heatmapDates,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  _ProcessedResult _processSessions(
    List<Map<String, dynamic>> rawSessions,
    int days,
  ) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final sessions = <_SessionData>[];
    final allExerciseLogs = <_ExerciseLogData>[];
    final heatmapDates = <String>{};
    int totalCompletedWorkouts = 0;
    int totalSets = 0;

    for (final raw in rawSessions) {
      final startTime =
          readDateTimeOrNull(raw, 'start_time', 'startTime') ?? DateTime.now();
      if (startTime.isBefore(cutoff)) continue;

      final status = WorkoutSessionStatus.fromJson(
        readStringOrNull(raw, 'status', 'status') ?? 'IN_PROGRESS',
      );
      final isCompleted = status == WorkoutSessionStatus.completed;

      if (isCompleted) {
        totalCompletedWorkouts++;
        heatmapDates.add(_formatDate(startTime));
      }

      final rawLogs =
          (raw['exerciseLogs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
      final logs = rawLogs.map((log) {
        final name = log['exerciseName'] as String? ?? 'Unknown';
        final weight = (log['weight'] as num?)?.toDouble() ?? 0;
        final reps = log['reps'] as int? ?? 0;
        final logCompleted = log['isCompleted'] as bool? ?? isCompleted;
        return _ExerciseLogData(
          exerciseName: name,
          weight: weight,
          reps: reps,
          isCompleted: logCompleted,
        );
      }).toList();

      allExerciseLogs.addAll(logs);
      if (isCompleted) {
        totalSets += logs.length;
      }

      sessions.add(_SessionData(
        id: raw['id'] as String? ?? '',
        name: raw['name'] as String? ?? 'Workout',
        startTime: startTime,
        endTime: readDateTimeOrNull(raw, 'end_time', 'endTime') ?? startTime,
        status: status,
        exerciseLogs: logs,
      ));
    }

    // --- Volume ---
    double totalVolume = 0;
    final volumeByExercise = <String, List<_ExerciseLogData>>{};
    for (final log in allExerciseLogs) {
      if (!log.isCompleted) continue;
      totalVolume += log.volume;
      volumeByExercise.putIfAbsent(log.exerciseName, () => []).add(log);
    }

    // --- Weekly volume grouped by body part ---
    final weeklyVolume = _computeWeeklyVolume(sessions);
    final weeklyVolumes = weeklyVolume.entries.map((entry) {
      return _WeeklyVolume(
        weekStart: entry.key,
        bodyPartVolumes: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    // --- Muscle distribution ---
    final muscleVolMap = <String, double>{};
    for (final log in allExerciseLogs) {
      if (!log.isCompleted || log.exerciseName == 'Unknown') continue;
      final bodyPart = _mapExerciseToBodyPart(log.exerciseName);
      muscleVolMap.update(bodyPart, (v) => v + log.volume, ifAbsent: () => log.volume);
    }
    final muscleDistribution = muscleVolMap.entries
        .map((e) => _MuscleVolume(bodyPart: e.key, volume: e.value))
        .toList()
      ..sort((a, b) => b.volume.compareTo(a.volume));

    // --- Personal Records (best weight per exercise) ---
    final bestWeightPerExercise = <String, _PrEntry>{};
    for (final log in allExerciseLogs) {
      if (!log.isCompleted || log.weight <= 0) continue;
      final existing = bestWeightPerExercise[log.exerciseName];
      if (existing == null || log.weight > existing.weight) {
        bestWeightPerExercise[log.exerciseName] = _PrEntry(
          exerciseName: log.exerciseName,
          weight: log.weight,
          reps: log.reps,
          date: _findSessionDate(sessions, log),
        );
      }
    }
    final personalRecords = bestWeightPerExercise.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return _ProcessedResult(
      sessions: sessions,
      totalWorkouts: totalCompletedWorkouts,
      totalSets: totalSets,
      totalVolume: totalVolume,
      weeklyVolumes: weeklyVolumes,
      muscleDistribution: muscleDistribution,
      personalRecords: personalRecords,
      heatmapDates: heatmapDates.toList()..sort(),
    );
  }

  Map<DateTime, Map<String, double>> _computeWeeklyVolume(
    List<_SessionData> sessions,
  ) {
    final result = <DateTime, Map<String, double>>{};

    for (final session in sessions) {
      if (session.status != WorkoutSessionStatus.completed) continue;
      final weekStart = _weekStart(session.startTime);

      for (final log in session.exerciseLogs) {
        if (!log.isCompleted) continue;
        final bodyPart = _mapExerciseToBodyPart(log.exerciseName);
        result.putIfAbsent(weekStart, () => <String, double>{});
        result[weekStart]!.update(
          bodyPart,
          (v) => v + log.volume,
          ifAbsent: () => log.volume,
        );
      }
    }

    return result;
  }

  DateTime _findSessionDate(List<_SessionData> sessions, _ExerciseLogData log) {
    for (final session in sessions) {
      if (session.exerciseLogs.any(
        (l) => identical(l, log) || l.exerciseName == log.exerciseName,
      )) {
        return session.startTime;
      }
    }
    return DateTime.now();
  }

  /// Maps exercise names to body part groups using keyword matching.
  String _mapExerciseToBodyPart(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('bench') ||
        name.contains('press') && !name.contains('shoulder') && !name.contains('overhead')) {
      return 'Chest';
    }
    if (name.contains('row') ||
        name.contains('pull') ||
        name.contains('lat') ||
        name.contains('deadlift') ||
        name.contains('back')) {
      return 'Back';
    }
    if (name.contains('squat') ||
        name.contains('leg') ||
        name.contains('lunge') ||
        name.contains('calf') ||
        name.contains('quad') ||
        name.contains('hamstring') ||
        name.contains('glute') ||
        name.contains('hip')) {
      return 'Legs';
    }
    if (name.contains('shoulder') ||
        name.contains('overhead') ||
        name.contains('ohp') ||
        name.contains('lateral') ||
        name.contains('front raise')) {
      return 'Shoulders';
    }
    if (name.contains('curl') ||
        name.contains('bicep') ||
        name.contains('tricep') ||
        name.contains('skull') ||
        name.contains('pushdown') ||
        name.contains('extension') ||
        name.contains('arm')) {
      return 'Arms';
    }
    if (name.contains('crunch') ||
        name.contains('sit') ||
        name.contains('plank') ||
        name.contains('ab') ||
        name.contains('core') ||
        name.contains('leg raise') ||
        name.contains('russian')) {
      return 'Core';
    }
    return 'Other';
  }

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProcessedResult {
  final List<_SessionData> sessions;
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;
  final List<_WeeklyVolume> weeklyVolumes;
  final List<_MuscleVolume> muscleDistribution;
  final List<_PrEntry> personalRecords;
  final List<String> heatmapDates;

  const _ProcessedResult({
    required this.sessions,
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    required this.weeklyVolumes,
    required this.muscleDistribution,
    required this.personalRecords,
    required this.heatmapDates,
  });
}

// =============================================================================
// Date Range enum
// =============================================================================

enum _DateRange {
  last7Days('7d'),
  last30Days('30d'),
  last90Days('90d'),
  allTime('All');

  final String label;
  const _DateRange(this.label);
}

// =============================================================================
// Screen
// =============================================================================

class ClientAnalyticsScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const ClientAnalyticsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<ClientAnalyticsScreen> createState() =>
      _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState
    extends ConsumerState<ClientAnalyticsScreen> {
  _DateRange _selectedRange = _DateRange.allTime;
  bool _initialLoadDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  void _loadData() {
    final days = _daysForRange(_selectedRange);
    ref
        .read(clientAnalyticsProvider(widget.clientId).notifier)
        .loadAnalytics(days: days);
  }

  int _daysForRange(_DateRange range) {
    switch (range) {
      case _DateRange.last7Days:
        return 7;
      case _DateRange.last30Days:
        return 30;
      case _DateRange.last90Days:
        return 90;
      case _DateRange.allTime:
        return 3650;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientAnalyticsProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<_DateRange>(
              value: _selectedRange,
              underline: const SizedBox(),
              isDense: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              items: _DateRange.values.map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(range.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null || value == _selectedRange) return;
                setState(() {
                  _selectedRange = value;
                });
                _loadData();
              },
            ),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, _ClientAnalyticsState state) {
    final theme = Theme.of(context);

    // Error state
    if (state.error != null && !state.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load analytics',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (!state.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No workout data yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete a workout to see analytics.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Content loaded
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(clientAnalyticsProvider(widget.clientId).notifier)
            .loadAnalytics(days: _daysForRange(_selectedRange));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading overlay when refreshing
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),

            // Summary Cards
            _SummaryCardsRow(
              workouts: state.totalWorkouts,
              sets: state.totalSets,
              volume: state.totalVolume,
            ),
            const SizedBox(height: 24),

            // Weekly Volume Chart
            if (state.weeklyVolumes.isNotEmpty) ...[
              const _SectionHeader(title: 'Weekly Volume'),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: _WeeklyVolumeChart(data: state.weeklyVolumes),
              ),
              const SizedBox(height: 24),
            ],

            // Muscle Distribution
            if (state.muscleDistribution.isNotEmpty) ...[
              const _SectionHeader(title: 'Muscle Distribution'),
              const SizedBox(height: 8),
              _MuscleDistributionChart(data: state.muscleDistribution),
              const SizedBox(height: 24),
            ],

            // Personal Records
            if (state.personalRecords.isNotEmpty) ...[
              const _SectionHeader(title: 'Personal Records'),
              const SizedBox(height: 8),
              _PersonalRecordsList(records: state.personalRecords),
              const SizedBox(height: 24),
            ],

            // Workout Heatmap
            if (state.heatmapDates.isNotEmpty) ...[
              const _SectionHeader(title: 'Workout Frequency'),
              const SizedBox(height: 8),
              _WorkoutHeatmap(dates: state.heatmapDates),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

// =============================================================================
// Summary Cards Row
// =============================================================================

class _SummaryCardsRow extends StatelessWidget {
  final int workouts;
  final int sets;
  final double volume;

  const _SummaryCardsRow({
    required this.workouts,
    required this.sets,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center,
            label: 'Workouts',
            value: workouts.toString(),
            color: Colors.blue,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.repeat,
            label: 'Sets',
            value: sets.toString(),
            color: Colors.green,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_up,
            label: 'Volume',
            value: '${volume.toStringAsFixed(0)} kg',
            color: Colors.orange,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Weekly Volume Chart (grouped bar chart using fl_chart)
// =============================================================================

class _WeeklyVolumeChart extends StatelessWidget {
  final List<_WeeklyVolume> data;

  const _WeeklyVolumeChart({required this.data});

  static const _bodyPartColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No volume data yet',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
        ),
      );
    }

    // Collect all unique body parts across all weeks
    final allBodyParts = <String>{};
    for (final week in data) {
      allBodyParts.addAll(week.bodyPartVolumes.keys);
    }
    final sortedParts = allBodyParts.toList()..sort();

    // Find max volume for scaling
    double maxVolume = 0;
    for (final week in data) {
      final weekTotal =
          week.bodyPartVolumes.values.fold<double>(0, (a, b) => a + b);
      if (weekTotal > maxVolume) maxVolume = weekTotal;
    }

    final yMax = (maxVolume * 1.25).clamp(1.0, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= data.length) return null;
              final week = data[groupIndex];
              final part = sortedParts.length > rodIndex
                  ? sortedParts[rodIndex]
                  : '';
              final vol = week.bodyPartVolumes[part] ?? 0;
              final dateStr = DateFormat.MMMd().format(week.weekStart);
              return BarTooltipItem(
                '$dateStr\n$part: ${vol.toStringAsFixed(0)} kg',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.MMMd().format(data[index].weekStart),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  _formatVolume(value),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.12),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final week = entry.value;
          final rods = sortedParts.asMap().entries.map((partEntry) {
            final vol = week.bodyPartVolumes[partEntry.value] ?? 0;
            return BarChartRodData(
              toY: vol,
              color:
                  _bodyPartColors[partEntry.key % _bodyPartColors.length],
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            );
          }).toList();
          return BarChartGroupData(
            x: entry.key,
            barRods: rods,
          );
        }).toList(),
      ),
    );
  }

  String _formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }
}

// =============================================================================
// Muscle Distribution Chart (horizontal bars)
// =============================================================================

class _MuscleDistributionChart extends StatelessWidget {
  final List<_MuscleVolume> data;

  const _MuscleDistributionChart({required this.data});

  static const _barColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVolume =
        data.fold<double>(0, (max, m) => m.volume > max ? m.volume : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final fraction = maxVolume > 0 ? item.volume / maxVolume : 0.0;
          final color = _barColors[index % _barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.bodyPart,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.volume.toStringAsFixed(0)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Personal Records List
// =============================================================================

class _PersonalRecordsList extends StatelessWidget {
  final List<_PrEntry> records;

  const _PersonalRecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRecords = records.take(10).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: displayRecords.asMap().entries.map((entry) {
          final pr = entry.value;
          final isLast = entry.key == displayRecords.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events,
                        size: 18, color: Colors.amber.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd().format(pr.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${pr.weight.toStringAsFixed(1)} kg',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${pr.reps} reps',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Workout Heatmap
// =============================================================================

class _WorkoutHeatmap extends StatelessWidget {
  final List<String> dates;

  const _WorkoutHeatmap({required this.dates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSet = dates.toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startRange = today.subtract(const Duration(days: 90));
    final startDay =
        startRange.subtract(Duration(days: startRange.weekday - 1));
    final totalDays = today.difference(startDay).inDays + 1;
    final allDays = List.generate(
      totalDays,
      (i) => startDay.add(Duration(days: i)),
    );

    final dateStrings = allDays.map((d) => _formatDate(d)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    'Mon', '', 'Wed', '', 'Fri', '', 'Sun',
                  ]
                      .map((label) => SizedBox(
                            height: 14,
                            child: label.isNotEmpty
                                ? Text(
                                    label,
                                    style: const TextStyle(
                                        fontSize: 8, color: Colors.grey),
                                  )
                                : const SizedBox.shrink(),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 4),
              // Scrollable grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthLabels(allDays),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 98,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 2,
                          runSpacing: 2,
                          children: dateStrings.map((dateStr) {
                            final isActive = activeSet.contains(dateStr);
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.7)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less',
                  style: TextStyle(fontSize: 9, color: Colors.grey)),
              const SizedBox(width: 4),
              ...List.generate(5, (index) {
                final alphas = [0.15, 0.3, 0.5, 0.7, 1.0];
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.grey.withValues(alpha: alphas[index])
                          : Colors.green.withValues(alpha: alphas[index]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              const Text('More',
                  style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildMonthLabels(List<DateTime> days) {
    final labels = <Widget>[];
    String? lastMonth;

    for (int i = 0; i < days.length; i += 7) {
      final day = days[i];
      final monthKey = '${day.year}-${day.month}';
      if (monthKey != lastMonth) {
        labels.add(Positioned(
          left: (i / 7) * 14,
          child: Text(
            _monthAbbr(day.month),
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ));
        lastMonth = monthKey;
      }
    }

    return SizedBox(
      height: 12,
      width: (days.length / 7).ceil() * 14.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: labels,
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
