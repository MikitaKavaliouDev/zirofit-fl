import 'package:drift/drift.dart';

/// Local-only table for caching the authenticated user's data.
/// Not synced with the backend — used for local auth state persistence.
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get username => text().nullable()();
  TextColumn get role => text()();
  Int64Column? get emailVerifiedAt => int64().nullable()();
  IntColumn get defaultCheckInDay => integer().withDefault(const Constant(0))();
  IntColumn get defaultCheckInHour => integer().withDefault(const Constant(9))();
  TextColumn get tier => text().withDefault(const Constant('STARTER'))();
  TextColumn get subscriptionStatus => text().nullable()();
  Int64Column? get trialEndsAt => int64().nullable()();
  BoolColumn get hasCompletedOnboarding => boolean().withDefault(const Constant(false))();
  TextColumn get stripeCustomerId => text().nullable()();
  TextColumn get stripeSubscriptionId => text().nullable()();
  TextColumn get stripeSubscriptionStatus => text().nullable()();
  TextColumn get stripeConnectAccountId => text().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('KG'))();
  TextColumn get pushTokens => text().withDefault(const Constant('[]'))(); // JSON array
  BoolColumn get stripeCancelAtPeriodEnd => boolean().withDefault(const Constant(false))();
  Int64Column? get stripeCurrentPeriodEnd => int64().nullable()();
  Int64Column? get stripeCancelAt => int64().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}
