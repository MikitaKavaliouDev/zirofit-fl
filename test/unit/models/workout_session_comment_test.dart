import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_session_comment.dart';

void main() {
  group('WorkoutSessionComment', () {
    final json = {
      'id': 'comment-1',
      'text': 'Great session!',
      'workout_session_id': 'ws-1',
      'user_id': 'user-1',
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final comment = WorkoutSessionComment.fromJson(json);

      expect(comment.id, 'comment-1');
      expect(comment.text, 'Great session!');
      expect(comment.workoutSessionId, 'ws-1');
      expect(comment.userId, 'user-1');
      expect(comment.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(comment.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(comment.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final comment = WorkoutSessionComment.fromJson(json);
      final output = comment.toJson();

      expect(output['id'], 'comment-1');
      expect(output['text'], 'Great session!');
      expect(output['workout_session_id'], 'ws-1');
      expect(output['user_id'], 'user-1');
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'comment-2',
        'text': 'Keep going',
        'workout_session_id': 'ws-2',
        'user_id': 'user-2',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final comment = WorkoutSessionComment.fromJson(minimal);

      expect(comment.id, 'comment-2');
      expect(comment.deletedAt, isNull);
    });

    test('equality', () {
      final a = WorkoutSessionComment.fromJson(json);
      final b = WorkoutSessionComment.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = WorkoutSessionComment.fromJson(json);
      final b = WorkoutSessionComment.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
