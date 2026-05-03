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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientExerciseLog.fromJson(Map<String, dynamic> json) =>
      ClientExerciseLog(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        exerciseId: json['exercise_id'] as String,
        reps: json['reps'] as int?,
        weight: (json['weight'] as num?)?.toDouble(),
        isCompleted: json['is_completed'] as bool?,
        order: json['order'] as int?,
        tempo: json['tempo'] as String?,
        side: (json['side'] as String?) ?? 'BOTH',
        workoutSessionId:
            json['workout_session_id'] as String,
        supersetKey: json['superset_key'] as String?,
        orderInSuperset: json['order_in_superset'] as int?,
        sets: json['sets'] as List<dynamic>?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

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
      'sets: $sets, createdAt: $createdAt, updatedAt: $updatedAt, '
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
        createdAt,
        updatedAt,
        deletedAt,
      );
}
