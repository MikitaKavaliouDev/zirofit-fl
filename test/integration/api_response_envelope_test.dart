import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/benefit.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/data/models/habit_log.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/notification_model.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a mock [Response] from a response [body] map.
///
/// Use this to simulate Dio responses at the transport level without any real
/// HTTP calls. The returned [Response.data] is [body]; the caller can verify
/// envelope parsing by passing [body] directly to [ApiResponse.fromJson].
Response<Map<String, dynamic>> _mockResponse(
  Map<String, dynamic> body, {
  String path = '',
  int statusCode = 200,
}) {
  return Response<Map<String, dynamic>>(
    data: body,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  );
}

/// Shortcut for `{"data": value}`.
Map<String, dynamic> _data(Map<String, dynamic> value) => {'data': value};

/// Shortcut for `{"data": list}`.
Map<String, dynamic> _dataList(List<dynamic> value) => {'data': value};

/// A fixed Unix-ms timestamp used in all test fixtures (2024-01-01T00:00:00Z).
const int kTimestamp = 1704067200000;

/// A second timestamp (2024-01-15T00:00:00Z).
const int kTimestamp2 = 1705276800000;

/// A third timestamp (2024-02-01T00:00:00Z).
const int kTimestamp3 = 1706745600000;

// =============================================================================
// 1. AUTH GROUP
// =============================================================================

void main() {
  group('Auth endpoints', () {
    test('POST /auth/login — parses tokens, user fields, and role', () {
      final body = _data({
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.test',
        'refreshToken': 'eyJhbGciOiJIUzI1NiJ9.refresh',
        'user': {
          'id': 'user-1',
          'email': 'trainer@ziro.fit',
          'name': 'Test Trainer',
        },
        'role': 'trainer',
      });

      final response = _mockResponse(body, path: ApiConstants.login);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, isNotNull);
      final data = envelope.data!;
      expect(data['accessToken'], 'eyJhbGciOiJIUzI1NiJ9.test');
      expect(data['refreshToken'], 'eyJhbGciOiJIUzI1NiJ9.refresh');
      expect(data['role'], 'trainer');
      expect((data['user'] as Map<String, dynamic>)['email'], 'trainer@ziro.fit');
    });

    test('POST /auth/register — parses userId, message, requiresSubscription, '
        'confirmationRequired', () {
      final body = _data({
        'userId': 'user-new-1',
        'message': 'Registration successful. Please verify your email.',
        'requiresSubscription': true,
        'confirmationRequired': true,
      });

      final response = _mockResponse(body, path: ApiConstants.register);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['userId'], 'user-new-1');
      expect(envelope.data!['requiresSubscription'], isTrue);
      expect(envelope.data!['confirmationRequired'], isTrue);
      expect(envelope.data!['message'], contains('Registration successful'));
    });

    test('GET /auth/me — parses full User with role, tier, metadata', () {
      final body = _data({
        'id': 'user-1',
        'email': 'trainer@ziro.fit',
        'name': 'Test Trainer',
        'role': 'trainer',
        'username': 'test_trainer',
        'tier': 'PRO',
        'hasCompletedOnboarding': true,
        'has_completed_onboarding': true,
        'subscriptionStatus': 'active',
        'subscription_status': 'active',
        'profilePhotoPath': 'https://example.com/avatar.png',
        'isFreeAccessModeEnabled': false,
        'is_free_access_mode_enabled': false,
        'metadata': {'theme': 'dark'},
        'created_at': kTimestamp,
        'updated_at': kTimestamp,
      });

      final response = _mockResponse(body, path: ApiConstants.me);
      final envelope = ApiResponse.fromJson(response.data!, User.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, isA<User>());
      final user = envelope.data!;
      expect(user.id, 'user-1');
      expect(user.email, 'trainer@ziro.fit');
      expect(user.role, 'trainer');
      expect(user.hasCompletedOnboarding, isTrue);
    });

    test('POST /auth/refresh — parses tokens, expiresAt, and nested user', () {
      final body = _data({
        'accessToken': 'eyJ.new-access',
        'refreshToken': 'eyJ.new-refresh',
        'expiresAt': 1704067300,
        'expires_at': 1704067300,
        'user': {
          'id': 'user-1',
          'email': 'trainer@ziro.fit',
          'name': 'Test Trainer',
          'role': 'trainer',
        },
      });

      final response = _mockResponse(body, path: ApiConstants.refresh);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['accessToken'], 'eyJ.new-access');
      expect(envelope.data!['refreshToken'], 'eyJ.new-refresh');
      expect(envelope.data!['expiresAt'], 1704067300);
      final user = envelope.data!['user'] as Map<String, dynamic>;
      expect(user['id'], 'user-1');
    });

    test('POST /auth/forgot-password — parses message', () {
      final body = _data({
        'message': 'Password reset email sent if the account exists.',
      });

      final response = _mockResponse(body, path: ApiConstants.forgotPassword);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['message'], contains('Password reset email sent'));
    });

    test('POST /auth/complete-onboarding — parses simple success flag', () {
      final body = _data({'success': true});

      final response =
          _mockResponse(body, path: ApiConstants.completeOnboarding);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['success'], isTrue);
    });
  });

  // ===========================================================================
  // 2. CLIENT ENDPOINTS
  // ===========================================================================

  group('Client endpoints', () {
    test('GET /api/clients — parses client list with isPremium flag', () {
      final body = _data({
        'clients': [
          {
            'id': 'client-1',
            'name': 'John Doe',
            'email': 'john@example.com',
            'phone': '+1234567890',
            'status': 'active',
            'avatar_path': 'https://example.com/avatar.jpg',
            'last_check_in': kTimestamp2,
            'upcoming_session': kTimestamp3,
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
          {
            'id': 'client-2',
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'status': 'pending',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'isPremium': true,
      });

      final response = _mockResponse(body, path: ApiConstants.clients);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final clients =
          (envelope.data!['clients'] as List).map((e) => Client.fromJson(e));
      expect(clients, hasLength(2));
      expect(clients.first.name, 'John Doe');
      expect(clients.first.status, 'active');
      expect(clients.last.name, 'Jane Smith');
      expect(envelope.data!['isPremium'], isTrue);
    });

    test('POST /api/clients — parses created client', () {
      final body = _data({
        'client': {
          'id': 'client-new',
          'name': 'New Client',
          'email': 'new@example.com',
          'phone': '+9876543210',
          'status': 'pending',
          'trainer_id': 'trainer-1',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response = _mockResponse(body, path: ApiConstants.clients);
      final envelope =
          ApiResponse.fromJson(response.data!, (json) => Client.fromJson(
            json['client'] as Map<String, dynamic>,
          ));

      expect(envelope.isSuccess, isTrue);
      final client = envelope.data!;
      expect(client.id, 'client-new');
      expect(client.name, 'New Client');
      expect(client.email, 'new@example.com');
      expect(client.status, 'pending');
    });

    test('GET /api/clients/{id}/dashboard — parses nested client dashboard '
        'with sessions, measurements, checkIns, habits, PRs, photos', () {
      final body = _data({
        'client': {
          'id': 'client-1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'status': 'active',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
        'recentSessions': [
          {
            'id': 'session-1',
            'client_id': 'client-1',
            'name': 'Morning Workout',
            'start_time': kTimestamp2,
            'end_time': kTimestamp2 + 3600000,
            'status': 'COMPLETED',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'measurements': [
          {
            'id': 'meas-1',
            'client_id': 'client-1',
            'measurement_date': kTimestamp,
            'weight_kg': 80.5,
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'checkIns': [
          {
            'id': 'checkin-1',
            'client_id': 'client-1',
            'date': kTimestamp,
            'status': 'SUBMITTED',
            'weight': 80.5,
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'habits': [
          {
            'id': 'habit-1',
            'client_id': 'client-1',
            'trainer_id': 'trainer-1',
            'title': 'Drink water',
            'frequency': 'DAILY',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'recentPRs': [
          {
            'id': 'pr-1',
            'client_id': 'client-1',
            'exercise_id': 'exercise-1',
            'workout_session_id': 'session-1',
            'record_type': 'weight',
            'value': 100.0,
            'achieved_at': kTimestamp2,
          },
        ],
        'progressPhotos': [
          {
            'id': 'photo-1',
            'client_id': 'client-1',
            'photo_date': kTimestamp,
            'image_path': 'photos/front.jpg',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
      });

      final response = _mockResponse(body, path: '/clients/client-1/dashboard');
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final data = envelope.data!;
      expect(
          (data['client'] as Map<String, dynamic>)['id'], 'client-1');
      expect((data['recentSessions'] as List), hasLength(1));
      expect((data['measurements'] as List), hasLength(1));
      expect((data['checkIns'] as List), hasLength(1));
      expect((data['habits'] as List), hasLength(1));
      expect((data['recentPRs'] as List), hasLength(1));
      expect((data['progressPhotos'] as List), hasLength(1));
    });

    test('GET /api/clients/{id}/measurements — parses ClientMeasurement list',
        () {
      final body = _data({
        'measurements': [
          {
            'id': 'meas-1',
            'client_id': 'client-1',
            'measurement_date': kTimestamp,
            'weight_kg': 80.5,
            'body_fat_percentage': 15.0,
            'notes': 'Good progress',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
      });

      final response =
          _mockResponse(body, path: '/clients/client-1/measurements');
      final envelope = ApiResponse.fromJson(response.data!, (json) {
        final list = (json['measurements'] as List)
            .map((e) => ClientMeasurement.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      });

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.weightKg, 80.5);
      expect(envelope.data!.first.bodyFatPercentage, 15.0);
    });

    test('POST /api/clients/{id}/measurements — parses created measurement',
        () {
      final body = _data({
        'measurement': {
          'id': 'meas-new',
          'client_id': 'client-1',
          'measurement_date': kTimestamp2,
          'weight_kg': 82.0,
          'body_fat_percentage': 14.5,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response =
          _mockResponse(body, path: '/clients/client-1/measurements');
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => ClientMeasurement.fromJson(
          json['measurement'] as Map<String, dynamic>,
        ),
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.weightKg, 82.0);
      expect(envelope.data!.bodyFatPercentage, 14.5);
    });

    test('GET /api/clients/{id}/photos — parses paginated photos', () {
      final body = _data({
        'photos': [
          {
            'id': 'photo-1',
            'client_id': 'client-1',
            'photo_date': kTimestamp,
            'image_path': 'photos/front.jpg',
            'caption': 'Front view',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'totalCount': 50,
        'total_count': 50,
        'limit': 30,
        'offset': 0,
      });

      final response = _mockResponse(body, path: '/clients/client-1/photos');
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final photos = (envelope.data!['photos'] as List)
          .map((e) => ClientProgressPhoto.fromJson(e as Map<String, dynamic>));
      expect(photos, hasLength(1));
      expect(photos.first.imagePath, 'photos/front.jpg');
      expect(envelope.data!['totalCount'], 50);
    });
  });

  // ===========================================================================
  // 3. WORKOUT ENDPOINTS
  // ===========================================================================

  group('Workout endpoints', () {
    test('POST /api/workout-sessions/start — parses session from nested key',
        () {
      final body = _data({
        'session': {
          'id': 'session-new',
          'client_id': 'client-1',
          'name': 'Morning Workout',
          'start_time': kTimestamp,
          'status': 'IN_PROGRESS',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response = _mockResponse(body, path: ApiConstants.workoutStart);
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => WorkoutSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.id, 'session-new');
      expect(envelope.data!.status, WorkoutSessionStatus.inProgress);
      expect(envelope.data!.clientId, 'client-1');
    });

    test('GET /api/workout-sessions/live — parses session with exercise logs',
        () {
      final body = _data({
        'session': {
          'id': 'session-live',
          'client_id': 'client-1',
          'start_time': kTimestamp,
          'status': 'IN_PROGRESS',
          'exerciseLogs': [
            {
              'id': 'log-1',
              'client_id': 'client-1',
              'exercise_id': 'exercise-1',
              'reps': 10,
              'weight': 50.0,
              'workout_session_id': 'session-live',
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
          'exercise_logs': [
            {
              'id': 'log-1',
              'client_id': 'client-1',
              'exercise_id': 'exercise-1',
              'reps': 10,
              'weight': 50.0,
              'workout_session_id': 'session-live',
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response = _mockResponse(body, path: ApiConstants.workoutLive);
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => WorkoutSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.id, 'session-live');
      expect(envelope.data!.status, WorkoutSessionStatus.inProgress);
    });

    test('POST /api/workout-sessions/finish — parses COMPLETED session', () {
      final body = _data({
        'session': {
          'id': 'session-finished',
          'client_id': 'client-1',
          'start_time': kTimestamp,
          'end_time': kTimestamp + 3600000,
          'status': 'COMPLETED',
          'notes': 'Great workout!',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response = _mockResponse(body, path: ApiConstants.workoutFinish);
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => WorkoutSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.status, WorkoutSessionStatus.completed);
      expect(envelope.data!.notes, 'Great workout!');
    });

    test('GET /api/workout-sessions/history — parses paginated sessions', () {
      final body = _data({
        'sessions': [
          {
            'id': 'session-hist-1',
            'client_id': 'client-1',
            'start_time': kTimestamp2,
            'end_time': kTimestamp2 + 3600000,
            'status': 'COMPLETED',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'nextCursor': '2024-01-15T00:00:00.000Z',
        'next_cursor': '2024-01-15T00:00:00.000Z',
        'hasMore': true,
        'has_more': true,
      });

      final response = _mockResponse(body, path: ApiConstants.workoutHistory);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final sessions = (envelope.data!['sessions'] as List)
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>));
      expect(sessions, hasLength(1));
      expect(sessions.first.id, 'session-hist-1');
      expect(envelope.data!['hasMore'], isTrue);
    });

    test('POST /api/workout-sessions/{id}/cancel — parses simple message', () {
      final body = _data({
        'message': 'Workout cancelled successfully',
      });

      final response =
          _mockResponse(body, path: '/workout-sessions/session-1/cancel');
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['message'], 'Workout cancelled successfully');
    });

    test('POST /api/workout/log — parses log + newRecords', () {
      final body = _data({
        'log': {
          'id': 'log-1',
          'client_id': 'client-1',
          'exercise_id': 'exercise-1',
          'reps': 12,
          'weight': 60.0,
          'is_completed': true,
          'workout_session_id': 'session-1',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
        'newRecords': [
          {
            'id': 'pr-1',
            'client_id': 'client-1',
            'exercise_id': 'exercise-1',
            'workout_session_id': 'session-1',
            'record_type': 'weight',
            'value': 60.0,
            'achieved_at': kTimestamp2,
          },
        ],
      });

      final response = _mockResponse(body, path: '/workout/log');
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final log = ClientExerciseLog.fromJson(
        envelope.data!['log'] as Map<String, dynamic>,
      );
      expect(log.id, 'log-1');
      expect(log.reps, 12);
      expect(log.isCompleted, isTrue);

      final records = (envelope.data!['newRecords'] as List)
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>));
      expect(records, hasLength(1));
      expect(records.first.recordType, 'weight');
      expect(records.first.value, 60.0);
    });

    test('GET /api/workout-sessions/{id} — parses full detail with nested '
        'template, client, and exercise logs', () {
      final body = _data({
        'session': {
          'id': 'session-detail',
          'client_id': 'client-1',
          'start_time': kTimestamp,
          'end_time': kTimestamp + 3600000,
          'status': 'COMPLETED',
          'notes': 'Felt strong',
          'workout_template_id': 'template-1',
          'workoutTemplate': {
            'id': 'template-1',
            'name': 'Full Body',
          },
          'workout_template': {
            'id': 'template-1',
            'name': 'Full Body',
          },
          'client': {
            'id': 'client-1',
            'name': 'John Doe',
          },
          'exerciseLogs': [
            {
              'id': 'log-1',
              'client_id': 'client-1',
              'exercise_id': 'exercise-1',
              'reps': 10,
              'weight': 50.0,
              'workout_session_id': 'session-detail',
              'exercise': {
                'id': 'exercise-1',
                'name': 'Bench Press',
                'muscle_group': 'Chest',
                'muscleGroup': 'Chest',
              },
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
          'exercise_logs': [
            {
              'id': 'log-1',
              'client_id': 'client-1',
              'exercise_id': 'exercise-1',
              'reps': 10,
              'weight': 50.0,
              'workout_session_id': 'session-detail',
              'exercise': {
                'id': 'exercise-1',
                'name': 'Bench Press',
                'muscle_group': 'Chest',
              },
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response =
          _mockResponse(body, path: '/workout-sessions/session-detail');
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => json['session'] as Map<String, dynamic>,
      );

      expect(envelope.isSuccess, isTrue);
      final sessionJson = envelope.data!;
      expect(sessionJson['id'], 'session-detail');

      final template = sessionJson['workoutTemplate']
          as Map<String, dynamic>?;
      expect(template?['name'], 'Full Body');

      final client = sessionJson['client'] as Map<String, dynamic>;
      expect(client['name'], 'John Doe');

      final logs = (sessionJson['exerciseLogs'] as List)
          .map((e) => ClientExerciseLog.fromJson(e as Map<String, dynamic>));
      expect(logs, hasLength(1));
    });

    test('GET /api/workout-sessions/{id}/summary — parses summary with '
        'bestSet and newRecordsCount', () {
      final body = _data({
        'session': {
          'id': 'session-summary',
          'client_id': 'client-1',
          'start_time': kTimestamp,
          'end_time': kTimestamp + 3600000,
          'status': 'COMPLETED',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
        'totalWorkouts': 25,
        'total_workouts': 25,
        'bestSet': {
          'exerciseName': 'Bench Press',
          'exercise_name': 'Bench Press',
          'reps': 10,
          'weight': 80,
        },
        'best_set': {
          'exerciseName': 'Bench Press',
          'exercise_name': 'Bench Press',
          'reps': 10,
          'weight': 80,
        },
        'newRecordsCount': 2,
        'new_records_count': 2,
      });

      final response =
          _mockResponse(body, path: '/workout-sessions/session-summary/summary');
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['totalWorkouts'], 25);
      expect(envelope.data!['newRecordsCount'], 2);
      final bestSet = envelope.data!['bestSet'] as Map<String, dynamic>;
      expect(bestSet['exerciseName'], 'Bench Press');
      expect(bestSet['reps'], 10);
      expect(bestSet['weight'], 80);
    });
  });

  // ===========================================================================
  // 4. PROFILE ENDPOINTS
  // ===========================================================================

  group('Profile endpoints', () {
    test('GET /api/profile/me — parses User + Profile with nested services, '
        'packages, testimonials', () {
      final body = _data({
        'id': 'user-1',
        'name': 'Test Trainer',
        'email': 'trainer@ziro.fit',
        'username': 'test_trainer',
        'role': 'trainer',
        'created_at': kTimestamp,
        'updated_at': kTimestamp,
        'profile': {
          'id': 'profile-1',
          'user_id': 'user-1',
          'about_me': 'Experienced coach',
          'philosophy': 'Consistency over perfection',
          'profile_photo_path': 'https://example.com/photo.jpg',
          'specialties': ['Weight Loss', 'Strength'],
          'training_types': ['ONLINE'],
          'completion_percentage': 80,
          'is_verified': true,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
        'packages': [
          {
            'id': 'pkg-1',
            'name': '10 Sessions',
            'price': 299.99,
            'number_of_sessions': 10,
            'is_active': true,
            'stripe_product_id': 'prod_xxx',
            'stripe_price_id': 'price_xxx',
            'trainer_id': 'user-1',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
      });

      final response = _mockResponse(body, path: ApiConstants.profileMe);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      // Parse the User from the top-level fields
      final user = User.fromJson(envelope.data!);
      expect(user.id, 'user-1');
      expect(user.name, 'Test Trainer');
      expect(user.role, 'trainer');

      // Parse nested profile
      final profileJson =
          envelope.data!['profile'] as Map<String, dynamic>;
      final profile = Profile.fromJson(profileJson);
      expect(profile.aboutMe, 'Experienced coach');
      expect(profile.philosophy, 'Consistency over perfection');

      // Parse nested packages
      final packages = (envelope.data!['packages'] as List)
          .map((e) => Package.fromJson(e as Map<String, dynamic>));
      expect(packages, hasLength(1));
      expect(packages.first.name, '10 Sessions');
    });

    test('GET /api/profile/me/services — parses Service list', () {
      final body = _dataList([
        {
          'id': 'svc-1',
          'profile_id': 'profile-1',
          'title': 'Personal Training',
          'description': 'One-on-one coaching',
          'price': 50.0,
          'currency': 'PLN',
          'duration': 60,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.profileMeServices);
      final envelope =
          apiResponseListFromJson(response.data!, Service.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.title, 'Personal Training');
      expect(envelope.data!.first.price, 50.0);
    });

    test('POST /api/profile/me/services — parses created Service', () {
      final body = _data({
        'id': 'svc-new',
        'profile_id': 'profile-1',
        'title': 'Nutrition Coaching',
        'description': 'Meal planning and guidance',
        'price': 75.0,
        'duration': 45,
        'created_at': kTimestamp,
        'updated_at': kTimestamp,
      });

      final response =
          _mockResponse(body, path: ApiConstants.profileMeServices);
      final envelope =
          ApiResponse.fromJson(response.data!, Service.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.title, 'Nutrition Coaching');
      expect(envelope.data!.price, 75.0);
    });

    test('GET /api/profile/me/packages — parses Package list', () {
      final body = _dataList([
        {
          'id': 'pkg-1',
          'name': '5 Sessions',
          'description': 'Intro package',
          'price': 149.99,
          'number_of_sessions': 5,
          'is_active': true,
          'stripe_product_id': 'prod_1',
          'stripe_price_id': 'price_1',
          'trainer_id': 'user-1',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.profileMePackages);
      final envelope =
          apiResponseListFromJson(response.data!, Package.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.name, '5 Sessions');
    });

    test('GET /api/profile/me/testimonials — parses Testimonial list', () {
      final body = _dataList([
        {
          'id': 'test-1',
          'profile_id': 'profile-1',
          'client_name': 'Jane Doe',
          'testimonial_text': 'Amazing trainer!',
          'rating': 5,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.profileMeTestimonials);
      final envelope =
          apiResponseListFromJson(response.data!, Testimonial.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.clientName, 'Jane Doe');
      expect(envelope.data!.first.rating, 5);
    });

    test('GET /api/profile/me/benefits — parses Benefit list', () {
      final body = _dataList([
        {
          'id': 'ben-1',
          'profile_id': 'profile-1',
          'title': 'Flexible Scheduling',
          'description': 'Train anytime',
          'order_column': 1,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.profileMeBenefits);
      final envelope =
          apiResponseListFromJson(response.data!, Benefit.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.title, 'Flexible Scheduling');
    });
  });

  // ===========================================================================
  // 5. CALENDAR / BOOKING ENDPOINTS
  // ===========================================================================

  group('Calendar / Booking endpoints', () {
    test('GET /api/bookings — parses Booking list', () {
      final body = _dataList([
        {
          'id': 'booking-1',
          'start_time': kTimestamp2,
          'end_time': kTimestamp2 + 3600000,
          'status': 'PENDING',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response = _mockResponse(body, path: ApiConstants.bookings);
      final envelope =
          apiResponseListFromJson(response.data!, Booking.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.id, 'booking-1');
      expect(envelope.data!.first.status, BookingStatus.pending);
    });

    test('POST /api/bookings/{id}/confirm — parses updated Booking', () {
      final body = _data({
        'booking': {
          'id': 'booking-1',
          'start_time': kTimestamp2,
          'end_time': kTimestamp2 + 3600000,
          'status': 'CONFIRMED',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      });

      final response =
          _mockResponse(body, path: '/bookings/booking-1/confirm');
      final envelope = ApiResponse.fromJson(
        response.data!,
        (json) => Booking.fromJson(
          json['booking'] as Map<String, dynamic>,
        ),
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.status, BookingStatus.confirmed);
    });

    test('GET /api/trainer/calendar — parses calendar events', () {
      final body = _data({
        'events': [
          {
            'id': 'event-1',
            'title': 'Session with John',
            'startTime': '2024-01-15T10:00:00Z',
            'start_time': '2024-01-15T10:00:00Z',
            'endTime': '2024-01-15T11:00:00Z',
            'end_time': '2024-01-15T11:00:00Z',
            'type': 'workout_session',
            'clientId': 'client-1',
            'client_id': 'client-1',
            'clientName': 'John Doe',
            'client_name': 'John Doe',
            'status': 'PLANNED',
          },
        ],
      });

      final response =
          _mockResponse(body, path: ApiConstants.trainerCalendar);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final events = envelope.data!['events'] as List;
      expect(events, hasLength(1));
      expect(events.first['title'], 'Session with John');
      expect(events.first['type'], 'workout_session');
    });
  });

  // ===========================================================================
  // 6. TRAINER ENDPOINTS
  // ===========================================================================

  group('Trainer endpoints', () {
    test('GET /api/trainer/check-ins — parses CheckIn list with nested client',
        () {
      final body = _dataList([
        {
          'id': 'checkin-1',
          'client_id': 'client-1',
          'date': kTimestamp2,
          'status': 'SUBMITTED',
          'weight': 80.0,
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.trainerCheckIns);
      final envelope =
          apiResponseListFromJson(response.data!, CheckIn.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.id, 'checkin-1');
      expect(envelope.data!.first.status, 'SUBMITTED');
    });

    test('POST /api/trainer/check-ins/{id}/review — parses updated CheckIn '
        'with REVIEWED status', () {
      final body = _data({
        'id': 'checkin-1',
        'client_id': 'client-1',
        'date': kTimestamp2,
        'status': 'REVIEWED',
        'trainer_response': 'Great progress! Keep it up.',
        'trainerResponse': 'Great progress! Keep it up.',
        'weight': 80.0,
        'reviewed_at': kTimestamp3,
        'reviewed_by_user_id': 'trainer-1',
        'created_at': kTimestamp,
        'updated_at': kTimestamp3,
      });

      final response =
          _mockResponse(body, path: '/trainer/check-ins/checkin-1/review');
      final envelope =
          ApiResponse.fromJson(response.data!, CheckIn.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!.status, 'REVIEWED');
      expect(envelope.data!.trainerResponse,
          'Great progress! Keep it up.');
    });

    test('GET /api/trainer/programs — parses nested program structure', () {
      final body = _data({
        'userPrograms': [
          {
            'id': 'prog-1',
            'name': 'Beginner Program',
            'description': 'Great for starters',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'user_programs': [
          {
            'id': 'prog-1',
            'name': 'Beginner Program',
            'description': 'Great for starters',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'systemPrograms': [],
        'system_programs': [],
        'userTemplates': [],
        'user_templates': [],
        'systemTemplates': [],
        'system_templates': [],
      });

      final response =
          _mockResponse(body, path: ApiConstants.trainerPrograms);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final userPrograms = (envelope.data!['userPrograms'] as List)
          .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>));
      expect(userPrograms, hasLength(1));
      expect(userPrograms.first.name, 'Beginner Program');
    });

    test('GET /api/trainer/resource-vault — parses Resource list', () {
      final body = _dataList([
        {
          'id': 'res-1',
          'trainer_id': 'trainer-1',
          'title': 'Nutrition Guide',
          'description': 'A comprehensive nutrition guide',
          'file_url': 'https://example.com/guide.pdf',
          'file_type': 'PDF',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response =
          _mockResponse(body, path: ApiConstants.trainerResourceVault);
      final envelope =
          apiResponseListFromJson(response.data!, Resource.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.title, 'Nutrition Guide');
    });

    test('GET /api/trainer/session-creation-data — parses creation data', () {
      final body = _data({
        'clients': [
          {'id': 'client-1', 'name': 'John Doe'},
        ],
        'templates': [
          {
            'id': 'template-1',
            'name': 'Full Body',
            'program_id': 'prog-1',
            'programId': 'prog-1',
            'program': {'id': 'prog-1', 'name': 'Beginner Program'},
          },
        ],
      });

      final response =
          _mockResponse(body, path: ApiConstants.sessionCreationData);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final clients = envelope.data!['clients'] as List;
      expect(clients, hasLength(1));
      expect(clients.first['name'], 'John Doe');

      final templates = envelope.data!['templates'] as List;
      expect(templates, hasLength(1));
      expect(templates.first['name'], 'Full Body');
    });
  });

  // ===========================================================================
  // 7. ADMIN ENDPOINTS
  // ===========================================================================

  group('Admin endpoints', () {
    test('GET /api/admin/stats — parses raw stats map', () {
      final body = _data({
        'totalUsers': 1500,
        'total_users': 1500,
        'activeTrainers': 120,
        'active_trainers': 120,
        'activeClients': 800,
        'active_clients': 800,
        'totalRevenue': 45000.0,
        'total_revenue': 45000.0,
        'newSignupsThisMonth': 85,
        'new_signups_this_month': 85,
      });

      final response = _mockResponse(body, path: ApiConstants.adminStats);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['totalUsers'], 1500);
      expect(envelope.data!['activeTrainers'], 120);
      expect(envelope.data!['totalRevenue'], 45000.0);
    });

    test('GET /api/admin/events — parses Event list', () {
      final body = _dataList([
        {
          'id': 'event-1',
          'trainer_id': 'trainer-1',
          'title': 'Yoga Workshop',
          'description': 'A relaxing yoga session',
          'start_time': kTimestamp3,
          'end_time': kTimestamp3 + 7200000,
          'price': 29.99,
          'capacity': 20,
          'enrolled_count': 5,
          'status': 'APPROVED',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response = _mockResponse(body, path: ApiConstants.adminEvents);
      final envelope =
          apiResponseListFromJson(response.data!, Event.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.title, 'Yoga Workshop');
    });

    test('GET /api/admin/tickets — parses SupportTicket list', () {
      final body = _dataList([
        {
          'id': 'ticket-1',
          'user_id': 'user-1',
          'category': 'BUG_REPORT',
          'message': 'Having trouble logging in',
          'app_version': '1.2.3',
          'os_version': 'iOS 17.0',
          'status': 'OPEN',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response = _mockResponse(body, path: ApiConstants.adminTickets);
      final envelope =
          apiResponseListFromJson(response.data!, SupportTicket.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.message, 'Having trouble logging in');
    });
  });

  // ===========================================================================
  // 8. SYNC ENDPOINTS
  // ===========================================================================

  group('Sync endpoints', () {
    test('GET /api/sync/pull — parses SyncPayload with changes', () {
      final body = _data({
        'changes': {
          'clients': {
            'created': [
              {'id': 'client-sync-1', 'name': 'Synced Client'},
            ],
            'updated': <Map<String, dynamic>>[],
            'deleted': <String>[],
          },
          'workout_sessions': {
            'created': [],
            'updated': [],
            'deleted': [],
          },
        },
        'timestamp': kTimestamp,
      });

      final response = _mockResponse(body, path: ApiConstants.syncPull);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final changes = envelope.data!['changes'] as Map<String, dynamic>;
      expect(changes, contains('clients'));
      expect(changes, contains('workout_sessions'));

      final clients = changes['clients'] as Map<String, dynamic>;
      expect(clients['created'], hasLength(1));
      expect((clients['created'] as List).first['id'], 'client-sync-1');

      expect(envelope.data!['timestamp'], kTimestamp);
    });

    test('POST /api/sync/push — parses basic timestamp response', () {
      final body = _data({'timestamp': kTimestamp2});

      final response = _mockResponse(body, path: ApiConstants.syncPush);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['timestamp'], kTimestamp2);
    });
  });

  // ===========================================================================
  // 9. OTHER KEY ENDPOINTS
  // ===========================================================================

  group('Other key endpoints', () {
    test('GET /api/exercises — parses paginated Exercise search', () {
      final body = _data({
        'exercises': [
          {
            'id': 'ex-1',
            'name': 'Bench Press',
            'muscle_group': 'Chest',
            'equipment': 'Barbell',
            'category': 'Strength',
            'description': 'Lie on bench, press bar up',
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
        'total': 150,
        'page': 1,
        'hasMore': true,
        'has_more': true,
      });

      final response = _mockResponse(body, path: ApiConstants.exercises);
      final envelope = ApiResponse.fromJson(response.data!, (json) {
        final list = (json['exercises'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      });

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.name, 'Bench Press');
    });

    test('GET /api/notifications — parses Notification list', () {
      final body = _data({
        'notifications': [
          {
            'id': 'notif-1',
            'user_id': 'user-1',
            'message': 'Your workout starts in 1 hour',
            'type': 'session_reminder',
            'read_status': false,
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
      });

      final response = _mockResponse(body, path: ApiConstants.notifications);
      final envelope = ApiResponse.fromJson(response.data!, (json) {
        final list = (json['notifications'] as List)
            .map((e) =>
                Notification.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      });

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.type, 'session_reminder');
      expect(envelope.data!.first.readStatus, isFalse);
    });

    test('GET /api/blog — parses BlogPost list', () {
      final body = _dataList([
        {
          'id': 'post-1',
          'title': '5 Tips for Better Workouts',
          'slug': '5-tips-better-workouts',
          'content': 'Lorem ipsum dolor sit amet...',
          'excerpt': 'Improve your training',
          'published': true,
          'author_id': 'user-1',
          'created_at': kTimestamp,
          'updated_at': kTimestamp,
        },
      ]);

      final response = _mockResponse(body, path: ApiConstants.blog);
      final envelope =
          apiResponseListFromJson(response.data!, BlogPost.fromJson);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      expect(envelope.data!.first.title, '5 Tips for Better Workouts');
    });

    test('GET /api/client/dashboard — parses complex nested client dashboard',
        () {
      final body = _data({
        'clientData': {
          'id': 'client-1',
          'userId': 'user-1',
          'user_id': 'user-1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'trainer': {
            'id': 'trainer-1',
            'name': 'Trainer Name',
            'username': 'trainer',
            'email': 'trainer@example.com',
          },
          'workoutSessions': [
            {
              'id': 'session-1',
              'client_id': 'client-1',
              'start_time': kTimestamp2,
              'end_time': kTimestamp2 + 3600000,
              'status': 'COMPLETED',
              'name': 'Full Body A',
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
          'measurements': [
            {
              'id': 'meas-1',
              'client_id': 'client-1',
              'measurement_date': kTimestamp,
              'weight_kg': 80.0,
              'created_at': kTimestamp,
              'updated_at': kTimestamp,
            },
          ],
        },
        'weightUnit': 'KG',
        'weight_unit': 'KG',
        'upcomingClientSessions': [
          {
            'id': 'session-planned',
            'title': 'Full Body B',
            'date': '2024-01-20T10:00:00Z',
            'duration': 60,
          },
        ],
        'upcoming_client_sessions': [
          {
            'id': 'session-planned',
            'title': 'Full Body B',
            'date': '2024-01-20T10:00:00Z',
            'duration': 60,
          },
        ],
        'lastCheckIn': '2024-01-10T10:00:00.000Z',
        'last_check_in': '2024-01-10T10:00:00.000Z',
      });

      final response =
          _mockResponse(body, path: ApiConstants.clientDashboard);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final clientData =
          envelope.data!['clientData'] as Map<String, dynamic>;
      expect(clientData['name'], 'John Doe');

      final trainer = clientData['trainer'] as Map<String, dynamic>;
      expect(trainer['name'], 'Trainer Name');

      expect(envelope.data!['weightUnit'], 'KG');

      final upcomingSessions =
          envelope.data!['upcomingClientSessions'] as List;
      expect(upcomingSessions, hasLength(1));
      expect(upcomingSessions.first['title'], 'Full Body B');
    });

    test('GET /api/client/habits — parses DailyHabit with nested HabitLog', () {
      final body = _data({
        'habits': [
          {
            'id': 'habit-1',
            'client_id': 'client-1',
            'trainer_id': 'trainer-1',
            'title': 'Drink 8 glasses of water',
            'description': 'Stay hydrated throughout the day',
            'frequency': 'DAILY',
            'is_active': true,
            'logs': [
              {
                'id': 'log-1',
                'habit_id': 'habit-1',
                'client_id': 'client-1',
                'date': kTimestamp2,
                'is_completed': true,
                'note': 'Felt great',
                'created_at': kTimestamp2,
                'updated_at': kTimestamp2,
              },
            ],
            'created_at': kTimestamp,
            'updated_at': kTimestamp,
          },
        ],
      });

      final response =
          _mockResponse(body, path: ApiConstants.clientHabits);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      final habits = (envelope.data!['habits'] as List)
          .map((e) => DailyHabit.fromJson(e as Map<String, dynamic>));
      expect(habits, hasLength(1));
      expect(habits.first.title, 'Drink 8 glasses of water');

      // Parse nested habit logs
      final logs = ((envelope.data!['habits'] as List).first['logs'] as List)
          .map((e) => HabitLog.fromJson(e as Map<String, dynamic>));
      expect(logs, hasLength(1));
      expect(logs.first.isCompleted, isTrue);
    });

    test('GET /api/client/programs — parses program assignments with '
        'nested program and templates', () {
      final body = [
        {
          'assignmentId': 'assign-1',
          'assignment_id': 'assign-1',
          'startDate': '2024-01-01T00:00:00Z',
          'start_date': '2024-01-01T00:00:00Z',
          'isActive': true,
          'is_active': true,
          'program': {
            'id': 'prog-1',
            'name': 'Beginner Program',
            'description': 'Great for starters',
            'templates': [
              {
                'id': 'template-1',
                'name': 'Workout A',
                'order': 0,
                'program_id': 'prog-1',
              },
            ],
          },
        },
      ];

      final response =
          _mockResponse(_dataList(body), path: '/client/programs');
      final envelope =
          apiResponseListFromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data, hasLength(1));
      final assignment = envelope.data!.first;
      expect(assignment['assignment_id'], 'assign-1');
      expect(assignment['isActive'], isTrue);

      final program =
          assignment['program'] as Map<String, dynamic>;
      expect(program['name'], 'Beginner Program');
      expect(program['templates'], hasLength(1));
    });

    test('GET /api/billing/subscription — parses subscription data', () {
      final body = _data({
        'tier': 'PRO',
        'subscriptionStatus': 'active',
        'subscription_status': 'active',
        'tierName': 'Pro',
        'tier_name': 'Pro',
        'tierId': 'PRO',
        'tier_id': 'PRO',
        'stripeCancelAtPeriodEnd': false,
        'stripe_cancel_at_period_end': false,
        'stripeCurrentPeriodEnd': 1704067200,
        'stripe_current_period_end': 1704067200,
        'stripeCancelAt': null,
        'stripe_cancel_at': null,
        'trialEndsAt': '2024-02-15T00:00:00Z',
        'trial_ends_at': '2024-02-15T00:00:00Z',
        'freeMode': false,
        'free_mode': false,
      });

      final response =
          _mockResponse(body, path: ApiConstants.billingSubscription);
      final envelope = ApiResponse.fromJson(response.data!, (json) => json);

      expect(envelope.isSuccess, isTrue);
      expect(envelope.data!['tier'], 'PRO');
      expect(envelope.data!['subscriptionStatus'], 'active');
      expect(envelope.data!['freeMode'], isFalse);
    });
  });
}
