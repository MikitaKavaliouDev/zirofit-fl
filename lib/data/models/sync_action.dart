import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// Type of sync action for offline queue
enum SyncActionType {
  logSet,
  finishWorkout,
  addExercise,
  removeExercise,
  uploadMedia;

  static SyncActionType fromJson(String? json) {
    if (json == null) return SyncActionType.logSet;
    switch (json.toUpperCase()) {
      case 'LOG_SET':
        return SyncActionType.logSet;
      case 'FINISH_WORKOUT':
        return SyncActionType.finishWorkout;
      case 'ADD_EXERCISE':
        return SyncActionType.addExercise;
      case 'REMOVE_EXERCISE':
        return SyncActionType.removeExercise;
      case 'UPLOAD_MEDIA':
        return SyncActionType.uploadMedia;
      default:
        return SyncActionType.logSet;
    }
  }

  String toJson() => name;
}

/// A sync action to be performed when online
class SyncAction {
  final String id;
  final SyncActionType actionType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final bool isProcessed;

  const SyncAction({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.isProcessed = false,
  });

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
        id: json['id'] as String,
        actionType: SyncActionType.fromJson(json['action_type'] as String?),
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        createdAt: readDateTimeOrNull(json, 'created_at', 'createdAt') ?? DateTime.now(),
        retryCount: json['retry_count'] as int? ?? 0,
        isProcessed: json['is_processed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'action_type': actionType.toJson(),
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'is_processed': isProcessed,
      };

  SyncAction copyWith({
    String? id,
    SyncActionType? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    bool? isProcessed,
  }) =>
      SyncAction(
        id: id ?? this.id,
        actionType: actionType ?? this.actionType,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        isProcessed: isProcessed ?? this.isProcessed,
      );
}

/// Payload for logging a set
class LogSetPayload {
  final String sessionId;
  final String exerciseId;
  final String? exerciseName;
  final int? reps;
  final double? weight;
  final double? rpe;
  final SetStatus? setStatus;
  final bool isCompleted;

  const LogSetPayload({
    required this.sessionId,
    required this.exerciseId,
    this.exerciseName,
    this.reps,
    this.weight,
    this.rpe,
    this.setStatus,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'exercise_id': exerciseId,
        if (exerciseName != null) 'exercise_name': exerciseName,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (rpe != null) 'rpe': rpe,
        if (setStatus != null) 'set_status': setStatus!.toJson(),
        'is_completed': isCompleted,
      };
}

/// Payload for finishing a workout
class FinishWorkoutPayload {
  final String sessionId;
  final bool completeUnfinished;
  final String? notes;

  const FinishWorkoutPayload({
    required this.sessionId,
    this.completeUnfinished = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'complete_unfinished': completeUnfinished,
        if (notes != null) 'notes': notes,
      };
}

// Import SetStatus
enum SetStatus {
  normal,
  warmUp,
  dropSet,
  failure;

  static SetStatus fromJson(String? json) {
    if (json == null) return SetStatus.normal;
    switch (json.toUpperCase()) {
      case 'WARM_UP':
      case 'WARMUP':
        return SetStatus.warmUp;
      case 'DROP_SET':
        return SetStatus.dropSet;
      case 'FAILURE':
        return SetStatus.failure;
      default:
        return SetStatus.normal;
    }
  }

  String toJson() => name;
}