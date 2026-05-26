library;

// ---------------------------------------------------------------------------
// TimelineSlot — a single time slot within a day
// ---------------------------------------------------------------------------

class TimelineSlot {
  final String id;
  final String? templateId;
  final String? templateName;
  final int exerciseCount;
  final String? startTime;
  final int? durationMinutes;

  const TimelineSlot({
    required this.id,
    this.templateId,
    this.templateName,
    this.exerciseCount = 0,
    this.startTime,
    this.durationMinutes,
  });

  /// Creates an empty slot (no template assigned).
  factory TimelineSlot.empty(String id) => TimelineSlot(id: id);

  /// Assigns (or replaces) the template info on this slot.
  TimelineSlot copyWithTemplate({
    required String templateId,
    required String templateName,
    required int exerciseCount,
  }) {
    return TimelineSlot(
      id: id,
      templateId: templateId,
      templateName: templateName,
      exerciseCount: exerciseCount,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
  }

  /// Removes the template assignment, leaving the slot empty.
  TimelineSlot copyWithoutTemplate() {
    return TimelineSlot(
      id: id,
      templateId: null,
      templateName: null,
      exerciseCount: 0,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
  }

  TimelineSlot copyWith({
    String? id,
    String? templateId,
    bool clearTemplateId = false,
    String? templateName,
    bool clearTemplateName = false,
    int? exerciseCount,
    String? startTime,
    bool clearStartTime = false,
    int? durationMinutes,
  }) {
    return TimelineSlot(
      id: id ?? this.id,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      templateName:
          clearTemplateName ? null : (templateName ?? this.templateName),
      exerciseCount: exerciseCount ?? this.exerciseCount,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  /// Whether this slot has a template assigned.
  bool get hasTemplate => templateId != null && templateName != null;

  @override
  String toString() =>
      'TimelineSlot(id: $id, templateId: $templateId, '
      'templateName: $templateName, exerciseCount: $exerciseCount, '
      'startTime: $startTime, durationMinutes: $durationMinutes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineSlot &&
          id == other.id &&
          templateId == other.templateId &&
          templateName == other.templateName &&
          exerciseCount == other.exerciseCount &&
          startTime == other.startTime &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        templateId,
        templateName,
        exerciseCount,
        startTime,
        durationMinutes,
      );
}

// ---------------------------------------------------------------------------
// TimelineDay — a single day containing multiple time slots
// ---------------------------------------------------------------------------

class TimelineDay {
  final String id;
  final int dayNumber;
  final String name;
  final List<TimelineSlot> slots;

  const TimelineDay({
    required this.id,
    required this.dayNumber,
    required this.name,
    this.slots = const [],
  });

  /// Creates a day with a single empty morning slot.
  factory TimelineDay.withDefaultSlot({
    required String id,
    required int dayNumber,
    required String name,
  }) {
    return TimelineDay(
      id: id,
      dayNumber: dayNumber,
      name: name,
      slots: [TimelineSlot.empty('${id}_slot_0')],
    );
  }

  TimelineDay copyWith({
    String? id,
    int? dayNumber,
    String? name,
    List<TimelineSlot>? slots,
  }) {
    return TimelineDay(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      slots: slots ?? this.slots,
    );
  }

  @override
  String toString() =>
      'TimelineDay(id: $id, dayNumber: $dayNumber, name: $name, '
      'slots: ${slots.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineDay &&
          id == other.id &&
          dayNumber == other.dayNumber &&
          name == other.name &&
          _listEquals(slots, other.slots);

  @override
  int get hashCode => Object.hash(id, dayNumber, name, Object.hashAll(slots));
}

// ---------------------------------------------------------------------------
// TimelineWeek — a week containing multiple days
// ---------------------------------------------------------------------------

class TimelineWeek {
  final String id;
  final int weekNumber;
  final String name;
  final List<TimelineDay> days;

  const TimelineWeek({
    required this.id,
    required this.weekNumber,
    required this.name,
    this.days = const [],
  });

  /// Creates a week with 7 days, each having one default slot.
  factory TimelineWeek.withDefaultDays({
    required String id,
    required int weekNumber,
    required String name,
  }) {
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday',
    ];
    final days = List<TimelineDay>.generate(7, (i) {
      final dayId = '${id}_day_$i';
      return TimelineDay.withDefaultSlot(
        id: dayId,
        dayNumber: i + 1,
        name: dayNames[i],
      );
    });
    return TimelineWeek(id: id, weekNumber: weekNumber, name: name, days: days);
  }

  TimelineWeek copyWith({
    String? id,
    int? weekNumber,
    String? name,
    List<TimelineDay>? days,
  }) {
    return TimelineWeek(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      name: name ?? this.name,
      days: days ?? this.days,
    );
  }

  @override
  String toString() =>
      'TimelineWeek(id: $id, weekNumber: $weekNumber, name: $name, '
      'days: ${days.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineWeek &&
          id == other.id &&
          weekNumber == other.weekNumber &&
          name == other.name &&
          _listEquals(days, other.days);

  @override
  int get hashCode =>
      Object.hash(id, weekNumber, name, Object.hashAll(days));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Compares two lists for element-wise equality (uses `==` on each element).
bool _listEquals(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Generates a simple unique ID based on the current timestamp.
String generateTimelineId() =>
    '${DateTime.now().millisecondsSinceEpoch}_'
    '${DateTime.now().microsecondsSinceEpoch % 1000}';
