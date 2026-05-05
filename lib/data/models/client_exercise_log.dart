import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientExerciseLog {
  final String id;
  final String clientId;
  final String exerciseId;
  final int? reps;
  final double? weight;
  final bool? isCompleted;
  final int? order;
  final String? tempo;
  final String side;
  final String workoutSessionId;
  final String? supersetKey;
  final int? orderInSuperset;
  final List<dynamic>? sets;
  final double? rpe;
  final double? rir;
  final String? exerciseName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientExerciseLog({
    required this.id,
    required this.clientId,
    required this.exerciseId,
    this.reps,
    this.weight,
    this.isCompleted,
    this.order,
    this.tempo,
    this.side = 'BOTH',
    required this.workoutSessionId,
    this.supersetKey,
    this.orderInSuperset,
    this.sets,
    this.rpe,
    this.rir,
    this.exerciseName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientExerciseLog.fromJson(
    Map<String, dynamic> json,
  ) => ClientExerciseLog(
    id: json['id'] as String,
    clientId: () {
      // Try flat keys first (snake_case, camelCase)
      final flat = readStringOrNull(json, 'client_id', 'clientId');
      if (flat != null) return flat;
      // Fallback: nested client object (if backend sends {"client":{"id":"..."}})
      final clientMap = json['client'] as Map<String, dynamic>?;
      final nestedId = clientMap?['id'] as String?;
      if (nestedId != null) return nestedId;
      throw const FormatException('Missing client_id/clientId/client.id');
    }(),
    exerciseId: readString(json, 'exercise_id', 'exerciseId'),
    reps: json['reps'] as int?,
    weight: (json['weight'] as num?)?.toDouble(),
    isCompleted: _readIsCompleted(json),
    order: json['order'] as int?,
    tempo: json['tempo'] as String?,
    side: (json['side'] as String?) ?? 'BOTH',
    workoutSessionId: readString(
      json,
      'workout_session_id',
      'workoutSessionId',
    ),
    supersetKey: readStringOrNull(json, 'superset_key', 'supersetKey'),
    orderInSuperset: readIntOrNull(
      json,
      'order_in_superset',
      'orderInSuperset',
    ),
    sets: json['sets'] as List<dynamic>?,
    rpe: (json['rpe'] as num?)?.toDouble(),
    rir: (json['rir'] as num?)?.toDouble(),
    exerciseName: readStringOrNull(json, 'exercise_name', 'exerciseName'),
    createdAt: readDateTime(json, 'created_at', 'createdAt'),
    updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
    deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
  );

  /// Extracts the nullable [bool] for [isCompleted] from either snake_case or
  /// camelCase JSON key.
  static bool? _readIsCompleted(Map<String, dynamic> json) {
    final v = json['is_completed'] ?? json['isCompleted'];
    if (v is bool) return v;
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'exercise_id': exerciseId,
    'reps': reps,
    'weight': weight,
    'is_completed': isCompleted,
    'order': order,
    'tempo': tempo,
    'side': side,
    'workout_session_id': workoutSessionId,
    'superset_key': supersetKey,
    'order_in_superset': orderInSuperset,
    'sets': sets,
    'rpe': rpe,
    'rir': rir,
    'exercise_name': exerciseName,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };

  @override
  String toString() =>
      'ClientExerciseLog(id: $id, clientId: $clientId, '
      'exerciseId: $exerciseId, reps: $reps, weight: $weight, '
      'isCompleted: $isCompleted, order: $order, tempo: $tempo, '
      'side: $side, workoutSessionId: $workoutSessionId, '
      'supersetKey: $supersetKey, orderInSuperset: $orderInSuperset, '
      'sets: $sets, rpe: $rpe, rir: $rir, exerciseName: $exerciseName, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientExerciseLog &&
          id == other.id &&
          clientId == other.clientId &&
          exerciseId == other.exerciseId &&
          reps == other.reps &&
          weight == other.weight &&
          isCompleted == other.isCompleted &&
          order == other.order &&
          tempo == other.tempo &&
          side == other.side &&
          workoutSessionId == other.workoutSessionId &&
          supersetKey == other.supersetKey &&
          orderInSuperset == other.orderInSuperset &&
          sets == other.sets &&
          rpe == other.rpe &&
          rir == other.rir &&
          exerciseName == other.exerciseName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    exerciseId,
    reps,
    weight,
    isCompleted,
    order,
    tempo,
    side,
    workoutSessionId,
    supersetKey,
    orderInSuperset,
    sets,
    rpe,
    rir,
    exerciseName,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
