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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: readString(json, 'id', 'id'),
        name: readString(json, 'name', 'name'),
        email: readString(json, 'email', 'email'),
        username: readStringOrNull(json, 'username', 'username'),
        role: readString(json, 'role', 'role'),
        emailVerifiedAt:
            readDateTimeOrNull(json, 'email_verified_at', 'emailVerifiedAt'),
        defaultCheckInDay: (json['default_check_in_day'] ??
            json['defaultCheckInDay'] as int?) ?? 0,
        defaultCheckInHour: (json['default_check_in_hour'] ??
            json['defaultCheckInHour'] as int?) ?? 9,
        tier: UserTier.fromJson(
            readStringOrNull(json, 'tier', 'tier') ?? 'STARTER'),
        subscriptionStatus:
            readStringOrNull(json, 'subscription_status', 'subscriptionStatus'),
        trialEndsAt: readDateTimeOrNull(json, 'trial_ends_at', 'trialEndsAt'),
        hasCompletedOnboarding:
            readBool(json, 'has_completed_onboarding', 'hasCompletedOnboarding'),
        stripeCustomerId:
            readStringOrNull(json, 'stripe_customer_id', 'stripeCustomerId'),
        stripeSubscriptionId: readStringOrNull(
            json, 'stripe_subscription_id', 'stripeSubscriptionId'),
        stripeSubscriptionStatus: readStringOrNull(
            json, 'stripe_subscription_status', 'stripeSubscriptionStatus'),
        stripeConnectAccountId: readStringOrNull(
            json, 'stripe_connect_account_id', 'stripeConnectAccountId'),
        weightUnit: WeightUnit.fromJson(
            readStringOrNull(json, 'weight_unit', 'weightUnit') ?? 'KG'),
        pushTokens: (json['push_tokens'] ?? json['pushTokens'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        stripeCancelAtPeriodEnd: readBool(
            json, 'stripe_cancel_at_period_end', 'stripeCancelAtPeriodEnd'),
        stripeCurrentPeriodEnd: readDateTimeOrNull(
            json, 'stripe_current_period_end', 'stripeCurrentPeriodEnd'),
        stripeCancelAt:
            readDateTimeOrNull(json, 'stripe_cancel_at', 'stripeCancelAt'),
        createdAt: readDateTimeOrNull(json, 'created_at', 'createdAt'),
        updatedAt: readDateTimeOrNull(json, 'updated_at', 'updatedAt'),
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
