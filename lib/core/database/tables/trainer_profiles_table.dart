import 'package:drift/drift.dart';

/// Mirrors the profiles table but scoped to the trainer's own profile.
/// Both "profiles" and "trainer_profiles" map to the same Prisma Profile model.
/// On the client, they are stored as separate Drift tables to match the sync API.
class TrainerProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get certifications => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get aboutMe => text().nullable()();
  TextColumn get philosophy => text().nullable()();
  TextColumn get methodology => text().nullable()();
  TextColumn get branding => text().nullable()();
  TextColumn get bannerImagePath => text().nullable()();
  TextColumn get customDomain => text().nullable()();
  BoolColumn get domainVerified => boolean().withDefault(const Constant(false))();
  TextColumn get profilePhotoPath => text().nullable()();
  TextColumn get specialties => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get trainingTypes => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get businessCurrency => text().withDefault(const Constant('PLN'))();
  RealColumn get averageRating => real().nullable()();
  IntColumn get completionPercentage => integer().withDefault(const Constant(0))();
  TextColumn get missingFields => text().nullable()(); // JSON
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  TextColumn get availability => text().nullable()(); // JSON
  RealColumn get minServicePrice => real().nullable()();
  // Deprecated location fields
  TextColumn get location => text().nullable()();
  TextColumn get locationNormalized => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
