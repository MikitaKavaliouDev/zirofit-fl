import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/user_tier.dart';
import 'package:zirofit_fl/data/models/enums/weight_unit.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String role;
  final DateTime? emailVerifiedAt;
  final int defaultCheckInDay;
  final int defaultCheckInHour;
  final UserTier tier;
  final String? subscriptionStatus;
  final DateTime? trialEndsAt;
  final bool hasCompletedOnboarding;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripeSubscriptionStatus;
  final String? stripeConnectAccountId;
  final WeightUnit weightUnit;
  final List<String> pushTokens;
  final bool stripeCancelAtPeriodEnd;
  final DateTime? stripeCurrentPeriodEnd;
  final DateTime? stripeCancelAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.role,
    this.emailVerifiedAt,
    this.defaultCheckInDay = 0,
    this.defaultCheckInHour = 9,
    this.tier = UserTier.starter,
    this.subscriptionStatus,
    this.trialEndsAt,
    this.hasCompletedOnboarding = false,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripeSubscriptionStatus,
    this.stripeConnectAccountId,
    this.weightUnit = WeightUnit.kg,
    this.pushTokens = const [],
    this.stripeCancelAtPeriodEnd = false,
    this.stripeCurrentPeriodEnd,
    this.stripeCancelAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        username: json['username'] as String?,
        role: json['role'] as String,
        emailVerifiedAt:
            dateTimeFromJsonOrNull(json['email_verified_at'] as int?),
        defaultCheckInDay: (json['default_check_in_day'] as int?) ?? 0,
        defaultCheckInHour: (json['default_check_in_hour'] as int?) ?? 9,
        tier: UserTier.fromJson(json['tier'] as String? ?? 'STARTER'),
        subscriptionStatus: json['subscription_status'] as String?,
        trialEndsAt: dateTimeFromJsonOrNull(json['trial_ends_at'] as int?),
        hasCompletedOnboarding:
            (json['has_completed_onboarding'] as bool?) ?? false,
        stripeCustomerId: json['stripe_customer_id'] as String?,
        stripeSubscriptionId: json['stripe_subscription_id'] as String?,
        stripeSubscriptionStatus:
            json['stripe_subscription_status'] as String?,
        stripeConnectAccountId: json['stripe_connect_account_id'] as String?,
        weightUnit:
            WeightUnit.fromJson(json['weight_unit'] as String? ?? 'KG'),
        pushTokens: (json['push_tokens'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        stripeCancelAtPeriodEnd:
            (json['stripe_cancel_at_period_end'] as bool?) ?? false,
        stripeCurrentPeriodEnd: dateTimeFromJsonOrNull(
            json['stripe_current_period_end'] as int?),
        stripeCancelAt:
            dateTimeFromJsonOrNull(json['stripe_cancel_at'] as int?),
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'email_verified_at': dateTimeToJson(emailVerifiedAt),
        'default_check_in_day': defaultCheckInDay,
        'default_check_in_hour': defaultCheckInHour,
        'tier': tier.toJson(),
        'subscription_status': subscriptionStatus,
        'trial_ends_at': dateTimeToJson(trialEndsAt),
        'has_completed_onboarding': hasCompletedOnboarding,
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
        'stripe_subscription_status': stripeSubscriptionStatus,
        'stripe_connect_account_id': stripeConnectAccountId,
        'weight_unit': weightUnit.toJson(),
        'push_tokens': pushTokens,
        'stripe_cancel_at_period_end': stripeCancelAtPeriodEnd,
        'stripe_current_period_end': dateTimeToJson(stripeCurrentPeriodEnd),
        'stripe_cancel_at': dateTimeToJson(stripeCancelAt),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, username: $username, '
      'role: $role, emailVerifiedAt: $emailVerifiedAt, '
      'defaultCheckInDay: $defaultCheckInDay, defaultCheckInHour: $defaultCheckInHour, '
      'tier: $tier, subscriptionStatus: $subscriptionStatus, '
      'trialEndsAt: $trialEndsAt, hasCompletedOnboarding: $hasCompletedOnboarding, '
      'stripeCustomerId: $stripeCustomerId, '
      'stripeSubscriptionId: $stripeSubscriptionId, '
      'stripeSubscriptionStatus: $stripeSubscriptionStatus, '
      'stripeConnectAccountId: $stripeConnectAccountId, '
      'weightUnit: $weightUnit, pushTokens: $pushTokens, '
      'stripeCancelAtPeriodEnd: $stripeCancelAtPeriodEnd, '
      'stripeCurrentPeriodEnd: $stripeCurrentPeriodEnd, '
      'stripeCancelAt: $stripeCancelAt, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          username == other.username &&
          role == other.role &&
          emailVerifiedAt == other.emailVerifiedAt &&
          defaultCheckInDay == other.defaultCheckInDay &&
          defaultCheckInHour == other.defaultCheckInHour &&
          tier == other.tier &&
          subscriptionStatus == other.subscriptionStatus &&
          trialEndsAt == other.trialEndsAt &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          stripeCustomerId == other.stripeCustomerId &&
          stripeSubscriptionId == other.stripeSubscriptionId &&
          stripeSubscriptionStatus == other.stripeSubscriptionStatus &&
          stripeConnectAccountId == other.stripeConnectAccountId &&
          weightUnit == other.weightUnit &&
          pushTokens == other.pushTokens &&
          stripeCancelAtPeriodEnd == other.stripeCancelAtPeriodEnd &&
          stripeCurrentPeriodEnd == other.stripeCurrentPeriodEnd &&
          stripeCancelAt == other.stripeCancelAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        email,
        username,
        role,
        emailVerifiedAt,
        defaultCheckInDay,
        defaultCheckInHour,
        tier,
        subscriptionStatus,
        trialEndsAt,
        hasCompletedOnboarding,
        stripeCustomerId,
        stripeSubscriptionId,
        stripeSubscriptionStatus,
        stripeConnectAccountId,
        weightUnit,
        pushTokens,
        stripeCancelAtPeriodEnd,
        stripeCurrentPeriodEnd,
        stripeCancelAt,
        createdAt,
        updatedAt,
      ]);
}
