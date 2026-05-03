// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailVerifiedAtMeta = const VerificationMeta(
    'emailVerifiedAt',
  );
  @override
  late final GeneratedColumn<BigInt> emailVerifiedAt = GeneratedColumn<BigInt>(
    'email_verified_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultCheckInDayMeta = const VerificationMeta(
    'defaultCheckInDay',
  );
  @override
  late final GeneratedColumn<int> defaultCheckInDay = GeneratedColumn<int>(
    'default_check_in_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _defaultCheckInHourMeta =
      const VerificationMeta('defaultCheckInHour');
  @override
  late final GeneratedColumn<int> defaultCheckInHour = GeneratedColumn<int>(
    'default_check_in_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9),
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('STARTER'),
  );
  static const VerificationMeta _subscriptionStatusMeta =
      const VerificationMeta('subscriptionStatus');
  @override
  late final GeneratedColumn<String> subscriptionStatus =
      GeneratedColumn<String>(
        'subscription_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _trialEndsAtMeta = const VerificationMeta(
    'trialEndsAt',
  );
  @override
  late final GeneratedColumn<BigInt> trialEndsAt = GeneratedColumn<BigInt>(
    'trial_ends_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasCompletedOnboardingMeta =
      const VerificationMeta('hasCompletedOnboarding');
  @override
  late final GeneratedColumn<bool> hasCompletedOnboarding =
      GeneratedColumn<bool>(
        'has_completed_onboarding',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_completed_onboarding" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _stripeCustomerIdMeta = const VerificationMeta(
    'stripeCustomerId',
  );
  @override
  late final GeneratedColumn<String> stripeCustomerId = GeneratedColumn<String>(
    'stripe_customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stripeSubscriptionIdMeta =
      const VerificationMeta('stripeSubscriptionId');
  @override
  late final GeneratedColumn<String> stripeSubscriptionId =
      GeneratedColumn<String>(
        'stripe_subscription_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stripeSubscriptionStatusMeta =
      const VerificationMeta('stripeSubscriptionStatus');
  @override
  late final GeneratedColumn<String> stripeSubscriptionStatus =
      GeneratedColumn<String>(
        'stripe_subscription_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stripeConnectAccountIdMeta =
      const VerificationMeta('stripeConnectAccountId');
  @override
  late final GeneratedColumn<String> stripeConnectAccountId =
      GeneratedColumn<String>(
        'stripe_connect_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weightUnitMeta = const VerificationMeta(
    'weightUnit',
  );
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
    'weight_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KG'),
  );
  static const VerificationMeta _pushTokensMeta = const VerificationMeta(
    'pushTokens',
  );
  @override
  late final GeneratedColumn<String> pushTokens = GeneratedColumn<String>(
    'push_tokens',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _stripeCancelAtPeriodEndMeta =
      const VerificationMeta('stripeCancelAtPeriodEnd');
  @override
  late final GeneratedColumn<bool> stripeCancelAtPeriodEnd =
      GeneratedColumn<bool>(
        'stripe_cancel_at_period_end',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("stripe_cancel_at_period_end" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _stripeCurrentPeriodEndMeta =
      const VerificationMeta('stripeCurrentPeriodEnd');
  @override
  late final GeneratedColumn<BigInt> stripeCurrentPeriodEnd =
      GeneratedColumn<BigInt>(
        'stripe_current_period_end',
        aliasedName,
        true,
        type: DriftSqlType.bigInt,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stripeCancelAtMeta = const VerificationMeta(
    'stripeCancelAt',
  );
  @override
  late final GeneratedColumn<BigInt> stripeCancelAt = GeneratedColumn<BigInt>(
    'stripe_cancel_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('email_verified_at')) {
      context.handle(
        _emailVerifiedAtMeta,
        emailVerifiedAt.isAcceptableOrUnknown(
          data['email_verified_at']!,
          _emailVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('default_check_in_day')) {
      context.handle(
        _defaultCheckInDayMeta,
        defaultCheckInDay.isAcceptableOrUnknown(
          data['default_check_in_day']!,
          _defaultCheckInDayMeta,
        ),
      );
    }
    if (data.containsKey('default_check_in_hour')) {
      context.handle(
        _defaultCheckInHourMeta,
        defaultCheckInHour.isAcceptableOrUnknown(
          data['default_check_in_hour']!,
          _defaultCheckInHourMeta,
        ),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    }
    if (data.containsKey('subscription_status')) {
      context.handle(
        _subscriptionStatusMeta,
        subscriptionStatus.isAcceptableOrUnknown(
          data['subscription_status']!,
          _subscriptionStatusMeta,
        ),
      );
    }
    if (data.containsKey('trial_ends_at')) {
      context.handle(
        _trialEndsAtMeta,
        trialEndsAt.isAcceptableOrUnknown(
          data['trial_ends_at']!,
          _trialEndsAtMeta,
        ),
      );
    }
    if (data.containsKey('has_completed_onboarding')) {
      context.handle(
        _hasCompletedOnboardingMeta,
        hasCompletedOnboarding.isAcceptableOrUnknown(
          data['has_completed_onboarding']!,
          _hasCompletedOnboardingMeta,
        ),
      );
    }
    if (data.containsKey('stripe_customer_id')) {
      context.handle(
        _stripeCustomerIdMeta,
        stripeCustomerId.isAcceptableOrUnknown(
          data['stripe_customer_id']!,
          _stripeCustomerIdMeta,
        ),
      );
    }
    if (data.containsKey('stripe_subscription_id')) {
      context.handle(
        _stripeSubscriptionIdMeta,
        stripeSubscriptionId.isAcceptableOrUnknown(
          data['stripe_subscription_id']!,
          _stripeSubscriptionIdMeta,
        ),
      );
    }
    if (data.containsKey('stripe_subscription_status')) {
      context.handle(
        _stripeSubscriptionStatusMeta,
        stripeSubscriptionStatus.isAcceptableOrUnknown(
          data['stripe_subscription_status']!,
          _stripeSubscriptionStatusMeta,
        ),
      );
    }
    if (data.containsKey('stripe_connect_account_id')) {
      context.handle(
        _stripeConnectAccountIdMeta,
        stripeConnectAccountId.isAcceptableOrUnknown(
          data['stripe_connect_account_id']!,
          _stripeConnectAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
        _weightUnitMeta,
        weightUnit.isAcceptableOrUnknown(data['weight_unit']!, _weightUnitMeta),
      );
    }
    if (data.containsKey('push_tokens')) {
      context.handle(
        _pushTokensMeta,
        pushTokens.isAcceptableOrUnknown(data['push_tokens']!, _pushTokensMeta),
      );
    }
    if (data.containsKey('stripe_cancel_at_period_end')) {
      context.handle(
        _stripeCancelAtPeriodEndMeta,
        stripeCancelAtPeriodEnd.isAcceptableOrUnknown(
          data['stripe_cancel_at_period_end']!,
          _stripeCancelAtPeriodEndMeta,
        ),
      );
    }
    if (data.containsKey('stripe_current_period_end')) {
      context.handle(
        _stripeCurrentPeriodEndMeta,
        stripeCurrentPeriodEnd.isAcceptableOrUnknown(
          data['stripe_current_period_end']!,
          _stripeCurrentPeriodEndMeta,
        ),
      );
    }
    if (data.containsKey('stripe_cancel_at')) {
      context.handle(
        _stripeCancelAtMeta,
        stripeCancelAt.isAcceptableOrUnknown(
          data['stripe_cancel_at']!,
          _stripeCancelAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      emailVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}email_verified_at'],
      ),
      defaultCheckInDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_check_in_day'],
      )!,
      defaultCheckInHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_check_in_hour'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      subscriptionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_status'],
      ),
      trialEndsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}trial_ends_at'],
      ),
      hasCompletedOnboarding: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_completed_onboarding'],
      )!,
      stripeCustomerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_customer_id'],
      ),
      stripeSubscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_subscription_id'],
      ),
      stripeSubscriptionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_subscription_status'],
      ),
      stripeConnectAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_connect_account_id'],
      ),
      weightUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_unit'],
      )!,
      pushTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}push_tokens'],
      )!,
      stripeCancelAtPeriodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stripe_cancel_at_period_end'],
      )!,
      stripeCurrentPeriodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}stripe_current_period_end'],
      ),
      stripeCancelAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}stripe_cancel_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String role;
  final BigInt? emailVerifiedAt;
  final int defaultCheckInDay;
  final int defaultCheckInHour;
  final String tier;
  final String? subscriptionStatus;
  final BigInt? trialEndsAt;
  final bool hasCompletedOnboarding;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripeSubscriptionStatus;
  final String? stripeConnectAccountId;
  final String weightUnit;
  final String pushTokens;
  final bool stripeCancelAtPeriodEnd;
  final BigInt? stripeCurrentPeriodEnd;
  final BigInt? stripeCancelAt;
  final BigInt createdAt;
  final BigInt updatedAt;
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.role,
    this.emailVerifiedAt,
    required this.defaultCheckInDay,
    required this.defaultCheckInHour,
    required this.tier,
    this.subscriptionStatus,
    this.trialEndsAt,
    required this.hasCompletedOnboarding,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripeSubscriptionStatus,
    this.stripeConnectAccountId,
    required this.weightUnit,
    required this.pushTokens,
    required this.stripeCancelAtPeriodEnd,
    this.stripeCurrentPeriodEnd,
    this.stripeCancelAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || emailVerifiedAt != null) {
      map['email_verified_at'] = Variable<BigInt>(emailVerifiedAt);
    }
    map['default_check_in_day'] = Variable<int>(defaultCheckInDay);
    map['default_check_in_hour'] = Variable<int>(defaultCheckInHour);
    map['tier'] = Variable<String>(tier);
    if (!nullToAbsent || subscriptionStatus != null) {
      map['subscription_status'] = Variable<String>(subscriptionStatus);
    }
    if (!nullToAbsent || trialEndsAt != null) {
      map['trial_ends_at'] = Variable<BigInt>(trialEndsAt);
    }
    map['has_completed_onboarding'] = Variable<bool>(hasCompletedOnboarding);
    if (!nullToAbsent || stripeCustomerId != null) {
      map['stripe_customer_id'] = Variable<String>(stripeCustomerId);
    }
    if (!nullToAbsent || stripeSubscriptionId != null) {
      map['stripe_subscription_id'] = Variable<String>(stripeSubscriptionId);
    }
    if (!nullToAbsent || stripeSubscriptionStatus != null) {
      map['stripe_subscription_status'] = Variable<String>(
        stripeSubscriptionStatus,
      );
    }
    if (!nullToAbsent || stripeConnectAccountId != null) {
      map['stripe_connect_account_id'] = Variable<String>(
        stripeConnectAccountId,
      );
    }
    map['weight_unit'] = Variable<String>(weightUnit);
    map['push_tokens'] = Variable<String>(pushTokens);
    map['stripe_cancel_at_period_end'] = Variable<bool>(
      stripeCancelAtPeriodEnd,
    );
    if (!nullToAbsent || stripeCurrentPeriodEnd != null) {
      map['stripe_current_period_end'] = Variable<BigInt>(
        stripeCurrentPeriodEnd,
      );
    }
    if (!nullToAbsent || stripeCancelAt != null) {
      map['stripe_cancel_at'] = Variable<BigInt>(stripeCancelAt);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      role: Value(role),
      emailVerifiedAt: emailVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(emailVerifiedAt),
      defaultCheckInDay: Value(defaultCheckInDay),
      defaultCheckInHour: Value(defaultCheckInHour),
      tier: Value(tier),
      subscriptionStatus: subscriptionStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionStatus),
      trialEndsAt: trialEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trialEndsAt),
      hasCompletedOnboarding: Value(hasCompletedOnboarding),
      stripeCustomerId: stripeCustomerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeCustomerId),
      stripeSubscriptionId: stripeSubscriptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeSubscriptionId),
      stripeSubscriptionStatus: stripeSubscriptionStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeSubscriptionStatus),
      stripeConnectAccountId: stripeConnectAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeConnectAccountId),
      weightUnit: Value(weightUnit),
      pushTokens: Value(pushTokens),
      stripeCancelAtPeriodEnd: Value(stripeCancelAtPeriodEnd),
      stripeCurrentPeriodEnd: stripeCurrentPeriodEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeCurrentPeriodEnd),
      stripeCancelAt: stripeCancelAt == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeCancelAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      username: serializer.fromJson<String?>(json['username']),
      role: serializer.fromJson<String>(json['role']),
      emailVerifiedAt: serializer.fromJson<BigInt?>(json['emailVerifiedAt']),
      defaultCheckInDay: serializer.fromJson<int>(json['defaultCheckInDay']),
      defaultCheckInHour: serializer.fromJson<int>(json['defaultCheckInHour']),
      tier: serializer.fromJson<String>(json['tier']),
      subscriptionStatus: serializer.fromJson<String?>(
        json['subscriptionStatus'],
      ),
      trialEndsAt: serializer.fromJson<BigInt?>(json['trialEndsAt']),
      hasCompletedOnboarding: serializer.fromJson<bool>(
        json['hasCompletedOnboarding'],
      ),
      stripeCustomerId: serializer.fromJson<String?>(json['stripeCustomerId']),
      stripeSubscriptionId: serializer.fromJson<String?>(
        json['stripeSubscriptionId'],
      ),
      stripeSubscriptionStatus: serializer.fromJson<String?>(
        json['stripeSubscriptionStatus'],
      ),
      stripeConnectAccountId: serializer.fromJson<String?>(
        json['stripeConnectAccountId'],
      ),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      pushTokens: serializer.fromJson<String>(json['pushTokens']),
      stripeCancelAtPeriodEnd: serializer.fromJson<bool>(
        json['stripeCancelAtPeriodEnd'],
      ),
      stripeCurrentPeriodEnd: serializer.fromJson<BigInt?>(
        json['stripeCurrentPeriodEnd'],
      ),
      stripeCancelAt: serializer.fromJson<BigInt?>(json['stripeCancelAt']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'username': serializer.toJson<String?>(username),
      'role': serializer.toJson<String>(role),
      'emailVerifiedAt': serializer.toJson<BigInt?>(emailVerifiedAt),
      'defaultCheckInDay': serializer.toJson<int>(defaultCheckInDay),
      'defaultCheckInHour': serializer.toJson<int>(defaultCheckInHour),
      'tier': serializer.toJson<String>(tier),
      'subscriptionStatus': serializer.toJson<String?>(subscriptionStatus),
      'trialEndsAt': serializer.toJson<BigInt?>(trialEndsAt),
      'hasCompletedOnboarding': serializer.toJson<bool>(hasCompletedOnboarding),
      'stripeCustomerId': serializer.toJson<String?>(stripeCustomerId),
      'stripeSubscriptionId': serializer.toJson<String?>(stripeSubscriptionId),
      'stripeSubscriptionStatus': serializer.toJson<String?>(
        stripeSubscriptionStatus,
      ),
      'stripeConnectAccountId': serializer.toJson<String?>(
        stripeConnectAccountId,
      ),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'pushTokens': serializer.toJson<String>(pushTokens),
      'stripeCancelAtPeriodEnd': serializer.toJson<bool>(
        stripeCancelAtPeriodEnd,
      ),
      'stripeCurrentPeriodEnd': serializer.toJson<BigInt?>(
        stripeCurrentPeriodEnd,
      ),
      'stripeCancelAt': serializer.toJson<BigInt?>(stripeCancelAt),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    Value<String?> username = const Value.absent(),
    String? role,
    Value<BigInt?> emailVerifiedAt = const Value.absent(),
    int? defaultCheckInDay,
    int? defaultCheckInHour,
    String? tier,
    Value<String?> subscriptionStatus = const Value.absent(),
    Value<BigInt?> trialEndsAt = const Value.absent(),
    bool? hasCompletedOnboarding,
    Value<String?> stripeCustomerId = const Value.absent(),
    Value<String?> stripeSubscriptionId = const Value.absent(),
    Value<String?> stripeSubscriptionStatus = const Value.absent(),
    Value<String?> stripeConnectAccountId = const Value.absent(),
    String? weightUnit,
    String? pushTokens,
    bool? stripeCancelAtPeriodEnd,
    Value<BigInt?> stripeCurrentPeriodEnd = const Value.absent(),
    Value<BigInt?> stripeCancelAt = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    username: username.present ? username.value : this.username,
    role: role ?? this.role,
    emailVerifiedAt: emailVerifiedAt.present
        ? emailVerifiedAt.value
        : this.emailVerifiedAt,
    defaultCheckInDay: defaultCheckInDay ?? this.defaultCheckInDay,
    defaultCheckInHour: defaultCheckInHour ?? this.defaultCheckInHour,
    tier: tier ?? this.tier,
    subscriptionStatus: subscriptionStatus.present
        ? subscriptionStatus.value
        : this.subscriptionStatus,
    trialEndsAt: trialEndsAt.present ? trialEndsAt.value : this.trialEndsAt,
    hasCompletedOnboarding:
        hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    stripeCustomerId: stripeCustomerId.present
        ? stripeCustomerId.value
        : this.stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId.present
        ? stripeSubscriptionId.value
        : this.stripeSubscriptionId,
    stripeSubscriptionStatus: stripeSubscriptionStatus.present
        ? stripeSubscriptionStatus.value
        : this.stripeSubscriptionStatus,
    stripeConnectAccountId: stripeConnectAccountId.present
        ? stripeConnectAccountId.value
        : this.stripeConnectAccountId,
    weightUnit: weightUnit ?? this.weightUnit,
    pushTokens: pushTokens ?? this.pushTokens,
    stripeCancelAtPeriodEnd:
        stripeCancelAtPeriodEnd ?? this.stripeCancelAtPeriodEnd,
    stripeCurrentPeriodEnd: stripeCurrentPeriodEnd.present
        ? stripeCurrentPeriodEnd.value
        : this.stripeCurrentPeriodEnd,
    stripeCancelAt: stripeCancelAt.present
        ? stripeCancelAt.value
        : this.stripeCancelAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      username: data.username.present ? data.username.value : this.username,
      role: data.role.present ? data.role.value : this.role,
      emailVerifiedAt: data.emailVerifiedAt.present
          ? data.emailVerifiedAt.value
          : this.emailVerifiedAt,
      defaultCheckInDay: data.defaultCheckInDay.present
          ? data.defaultCheckInDay.value
          : this.defaultCheckInDay,
      defaultCheckInHour: data.defaultCheckInHour.present
          ? data.defaultCheckInHour.value
          : this.defaultCheckInHour,
      tier: data.tier.present ? data.tier.value : this.tier,
      subscriptionStatus: data.subscriptionStatus.present
          ? data.subscriptionStatus.value
          : this.subscriptionStatus,
      trialEndsAt: data.trialEndsAt.present
          ? data.trialEndsAt.value
          : this.trialEndsAt,
      hasCompletedOnboarding: data.hasCompletedOnboarding.present
          ? data.hasCompletedOnboarding.value
          : this.hasCompletedOnboarding,
      stripeCustomerId: data.stripeCustomerId.present
          ? data.stripeCustomerId.value
          : this.stripeCustomerId,
      stripeSubscriptionId: data.stripeSubscriptionId.present
          ? data.stripeSubscriptionId.value
          : this.stripeSubscriptionId,
      stripeSubscriptionStatus: data.stripeSubscriptionStatus.present
          ? data.stripeSubscriptionStatus.value
          : this.stripeSubscriptionStatus,
      stripeConnectAccountId: data.stripeConnectAccountId.present
          ? data.stripeConnectAccountId.value
          : this.stripeConnectAccountId,
      weightUnit: data.weightUnit.present
          ? data.weightUnit.value
          : this.weightUnit,
      pushTokens: data.pushTokens.present
          ? data.pushTokens.value
          : this.pushTokens,
      stripeCancelAtPeriodEnd: data.stripeCancelAtPeriodEnd.present
          ? data.stripeCancelAtPeriodEnd.value
          : this.stripeCancelAtPeriodEnd,
      stripeCurrentPeriodEnd: data.stripeCurrentPeriodEnd.present
          ? data.stripeCurrentPeriodEnd.value
          : this.stripeCurrentPeriodEnd,
      stripeCancelAt: data.stripeCancelAt.present
          ? data.stripeCancelAt.value
          : this.stripeCancelAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('role: $role, ')
          ..write('emailVerifiedAt: $emailVerifiedAt, ')
          ..write('defaultCheckInDay: $defaultCheckInDay, ')
          ..write('defaultCheckInHour: $defaultCheckInHour, ')
          ..write('tier: $tier, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('trialEndsAt: $trialEndsAt, ')
          ..write('hasCompletedOnboarding: $hasCompletedOnboarding, ')
          ..write('stripeCustomerId: $stripeCustomerId, ')
          ..write('stripeSubscriptionId: $stripeSubscriptionId, ')
          ..write('stripeSubscriptionStatus: $stripeSubscriptionStatus, ')
          ..write('stripeConnectAccountId: $stripeConnectAccountId, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('pushTokens: $pushTokens, ')
          ..write('stripeCancelAtPeriodEnd: $stripeCancelAtPeriodEnd, ')
          ..write('stripeCurrentPeriodEnd: $stripeCurrentPeriodEnd, ')
          ..write('stripeCancelAt: $stripeCancelAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.username == this.username &&
          other.role == this.role &&
          other.emailVerifiedAt == this.emailVerifiedAt &&
          other.defaultCheckInDay == this.defaultCheckInDay &&
          other.defaultCheckInHour == this.defaultCheckInHour &&
          other.tier == this.tier &&
          other.subscriptionStatus == this.subscriptionStatus &&
          other.trialEndsAt == this.trialEndsAt &&
          other.hasCompletedOnboarding == this.hasCompletedOnboarding &&
          other.stripeCustomerId == this.stripeCustomerId &&
          other.stripeSubscriptionId == this.stripeSubscriptionId &&
          other.stripeSubscriptionStatus == this.stripeSubscriptionStatus &&
          other.stripeConnectAccountId == this.stripeConnectAccountId &&
          other.weightUnit == this.weightUnit &&
          other.pushTokens == this.pushTokens &&
          other.stripeCancelAtPeriodEnd == this.stripeCancelAtPeriodEnd &&
          other.stripeCurrentPeriodEnd == this.stripeCurrentPeriodEnd &&
          other.stripeCancelAt == this.stripeCancelAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> username;
  final Value<String> role;
  final Value<BigInt?> emailVerifiedAt;
  final Value<int> defaultCheckInDay;
  final Value<int> defaultCheckInHour;
  final Value<String> tier;
  final Value<String?> subscriptionStatus;
  final Value<BigInt?> trialEndsAt;
  final Value<bool> hasCompletedOnboarding;
  final Value<String?> stripeCustomerId;
  final Value<String?> stripeSubscriptionId;
  final Value<String?> stripeSubscriptionStatus;
  final Value<String?> stripeConnectAccountId;
  final Value<String> weightUnit;
  final Value<String> pushTokens;
  final Value<bool> stripeCancelAtPeriodEnd;
  final Value<BigInt?> stripeCurrentPeriodEnd;
  final Value<BigInt?> stripeCancelAt;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.username = const Value.absent(),
    this.role = const Value.absent(),
    this.emailVerifiedAt = const Value.absent(),
    this.defaultCheckInDay = const Value.absent(),
    this.defaultCheckInHour = const Value.absent(),
    this.tier = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.hasCompletedOnboarding = const Value.absent(),
    this.stripeCustomerId = const Value.absent(),
    this.stripeSubscriptionId = const Value.absent(),
    this.stripeSubscriptionStatus = const Value.absent(),
    this.stripeConnectAccountId = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.pushTokens = const Value.absent(),
    this.stripeCancelAtPeriodEnd = const Value.absent(),
    this.stripeCurrentPeriodEnd = const Value.absent(),
    this.stripeCancelAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String email,
    this.username = const Value.absent(),
    required String role,
    this.emailVerifiedAt = const Value.absent(),
    this.defaultCheckInDay = const Value.absent(),
    this.defaultCheckInHour = const Value.absent(),
    this.tier = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.hasCompletedOnboarding = const Value.absent(),
    this.stripeCustomerId = const Value.absent(),
    this.stripeSubscriptionId = const Value.absent(),
    this.stripeSubscriptionStatus = const Value.absent(),
    this.stripeConnectAccountId = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.pushTokens = const Value.absent(),
    this.stripeCancelAtPeriodEnd = const Value.absent(),
    this.stripeCurrentPeriodEnd = const Value.absent(),
    this.stripeCancelAt = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? username,
    Expression<String>? role,
    Expression<BigInt>? emailVerifiedAt,
    Expression<int>? defaultCheckInDay,
    Expression<int>? defaultCheckInHour,
    Expression<String>? tier,
    Expression<String>? subscriptionStatus,
    Expression<BigInt>? trialEndsAt,
    Expression<bool>? hasCompletedOnboarding,
    Expression<String>? stripeCustomerId,
    Expression<String>? stripeSubscriptionId,
    Expression<String>? stripeSubscriptionStatus,
    Expression<String>? stripeConnectAccountId,
    Expression<String>? weightUnit,
    Expression<String>? pushTokens,
    Expression<bool>? stripeCancelAtPeriodEnd,
    Expression<BigInt>? stripeCurrentPeriodEnd,
    Expression<BigInt>? stripeCancelAt,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (role != null) 'role': role,
      if (emailVerifiedAt != null) 'email_verified_at': emailVerifiedAt,
      if (defaultCheckInDay != null) 'default_check_in_day': defaultCheckInDay,
      if (defaultCheckInHour != null)
        'default_check_in_hour': defaultCheckInHour,
      if (tier != null) 'tier': tier,
      if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt,
      if (hasCompletedOnboarding != null)
        'has_completed_onboarding': hasCompletedOnboarding,
      if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
      if (stripeSubscriptionId != null)
        'stripe_subscription_id': stripeSubscriptionId,
      if (stripeSubscriptionStatus != null)
        'stripe_subscription_status': stripeSubscriptionStatus,
      if (stripeConnectAccountId != null)
        'stripe_connect_account_id': stripeConnectAccountId,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (pushTokens != null) 'push_tokens': pushTokens,
      if (stripeCancelAtPeriodEnd != null)
        'stripe_cancel_at_period_end': stripeCancelAtPeriodEnd,
      if (stripeCurrentPeriodEnd != null)
        'stripe_current_period_end': stripeCurrentPeriodEnd,
      if (stripeCancelAt != null) 'stripe_cancel_at': stripeCancelAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? username,
    Value<String>? role,
    Value<BigInt?>? emailVerifiedAt,
    Value<int>? defaultCheckInDay,
    Value<int>? defaultCheckInHour,
    Value<String>? tier,
    Value<String?>? subscriptionStatus,
    Value<BigInt?>? trialEndsAt,
    Value<bool>? hasCompletedOnboarding,
    Value<String?>? stripeCustomerId,
    Value<String?>? stripeSubscriptionId,
    Value<String?>? stripeSubscriptionStatus,
    Value<String?>? stripeConnectAccountId,
    Value<String>? weightUnit,
    Value<String>? pushTokens,
    Value<bool>? stripeCancelAtPeriodEnd,
    Value<BigInt?>? stripeCurrentPeriodEnd,
    Value<BigInt?>? stripeCancelAt,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      defaultCheckInDay: defaultCheckInDay ?? this.defaultCheckInDay,
      defaultCheckInHour: defaultCheckInHour ?? this.defaultCheckInHour,
      tier: tier ?? this.tier,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripeSubscriptionStatus:
          stripeSubscriptionStatus ?? this.stripeSubscriptionStatus,
      stripeConnectAccountId:
          stripeConnectAccountId ?? this.stripeConnectAccountId,
      weightUnit: weightUnit ?? this.weightUnit,
      pushTokens: pushTokens ?? this.pushTokens,
      stripeCancelAtPeriodEnd:
          stripeCancelAtPeriodEnd ?? this.stripeCancelAtPeriodEnd,
      stripeCurrentPeriodEnd:
          stripeCurrentPeriodEnd ?? this.stripeCurrentPeriodEnd,
      stripeCancelAt: stripeCancelAt ?? this.stripeCancelAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (emailVerifiedAt.present) {
      map['email_verified_at'] = Variable<BigInt>(emailVerifiedAt.value);
    }
    if (defaultCheckInDay.present) {
      map['default_check_in_day'] = Variable<int>(defaultCheckInDay.value);
    }
    if (defaultCheckInHour.present) {
      map['default_check_in_hour'] = Variable<int>(defaultCheckInHour.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (subscriptionStatus.present) {
      map['subscription_status'] = Variable<String>(subscriptionStatus.value);
    }
    if (trialEndsAt.present) {
      map['trial_ends_at'] = Variable<BigInt>(trialEndsAt.value);
    }
    if (hasCompletedOnboarding.present) {
      map['has_completed_onboarding'] = Variable<bool>(
        hasCompletedOnboarding.value,
      );
    }
    if (stripeCustomerId.present) {
      map['stripe_customer_id'] = Variable<String>(stripeCustomerId.value);
    }
    if (stripeSubscriptionId.present) {
      map['stripe_subscription_id'] = Variable<String>(
        stripeSubscriptionId.value,
      );
    }
    if (stripeSubscriptionStatus.present) {
      map['stripe_subscription_status'] = Variable<String>(
        stripeSubscriptionStatus.value,
      );
    }
    if (stripeConnectAccountId.present) {
      map['stripe_connect_account_id'] = Variable<String>(
        stripeConnectAccountId.value,
      );
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (pushTokens.present) {
      map['push_tokens'] = Variable<String>(pushTokens.value);
    }
    if (stripeCancelAtPeriodEnd.present) {
      map['stripe_cancel_at_period_end'] = Variable<bool>(
        stripeCancelAtPeriodEnd.value,
      );
    }
    if (stripeCurrentPeriodEnd.present) {
      map['stripe_current_period_end'] = Variable<BigInt>(
        stripeCurrentPeriodEnd.value,
      );
    }
    if (stripeCancelAt.present) {
      map['stripe_cancel_at'] = Variable<BigInt>(stripeCancelAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('role: $role, ')
          ..write('emailVerifiedAt: $emailVerifiedAt, ')
          ..write('defaultCheckInDay: $defaultCheckInDay, ')
          ..write('defaultCheckInHour: $defaultCheckInHour, ')
          ..write('tier: $tier, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('trialEndsAt: $trialEndsAt, ')
          ..write('hasCompletedOnboarding: $hasCompletedOnboarding, ')
          ..write('stripeCustomerId: $stripeCustomerId, ')
          ..write('stripeSubscriptionId: $stripeSubscriptionId, ')
          ..write('stripeSubscriptionStatus: $stripeSubscriptionStatus, ')
          ..write('stripeConnectAccountId: $stripeConnectAccountId, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('pushTokens: $pushTokens, ')
          ..write('stripeCancelAtPeriodEnd: $stripeCancelAtPeriodEnd, ')
          ..write('stripeCurrentPeriodEnd: $stripeCurrentPeriodEnd, ')
          ..write('stripeCancelAt: $stripeCancelAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    operation,
    data,
    createdAt,
    retryCount,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final String id;
  final String targetTable;
  final String recordId;
  final String operation;
  final String data;
  final BigInt createdAt;
  final int retryCount;
  final String? error;
  const SyncQueueItem({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.createdAt,
    required this.retryCount,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    map['data'] = Variable<String>(data);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation),
      data: Value(data),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<String>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'data': serializer.toJson<String>(data),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncQueueItem copyWith({
    String? id,
    String? targetTable,
    String? recordId,
    String? operation,
    String? data,
    BigInt? createdAt,
    int? retryCount,
    Value<String?> error = const Value.absent(),
  }) => SyncQueueItem(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    data: data ?? this.data,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    error: error.present ? error.value : this.error,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    recordId,
    operation,
    data,
    createdAt,
    retryCount,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.data == this.data &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.error == this.error);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<String> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<String> data;
  final Value<BigInt> createdAt;
  final Value<int> retryCount;
  final Value<String?> error;
  final Value<int> rowid;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    required String id,
    required String targetTable,
    required String recordId,
    required String operation,
    required String data,
    required BigInt createdAt,
    this.retryCount = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetTable = Value(targetTable),
       recordId = Value(recordId),
       operation = Value(operation),
       data = Value(data),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueItem> custom({
    Expression<String>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? data,
    Expression<BigInt>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetTable,
    Value<String>? recordId,
    Value<String>? operation,
    Value<String>? data,
    Value<BigInt>? createdAt,
    Value<int>? retryCount,
    Value<String?>? error,
    Value<int>? rowid,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientsTable extends Clients with TableInfo<$ClientsTable, Client> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainerIdMeta = const VerificationMeta(
    'trainerId',
  );
  @override
  late final GeneratedColumn<String> trainerId = GeneratedColumn<String>(
    'trainer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<BigInt> dateOfBirth = GeneratedColumn<BigInt>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalsMeta = const VerificationMeta('goals');
  @override
  late final GeneratedColumn<String> goals = GeneratedColumn<String>(
    'goals',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthNotesMeta = const VerificationMeta(
    'healthNotes',
  );
  @override
  late final GeneratedColumn<String> healthNotes = GeneratedColumn<String>(
    'health_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyContactNameMeta =
      const VerificationMeta('emergencyContactName');
  @override
  late final GeneratedColumn<String> emergencyContactName =
      GeneratedColumn<String>(
        'emergency_contact_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _emergencyContactPhoneMeta =
      const VerificationMeta('emergencyContactPhone');
  @override
  late final GeneratedColumn<String> emergencyContactPhone =
      GeneratedColumn<String>(
        'emergency_contact_phone',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _checkInDayMeta = const VerificationMeta(
    'checkInDay',
  );
  @override
  late final GeneratedColumn<int> checkInDay = GeneratedColumn<int>(
    'check_in_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkInHourMeta = const VerificationMeta(
    'checkInHour',
  );
  @override
  late final GeneratedColumn<int> checkInHour = GeneratedColumn<int>(
    'check_in_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataSharingExpiresAtMeta =
      const VerificationMeta('dataSharingExpiresAt');
  @override
  late final GeneratedColumn<BigInt> dataSharingExpiresAt =
      GeneratedColumn<BigInt>(
        'data_sharing_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.bigInt,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sharingSettingsMeta = const VerificationMeta(
    'sharingSettings',
  );
  @override
  late final GeneratedColumn<String> sharingSettings = GeneratedColumn<String>(
    'sharing_settings',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trainerId,
    userId,
    name,
    email,
    phone,
    avatarPath,
    status,
    dateOfBirth,
    goals,
    healthNotes,
    emergencyContactName,
    emergencyContactPhone,
    checkInDay,
    checkInHour,
    dataSharingExpiresAt,
    sharingSettings,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Client> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trainer_id')) {
      context.handle(
        _trainerIdMeta,
        trainerId.isAcceptableOrUnknown(data['trainer_id']!, _trainerIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('goals')) {
      context.handle(
        _goalsMeta,
        goals.isAcceptableOrUnknown(data['goals']!, _goalsMeta),
      );
    }
    if (data.containsKey('health_notes')) {
      context.handle(
        _healthNotesMeta,
        healthNotes.isAcceptableOrUnknown(
          data['health_notes']!,
          _healthNotesMeta,
        ),
      );
    }
    if (data.containsKey('emergency_contact_name')) {
      context.handle(
        _emergencyContactNameMeta,
        emergencyContactName.isAcceptableOrUnknown(
          data['emergency_contact_name']!,
          _emergencyContactNameMeta,
        ),
      );
    }
    if (data.containsKey('emergency_contact_phone')) {
      context.handle(
        _emergencyContactPhoneMeta,
        emergencyContactPhone.isAcceptableOrUnknown(
          data['emergency_contact_phone']!,
          _emergencyContactPhoneMeta,
        ),
      );
    }
    if (data.containsKey('check_in_day')) {
      context.handle(
        _checkInDayMeta,
        checkInDay.isAcceptableOrUnknown(
          data['check_in_day']!,
          _checkInDayMeta,
        ),
      );
    }
    if (data.containsKey('check_in_hour')) {
      context.handle(
        _checkInHourMeta,
        checkInHour.isAcceptableOrUnknown(
          data['check_in_hour']!,
          _checkInHourMeta,
        ),
      );
    }
    if (data.containsKey('data_sharing_expires_at')) {
      context.handle(
        _dataSharingExpiresAtMeta,
        dataSharingExpiresAt.isAcceptableOrUnknown(
          data['data_sharing_expires_at']!,
          _dataSharingExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('sharing_settings')) {
      context.handle(
        _sharingSettingsMeta,
        sharingSettings.isAcceptableOrUnknown(
          data['sharing_settings']!,
          _sharingSettingsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Client map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Client(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trainerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}date_of_birth'],
      ),
      goals: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goals'],
      ),
      healthNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_notes'],
      ),
      emergencyContactName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_contact_name'],
      ),
      emergencyContactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_contact_phone'],
      ),
      checkInDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}check_in_day'],
      ),
      checkInHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}check_in_hour'],
      ),
      dataSharingExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}data_sharing_expires_at'],
      ),
      sharingSettings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sharing_settings'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }
}

class Client extends DataClass implements Insertable<Client> {
  final String id;
  final String? trainerId;
  final String? userId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String status;
  final BigInt? dateOfBirth;
  final String? goals;
  final String? healthNotes;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final int? checkInDay;
  final int? checkInHour;
  final BigInt? dataSharingExpiresAt;
  final String? sharingSettings;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const Client({
    required this.id,
    this.trainerId,
    this.userId,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    required this.status,
    this.dateOfBirth,
    this.goals,
    this.healthNotes,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.checkInDay,
    this.checkInHour,
    this.dataSharingExpiresAt,
    this.sharingSettings,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || trainerId != null) {
      map['trainer_id'] = Variable<String>(trainerId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<BigInt>(dateOfBirth);
    }
    if (!nullToAbsent || goals != null) {
      map['goals'] = Variable<String>(goals);
    }
    if (!nullToAbsent || healthNotes != null) {
      map['health_notes'] = Variable<String>(healthNotes);
    }
    if (!nullToAbsent || emergencyContactName != null) {
      map['emergency_contact_name'] = Variable<String>(emergencyContactName);
    }
    if (!nullToAbsent || emergencyContactPhone != null) {
      map['emergency_contact_phone'] = Variable<String>(emergencyContactPhone);
    }
    if (!nullToAbsent || checkInDay != null) {
      map['check_in_day'] = Variable<int>(checkInDay);
    }
    if (!nullToAbsent || checkInHour != null) {
      map['check_in_hour'] = Variable<int>(checkInHour);
    }
    if (!nullToAbsent || dataSharingExpiresAt != null) {
      map['data_sharing_expires_at'] = Variable<BigInt>(dataSharingExpiresAt);
    }
    if (!nullToAbsent || sharingSettings != null) {
      map['sharing_settings'] = Variable<String>(sharingSettings);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      trainerId: trainerId == null && nullToAbsent
          ? const Value.absent()
          : Value(trainerId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      status: Value(status),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      goals: goals == null && nullToAbsent
          ? const Value.absent()
          : Value(goals),
      healthNotes: healthNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(healthNotes),
      emergencyContactName: emergencyContactName == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContactName),
      emergencyContactPhone: emergencyContactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContactPhone),
      checkInDay: checkInDay == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInDay),
      checkInHour: checkInHour == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInHour),
      dataSharingExpiresAt: dataSharingExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSharingExpiresAt),
      sharingSettings: sharingSettings == null && nullToAbsent
          ? const Value.absent()
          : Value(sharingSettings),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory Client.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Client(
      id: serializer.fromJson<String>(json['id']),
      trainerId: serializer.fromJson<String?>(json['trainerId']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      status: serializer.fromJson<String>(json['status']),
      dateOfBirth: serializer.fromJson<BigInt?>(json['dateOfBirth']),
      goals: serializer.fromJson<String?>(json['goals']),
      healthNotes: serializer.fromJson<String?>(json['healthNotes']),
      emergencyContactName: serializer.fromJson<String?>(
        json['emergencyContactName'],
      ),
      emergencyContactPhone: serializer.fromJson<String?>(
        json['emergencyContactPhone'],
      ),
      checkInDay: serializer.fromJson<int?>(json['checkInDay']),
      checkInHour: serializer.fromJson<int?>(json['checkInHour']),
      dataSharingExpiresAt: serializer.fromJson<BigInt?>(
        json['dataSharingExpiresAt'],
      ),
      sharingSettings: serializer.fromJson<String?>(json['sharingSettings']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trainerId': serializer.toJson<String?>(trainerId),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'status': serializer.toJson<String>(status),
      'dateOfBirth': serializer.toJson<BigInt?>(dateOfBirth),
      'goals': serializer.toJson<String?>(goals),
      'healthNotes': serializer.toJson<String?>(healthNotes),
      'emergencyContactName': serializer.toJson<String?>(emergencyContactName),
      'emergencyContactPhone': serializer.toJson<String?>(
        emergencyContactPhone,
      ),
      'checkInDay': serializer.toJson<int?>(checkInDay),
      'checkInHour': serializer.toJson<int?>(checkInHour),
      'dataSharingExpiresAt': serializer.toJson<BigInt?>(dataSharingExpiresAt),
      'sharingSettings': serializer.toJson<String?>(sharingSettings),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Client copyWith({
    String? id,
    Value<String?> trainerId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    String? name,
    Value<String?> email = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> avatarPath = const Value.absent(),
    String? status,
    Value<BigInt?> dateOfBirth = const Value.absent(),
    Value<String?> goals = const Value.absent(),
    Value<String?> healthNotes = const Value.absent(),
    Value<String?> emergencyContactName = const Value.absent(),
    Value<String?> emergencyContactPhone = const Value.absent(),
    Value<int?> checkInDay = const Value.absent(),
    Value<int?> checkInHour = const Value.absent(),
    Value<BigInt?> dataSharingExpiresAt = const Value.absent(),
    Value<String?> sharingSettings = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => Client(
    id: id ?? this.id,
    trainerId: trainerId.present ? trainerId.value : this.trainerId,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    email: email.present ? email.value : this.email,
    phone: phone.present ? phone.value : this.phone,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    status: status ?? this.status,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    goals: goals.present ? goals.value : this.goals,
    healthNotes: healthNotes.present ? healthNotes.value : this.healthNotes,
    emergencyContactName: emergencyContactName.present
        ? emergencyContactName.value
        : this.emergencyContactName,
    emergencyContactPhone: emergencyContactPhone.present
        ? emergencyContactPhone.value
        : this.emergencyContactPhone,
    checkInDay: checkInDay.present ? checkInDay.value : this.checkInDay,
    checkInHour: checkInHour.present ? checkInHour.value : this.checkInHour,
    dataSharingExpiresAt: dataSharingExpiresAt.present
        ? dataSharingExpiresAt.value
        : this.dataSharingExpiresAt,
    sharingSettings: sharingSettings.present
        ? sharingSettings.value
        : this.sharingSettings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      trainerId: data.trainerId.present ? data.trainerId.value : this.trainerId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      status: data.status.present ? data.status.value : this.status,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      goals: data.goals.present ? data.goals.value : this.goals,
      healthNotes: data.healthNotes.present
          ? data.healthNotes.value
          : this.healthNotes,
      emergencyContactName: data.emergencyContactName.present
          ? data.emergencyContactName.value
          : this.emergencyContactName,
      emergencyContactPhone: data.emergencyContactPhone.present
          ? data.emergencyContactPhone.value
          : this.emergencyContactPhone,
      checkInDay: data.checkInDay.present
          ? data.checkInDay.value
          : this.checkInDay,
      checkInHour: data.checkInHour.present
          ? data.checkInHour.value
          : this.checkInHour,
      dataSharingExpiresAt: data.dataSharingExpiresAt.present
          ? data.dataSharingExpiresAt.value
          : this.dataSharingExpiresAt,
      sharingSettings: data.sharingSettings.present
          ? data.sharingSettings.value
          : this.sharingSettings,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Client(')
          ..write('id: $id, ')
          ..write('trainerId: $trainerId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('status: $status, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('goals: $goals, ')
          ..write('healthNotes: $healthNotes, ')
          ..write('emergencyContactName: $emergencyContactName, ')
          ..write('emergencyContactPhone: $emergencyContactPhone, ')
          ..write('checkInDay: $checkInDay, ')
          ..write('checkInHour: $checkInHour, ')
          ..write('dataSharingExpiresAt: $dataSharingExpiresAt, ')
          ..write('sharingSettings: $sharingSettings, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    trainerId,
    userId,
    name,
    email,
    phone,
    avatarPath,
    status,
    dateOfBirth,
    goals,
    healthNotes,
    emergencyContactName,
    emergencyContactPhone,
    checkInDay,
    checkInHour,
    dataSharingExpiresAt,
    sharingSettings,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.trainerId == this.trainerId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.avatarPath == this.avatarPath &&
          other.status == this.status &&
          other.dateOfBirth == this.dateOfBirth &&
          other.goals == this.goals &&
          other.healthNotes == this.healthNotes &&
          other.emergencyContactName == this.emergencyContactName &&
          other.emergencyContactPhone == this.emergencyContactPhone &&
          other.checkInDay == this.checkInDay &&
          other.checkInHour == this.checkInHour &&
          other.dataSharingExpiresAt == this.dataSharingExpiresAt &&
          other.sharingSettings == this.sharingSettings &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String?> trainerId;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> avatarPath;
  final Value<String> status;
  final Value<BigInt?> dateOfBirth;
  final Value<String?> goals;
  final Value<String?> healthNotes;
  final Value<String?> emergencyContactName;
  final Value<String?> emergencyContactPhone;
  final Value<int?> checkInDay;
  final Value<int?> checkInHour;
  final Value<BigInt?> dataSharingExpiresAt;
  final Value<String?> sharingSettings;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.status = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.goals = const Value.absent(),
    this.healthNotes = const Value.absent(),
    this.emergencyContactName = const Value.absent(),
    this.emergencyContactPhone = const Value.absent(),
    this.checkInDay = const Value.absent(),
    this.checkInHour = const Value.absent(),
    this.dataSharingExpiresAt = const Value.absent(),
    this.sharingSettings = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    this.trainerId = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.avatarPath = const Value.absent(),
    required String status,
    this.dateOfBirth = const Value.absent(),
    this.goals = const Value.absent(),
    this.healthNotes = const Value.absent(),
    this.emergencyContactName = const Value.absent(),
    this.emergencyContactPhone = const Value.absent(),
    this.checkInDay = const Value.absent(),
    this.checkInHour = const Value.absent(),
    this.dataSharingExpiresAt = const Value.absent(),
    this.sharingSettings = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Client> custom({
    Expression<String>? id,
    Expression<String>? trainerId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? avatarPath,
    Expression<String>? status,
    Expression<BigInt>? dateOfBirth,
    Expression<String>? goals,
    Expression<String>? healthNotes,
    Expression<String>? emergencyContactName,
    Expression<String>? emergencyContactPhone,
    Expression<int>? checkInDay,
    Expression<int>? checkInHour,
    Expression<BigInt>? dataSharingExpiresAt,
    Expression<String>? sharingSettings,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trainerId != null) 'trainer_id': trainerId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (status != null) 'status': status,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (goals != null) 'goals': goals,
      if (healthNotes != null) 'health_notes': healthNotes,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      if (checkInDay != null) 'check_in_day': checkInDay,
      if (checkInHour != null) 'check_in_hour': checkInHour,
      if (dataSharingExpiresAt != null)
        'data_sharing_expires_at': dataSharingExpiresAt,
      if (sharingSettings != null) 'sharing_settings': sharingSettings,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith({
    Value<String>? id,
    Value<String?>? trainerId,
    Value<String?>? userId,
    Value<String>? name,
    Value<String?>? email,
    Value<String?>? phone,
    Value<String?>? avatarPath,
    Value<String>? status,
    Value<BigInt?>? dateOfBirth,
    Value<String?>? goals,
    Value<String?>? healthNotes,
    Value<String?>? emergencyContactName,
    Value<String?>? emergencyContactPhone,
    Value<int?>? checkInDay,
    Value<int?>? checkInHour,
    Value<BigInt?>? dataSharingExpiresAt,
    Value<String?>? sharingSettings,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ClientsCompanion(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      status: status ?? this.status,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      goals: goals ?? this.goals,
      healthNotes: healthNotes ?? this.healthNotes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      checkInDay: checkInDay ?? this.checkInDay,
      checkInHour: checkInHour ?? this.checkInHour,
      dataSharingExpiresAt: dataSharingExpiresAt ?? this.dataSharingExpiresAt,
      sharingSettings: sharingSettings ?? this.sharingSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trainerId.present) {
      map['trainer_id'] = Variable<String>(trainerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<BigInt>(dateOfBirth.value);
    }
    if (goals.present) {
      map['goals'] = Variable<String>(goals.value);
    }
    if (healthNotes.present) {
      map['health_notes'] = Variable<String>(healthNotes.value);
    }
    if (emergencyContactName.present) {
      map['emergency_contact_name'] = Variable<String>(
        emergencyContactName.value,
      );
    }
    if (emergencyContactPhone.present) {
      map['emergency_contact_phone'] = Variable<String>(
        emergencyContactPhone.value,
      );
    }
    if (checkInDay.present) {
      map['check_in_day'] = Variable<int>(checkInDay.value);
    }
    if (checkInHour.present) {
      map['check_in_hour'] = Variable<int>(checkInHour.value);
    }
    if (dataSharingExpiresAt.present) {
      map['data_sharing_expires_at'] = Variable<BigInt>(
        dataSharingExpiresAt.value,
      );
    }
    if (sharingSettings.present) {
      map['sharing_settings'] = Variable<String>(sharingSettings.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('trainerId: $trainerId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('status: $status, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('goals: $goals, ')
          ..write('healthNotes: $healthNotes, ')
          ..write('emergencyContactName: $emergencyContactName, ')
          ..write('emergencyContactPhone: $emergencyContactPhone, ')
          ..write('checkInDay: $checkInDay, ')
          ..write('checkInHour: $checkInHour, ')
          ..write('dataSharingExpiresAt: $dataSharingExpiresAt, ')
          ..write('sharingSettings: $sharingSettings, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _certificationsMeta = const VerificationMeta(
    'certifications',
  );
  @override
  late final GeneratedColumn<String> certifications = GeneratedColumn<String>(
    'certifications',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aboutMeMeta = const VerificationMeta(
    'aboutMe',
  );
  @override
  late final GeneratedColumn<String> aboutMe = GeneratedColumn<String>(
    'about_me',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _philosophyMeta = const VerificationMeta(
    'philosophy',
  );
  @override
  late final GeneratedColumn<String> philosophy = GeneratedColumn<String>(
    'philosophy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodologyMeta = const VerificationMeta(
    'methodology',
  );
  @override
  late final GeneratedColumn<String> methodology = GeneratedColumn<String>(
    'methodology',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandingMeta = const VerificationMeta(
    'branding',
  );
  @override
  late final GeneratedColumn<String> branding = GeneratedColumn<String>(
    'branding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerImagePathMeta = const VerificationMeta(
    'bannerImagePath',
  );
  @override
  late final GeneratedColumn<String> bannerImagePath = GeneratedColumn<String>(
    'banner_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customDomainMeta = const VerificationMeta(
    'customDomain',
  );
  @override
  late final GeneratedColumn<String> customDomain = GeneratedColumn<String>(
    'custom_domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainVerifiedMeta = const VerificationMeta(
    'domainVerified',
  );
  @override
  late final GeneratedColumn<bool> domainVerified = GeneratedColumn<bool>(
    'domain_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("domain_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profilePhotoPathMeta = const VerificationMeta(
    'profilePhotoPath',
  );
  @override
  late final GeneratedColumn<String> profilePhotoPath = GeneratedColumn<String>(
    'profile_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialtiesMeta = const VerificationMeta(
    'specialties',
  );
  @override
  late final GeneratedColumn<String> specialties = GeneratedColumn<String>(
    'specialties',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _trainingTypesMeta = const VerificationMeta(
    'trainingTypes',
  );
  @override
  late final GeneratedColumn<String> trainingTypes = GeneratedColumn<String>(
    'training_types',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _businessCurrencyMeta = const VerificationMeta(
    'businessCurrency',
  );
  @override
  late final GeneratedColumn<String> businessCurrency = GeneratedColumn<String>(
    'business_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PLN'),
  );
  static const VerificationMeta _averageRatingMeta = const VerificationMeta(
    'averageRating',
  );
  @override
  late final GeneratedColumn<double> averageRating = GeneratedColumn<double>(
    'average_rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionPercentageMeta =
      const VerificationMeta('completionPercentage');
  @override
  late final GeneratedColumn<int> completionPercentage = GeneratedColumn<int>(
    'completion_percentage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missingFieldsMeta = const VerificationMeta(
    'missingFields',
  );
  @override
  late final GeneratedColumn<String> missingFields = GeneratedColumn<String>(
    'missing_fields',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVerifiedMeta = const VerificationMeta(
    'isVerified',
  );
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
    'is_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minServicePriceMeta = const VerificationMeta(
    'minServicePrice',
  );
  @override
  late final GeneratedColumn<double> minServicePrice = GeneratedColumn<double>(
    'min_service_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNormalizedMeta =
      const VerificationMeta('locationNormalized');
  @override
  late final GeneratedColumn<String> locationNormalized =
      GeneratedColumn<String>(
        'location_normalized',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    certifications,
    phone,
    aboutMe,
    philosophy,
    methodology,
    branding,
    bannerImagePath,
    customDomain,
    domainVerified,
    profilePhotoPath,
    specialties,
    trainingTypes,
    businessCurrency,
    averageRating,
    completionPercentage,
    missingFields,
    isVerified,
    availability,
    minServicePrice,
    location,
    locationNormalized,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('certifications')) {
      context.handle(
        _certificationsMeta,
        certifications.isAcceptableOrUnknown(
          data['certifications']!,
          _certificationsMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('about_me')) {
      context.handle(
        _aboutMeMeta,
        aboutMe.isAcceptableOrUnknown(data['about_me']!, _aboutMeMeta),
      );
    }
    if (data.containsKey('philosophy')) {
      context.handle(
        _philosophyMeta,
        philosophy.isAcceptableOrUnknown(data['philosophy']!, _philosophyMeta),
      );
    }
    if (data.containsKey('methodology')) {
      context.handle(
        _methodologyMeta,
        methodology.isAcceptableOrUnknown(
          data['methodology']!,
          _methodologyMeta,
        ),
      );
    }
    if (data.containsKey('branding')) {
      context.handle(
        _brandingMeta,
        branding.isAcceptableOrUnknown(data['branding']!, _brandingMeta),
      );
    }
    if (data.containsKey('banner_image_path')) {
      context.handle(
        _bannerImagePathMeta,
        bannerImagePath.isAcceptableOrUnknown(
          data['banner_image_path']!,
          _bannerImagePathMeta,
        ),
      );
    }
    if (data.containsKey('custom_domain')) {
      context.handle(
        _customDomainMeta,
        customDomain.isAcceptableOrUnknown(
          data['custom_domain']!,
          _customDomainMeta,
        ),
      );
    }
    if (data.containsKey('domain_verified')) {
      context.handle(
        _domainVerifiedMeta,
        domainVerified.isAcceptableOrUnknown(
          data['domain_verified']!,
          _domainVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('profile_photo_path')) {
      context.handle(
        _profilePhotoPathMeta,
        profilePhotoPath.isAcceptableOrUnknown(
          data['profile_photo_path']!,
          _profilePhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('specialties')) {
      context.handle(
        _specialtiesMeta,
        specialties.isAcceptableOrUnknown(
          data['specialties']!,
          _specialtiesMeta,
        ),
      );
    }
    if (data.containsKey('training_types')) {
      context.handle(
        _trainingTypesMeta,
        trainingTypes.isAcceptableOrUnknown(
          data['training_types']!,
          _trainingTypesMeta,
        ),
      );
    }
    if (data.containsKey('business_currency')) {
      context.handle(
        _businessCurrencyMeta,
        businessCurrency.isAcceptableOrUnknown(
          data['business_currency']!,
          _businessCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('average_rating')) {
      context.handle(
        _averageRatingMeta,
        averageRating.isAcceptableOrUnknown(
          data['average_rating']!,
          _averageRatingMeta,
        ),
      );
    }
    if (data.containsKey('completion_percentage')) {
      context.handle(
        _completionPercentageMeta,
        completionPercentage.isAcceptableOrUnknown(
          data['completion_percentage']!,
          _completionPercentageMeta,
        ),
      );
    }
    if (data.containsKey('missing_fields')) {
      context.handle(
        _missingFieldsMeta,
        missingFields.isAcceptableOrUnknown(
          data['missing_fields']!,
          _missingFieldsMeta,
        ),
      );
    }
    if (data.containsKey('is_verified')) {
      context.handle(
        _isVerifiedMeta,
        isVerified.isAcceptableOrUnknown(data['is_verified']!, _isVerifiedMeta),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    }
    if (data.containsKey('min_service_price')) {
      context.handle(
        _minServicePriceMeta,
        minServicePrice.isAcceptableOrUnknown(
          data['min_service_price']!,
          _minServicePriceMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('location_normalized')) {
      context.handle(
        _locationNormalizedMeta,
        locationNormalized.isAcceptableOrUnknown(
          data['location_normalized']!,
          _locationNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      certifications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certifications'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      aboutMe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}about_me'],
      ),
      philosophy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}philosophy'],
      ),
      methodology: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}methodology'],
      ),
      branding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branding'],
      ),
      bannerImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_image_path'],
      ),
      customDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_domain'],
      ),
      domainVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}domain_verified'],
      )!,
      profilePhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_photo_path'],
      ),
      specialties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialties'],
      )!,
      trainingTypes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}training_types'],
      )!,
      businessCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_currency'],
      )!,
      averageRating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_rating'],
      ),
      completionPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_percentage'],
      )!,
      missingFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_fields'],
      ),
      isVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_verified'],
      )!,
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      ),
      minServicePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_service_price'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      locationNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_normalized'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String userId;
  final String? certifications;
  final String? phone;
  final String? aboutMe;
  final String? philosophy;
  final String? methodology;
  final String? branding;
  final String? bannerImagePath;
  final String? customDomain;
  final bool domainVerified;
  final String? profilePhotoPath;
  final String specialties;
  final String trainingTypes;
  final String businessCurrency;
  final double? averageRating;
  final int completionPercentage;
  final String? missingFields;
  final bool isVerified;
  final String? availability;
  final double? minServicePrice;
  final String? location;
  final String? locationNormalized;
  final double? latitude;
  final double? longitude;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const Profile({
    required this.id,
    required this.userId,
    this.certifications,
    this.phone,
    this.aboutMe,
    this.philosophy,
    this.methodology,
    this.branding,
    this.bannerImagePath,
    this.customDomain,
    required this.domainVerified,
    this.profilePhotoPath,
    required this.specialties,
    required this.trainingTypes,
    required this.businessCurrency,
    this.averageRating,
    required this.completionPercentage,
    this.missingFields,
    required this.isVerified,
    this.availability,
    this.minServicePrice,
    this.location,
    this.locationNormalized,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || certifications != null) {
      map['certifications'] = Variable<String>(certifications);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || aboutMe != null) {
      map['about_me'] = Variable<String>(aboutMe);
    }
    if (!nullToAbsent || philosophy != null) {
      map['philosophy'] = Variable<String>(philosophy);
    }
    if (!nullToAbsent || methodology != null) {
      map['methodology'] = Variable<String>(methodology);
    }
    if (!nullToAbsent || branding != null) {
      map['branding'] = Variable<String>(branding);
    }
    if (!nullToAbsent || bannerImagePath != null) {
      map['banner_image_path'] = Variable<String>(bannerImagePath);
    }
    if (!nullToAbsent || customDomain != null) {
      map['custom_domain'] = Variable<String>(customDomain);
    }
    map['domain_verified'] = Variable<bool>(domainVerified);
    if (!nullToAbsent || profilePhotoPath != null) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath);
    }
    map['specialties'] = Variable<String>(specialties);
    map['training_types'] = Variable<String>(trainingTypes);
    map['business_currency'] = Variable<String>(businessCurrency);
    if (!nullToAbsent || averageRating != null) {
      map['average_rating'] = Variable<double>(averageRating);
    }
    map['completion_percentage'] = Variable<int>(completionPercentage);
    if (!nullToAbsent || missingFields != null) {
      map['missing_fields'] = Variable<String>(missingFields);
    }
    map['is_verified'] = Variable<bool>(isVerified);
    if (!nullToAbsent || availability != null) {
      map['availability'] = Variable<String>(availability);
    }
    if (!nullToAbsent || minServicePrice != null) {
      map['min_service_price'] = Variable<double>(minServicePrice);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || locationNormalized != null) {
      map['location_normalized'] = Variable<String>(locationNormalized);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      certifications: certifications == null && nullToAbsent
          ? const Value.absent()
          : Value(certifications),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      aboutMe: aboutMe == null && nullToAbsent
          ? const Value.absent()
          : Value(aboutMe),
      philosophy: philosophy == null && nullToAbsent
          ? const Value.absent()
          : Value(philosophy),
      methodology: methodology == null && nullToAbsent
          ? const Value.absent()
          : Value(methodology),
      branding: branding == null && nullToAbsent
          ? const Value.absent()
          : Value(branding),
      bannerImagePath: bannerImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerImagePath),
      customDomain: customDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(customDomain),
      domainVerified: Value(domainVerified),
      profilePhotoPath: profilePhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoPath),
      specialties: Value(specialties),
      trainingTypes: Value(trainingTypes),
      businessCurrency: Value(businessCurrency),
      averageRating: averageRating == null && nullToAbsent
          ? const Value.absent()
          : Value(averageRating),
      completionPercentage: Value(completionPercentage),
      missingFields: missingFields == null && nullToAbsent
          ? const Value.absent()
          : Value(missingFields),
      isVerified: Value(isVerified),
      availability: availability == null && nullToAbsent
          ? const Value.absent()
          : Value(availability),
      minServicePrice: minServicePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(minServicePrice),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      locationNormalized: locationNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(locationNormalized),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      certifications: serializer.fromJson<String?>(json['certifications']),
      phone: serializer.fromJson<String?>(json['phone']),
      aboutMe: serializer.fromJson<String?>(json['aboutMe']),
      philosophy: serializer.fromJson<String?>(json['philosophy']),
      methodology: serializer.fromJson<String?>(json['methodology']),
      branding: serializer.fromJson<String?>(json['branding']),
      bannerImagePath: serializer.fromJson<String?>(json['bannerImagePath']),
      customDomain: serializer.fromJson<String?>(json['customDomain']),
      domainVerified: serializer.fromJson<bool>(json['domainVerified']),
      profilePhotoPath: serializer.fromJson<String?>(json['profilePhotoPath']),
      specialties: serializer.fromJson<String>(json['specialties']),
      trainingTypes: serializer.fromJson<String>(json['trainingTypes']),
      businessCurrency: serializer.fromJson<String>(json['businessCurrency']),
      averageRating: serializer.fromJson<double?>(json['averageRating']),
      completionPercentage: serializer.fromJson<int>(
        json['completionPercentage'],
      ),
      missingFields: serializer.fromJson<String?>(json['missingFields']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      availability: serializer.fromJson<String?>(json['availability']),
      minServicePrice: serializer.fromJson<double?>(json['minServicePrice']),
      location: serializer.fromJson<String?>(json['location']),
      locationNormalized: serializer.fromJson<String?>(
        json['locationNormalized'],
      ),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'certifications': serializer.toJson<String?>(certifications),
      'phone': serializer.toJson<String?>(phone),
      'aboutMe': serializer.toJson<String?>(aboutMe),
      'philosophy': serializer.toJson<String?>(philosophy),
      'methodology': serializer.toJson<String?>(methodology),
      'branding': serializer.toJson<String?>(branding),
      'bannerImagePath': serializer.toJson<String?>(bannerImagePath),
      'customDomain': serializer.toJson<String?>(customDomain),
      'domainVerified': serializer.toJson<bool>(domainVerified),
      'profilePhotoPath': serializer.toJson<String?>(profilePhotoPath),
      'specialties': serializer.toJson<String>(specialties),
      'trainingTypes': serializer.toJson<String>(trainingTypes),
      'businessCurrency': serializer.toJson<String>(businessCurrency),
      'averageRating': serializer.toJson<double?>(averageRating),
      'completionPercentage': serializer.toJson<int>(completionPercentage),
      'missingFields': serializer.toJson<String?>(missingFields),
      'isVerified': serializer.toJson<bool>(isVerified),
      'availability': serializer.toJson<String?>(availability),
      'minServicePrice': serializer.toJson<double?>(minServicePrice),
      'location': serializer.toJson<String?>(location),
      'locationNormalized': serializer.toJson<String?>(locationNormalized),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Profile copyWith({
    String? id,
    String? userId,
    Value<String?> certifications = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> aboutMe = const Value.absent(),
    Value<String?> philosophy = const Value.absent(),
    Value<String?> methodology = const Value.absent(),
    Value<String?> branding = const Value.absent(),
    Value<String?> bannerImagePath = const Value.absent(),
    Value<String?> customDomain = const Value.absent(),
    bool? domainVerified,
    Value<String?> profilePhotoPath = const Value.absent(),
    String? specialties,
    String? trainingTypes,
    String? businessCurrency,
    Value<double?> averageRating = const Value.absent(),
    int? completionPercentage,
    Value<String?> missingFields = const Value.absent(),
    bool? isVerified,
    Value<String?> availability = const Value.absent(),
    Value<double?> minServicePrice = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> locationNormalized = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => Profile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    certifications: certifications.present
        ? certifications.value
        : this.certifications,
    phone: phone.present ? phone.value : this.phone,
    aboutMe: aboutMe.present ? aboutMe.value : this.aboutMe,
    philosophy: philosophy.present ? philosophy.value : this.philosophy,
    methodology: methodology.present ? methodology.value : this.methodology,
    branding: branding.present ? branding.value : this.branding,
    bannerImagePath: bannerImagePath.present
        ? bannerImagePath.value
        : this.bannerImagePath,
    customDomain: customDomain.present ? customDomain.value : this.customDomain,
    domainVerified: domainVerified ?? this.domainVerified,
    profilePhotoPath: profilePhotoPath.present
        ? profilePhotoPath.value
        : this.profilePhotoPath,
    specialties: specialties ?? this.specialties,
    trainingTypes: trainingTypes ?? this.trainingTypes,
    businessCurrency: businessCurrency ?? this.businessCurrency,
    averageRating: averageRating.present
        ? averageRating.value
        : this.averageRating,
    completionPercentage: completionPercentage ?? this.completionPercentage,
    missingFields: missingFields.present
        ? missingFields.value
        : this.missingFields,
    isVerified: isVerified ?? this.isVerified,
    availability: availability.present ? availability.value : this.availability,
    minServicePrice: minServicePrice.present
        ? minServicePrice.value
        : this.minServicePrice,
    location: location.present ? location.value : this.location,
    locationNormalized: locationNormalized.present
        ? locationNormalized.value
        : this.locationNormalized,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      certifications: data.certifications.present
          ? data.certifications.value
          : this.certifications,
      phone: data.phone.present ? data.phone.value : this.phone,
      aboutMe: data.aboutMe.present ? data.aboutMe.value : this.aboutMe,
      philosophy: data.philosophy.present
          ? data.philosophy.value
          : this.philosophy,
      methodology: data.methodology.present
          ? data.methodology.value
          : this.methodology,
      branding: data.branding.present ? data.branding.value : this.branding,
      bannerImagePath: data.bannerImagePath.present
          ? data.bannerImagePath.value
          : this.bannerImagePath,
      customDomain: data.customDomain.present
          ? data.customDomain.value
          : this.customDomain,
      domainVerified: data.domainVerified.present
          ? data.domainVerified.value
          : this.domainVerified,
      profilePhotoPath: data.profilePhotoPath.present
          ? data.profilePhotoPath.value
          : this.profilePhotoPath,
      specialties: data.specialties.present
          ? data.specialties.value
          : this.specialties,
      trainingTypes: data.trainingTypes.present
          ? data.trainingTypes.value
          : this.trainingTypes,
      businessCurrency: data.businessCurrency.present
          ? data.businessCurrency.value
          : this.businessCurrency,
      averageRating: data.averageRating.present
          ? data.averageRating.value
          : this.averageRating,
      completionPercentage: data.completionPercentage.present
          ? data.completionPercentage.value
          : this.completionPercentage,
      missingFields: data.missingFields.present
          ? data.missingFields.value
          : this.missingFields,
      isVerified: data.isVerified.present
          ? data.isVerified.value
          : this.isVerified,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      minServicePrice: data.minServicePrice.present
          ? data.minServicePrice.value
          : this.minServicePrice,
      location: data.location.present ? data.location.value : this.location,
      locationNormalized: data.locationNormalized.present
          ? data.locationNormalized.value
          : this.locationNormalized,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('certifications: $certifications, ')
          ..write('phone: $phone, ')
          ..write('aboutMe: $aboutMe, ')
          ..write('philosophy: $philosophy, ')
          ..write('methodology: $methodology, ')
          ..write('branding: $branding, ')
          ..write('bannerImagePath: $bannerImagePath, ')
          ..write('customDomain: $customDomain, ')
          ..write('domainVerified: $domainVerified, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('specialties: $specialties, ')
          ..write('trainingTypes: $trainingTypes, ')
          ..write('businessCurrency: $businessCurrency, ')
          ..write('averageRating: $averageRating, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('missingFields: $missingFields, ')
          ..write('isVerified: $isVerified, ')
          ..write('availability: $availability, ')
          ..write('minServicePrice: $minServicePrice, ')
          ..write('location: $location, ')
          ..write('locationNormalized: $locationNormalized, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    certifications,
    phone,
    aboutMe,
    philosophy,
    methodology,
    branding,
    bannerImagePath,
    customDomain,
    domainVerified,
    profilePhotoPath,
    specialties,
    trainingTypes,
    businessCurrency,
    averageRating,
    completionPercentage,
    missingFields,
    isVerified,
    availability,
    minServicePrice,
    location,
    locationNormalized,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.certifications == this.certifications &&
          other.phone == this.phone &&
          other.aboutMe == this.aboutMe &&
          other.philosophy == this.philosophy &&
          other.methodology == this.methodology &&
          other.branding == this.branding &&
          other.bannerImagePath == this.bannerImagePath &&
          other.customDomain == this.customDomain &&
          other.domainVerified == this.domainVerified &&
          other.profilePhotoPath == this.profilePhotoPath &&
          other.specialties == this.specialties &&
          other.trainingTypes == this.trainingTypes &&
          other.businessCurrency == this.businessCurrency &&
          other.averageRating == this.averageRating &&
          other.completionPercentage == this.completionPercentage &&
          other.missingFields == this.missingFields &&
          other.isVerified == this.isVerified &&
          other.availability == this.availability &&
          other.minServicePrice == this.minServicePrice &&
          other.location == this.location &&
          other.locationNormalized == this.locationNormalized &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> certifications;
  final Value<String?> phone;
  final Value<String?> aboutMe;
  final Value<String?> philosophy;
  final Value<String?> methodology;
  final Value<String?> branding;
  final Value<String?> bannerImagePath;
  final Value<String?> customDomain;
  final Value<bool> domainVerified;
  final Value<String?> profilePhotoPath;
  final Value<String> specialties;
  final Value<String> trainingTypes;
  final Value<String> businessCurrency;
  final Value<double?> averageRating;
  final Value<int> completionPercentage;
  final Value<String?> missingFields;
  final Value<bool> isVerified;
  final Value<String?> availability;
  final Value<double?> minServicePrice;
  final Value<String?> location;
  final Value<String?> locationNormalized;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.certifications = const Value.absent(),
    this.phone = const Value.absent(),
    this.aboutMe = const Value.absent(),
    this.philosophy = const Value.absent(),
    this.methodology = const Value.absent(),
    this.branding = const Value.absent(),
    this.bannerImagePath = const Value.absent(),
    this.customDomain = const Value.absent(),
    this.domainVerified = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.specialties = const Value.absent(),
    this.trainingTypes = const Value.absent(),
    this.businessCurrency = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.missingFields = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.availability = const Value.absent(),
    this.minServicePrice = const Value.absent(),
    this.location = const Value.absent(),
    this.locationNormalized = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String userId,
    this.certifications = const Value.absent(),
    this.phone = const Value.absent(),
    this.aboutMe = const Value.absent(),
    this.philosophy = const Value.absent(),
    this.methodology = const Value.absent(),
    this.branding = const Value.absent(),
    this.bannerImagePath = const Value.absent(),
    this.customDomain = const Value.absent(),
    this.domainVerified = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.specialties = const Value.absent(),
    this.trainingTypes = const Value.absent(),
    this.businessCurrency = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.missingFields = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.availability = const Value.absent(),
    this.minServicePrice = const Value.absent(),
    this.location = const Value.absent(),
    this.locationNormalized = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? certifications,
    Expression<String>? phone,
    Expression<String>? aboutMe,
    Expression<String>? philosophy,
    Expression<String>? methodology,
    Expression<String>? branding,
    Expression<String>? bannerImagePath,
    Expression<String>? customDomain,
    Expression<bool>? domainVerified,
    Expression<String>? profilePhotoPath,
    Expression<String>? specialties,
    Expression<String>? trainingTypes,
    Expression<String>? businessCurrency,
    Expression<double>? averageRating,
    Expression<int>? completionPercentage,
    Expression<String>? missingFields,
    Expression<bool>? isVerified,
    Expression<String>? availability,
    Expression<double>? minServicePrice,
    Expression<String>? location,
    Expression<String>? locationNormalized,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (certifications != null) 'certifications': certifications,
      if (phone != null) 'phone': phone,
      if (aboutMe != null) 'about_me': aboutMe,
      if (philosophy != null) 'philosophy': philosophy,
      if (methodology != null) 'methodology': methodology,
      if (branding != null) 'branding': branding,
      if (bannerImagePath != null) 'banner_image_path': bannerImagePath,
      if (customDomain != null) 'custom_domain': customDomain,
      if (domainVerified != null) 'domain_verified': domainVerified,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (specialties != null) 'specialties': specialties,
      if (trainingTypes != null) 'training_types': trainingTypes,
      if (businessCurrency != null) 'business_currency': businessCurrency,
      if (averageRating != null) 'average_rating': averageRating,
      if (completionPercentage != null)
        'completion_percentage': completionPercentage,
      if (missingFields != null) 'missing_fields': missingFields,
      if (isVerified != null) 'is_verified': isVerified,
      if (availability != null) 'availability': availability,
      if (minServicePrice != null) 'min_service_price': minServicePrice,
      if (location != null) 'location': location,
      if (locationNormalized != null) 'location_normalized': locationNormalized,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? certifications,
    Value<String?>? phone,
    Value<String?>? aboutMe,
    Value<String?>? philosophy,
    Value<String?>? methodology,
    Value<String?>? branding,
    Value<String?>? bannerImagePath,
    Value<String?>? customDomain,
    Value<bool>? domainVerified,
    Value<String?>? profilePhotoPath,
    Value<String>? specialties,
    Value<String>? trainingTypes,
    Value<String>? businessCurrency,
    Value<double?>? averageRating,
    Value<int>? completionPercentage,
    Value<String?>? missingFields,
    Value<bool>? isVerified,
    Value<String?>? availability,
    Value<double?>? minServicePrice,
    Value<String?>? location,
    Value<String?>? locationNormalized,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certifications: certifications ?? this.certifications,
      phone: phone ?? this.phone,
      aboutMe: aboutMe ?? this.aboutMe,
      philosophy: philosophy ?? this.philosophy,
      methodology: methodology ?? this.methodology,
      branding: branding ?? this.branding,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      customDomain: customDomain ?? this.customDomain,
      domainVerified: domainVerified ?? this.domainVerified,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      specialties: specialties ?? this.specialties,
      trainingTypes: trainingTypes ?? this.trainingTypes,
      businessCurrency: businessCurrency ?? this.businessCurrency,
      averageRating: averageRating ?? this.averageRating,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      missingFields: missingFields ?? this.missingFields,
      isVerified: isVerified ?? this.isVerified,
      availability: availability ?? this.availability,
      minServicePrice: minServicePrice ?? this.minServicePrice,
      location: location ?? this.location,
      locationNormalized: locationNormalized ?? this.locationNormalized,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (certifications.present) {
      map['certifications'] = Variable<String>(certifications.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (aboutMe.present) {
      map['about_me'] = Variable<String>(aboutMe.value);
    }
    if (philosophy.present) {
      map['philosophy'] = Variable<String>(philosophy.value);
    }
    if (methodology.present) {
      map['methodology'] = Variable<String>(methodology.value);
    }
    if (branding.present) {
      map['branding'] = Variable<String>(branding.value);
    }
    if (bannerImagePath.present) {
      map['banner_image_path'] = Variable<String>(bannerImagePath.value);
    }
    if (customDomain.present) {
      map['custom_domain'] = Variable<String>(customDomain.value);
    }
    if (domainVerified.present) {
      map['domain_verified'] = Variable<bool>(domainVerified.value);
    }
    if (profilePhotoPath.present) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath.value);
    }
    if (specialties.present) {
      map['specialties'] = Variable<String>(specialties.value);
    }
    if (trainingTypes.present) {
      map['training_types'] = Variable<String>(trainingTypes.value);
    }
    if (businessCurrency.present) {
      map['business_currency'] = Variable<String>(businessCurrency.value);
    }
    if (averageRating.present) {
      map['average_rating'] = Variable<double>(averageRating.value);
    }
    if (completionPercentage.present) {
      map['completion_percentage'] = Variable<int>(completionPercentage.value);
    }
    if (missingFields.present) {
      map['missing_fields'] = Variable<String>(missingFields.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (minServicePrice.present) {
      map['min_service_price'] = Variable<double>(minServicePrice.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (locationNormalized.present) {
      map['location_normalized'] = Variable<String>(locationNormalized.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('certifications: $certifications, ')
          ..write('phone: $phone, ')
          ..write('aboutMe: $aboutMe, ')
          ..write('philosophy: $philosophy, ')
          ..write('methodology: $methodology, ')
          ..write('branding: $branding, ')
          ..write('bannerImagePath: $bannerImagePath, ')
          ..write('customDomain: $customDomain, ')
          ..write('domainVerified: $domainVerified, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('specialties: $specialties, ')
          ..write('trainingTypes: $trainingTypes, ')
          ..write('businessCurrency: $businessCurrency, ')
          ..write('averageRating: $averageRating, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('missingFields: $missingFields, ')
          ..write('isVerified: $isVerified, ')
          ..write('availability: $availability, ')
          ..write('minServicePrice: $minServicePrice, ')
          ..write('location: $location, ')
          ..write('locationNormalized: $locationNormalized, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainerProfilesTable extends TrainerProfiles
    with TableInfo<$TrainerProfilesTable, TrainerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _certificationsMeta = const VerificationMeta(
    'certifications',
  );
  @override
  late final GeneratedColumn<String> certifications = GeneratedColumn<String>(
    'certifications',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aboutMeMeta = const VerificationMeta(
    'aboutMe',
  );
  @override
  late final GeneratedColumn<String> aboutMe = GeneratedColumn<String>(
    'about_me',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _philosophyMeta = const VerificationMeta(
    'philosophy',
  );
  @override
  late final GeneratedColumn<String> philosophy = GeneratedColumn<String>(
    'philosophy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodologyMeta = const VerificationMeta(
    'methodology',
  );
  @override
  late final GeneratedColumn<String> methodology = GeneratedColumn<String>(
    'methodology',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandingMeta = const VerificationMeta(
    'branding',
  );
  @override
  late final GeneratedColumn<String> branding = GeneratedColumn<String>(
    'branding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerImagePathMeta = const VerificationMeta(
    'bannerImagePath',
  );
  @override
  late final GeneratedColumn<String> bannerImagePath = GeneratedColumn<String>(
    'banner_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customDomainMeta = const VerificationMeta(
    'customDomain',
  );
  @override
  late final GeneratedColumn<String> customDomain = GeneratedColumn<String>(
    'custom_domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainVerifiedMeta = const VerificationMeta(
    'domainVerified',
  );
  @override
  late final GeneratedColumn<bool> domainVerified = GeneratedColumn<bool>(
    'domain_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("domain_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profilePhotoPathMeta = const VerificationMeta(
    'profilePhotoPath',
  );
  @override
  late final GeneratedColumn<String> profilePhotoPath = GeneratedColumn<String>(
    'profile_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialtiesMeta = const VerificationMeta(
    'specialties',
  );
  @override
  late final GeneratedColumn<String> specialties = GeneratedColumn<String>(
    'specialties',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _trainingTypesMeta = const VerificationMeta(
    'trainingTypes',
  );
  @override
  late final GeneratedColumn<String> trainingTypes = GeneratedColumn<String>(
    'training_types',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _businessCurrencyMeta = const VerificationMeta(
    'businessCurrency',
  );
  @override
  late final GeneratedColumn<String> businessCurrency = GeneratedColumn<String>(
    'business_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PLN'),
  );
  static const VerificationMeta _averageRatingMeta = const VerificationMeta(
    'averageRating',
  );
  @override
  late final GeneratedColumn<double> averageRating = GeneratedColumn<double>(
    'average_rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionPercentageMeta =
      const VerificationMeta('completionPercentage');
  @override
  late final GeneratedColumn<int> completionPercentage = GeneratedColumn<int>(
    'completion_percentage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missingFieldsMeta = const VerificationMeta(
    'missingFields',
  );
  @override
  late final GeneratedColumn<String> missingFields = GeneratedColumn<String>(
    'missing_fields',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVerifiedMeta = const VerificationMeta(
    'isVerified',
  );
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
    'is_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minServicePriceMeta = const VerificationMeta(
    'minServicePrice',
  );
  @override
  late final GeneratedColumn<double> minServicePrice = GeneratedColumn<double>(
    'min_service_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNormalizedMeta =
      const VerificationMeta('locationNormalized');
  @override
  late final GeneratedColumn<String> locationNormalized =
      GeneratedColumn<String>(
        'location_normalized',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    certifications,
    phone,
    aboutMe,
    philosophy,
    methodology,
    branding,
    bannerImagePath,
    customDomain,
    domainVerified,
    profilePhotoPath,
    specialties,
    trainingTypes,
    businessCurrency,
    averageRating,
    completionPercentage,
    missingFields,
    isVerified,
    availability,
    minServicePrice,
    location,
    locationNormalized,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trainer_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainerProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('certifications')) {
      context.handle(
        _certificationsMeta,
        certifications.isAcceptableOrUnknown(
          data['certifications']!,
          _certificationsMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('about_me')) {
      context.handle(
        _aboutMeMeta,
        aboutMe.isAcceptableOrUnknown(data['about_me']!, _aboutMeMeta),
      );
    }
    if (data.containsKey('philosophy')) {
      context.handle(
        _philosophyMeta,
        philosophy.isAcceptableOrUnknown(data['philosophy']!, _philosophyMeta),
      );
    }
    if (data.containsKey('methodology')) {
      context.handle(
        _methodologyMeta,
        methodology.isAcceptableOrUnknown(
          data['methodology']!,
          _methodologyMeta,
        ),
      );
    }
    if (data.containsKey('branding')) {
      context.handle(
        _brandingMeta,
        branding.isAcceptableOrUnknown(data['branding']!, _brandingMeta),
      );
    }
    if (data.containsKey('banner_image_path')) {
      context.handle(
        _bannerImagePathMeta,
        bannerImagePath.isAcceptableOrUnknown(
          data['banner_image_path']!,
          _bannerImagePathMeta,
        ),
      );
    }
    if (data.containsKey('custom_domain')) {
      context.handle(
        _customDomainMeta,
        customDomain.isAcceptableOrUnknown(
          data['custom_domain']!,
          _customDomainMeta,
        ),
      );
    }
    if (data.containsKey('domain_verified')) {
      context.handle(
        _domainVerifiedMeta,
        domainVerified.isAcceptableOrUnknown(
          data['domain_verified']!,
          _domainVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('profile_photo_path')) {
      context.handle(
        _profilePhotoPathMeta,
        profilePhotoPath.isAcceptableOrUnknown(
          data['profile_photo_path']!,
          _profilePhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('specialties')) {
      context.handle(
        _specialtiesMeta,
        specialties.isAcceptableOrUnknown(
          data['specialties']!,
          _specialtiesMeta,
        ),
      );
    }
    if (data.containsKey('training_types')) {
      context.handle(
        _trainingTypesMeta,
        trainingTypes.isAcceptableOrUnknown(
          data['training_types']!,
          _trainingTypesMeta,
        ),
      );
    }
    if (data.containsKey('business_currency')) {
      context.handle(
        _businessCurrencyMeta,
        businessCurrency.isAcceptableOrUnknown(
          data['business_currency']!,
          _businessCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('average_rating')) {
      context.handle(
        _averageRatingMeta,
        averageRating.isAcceptableOrUnknown(
          data['average_rating']!,
          _averageRatingMeta,
        ),
      );
    }
    if (data.containsKey('completion_percentage')) {
      context.handle(
        _completionPercentageMeta,
        completionPercentage.isAcceptableOrUnknown(
          data['completion_percentage']!,
          _completionPercentageMeta,
        ),
      );
    }
    if (data.containsKey('missing_fields')) {
      context.handle(
        _missingFieldsMeta,
        missingFields.isAcceptableOrUnknown(
          data['missing_fields']!,
          _missingFieldsMeta,
        ),
      );
    }
    if (data.containsKey('is_verified')) {
      context.handle(
        _isVerifiedMeta,
        isVerified.isAcceptableOrUnknown(data['is_verified']!, _isVerifiedMeta),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    }
    if (data.containsKey('min_service_price')) {
      context.handle(
        _minServicePriceMeta,
        minServicePrice.isAcceptableOrUnknown(
          data['min_service_price']!,
          _minServicePriceMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('location_normalized')) {
      context.handle(
        _locationNormalizedMeta,
        locationNormalized.isAcceptableOrUnknown(
          data['location_normalized']!,
          _locationNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainerProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      certifications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certifications'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      aboutMe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}about_me'],
      ),
      philosophy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}philosophy'],
      ),
      methodology: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}methodology'],
      ),
      branding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branding'],
      ),
      bannerImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_image_path'],
      ),
      customDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_domain'],
      ),
      domainVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}domain_verified'],
      )!,
      profilePhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_photo_path'],
      ),
      specialties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialties'],
      )!,
      trainingTypes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}training_types'],
      )!,
      businessCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_currency'],
      )!,
      averageRating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_rating'],
      ),
      completionPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_percentage'],
      )!,
      missingFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_fields'],
      ),
      isVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_verified'],
      )!,
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      ),
      minServicePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_service_price'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      locationNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_normalized'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TrainerProfilesTable createAlias(String alias) {
    return $TrainerProfilesTable(attachedDatabase, alias);
  }
}

class TrainerProfile extends DataClass implements Insertable<TrainerProfile> {
  final String id;
  final String userId;
  final String? certifications;
  final String? phone;
  final String? aboutMe;
  final String? philosophy;
  final String? methodology;
  final String? branding;
  final String? bannerImagePath;
  final String? customDomain;
  final bool domainVerified;
  final String? profilePhotoPath;
  final String specialties;
  final String trainingTypes;
  final String businessCurrency;
  final double? averageRating;
  final int completionPercentage;
  final String? missingFields;
  final bool isVerified;
  final String? availability;
  final double? minServicePrice;
  final String? location;
  final String? locationNormalized;
  final double? latitude;
  final double? longitude;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const TrainerProfile({
    required this.id,
    required this.userId,
    this.certifications,
    this.phone,
    this.aboutMe,
    this.philosophy,
    this.methodology,
    this.branding,
    this.bannerImagePath,
    this.customDomain,
    required this.domainVerified,
    this.profilePhotoPath,
    required this.specialties,
    required this.trainingTypes,
    required this.businessCurrency,
    this.averageRating,
    required this.completionPercentage,
    this.missingFields,
    required this.isVerified,
    this.availability,
    this.minServicePrice,
    this.location,
    this.locationNormalized,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || certifications != null) {
      map['certifications'] = Variable<String>(certifications);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || aboutMe != null) {
      map['about_me'] = Variable<String>(aboutMe);
    }
    if (!nullToAbsent || philosophy != null) {
      map['philosophy'] = Variable<String>(philosophy);
    }
    if (!nullToAbsent || methodology != null) {
      map['methodology'] = Variable<String>(methodology);
    }
    if (!nullToAbsent || branding != null) {
      map['branding'] = Variable<String>(branding);
    }
    if (!nullToAbsent || bannerImagePath != null) {
      map['banner_image_path'] = Variable<String>(bannerImagePath);
    }
    if (!nullToAbsent || customDomain != null) {
      map['custom_domain'] = Variable<String>(customDomain);
    }
    map['domain_verified'] = Variable<bool>(domainVerified);
    if (!nullToAbsent || profilePhotoPath != null) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath);
    }
    map['specialties'] = Variable<String>(specialties);
    map['training_types'] = Variable<String>(trainingTypes);
    map['business_currency'] = Variable<String>(businessCurrency);
    if (!nullToAbsent || averageRating != null) {
      map['average_rating'] = Variable<double>(averageRating);
    }
    map['completion_percentage'] = Variable<int>(completionPercentage);
    if (!nullToAbsent || missingFields != null) {
      map['missing_fields'] = Variable<String>(missingFields);
    }
    map['is_verified'] = Variable<bool>(isVerified);
    if (!nullToAbsent || availability != null) {
      map['availability'] = Variable<String>(availability);
    }
    if (!nullToAbsent || minServicePrice != null) {
      map['min_service_price'] = Variable<double>(minServicePrice);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || locationNormalized != null) {
      map['location_normalized'] = Variable<String>(locationNormalized);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TrainerProfilesCompanion toCompanion(bool nullToAbsent) {
    return TrainerProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      certifications: certifications == null && nullToAbsent
          ? const Value.absent()
          : Value(certifications),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      aboutMe: aboutMe == null && nullToAbsent
          ? const Value.absent()
          : Value(aboutMe),
      philosophy: philosophy == null && nullToAbsent
          ? const Value.absent()
          : Value(philosophy),
      methodology: methodology == null && nullToAbsent
          ? const Value.absent()
          : Value(methodology),
      branding: branding == null && nullToAbsent
          ? const Value.absent()
          : Value(branding),
      bannerImagePath: bannerImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerImagePath),
      customDomain: customDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(customDomain),
      domainVerified: Value(domainVerified),
      profilePhotoPath: profilePhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoPath),
      specialties: Value(specialties),
      trainingTypes: Value(trainingTypes),
      businessCurrency: Value(businessCurrency),
      averageRating: averageRating == null && nullToAbsent
          ? const Value.absent()
          : Value(averageRating),
      completionPercentage: Value(completionPercentage),
      missingFields: missingFields == null && nullToAbsent
          ? const Value.absent()
          : Value(missingFields),
      isVerified: Value(isVerified),
      availability: availability == null && nullToAbsent
          ? const Value.absent()
          : Value(availability),
      minServicePrice: minServicePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(minServicePrice),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      locationNormalized: locationNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(locationNormalized),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TrainerProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainerProfile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      certifications: serializer.fromJson<String?>(json['certifications']),
      phone: serializer.fromJson<String?>(json['phone']),
      aboutMe: serializer.fromJson<String?>(json['aboutMe']),
      philosophy: serializer.fromJson<String?>(json['philosophy']),
      methodology: serializer.fromJson<String?>(json['methodology']),
      branding: serializer.fromJson<String?>(json['branding']),
      bannerImagePath: serializer.fromJson<String?>(json['bannerImagePath']),
      customDomain: serializer.fromJson<String?>(json['customDomain']),
      domainVerified: serializer.fromJson<bool>(json['domainVerified']),
      profilePhotoPath: serializer.fromJson<String?>(json['profilePhotoPath']),
      specialties: serializer.fromJson<String>(json['specialties']),
      trainingTypes: serializer.fromJson<String>(json['trainingTypes']),
      businessCurrency: serializer.fromJson<String>(json['businessCurrency']),
      averageRating: serializer.fromJson<double?>(json['averageRating']),
      completionPercentage: serializer.fromJson<int>(
        json['completionPercentage'],
      ),
      missingFields: serializer.fromJson<String?>(json['missingFields']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      availability: serializer.fromJson<String?>(json['availability']),
      minServicePrice: serializer.fromJson<double?>(json['minServicePrice']),
      location: serializer.fromJson<String?>(json['location']),
      locationNormalized: serializer.fromJson<String?>(
        json['locationNormalized'],
      ),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'certifications': serializer.toJson<String?>(certifications),
      'phone': serializer.toJson<String?>(phone),
      'aboutMe': serializer.toJson<String?>(aboutMe),
      'philosophy': serializer.toJson<String?>(philosophy),
      'methodology': serializer.toJson<String?>(methodology),
      'branding': serializer.toJson<String?>(branding),
      'bannerImagePath': serializer.toJson<String?>(bannerImagePath),
      'customDomain': serializer.toJson<String?>(customDomain),
      'domainVerified': serializer.toJson<bool>(domainVerified),
      'profilePhotoPath': serializer.toJson<String?>(profilePhotoPath),
      'specialties': serializer.toJson<String>(specialties),
      'trainingTypes': serializer.toJson<String>(trainingTypes),
      'businessCurrency': serializer.toJson<String>(businessCurrency),
      'averageRating': serializer.toJson<double?>(averageRating),
      'completionPercentage': serializer.toJson<int>(completionPercentage),
      'missingFields': serializer.toJson<String?>(missingFields),
      'isVerified': serializer.toJson<bool>(isVerified),
      'availability': serializer.toJson<String?>(availability),
      'minServicePrice': serializer.toJson<double?>(minServicePrice),
      'location': serializer.toJson<String?>(location),
      'locationNormalized': serializer.toJson<String?>(locationNormalized),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TrainerProfile copyWith({
    String? id,
    String? userId,
    Value<String?> certifications = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> aboutMe = const Value.absent(),
    Value<String?> philosophy = const Value.absent(),
    Value<String?> methodology = const Value.absent(),
    Value<String?> branding = const Value.absent(),
    Value<String?> bannerImagePath = const Value.absent(),
    Value<String?> customDomain = const Value.absent(),
    bool? domainVerified,
    Value<String?> profilePhotoPath = const Value.absent(),
    String? specialties,
    String? trainingTypes,
    String? businessCurrency,
    Value<double?> averageRating = const Value.absent(),
    int? completionPercentage,
    Value<String?> missingFields = const Value.absent(),
    bool? isVerified,
    Value<String?> availability = const Value.absent(),
    Value<double?> minServicePrice = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> locationNormalized = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => TrainerProfile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    certifications: certifications.present
        ? certifications.value
        : this.certifications,
    phone: phone.present ? phone.value : this.phone,
    aboutMe: aboutMe.present ? aboutMe.value : this.aboutMe,
    philosophy: philosophy.present ? philosophy.value : this.philosophy,
    methodology: methodology.present ? methodology.value : this.methodology,
    branding: branding.present ? branding.value : this.branding,
    bannerImagePath: bannerImagePath.present
        ? bannerImagePath.value
        : this.bannerImagePath,
    customDomain: customDomain.present ? customDomain.value : this.customDomain,
    domainVerified: domainVerified ?? this.domainVerified,
    profilePhotoPath: profilePhotoPath.present
        ? profilePhotoPath.value
        : this.profilePhotoPath,
    specialties: specialties ?? this.specialties,
    trainingTypes: trainingTypes ?? this.trainingTypes,
    businessCurrency: businessCurrency ?? this.businessCurrency,
    averageRating: averageRating.present
        ? averageRating.value
        : this.averageRating,
    completionPercentage: completionPercentage ?? this.completionPercentage,
    missingFields: missingFields.present
        ? missingFields.value
        : this.missingFields,
    isVerified: isVerified ?? this.isVerified,
    availability: availability.present ? availability.value : this.availability,
    minServicePrice: minServicePrice.present
        ? minServicePrice.value
        : this.minServicePrice,
    location: location.present ? location.value : this.location,
    locationNormalized: locationNormalized.present
        ? locationNormalized.value
        : this.locationNormalized,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TrainerProfile copyWithCompanion(TrainerProfilesCompanion data) {
    return TrainerProfile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      certifications: data.certifications.present
          ? data.certifications.value
          : this.certifications,
      phone: data.phone.present ? data.phone.value : this.phone,
      aboutMe: data.aboutMe.present ? data.aboutMe.value : this.aboutMe,
      philosophy: data.philosophy.present
          ? data.philosophy.value
          : this.philosophy,
      methodology: data.methodology.present
          ? data.methodology.value
          : this.methodology,
      branding: data.branding.present ? data.branding.value : this.branding,
      bannerImagePath: data.bannerImagePath.present
          ? data.bannerImagePath.value
          : this.bannerImagePath,
      customDomain: data.customDomain.present
          ? data.customDomain.value
          : this.customDomain,
      domainVerified: data.domainVerified.present
          ? data.domainVerified.value
          : this.domainVerified,
      profilePhotoPath: data.profilePhotoPath.present
          ? data.profilePhotoPath.value
          : this.profilePhotoPath,
      specialties: data.specialties.present
          ? data.specialties.value
          : this.specialties,
      trainingTypes: data.trainingTypes.present
          ? data.trainingTypes.value
          : this.trainingTypes,
      businessCurrency: data.businessCurrency.present
          ? data.businessCurrency.value
          : this.businessCurrency,
      averageRating: data.averageRating.present
          ? data.averageRating.value
          : this.averageRating,
      completionPercentage: data.completionPercentage.present
          ? data.completionPercentage.value
          : this.completionPercentage,
      missingFields: data.missingFields.present
          ? data.missingFields.value
          : this.missingFields,
      isVerified: data.isVerified.present
          ? data.isVerified.value
          : this.isVerified,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      minServicePrice: data.minServicePrice.present
          ? data.minServicePrice.value
          : this.minServicePrice,
      location: data.location.present ? data.location.value : this.location,
      locationNormalized: data.locationNormalized.present
          ? data.locationNormalized.value
          : this.locationNormalized,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainerProfile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('certifications: $certifications, ')
          ..write('phone: $phone, ')
          ..write('aboutMe: $aboutMe, ')
          ..write('philosophy: $philosophy, ')
          ..write('methodology: $methodology, ')
          ..write('branding: $branding, ')
          ..write('bannerImagePath: $bannerImagePath, ')
          ..write('customDomain: $customDomain, ')
          ..write('domainVerified: $domainVerified, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('specialties: $specialties, ')
          ..write('trainingTypes: $trainingTypes, ')
          ..write('businessCurrency: $businessCurrency, ')
          ..write('averageRating: $averageRating, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('missingFields: $missingFields, ')
          ..write('isVerified: $isVerified, ')
          ..write('availability: $availability, ')
          ..write('minServicePrice: $minServicePrice, ')
          ..write('location: $location, ')
          ..write('locationNormalized: $locationNormalized, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    certifications,
    phone,
    aboutMe,
    philosophy,
    methodology,
    branding,
    bannerImagePath,
    customDomain,
    domainVerified,
    profilePhotoPath,
    specialties,
    trainingTypes,
    businessCurrency,
    averageRating,
    completionPercentage,
    missingFields,
    isVerified,
    availability,
    minServicePrice,
    location,
    locationNormalized,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainerProfile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.certifications == this.certifications &&
          other.phone == this.phone &&
          other.aboutMe == this.aboutMe &&
          other.philosophy == this.philosophy &&
          other.methodology == this.methodology &&
          other.branding == this.branding &&
          other.bannerImagePath == this.bannerImagePath &&
          other.customDomain == this.customDomain &&
          other.domainVerified == this.domainVerified &&
          other.profilePhotoPath == this.profilePhotoPath &&
          other.specialties == this.specialties &&
          other.trainingTypes == this.trainingTypes &&
          other.businessCurrency == this.businessCurrency &&
          other.averageRating == this.averageRating &&
          other.completionPercentage == this.completionPercentage &&
          other.missingFields == this.missingFields &&
          other.isVerified == this.isVerified &&
          other.availability == this.availability &&
          other.minServicePrice == this.minServicePrice &&
          other.location == this.location &&
          other.locationNormalized == this.locationNormalized &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TrainerProfilesCompanion extends UpdateCompanion<TrainerProfile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> certifications;
  final Value<String?> phone;
  final Value<String?> aboutMe;
  final Value<String?> philosophy;
  final Value<String?> methodology;
  final Value<String?> branding;
  final Value<String?> bannerImagePath;
  final Value<String?> customDomain;
  final Value<bool> domainVerified;
  final Value<String?> profilePhotoPath;
  final Value<String> specialties;
  final Value<String> trainingTypes;
  final Value<String> businessCurrency;
  final Value<double?> averageRating;
  final Value<int> completionPercentage;
  final Value<String?> missingFields;
  final Value<bool> isVerified;
  final Value<String?> availability;
  final Value<double?> minServicePrice;
  final Value<String?> location;
  final Value<String?> locationNormalized;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TrainerProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.certifications = const Value.absent(),
    this.phone = const Value.absent(),
    this.aboutMe = const Value.absent(),
    this.philosophy = const Value.absent(),
    this.methodology = const Value.absent(),
    this.branding = const Value.absent(),
    this.bannerImagePath = const Value.absent(),
    this.customDomain = const Value.absent(),
    this.domainVerified = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.specialties = const Value.absent(),
    this.trainingTypes = const Value.absent(),
    this.businessCurrency = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.missingFields = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.availability = const Value.absent(),
    this.minServicePrice = const Value.absent(),
    this.location = const Value.absent(),
    this.locationNormalized = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainerProfilesCompanion.insert({
    required String id,
    required String userId,
    this.certifications = const Value.absent(),
    this.phone = const Value.absent(),
    this.aboutMe = const Value.absent(),
    this.philosophy = const Value.absent(),
    this.methodology = const Value.absent(),
    this.branding = const Value.absent(),
    this.bannerImagePath = const Value.absent(),
    this.customDomain = const Value.absent(),
    this.domainVerified = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.specialties = const Value.absent(),
    this.trainingTypes = const Value.absent(),
    this.businessCurrency = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.completionPercentage = const Value.absent(),
    this.missingFields = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.availability = const Value.absent(),
    this.minServicePrice = const Value.absent(),
    this.location = const Value.absent(),
    this.locationNormalized = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrainerProfile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? certifications,
    Expression<String>? phone,
    Expression<String>? aboutMe,
    Expression<String>? philosophy,
    Expression<String>? methodology,
    Expression<String>? branding,
    Expression<String>? bannerImagePath,
    Expression<String>? customDomain,
    Expression<bool>? domainVerified,
    Expression<String>? profilePhotoPath,
    Expression<String>? specialties,
    Expression<String>? trainingTypes,
    Expression<String>? businessCurrency,
    Expression<double>? averageRating,
    Expression<int>? completionPercentage,
    Expression<String>? missingFields,
    Expression<bool>? isVerified,
    Expression<String>? availability,
    Expression<double>? minServicePrice,
    Expression<String>? location,
    Expression<String>? locationNormalized,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (certifications != null) 'certifications': certifications,
      if (phone != null) 'phone': phone,
      if (aboutMe != null) 'about_me': aboutMe,
      if (philosophy != null) 'philosophy': philosophy,
      if (methodology != null) 'methodology': methodology,
      if (branding != null) 'branding': branding,
      if (bannerImagePath != null) 'banner_image_path': bannerImagePath,
      if (customDomain != null) 'custom_domain': customDomain,
      if (domainVerified != null) 'domain_verified': domainVerified,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (specialties != null) 'specialties': specialties,
      if (trainingTypes != null) 'training_types': trainingTypes,
      if (businessCurrency != null) 'business_currency': businessCurrency,
      if (averageRating != null) 'average_rating': averageRating,
      if (completionPercentage != null)
        'completion_percentage': completionPercentage,
      if (missingFields != null) 'missing_fields': missingFields,
      if (isVerified != null) 'is_verified': isVerified,
      if (availability != null) 'availability': availability,
      if (minServicePrice != null) 'min_service_price': minServicePrice,
      if (location != null) 'location': location,
      if (locationNormalized != null) 'location_normalized': locationNormalized,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainerProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? certifications,
    Value<String?>? phone,
    Value<String?>? aboutMe,
    Value<String?>? philosophy,
    Value<String?>? methodology,
    Value<String?>? branding,
    Value<String?>? bannerImagePath,
    Value<String?>? customDomain,
    Value<bool>? domainVerified,
    Value<String?>? profilePhotoPath,
    Value<String>? specialties,
    Value<String>? trainingTypes,
    Value<String>? businessCurrency,
    Value<double?>? averageRating,
    Value<int>? completionPercentage,
    Value<String?>? missingFields,
    Value<bool>? isVerified,
    Value<String?>? availability,
    Value<double?>? minServicePrice,
    Value<String?>? location,
    Value<String?>? locationNormalized,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TrainerProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certifications: certifications ?? this.certifications,
      phone: phone ?? this.phone,
      aboutMe: aboutMe ?? this.aboutMe,
      philosophy: philosophy ?? this.philosophy,
      methodology: methodology ?? this.methodology,
      branding: branding ?? this.branding,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      customDomain: customDomain ?? this.customDomain,
      domainVerified: domainVerified ?? this.domainVerified,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      specialties: specialties ?? this.specialties,
      trainingTypes: trainingTypes ?? this.trainingTypes,
      businessCurrency: businessCurrency ?? this.businessCurrency,
      averageRating: averageRating ?? this.averageRating,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      missingFields: missingFields ?? this.missingFields,
      isVerified: isVerified ?? this.isVerified,
      availability: availability ?? this.availability,
      minServicePrice: minServicePrice ?? this.minServicePrice,
      location: location ?? this.location,
      locationNormalized: locationNormalized ?? this.locationNormalized,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (certifications.present) {
      map['certifications'] = Variable<String>(certifications.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (aboutMe.present) {
      map['about_me'] = Variable<String>(aboutMe.value);
    }
    if (philosophy.present) {
      map['philosophy'] = Variable<String>(philosophy.value);
    }
    if (methodology.present) {
      map['methodology'] = Variable<String>(methodology.value);
    }
    if (branding.present) {
      map['branding'] = Variable<String>(branding.value);
    }
    if (bannerImagePath.present) {
      map['banner_image_path'] = Variable<String>(bannerImagePath.value);
    }
    if (customDomain.present) {
      map['custom_domain'] = Variable<String>(customDomain.value);
    }
    if (domainVerified.present) {
      map['domain_verified'] = Variable<bool>(domainVerified.value);
    }
    if (profilePhotoPath.present) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath.value);
    }
    if (specialties.present) {
      map['specialties'] = Variable<String>(specialties.value);
    }
    if (trainingTypes.present) {
      map['training_types'] = Variable<String>(trainingTypes.value);
    }
    if (businessCurrency.present) {
      map['business_currency'] = Variable<String>(businessCurrency.value);
    }
    if (averageRating.present) {
      map['average_rating'] = Variable<double>(averageRating.value);
    }
    if (completionPercentage.present) {
      map['completion_percentage'] = Variable<int>(completionPercentage.value);
    }
    if (missingFields.present) {
      map['missing_fields'] = Variable<String>(missingFields.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (minServicePrice.present) {
      map['min_service_price'] = Variable<double>(minServicePrice.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (locationNormalized.present) {
      map['location_normalized'] = Variable<String>(locationNormalized.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainerProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('certifications: $certifications, ')
          ..write('phone: $phone, ')
          ..write('aboutMe: $aboutMe, ')
          ..write('philosophy: $philosophy, ')
          ..write('methodology: $methodology, ')
          ..write('branding: $branding, ')
          ..write('bannerImagePath: $bannerImagePath, ')
          ..write('customDomain: $customDomain, ')
          ..write('domainVerified: $domainVerified, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('specialties: $specialties, ')
          ..write('trainingTypes: $trainingTypes, ')
          ..write('businessCurrency: $businessCurrency, ')
          ..write('averageRating: $averageRating, ')
          ..write('completionPercentage: $completionPercentage, ')
          ..write('missingFields: $missingFields, ')
          ..write('isVerified: $isVerified, ')
          ..write('availability: $availability, ')
          ..write('minServicePrice: $minServicePrice, ')
          ..write('location: $location, ')
          ..write('locationNormalized: $locationNormalized, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<BigInt> startTime = GeneratedColumn<BigInt>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<BigInt> endTime = GeneratedColumn<BigInt>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restStartedAtMeta = const VerificationMeta(
    'restStartedAt',
  );
  @override
  late final GeneratedColumn<BigInt> restStartedAt = GeneratedColumn<BigInt>(
    'rest_started_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutTemplateIdMeta = const VerificationMeta(
    'workoutTemplateId',
  );
  @override
  late final GeneratedColumn<String> workoutTemplateId =
      GeneratedColumn<String>(
        'workout_template_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plannedDateMeta = const VerificationMeta(
    'plannedDate',
  );
  @override
  late final GeneratedColumn<BigInt> plannedDate = GeneratedColumn<BigInt>(
    'planned_date',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientPackageIdMeta = const VerificationMeta(
    'clientPackageId',
  );
  @override
  late final GeneratedColumn<String> clientPackageId = GeneratedColumn<String>(
    'client_package_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTrainerLedMeta = const VerificationMeta(
    'isTrainerLed',
  );
  @override
  late final GeneratedColumn<bool> isTrainerLed = GeneratedColumn<bool>(
    'is_trainer_led',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trainer_led" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<BigInt> reminderTime = GeneratedColumn<BigInt>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trainerReminderSentMeta =
      const VerificationMeta('trainerReminderSent');
  @override
  late final GeneratedColumn<bool> trainerReminderSent = GeneratedColumn<bool>(
    'trainer_reminder_sent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trainer_reminder_sent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    name,
    startTime,
    endTime,
    status,
    notes,
    restStartedAt,
    workoutTemplateId,
    plannedDate,
    clientPackageId,
    isTrainerLed,
    reminderTime,
    trainerReminderSent,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rest_started_at')) {
      context.handle(
        _restStartedAtMeta,
        restStartedAt.isAcceptableOrUnknown(
          data['rest_started_at']!,
          _restStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('workout_template_id')) {
      context.handle(
        _workoutTemplateIdMeta,
        workoutTemplateId.isAcceptableOrUnknown(
          data['workout_template_id']!,
          _workoutTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('planned_date')) {
      context.handle(
        _plannedDateMeta,
        plannedDate.isAcceptableOrUnknown(
          data['planned_date']!,
          _plannedDateMeta,
        ),
      );
    }
    if (data.containsKey('client_package_id')) {
      context.handle(
        _clientPackageIdMeta,
        clientPackageId.isAcceptableOrUnknown(
          data['client_package_id']!,
          _clientPackageIdMeta,
        ),
      );
    }
    if (data.containsKey('is_trainer_led')) {
      context.handle(
        _isTrainerLedMeta,
        isTrainerLed.isAcceptableOrUnknown(
          data['is_trainer_led']!,
          _isTrainerLedMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('trainer_reminder_sent')) {
      context.handle(
        _trainerReminderSentMeta,
        trainerReminderSent.isAcceptableOrUnknown(
          data['trainer_reminder_sent']!,
          _trainerReminderSentMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}end_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      restStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}rest_started_at'],
      ),
      workoutTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_template_id'],
      ),
      plannedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}planned_date'],
      ),
      clientPackageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_package_id'],
      ),
      isTrainerLed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trainer_led'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}reminder_time'],
      ),
      trainerReminderSent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trainer_reminder_sent'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final String id;
  final String clientId;
  final String? name;
  final BigInt startTime;
  final BigInt? endTime;
  final String status;
  final String? notes;
  final BigInt? restStartedAt;
  final String? workoutTemplateId;
  final BigInt? plannedDate;
  final String? clientPackageId;
  final bool isTrainerLed;
  final BigInt? reminderTime;
  final bool trainerReminderSent;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const WorkoutSession({
    required this.id,
    required this.clientId,
    this.name,
    required this.startTime,
    this.endTime,
    required this.status,
    this.notes,
    this.restStartedAt,
    this.workoutTemplateId,
    this.plannedDate,
    this.clientPackageId,
    required this.isTrainerLed,
    this.reminderTime,
    required this.trainerReminderSent,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['start_time'] = Variable<BigInt>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<BigInt>(endTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || restStartedAt != null) {
      map['rest_started_at'] = Variable<BigInt>(restStartedAt);
    }
    if (!nullToAbsent || workoutTemplateId != null) {
      map['workout_template_id'] = Variable<String>(workoutTemplateId);
    }
    if (!nullToAbsent || plannedDate != null) {
      map['planned_date'] = Variable<BigInt>(plannedDate);
    }
    if (!nullToAbsent || clientPackageId != null) {
      map['client_package_id'] = Variable<String>(clientPackageId);
    }
    map['is_trainer_led'] = Variable<bool>(isTrainerLed);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<BigInt>(reminderTime);
    }
    map['trainer_reminder_sent'] = Variable<bool>(trainerReminderSent);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      restStartedAt: restStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(restStartedAt),
      workoutTemplateId: workoutTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutTemplateId),
      plannedDate: plannedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedDate),
      clientPackageId: clientPackageId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientPackageId),
      isTrainerLed: Value(isTrainerLed),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      trainerReminderSent: Value(trainerReminderSent),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      name: serializer.fromJson<String?>(json['name']),
      startTime: serializer.fromJson<BigInt>(json['startTime']),
      endTime: serializer.fromJson<BigInt?>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      restStartedAt: serializer.fromJson<BigInt?>(json['restStartedAt']),
      workoutTemplateId: serializer.fromJson<String?>(
        json['workoutTemplateId'],
      ),
      plannedDate: serializer.fromJson<BigInt?>(json['plannedDate']),
      clientPackageId: serializer.fromJson<String?>(json['clientPackageId']),
      isTrainerLed: serializer.fromJson<bool>(json['isTrainerLed']),
      reminderTime: serializer.fromJson<BigInt?>(json['reminderTime']),
      trainerReminderSent: serializer.fromJson<bool>(
        json['trainerReminderSent'],
      ),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'name': serializer.toJson<String?>(name),
      'startTime': serializer.toJson<BigInt>(startTime),
      'endTime': serializer.toJson<BigInt?>(endTime),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'restStartedAt': serializer.toJson<BigInt?>(restStartedAt),
      'workoutTemplateId': serializer.toJson<String?>(workoutTemplateId),
      'plannedDate': serializer.toJson<BigInt?>(plannedDate),
      'clientPackageId': serializer.toJson<String?>(clientPackageId),
      'isTrainerLed': serializer.toJson<bool>(isTrainerLed),
      'reminderTime': serializer.toJson<BigInt?>(reminderTime),
      'trainerReminderSent': serializer.toJson<bool>(trainerReminderSent),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  WorkoutSession copyWith({
    String? id,
    String? clientId,
    Value<String?> name = const Value.absent(),
    BigInt? startTime,
    Value<BigInt?> endTime = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    Value<BigInt?> restStartedAt = const Value.absent(),
    Value<String?> workoutTemplateId = const Value.absent(),
    Value<BigInt?> plannedDate = const Value.absent(),
    Value<String?> clientPackageId = const Value.absent(),
    bool? isTrainerLed,
    Value<BigInt?> reminderTime = const Value.absent(),
    bool? trainerReminderSent,
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => WorkoutSession(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    name: name.present ? name.value : this.name,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    restStartedAt: restStartedAt.present
        ? restStartedAt.value
        : this.restStartedAt,
    workoutTemplateId: workoutTemplateId.present
        ? workoutTemplateId.value
        : this.workoutTemplateId,
    plannedDate: plannedDate.present ? plannedDate.value : this.plannedDate,
    clientPackageId: clientPackageId.present
        ? clientPackageId.value
        : this.clientPackageId,
    isTrainerLed: isTrainerLed ?? this.isTrainerLed,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    trainerReminderSent: trainerReminderSent ?? this.trainerReminderSent,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      name: data.name.present ? data.name.value : this.name,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      restStartedAt: data.restStartedAt.present
          ? data.restStartedAt.value
          : this.restStartedAt,
      workoutTemplateId: data.workoutTemplateId.present
          ? data.workoutTemplateId.value
          : this.workoutTemplateId,
      plannedDate: data.plannedDate.present
          ? data.plannedDate.value
          : this.plannedDate,
      clientPackageId: data.clientPackageId.present
          ? data.clientPackageId.value
          : this.clientPackageId,
      isTrainerLed: data.isTrainerLed.present
          ? data.isTrainerLed.value
          : this.isTrainerLed,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      trainerReminderSent: data.trainerReminderSent.present
          ? data.trainerReminderSent.value
          : this.trainerReminderSent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('name: $name, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('restStartedAt: $restStartedAt, ')
          ..write('workoutTemplateId: $workoutTemplateId, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('clientPackageId: $clientPackageId, ')
          ..write('isTrainerLed: $isTrainerLed, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('trainerReminderSent: $trainerReminderSent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    name,
    startTime,
    endTime,
    status,
    notes,
    restStartedAt,
    workoutTemplateId,
    plannedDate,
    clientPackageId,
    isTrainerLed,
    reminderTime,
    trainerReminderSent,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.name == this.name &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.restStartedAt == this.restStartedAt &&
          other.workoutTemplateId == this.workoutTemplateId &&
          other.plannedDate == this.plannedDate &&
          other.clientPackageId == this.clientPackageId &&
          other.isTrainerLed == this.isTrainerLed &&
          other.reminderTime == this.reminderTime &&
          other.trainerReminderSent == this.trainerReminderSent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<String?> name;
  final Value<BigInt> startTime;
  final Value<BigInt?> endTime;
  final Value<String> status;
  final Value<String?> notes;
  final Value<BigInt?> restStartedAt;
  final Value<String?> workoutTemplateId;
  final Value<BigInt?> plannedDate;
  final Value<String?> clientPackageId;
  final Value<bool> isTrainerLed;
  final Value<BigInt?> reminderTime;
  final Value<bool> trainerReminderSent;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.name = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.restStartedAt = const Value.absent(),
    this.workoutTemplateId = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.clientPackageId = const Value.absent(),
    this.isTrainerLed = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.trainerReminderSent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    required String id,
    required String clientId,
    this.name = const Value.absent(),
    required BigInt startTime,
    this.endTime = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.restStartedAt = const Value.absent(),
    this.workoutTemplateId = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.clientPackageId = const Value.absent(),
    this.isTrainerLed = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.trainerReminderSent = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       startTime = Value(startTime),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkoutSession> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? name,
    Expression<BigInt>? startTime,
    Expression<BigInt>? endTime,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<BigInt>? restStartedAt,
    Expression<String>? workoutTemplateId,
    Expression<BigInt>? plannedDate,
    Expression<String>? clientPackageId,
    Expression<bool>? isTrainerLed,
    Expression<BigInt>? reminderTime,
    Expression<bool>? trainerReminderSent,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (name != null) 'name': name,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (restStartedAt != null) 'rest_started_at': restStartedAt,
      if (workoutTemplateId != null) 'workout_template_id': workoutTemplateId,
      if (plannedDate != null) 'planned_date': plannedDate,
      if (clientPackageId != null) 'client_package_id': clientPackageId,
      if (isTrainerLed != null) 'is_trainer_led': isTrainerLed,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (trainerReminderSent != null)
        'trainer_reminder_sent': trainerReminderSent,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<String?>? name,
    Value<BigInt>? startTime,
    Value<BigInt?>? endTime,
    Value<String>? status,
    Value<String?>? notes,
    Value<BigInt?>? restStartedAt,
    Value<String?>? workoutTemplateId,
    Value<BigInt?>? plannedDate,
    Value<String?>? clientPackageId,
    Value<bool>? isTrainerLed,
    Value<BigInt?>? reminderTime,
    Value<bool>? trainerReminderSent,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      restStartedAt: restStartedAt ?? this.restStartedAt,
      workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
      plannedDate: plannedDate ?? this.plannedDate,
      clientPackageId: clientPackageId ?? this.clientPackageId,
      isTrainerLed: isTrainerLed ?? this.isTrainerLed,
      reminderTime: reminderTime ?? this.reminderTime,
      trainerReminderSent: trainerReminderSent ?? this.trainerReminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<BigInt>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<BigInt>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (restStartedAt.present) {
      map['rest_started_at'] = Variable<BigInt>(restStartedAt.value);
    }
    if (workoutTemplateId.present) {
      map['workout_template_id'] = Variable<String>(workoutTemplateId.value);
    }
    if (plannedDate.present) {
      map['planned_date'] = Variable<BigInt>(plannedDate.value);
    }
    if (clientPackageId.present) {
      map['client_package_id'] = Variable<String>(clientPackageId.value);
    }
    if (isTrainerLed.present) {
      map['is_trainer_led'] = Variable<bool>(isTrainerLed.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<BigInt>(reminderTime.value);
    }
    if (trainerReminderSent.present) {
      map['trainer_reminder_sent'] = Variable<bool>(trainerReminderSent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('name: $name, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('restStartedAt: $restStartedAt, ')
          ..write('workoutTemplateId: $workoutTemplateId, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('clientPackageId: $clientPackageId, ')
          ..write('isTrainerLed: $isTrainerLed, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('trainerReminderSent: $trainerReminderSent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleGroupMeta = const VerificationMeta(
    'muscleGroup',
  );
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
    'muscle_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<String> createdById = GeneratedColumn<String>(
    'created_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedRestSecondsMeta =
      const VerificationMeta('recommendedRestSeconds');
  @override
  late final GeneratedColumn<int> recommendedRestSeconds = GeneratedColumn<int>(
    'recommended_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUnilateralMeta = const VerificationMeta(
    'isUnilateral',
  );
  @override
  late final GeneratedColumn<bool> isUnilateral = GeneratedColumn<bool>(
    'is_unilateral',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unilateral" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    muscleGroup,
    equipment,
    category,
    description,
    videoUrl,
    createdById,
    recommendedRestSeconds,
    isUnilateral,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
        _muscleGroupMeta,
        muscleGroup.isAcceptableOrUnknown(
          data['muscle_group']!,
          _muscleGroupMeta,
        ),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    }
    if (data.containsKey('recommended_rest_seconds')) {
      context.handle(
        _recommendedRestSecondsMeta,
        recommendedRestSeconds.isAcceptableOrUnknown(
          data['recommended_rest_seconds']!,
          _recommendedRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_unilateral')) {
      context.handle(
        _isUnilateralMeta,
        isUnilateral.isAcceptableOrUnknown(
          data['is_unilateral']!,
          _isUnilateralMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      muscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_group'],
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_id'],
      ),
      recommendedRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_rest_seconds'],
      ),
      isUnilateral: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unilateral'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? equipment;
  final String? category;
  final String? description;
  final String? videoUrl;
  final String? createdById;
  final int? recommendedRestSeconds;
  final bool isUnilateral;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const Exercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.equipment,
    this.category,
    this.description,
    this.videoUrl,
    this.createdById,
    this.recommendedRestSeconds,
    required this.isUnilateral,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || muscleGroup != null) {
      map['muscle_group'] = Variable<String>(muscleGroup);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || createdById != null) {
      map['created_by_id'] = Variable<String>(createdById);
    }
    if (!nullToAbsent || recommendedRestSeconds != null) {
      map['recommended_rest_seconds'] = Variable<int>(recommendedRestSeconds);
    }
    map['is_unilateral'] = Variable<bool>(isUnilateral);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleGroup: muscleGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(muscleGroup),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      createdById: createdById == null && nullToAbsent
          ? const Value.absent()
          : Value(createdById),
      recommendedRestSeconds: recommendedRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedRestSeconds),
      isUnilateral: Value(isUnilateral),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleGroup: serializer.fromJson<String?>(json['muscleGroup']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      category: serializer.fromJson<String?>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      createdById: serializer.fromJson<String?>(json['createdById']),
      recommendedRestSeconds: serializer.fromJson<int?>(
        json['recommendedRestSeconds'],
      ),
      isUnilateral: serializer.fromJson<bool>(json['isUnilateral']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'muscleGroup': serializer.toJson<String?>(muscleGroup),
      'equipment': serializer.toJson<String?>(equipment),
      'category': serializer.toJson<String?>(category),
      'description': serializer.toJson<String?>(description),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'createdById': serializer.toJson<String?>(createdById),
      'recommendedRestSeconds': serializer.toJson<int?>(recommendedRestSeconds),
      'isUnilateral': serializer.toJson<bool>(isUnilateral),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    Value<String?> muscleGroup = const Value.absent(),
    Value<String?> equipment = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> createdById = const Value.absent(),
    Value<int?> recommendedRestSeconds = const Value.absent(),
    bool? isUnilateral,
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    muscleGroup: muscleGroup.present ? muscleGroup.value : this.muscleGroup,
    equipment: equipment.present ? equipment.value : this.equipment,
    category: category.present ? category.value : this.category,
    description: description.present ? description.value : this.description,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    createdById: createdById.present ? createdById.value : this.createdById,
    recommendedRestSeconds: recommendedRestSeconds.present
        ? recommendedRestSeconds.value
        : this.recommendedRestSeconds,
    isUnilateral: isUnilateral ?? this.isUnilateral,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      recommendedRestSeconds: data.recommendedRestSeconds.present
          ? data.recommendedRestSeconds.value
          : this.recommendedRestSeconds,
      isUnilateral: data.isUnilateral.present
          ? data.isUnilateral.value
          : this.isUnilateral,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('createdById: $createdById, ')
          ..write('recommendedRestSeconds: $recommendedRestSeconds, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    muscleGroup,
    equipment,
    category,
    description,
    videoUrl,
    createdById,
    recommendedRestSeconds,
    isUnilateral,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleGroup == this.muscleGroup &&
          other.equipment == this.equipment &&
          other.category == this.category &&
          other.description == this.description &&
          other.videoUrl == this.videoUrl &&
          other.createdById == this.createdById &&
          other.recommendedRestSeconds == this.recommendedRestSeconds &&
          other.isUnilateral == this.isUnilateral &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> muscleGroup;
  final Value<String?> equipment;
  final Value<String?> category;
  final Value<String?> description;
  final Value<String?> videoUrl;
  final Value<String?> createdById;
  final Value<int?> recommendedRestSeconds;
  final Value<bool> isUnilateral;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.equipment = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.createdById = const Value.absent(),
    this.recommendedRestSeconds = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    this.muscleGroup = const Value.absent(),
    this.equipment = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.createdById = const Value.absent(),
    this.recommendedRestSeconds = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? muscleGroup,
    Expression<String>? equipment,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? videoUrl,
    Expression<String>? createdById,
    Expression<int>? recommendedRestSeconds,
    Expression<bool>? isUnilateral,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (equipment != null) 'equipment': equipment,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (videoUrl != null) 'video_url': videoUrl,
      if (createdById != null) 'created_by_id': createdById,
      if (recommendedRestSeconds != null)
        'recommended_rest_seconds': recommendedRestSeconds,
      if (isUnilateral != null) 'is_unilateral': isUnilateral,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? muscleGroup,
    Value<String?>? equipment,
    Value<String?>? category,
    Value<String?>? description,
    Value<String?>? videoUrl,
    Value<String?>? createdById,
    Value<int?>? recommendedRestSeconds,
    Value<bool>? isUnilateral,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      category: category ?? this.category,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      createdById: createdById ?? this.createdById,
      recommendedRestSeconds:
          recommendedRestSeconds ?? this.recommendedRestSeconds,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<String>(createdById.value);
    }
    if (recommendedRestSeconds.present) {
      map['recommended_rest_seconds'] = Variable<int>(
        recommendedRestSeconds.value,
      );
    }
    if (isUnilateral.present) {
      map['is_unilateral'] = Variable<bool>(isUnilateral.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('createdById: $createdById, ')
          ..write('recommendedRestSeconds: $recommendedRestSeconds, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    programId,
    order,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final String id;
  final String name;
  final String? description;
  final String programId;
  final int order;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.programId,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['program_id'] = Variable<String>(programId);
    map['order'] = Variable<int>(order);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      programId: Value(programId),
      order: Value(order),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      programId: serializer.fromJson<String>(json['programId']),
      order: serializer.fromJson<int>(json['order']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'programId': serializer.toJson<String>(programId),
      'order': serializer.toJson<int>(order),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? programId,
    int? order,
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    programId: programId ?? this.programId,
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      programId: data.programId.present ? data.programId.value : this.programId,
      order: data.order.present ? data.order.value : this.order,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('programId: $programId, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    programId,
    order,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.programId == this.programId &&
          other.order == this.order &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> programId;
  final Value<int> order;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.programId = const Value.absent(),
    this.order = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String programId,
    this.order = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       programId = Value(programId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkoutTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? programId,
    Expression<int>? order,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (programId != null) 'program_id': programId,
      if (order != null) 'order': order,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? programId,
    Value<int>? order,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      programId: programId ?? this.programId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('programId: $programId, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientAssessmentsTable extends ClientAssessments
    with TableInfo<$ClientAssessmentsTable, ClientAssessment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientAssessmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assessmentIdMeta = const VerificationMeta(
    'assessmentId',
  );
  @override
  late final GeneratedColumn<String> assessmentId = GeneratedColumn<String>(
    'assessment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<BigInt> date = GeneratedColumn<BigInt>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assessmentId,
    clientId,
    value,
    date,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientAssessment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('assessment_id')) {
      context.handle(
        _assessmentIdMeta,
        assessmentId.isAcceptableOrUnknown(
          data['assessment_id']!,
          _assessmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assessmentIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientAssessment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientAssessment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assessmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ClientAssessmentsTable createAlias(String alias) {
    return $ClientAssessmentsTable(attachedDatabase, alias);
  }
}

class ClientAssessment extends DataClass
    implements Insertable<ClientAssessment> {
  final String id;
  final String assessmentId;
  final String clientId;
  final double value;
  final BigInt date;
  final String? notes;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const ClientAssessment({
    required this.id,
    required this.assessmentId,
    required this.clientId,
    required this.value,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['assessment_id'] = Variable<String>(assessmentId);
    map['client_id'] = Variable<String>(clientId);
    map['value'] = Variable<double>(value);
    map['date'] = Variable<BigInt>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ClientAssessmentsCompanion toCompanion(bool nullToAbsent) {
    return ClientAssessmentsCompanion(
      id: Value(id),
      assessmentId: Value(assessmentId),
      clientId: Value(clientId),
      value: Value(value),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ClientAssessment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientAssessment(
      id: serializer.fromJson<String>(json['id']),
      assessmentId: serializer.fromJson<String>(json['assessmentId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      value: serializer.fromJson<double>(json['value']),
      date: serializer.fromJson<BigInt>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assessmentId': serializer.toJson<String>(assessmentId),
      'clientId': serializer.toJson<String>(clientId),
      'value': serializer.toJson<double>(value),
      'date': serializer.toJson<BigInt>(date),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ClientAssessment copyWith({
    String? id,
    String? assessmentId,
    String? clientId,
    double? value,
    BigInt? date,
    Value<String?> notes = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => ClientAssessment(
    id: id ?? this.id,
    assessmentId: assessmentId ?? this.assessmentId,
    clientId: clientId ?? this.clientId,
    value: value ?? this.value,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ClientAssessment copyWithCompanion(ClientAssessmentsCompanion data) {
    return ClientAssessment(
      id: data.id.present ? data.id.value : this.id,
      assessmentId: data.assessmentId.present
          ? data.assessmentId.value
          : this.assessmentId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      value: data.value.present ? data.value.value : this.value,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientAssessment(')
          ..write('id: $id, ')
          ..write('assessmentId: $assessmentId, ')
          ..write('clientId: $clientId, ')
          ..write('value: $value, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assessmentId,
    clientId,
    value,
    date,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientAssessment &&
          other.id == this.id &&
          other.assessmentId == this.assessmentId &&
          other.clientId == this.clientId &&
          other.value == this.value &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ClientAssessmentsCompanion extends UpdateCompanion<ClientAssessment> {
  final Value<String> id;
  final Value<String> assessmentId;
  final Value<String> clientId;
  final Value<double> value;
  final Value<BigInt> date;
  final Value<String?> notes;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ClientAssessmentsCompanion({
    this.id = const Value.absent(),
    this.assessmentId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.value = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientAssessmentsCompanion.insert({
    required String id,
    required String assessmentId,
    required String clientId,
    required double value,
    required BigInt date,
    this.notes = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assessmentId = Value(assessmentId),
       clientId = Value(clientId),
       value = Value(value),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClientAssessment> custom({
    Expression<String>? id,
    Expression<String>? assessmentId,
    Expression<String>? clientId,
    Expression<double>? value,
    Expression<BigInt>? date,
    Expression<String>? notes,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assessmentId != null) 'assessment_id': assessmentId,
      if (clientId != null) 'client_id': clientId,
      if (value != null) 'value': value,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientAssessmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? assessmentId,
    Value<String>? clientId,
    Value<double>? value,
    Value<BigInt>? date,
    Value<String?>? notes,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ClientAssessmentsCompanion(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      clientId: clientId ?? this.clientId,
      value: value ?? this.value,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assessmentId.present) {
      map['assessment_id'] = Variable<String>(assessmentId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (date.present) {
      map['date'] = Variable<BigInt>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientAssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('assessmentId: $assessmentId, ')
          ..write('clientId: $clientId, ')
          ..write('value: $value, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientMeasurementsTable extends ClientMeasurements
    with TableInfo<$ClientMeasurementsTable, ClientMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementDateMeta = const VerificationMeta(
    'measurementDate',
  );
  @override
  late final GeneratedColumn<BigInt> measurementDate = GeneratedColumn<BigInt>(
    'measurement_date',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFatPercentageMeta = const VerificationMeta(
    'bodyFatPercentage',
  );
  @override
  late final GeneratedColumn<double> bodyFatPercentage =
      GeneratedColumn<double>(
        'body_fat_percentage',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customMetricsMeta = const VerificationMeta(
    'customMetrics',
  );
  @override
  late final GeneratedColumn<String> customMetrics = GeneratedColumn<String>(
    'custom_metrics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    measurementDate,
    weightKg,
    bodyFatPercentage,
    notes,
    customMetrics,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('measurement_date')) {
      context.handle(
        _measurementDateMeta,
        measurementDate.isAcceptableOrUnknown(
          data['measurement_date']!,
          _measurementDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementDateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('body_fat_percentage')) {
      context.handle(
        _bodyFatPercentageMeta,
        bodyFatPercentage.isAcceptableOrUnknown(
          data['body_fat_percentage']!,
          _bodyFatPercentageMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('custom_metrics')) {
      context.handle(
        _customMetricsMeta,
        customMetrics.isAcceptableOrUnknown(
          data['custom_metrics']!,
          _customMetricsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      measurementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}measurement_date'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      bodyFatPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_percentage'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      customMetrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_metrics'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ClientMeasurementsTable createAlias(String alias) {
    return $ClientMeasurementsTable(attachedDatabase, alias);
  }
}

class ClientMeasurement extends DataClass
    implements Insertable<ClientMeasurement> {
  final String id;
  final String clientId;
  final BigInt measurementDate;
  final double? weightKg;
  final double? bodyFatPercentage;
  final String? notes;
  final String? customMetrics;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const ClientMeasurement({
    required this.id,
    required this.clientId,
    required this.measurementDate,
    this.weightKg,
    this.bodyFatPercentage,
    this.notes,
    this.customMetrics,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['measurement_date'] = Variable<BigInt>(measurementDate);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || bodyFatPercentage != null) {
      map['body_fat_percentage'] = Variable<double>(bodyFatPercentage);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || customMetrics != null) {
      map['custom_metrics'] = Variable<String>(customMetrics);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ClientMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return ClientMeasurementsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      measurementDate: Value(measurementDate),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      bodyFatPercentage: bodyFatPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercentage),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      customMetrics: customMetrics == null && nullToAbsent
          ? const Value.absent()
          : Value(customMetrics),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ClientMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientMeasurement(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      measurementDate: serializer.fromJson<BigInt>(json['measurementDate']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      bodyFatPercentage: serializer.fromJson<double?>(
        json['bodyFatPercentage'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      customMetrics: serializer.fromJson<String?>(json['customMetrics']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'measurementDate': serializer.toJson<BigInt>(measurementDate),
      'weightKg': serializer.toJson<double?>(weightKg),
      'bodyFatPercentage': serializer.toJson<double?>(bodyFatPercentage),
      'notes': serializer.toJson<String?>(notes),
      'customMetrics': serializer.toJson<String?>(customMetrics),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ClientMeasurement copyWith({
    String? id,
    String? clientId,
    BigInt? measurementDate,
    Value<double?> weightKg = const Value.absent(),
    Value<double?> bodyFatPercentage = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> customMetrics = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => ClientMeasurement(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    measurementDate: measurementDate ?? this.measurementDate,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    bodyFatPercentage: bodyFatPercentage.present
        ? bodyFatPercentage.value
        : this.bodyFatPercentage,
    notes: notes.present ? notes.value : this.notes,
    customMetrics: customMetrics.present
        ? customMetrics.value
        : this.customMetrics,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ClientMeasurement copyWithCompanion(ClientMeasurementsCompanion data) {
    return ClientMeasurement(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      measurementDate: data.measurementDate.present
          ? data.measurementDate.value
          : this.measurementDate,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPercentage: data.bodyFatPercentage.present
          ? data.bodyFatPercentage.value
          : this.bodyFatPercentage,
      notes: data.notes.present ? data.notes.value : this.notes,
      customMetrics: data.customMetrics.present
          ? data.customMetrics.value
          : this.customMetrics,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientMeasurement(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('measurementDate: $measurementDate, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercentage: $bodyFatPercentage, ')
          ..write('notes: $notes, ')
          ..write('customMetrics: $customMetrics, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    measurementDate,
    weightKg,
    bodyFatPercentage,
    notes,
    customMetrics,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientMeasurement &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.measurementDate == this.measurementDate &&
          other.weightKg == this.weightKg &&
          other.bodyFatPercentage == this.bodyFatPercentage &&
          other.notes == this.notes &&
          other.customMetrics == this.customMetrics &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ClientMeasurementsCompanion extends UpdateCompanion<ClientMeasurement> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<BigInt> measurementDate;
  final Value<double?> weightKg;
  final Value<double?> bodyFatPercentage;
  final Value<String?> notes;
  final Value<String?> customMetrics;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ClientMeasurementsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.measurementDate = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    this.customMetrics = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientMeasurementsCompanion.insert({
    required String id,
    required String clientId,
    required BigInt measurementDate,
    this.weightKg = const Value.absent(),
    this.bodyFatPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    this.customMetrics = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       measurementDate = Value(measurementDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClientMeasurement> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<BigInt>? measurementDate,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPercentage,
    Expression<String>? notes,
    Expression<String>? customMetrics,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (measurementDate != null) 'measurement_date': measurementDate,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
      if (notes != null) 'notes': notes,
      if (customMetrics != null) 'custom_metrics': customMetrics,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientMeasurementsCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<BigInt>? measurementDate,
    Value<double?>? weightKg,
    Value<double?>? bodyFatPercentage,
    Value<String?>? notes,
    Value<String?>? customMetrics,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ClientMeasurementsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      measurementDate: measurementDate ?? this.measurementDate,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      notes: notes ?? this.notes,
      customMetrics: customMetrics ?? this.customMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (measurementDate.present) {
      map['measurement_date'] = Variable<BigInt>(measurementDate.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPercentage.present) {
      map['body_fat_percentage'] = Variable<double>(bodyFatPercentage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (customMetrics.present) {
      map['custom_metrics'] = Variable<String>(customMetrics.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('measurementDate: $measurementDate, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercentage: $bodyFatPercentage, ')
          ..write('notes: $notes, ')
          ..write('customMetrics: $customMetrics, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientPhotosTable extends ClientPhotos
    with TableInfo<$ClientPhotosTable, ClientPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoDateMeta = const VerificationMeta(
    'photoDate',
  );
  @override
  late final GeneratedColumn<BigInt> photoDate = GeneratedColumn<BigInt>(
    'photo_date',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkInIdMeta = const VerificationMeta(
    'checkInId',
  );
  @override
  late final GeneratedColumn<String> checkInId = GeneratedColumn<String>(
    'check_in_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    photoDate,
    imagePath,
    caption,
    checkInId,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('photo_date')) {
      context.handle(
        _photoDateMeta,
        photoDate.isAcceptableOrUnknown(data['photo_date']!, _photoDateMeta),
      );
    } else if (isInserting) {
      context.missing(_photoDateMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('check_in_id')) {
      context.handle(
        _checkInIdMeta,
        checkInId.isAcceptableOrUnknown(data['check_in_id']!, _checkInIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      photoDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}photo_date'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      checkInId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_in_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ClientPhotosTable createAlias(String alias) {
    return $ClientPhotosTable(attachedDatabase, alias);
  }
}

class ClientPhoto extends DataClass implements Insertable<ClientPhoto> {
  final String id;
  final String clientId;
  final BigInt photoDate;
  final String imagePath;
  final String? caption;
  final String? checkInId;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const ClientPhoto({
    required this.id,
    required this.clientId,
    required this.photoDate,
    required this.imagePath,
    this.caption,
    this.checkInId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['photo_date'] = Variable<BigInt>(photoDate);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || checkInId != null) {
      map['check_in_id'] = Variable<String>(checkInId);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ClientPhotosCompanion toCompanion(bool nullToAbsent) {
    return ClientPhotosCompanion(
      id: Value(id),
      clientId: Value(clientId),
      photoDate: Value(photoDate),
      imagePath: Value(imagePath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      checkInId: checkInId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ClientPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientPhoto(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      photoDate: serializer.fromJson<BigInt>(json['photoDate']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      caption: serializer.fromJson<String?>(json['caption']),
      checkInId: serializer.fromJson<String?>(json['checkInId']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'photoDate': serializer.toJson<BigInt>(photoDate),
      'imagePath': serializer.toJson<String>(imagePath),
      'caption': serializer.toJson<String?>(caption),
      'checkInId': serializer.toJson<String?>(checkInId),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ClientPhoto copyWith({
    String? id,
    String? clientId,
    BigInt? photoDate,
    String? imagePath,
    Value<String?> caption = const Value.absent(),
    Value<String?> checkInId = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => ClientPhoto(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    photoDate: photoDate ?? this.photoDate,
    imagePath: imagePath ?? this.imagePath,
    caption: caption.present ? caption.value : this.caption,
    checkInId: checkInId.present ? checkInId.value : this.checkInId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ClientPhoto copyWithCompanion(ClientPhotosCompanion data) {
    return ClientPhoto(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      photoDate: data.photoDate.present ? data.photoDate.value : this.photoDate,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      checkInId: data.checkInId.present ? data.checkInId.value : this.checkInId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientPhoto(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('photoDate: $photoDate, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('checkInId: $checkInId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    photoDate,
    imagePath,
    caption,
    checkInId,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientPhoto &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.photoDate == this.photoDate &&
          other.imagePath == this.imagePath &&
          other.caption == this.caption &&
          other.checkInId == this.checkInId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ClientPhotosCompanion extends UpdateCompanion<ClientPhoto> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<BigInt> photoDate;
  final Value<String> imagePath;
  final Value<String?> caption;
  final Value<String?> checkInId;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ClientPhotosCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.photoDate = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.checkInId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientPhotosCompanion.insert({
    required String id,
    required String clientId,
    required BigInt photoDate,
    required String imagePath,
    this.caption = const Value.absent(),
    this.checkInId = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       photoDate = Value(photoDate),
       imagePath = Value(imagePath),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClientPhoto> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<BigInt>? photoDate,
    Expression<String>? imagePath,
    Expression<String>? caption,
    Expression<String>? checkInId,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (photoDate != null) 'photo_date': photoDate,
      if (imagePath != null) 'image_path': imagePath,
      if (caption != null) 'caption': caption,
      if (checkInId != null) 'check_in_id': checkInId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<BigInt>? photoDate,
    Value<String>? imagePath,
    Value<String?>? caption,
    Value<String?>? checkInId,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ClientPhotosCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      photoDate: photoDate ?? this.photoDate,
      imagePath: imagePath ?? this.imagePath,
      caption: caption ?? this.caption,
      checkInId: checkInId ?? this.checkInId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (photoDate.present) {
      map['photo_date'] = Variable<BigInt>(photoDate.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (checkInId.present) {
      map['check_in_id'] = Variable<String>(checkInId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientPhotosCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('photoDate: $photoDate, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('checkInId: $checkInId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientExerciseLogsTable extends ClientExerciseLogs
    with TableInfo<$ClientExerciseLogsTable, ClientExerciseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientExerciseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<String> tempo = GeneratedColumn<String>(
    'tempo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('BOTH'),
  );
  static const VerificationMeta _workoutSessionIdMeta = const VerificationMeta(
    'workoutSessionId',
  );
  @override
  late final GeneratedColumn<String> workoutSessionId = GeneratedColumn<String>(
    'workout_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersetKeyMeta = const VerificationMeta(
    'supersetKey',
  );
  @override
  late final GeneratedColumn<String> supersetKey = GeneratedColumn<String>(
    'superset_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderInSupersetMeta = const VerificationMeta(
    'orderInSuperset',
  );
  @override
  late final GeneratedColumn<int> orderInSuperset = GeneratedColumn<int>(
    'order_in_superset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<String> sets = GeneratedColumn<String>(
    'sets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_exercise_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientExerciseLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('tempo')) {
      context.handle(
        _tempoMeta,
        tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta),
      );
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    }
    if (data.containsKey('workout_session_id')) {
      context.handle(
        _workoutSessionIdMeta,
        workoutSessionId.isAcceptableOrUnknown(
          data['workout_session_id']!,
          _workoutSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutSessionIdMeta);
    }
    if (data.containsKey('superset_key')) {
      context.handle(
        _supersetKeyMeta,
        supersetKey.isAcceptableOrUnknown(
          data['superset_key']!,
          _supersetKeyMeta,
        ),
      );
    }
    if (data.containsKey('order_in_superset')) {
      context.handle(
        _orderInSupersetMeta,
        orderInSuperset.isAcceptableOrUnknown(
          data['order_in_superset']!,
          _orderInSupersetMeta,
        ),
      );
    }
    if (data.containsKey('sets')) {
      context.handle(
        _setsMeta,
        sets.isAcceptableOrUnknown(data['sets']!, _setsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientExerciseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientExerciseLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      ),
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      ),
      tempo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tempo'],
      ),
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      )!,
      workoutSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_session_id'],
      )!,
      supersetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_key'],
      ),
      orderInSuperset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_in_superset'],
      ),
      sets: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sets'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ClientExerciseLogsTable createAlias(String alias) {
    return $ClientExerciseLogsTable(attachedDatabase, alias);
  }
}

class ClientExerciseLog extends DataClass
    implements Insertable<ClientExerciseLog> {
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
  final String? sets;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const ClientExerciseLog({
    required this.id,
    required this.clientId,
    required this.exerciseId,
    this.reps,
    this.weight,
    this.isCompleted,
    this.order,
    this.tempo,
    required this.side,
    required this.workoutSessionId,
    this.supersetKey,
    this.orderInSuperset,
    this.sets,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['exercise_id'] = Variable<String>(exerciseId);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || isCompleted != null) {
      map['is_completed'] = Variable<bool>(isCompleted);
    }
    if (!nullToAbsent || order != null) {
      map['order'] = Variable<int>(order);
    }
    if (!nullToAbsent || tempo != null) {
      map['tempo'] = Variable<String>(tempo);
    }
    map['side'] = Variable<String>(side);
    map['workout_session_id'] = Variable<String>(workoutSessionId);
    if (!nullToAbsent || supersetKey != null) {
      map['superset_key'] = Variable<String>(supersetKey);
    }
    if (!nullToAbsent || orderInSuperset != null) {
      map['order_in_superset'] = Variable<int>(orderInSuperset);
    }
    if (!nullToAbsent || sets != null) {
      map['sets'] = Variable<String>(sets);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ClientExerciseLogsCompanion toCompanion(bool nullToAbsent) {
    return ClientExerciseLogsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      exerciseId: Value(exerciseId),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      isCompleted: isCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(isCompleted),
      order: order == null && nullToAbsent
          ? const Value.absent()
          : Value(order),
      tempo: tempo == null && nullToAbsent
          ? const Value.absent()
          : Value(tempo),
      side: Value(side),
      workoutSessionId: Value(workoutSessionId),
      supersetKey: supersetKey == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetKey),
      orderInSuperset: orderInSuperset == null && nullToAbsent
          ? const Value.absent()
          : Value(orderInSuperset),
      sets: sets == null && nullToAbsent ? const Value.absent() : Value(sets),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ClientExerciseLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientExerciseLog(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      reps: serializer.fromJson<int?>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
      isCompleted: serializer.fromJson<bool?>(json['isCompleted']),
      order: serializer.fromJson<int?>(json['order']),
      tempo: serializer.fromJson<String?>(json['tempo']),
      side: serializer.fromJson<String>(json['side']),
      workoutSessionId: serializer.fromJson<String>(json['workoutSessionId']),
      supersetKey: serializer.fromJson<String?>(json['supersetKey']),
      orderInSuperset: serializer.fromJson<int?>(json['orderInSuperset']),
      sets: serializer.fromJson<String?>(json['sets']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'reps': serializer.toJson<int?>(reps),
      'weight': serializer.toJson<double?>(weight),
      'isCompleted': serializer.toJson<bool?>(isCompleted),
      'order': serializer.toJson<int?>(order),
      'tempo': serializer.toJson<String?>(tempo),
      'side': serializer.toJson<String>(side),
      'workoutSessionId': serializer.toJson<String>(workoutSessionId),
      'supersetKey': serializer.toJson<String?>(supersetKey),
      'orderInSuperset': serializer.toJson<int?>(orderInSuperset),
      'sets': serializer.toJson<String?>(sets),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ClientExerciseLog copyWith({
    String? id,
    String? clientId,
    String? exerciseId,
    Value<int?> reps = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<bool?> isCompleted = const Value.absent(),
    Value<int?> order = const Value.absent(),
    Value<String?> tempo = const Value.absent(),
    String? side,
    String? workoutSessionId,
    Value<String?> supersetKey = const Value.absent(),
    Value<int?> orderInSuperset = const Value.absent(),
    Value<String?> sets = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => ClientExerciseLog(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    exerciseId: exerciseId ?? this.exerciseId,
    reps: reps.present ? reps.value : this.reps,
    weight: weight.present ? weight.value : this.weight,
    isCompleted: isCompleted.present ? isCompleted.value : this.isCompleted,
    order: order.present ? order.value : this.order,
    tempo: tempo.present ? tempo.value : this.tempo,
    side: side ?? this.side,
    workoutSessionId: workoutSessionId ?? this.workoutSessionId,
    supersetKey: supersetKey.present ? supersetKey.value : this.supersetKey,
    orderInSuperset: orderInSuperset.present
        ? orderInSuperset.value
        : this.orderInSuperset,
    sets: sets.present ? sets.value : this.sets,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ClientExerciseLog copyWithCompanion(ClientExerciseLogsCompanion data) {
    return ClientExerciseLog(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      order: data.order.present ? data.order.value : this.order,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      side: data.side.present ? data.side.value : this.side,
      workoutSessionId: data.workoutSessionId.present
          ? data.workoutSessionId.value
          : this.workoutSessionId,
      supersetKey: data.supersetKey.present
          ? data.supersetKey.value
          : this.supersetKey,
      orderInSuperset: data.orderInSuperset.present
          ? data.orderInSuperset.value
          : this.orderInSuperset,
      sets: data.sets.present ? data.sets.value : this.sets,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientExerciseLog(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('order: $order, ')
          ..write('tempo: $tempo, ')
          ..write('side: $side, ')
          ..write('workoutSessionId: $workoutSessionId, ')
          ..write('supersetKey: $supersetKey, ')
          ..write('orderInSuperset: $orderInSuperset, ')
          ..write('sets: $sets, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

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
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientExerciseLog &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.exerciseId == this.exerciseId &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.isCompleted == this.isCompleted &&
          other.order == this.order &&
          other.tempo == this.tempo &&
          other.side == this.side &&
          other.workoutSessionId == this.workoutSessionId &&
          other.supersetKey == this.supersetKey &&
          other.orderInSuperset == this.orderInSuperset &&
          other.sets == this.sets &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ClientExerciseLogsCompanion extends UpdateCompanion<ClientExerciseLog> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<String> exerciseId;
  final Value<int?> reps;
  final Value<double?> weight;
  final Value<bool?> isCompleted;
  final Value<int?> order;
  final Value<String?> tempo;
  final Value<String> side;
  final Value<String> workoutSessionId;
  final Value<String?> supersetKey;
  final Value<int?> orderInSuperset;
  final Value<String?> sets;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ClientExerciseLogsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.order = const Value.absent(),
    this.tempo = const Value.absent(),
    this.side = const Value.absent(),
    this.workoutSessionId = const Value.absent(),
    this.supersetKey = const Value.absent(),
    this.orderInSuperset = const Value.absent(),
    this.sets = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientExerciseLogsCompanion.insert({
    required String id,
    required String clientId,
    required String exerciseId,
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.order = const Value.absent(),
    this.tempo = const Value.absent(),
    this.side = const Value.absent(),
    required String workoutSessionId,
    this.supersetKey = const Value.absent(),
    this.orderInSuperset = const Value.absent(),
    this.sets = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       exerciseId = Value(exerciseId),
       workoutSessionId = Value(workoutSessionId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClientExerciseLog> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? exerciseId,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<bool>? isCompleted,
    Expression<int>? order,
    Expression<String>? tempo,
    Expression<String>? side,
    Expression<String>? workoutSessionId,
    Expression<String>? supersetKey,
    Expression<int>? orderInSuperset,
    Expression<String>? sets,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (order != null) 'order': order,
      if (tempo != null) 'tempo': tempo,
      if (side != null) 'side': side,
      if (workoutSessionId != null) 'workout_session_id': workoutSessionId,
      if (supersetKey != null) 'superset_key': supersetKey,
      if (orderInSuperset != null) 'order_in_superset': orderInSuperset,
      if (sets != null) 'sets': sets,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientExerciseLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<String>? exerciseId,
    Value<int?>? reps,
    Value<double?>? weight,
    Value<bool?>? isCompleted,
    Value<int?>? order,
    Value<String?>? tempo,
    Value<String>? side,
    Value<String>? workoutSessionId,
    Value<String?>? supersetKey,
    Value<int?>? orderInSuperset,
    Value<String?>? sets,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ClientExerciseLogsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      tempo: tempo ?? this.tempo,
      side: side ?? this.side,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      supersetKey: supersetKey ?? this.supersetKey,
      orderInSuperset: orderInSuperset ?? this.orderInSuperset,
      sets: sets ?? this.sets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<String>(tempo.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (workoutSessionId.present) {
      map['workout_session_id'] = Variable<String>(workoutSessionId.value);
    }
    if (supersetKey.present) {
      map['superset_key'] = Variable<String>(supersetKey.value);
    }
    if (orderInSuperset.present) {
      map['order_in_superset'] = Variable<int>(orderInSuperset.value);
    }
    if (sets.present) {
      map['sets'] = Variable<String>(sets.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientExerciseLogsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('order: $order, ')
          ..write('tempo: $tempo, ')
          ..write('side: $side, ')
          ..write('workoutSessionId: $workoutSessionId, ')
          ..write('supersetKey: $supersetKey, ')
          ..write('orderInSuperset: $orderInSuperset, ')
          ..write('sets: $sets, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainerServicesTable extends TrainerServices
    with TableInfo<$TrainerServicesTable, TrainerService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainerServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    title,
    description,
    price,
    currency,
    duration,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trainer_services';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainerService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainerService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainerService(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TrainerServicesTable createAlias(String alias) {
    return $TrainerServicesTable(attachedDatabase, alias);
  }
}

class TrainerService extends DataClass implements Insertable<TrainerService> {
  final String id;
  final String profileId;
  final String title;
  final String description;
  final double? price;
  final String? currency;
  final int? duration;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const TrainerService({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    this.price,
    this.currency,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TrainerServicesCompanion toCompanion(bool nullToAbsent) {
    return TrainerServicesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      title: Value(title),
      description: Value(description),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TrainerService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainerService(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      price: serializer.fromJson<double?>(json['price']),
      currency: serializer.fromJson<String?>(json['currency']),
      duration: serializer.fromJson<int?>(json['duration']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'price': serializer.toJson<double?>(price),
      'currency': serializer.toJson<String?>(currency),
      'duration': serializer.toJson<int?>(duration),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TrainerService copyWith({
    String? id,
    String? profileId,
    String? title,
    String? description,
    Value<double?> price = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => TrainerService(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    title: title ?? this.title,
    description: description ?? this.description,
    price: price.present ? price.value : this.price,
    currency: currency.present ? currency.value : this.currency,
    duration: duration.present ? duration.value : this.duration,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TrainerService copyWithCompanion(TrainerServicesCompanion data) {
    return TrainerService(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      duration: data.duration.present ? data.duration.value : this.duration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainerService(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    title,
    description,
    price,
    currency,
    duration,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainerService &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.title == this.title &&
          other.description == this.description &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.duration == this.duration &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TrainerServicesCompanion extends UpdateCompanion<TrainerService> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> title;
  final Value<String> description;
  final Value<double?> price;
  final Value<String?> currency;
  final Value<int?> duration;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TrainerServicesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainerServicesCompanion.insert({
    required String id,
    required String profileId,
    required String title,
    required String description,
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.duration = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       title = Value(title),
       description = Value(description),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrainerService> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? price,
    Expression<String>? currency,
    Expression<int>? duration,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainerServicesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? title,
    Value<String>? description,
    Value<double?>? price,
    Value<String?>? currency,
    Value<int?>? duration,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TrainerServicesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainerServicesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainerPackagesTable extends TrainerPackages
    with TableInfo<$TrainerPackagesTable, TrainerPackage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainerPackagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberOfSessionsMeta = const VerificationMeta(
    'numberOfSessions',
  );
  @override
  late final GeneratedColumn<int> numberOfSessions = GeneratedColumn<int>(
    'number_of_sessions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _stripeProductIdMeta = const VerificationMeta(
    'stripeProductId',
  );
  @override
  late final GeneratedColumn<String> stripeProductId = GeneratedColumn<String>(
    'stripe_product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stripePriceIdMeta = const VerificationMeta(
    'stripePriceId',
  );
  @override
  late final GeneratedColumn<String> stripePriceId = GeneratedColumn<String>(
    'stripe_price_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainerIdMeta = const VerificationMeta(
    'trainerId',
  );
  @override
  late final GeneratedColumn<String> trainerId = GeneratedColumn<String>(
    'trainer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    price,
    numberOfSessions,
    isActive,
    stripeProductId,
    stripePriceId,
    trainerId,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trainer_packages';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainerPackage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('number_of_sessions')) {
      context.handle(
        _numberOfSessionsMeta,
        numberOfSessions.isAcceptableOrUnknown(
          data['number_of_sessions']!,
          _numberOfSessionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numberOfSessionsMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('stripe_product_id')) {
      context.handle(
        _stripeProductIdMeta,
        stripeProductId.isAcceptableOrUnknown(
          data['stripe_product_id']!,
          _stripeProductIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stripeProductIdMeta);
    }
    if (data.containsKey('stripe_price_id')) {
      context.handle(
        _stripePriceIdMeta,
        stripePriceId.isAcceptableOrUnknown(
          data['stripe_price_id']!,
          _stripePriceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stripePriceIdMeta);
    }
    if (data.containsKey('trainer_id')) {
      context.handle(
        _trainerIdMeta,
        trainerId.isAcceptableOrUnknown(data['trainer_id']!, _trainerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trainerIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainerPackage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainerPackage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      numberOfSessions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_sessions'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      stripeProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_product_id'],
      )!,
      stripePriceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stripe_price_id'],
      )!,
      trainerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TrainerPackagesTable createAlias(String alias) {
    return $TrainerPackagesTable(attachedDatabase, alias);
  }
}

class TrainerPackage extends DataClass implements Insertable<TrainerPackage> {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int numberOfSessions;
  final bool isActive;
  final String stripeProductId;
  final String stripePriceId;
  final String trainerId;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const TrainerPackage({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.numberOfSessions,
    required this.isActive,
    required this.stripeProductId,
    required this.stripePriceId,
    required this.trainerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    map['number_of_sessions'] = Variable<int>(numberOfSessions);
    map['is_active'] = Variable<bool>(isActive);
    map['stripe_product_id'] = Variable<String>(stripeProductId);
    map['stripe_price_id'] = Variable<String>(stripePriceId);
    map['trainer_id'] = Variable<String>(trainerId);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TrainerPackagesCompanion toCompanion(bool nullToAbsent) {
    return TrainerPackagesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      numberOfSessions: Value(numberOfSessions),
      isActive: Value(isActive),
      stripeProductId: Value(stripeProductId),
      stripePriceId: Value(stripePriceId),
      trainerId: Value(trainerId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TrainerPackage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainerPackage(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      numberOfSessions: serializer.fromJson<int>(json['numberOfSessions']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      stripeProductId: serializer.fromJson<String>(json['stripeProductId']),
      stripePriceId: serializer.fromJson<String>(json['stripePriceId']),
      trainerId: serializer.fromJson<String>(json['trainerId']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'numberOfSessions': serializer.toJson<int>(numberOfSessions),
      'isActive': serializer.toJson<bool>(isActive),
      'stripeProductId': serializer.toJson<String>(stripeProductId),
      'stripePriceId': serializer.toJson<String>(stripePriceId),
      'trainerId': serializer.toJson<String>(trainerId),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TrainerPackage copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    double? price,
    int? numberOfSessions,
    bool? isActive,
    String? stripeProductId,
    String? stripePriceId,
    String? trainerId,
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => TrainerPackage(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    price: price ?? this.price,
    numberOfSessions: numberOfSessions ?? this.numberOfSessions,
    isActive: isActive ?? this.isActive,
    stripeProductId: stripeProductId ?? this.stripeProductId,
    stripePriceId: stripePriceId ?? this.stripePriceId,
    trainerId: trainerId ?? this.trainerId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TrainerPackage copyWithCompanion(TrainerPackagesCompanion data) {
    return TrainerPackage(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      numberOfSessions: data.numberOfSessions.present
          ? data.numberOfSessions.value
          : this.numberOfSessions,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      stripeProductId: data.stripeProductId.present
          ? data.stripeProductId.value
          : this.stripeProductId,
      stripePriceId: data.stripePriceId.present
          ? data.stripePriceId.value
          : this.stripePriceId,
      trainerId: data.trainerId.present ? data.trainerId.value : this.trainerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainerPackage(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('numberOfSessions: $numberOfSessions, ')
          ..write('isActive: $isActive, ')
          ..write('stripeProductId: $stripeProductId, ')
          ..write('stripePriceId: $stripePriceId, ')
          ..write('trainerId: $trainerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    price,
    numberOfSessions,
    isActive,
    stripeProductId,
    stripePriceId,
    trainerId,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainerPackage &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.numberOfSessions == this.numberOfSessions &&
          other.isActive == this.isActive &&
          other.stripeProductId == this.stripeProductId &&
          other.stripePriceId == this.stripePriceId &&
          other.trainerId == this.trainerId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TrainerPackagesCompanion extends UpdateCompanion<TrainerPackage> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<int> numberOfSessions;
  final Value<bool> isActive;
  final Value<String> stripeProductId;
  final Value<String> stripePriceId;
  final Value<String> trainerId;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TrainerPackagesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.numberOfSessions = const Value.absent(),
    this.isActive = const Value.absent(),
    this.stripeProductId = const Value.absent(),
    this.stripePriceId = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainerPackagesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required double price,
    required int numberOfSessions,
    this.isActive = const Value.absent(),
    required String stripeProductId,
    required String stripePriceId,
    required String trainerId,
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       price = Value(price),
       numberOfSessions = Value(numberOfSessions),
       stripeProductId = Value(stripeProductId),
       stripePriceId = Value(stripePriceId),
       trainerId = Value(trainerId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrainerPackage> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<int>? numberOfSessions,
    Expression<bool>? isActive,
    Expression<String>? stripeProductId,
    Expression<String>? stripePriceId,
    Expression<String>? trainerId,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (numberOfSessions != null) 'number_of_sessions': numberOfSessions,
      if (isActive != null) 'is_active': isActive,
      if (stripeProductId != null) 'stripe_product_id': stripeProductId,
      if (stripePriceId != null) 'stripe_price_id': stripePriceId,
      if (trainerId != null) 'trainer_id': trainerId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainerPackagesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? price,
    Value<int>? numberOfSessions,
    Value<bool>? isActive,
    Value<String>? stripeProductId,
    Value<String>? stripePriceId,
    Value<String>? trainerId,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TrainerPackagesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      numberOfSessions: numberOfSessions ?? this.numberOfSessions,
      isActive: isActive ?? this.isActive,
      stripeProductId: stripeProductId ?? this.stripeProductId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      trainerId: trainerId ?? this.trainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (numberOfSessions.present) {
      map['number_of_sessions'] = Variable<int>(numberOfSessions.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (stripeProductId.present) {
      map['stripe_product_id'] = Variable<String>(stripeProductId.value);
    }
    if (stripePriceId.present) {
      map['stripe_price_id'] = Variable<String>(stripePriceId.value);
    }
    if (trainerId.present) {
      map['trainer_id'] = Variable<String>(trainerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainerPackagesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('numberOfSessions: $numberOfSessions, ')
          ..write('isActive: $isActive, ')
          ..write('stripeProductId: $stripeProductId, ')
          ..write('stripePriceId: $stripePriceId, ')
          ..write('trainerId: $trainerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainerTestimonialsTable extends TrainerTestimonials
    with TableInfo<$TrainerTestimonialsTable, TrainerTestimonial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainerTestimonialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testimonialTextMeta = const VerificationMeta(
    'testimonialText',
  );
  @override
  late final GeneratedColumn<String> testimonialText = GeneratedColumn<String>(
    'testimonial_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    clientName,
    testimonialText,
    rating,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trainer_testimonials';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainerTestimonial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('testimonial_text')) {
      context.handle(
        _testimonialTextMeta,
        testimonialText.isAcceptableOrUnknown(
          data['testimonial_text']!,
          _testimonialTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_testimonialTextMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainerTestimonial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainerTestimonial(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      )!,
      testimonialText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}testimonial_text'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TrainerTestimonialsTable createAlias(String alias) {
    return $TrainerTestimonialsTable(attachedDatabase, alias);
  }
}

class TrainerTestimonial extends DataClass
    implements Insertable<TrainerTestimonial> {
  final String id;
  final String profileId;
  final String clientName;
  final String testimonialText;
  final int? rating;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const TrainerTestimonial({
    required this.id,
    required this.profileId,
    required this.clientName,
    required this.testimonialText,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['client_name'] = Variable<String>(clientName);
    map['testimonial_text'] = Variable<String>(testimonialText);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TrainerTestimonialsCompanion toCompanion(bool nullToAbsent) {
    return TrainerTestimonialsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      clientName: Value(clientName),
      testimonialText: Value(testimonialText),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TrainerTestimonial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainerTestimonial(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      clientName: serializer.fromJson<String>(json['clientName']),
      testimonialText: serializer.fromJson<String>(json['testimonialText']),
      rating: serializer.fromJson<int?>(json['rating']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'clientName': serializer.toJson<String>(clientName),
      'testimonialText': serializer.toJson<String>(testimonialText),
      'rating': serializer.toJson<int?>(rating),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TrainerTestimonial copyWith({
    String? id,
    String? profileId,
    String? clientName,
    String? testimonialText,
    Value<int?> rating = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => TrainerTestimonial(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    clientName: clientName ?? this.clientName,
    testimonialText: testimonialText ?? this.testimonialText,
    rating: rating.present ? rating.value : this.rating,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TrainerTestimonial copyWithCompanion(TrainerTestimonialsCompanion data) {
    return TrainerTestimonial(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      testimonialText: data.testimonialText.present
          ? data.testimonialText.value
          : this.testimonialText,
      rating: data.rating.present ? data.rating.value : this.rating,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainerTestimonial(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('clientName: $clientName, ')
          ..write('testimonialText: $testimonialText, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    clientName,
    testimonialText,
    rating,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainerTestimonial &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.clientName == this.clientName &&
          other.testimonialText == this.testimonialText &&
          other.rating == this.rating &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TrainerTestimonialsCompanion extends UpdateCompanion<TrainerTestimonial> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> clientName;
  final Value<String> testimonialText;
  final Value<int?> rating;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TrainerTestimonialsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.testimonialText = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainerTestimonialsCompanion.insert({
    required String id,
    required String profileId,
    required String clientName,
    required String testimonialText,
    this.rating = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       clientName = Value(clientName),
       testimonialText = Value(testimonialText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrainerTestimonial> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? clientName,
    Expression<String>? testimonialText,
    Expression<int>? rating,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (clientName != null) 'client_name': clientName,
      if (testimonialText != null) 'testimonial_text': testimonialText,
      if (rating != null) 'rating': rating,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainerTestimonialsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? clientName,
    Value<String>? testimonialText,
    Value<int?>? rating,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TrainerTestimonialsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      clientName: clientName ?? this.clientName,
      testimonialText: testimonialText ?? this.testimonialText,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (testimonialText.present) {
      map['testimonial_text'] = Variable<String>(testimonialText.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainerTestimonialsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('clientName: $clientName, ')
          ..write('testimonialText: $testimonialText, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainerProgramsTable extends TrainerPrograms
    with TableInfo<$TrainerProgramsTable, TrainerProgram> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainerProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trainerIdMeta = const VerificationMeta(
    'trainerId',
  );
  @override
  late final GeneratedColumn<String> trainerId = GeneratedColumn<String>(
    'trainer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    trainerId,
    category,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trainer_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainerProgram> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('trainer_id')) {
      context.handle(
        _trainerIdMeta,
        trainerId.isAcceptableOrUnknown(data['trainer_id']!, _trainerIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainerProgram map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainerProgram(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      trainerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TrainerProgramsTable createAlias(String alias) {
    return $TrainerProgramsTable(attachedDatabase, alias);
  }
}

class TrainerProgram extends DataClass implements Insertable<TrainerProgram> {
  final String id;
  final String name;
  final String? description;
  final String? trainerId;
  final String? category;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const TrainerProgram({
    required this.id,
    required this.name,
    this.description,
    this.trainerId,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || trainerId != null) {
      map['trainer_id'] = Variable<String>(trainerId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TrainerProgramsCompanion toCompanion(bool nullToAbsent) {
    return TrainerProgramsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      trainerId: trainerId == null && nullToAbsent
          ? const Value.absent()
          : Value(trainerId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TrainerProgram.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainerProgram(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      trainerId: serializer.fromJson<String?>(json['trainerId']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'trainerId': serializer.toJson<String?>(trainerId),
      'category': serializer.toJson<String?>(category),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TrainerProgram copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> trainerId = const Value.absent(),
    Value<String?> category = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => TrainerProgram(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    trainerId: trainerId.present ? trainerId.value : this.trainerId,
    category: category.present ? category.value : this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TrainerProgram copyWithCompanion(TrainerProgramsCompanion data) {
    return TrainerProgram(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      trainerId: data.trainerId.present ? data.trainerId.value : this.trainerId,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainerProgram(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('trainerId: $trainerId, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    trainerId,
    category,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainerProgram &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.trainerId == this.trainerId &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TrainerProgramsCompanion extends UpdateCompanion<TrainerProgram> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> trainerId;
  final Value<String?> category;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TrainerProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainerProgramsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.category = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TrainerProgram> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? trainerId,
    Expression<String>? category,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (trainerId != null) 'trainer_id': trainerId,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainerProgramsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? trainerId,
    Value<String?>? category,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TrainerProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trainerId: trainerId ?? this.trainerId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (trainerId.present) {
      map['trainer_id'] = Variable<String>(trainerId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainerProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('trainerId: $trainerId, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<BigInt> startTime = GeneratedColumn<BigInt>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<BigInt> endTime = GeneratedColumn<BigInt>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataSharingApprovedMeta =
      const VerificationMeta('dataSharingApproved');
  @override
  late final GeneratedColumn<bool> dataSharingApproved = GeneratedColumn<bool>(
    'data_sharing_approved',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("data_sharing_approved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataSharingApprovedAtMeta =
      const VerificationMeta('dataSharingApprovedAt');
  @override
  late final GeneratedColumn<BigInt> dataSharingApprovedAt =
      GeneratedColumn<BigInt>(
        'data_sharing_approved_at',
        aliasedName,
        true,
        type: DriftSqlType.bigInt,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _trainerIdMeta = const VerificationMeta(
    'trainerId',
  );
  @override
  late final GeneratedColumn<String> trainerId = GeneratedColumn<String>(
    'trainer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientEmailMeta = const VerificationMeta(
    'clientEmail',
  );
  @override
  late final GeneratedColumn<String> clientEmail = GeneratedColumn<String>(
    'client_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNotesMeta = const VerificationMeta(
    'clientNotes',
  );
  @override
  late final GeneratedColumn<String> clientNotes = GeneratedColumn<String>(
    'client_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    endTime,
    status,
    dataSharingApproved,
    dataSharingApprovedAt,
    trainerId,
    clientId,
    clientName,
    clientEmail,
    clientNotes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('data_sharing_approved')) {
      context.handle(
        _dataSharingApprovedMeta,
        dataSharingApproved.isAcceptableOrUnknown(
          data['data_sharing_approved']!,
          _dataSharingApprovedMeta,
        ),
      );
    }
    if (data.containsKey('data_sharing_approved_at')) {
      context.handle(
        _dataSharingApprovedAtMeta,
        dataSharingApprovedAt.isAcceptableOrUnknown(
          data['data_sharing_approved_at']!,
          _dataSharingApprovedAtMeta,
        ),
      );
    }
    if (data.containsKey('trainer_id')) {
      context.handle(
        _trainerIdMeta,
        trainerId.isAcceptableOrUnknown(data['trainer_id']!, _trainerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trainerIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    }
    if (data.containsKey('client_email')) {
      context.handle(
        _clientEmailMeta,
        clientEmail.isAcceptableOrUnknown(
          data['client_email']!,
          _clientEmailMeta,
        ),
      );
    }
    if (data.containsKey('client_notes')) {
      context.handle(
        _clientNotesMeta,
        clientNotes.isAcceptableOrUnknown(
          data['client_notes']!,
          _clientNotesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}end_time'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dataSharingApproved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}data_sharing_approved'],
      ),
      dataSharingApprovedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}data_sharing_approved_at'],
      ),
      trainerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      ),
      clientEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_email'],
      ),
      clientNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEvent extends DataClass implements Insertable<CalendarEvent> {
  final String id;
  final BigInt startTime;
  final BigInt endTime;
  final String status;
  final bool? dataSharingApproved;
  final BigInt? dataSharingApprovedAt;
  final String trainerId;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? clientNotes;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const CalendarEvent({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.dataSharingApproved,
    this.dataSharingApprovedAt,
    required this.trainerId,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.clientNotes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<BigInt>(startTime);
    map['end_time'] = Variable<BigInt>(endTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dataSharingApproved != null) {
      map['data_sharing_approved'] = Variable<bool>(dataSharingApproved);
    }
    if (!nullToAbsent || dataSharingApprovedAt != null) {
      map['data_sharing_approved_at'] = Variable<BigInt>(dataSharingApprovedAt);
    }
    map['trainer_id'] = Variable<String>(trainerId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || clientEmail != null) {
      map['client_email'] = Variable<String>(clientEmail);
    }
    if (!nullToAbsent || clientNotes != null) {
      map['client_notes'] = Variable<String>(clientNotes);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: Value(endTime),
      status: Value(status),
      dataSharingApproved: dataSharingApproved == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSharingApproved),
      dataSharingApprovedAt: dataSharingApprovedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSharingApprovedAt),
      trainerId: Value(trainerId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      clientEmail: clientEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(clientEmail),
      clientNotes: clientNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(clientNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory CalendarEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEvent(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<BigInt>(json['startTime']),
      endTime: serializer.fromJson<BigInt>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      dataSharingApproved: serializer.fromJson<bool?>(
        json['dataSharingApproved'],
      ),
      dataSharingApprovedAt: serializer.fromJson<BigInt?>(
        json['dataSharingApprovedAt'],
      ),
      trainerId: serializer.fromJson<String>(json['trainerId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      clientEmail: serializer.fromJson<String?>(json['clientEmail']),
      clientNotes: serializer.fromJson<String?>(json['clientNotes']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<BigInt>(startTime),
      'endTime': serializer.toJson<BigInt>(endTime),
      'status': serializer.toJson<String>(status),
      'dataSharingApproved': serializer.toJson<bool?>(dataSharingApproved),
      'dataSharingApprovedAt': serializer.toJson<BigInt?>(
        dataSharingApprovedAt,
      ),
      'trainerId': serializer.toJson<String>(trainerId),
      'clientId': serializer.toJson<String?>(clientId),
      'clientName': serializer.toJson<String?>(clientName),
      'clientEmail': serializer.toJson<String?>(clientEmail),
      'clientNotes': serializer.toJson<String?>(clientNotes),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  CalendarEvent copyWith({
    String? id,
    BigInt? startTime,
    BigInt? endTime,
    String? status,
    Value<bool?> dataSharingApproved = const Value.absent(),
    Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
    String? trainerId,
    Value<String?> clientId = const Value.absent(),
    Value<String?> clientName = const Value.absent(),
    Value<String?> clientEmail = const Value.absent(),
    Value<String?> clientNotes = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => CalendarEvent(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    dataSharingApproved: dataSharingApproved.present
        ? dataSharingApproved.value
        : this.dataSharingApproved,
    dataSharingApprovedAt: dataSharingApprovedAt.present
        ? dataSharingApprovedAt.value
        : this.dataSharingApprovedAt,
    trainerId: trainerId ?? this.trainerId,
    clientId: clientId.present ? clientId.value : this.clientId,
    clientName: clientName.present ? clientName.value : this.clientName,
    clientEmail: clientEmail.present ? clientEmail.value : this.clientEmail,
    clientNotes: clientNotes.present ? clientNotes.value : this.clientNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CalendarEvent copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEvent(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      dataSharingApproved: data.dataSharingApproved.present
          ? data.dataSharingApproved.value
          : this.dataSharingApproved,
      dataSharingApprovedAt: data.dataSharingApprovedAt.present
          ? data.dataSharingApprovedAt.value
          : this.dataSharingApprovedAt,
      trainerId: data.trainerId.present ? data.trainerId.value : this.trainerId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      clientEmail: data.clientEmail.present
          ? data.clientEmail.value
          : this.clientEmail,
      clientNotes: data.clientNotes.present
          ? data.clientNotes.value
          : this.clientNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEvent(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('dataSharingApproved: $dataSharingApproved, ')
          ..write('dataSharingApprovedAt: $dataSharingApprovedAt, ')
          ..write('trainerId: $trainerId, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientNotes: $clientNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    endTime,
    status,
    dataSharingApproved,
    dataSharingApprovedAt,
    trainerId,
    clientId,
    clientName,
    clientEmail,
    clientNotes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEvent &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.dataSharingApproved == this.dataSharingApproved &&
          other.dataSharingApprovedAt == this.dataSharingApprovedAt &&
          other.trainerId == this.trainerId &&
          other.clientId == this.clientId &&
          other.clientName == this.clientName &&
          other.clientEmail == this.clientEmail &&
          other.clientNotes == this.clientNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEvent> {
  final Value<String> id;
  final Value<BigInt> startTime;
  final Value<BigInt> endTime;
  final Value<String> status;
  final Value<bool?> dataSharingApproved;
  final Value<BigInt?> dataSharingApprovedAt;
  final Value<String> trainerId;
  final Value<String?> clientId;
  final Value<String?> clientName;
  final Value<String?> clientEmail;
  final Value<String?> clientNotes;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.dataSharingApproved = const Value.absent(),
    this.dataSharingApprovedAt = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required BigInt startTime,
    required BigInt endTime,
    required String status,
    this.dataSharingApproved = const Value.absent(),
    this.dataSharingApprovedAt = const Value.absent(),
    required String trainerId,
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientNotes = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTime = Value(startTime),
       endTime = Value(endTime),
       status = Value(status),
       trainerId = Value(trainerId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarEvent> custom({
    Expression<String>? id,
    Expression<BigInt>? startTime,
    Expression<BigInt>? endTime,
    Expression<String>? status,
    Expression<bool>? dataSharingApproved,
    Expression<BigInt>? dataSharingApprovedAt,
    Expression<String>? trainerId,
    Expression<String>? clientId,
    Expression<String>? clientName,
    Expression<String>? clientEmail,
    Expression<String>? clientNotes,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (dataSharingApproved != null)
        'data_sharing_approved': dataSharingApproved,
      if (dataSharingApprovedAt != null)
        'data_sharing_approved_at': dataSharingApprovedAt,
      if (trainerId != null) 'trainer_id': trainerId,
      if (clientId != null) 'client_id': clientId,
      if (clientName != null) 'client_name': clientName,
      if (clientEmail != null) 'client_email': clientEmail,
      if (clientNotes != null) 'client_notes': clientNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<BigInt>? startTime,
    Value<BigInt>? endTime,
    Value<String>? status,
    Value<bool?>? dataSharingApproved,
    Value<BigInt?>? dataSharingApprovedAt,
    Value<String>? trainerId,
    Value<String?>? clientId,
    Value<String?>? clientName,
    Value<String?>? clientEmail,
    Value<String?>? clientNotes,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      dataSharingApproved: dataSharingApproved ?? this.dataSharingApproved,
      dataSharingApprovedAt:
          dataSharingApprovedAt ?? this.dataSharingApprovedAt,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientNotes: clientNotes ?? this.clientNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<BigInt>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<BigInt>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dataSharingApproved.present) {
      map['data_sharing_approved'] = Variable<bool>(dataSharingApproved.value);
    }
    if (dataSharingApprovedAt.present) {
      map['data_sharing_approved_at'] = Variable<BigInt>(
        dataSharingApprovedAt.value,
      );
    }
    if (trainerId.present) {
      map['trainer_id'] = Variable<String>(trainerId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientEmail.present) {
      map['client_email'] = Variable<String>(clientEmail.value);
    }
    if (clientNotes.present) {
      map['client_notes'] = Variable<String>(clientNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('dataSharingApproved: $dataSharingApproved, ')
          ..write('dataSharingApprovedAt: $dataSharingApprovedAt, ')
          ..write('trainerId: $trainerId, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientNotes: $clientNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, Notification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readStatusMeta = const VerificationMeta(
    'readStatus',
  );
  @override
  late final GeneratedColumn<bool> readStatus = GeneratedColumn<bool>(
    'read_status',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read_status" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    message,
    type,
    readStatus,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Notification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('read_status')) {
      context.handle(
        _readStatusMeta,
        readStatus.isAcceptableOrUnknown(data['read_status']!, _readStatusMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      readStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read_status'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class Notification extends DataClass implements Insertable<Notification> {
  final String id;
  final String userId;
  final String message;
  final String type;
  final bool readStatus;
  final String? metadata;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.readStatus,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['message'] = Variable<String>(message);
    map['type'] = Variable<String>(type);
    map['read_status'] = Variable<bool>(readStatus);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      message: Value(message),
      type: Value(type),
      readStatus: Value(readStatus),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory Notification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notification(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      message: serializer.fromJson<String>(json['message']),
      type: serializer.fromJson<String>(json['type']),
      readStatus: serializer.fromJson<bool>(json['readStatus']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'message': serializer.toJson<String>(message),
      'type': serializer.toJson<String>(type),
      'readStatus': serializer.toJson<bool>(readStatus),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? message,
    String? type,
    bool? readStatus,
    Value<String?> metadata = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => Notification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    message: message ?? this.message,
    type: type ?? this.type,
    readStatus: readStatus ?? this.readStatus,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Notification copyWithCompanion(NotificationsCompanion data) {
    return Notification(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      message: data.message.present ? data.message.value : this.message,
      type: data.type.present ? data.type.value : this.type,
      readStatus: data.readStatus.present
          ? data.readStatus.value
          : this.readStatus,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('readStatus: $readStatus, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    message,
    type,
    readStatus,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.message == this.message &&
          other.type == this.type &&
          other.readStatus == this.readStatus &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class NotificationsCompanion extends UpdateCompanion<Notification> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> message;
  final Value<String> type;
  final Value<bool> readStatus;
  final Value<String?> metadata;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.message = const Value.absent(),
    this.type = const Value.absent(),
    this.readStatus = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String userId,
    required String message,
    required String type,
    this.readStatus = const Value.absent(),
    this.metadata = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       message = Value(message),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Notification> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? message,
    Expression<String>? type,
    Expression<bool>? readStatus,
    Expression<String>? metadata,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
      if (readStatus != null) 'read_status': readStatus,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? message,
    Value<String>? type,
    Value<bool>? readStatus,
    Value<String?>? metadata,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      readStatus: readStatus ?? this.readStatus,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (readStatus.present) {
      map['read_status'] = Variable<bool>(readStatus.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('readStatus: $readStatus, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookingsTable extends Bookings with TableInfo<$BookingsTable, Booking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<BigInt> startTime = GeneratedColumn<BigInt>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<BigInt> endTime = GeneratedColumn<BigInt>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataSharingApprovedMeta =
      const VerificationMeta('dataSharingApproved');
  @override
  late final GeneratedColumn<bool> dataSharingApproved = GeneratedColumn<bool>(
    'data_sharing_approved',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("data_sharing_approved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataSharingApprovedAtMeta =
      const VerificationMeta('dataSharingApprovedAt');
  @override
  late final GeneratedColumn<BigInt> dataSharingApprovedAt =
      GeneratedColumn<BigInt>(
        'data_sharing_approved_at',
        aliasedName,
        true,
        type: DriftSqlType.bigInt,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _trainerIdMeta = const VerificationMeta(
    'trainerId',
  );
  @override
  late final GeneratedColumn<String> trainerId = GeneratedColumn<String>(
    'trainer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientEmailMeta = const VerificationMeta(
    'clientEmail',
  );
  @override
  late final GeneratedColumn<String> clientEmail = GeneratedColumn<String>(
    'client_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNotesMeta = const VerificationMeta(
    'clientNotes',
  );
  @override
  late final GeneratedColumn<String> clientNotes = GeneratedColumn<String>(
    'client_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<BigInt> deletedAt = GeneratedColumn<BigInt>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    endTime,
    status,
    dataSharingApproved,
    dataSharingApprovedAt,
    trainerId,
    clientId,
    clientName,
    clientEmail,
    clientNotes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Booking> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('data_sharing_approved')) {
      context.handle(
        _dataSharingApprovedMeta,
        dataSharingApproved.isAcceptableOrUnknown(
          data['data_sharing_approved']!,
          _dataSharingApprovedMeta,
        ),
      );
    }
    if (data.containsKey('data_sharing_approved_at')) {
      context.handle(
        _dataSharingApprovedAtMeta,
        dataSharingApprovedAt.isAcceptableOrUnknown(
          data['data_sharing_approved_at']!,
          _dataSharingApprovedAtMeta,
        ),
      );
    }
    if (data.containsKey('trainer_id')) {
      context.handle(
        _trainerIdMeta,
        trainerId.isAcceptableOrUnknown(data['trainer_id']!, _trainerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trainerIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    }
    if (data.containsKey('client_email')) {
      context.handle(
        _clientEmailMeta,
        clientEmail.isAcceptableOrUnknown(
          data['client_email']!,
          _clientEmailMeta,
        ),
      );
    }
    if (data.containsKey('client_notes')) {
      context.handle(
        _clientNotesMeta,
        clientNotes.isAcceptableOrUnknown(
          data['client_notes']!,
          _clientNotesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Booking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Booking(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}end_time'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dataSharingApproved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}data_sharing_approved'],
      ),
      dataSharingApprovedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}data_sharing_approved_at'],
      ),
      trainerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      ),
      clientEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_email'],
      ),
      clientNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $BookingsTable createAlias(String alias) {
    return $BookingsTable(attachedDatabase, alias);
  }
}

class Booking extends DataClass implements Insertable<Booking> {
  final String id;
  final BigInt startTime;
  final BigInt endTime;
  final String status;
  final bool? dataSharingApproved;
  final BigInt? dataSharingApprovedAt;
  final String trainerId;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? clientNotes;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? deletedAt;
  final int syncStatus;
  const Booking({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.dataSharingApproved,
    this.dataSharingApprovedAt,
    required this.trainerId,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.clientNotes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<BigInt>(startTime);
    map['end_time'] = Variable<BigInt>(endTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dataSharingApproved != null) {
      map['data_sharing_approved'] = Variable<bool>(dataSharingApproved);
    }
    if (!nullToAbsent || dataSharingApprovedAt != null) {
      map['data_sharing_approved_at'] = Variable<BigInt>(dataSharingApprovedAt);
    }
    map['trainer_id'] = Variable<String>(trainerId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || clientEmail != null) {
      map['client_email'] = Variable<String>(clientEmail);
    }
    if (!nullToAbsent || clientNotes != null) {
      map['client_notes'] = Variable<String>(clientNotes);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<BigInt>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  BookingsCompanion toCompanion(bool nullToAbsent) {
    return BookingsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: Value(endTime),
      status: Value(status),
      dataSharingApproved: dataSharingApproved == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSharingApproved),
      dataSharingApprovedAt: dataSharingApprovedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSharingApprovedAt),
      trainerId: Value(trainerId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      clientEmail: clientEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(clientEmail),
      clientNotes: clientNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(clientNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory Booking.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Booking(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<BigInt>(json['startTime']),
      endTime: serializer.fromJson<BigInt>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      dataSharingApproved: serializer.fromJson<bool?>(
        json['dataSharingApproved'],
      ),
      dataSharingApprovedAt: serializer.fromJson<BigInt?>(
        json['dataSharingApprovedAt'],
      ),
      trainerId: serializer.fromJson<String>(json['trainerId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      clientEmail: serializer.fromJson<String?>(json['clientEmail']),
      clientNotes: serializer.fromJson<String?>(json['clientNotes']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
      deletedAt: serializer.fromJson<BigInt?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<BigInt>(startTime),
      'endTime': serializer.toJson<BigInt>(endTime),
      'status': serializer.toJson<String>(status),
      'dataSharingApproved': serializer.toJson<bool?>(dataSharingApproved),
      'dataSharingApprovedAt': serializer.toJson<BigInt?>(
        dataSharingApprovedAt,
      ),
      'trainerId': serializer.toJson<String>(trainerId),
      'clientId': serializer.toJson<String?>(clientId),
      'clientName': serializer.toJson<String?>(clientName),
      'clientEmail': serializer.toJson<String?>(clientEmail),
      'clientNotes': serializer.toJson<String?>(clientNotes),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
      'deletedAt': serializer.toJson<BigInt?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Booking copyWith({
    String? id,
    BigInt? startTime,
    BigInt? endTime,
    String? status,
    Value<bool?> dataSharingApproved = const Value.absent(),
    Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
    String? trainerId,
    Value<String?> clientId = const Value.absent(),
    Value<String?> clientName = const Value.absent(),
    Value<String?> clientEmail = const Value.absent(),
    Value<String?> clientNotes = const Value.absent(),
    BigInt? createdAt,
    BigInt? updatedAt,
    Value<BigInt?> deletedAt = const Value.absent(),
    int? syncStatus,
  }) => Booking(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    dataSharingApproved: dataSharingApproved.present
        ? dataSharingApproved.value
        : this.dataSharingApproved,
    dataSharingApprovedAt: dataSharingApprovedAt.present
        ? dataSharingApprovedAt.value
        : this.dataSharingApprovedAt,
    trainerId: trainerId ?? this.trainerId,
    clientId: clientId.present ? clientId.value : this.clientId,
    clientName: clientName.present ? clientName.value : this.clientName,
    clientEmail: clientEmail.present ? clientEmail.value : this.clientEmail,
    clientNotes: clientNotes.present ? clientNotes.value : this.clientNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Booking copyWithCompanion(BookingsCompanion data) {
    return Booking(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      dataSharingApproved: data.dataSharingApproved.present
          ? data.dataSharingApproved.value
          : this.dataSharingApproved,
      dataSharingApprovedAt: data.dataSharingApprovedAt.present
          ? data.dataSharingApprovedAt.value
          : this.dataSharingApprovedAt,
      trainerId: data.trainerId.present ? data.trainerId.value : this.trainerId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      clientEmail: data.clientEmail.present
          ? data.clientEmail.value
          : this.clientEmail,
      clientNotes: data.clientNotes.present
          ? data.clientNotes.value
          : this.clientNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Booking(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('dataSharingApproved: $dataSharingApproved, ')
          ..write('dataSharingApprovedAt: $dataSharingApprovedAt, ')
          ..write('trainerId: $trainerId, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientNotes: $clientNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    endTime,
    status,
    dataSharingApproved,
    dataSharingApprovedAt,
    trainerId,
    clientId,
    clientName,
    clientEmail,
    clientNotes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Booking &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.dataSharingApproved == this.dataSharingApproved &&
          other.dataSharingApprovedAt == this.dataSharingApprovedAt &&
          other.trainerId == this.trainerId &&
          other.clientId == this.clientId &&
          other.clientName == this.clientName &&
          other.clientEmail == this.clientEmail &&
          other.clientNotes == this.clientNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class BookingsCompanion extends UpdateCompanion<Booking> {
  final Value<String> id;
  final Value<BigInt> startTime;
  final Value<BigInt> endTime;
  final Value<String> status;
  final Value<bool?> dataSharingApproved;
  final Value<BigInt?> dataSharingApprovedAt;
  final Value<String> trainerId;
  final Value<String?> clientId;
  final Value<String?> clientName;
  final Value<String?> clientEmail;
  final Value<String?> clientNotes;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<BigInt?> deletedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const BookingsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.dataSharingApproved = const Value.absent(),
    this.dataSharingApprovedAt = const Value.absent(),
    this.trainerId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookingsCompanion.insert({
    required String id,
    required BigInt startTime,
    required BigInt endTime,
    required String status,
    this.dataSharingApproved = const Value.absent(),
    this.dataSharingApprovedAt = const Value.absent(),
    required String trainerId,
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientNotes = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTime = Value(startTime),
       endTime = Value(endTime),
       status = Value(status),
       trainerId = Value(trainerId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Booking> custom({
    Expression<String>? id,
    Expression<BigInt>? startTime,
    Expression<BigInt>? endTime,
    Expression<String>? status,
    Expression<bool>? dataSharingApproved,
    Expression<BigInt>? dataSharingApprovedAt,
    Expression<String>? trainerId,
    Expression<String>? clientId,
    Expression<String>? clientName,
    Expression<String>? clientEmail,
    Expression<String>? clientNotes,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<BigInt>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (dataSharingApproved != null)
        'data_sharing_approved': dataSharingApproved,
      if (dataSharingApprovedAt != null)
        'data_sharing_approved_at': dataSharingApprovedAt,
      if (trainerId != null) 'trainer_id': trainerId,
      if (clientId != null) 'client_id': clientId,
      if (clientName != null) 'client_name': clientName,
      if (clientEmail != null) 'client_email': clientEmail,
      if (clientNotes != null) 'client_notes': clientNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookingsCompanion copyWith({
    Value<String>? id,
    Value<BigInt>? startTime,
    Value<BigInt>? endTime,
    Value<String>? status,
    Value<bool?>? dataSharingApproved,
    Value<BigInt?>? dataSharingApprovedAt,
    Value<String>? trainerId,
    Value<String?>? clientId,
    Value<String?>? clientName,
    Value<String?>? clientEmail,
    Value<String?>? clientNotes,
    Value<BigInt>? createdAt,
    Value<BigInt>? updatedAt,
    Value<BigInt?>? deletedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return BookingsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      dataSharingApproved: dataSharingApproved ?? this.dataSharingApproved,
      dataSharingApprovedAt:
          dataSharingApprovedAt ?? this.dataSharingApprovedAt,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientNotes: clientNotes ?? this.clientNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<BigInt>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<BigInt>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dataSharingApproved.present) {
      map['data_sharing_approved'] = Variable<bool>(dataSharingApproved.value);
    }
    if (dataSharingApprovedAt.present) {
      map['data_sharing_approved_at'] = Variable<BigInt>(
        dataSharingApprovedAt.value,
      );
    }
    if (trainerId.present) {
      map['trainer_id'] = Variable<String>(trainerId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientEmail.present) {
      map['client_email'] = Variable<String>(clientEmail.value);
    }
    if (clientNotes.present) {
      map['client_notes'] = Variable<String>(clientNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<BigInt>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('dataSharingApproved: $dataSharingApproved, ')
          ..write('dataSharingApprovedAt: $dataSharingApprovedAt, ')
          ..write('trainerId: $trainerId, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientNotes: $clientNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $ClientsTable clients = $ClientsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $TrainerProfilesTable trainerProfiles = $TrainerProfilesTable(
    this,
  );
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $ClientAssessmentsTable clientAssessments =
      $ClientAssessmentsTable(this);
  late final $ClientMeasurementsTable clientMeasurements =
      $ClientMeasurementsTable(this);
  late final $ClientPhotosTable clientPhotos = $ClientPhotosTable(this);
  late final $ClientExerciseLogsTable clientExerciseLogs =
      $ClientExerciseLogsTable(this);
  late final $TrainerServicesTable trainerServices = $TrainerServicesTable(
    this,
  );
  late final $TrainerPackagesTable trainerPackages = $TrainerPackagesTable(
    this,
  );
  late final $TrainerTestimonialsTable trainerTestimonials =
      $TrainerTestimonialsTable(this);
  late final $TrainerProgramsTable trainerPrograms = $TrainerProgramsTable(
    this,
  );
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $BookingsTable bookings = $BookingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    syncQueueItems,
    clients,
    profiles,
    trainerProfiles,
    workoutSessions,
    exercises,
    workoutTemplates,
    clientAssessments,
    clientMeasurements,
    clientPhotos,
    clientExerciseLogs,
    trainerServices,
    trainerPackages,
    trainerTestimonials,
    trainerPrograms,
    calendarEvents,
    notifications,
    bookings,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String name,
      required String email,
      Value<String?> username,
      required String role,
      Value<BigInt?> emailVerifiedAt,
      Value<int> defaultCheckInDay,
      Value<int> defaultCheckInHour,
      Value<String> tier,
      Value<String?> subscriptionStatus,
      Value<BigInt?> trialEndsAt,
      Value<bool> hasCompletedOnboarding,
      Value<String?> stripeCustomerId,
      Value<String?> stripeSubscriptionId,
      Value<String?> stripeSubscriptionStatus,
      Value<String?> stripeConnectAccountId,
      Value<String> weightUnit,
      Value<String> pushTokens,
      Value<bool> stripeCancelAtPeriodEnd,
      Value<BigInt?> stripeCurrentPeriodEnd,
      Value<BigInt?> stripeCancelAt,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> email,
      Value<String?> username,
      Value<String> role,
      Value<BigInt?> emailVerifiedAt,
      Value<int> defaultCheckInDay,
      Value<int> defaultCheckInHour,
      Value<String> tier,
      Value<String?> subscriptionStatus,
      Value<BigInt?> trialEndsAt,
      Value<bool> hasCompletedOnboarding,
      Value<String?> stripeCustomerId,
      Value<String?> stripeSubscriptionId,
      Value<String?> stripeSubscriptionStatus,
      Value<String?> stripeConnectAccountId,
      Value<String> weightUnit,
      Value<String> pushTokens,
      Value<bool> stripeCancelAtPeriodEnd,
      Value<BigInt?> stripeCurrentPeriodEnd,
      Value<BigInt?> stripeCancelAt,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get emailVerifiedAt => $composableBuilder(
    column: $table.emailVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultCheckInDay => $composableBuilder(
    column: $table.defaultCheckInDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultCheckInHour => $composableBuilder(
    column: $table.defaultCheckInHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get trialEndsAt => $composableBuilder(
    column: $table.trialEndsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripeCustomerId => $composableBuilder(
    column: $table.stripeCustomerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripeSubscriptionId => $composableBuilder(
    column: $table.stripeSubscriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripeSubscriptionStatus => $composableBuilder(
    column: $table.stripeSubscriptionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripeConnectAccountId => $composableBuilder(
    column: $table.stripeConnectAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pushTokens => $composableBuilder(
    column: $table.pushTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stripeCancelAtPeriodEnd => $composableBuilder(
    column: $table.stripeCancelAtPeriodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get stripeCurrentPeriodEnd => $composableBuilder(
    column: $table.stripeCurrentPeriodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get stripeCancelAt => $composableBuilder(
    column: $table.stripeCancelAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get emailVerifiedAt => $composableBuilder(
    column: $table.emailVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultCheckInDay => $composableBuilder(
    column: $table.defaultCheckInDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultCheckInHour => $composableBuilder(
    column: $table.defaultCheckInHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get trialEndsAt => $composableBuilder(
    column: $table.trialEndsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripeCustomerId => $composableBuilder(
    column: $table.stripeCustomerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripeSubscriptionId => $composableBuilder(
    column: $table.stripeSubscriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripeSubscriptionStatus => $composableBuilder(
    column: $table.stripeSubscriptionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripeConnectAccountId => $composableBuilder(
    column: $table.stripeConnectAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pushTokens => $composableBuilder(
    column: $table.pushTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stripeCancelAtPeriodEnd => $composableBuilder(
    column: $table.stripeCancelAtPeriodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get stripeCurrentPeriodEnd => $composableBuilder(
    column: $table.stripeCurrentPeriodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get stripeCancelAt => $composableBuilder(
    column: $table.stripeCancelAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<BigInt> get emailVerifiedAt => $composableBuilder(
    column: $table.emailVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultCheckInDay => $composableBuilder(
    column: $table.defaultCheckInDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultCheckInHour => $composableBuilder(
    column: $table.defaultCheckInHour,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get trialEndsAt => $composableBuilder(
    column: $table.trialEndsAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stripeCustomerId => $composableBuilder(
    column: $table.stripeCustomerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stripeSubscriptionId => $composableBuilder(
    column: $table.stripeSubscriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stripeSubscriptionStatus => $composableBuilder(
    column: $table.stripeSubscriptionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stripeConnectAccountId => $composableBuilder(
    column: $table.stripeConnectAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pushTokens => $composableBuilder(
    column: $table.pushTokens,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get stripeCancelAtPeriodEnd => $composableBuilder(
    column: $table.stripeCancelAtPeriodEnd,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get stripeCurrentPeriodEnd => $composableBuilder(
    column: $table.stripeCurrentPeriodEnd,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get stripeCancelAt => $composableBuilder(
    column: $table.stripeCancelAt,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<BigInt?> emailVerifiedAt = const Value.absent(),
                Value<int> defaultCheckInDay = const Value.absent(),
                Value<int> defaultCheckInHour = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<String?> subscriptionStatus = const Value.absent(),
                Value<BigInt?> trialEndsAt = const Value.absent(),
                Value<bool> hasCompletedOnboarding = const Value.absent(),
                Value<String?> stripeCustomerId = const Value.absent(),
                Value<String?> stripeSubscriptionId = const Value.absent(),
                Value<String?> stripeSubscriptionStatus = const Value.absent(),
                Value<String?> stripeConnectAccountId = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<String> pushTokens = const Value.absent(),
                Value<bool> stripeCancelAtPeriodEnd = const Value.absent(),
                Value<BigInt?> stripeCurrentPeriodEnd = const Value.absent(),
                Value<BigInt?> stripeCancelAt = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                username: username,
                role: role,
                emailVerifiedAt: emailVerifiedAt,
                defaultCheckInDay: defaultCheckInDay,
                defaultCheckInHour: defaultCheckInHour,
                tier: tier,
                subscriptionStatus: subscriptionStatus,
                trialEndsAt: trialEndsAt,
                hasCompletedOnboarding: hasCompletedOnboarding,
                stripeCustomerId: stripeCustomerId,
                stripeSubscriptionId: stripeSubscriptionId,
                stripeSubscriptionStatus: stripeSubscriptionStatus,
                stripeConnectAccountId: stripeConnectAccountId,
                weightUnit: weightUnit,
                pushTokens: pushTokens,
                stripeCancelAtPeriodEnd: stripeCancelAtPeriodEnd,
                stripeCurrentPeriodEnd: stripeCurrentPeriodEnd,
                stripeCancelAt: stripeCancelAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String email,
                Value<String?> username = const Value.absent(),
                required String role,
                Value<BigInt?> emailVerifiedAt = const Value.absent(),
                Value<int> defaultCheckInDay = const Value.absent(),
                Value<int> defaultCheckInHour = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<String?> subscriptionStatus = const Value.absent(),
                Value<BigInt?> trialEndsAt = const Value.absent(),
                Value<bool> hasCompletedOnboarding = const Value.absent(),
                Value<String?> stripeCustomerId = const Value.absent(),
                Value<String?> stripeSubscriptionId = const Value.absent(),
                Value<String?> stripeSubscriptionStatus = const Value.absent(),
                Value<String?> stripeConnectAccountId = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<String> pushTokens = const Value.absent(),
                Value<bool> stripeCancelAtPeriodEnd = const Value.absent(),
                Value<BigInt?> stripeCurrentPeriodEnd = const Value.absent(),
                Value<BigInt?> stripeCancelAt = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                username: username,
                role: role,
                emailVerifiedAt: emailVerifiedAt,
                defaultCheckInDay: defaultCheckInDay,
                defaultCheckInHour: defaultCheckInHour,
                tier: tier,
                subscriptionStatus: subscriptionStatus,
                trialEndsAt: trialEndsAt,
                hasCompletedOnboarding: hasCompletedOnboarding,
                stripeCustomerId: stripeCustomerId,
                stripeSubscriptionId: stripeSubscriptionId,
                stripeSubscriptionStatus: stripeSubscriptionStatus,
                stripeConnectAccountId: stripeConnectAccountId,
                weightUnit: weightUnit,
                pushTokens: pushTokens,
                stripeCancelAtPeriodEnd: stripeCancelAtPeriodEnd,
                stripeCurrentPeriodEnd: stripeCurrentPeriodEnd,
                stripeCancelAt: stripeCancelAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      required String id,
      required String targetTable,
      required String recordId,
      required String operation,
      required String data,
      required BigInt createdAt,
      Value<int> retryCount,
      Value<String?> error,
      Value<int> rowid,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<String> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<String> operation,
      Value<String> data,
      Value<BigInt> createdAt,
      Value<int> retryCount,
      Value<String?> error,
      Value<int> rowid,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                data: data,
                createdAt: createdAt,
                retryCount: retryCount,
                error: error,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetTable,
                required String recordId,
                required String operation,
                required String data,
                required BigInt createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                data: data,
                createdAt: createdAt,
                retryCount: retryCount,
                error: error,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;
typedef $$ClientsTableCreateCompanionBuilder =
    ClientsCompanion Function({
      required String id,
      Value<String?> trainerId,
      Value<String?> userId,
      required String name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> avatarPath,
      required String status,
      Value<BigInt?> dateOfBirth,
      Value<String?> goals,
      Value<String?> healthNotes,
      Value<String?> emergencyContactName,
      Value<String?> emergencyContactPhone,
      Value<int?> checkInDay,
      Value<int?> checkInHour,
      Value<BigInt?> dataSharingExpiresAt,
      Value<String?> sharingSettings,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ClientsTableUpdateCompanionBuilder =
    ClientsCompanion Function({
      Value<String> id,
      Value<String?> trainerId,
      Value<String?> userId,
      Value<String> name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> avatarPath,
      Value<String> status,
      Value<BigInt?> dateOfBirth,
      Value<String?> goals,
      Value<String?> healthNotes,
      Value<String?> emergencyContactName,
      Value<String?> emergencyContactPhone,
      Value<int?> checkInDay,
      Value<int?> checkInHour,
      Value<BigInt?> dataSharingExpiresAt,
      Value<String?> sharingSettings,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ClientsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyContactName => $composableBuilder(
    column: $table.emergencyContactName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyContactPhone => $composableBuilder(
    column: $table.emergencyContactPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkInDay => $composableBuilder(
    column: $table.checkInDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkInHour => $composableBuilder(
    column: $table.checkInHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get dataSharingExpiresAt => $composableBuilder(
    column: $table.dataSharingExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharingSettings => $composableBuilder(
    column: $table.sharingSettings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyContactName => $composableBuilder(
    column: $table.emergencyContactName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyContactPhone => $composableBuilder(
    column: $table.emergencyContactPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkInDay => $composableBuilder(
    column: $table.checkInDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkInHour => $composableBuilder(
    column: $table.checkInHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get dataSharingExpiresAt => $composableBuilder(
    column: $table.dataSharingExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharingSettings => $composableBuilder(
    column: $table.sharingSettings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trainerId =>
      $composableBuilder(column: $table.trainerId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<BigInt> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goals =>
      $composableBuilder(column: $table.goals, builder: (column) => column);

  GeneratedColumn<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyContactName => $composableBuilder(
    column: $table.emergencyContactName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyContactPhone => $composableBuilder(
    column: $table.emergencyContactPhone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get checkInDay => $composableBuilder(
    column: $table.checkInDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get checkInHour => $composableBuilder(
    column: $table.checkInHour,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get dataSharingExpiresAt => $composableBuilder(
    column: $table.dataSharingExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharingSettings => $composableBuilder(
    column: $table.sharingSettings,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ClientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTable,
          Client,
          $$ClientsTableFilterComposer,
          $$ClientsTableOrderingComposer,
          $$ClientsTableAnnotationComposer,
          $$ClientsTableCreateCompanionBuilder,
          $$ClientsTableUpdateCompanionBuilder,
          (Client, BaseReferences<_$AppDatabase, $ClientsTable, Client>),
          Client,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableManager(_$AppDatabase db, $ClientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> trainerId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<BigInt?> dateOfBirth = const Value.absent(),
                Value<String?> goals = const Value.absent(),
                Value<String?> healthNotes = const Value.absent(),
                Value<String?> emergencyContactName = const Value.absent(),
                Value<String?> emergencyContactPhone = const Value.absent(),
                Value<int?> checkInDay = const Value.absent(),
                Value<int?> checkInHour = const Value.absent(),
                Value<BigInt?> dataSharingExpiresAt = const Value.absent(),
                Value<String?> sharingSettings = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion(
                id: id,
                trainerId: trainerId,
                userId: userId,
                name: name,
                email: email,
                phone: phone,
                avatarPath: avatarPath,
                status: status,
                dateOfBirth: dateOfBirth,
                goals: goals,
                healthNotes: healthNotes,
                emergencyContactName: emergencyContactName,
                emergencyContactPhone: emergencyContactPhone,
                checkInDay: checkInDay,
                checkInHour: checkInHour,
                dataSharingExpiresAt: dataSharingExpiresAt,
                sharingSettings: sharingSettings,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> trainerId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String name,
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                required String status,
                Value<BigInt?> dateOfBirth = const Value.absent(),
                Value<String?> goals = const Value.absent(),
                Value<String?> healthNotes = const Value.absent(),
                Value<String?> emergencyContactName = const Value.absent(),
                Value<String?> emergencyContactPhone = const Value.absent(),
                Value<int?> checkInDay = const Value.absent(),
                Value<int?> checkInHour = const Value.absent(),
                Value<BigInt?> dataSharingExpiresAt = const Value.absent(),
                Value<String?> sharingSettings = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion.insert(
                id: id,
                trainerId: trainerId,
                userId: userId,
                name: name,
                email: email,
                phone: phone,
                avatarPath: avatarPath,
                status: status,
                dateOfBirth: dateOfBirth,
                goals: goals,
                healthNotes: healthNotes,
                emergencyContactName: emergencyContactName,
                emergencyContactPhone: emergencyContactPhone,
                checkInDay: checkInDay,
                checkInHour: checkInHour,
                dataSharingExpiresAt: dataSharingExpiresAt,
                sharingSettings: sharingSettings,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTable,
      Client,
      $$ClientsTableFilterComposer,
      $$ClientsTableOrderingComposer,
      $$ClientsTableAnnotationComposer,
      $$ClientsTableCreateCompanionBuilder,
      $$ClientsTableUpdateCompanionBuilder,
      (Client, BaseReferences<_$AppDatabase, $ClientsTable, Client>),
      Client,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String userId,
      Value<String?> certifications,
      Value<String?> phone,
      Value<String?> aboutMe,
      Value<String?> philosophy,
      Value<String?> methodology,
      Value<String?> branding,
      Value<String?> bannerImagePath,
      Value<String?> customDomain,
      Value<bool> domainVerified,
      Value<String?> profilePhotoPath,
      Value<String> specialties,
      Value<String> trainingTypes,
      Value<String> businessCurrency,
      Value<double?> averageRating,
      Value<int> completionPercentage,
      Value<String?> missingFields,
      Value<bool> isVerified,
      Value<String?> availability,
      Value<double?> minServicePrice,
      Value<String?> location,
      Value<String?> locationNormalized,
      Value<double?> latitude,
      Value<double?> longitude,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> certifications,
      Value<String?> phone,
      Value<String?> aboutMe,
      Value<String?> philosophy,
      Value<String?> methodology,
      Value<String?> branding,
      Value<String?> bannerImagePath,
      Value<String?> customDomain,
      Value<bool> domainVerified,
      Value<String?> profilePhotoPath,
      Value<String> specialties,
      Value<String> trainingTypes,
      Value<String> businessCurrency,
      Value<double?> averageRating,
      Value<int> completionPercentage,
      Value<String?> missingFields,
      Value<bool> isVerified,
      Value<String?> availability,
      Value<double?> minServicePrice,
      Value<String?> location,
      Value<String?> locationNormalized,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aboutMe => $composableBuilder(
    column: $table.aboutMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branding => $composableBuilder(
    column: $table.branding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aboutMe => $composableBuilder(
    column: $table.aboutMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branding => $composableBuilder(
    column: $table.branding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get aboutMe =>
      $composableBuilder(column: $table.aboutMe, builder: (column) => column);

  GeneratedColumn<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branding =>
      $composableBuilder(column: $table.branding, builder: (column) => column);

  GeneratedColumn<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> aboutMe = const Value.absent(),
                Value<String?> philosophy = const Value.absent(),
                Value<String?> methodology = const Value.absent(),
                Value<String?> branding = const Value.absent(),
                Value<String?> bannerImagePath = const Value.absent(),
                Value<String?> customDomain = const Value.absent(),
                Value<bool> domainVerified = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String> specialties = const Value.absent(),
                Value<String> trainingTypes = const Value.absent(),
                Value<String> businessCurrency = const Value.absent(),
                Value<double?> averageRating = const Value.absent(),
                Value<int> completionPercentage = const Value.absent(),
                Value<String?> missingFields = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<double?> minServicePrice = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> locationNormalized = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                userId: userId,
                certifications: certifications,
                phone: phone,
                aboutMe: aboutMe,
                philosophy: philosophy,
                methodology: methodology,
                branding: branding,
                bannerImagePath: bannerImagePath,
                customDomain: customDomain,
                domainVerified: domainVerified,
                profilePhotoPath: profilePhotoPath,
                specialties: specialties,
                trainingTypes: trainingTypes,
                businessCurrency: businessCurrency,
                averageRating: averageRating,
                completionPercentage: completionPercentage,
                missingFields: missingFields,
                isVerified: isVerified,
                availability: availability,
                minServicePrice: minServicePrice,
                location: location,
                locationNormalized: locationNormalized,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> certifications = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> aboutMe = const Value.absent(),
                Value<String?> philosophy = const Value.absent(),
                Value<String?> methodology = const Value.absent(),
                Value<String?> branding = const Value.absent(),
                Value<String?> bannerImagePath = const Value.absent(),
                Value<String?> customDomain = const Value.absent(),
                Value<bool> domainVerified = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String> specialties = const Value.absent(),
                Value<String> trainingTypes = const Value.absent(),
                Value<String> businessCurrency = const Value.absent(),
                Value<double?> averageRating = const Value.absent(),
                Value<int> completionPercentage = const Value.absent(),
                Value<String?> missingFields = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<double?> minServicePrice = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> locationNormalized = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                userId: userId,
                certifications: certifications,
                phone: phone,
                aboutMe: aboutMe,
                philosophy: philosophy,
                methodology: methodology,
                branding: branding,
                bannerImagePath: bannerImagePath,
                customDomain: customDomain,
                domainVerified: domainVerified,
                profilePhotoPath: profilePhotoPath,
                specialties: specialties,
                trainingTypes: trainingTypes,
                businessCurrency: businessCurrency,
                averageRating: averageRating,
                completionPercentage: completionPercentage,
                missingFields: missingFields,
                isVerified: isVerified,
                availability: availability,
                minServicePrice: minServicePrice,
                location: location,
                locationNormalized: locationNormalized,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$TrainerProfilesTableCreateCompanionBuilder =
    TrainerProfilesCompanion Function({
      required String id,
      required String userId,
      Value<String?> certifications,
      Value<String?> phone,
      Value<String?> aboutMe,
      Value<String?> philosophy,
      Value<String?> methodology,
      Value<String?> branding,
      Value<String?> bannerImagePath,
      Value<String?> customDomain,
      Value<bool> domainVerified,
      Value<String?> profilePhotoPath,
      Value<String> specialties,
      Value<String> trainingTypes,
      Value<String> businessCurrency,
      Value<double?> averageRating,
      Value<int> completionPercentage,
      Value<String?> missingFields,
      Value<bool> isVerified,
      Value<String?> availability,
      Value<double?> minServicePrice,
      Value<String?> location,
      Value<String?> locationNormalized,
      Value<double?> latitude,
      Value<double?> longitude,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TrainerProfilesTableUpdateCompanionBuilder =
    TrainerProfilesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> certifications,
      Value<String?> phone,
      Value<String?> aboutMe,
      Value<String?> philosophy,
      Value<String?> methodology,
      Value<String?> branding,
      Value<String?> bannerImagePath,
      Value<String?> customDomain,
      Value<bool> domainVerified,
      Value<String?> profilePhotoPath,
      Value<String> specialties,
      Value<String> trainingTypes,
      Value<String> businessCurrency,
      Value<double?> averageRating,
      Value<int> completionPercentage,
      Value<String?> missingFields,
      Value<bool> isVerified,
      Value<String?> availability,
      Value<double?> minServicePrice,
      Value<String?> location,
      Value<String?> locationNormalized,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TrainerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $TrainerProfilesTable> {
  $$TrainerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aboutMe => $composableBuilder(
    column: $table.aboutMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branding => $composableBuilder(
    column: $table.branding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainerProfilesTable> {
  $$TrainerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aboutMe => $composableBuilder(
    column: $table.aboutMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branding => $composableBuilder(
    column: $table.branding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainerProfilesTable> {
  $$TrainerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get aboutMe =>
      $composableBuilder(column: $table.aboutMe, builder: (column) => column);

  GeneratedColumn<String> get philosophy => $composableBuilder(
    column: $table.philosophy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get methodology => $composableBuilder(
    column: $table.methodology,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branding =>
      $composableBuilder(column: $table.branding, builder: (column) => column);

  GeneratedColumn<String> get bannerImagePath => $composableBuilder(
    column: $table.bannerImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDomain => $composableBuilder(
    column: $table.customDomain,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get domainVerified => $composableBuilder(
    column: $table.domainVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainingTypes => $composableBuilder(
    column: $table.trainingTypes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessCurrency => $composableBuilder(
    column: $table.businessCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionPercentage => $composableBuilder(
    column: $table.completionPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingFields => $composableBuilder(
    column: $table.missingFields,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minServicePrice => $composableBuilder(
    column: $table.minServicePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get locationNormalized => $composableBuilder(
    column: $table.locationNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TrainerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainerProfilesTable,
          TrainerProfile,
          $$TrainerProfilesTableFilterComposer,
          $$TrainerProfilesTableOrderingComposer,
          $$TrainerProfilesTableAnnotationComposer,
          $$TrainerProfilesTableCreateCompanionBuilder,
          $$TrainerProfilesTableUpdateCompanionBuilder,
          (
            TrainerProfile,
            BaseReferences<
              _$AppDatabase,
              $TrainerProfilesTable,
              TrainerProfile
            >,
          ),
          TrainerProfile,
          PrefetchHooks Function()
        > {
  $$TrainerProfilesTableTableManager(
    _$AppDatabase db,
    $TrainerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> aboutMe = const Value.absent(),
                Value<String?> philosophy = const Value.absent(),
                Value<String?> methodology = const Value.absent(),
                Value<String?> branding = const Value.absent(),
                Value<String?> bannerImagePath = const Value.absent(),
                Value<String?> customDomain = const Value.absent(),
                Value<bool> domainVerified = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String> specialties = const Value.absent(),
                Value<String> trainingTypes = const Value.absent(),
                Value<String> businessCurrency = const Value.absent(),
                Value<double?> averageRating = const Value.absent(),
                Value<int> completionPercentage = const Value.absent(),
                Value<String?> missingFields = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<double?> minServicePrice = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> locationNormalized = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerProfilesCompanion(
                id: id,
                userId: userId,
                certifications: certifications,
                phone: phone,
                aboutMe: aboutMe,
                philosophy: philosophy,
                methodology: methodology,
                branding: branding,
                bannerImagePath: bannerImagePath,
                customDomain: customDomain,
                domainVerified: domainVerified,
                profilePhotoPath: profilePhotoPath,
                specialties: specialties,
                trainingTypes: trainingTypes,
                businessCurrency: businessCurrency,
                averageRating: averageRating,
                completionPercentage: completionPercentage,
                missingFields: missingFields,
                isVerified: isVerified,
                availability: availability,
                minServicePrice: minServicePrice,
                location: location,
                locationNormalized: locationNormalized,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> certifications = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> aboutMe = const Value.absent(),
                Value<String?> philosophy = const Value.absent(),
                Value<String?> methodology = const Value.absent(),
                Value<String?> branding = const Value.absent(),
                Value<String?> bannerImagePath = const Value.absent(),
                Value<String?> customDomain = const Value.absent(),
                Value<bool> domainVerified = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String> specialties = const Value.absent(),
                Value<String> trainingTypes = const Value.absent(),
                Value<String> businessCurrency = const Value.absent(),
                Value<double?> averageRating = const Value.absent(),
                Value<int> completionPercentage = const Value.absent(),
                Value<String?> missingFields = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<double?> minServicePrice = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> locationNormalized = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerProfilesCompanion.insert(
                id: id,
                userId: userId,
                certifications: certifications,
                phone: phone,
                aboutMe: aboutMe,
                philosophy: philosophy,
                methodology: methodology,
                branding: branding,
                bannerImagePath: bannerImagePath,
                customDomain: customDomain,
                domainVerified: domainVerified,
                profilePhotoPath: profilePhotoPath,
                specialties: specialties,
                trainingTypes: trainingTypes,
                businessCurrency: businessCurrency,
                averageRating: averageRating,
                completionPercentage: completionPercentage,
                missingFields: missingFields,
                isVerified: isVerified,
                availability: availability,
                minServicePrice: minServicePrice,
                location: location,
                locationNormalized: locationNormalized,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainerProfilesTable,
      TrainerProfile,
      $$TrainerProfilesTableFilterComposer,
      $$TrainerProfilesTableOrderingComposer,
      $$TrainerProfilesTableAnnotationComposer,
      $$TrainerProfilesTableCreateCompanionBuilder,
      $$TrainerProfilesTableUpdateCompanionBuilder,
      (
        TrainerProfile,
        BaseReferences<_$AppDatabase, $TrainerProfilesTable, TrainerProfile>,
      ),
      TrainerProfile,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      required String id,
      required String clientId,
      Value<String?> name,
      required BigInt startTime,
      Value<BigInt?> endTime,
      required String status,
      Value<String?> notes,
      Value<BigInt?> restStartedAt,
      Value<String?> workoutTemplateId,
      Value<BigInt?> plannedDate,
      Value<String?> clientPackageId,
      Value<bool> isTrainerLed,
      Value<BigInt?> reminderTime,
      Value<bool> trainerReminderSent,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<String?> name,
      Value<BigInt> startTime,
      Value<BigInt?> endTime,
      Value<String> status,
      Value<String?> notes,
      Value<BigInt?> restStartedAt,
      Value<String?> workoutTemplateId,
      Value<BigInt?> plannedDate,
      Value<String?> clientPackageId,
      Value<bool> isTrainerLed,
      Value<BigInt?> reminderTime,
      Value<bool> trainerReminderSent,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutTemplateId => $composableBuilder(
    column: $table.workoutTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientPackageId => $composableBuilder(
    column: $table.clientPackageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrainerLed => $composableBuilder(
    column: $table.isTrainerLed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trainerReminderSent => $composableBuilder(
    column: $table.trainerReminderSent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutTemplateId => $composableBuilder(
    column: $table.workoutTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPackageId => $composableBuilder(
    column: $table.clientPackageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrainerLed => $composableBuilder(
    column: $table.isTrainerLed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trainerReminderSent => $composableBuilder(
    column: $table.trainerReminderSent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<BigInt> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<BigInt> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<BigInt> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workoutTemplateId => $composableBuilder(
    column: $table.workoutTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientPackageId => $composableBuilder(
    column: $table.clientPackageId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTrainerLed => $composableBuilder(
    column: $table.isTrainerLed,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trainerReminderSent => $composableBuilder(
    column: $table.trainerReminderSent,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (
            WorkoutSession,
            BaseReferences<
              _$AppDatabase,
              $WorkoutSessionsTable,
              WorkoutSession
            >,
          ),
          WorkoutSession,
          PrefetchHooks Function()
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<BigInt> startTime = const Value.absent(),
                Value<BigInt?> endTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<BigInt?> restStartedAt = const Value.absent(),
                Value<String?> workoutTemplateId = const Value.absent(),
                Value<BigInt?> plannedDate = const Value.absent(),
                Value<String?> clientPackageId = const Value.absent(),
                Value<bool> isTrainerLed = const Value.absent(),
                Value<BigInt?> reminderTime = const Value.absent(),
                Value<bool> trainerReminderSent = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                clientId: clientId,
                name: name,
                startTime: startTime,
                endTime: endTime,
                status: status,
                notes: notes,
                restStartedAt: restStartedAt,
                workoutTemplateId: workoutTemplateId,
                plannedDate: plannedDate,
                clientPackageId: clientPackageId,
                isTrainerLed: isTrainerLed,
                reminderTime: reminderTime,
                trainerReminderSent: trainerReminderSent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                Value<String?> name = const Value.absent(),
                required BigInt startTime,
                Value<BigInt?> endTime = const Value.absent(),
                required String status,
                Value<String?> notes = const Value.absent(),
                Value<BigInt?> restStartedAt = const Value.absent(),
                Value<String?> workoutTemplateId = const Value.absent(),
                Value<BigInt?> plannedDate = const Value.absent(),
                Value<String?> clientPackageId = const Value.absent(),
                Value<bool> isTrainerLed = const Value.absent(),
                Value<BigInt?> reminderTime = const Value.absent(),
                Value<bool> trainerReminderSent = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                clientId: clientId,
                name: name,
                startTime: startTime,
                endTime: endTime,
                status: status,
                notes: notes,
                restStartedAt: restStartedAt,
                workoutTemplateId: workoutTemplateId,
                plannedDate: plannedDate,
                clientPackageId: clientPackageId,
                isTrainerLed: isTrainerLed,
                reminderTime: reminderTime,
                trainerReminderSent: trainerReminderSent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (
        WorkoutSession,
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession>,
      ),
      WorkoutSession,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String name,
      Value<String?> muscleGroup,
      Value<String?> equipment,
      Value<String?> category,
      Value<String?> description,
      Value<String?> videoUrl,
      Value<String?> createdById,
      Value<int?> recommendedRestSeconds,
      Value<bool> isUnilateral,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> muscleGroup,
      Value<String?> equipment,
      Value<String?> category,
      Value<String?> description,
      Value<String?> videoUrl,
      Value<String?> createdById,
      Value<int?> recommendedRestSeconds,
      Value<bool> isUnilateral,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedRestSeconds => $composableBuilder(
    column: $table.recommendedRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedRestSeconds => $composableBuilder(
    column: $table.recommendedRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedRestSeconds => $composableBuilder(
    column: $table.recommendedRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> muscleGroup = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                Value<int?> recommendedRestSeconds = const Value.absent(),
                Value<bool> isUnilateral = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                category: category,
                description: description,
                videoUrl: videoUrl,
                createdById: createdById,
                recommendedRestSeconds: recommendedRestSeconds,
                isUnilateral: isUnilateral,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> muscleGroup = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                Value<int?> recommendedRestSeconds = const Value.absent(),
                Value<bool> isUnilateral = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                category: category,
                description: description,
                videoUrl: videoUrl,
                createdById: createdById,
                recommendedRestSeconds: recommendedRestSeconds,
                isUnilateral: isUnilateral,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String programId,
      Value<int> order,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> programId,
      Value<int> order,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (
            WorkoutTemplate,
            BaseReferences<
              _$AppDatabase,
              $WorkoutTemplatesTable,
              WorkoutTemplate
            >,
          ),
          WorkoutTemplate,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                name: name,
                description: description,
                programId: programId,
                order: order,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String programId,
                Value<int> order = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                name: name,
                description: description,
                programId: programId,
                order: order,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (
        WorkoutTemplate,
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate>,
      ),
      WorkoutTemplate,
      PrefetchHooks Function()
    >;
typedef $$ClientAssessmentsTableCreateCompanionBuilder =
    ClientAssessmentsCompanion Function({
      required String id,
      required String assessmentId,
      required String clientId,
      required double value,
      required BigInt date,
      Value<String?> notes,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ClientAssessmentsTableUpdateCompanionBuilder =
    ClientAssessmentsCompanion Function({
      Value<String> id,
      Value<String> assessmentId,
      Value<String> clientId,
      Value<double> value,
      Value<BigInt> date,
      Value<String?> notes,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ClientAssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientAssessmentsTable> {
  $$ClientAssessmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientAssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientAssessmentsTable> {
  $$ClientAssessmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientAssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientAssessmentsTable> {
  $$ClientAssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<BigInt> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ClientAssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientAssessmentsTable,
          ClientAssessment,
          $$ClientAssessmentsTableFilterComposer,
          $$ClientAssessmentsTableOrderingComposer,
          $$ClientAssessmentsTableAnnotationComposer,
          $$ClientAssessmentsTableCreateCompanionBuilder,
          $$ClientAssessmentsTableUpdateCompanionBuilder,
          (
            ClientAssessment,
            BaseReferences<
              _$AppDatabase,
              $ClientAssessmentsTable,
              ClientAssessment
            >,
          ),
          ClientAssessment,
          PrefetchHooks Function()
        > {
  $$ClientAssessmentsTableTableManager(
    _$AppDatabase db,
    $ClientAssessmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientAssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientAssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientAssessmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assessmentId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<BigInt> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientAssessmentsCompanion(
                id: id,
                assessmentId: assessmentId,
                clientId: clientId,
                value: value,
                date: date,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assessmentId,
                required String clientId,
                required double value,
                required BigInt date,
                Value<String?> notes = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientAssessmentsCompanion.insert(
                id: id,
                assessmentId: assessmentId,
                clientId: clientId,
                value: value,
                date: date,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientAssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientAssessmentsTable,
      ClientAssessment,
      $$ClientAssessmentsTableFilterComposer,
      $$ClientAssessmentsTableOrderingComposer,
      $$ClientAssessmentsTableAnnotationComposer,
      $$ClientAssessmentsTableCreateCompanionBuilder,
      $$ClientAssessmentsTableUpdateCompanionBuilder,
      (
        ClientAssessment,
        BaseReferences<
          _$AppDatabase,
          $ClientAssessmentsTable,
          ClientAssessment
        >,
      ),
      ClientAssessment,
      PrefetchHooks Function()
    >;
typedef $$ClientMeasurementsTableCreateCompanionBuilder =
    ClientMeasurementsCompanion Function({
      required String id,
      required String clientId,
      required BigInt measurementDate,
      Value<double?> weightKg,
      Value<double?> bodyFatPercentage,
      Value<String?> notes,
      Value<String?> customMetrics,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ClientMeasurementsTableUpdateCompanionBuilder =
    ClientMeasurementsCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<BigInt> measurementDate,
      Value<double?> weightKg,
      Value<double?> bodyFatPercentage,
      Value<String?> notes,
      Value<String?> customMetrics,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ClientMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientMeasurementsTable> {
  $$ClientMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get measurementDate => $composableBuilder(
    column: $table.measurementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientMeasurementsTable> {
  $$ClientMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get measurementDate => $composableBuilder(
    column: $table.measurementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientMeasurementsTable> {
  $$ClientMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<BigInt> get measurementDate => $composableBuilder(
    column: $table.measurementDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ClientMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientMeasurementsTable,
          ClientMeasurement,
          $$ClientMeasurementsTableFilterComposer,
          $$ClientMeasurementsTableOrderingComposer,
          $$ClientMeasurementsTableAnnotationComposer,
          $$ClientMeasurementsTableCreateCompanionBuilder,
          $$ClientMeasurementsTableUpdateCompanionBuilder,
          (
            ClientMeasurement,
            BaseReferences<
              _$AppDatabase,
              $ClientMeasurementsTable,
              ClientMeasurement
            >,
          ),
          ClientMeasurement,
          PrefetchHooks Function()
        > {
  $$ClientMeasurementsTableTableManager(
    _$AppDatabase db,
    $ClientMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientMeasurementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<BigInt> measurementDate = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> bodyFatPercentage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> customMetrics = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientMeasurementsCompanion(
                id: id,
                clientId: clientId,
                measurementDate: measurementDate,
                weightKg: weightKg,
                bodyFatPercentage: bodyFatPercentage,
                notes: notes,
                customMetrics: customMetrics,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                required BigInt measurementDate,
                Value<double?> weightKg = const Value.absent(),
                Value<double?> bodyFatPercentage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> customMetrics = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientMeasurementsCompanion.insert(
                id: id,
                clientId: clientId,
                measurementDate: measurementDate,
                weightKg: weightKg,
                bodyFatPercentage: bodyFatPercentage,
                notes: notes,
                customMetrics: customMetrics,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientMeasurementsTable,
      ClientMeasurement,
      $$ClientMeasurementsTableFilterComposer,
      $$ClientMeasurementsTableOrderingComposer,
      $$ClientMeasurementsTableAnnotationComposer,
      $$ClientMeasurementsTableCreateCompanionBuilder,
      $$ClientMeasurementsTableUpdateCompanionBuilder,
      (
        ClientMeasurement,
        BaseReferences<
          _$AppDatabase,
          $ClientMeasurementsTable,
          ClientMeasurement
        >,
      ),
      ClientMeasurement,
      PrefetchHooks Function()
    >;
typedef $$ClientPhotosTableCreateCompanionBuilder =
    ClientPhotosCompanion Function({
      required String id,
      required String clientId,
      required BigInt photoDate,
      required String imagePath,
      Value<String?> caption,
      Value<String?> checkInId,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ClientPhotosTableUpdateCompanionBuilder =
    ClientPhotosCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<BigInt> photoDate,
      Value<String> imagePath,
      Value<String?> caption,
      Value<String?> checkInId,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ClientPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ClientPhotosTable> {
  $$ClientPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get photoDate => $composableBuilder(
    column: $table.photoDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkInId => $composableBuilder(
    column: $table.checkInId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientPhotosTable> {
  $$ClientPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get photoDate => $composableBuilder(
    column: $table.photoDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkInId => $composableBuilder(
    column: $table.checkInId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientPhotosTable> {
  $$ClientPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<BigInt> get photoDate =>
      $composableBuilder(column: $table.photoDate, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get checkInId =>
      $composableBuilder(column: $table.checkInId, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ClientPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientPhotosTable,
          ClientPhoto,
          $$ClientPhotosTableFilterComposer,
          $$ClientPhotosTableOrderingComposer,
          $$ClientPhotosTableAnnotationComposer,
          $$ClientPhotosTableCreateCompanionBuilder,
          $$ClientPhotosTableUpdateCompanionBuilder,
          (
            ClientPhoto,
            BaseReferences<_$AppDatabase, $ClientPhotosTable, ClientPhoto>,
          ),
          ClientPhoto,
          PrefetchHooks Function()
        > {
  $$ClientPhotosTableTableManager(_$AppDatabase db, $ClientPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<BigInt> photoDate = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String?> checkInId = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientPhotosCompanion(
                id: id,
                clientId: clientId,
                photoDate: photoDate,
                imagePath: imagePath,
                caption: caption,
                checkInId: checkInId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                required BigInt photoDate,
                required String imagePath,
                Value<String?> caption = const Value.absent(),
                Value<String?> checkInId = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientPhotosCompanion.insert(
                id: id,
                clientId: clientId,
                photoDate: photoDate,
                imagePath: imagePath,
                caption: caption,
                checkInId: checkInId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientPhotosTable,
      ClientPhoto,
      $$ClientPhotosTableFilterComposer,
      $$ClientPhotosTableOrderingComposer,
      $$ClientPhotosTableAnnotationComposer,
      $$ClientPhotosTableCreateCompanionBuilder,
      $$ClientPhotosTableUpdateCompanionBuilder,
      (
        ClientPhoto,
        BaseReferences<_$AppDatabase, $ClientPhotosTable, ClientPhoto>,
      ),
      ClientPhoto,
      PrefetchHooks Function()
    >;
typedef $$ClientExerciseLogsTableCreateCompanionBuilder =
    ClientExerciseLogsCompanion Function({
      required String id,
      required String clientId,
      required String exerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<bool?> isCompleted,
      Value<int?> order,
      Value<String?> tempo,
      Value<String> side,
      required String workoutSessionId,
      Value<String?> supersetKey,
      Value<int?> orderInSuperset,
      Value<String?> sets,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$ClientExerciseLogsTableUpdateCompanionBuilder =
    ClientExerciseLogsCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<String> exerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<bool?> isCompleted,
      Value<int?> order,
      Value<String?> tempo,
      Value<String> side,
      Value<String> workoutSessionId,
      Value<String?> supersetKey,
      Value<int?> orderInSuperset,
      Value<String?> sets,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$ClientExerciseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientExerciseLogsTable> {
  $$ClientExerciseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetKey => $composableBuilder(
    column: $table.supersetKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderInSuperset => $composableBuilder(
    column: $table.orderInSuperset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientExerciseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientExerciseLogsTable> {
  $$ClientExerciseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetKey => $composableBuilder(
    column: $table.supersetKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderInSuperset => $composableBuilder(
    column: $table.orderInSuperset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientExerciseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientExerciseLogsTable> {
  $$ClientExerciseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersetKey => $composableBuilder(
    column: $table.supersetKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderInSuperset => $composableBuilder(
    column: $table.orderInSuperset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$ClientExerciseLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientExerciseLogsTable,
          ClientExerciseLog,
          $$ClientExerciseLogsTableFilterComposer,
          $$ClientExerciseLogsTableOrderingComposer,
          $$ClientExerciseLogsTableAnnotationComposer,
          $$ClientExerciseLogsTableCreateCompanionBuilder,
          $$ClientExerciseLogsTableUpdateCompanionBuilder,
          (
            ClientExerciseLog,
            BaseReferences<
              _$AppDatabase,
              $ClientExerciseLogsTable,
              ClientExerciseLog
            >,
          ),
          ClientExerciseLog,
          PrefetchHooks Function()
        > {
  $$ClientExerciseLogsTableTableManager(
    _$AppDatabase db,
    $ClientExerciseLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientExerciseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientExerciseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientExerciseLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<bool?> isCompleted = const Value.absent(),
                Value<int?> order = const Value.absent(),
                Value<String?> tempo = const Value.absent(),
                Value<String> side = const Value.absent(),
                Value<String> workoutSessionId = const Value.absent(),
                Value<String?> supersetKey = const Value.absent(),
                Value<int?> orderInSuperset = const Value.absent(),
                Value<String?> sets = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientExerciseLogsCompanion(
                id: id,
                clientId: clientId,
                exerciseId: exerciseId,
                reps: reps,
                weight: weight,
                isCompleted: isCompleted,
                order: order,
                tempo: tempo,
                side: side,
                workoutSessionId: workoutSessionId,
                supersetKey: supersetKey,
                orderInSuperset: orderInSuperset,
                sets: sets,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                required String exerciseId,
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<bool?> isCompleted = const Value.absent(),
                Value<int?> order = const Value.absent(),
                Value<String?> tempo = const Value.absent(),
                Value<String> side = const Value.absent(),
                required String workoutSessionId,
                Value<String?> supersetKey = const Value.absent(),
                Value<int?> orderInSuperset = const Value.absent(),
                Value<String?> sets = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientExerciseLogsCompanion.insert(
                id: id,
                clientId: clientId,
                exerciseId: exerciseId,
                reps: reps,
                weight: weight,
                isCompleted: isCompleted,
                order: order,
                tempo: tempo,
                side: side,
                workoutSessionId: workoutSessionId,
                supersetKey: supersetKey,
                orderInSuperset: orderInSuperset,
                sets: sets,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientExerciseLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientExerciseLogsTable,
      ClientExerciseLog,
      $$ClientExerciseLogsTableFilterComposer,
      $$ClientExerciseLogsTableOrderingComposer,
      $$ClientExerciseLogsTableAnnotationComposer,
      $$ClientExerciseLogsTableCreateCompanionBuilder,
      $$ClientExerciseLogsTableUpdateCompanionBuilder,
      (
        ClientExerciseLog,
        BaseReferences<
          _$AppDatabase,
          $ClientExerciseLogsTable,
          ClientExerciseLog
        >,
      ),
      ClientExerciseLog,
      PrefetchHooks Function()
    >;
typedef $$TrainerServicesTableCreateCompanionBuilder =
    TrainerServicesCompanion Function({
      required String id,
      required String profileId,
      required String title,
      required String description,
      Value<double?> price,
      Value<String?> currency,
      Value<int?> duration,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TrainerServicesTableUpdateCompanionBuilder =
    TrainerServicesCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> title,
      Value<String> description,
      Value<double?> price,
      Value<String?> currency,
      Value<int?> duration,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TrainerServicesTableFilterComposer
    extends Composer<_$AppDatabase, $TrainerServicesTable> {
  $$TrainerServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainerServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainerServicesTable> {
  $$TrainerServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainerServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainerServicesTable> {
  $$TrainerServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TrainerServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainerServicesTable,
          TrainerService,
          $$TrainerServicesTableFilterComposer,
          $$TrainerServicesTableOrderingComposer,
          $$TrainerServicesTableAnnotationComposer,
          $$TrainerServicesTableCreateCompanionBuilder,
          $$TrainerServicesTableUpdateCompanionBuilder,
          (
            TrainerService,
            BaseReferences<
              _$AppDatabase,
              $TrainerServicesTable,
              TrainerService
            >,
          ),
          TrainerService,
          PrefetchHooks Function()
        > {
  $$TrainerServicesTableTableManager(
    _$AppDatabase db,
    $TrainerServicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainerServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainerServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainerServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerServicesCompanion(
                id: id,
                profileId: profileId,
                title: title,
                description: description,
                price: price,
                currency: currency,
                duration: duration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String title,
                required String description,
                Value<double?> price = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerServicesCompanion.insert(
                id: id,
                profileId: profileId,
                title: title,
                description: description,
                price: price,
                currency: currency,
                duration: duration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainerServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainerServicesTable,
      TrainerService,
      $$TrainerServicesTableFilterComposer,
      $$TrainerServicesTableOrderingComposer,
      $$TrainerServicesTableAnnotationComposer,
      $$TrainerServicesTableCreateCompanionBuilder,
      $$TrainerServicesTableUpdateCompanionBuilder,
      (
        TrainerService,
        BaseReferences<_$AppDatabase, $TrainerServicesTable, TrainerService>,
      ),
      TrainerService,
      PrefetchHooks Function()
    >;
typedef $$TrainerPackagesTableCreateCompanionBuilder =
    TrainerPackagesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required double price,
      required int numberOfSessions,
      Value<bool> isActive,
      required String stripeProductId,
      required String stripePriceId,
      required String trainerId,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TrainerPackagesTableUpdateCompanionBuilder =
    TrainerPackagesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<double> price,
      Value<int> numberOfSessions,
      Value<bool> isActive,
      Value<String> stripeProductId,
      Value<String> stripePriceId,
      Value<String> trainerId,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TrainerPackagesTableFilterComposer
    extends Composer<_$AppDatabase, $TrainerPackagesTable> {
  $$TrainerPackagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfSessions => $composableBuilder(
    column: $table.numberOfSessions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripeProductId => $composableBuilder(
    column: $table.stripeProductId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stripePriceId => $composableBuilder(
    column: $table.stripePriceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainerPackagesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainerPackagesTable> {
  $$TrainerPackagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfSessions => $composableBuilder(
    column: $table.numberOfSessions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripeProductId => $composableBuilder(
    column: $table.stripeProductId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stripePriceId => $composableBuilder(
    column: $table.stripePriceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainerPackagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainerPackagesTable> {
  $$TrainerPackagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get numberOfSessions => $composableBuilder(
    column: $table.numberOfSessions,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get stripeProductId => $composableBuilder(
    column: $table.stripeProductId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stripePriceId => $composableBuilder(
    column: $table.stripePriceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainerId =>
      $composableBuilder(column: $table.trainerId, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TrainerPackagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainerPackagesTable,
          TrainerPackage,
          $$TrainerPackagesTableFilterComposer,
          $$TrainerPackagesTableOrderingComposer,
          $$TrainerPackagesTableAnnotationComposer,
          $$TrainerPackagesTableCreateCompanionBuilder,
          $$TrainerPackagesTableUpdateCompanionBuilder,
          (
            TrainerPackage,
            BaseReferences<
              _$AppDatabase,
              $TrainerPackagesTable,
              TrainerPackage
            >,
          ),
          TrainerPackage,
          PrefetchHooks Function()
        > {
  $$TrainerPackagesTableTableManager(
    _$AppDatabase db,
    $TrainerPackagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainerPackagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainerPackagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainerPackagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> numberOfSessions = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> stripeProductId = const Value.absent(),
                Value<String> stripePriceId = const Value.absent(),
                Value<String> trainerId = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerPackagesCompanion(
                id: id,
                name: name,
                description: description,
                price: price,
                numberOfSessions: numberOfSessions,
                isActive: isActive,
                stripeProductId: stripeProductId,
                stripePriceId: stripePriceId,
                trainerId: trainerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required double price,
                required int numberOfSessions,
                Value<bool> isActive = const Value.absent(),
                required String stripeProductId,
                required String stripePriceId,
                required String trainerId,
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerPackagesCompanion.insert(
                id: id,
                name: name,
                description: description,
                price: price,
                numberOfSessions: numberOfSessions,
                isActive: isActive,
                stripeProductId: stripeProductId,
                stripePriceId: stripePriceId,
                trainerId: trainerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainerPackagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainerPackagesTable,
      TrainerPackage,
      $$TrainerPackagesTableFilterComposer,
      $$TrainerPackagesTableOrderingComposer,
      $$TrainerPackagesTableAnnotationComposer,
      $$TrainerPackagesTableCreateCompanionBuilder,
      $$TrainerPackagesTableUpdateCompanionBuilder,
      (
        TrainerPackage,
        BaseReferences<_$AppDatabase, $TrainerPackagesTable, TrainerPackage>,
      ),
      TrainerPackage,
      PrefetchHooks Function()
    >;
typedef $$TrainerTestimonialsTableCreateCompanionBuilder =
    TrainerTestimonialsCompanion Function({
      required String id,
      required String profileId,
      required String clientName,
      required String testimonialText,
      Value<int?> rating,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TrainerTestimonialsTableUpdateCompanionBuilder =
    TrainerTestimonialsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> clientName,
      Value<String> testimonialText,
      Value<int?> rating,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TrainerTestimonialsTableFilterComposer
    extends Composer<_$AppDatabase, $TrainerTestimonialsTable> {
  $$TrainerTestimonialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testimonialText => $composableBuilder(
    column: $table.testimonialText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainerTestimonialsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainerTestimonialsTable> {
  $$TrainerTestimonialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testimonialText => $composableBuilder(
    column: $table.testimonialText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainerTestimonialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainerTestimonialsTable> {
  $$TrainerTestimonialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get testimonialText => $composableBuilder(
    column: $table.testimonialText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TrainerTestimonialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainerTestimonialsTable,
          TrainerTestimonial,
          $$TrainerTestimonialsTableFilterComposer,
          $$TrainerTestimonialsTableOrderingComposer,
          $$TrainerTestimonialsTableAnnotationComposer,
          $$TrainerTestimonialsTableCreateCompanionBuilder,
          $$TrainerTestimonialsTableUpdateCompanionBuilder,
          (
            TrainerTestimonial,
            BaseReferences<
              _$AppDatabase,
              $TrainerTestimonialsTable,
              TrainerTestimonial
            >,
          ),
          TrainerTestimonial,
          PrefetchHooks Function()
        > {
  $$TrainerTestimonialsTableTableManager(
    _$AppDatabase db,
    $TrainerTestimonialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainerTestimonialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainerTestimonialsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrainerTestimonialsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> clientName = const Value.absent(),
                Value<String> testimonialText = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerTestimonialsCompanion(
                id: id,
                profileId: profileId,
                clientName: clientName,
                testimonialText: testimonialText,
                rating: rating,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String clientName,
                required String testimonialText,
                Value<int?> rating = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerTestimonialsCompanion.insert(
                id: id,
                profileId: profileId,
                clientName: clientName,
                testimonialText: testimonialText,
                rating: rating,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainerTestimonialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainerTestimonialsTable,
      TrainerTestimonial,
      $$TrainerTestimonialsTableFilterComposer,
      $$TrainerTestimonialsTableOrderingComposer,
      $$TrainerTestimonialsTableAnnotationComposer,
      $$TrainerTestimonialsTableCreateCompanionBuilder,
      $$TrainerTestimonialsTableUpdateCompanionBuilder,
      (
        TrainerTestimonial,
        BaseReferences<
          _$AppDatabase,
          $TrainerTestimonialsTable,
          TrainerTestimonial
        >,
      ),
      TrainerTestimonial,
      PrefetchHooks Function()
    >;
typedef $$TrainerProgramsTableCreateCompanionBuilder =
    TrainerProgramsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> trainerId,
      Value<String?> category,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TrainerProgramsTableUpdateCompanionBuilder =
    TrainerProgramsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> trainerId,
      Value<String?> category,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TrainerProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $TrainerProgramsTable> {
  $$TrainerProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainerProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainerProgramsTable> {
  $$TrainerProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainerProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainerProgramsTable> {
  $$TrainerProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainerId =>
      $composableBuilder(column: $table.trainerId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TrainerProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainerProgramsTable,
          TrainerProgram,
          $$TrainerProgramsTableFilterComposer,
          $$TrainerProgramsTableOrderingComposer,
          $$TrainerProgramsTableAnnotationComposer,
          $$TrainerProgramsTableCreateCompanionBuilder,
          $$TrainerProgramsTableUpdateCompanionBuilder,
          (
            TrainerProgram,
            BaseReferences<
              _$AppDatabase,
              $TrainerProgramsTable,
              TrainerProgram
            >,
          ),
          TrainerProgram,
          PrefetchHooks Function()
        > {
  $$TrainerProgramsTableTableManager(
    _$AppDatabase db,
    $TrainerProgramsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainerProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainerProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainerProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> trainerId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerProgramsCompanion(
                id: id,
                name: name,
                description: description,
                trainerId: trainerId,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> trainerId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainerProgramsCompanion.insert(
                id: id,
                name: name,
                description: description,
                trainerId: trainerId,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainerProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainerProgramsTable,
      TrainerProgram,
      $$TrainerProgramsTableFilterComposer,
      $$TrainerProgramsTableOrderingComposer,
      $$TrainerProgramsTableAnnotationComposer,
      $$TrainerProgramsTableCreateCompanionBuilder,
      $$TrainerProgramsTableUpdateCompanionBuilder,
      (
        TrainerProgram,
        BaseReferences<_$AppDatabase, $TrainerProgramsTable, TrainerProgram>,
      ),
      TrainerProgram,
      PrefetchHooks Function()
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required BigInt startTime,
      required BigInt endTime,
      required String status,
      Value<bool?> dataSharingApproved,
      Value<BigInt?> dataSharingApprovedAt,
      required String trainerId,
      Value<String?> clientId,
      Value<String?> clientName,
      Value<String?> clientEmail,
      Value<String?> clientNotes,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<BigInt> startTime,
      Value<BigInt> endTime,
      Value<String> status,
      Value<bool?> dataSharingApproved,
      Value<BigInt?> dataSharingApprovedAt,
      Value<String> trainerId,
      Value<String?> clientId,
      Value<String?> clientName,
      Value<String?> clientEmail,
      Value<String?> clientNotes,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<BigInt> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<BigInt> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainerId =>
      $composableBuilder(column: $table.trainerId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEvent,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (
            CalendarEvent,
            BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent>,
          ),
          CalendarEvent,
          PrefetchHooks Function()
        > {
  $$CalendarEventsTableTableManager(
    _$AppDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BigInt> startTime = const Value.absent(),
                Value<BigInt> endTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool?> dataSharingApproved = const Value.absent(),
                Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
                Value<String> trainerId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> clientNotes = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                dataSharingApproved: dataSharingApproved,
                dataSharingApprovedAt: dataSharingApprovedAt,
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName,
                clientEmail: clientEmail,
                clientNotes: clientNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BigInt startTime,
                required BigInt endTime,
                required String status,
                Value<bool?> dataSharingApproved = const Value.absent(),
                Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
                required String trainerId,
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> clientNotes = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                dataSharingApproved: dataSharingApproved,
                dataSharingApprovedAt: dataSharingApprovedAt,
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName,
                clientEmail: clientEmail,
                clientNotes: clientNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEventsTable,
      CalendarEvent,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (
        CalendarEvent,
        BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent>,
      ),
      CalendarEvent,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      required String id,
      required String userId,
      required String message,
      required String type,
      Value<bool> readStatus,
      Value<String?> metadata,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> message,
      Value<String> type,
      Value<bool> readStatus,
      Value<String?> metadata,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTable,
          Notification,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            Notification,
            BaseReferences<_$AppDatabase, $NotificationsTable, Notification>,
          ),
          Notification,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> readStatus = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion(
                id: id,
                userId: userId,
                message: message,
                type: type,
                readStatus: readStatus,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String message,
                required String type,
                Value<bool> readStatus = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion.insert(
                id: id,
                userId: userId,
                message: message,
                type: type,
                readStatus: readStatus,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTable,
      Notification,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        Notification,
        BaseReferences<_$AppDatabase, $NotificationsTable, Notification>,
      ),
      Notification,
      PrefetchHooks Function()
    >;
typedef $$BookingsTableCreateCompanionBuilder =
    BookingsCompanion Function({
      required String id,
      required BigInt startTime,
      required BigInt endTime,
      required String status,
      Value<bool?> dataSharingApproved,
      Value<BigInt?> dataSharingApprovedAt,
      required String trainerId,
      Value<String?> clientId,
      Value<String?> clientName,
      Value<String?> clientEmail,
      Value<String?> clientNotes,
      required BigInt createdAt,
      required BigInt updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$BookingsTableUpdateCompanionBuilder =
    BookingsCompanion Function({
      Value<String> id,
      Value<BigInt> startTime,
      Value<BigInt> endTime,
      Value<String> status,
      Value<bool?> dataSharingApproved,
      Value<BigInt?> dataSharingApprovedAt,
      Value<String> trainerId,
      Value<String?> clientId,
      Value<String?> clientName,
      Value<String?> clientEmail,
      Value<String?> clientNotes,
      Value<BigInt> createdAt,
      Value<BigInt> updatedAt,
      Value<BigInt?> deletedAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$BookingsTableFilterComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainerId => $composableBuilder(
    column: $table.trainerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<BigInt> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<BigInt> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get dataSharingApproved => $composableBuilder(
    column: $table.dataSharingApproved,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get dataSharingApprovedAt => $composableBuilder(
    column: $table.dataSharingApprovedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainerId =>
      $composableBuilder(column: $table.trainerId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientNotes => $composableBuilder(
    column: $table.clientNotes,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$BookingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookingsTable,
          Booking,
          $$BookingsTableFilterComposer,
          $$BookingsTableOrderingComposer,
          $$BookingsTableAnnotationComposer,
          $$BookingsTableCreateCompanionBuilder,
          $$BookingsTableUpdateCompanionBuilder,
          (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
          Booking,
          PrefetchHooks Function()
        > {
  $$BookingsTableTableManager(_$AppDatabase db, $BookingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BigInt> startTime = const Value.absent(),
                Value<BigInt> endTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool?> dataSharingApproved = const Value.absent(),
                Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
                Value<String> trainerId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> clientNotes = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> updatedAt = const Value.absent(),
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingsCompanion(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                dataSharingApproved: dataSharingApproved,
                dataSharingApprovedAt: dataSharingApprovedAt,
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName,
                clientEmail: clientEmail,
                clientNotes: clientNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BigInt startTime,
                required BigInt endTime,
                required String status,
                Value<bool?> dataSharingApproved = const Value.absent(),
                Value<BigInt?> dataSharingApprovedAt = const Value.absent(),
                required String trainerId,
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> clientNotes = const Value.absent(),
                required BigInt createdAt,
                required BigInt updatedAt,
                Value<BigInt?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingsCompanion.insert(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                dataSharingApproved: dataSharingApproved,
                dataSharingApprovedAt: dataSharingApprovedAt,
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName,
                clientEmail: clientEmail,
                clientNotes: clientNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookingsTable,
      Booking,
      $$BookingsTableFilterComposer,
      $$BookingsTableOrderingComposer,
      $$BookingsTableAnnotationComposer,
      $$BookingsTableCreateCompanionBuilder,
      $$BookingsTableUpdateCompanionBuilder,
      (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
      Booking,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$TrainerProfilesTableTableManager get trainerProfiles =>
      $$TrainerProfilesTableTableManager(_db, _db.trainerProfiles);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$ClientAssessmentsTableTableManager get clientAssessments =>
      $$ClientAssessmentsTableTableManager(_db, _db.clientAssessments);
  $$ClientMeasurementsTableTableManager get clientMeasurements =>
      $$ClientMeasurementsTableTableManager(_db, _db.clientMeasurements);
  $$ClientPhotosTableTableManager get clientPhotos =>
      $$ClientPhotosTableTableManager(_db, _db.clientPhotos);
  $$ClientExerciseLogsTableTableManager get clientExerciseLogs =>
      $$ClientExerciseLogsTableTableManager(_db, _db.clientExerciseLogs);
  $$TrainerServicesTableTableManager get trainerServices =>
      $$TrainerServicesTableTableManager(_db, _db.trainerServices);
  $$TrainerPackagesTableTableManager get trainerPackages =>
      $$TrainerPackagesTableTableManager(_db, _db.trainerPackages);
  $$TrainerTestimonialsTableTableManager get trainerTestimonials =>
      $$TrainerTestimonialsTableTableManager(_db, _db.trainerTestimonials);
  $$TrainerProgramsTableTableManager get trainerPrograms =>
      $$TrainerProgramsTableTableManager(_db, _db.trainerPrograms);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$BookingsTableTableManager get bookings =>
      $$BookingsTableTableManager(_db, _db.bookings);
}
