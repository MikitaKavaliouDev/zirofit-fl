/// Factory for generating test User JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
/// Includes all fields the [User.fromJson] factory expects.
class UserFixture {
  static Map<String, dynamic> createJson({
    String id = 'test-user-id',
    String name = 'Test Trainer',
    String email = 'trainer@ziro.fit',
    String username = 'testtrainer',
    String role = 'trainer',
    String tier = 'PRO',
    bool hasCompletedOnboarding = true,
    String? subscriptionStatus = 'active',
    String weightUnit = 'KG',
    List<String> pushTokens = const [],
    int createdAt = 1700000000000,
    int updatedAt = 1700000000000,
  }) =>
      {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'tier': tier,
        'has_completed_onboarding': hasCompletedOnboarding,
        'subscription_status': subscriptionStatus,
        'weight_unit': weightUnit,
        'push_tokens': pushTokens,
        'email_verified_at': null,
        'default_check_in_day': 0,
        'default_check_in_hour': 9,
        'trial_ends_at': null,
        'stripe_customer_id': null,
        'stripe_subscription_id': null,
        'stripe_subscription_status': null,
        'stripe_connect_account_id': null,
        'stripe_cancel_at_period_end': false,
        'stripe_current_period_end': null,
        'stripe_cancel_at': null,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
