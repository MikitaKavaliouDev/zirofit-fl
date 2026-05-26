import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/programs/data/program_template_remote_source.dart';
import 'package:zirofit_fl/features/programs/models/timeline_models.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Represents the full editing state for the Visual Timeline Builder.
class TimelineBuilderState {
  final String programName;
  final String description;
  final List<TimelineWeek> weeks;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const TimelineBuilderState({
    this.programName = '',
    this.description = '',
    this.weeks = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  TimelineBuilderState copyWith({
    String? programName,
    String? description,
    List<TimelineWeek>? weeks,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return TimelineBuilderState(
      programName: programName ?? this.programName,
      description: description ?? this.description,
      weeks: weeks ?? this.weeks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  String toString() =>
      'TimelineBuilderState(programName: $programName, '
      'description: $description, weeks: ${weeks.length}, '
      'isLoading: $isLoading, error: $error, isSaving: $isSaving)';
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages all state transitions for the drag-drop timeline builder.
class TimelineBuilderNotifier
    extends StateNotifier<TimelineBuilderState> {
  final ProgramTemplateRemoteSource _remoteSource;

  TimelineBuilderNotifier({ProgramTemplateRemoteSource? remoteSource})
      : _remoteSource = remoteSource ?? ProgramTemplateRemoteSource(Dio()),
        super(_initialState());

  /// Creates the default initial state: one week with 7 days,
  /// each day having a single morning slot.
  static TimelineBuilderState _initialState() {
    final weekId = generateTimelineId();
    final week = TimelineWeek.withDefaultDays(
      id: weekId,
      weekNumber: 1,
      name: 'Week 1',
    );
    return TimelineBuilderState(weeks: [week]);
  }

  // ---------------------------------------------------------------------------
  // Program metadata
  // ---------------------------------------------------------------------------

  void setName(String name) {
    state = state.copyWith(programName: name);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  // ---------------------------------------------------------------------------
  // Week management
  // ---------------------------------------------------------------------------

  /// Appends a new week with 7 default days.
  void addWeek() {
    final weekNumber = state.weeks.length + 1;
    final week = TimelineWeek.withDefaultDays(
      id: generateTimelineId(),
      weekNumber: weekNumber,
      name: 'Week $weekNumber',
    );
    state = state.copyWith(weeks: [...state.weeks, week]);
  }

  /// Removes a week by ID. If only one week remains, no-op.
  void removeWeek(String weekId) {
    if (state.weeks.length <= 1) return;
    final weeks = state.weeks.where((w) => w.id != weekId).toList();
    // Renumber remaining weeks
    final renumbered = weeks.asMap().entries.map((e) {
      final newNumber = e.key + 1;
      return e.value.copyWith(
        weekNumber: newNumber,
        name: 'Week $newNumber',
      );
    }).toList();
    state = state.copyWith(weeks: renumbered);
  }

  /// Reorders weeks via drag-and-drop.
  void reorderWeeks(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final weeks = [...state.weeks];
    final item = weeks.removeAt(oldIndex);
    weeks.insert(newIndex, item);
    // Renumber
    final renumbered = weeks.asMap().entries.map((e) {
      final newNumber = e.key + 1;
      return e.value.copyWith(
        weekNumber: newNumber,
        name: 'Week $newNumber',
      );
    }).toList();
    state = state.copyWith(weeks: renumbered);
  }

  // ---------------------------------------------------------------------------
  // Day management
  // ---------------------------------------------------------------------------

  /// Adds a new day to the specified week.
  void addDay(String weekId) {
    final weeks = state.weeks.map((week) {
      if (week.id != weekId) return week;
      final dayNumber = week.days.length + 1;
      final day = TimelineDay.withDefaultSlot(
        id: '${week.id}_day_$dayNumber',
        dayNumber: dayNumber,
        name: 'Day $dayNumber',
      );
      return week.copyWith(days: [...week.days, day]);
    }).toList();
    state = state.copyWith(weeks: weeks);
  }

  /// Removes a day from the specified week.
  void removeDay(String weekId, String dayId) {
    final weeks = state.weeks.map((week) {
      if (week.id != weekId) return week;
      final days = week.days.where((d) => d.id != dayId).toList();
      // Renumber remaining days
      final renumbered = days.asMap().entries.map((e) {
        final newNumber = e.key + 1;
        return e.value.copyWith(
          dayNumber: newNumber,
          name: 'Day $newNumber',
        );
      }).toList();
      return week.copyWith(days: renumbered);
    }).toList();
    state = state.copyWith(weeks: weeks);
  }

  // ---------------------------------------------------------------------------
  // Slot / template assignment
  // ---------------------------------------------------------------------------

  /// Assigns a workout template to a slot identified by [slotId].
  void assignTemplate(
    String slotId,
    String templateId,
    String templateName,
    int exerciseCount,
  ) {
    final weeks = _mapSlots(state.weeks, slotId, (slot) {
      return slot.copyWithTemplate(
        templateId: templateId,
        templateName: templateName,
        exerciseCount: exerciseCount,
      );
    });
    state = state.copyWith(weeks: weeks);
  }

  /// Removes the template from a slot, leaving it empty.
  void removeTemplate(String slotId) {
    final weeks = _mapSlots(state.weeks, slotId, (slot) {
      return slot.copyWithoutTemplate();
    });
    state = state.copyWith(weeks: weeks);
  }

  // ---------------------------------------------------------------------------
  // Persistence stubs (Phase 7.3)
  // ---------------------------------------------------------------------------

  /// Loads a program timeline from the API.
  Future<void> loadProgram(String programId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _remoteSource.loadTimeline(programId);
      final data = response['data'];

      // The program data may be nested under `data` or `data.program`.
      Map<String, dynamic> programData;
      if (data is Map<String, dynamic>) {
        programData = (data['program'] as Map<String, dynamic>?) ?? data;
      } else {
        programData = response;
      }

      final name = programData['name'] as String? ?? '';
      final description = programData['description'] as String? ?? '';

      // Parse the timeline.weeks nested structure.
      final timelineRaw = programData['timeline'];
      final List<TimelineWeek> weeks;
      if (timelineRaw is Map<String, dynamic>) {
        weeks = _parseWeeks(timelineRaw['weeks']);
      } else {
        weeks = _parseWeeks(programData['weeks']);
      }

      state = state.copyWith(
        programName: name,
        description: description,
        weeks: weeks.isNotEmpty ? weeks : state.weeks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Saves the current program timeline to the API.
  /// Creates a new program via POST /trainer/programs.
  Future<bool> saveProgram() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final timelinePayload = _buildTimelinePayload();
      await _remoteSource.saveTimeline('', timelinePayload);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Serialization / Deserialization helpers
  // ---------------------------------------------------------------------------

  /// Builds the full timeline payload from the current state.
  Map<String, dynamic> _buildTimelinePayload() {
    return {
      'name': state.programName,
      'description': state.description,
      'timeline': {
        'weeks': state.weeks.map((week) => {
          'weekNumber': week.weekNumber,
          'name': week.name,
          'days': week.days.map((day) => {
            'dayNumber': day.dayNumber,
            'name': day.name,
            'slots': day.slots.map((slot) => {
              'templateId': slot.templateId,
              'templateName': slot.templateName,
              'exerciseCount': slot.exerciseCount,
              'startTime': slot.startTime,
            }).toList(),
          }).toList(),
        }).toList(),
      },
    };
  }

  /// Parses a list of raw week maps into [TimelineWeek] objects.
  List<TimelineWeek> _parseWeeks(dynamic weeksRaw) {
    if (weeksRaw is! List) return [];
    return weeksRaw.map((w) {
      final weekMap = w as Map<String, dynamic>;
      final weekId = generateTimelineId();
      final weekNumber = weekMap['weekNumber'] as int? ?? 1;
      final weekName = weekMap['name'] as String? ?? 'Week $weekNumber';
      final daysRaw = weekMap['days'] as List? ?? [];
      final days = daysRaw.map((d) {
        final dayMap = d as Map<String, dynamic>;
        final dayId = '${weekId}_day_${dayMap['dayNumber'] ?? 0}';
        final dayNumber = dayMap['dayNumber'] as int? ?? 1;
        final dayName = dayMap['name'] as String? ?? 'Day $dayNumber';
        final slotsRaw = dayMap['slots'] as List? ?? [];
        final slots = slotsRaw.map((s) {
          final slotMap = s as Map<String, dynamic>;
          final slotId = '${dayId}_slot_${slotsRaw.indexOf(s)}';
          return TimelineSlot(
            id: slotId,
            templateId: slotMap['templateId'] as String?,
            templateName: slotMap['templateName'] as String?,
            exerciseCount: slotMap['exerciseCount'] as int? ?? 0,
            startTime: slotMap['startTime'] as String?,
          );
        }).toList();
        return TimelineDay(
          id: dayId,
          dayNumber: dayNumber,
          name: dayName,
          slots: slots.isNotEmpty ? slots : [TimelineSlot.empty('${dayId}_slot_0')],
        );
      }).toList();
      return TimelineWeek(
        id: weekId,
        weekNumber: weekNumber,
        name: weekName,
        days: days,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Traverses all weeks/days to find a slot by [slotId] and apply [update].
  static List<TimelineWeek> _mapSlots(
    List<TimelineWeek> weeks,
    String slotId,
    TimelineSlot Function(TimelineSlot) update,
  ) {
    return weeks.map((week) {
      return week.copyWith(
        days: week.days.map((day) {
          return day.copyWith(
            slots: day.slots.map((slot) {
              return slot.id == slotId ? update(slot) : slot;
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }

  /// Extracts a user-friendly error message from various error types.
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the timeline builder state and notifier.
final timelineBuilderProvider =
    StateNotifierProvider<TimelineBuilderNotifier, TimelineBuilderState>((ref) {
  final remoteSource = ref.watch(programTemplateRemoteSourceProvider);
  return TimelineBuilderNotifier(remoteSource: remoteSource);
});
