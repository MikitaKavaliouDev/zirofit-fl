import '../common/user_fixture.dart';

/// Factory for generating sync-related JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class SyncFixture {
  /// Full pull response with empty change sets.
  static Map<String, dynamic> pullResponse() => {
        'changes': {
          'clients': {'created': [], 'updated': [], 'deleted': []},
          'workout_sessions': {'created': [], 'updated': [], 'deleted': []},
          'client_measurements': {'created': [], 'updated': [], 'deleted': []},
          'check_ins': {'created': [], 'updated': [], 'deleted': []},
          'bookings': {'created': [], 'updated': [], 'deleted': []},
          'notifications': {'created': [], 'updated': [], 'deleted': []},
        },
        'timestamp': 1700000001000,
      };

  /// Push success response.
  static Map<String, dynamic> pushResponse() => {
        'timestamp': 1700000001000,
      };

  /// Login response mimicking the real API.
  static Map<String, dynamic> loginResponse() => {
        'message': 'Login successful.',
        'role': 'trainer',
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': UserFixture.createJson(),
      };

  /// GET /api/auth/me response.
  static Map<String, dynamic> meResponse() => {
        'id': 'test-user-id',
        'email': 'trainer@ziro.fit',
        'name': 'Test Trainer',
        'role': 'trainer',
        'username': 'testtrainer',
        'tier': 'PRO',
        'has_completed_onboarding': true,
        'subscription_status': 'active',
      };

  /// Full pull response with one client and one session.
  static Map<String, dynamic> pullResponseWithData() => {
        'changes': {
          'clients': {
            'created': [
              {
                'id': 'client-1',
                'name': 'Synced Client',
                'email': 'synced@test.com',
                'phone': '+1111111111',
                'status': 'active',
                'trainer_id': 'test-trainer-id',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
            'updated': [],
            'deleted': [],
          },
          'workout_sessions': {
            'created': [],
            'updated': [],
            'deleted': ['session-deleted-1'],
          },
          'client_measurements': {'created': [], 'updated': [], 'deleted': []},
          'check_ins': {'created': [], 'updated': [], 'deleted': []},
          'bookings': {'created': [], 'updated': [], 'deleted': []},
          'notifications': {'created': [], 'updated': [], 'deleted': []},
        },
        'timestamp': 1700000001000,
      };
}
