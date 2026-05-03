# Ziro Fit — Data Models

> **Purpose:** Foundational reference mapping all Prisma models from the `zirofit-next` backend to Dart data classes with JSON serialization, enums, and syncing metadata.
>
> **Last updated:** 2026-05-01
>
> **Source:** `zirofit-next/prisma/schema.prisma`

---

## 1. Conventions

| Domain | Dart / App | Wire / API (JSON) |
|---|---|---|
| Field names | `camelCase` | `snake_case` |
| Dates / Timestamps | `DateTime` | `int` (Unix ms) |
| Nullable fields | `Type?` | absent or `null` |
| Lists | `List<T>` (non-null, default `[]`) / `null` in wire | `[]` or absent (wire treats missing as `[]`) |
| IDs | `String` | `String` (cuid or UUID) |
| Booleans | `bool` | `true` / `false` |
| Decimals | `double` (Dart) | `String` or `num` (Prisma `Decimal` → cast to double) |
| Enums | `enum` with `toJson()` / `fromJson()` | `String` (PascalCase, e.g. `"IN_PROGRESS"`) |
| Soft delete | `deletedAt` (`DateTime?`) | Present or absent |

**Serialization helpers** (defined once in a shared utility — not repeated per model):

```dart
int? dateTimeToJson(DateTime? dt) => dt?.millisecondsSinceEpoch;
DateTime dateTimeFromJson(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);
DateTime? dateTimeFromJsonOrNull(int? ms) =>
    ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

// Lists: wire omits empty arrays → Dart gets []
List<T> listFromJson<T>(List<dynamic>? json, T Function(dynamic) transform) =>
    json?.map(transform).toList() ?? [];
```

---

## 2. Enum Definitions (9 enums)

All enums follow the same pattern:

```dart
/// snake_case on wire, PascalCase in Dart.
enum XxxEnum {
  value,
  // …

  /// Deserialize from API string.
  factory XxxEnum.fromJson(String json) =>
      XxxEnum.values.firstWhere((e) => e.name == json);

  /// Serialize to API string.
  String toJson() => name;
}
```

### WorkoutSessionStatus

```dart
enum WorkoutSessionStatus { planned, inProgress, completed;

  factory WorkoutSessionStatus.fromJson(String json) =>
      WorkoutSessionStatus.values.firstWhere((e) => e.name == _toDartName(json));

  String toJson() => _toApiName(name);
}

String _toDartName(String api) {
  // PLANNED → planned, IN_PROGRESS → inProgress
  final parts = api.split('_');
  return parts[0].toLowerCase() +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase()).join();
}

String _toApiName(String dart) {
  return dart.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)}').toUpperCase();
}
```

For brevity, all enum serialization below follows the same `_toDartName` / `_toApiName` helpers (defined once in a shared `enum_utils.dart`).

| Enum | Values | Wire String |
|---|---|---|
| `WorkoutSessionStatus` | `planned`, `inProgress`, `completed` | `"PLANNED"`, `"IN_PROGRESS"`, `"COMPLETED"` |
| `StepType` | `exercise`, `rest` | `"EXERCISE"`, `"REST"` |
| `TrainingType` | `inPerson`, `online` | `"IN_PERSON"`, `"ONLINE"` |
| `BookingStatus` | `pending`, `confirmed`, `cancelled` | `"PENDING"`, `"CONFIRMED"`, `"CANCELLED"` |
| `WeightUnit` | `kg`, `lb` | `"KG"`, `"LB"` |
| `UserTier` | `starter`, `pro`, `elite` | `"STARTER"`, `"PRO"`, `"ELITE"` |
| `EventStatus` | `pending`, `approved`, `rejected` | `"PENDING"`, `"APPROVED"`, `"REJECTED"` |
| `HabitFrequency` | `daily`, `weekly` | `"DAILY"`, `"WEEKLY"` |
| `SupportTicketCategory` | `bugReport`, `featureRequest`, `generalSupport` | `"BUG_REPORT"`, `"FEATURE_REQUEST"`, `"GENERAL_SUPPORT"` |

```dart
// ============================================================
// All enum fromJson/toJson — uses shared helpers as above
// ============================================================

enum WorkoutSessionStatus { planned, inProgress, completed; /* … */ }
enum StepType { exercise, rest; /* … */ }
enum TrainingType { inPerson, online; /* … */ }
enum BookingStatus { pending, confirmed, cancelled; /* … */ }
enum WeightUnit { kg, lb; /* … */ }
enum UserTier { starter, pro, elite; /* … */ }
enum EventStatus { pending, approved, rejected; /* … */ }
enum HabitFrequency { daily, weekly; /* … */ }
enum SupportTicketCategory { bugReport, featureRequest, generalSupport; /* … */ }
```

---

## 3. Core Identity Models

### 3.1 User

| Dart field | Type | Wire field | Notes |
|---|---|---|---|
| `id` | `String` | `id` | Supabase Auth UUID |
| `name` | `String` | `name` | |
| `email` | `String` | `email` | `@unique` in DB |
| `username` | `String?` | `username` | Public profile URL |
| `role` | `String` | `role` | `"trainer"`, `"client"`, `"admin"`, `"pending"` |
| `emailVerifiedAt` | `DateTime?` | `email_verified_at` | |
| `defaultCheckInDay` | `int` | `default_check_in_day` | 0=Sunday, default 0 |
| `defaultCheckInHour` | `int` | `default_check_in_hour` | 24h, default 9 |
| `tier` | `UserTier` | `tier` | default `STARTER` |
| `subscriptionStatus` | `String?` | `subscription_status` | `active`, `past_due`, `canceled`, `incomplete` |
| `trialEndsAt` | `DateTime?` | `trial_ends_at` | |
| `hasCompletedOnboarding` | `bool` | `has_completed_onboarding` | default `false` |
| `stripeCustomerId` | `String?` | `stripe_customer_id` | `@unique` |
| `stripeSubscriptionId` | `String?` | `stripe_subscription_id` | `@unique` |
| `stripeSubscriptionStatus` | `String?` | `stripe_subscription_status` | |
| `stripeConnectAccountId` | `String?` | `stripe_connect_account_id` | `@unique`, trainer payouts |
| `weightUnit` | `WeightUnit` | `weight_unit` | default `KG` |
| `pushTokens` | `List<String>` | `push_tokens` | |
| `stripeCancelAtPeriodEnd` | `bool` | `stripe_cancel_at_period_end` | default `false` |
| `stripeCurrentPeriodEnd` | `DateTime?` | `stripe_current_period_end` | |
| `stripeCancelAt` | `DateTime?` | `stripe_cancel_at` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

```dart
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
    emailVerifiedAt: dateTimeFromJsonOrNull(json['email_verified_at'] as int?),
    defaultCheckInDay: (json['default_check_in_day'] as int?) ?? 0,
    defaultCheckInHour: (json['default_check_in_hour'] as int?) ?? 9,
    tier: UserTier.fromJson(json['tier'] as String? ?? 'STARTER'),
    subscriptionStatus: json['subscription_status'] as String?,
    trialEndsAt: dateTimeFromJsonOrNull(json['trial_ends_at'] as int?),
    hasCompletedOnboarding: (json['has_completed_onboarding'] as bool?) ?? false,
    stripeCustomerId: json['stripe_customer_id'] as String?,
    stripeSubscriptionId: json['stripe_subscription_id'] as String?,
    stripeSubscriptionStatus: json['stripe_subscription_status'] as String?,
    stripeConnectAccountId: json['stripe_connect_account_id'] as String?,
    weightUnit: WeightUnit.fromJson(json['weight_unit'] as String? ?? 'KG'),
    pushTokens: (json['push_tokens'] as List<dynamic>?)?.cast<String>() ?? const [],
    stripeCancelAtPeriodEnd: (json['stripe_cancel_at_period_end'] as bool?) ?? false,
    stripeCurrentPeriodEnd: dateTimeFromJsonOrNull(json['stripe_current_period_end'] as int?),
    stripeCancelAt: dateTimeFromJsonOrNull(json['stripe_cancel_at'] as int?),
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
}
```

### 3.2 Profile

| Dart field | Type | Wire field | Notes |
|---|---|---|---|
| `id` | `String` | `id` | cuid |
| `userId` | `String` | `user_id` | FK → User.id, `@unique` |
| `certifications` | `String?` | `certifications` | |
| `phone` | `String?` | `phone` | |
| `aboutMe` | `String?` | `about_me` | Text |
| `philosophy` | `String?` | `philosophy` | Text |
| `methodology` | `String?` | `methodology` | Text |
| `branding` | `String?` | `branding` | Text |
| `bannerImagePath` | `String?` | `banner_image_path` | |
| `customDomain` | `String?` | `custom_domain` | `@unique` |
| `domainVerified` | `bool` | `domain_verified` | default `false` |
| `profilePhotoPath` | `String?` | `profile_photo_path` | |
| `specialties` | `List<String>` | `specialties` | |
| `trainingTypes` | `List<TrainingType>` | `training_types` | |
| `businessCurrency` | `String` | `business_currency` | default `"PLN"` |
| `averageRating` | `double?` | `average_rating` | Float |
| `completionPercentage` | `int` | `completion_percentage` | default 0 |
| `missingFields` | `List<dynamic>?` | `missing_fields` | JSON array of strings |
| `isVerified` | `bool` | `is_verified` | default `false` |
| `availability` | `Map<String, dynamic>?` | `availability` | JSON, e.g. `{"mon":["09:00-17:00"]}` |
| `minServicePrice` | `double?` | `min_service_price` | Decimal → double |
| `location` | `String?` | `location` | **@deprecated** |
| `locationNormalized` | `String?` | `location_normalized` | **@deprecated** |
| `latitude` | `double?` | `latitude` | **@deprecated** |
| `longitude` | `double?` | `longitude` | **@deprecated** |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | Soft delete |

```dart
class Profile {
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
  final List<String> specialties;
  final List<TrainingType> trainingTypes;
  final String businessCurrency;
  final double? averageRating;
  final int completionPercentage;
  final List<dynamic>? missingFields;
  final bool isVerified;
  final Map<String, dynamic>? availability;
  final double? minServicePrice;
  // @deprecated
  final String? location;
  final String? locationNormalized;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Profile({ /* all fields */ });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    certifications: json['certifications'] as String?,
    phone: json['phone'] as String?,
    aboutMe: json['about_me'] as String?,
    philosophy: json['philosophy'] as String?,
    methodology: json['methodology'] as String?,
    branding: json['branding'] as String?,
    bannerImagePath: json['banner_image_path'] as String?,
    customDomain: json['custom_domain'] as String?,
    domainVerified: (json['domain_verified'] as bool?) ?? false,
    profilePhotoPath: json['profile_photo_path'] as String?,
    specialties: (json['specialties'] as List<dynamic>?)?.cast<String>() ?? const [],
    trainingTypes: (json['training_types'] as List<dynamic>?)
        ?.map((e) => TrainingType.fromJson(e as String))
        .toList() ?? const [],
    businessCurrency: (json['business_currency'] as String?) ?? 'PLN',
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    completionPercentage: (json['completion_percentage'] as int?) ?? 0,
    missingFields: (json['missing_fields'] as List<dynamic>?),
    isVerified: (json['is_verified'] as bool?) ?? false,
    availability: json['availability'] as Map<String, dynamic>?,
    minServicePrice: (json['min_service_price'] as num?)?.toDouble(),
    location: json['location'] as String?,
    locationNormalized: json['location_normalized'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'certifications': certifications,
    'phone': phone,
    'about_me': aboutMe,
    'philosophy': philosophy,
    'methodology': methodology,
    'branding': branding,
    'banner_image_path': bannerImagePath,
    'custom_domain': customDomain,
    'domain_verified': domainVerified,
    'profile_photo_path': profilePhotoPath,
    'specialties': specialties,
    'training_types': trainingTypes.map((e) => e.toJson()).toList(),
    'business_currency': businessCurrency,
    'average_rating': averageRating,
    'completion_percentage': completionPercentage,
    'missing_fields': missingFields,
    'is_verified': isVerified,
    'availability': availability,
    'min_service_price': minServicePrice,
    'location': location,
    'location_normalized': locationNormalized,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

---

## 4. Client Profile Sub-Models

All sub-models of `Profile` share the same pattern: `profileId` FK, `createdAt`/`updatedAt`/`deletedAt` timestamps.

### 4.1 Location

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | FK → Profile |
| `address` | `String` | `address` | |
| `normalizedAddress` | `String` | `normalized_address` | |
| `latitude` | `double?` | `latitude` | |
| `longitude` | `double?` | `longitude` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Location {
  final String id;
  final String profileId;
  final String address;
  final String normalizedAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Location({ /* all fields */ });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    address: json['address'] as String,
    normalizedAddress: json['normalized_address'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'profile_id': profileId,
    'address': address,
    'normalized_address': normalizedAddress,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 4.2 Service

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `title` | `String` | `title` | |
| `description` | `String` | `description` | Text |
| `price` | `double?` | `price` | Decimal → double |
| `currency` | `String?` | `currency` | |
| `duration` | `int?` | `duration` | Minutes |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 4.3 Testimonial

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `clientName` | `String` | `client_name` | |
| `testimonialText` | `String` | `testimonial_text` | Text |
| `rating` | `int?` | `rating` | 1–5 |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 4.4 TransformationPhoto

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `imagePath` | `String` | `image_path` | |
| `caption` | `String?` | `caption` | |
| `clientName` | `String?` | `client_name` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 4.5 SocialLink

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `platform` | `String` | `platform` | e.g. `"Instagram"` |
| `username` | `String` | `username` | |
| `profileUrl` | `String` | `profile_url` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 4.6 ExternalLink

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `linkUrl` | `String` | `link_url` | |
| `label` | `String` | `label` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 4.7 Benefit

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `profileId` | `String` | `profile_id` | |
| `iconName` | `String?` | `icon_name` | |
| `iconStyle` | `String?` | `icon_style` | default `"outline"` |
| `title` | `String` | `title` | |
| `description` | `String?` | `description` | Text |
| `orderColumn` | `int` | `order_column` | default 0 |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 5. Client Management Models

### 5.1 Client

| Dart field | Type | Wire field | Notes |
|---|---|---|---|
| `id` | `String` | `id` | cuid |
| `trainerId` | `String?` | `trainer_id` | FK → User.id (trainer) |
| `userId` | `String?` | `user_id` | FK → User.id (client account), `@unique` |
| `name` | `String` | `name` | |
| `email` | `String?` | `email` | |
| `phone` | `String?` | `phone` | |
| `avatarPath` | `String?` | `avatar_path` | |
| `status` | `String` | `status` | `"active"`, `"inactive"`, `"lead"` |
| `dateOfBirth` | `DateTime?` | `date_of_birth` | Date only |
| `goals` | `String?` | `goals` | Text |
| `healthNotes` | `String?` | `health_notes` | Text |
| `emergencyContactName` | `String?` | `emergency_contact_name` | |
| `emergencyContactPhone` | `String?` | `emergency_contact_phone` | |
| `checkInDay` | `int?` | `check_in_day` | Override trainer default |
| `checkInHour` | `int?` | `check_in_hour` | Override trainer default |
| `dataSharingExpiresAt` | `DateTime?` | `data_sharing_expires_at` | `null` = forever |
| `sharingSettings` | `Map<String, dynamic>?` | `sharing_settings` | JSON |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Client {
  final String id;
  final String? trainerId;
  final String? userId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String status;
  final DateTime? dateOfBirth;
  final String? goals;
  final String? healthNotes;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final int? checkInDay;
  final int? checkInHour;
  final DateTime? dataSharingExpiresAt;
  final Map<String, dynamic>? sharingSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Client({ /* all fields */ });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as String,
    trainerId: json['trainer_id'] as String?,
    userId: json['user_id'] as String?,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    avatarPath: json['avatar_path'] as String?,
    status: (json['status'] as String?) ?? 'active',
    dateOfBirth: dateTimeFromJsonOrNull(json['date_of_birth'] as int?),
    goals: json['goals'] as String?,
    healthNotes: json['health_notes'] as String?,
    emergencyContactName: json['emergency_contact_name'] as String?,
    emergencyContactPhone: json['emergency_contact_phone'] as String?,
    checkInDay: json['check_in_day'] as int?,
    checkInHour: json['check_in_hour'] as int?,
    dataSharingExpiresAt: dateTimeFromJsonOrNull(json['data_sharing_expires_at'] as int?),
    sharingSettings: json['sharing_settings'] as Map<String, dynamic>?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trainer_id': trainerId,
    'user_id': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar_path': avatarPath,
    'status': status,
    'date_of_birth': dateOfBirth != null ? DateTime(dateOfBirth!.year, dateOfBirth!.month, dateOfBirth!.day).millisecondsSinceEpoch : null,
    'goals': goals,
    'health_notes': healthNotes,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'check_in_day': checkInDay,
    'check_in_hour': checkInHour,
    'data_sharing_expires_at': dateTimeToJson(dataSharingExpiresAt),
    'sharing_settings': sharingSettings,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 5.2 ClientMeasurement

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `measurementDate` | `DateTime` | `measurement_date` | Date only |
| `weightKg` | `double?` | `weight_kg` | |
| `bodyFatPercentage` | `double?` | `body_fat_percentage` | |
| `notes` | `String?` | `notes` | Text |
| `customMetrics` | `List<dynamic>?` | `custom_metrics` | JSON `[{name, value}]` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 5.3 ClientProgressPhoto

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `photoDate` | `DateTime` | `photo_date` | Date |
| `imagePath` | `String` | `image_path` | |
| `caption` | `String?` | `caption` | |
| `checkInId` | `String?` | `check_in_id` | FK → CheckIn |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 6. Workout Engine Models

### 6.1 Exercise

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | `@unique` |
| `muscleGroup` | `String?` | `muscle_group` | |
| `equipment` | `String?` | `equipment` | |
| `category` | `String?` | `category` | VarChar(50) |
| `description` | `String?` | `description` | Text |
| `videoUrl` | `String?` | `video_url` | |
| `createdById` | `String?` | `created_by_id` | null = system exercise |
| `recommendedRestSeconds` | `int?` | `recommended_rest_seconds` | |
| `isUnilateral` | `bool` | `is_unilateral` | default `false` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Exercise {
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Exercise({ /* all fields */ });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    muscleGroup: json['muscle_group'] as String?,
    equipment: json['equipment'] as String?,
    category: json['category'] as String?,
    description: json['description'] as String?,
    videoUrl: json['video_url'] as String?,
    createdById: json['created_by_id'] as String?,
    recommendedRestSeconds: json['recommended_rest_seconds'] as int?,
    isUnilateral: (json['is_unilateral'] as bool?) ?? false,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscle_group': muscleGroup,
    'equipment': equipment,
    'category': category,
    'description': description,
    'video_url': videoUrl,
    'created_by_id': createdById,
    'recommended_rest_seconds': recommendedRestSeconds,
    'is_unilateral': isUnilateral,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 6.2 ClientExerciseLog

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `exerciseId` | `String` | `exercise_id` | FK → Exercise |
| `reps` | `int?` | `reps` | |
| `weight` | `double?` | `weight` | |
| `isCompleted` | `bool?` | `is_completed` | |
| `order` | `int?` | `order` | |
| `tempo` | `String?` | `tempo` | e.g. `"3010"` |
| `side` | `String` | `side` | `"LEFT"`, `"RIGHT"`, `"BOTH"` |
| `workoutSessionId` | `String` | `workout_session_id` | FK → WorkoutSession |
| `supersetKey` | `String?` | `superset_key` | |
| `orderInSuperset` | `int?` | `order_in_superset` | |
| `sets` | `List<dynamic>?` | `sets` | **DEPRECATED** JSON |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
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
  final List<dynamic>? sets; // DEPRECATED
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientExerciseLog({ /* all fields */ });

  factory ClientExerciseLog.fromJson(Map<String, dynamic> json) => ClientExerciseLog(
    id: json['id'] as String,
    clientId: json['client_id'] as String,
    exerciseId: json['exercise_id'] as String,
    reps: json['reps'] as int?,
    weight: (json['weight'] as num?)?.toDouble(),
    isCompleted: json['is_completed'] as bool?,
    order: json['order'] as int?,
    tempo: json['tempo'] as String?,
    side: (json['side'] as String?) ?? 'BOTH',
    workoutSessionId: json['workout_session_id'] as String,
    supersetKey: json['superset_key'] as String?,
    orderInSuperset: json['order_in_superset'] as int?,
    sets: json['sets'] as List<dynamic>?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
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
}
```

### 6.3 WorkoutSession

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `name` | `String?` | `name` | Custom workout name |
| `startTime` | `DateTime` | `start_time` | |
| `endTime` | `DateTime?` | `end_time` | |
| `status` | `WorkoutSessionStatus` | `status` | default `IN_PROGRESS` |
| `notes` | `String?` | `notes` | Text |
| `restStartedAt` | `DateTime?` | `rest_started_at` | |
| `workoutTemplateId` | `String?` | `workout_template_id` | FK → WorkoutTemplate |
| `plannedDate` | `DateTime?` | `planned_date` | Date |
| `clientPackageId` | `String?` | `client_package_id` | FK → ClientPackage |
| `isTrainerLed` | `bool` | `is_trainer_led` | default `false` |
| `reminderTime` | `DateTime?` | `reminder_time` | |
| `trainerReminderSent` | `bool` | `trainer_reminder_sent` | default `false` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 6.4 WorkoutSessionComment

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `text` | `String` | `text` | Text |
| `workoutSessionId` | `String` | `workout_session_id` | FK → WorkoutSession |
| `userId` | `String` | `user_id` | FK → User (author) |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 7. Program / Template Models

### 7.1 WorkoutProgram

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | |
| `description` | `String?` | `description` | Text |
| `trainerId` | `String?` | `trainer_id` | FK → User |
| `category` | `String?` | `category` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class WorkoutProgram {
  final String id;
  final String name;
  final String? description;
  final String? trainerId;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WorkoutProgram({ /* all fields */ });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    trainerId: json['trainer_id'] as String?,
    category: json['category'] as String?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'trainer_id': trainerId,
    'category': category,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 7.2 WorkoutTemplate

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | |
| `description` | `String?` | `description` | Text |
| `programId` | `String` | `program_id` | FK → WorkoutProgram |
| `order` | `int` | `order` | default 0 |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 7.3 TemplateExercise

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `templateId` | `String` | `template_id` | FK → WorkoutTemplate |
| `type` | `StepType?` | `type` | `EXERCISE` or `REST` |
| `exerciseId` | `String?` | `exercise_id` | FK → Exercise |
| `targetReps` | `String?` | `target_reps` | e.g. `"8-12"` |
| `targetRIR` | `int?` | `target_rir` | Reps in Reserve |
| `tempo` | `String?` | `tempo` | e.g. `"3010"` |
| `enableRpe` | `bool` | `enable_rpe` | default `false` |
| `durationSeconds` | `int?` | `duration_seconds` | Rest duration or post-exercise rest |
| `notes` | `String?` | `notes` | Text |
| `order` | `int` | `order` | default 0 |
| `supersetGroupId` | `String?` | `superset_group_id` | e.g. `"A1"`, `"B1"` |
| `supersetOrder` | `int?` | `superset_order` | Within group |
| `targetSets` | `int?` | `target_sets` | **DEPRECATED** |
| `targetRest` | `int?` | `target_rest` | **DEPRECATED** |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class TemplateExercise {
  final String id;
  final String templateId;
  final StepType? type;
  final String? exerciseId;
  final String? targetReps;
  final int? targetRIR;
  final String? tempo;
  final bool enableRpe;
  final int? durationSeconds;
  final String? notes;
  final int order;
  final String? supersetGroupId;
  final int? supersetOrder;
  final int? targetSets;  // DEPRECATED
  final int? targetRest;   // DEPRECATED
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TemplateExercise({ /* all fields */ });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) => TemplateExercise(
    id: json['id'] as String,
    templateId: json['template_id'] as String,
    type: json['type'] != null ? StepType.fromJson(json['type'] as String) : null,
    exerciseId: json['exercise_id'] as String?,
    targetReps: json['target_reps'] as String?,
    targetRIR: json['target_rir'] as int?,
    tempo: json['tempo'] as String?,
    enableRpe: (json['enable_rpe'] as bool?) ?? false,
    durationSeconds: json['duration_seconds'] as int?,
    notes: json['notes'] as String?,
    order: (json['order'] as int?) ?? 0,
    supersetGroupId: json['superset_group_id'] as String?,
    supersetOrder: json['superset_order'] as int?,
    targetSets: json['target_sets'] as int?,
    targetRest: json['target_rest'] as int?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'template_id': templateId,
    'type': type?.toJson(),
    'exercise_id': exerciseId,
    'target_reps': targetReps,
    'target_rir': targetRIR,
    'tempo': tempo,
    'enable_rpe': enableRpe,
    'duration_seconds': durationSeconds,
    'notes': notes,
    'order': order,
    'superset_group_id': supersetGroupId,
    'superset_order': supersetOrder,
    'target_sets': targetSets,
    'target_rest': targetRest,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 7.4 ClientProgramAssignment

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `programId` | `String` | `program_id` | FK → WorkoutProgram |
| `startDate` | `DateTime` | `start_date` | |
| `isActive` | `bool` | `is_active` | default `true` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 8. Progress Models

### 8.1 PersonalRecord

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `exerciseId` | `String` | `exercise_id` | FK → Exercise |
| `workoutSessionId` | `String` | `workout_session_id` | FK → WorkoutSession |
| `recordType` | `String` | `record_type` | `"e1rm"`, `"best_set_volume"`, `"max_weight"`, `"max_reps"` |
| `value` | `double` | `value` | |
| `achievedAt` | `DateTime` | `achieved_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

**Unique constraint:** `[clientId, exerciseId, recordType]`

```dart
class PersonalRecord {
  final String id;
  final String clientId;
  final String exerciseId;
  final String workoutSessionId;
  final String recordType;
  final double value;
  final DateTime achievedAt;
  final DateTime? deletedAt;

  const PersonalRecord({ /* all fields */ });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
    id: json['id'] as String,
    clientId: json['client_id'] as String,
    exerciseId: json['exercise_id'] as String,
    workoutSessionId: json['workout_session_id'] as String,
    recordType: json['record_type'] as String,
    value: (json['value'] as num).toDouble(),
    achievedAt: dateTimeFromJson(json['achieved_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'exercise_id': exerciseId,
    'workout_session_id': workoutSessionId,
    'record_type': recordType,
    'value': value,
    'achieved_at': dateTimeToJson(achievedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

---

## 9. Assessment Models

### 9.1 Assessment

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | |
| `description` | `String?` | `description` | Text |
| `unit` | `String` | `unit` | e.g. `"cm"`, `"seconds"` |
| `trainerId` | `String?` | `trainer_id` | null = system-wide |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

**Unique:** `[trainerId, name]`

### 9.2 AssessmentResult

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `assessmentId` | `String` | `assessment_id` | FK → Assessment |
| `clientId` | `String` | `client_id` | FK → Client |
| `value` | `double` | `value` | |
| `date` | `DateTime` | `date` | |
| `notes` | `String?` | `notes` | Text |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 10. Check-In Model

### 10.1 CheckIn

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `date` | `DateTime` | `date` | |
| `status` | `String` | `status` | `"SUBMITTED"` / `"REVIEWED"` |
| `weight` | `double?` | `weight` | Auto-syncs to ClientMeasurement |
| `waistCm` | `double?` | `waist_cm` | |
| `sleepHours` | `double?` | `sleep_hours` | |
| `energyLevel` | `int?` | `energy_level` | 1–10 |
| `stressLevel` | `int?` | `stress_level` | 1–10 |
| `hungerLevel` | `int?` | `hunger_level` | 1–10 |
| `digestionLevel` | `int?` | `digestion_level` | 1–10 |
| `nutritionCompliance` | `String?` | `nutrition_compliance` | `"ON_TRACK"`, `"MOSTLY"`, `"OFF_TRACK"` |
| `clientNotes` | `String?` | `client_notes` | Text |
| `trainerResponse` | `String?` | `trainer_response` | Text |
| `reviewedAt` | `DateTime?` | `reviewed_at` | |
| `reviewedByUserId` | `String?` | `reviewed_by_user_id` | FK → User |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

```dart
class CheckIn {
  final String id;
  final String clientId;
  final DateTime date;
  final String status;
  final double? weight;
  final double? waistCm;
  final double? sleepHours;
  final int? energyLevel;
  final int? stressLevel;
  final int? hungerLevel;
  final int? digestionLevel;
  final String? nutritionCompliance;
  final String? clientNotes;
  final String? trainerResponse;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckIn({ /* all fields */ });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    id: json['id'] as String,
    clientId: json['client_id'] as String,
    date: dateTimeFromJson(json['date'] as int),
    status: (json['status'] as String?) ?? 'SUBMITTED',
    weight: (json['weight'] as num?)?.toDouble(),
    waistCm: (json['waist_cm'] as num?)?.toDouble(),
    sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
    energyLevel: json['energy_level'] as int?,
    stressLevel: json['stress_level'] as int?,
    hungerLevel: json['hunger_level'] as int?,
    digestionLevel: json['digestion_level'] as int?,
    nutritionCompliance: json['nutrition_compliance'] as String?,
    clientNotes: json['client_notes'] as String?,
    trainerResponse: json['trainer_response'] as String?,
    reviewedAt: dateTimeFromJsonOrNull(json['reviewed_at'] as int?),
    reviewedByUserId: json['reviewed_by_user_id'] as String?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'date': dateTimeToJson(date),
    'status': status,
    'weight': weight,
    'waist_cm': waistCm,
    'sleep_hours': sleepHours,
    'energy_level': energyLevel,
    'stress_level': stressLevel,
    'hunger_level': hungerLevel,
    'digestion_level': digestionLevel,
    'nutrition_compliance': nutritionCompliance,
    'client_notes': clientNotes,
    'trainer_response': trainerResponse,
    'reviewed_at': dateTimeToJson(reviewedAt),
    'reviewed_by_user_id': reviewedByUserId,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
```

---

## 11. Communication Models

### 11.1 Conversation

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `clientId` | `String` | `client_id` | FK → Client (profile ID, not User ID) |
| `lastMessageAt` | `DateTime` | `last_message_at` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Unique:** `[trainerId, clientId]`

```dart
class Conversation {
  final String id;
  final String trainerId;
  final String clientId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({ /* all fields */ });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    trainerId: json['trainer_id'] as String,
    clientId: json['client_id'] as String,
    lastMessageAt: dateTimeFromJson(json['last_message_at'] as int),
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trainer_id': trainerId,
    'client_id': clientId,
    'last_message_at': dateTimeToJson(lastMessageAt),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
```

### 11.2 Message

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `conversationId` | `String` | `conversation_id` | FK → Conversation |
| `senderId` | `String?` | `sender_id` | null = system message |
| `content` | `String` | `content` | Text |
| `mediaUrl` | `String?` | `media_url` | |
| `mediaType` | `String?` | `media_type` | `"image"` or `"video"` |
| `isSystemMessage` | `bool` | `is_system_message` | default `false` |
| `workoutSessionId` | `String?` | `workout_session_id` | |
| `readAt` | `DateTime?` | `read_at` | |
| `createdAt` | `DateTime` | `created_at` | |

```dart
class Message {
  final String id;
  final String conversationId;
  final String? senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isSystemMessage;
  final String? workoutSessionId;
  final DateTime? readAt;
  final DateTime createdAt;

  const Message({ /* all fields */ });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String?,
    content: json['content'] as String,
    mediaUrl: json['media_url'] as String?,
    mediaType: json['media_type'] as String?,
    isSystemMessage: (json['is_system_message'] as bool?) ?? false,
    workoutSessionId: json['workout_session_id'] as String?,
    readAt: dateTimeFromJsonOrNull(json['read_at'] as int?),
    createdAt: dateTimeFromJson(json['created_at'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'is_system_message': isSystemMessage,
    'workout_session_id': workoutSessionId,
    'read_at': dateTimeToJson(readAt),
    'created_at': dateTimeToJson(createdAt),
  };
}
```

---

## 12. Scheduling Models

### 12.1 Booking

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `startTime` | `DateTime` | `start_time` | |
| `endTime` | `DateTime` | `end_time` | |
| `status` | `BookingStatus` | `status` | default `PENDING` |
| `dataSharingApproved` | `bool?` | `data_sharing_approved` | default `false` |
| `dataSharingApprovedAt` | `DateTime?` | `data_sharing_approved_at` | |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `clientId` | `String?` | `client_id` | FK → User (registered client) |
| `clientName` | `String?` | `client_name` | Legacy |
| `clientEmail` | `String?` | `client_email` | Legacy |
| `clientNotes` | `String?` | `client_notes` | Text |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Booking {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final bool? dataSharingApproved;
  final DateTime? dataSharingApprovedAt;
  final String trainerId;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? clientNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Booking({ /* all fields */ });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    startTime: dateTimeFromJson(json['start_time'] as int),
    endTime: dateTimeFromJson(json['end_time'] as int),
    status: BookingStatus.fromJson(json['status'] as String? ?? 'PENDING'),
    dataSharingApproved: json['data_sharing_approved'] as bool?,
    dataSharingApprovedAt: dateTimeFromJsonOrNull(json['data_sharing_approved_at'] as int?),
    trainerId: json['trainer_id'] as String,
    clientId: json['client_id'] as String?,
    clientName: json['client_name'] as String?,
    clientEmail: json['client_email'] as String?,
    clientNotes: json['client_notes'] as String?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'start_time': dateTimeToJson(startTime),
    'end_time': dateTimeToJson(endTime),
    'status': status.toJson(),
    'data_sharing_approved': dataSharingApproved,
    'data_sharing_approved_at': dateTimeToJson(dataSharingApprovedAt),
    'trainer_id': trainerId,
    'client_id': clientId,
    'client_name': clientName,
    'client_email': clientEmail,
    'client_notes': clientNotes,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 12.2 Event

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `title` | `String` | `title` | |
| `description` | `String?` | `description` | Text |
| `startTime` | `DateTime` | `start_time` | |
| `endTime` | `DateTime` | `end_time` | |
| `locationName` | `String?` | `location_name` | |
| `address` | `String?` | `address` | |
| `city` | `String?` | `city` | |
| `latitude` | `double?` | `latitude` | |
| `longitude` | `double?` | `longitude` | |
| `price` | `double` | `price` | Decimal, default 0 |
| `currency` | `String` | `currency` | default `"PLN"` |
| `capacity` | `int` | `capacity` | default 20 |
| `enrolledCount` | `int` | `enrolled_count` | default 0 |
| `category` | `String?` | `category` | |
| `imageUrl` | `String?` | `image_url` | |
| `isPromoted` | `bool` | `is_promoted` | default `false` |
| `status` | `EventStatus` | `status` | default `PENDING` |
| `rejectionReason` | `String?` | `rejection_reason` | Text |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

### 12.3 EventBooking

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `eventId` | `String` | `event_id` | FK → Event |
| `userId` | `String` | `user_id` | FK → User |
| `status` | `String` | `status` | default `"CONFIRMED"` |
| `paymentStatus` | `String` | `payment_status` | `"PENDING"`, `"PAID"`, `"FREE"` |
| `amountPaid` | `double` | `amount_paid` | Decimal, default 0 |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Unique:** `[eventId, userId]`

---

## 13. Monetization Models

### 13.1 Package

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | |
| `description` | `String?` | `description` | Text |
| `price` | `double` | `price` | Decimal(10,2) |
| `numberOfSessions` | `int` | `number_of_sessions` | |
| `isActive` | `bool` | `is_active` | default `true` |
| `stripeProductId` | `String` | `stripe_product_id` | `@unique` |
| `stripePriceId` | `String` | `stripe_price_id` | `@unique` |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

### 13.2 ClientPackage

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `packageId` | `String` | `package_id` | FK → Package |
| `sessionsRemaining` | `int` | `sessions_remaining` | |
| `purchaseDate` | `DateTime` | `purchase_date` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

---

## 14. Nutrition Models

### 14.1 Recipe

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `name` | `String` | `name` | |
| `description` | `String?` | `description` | Text |
| `instructions` | `String?` | `instructions` | Text |
| `proteinG` | `double?` | `protein_g` | |
| `carbsG` | `double?` | `carbs_g` | |
| `fatG` | `double?` | `fat_g` | |
| `calories` | `int?` | `calories` | |
| `difficulty` | `String?` | `difficulty` | `"easy"`, `"medium"`, `"hard"` |
| `prepTime` | `int?` | `prep_time` | Minutes |
| `cookTime` | `int?` | `cook_time` | Minutes |
| `isPublished` | `bool` | `is_published` | default `false` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Recipe {
  final String id;
  final String trainerId;
  final String name;
  final String? description;
  final String? instructions;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int? calories;
  final String? difficulty;
  final int? prepTime;
  final int? cookTime;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Recipe({ /* all fields */ });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    trainerId: json['trainer_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    instructions: json['instructions'] as String?,
    proteinG: (json['protein_g'] as num?)?.toDouble(),
    carbsG: (json['carbs_g'] as num?)?.toDouble(),
    fatG: (json['fat_g'] as num?)?.toDouble(),
    calories: json['calories'] as int?,
    difficulty: json['difficulty'] as String?,
    prepTime: json['prep_time'] as int?,
    cookTime: json['cook_time'] as int?,
    isPublished: (json['is_published'] as bool?) ?? false,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trainer_id': trainerId,
    'name': name,
    'description': description,
    'instructions': instructions,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'calories': calories,
    'difficulty': difficulty,
    'prep_time': prepTime,
    'cook_time': cookTime,
    'is_published': isPublished,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 14.2 RecipeTag

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `recipeId` | `String` | `recipe_id` | FK → Recipe |
| `name` | `String` | `name` | e.g. `"High Protein"` |

### 14.3 Product

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `recipeId` | `String` | `recipe_id` | FK → Recipe |
| `name` | `String` | `name` | |
| `brand` | `String?` | `brand` | |
| `amount` | `String?` | `amount` | e.g. `"200g"` |
| `isRecommended` | `bool` | `is_recommended` | default `false` |

---

## 15. Habit Models

### 15.1 DailyHabit

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `clientId` | `String` | `client_id` | FK → Client |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `title` | `String` | `title` | |
| `description` | `String?` | `description` | Text |
| `frequency` | `HabitFrequency` | `frequency` | default `DAILY` |
| `isActive` | `bool` | `is_active` | default `true` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class DailyHabit {
  final String id;
  final String clientId;
  final String trainerId;
  final String title;
  final String? description;
  final HabitFrequency frequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DailyHabit({ /* all fields */ });

  factory DailyHabit.fromJson(Map<String, dynamic> json) => DailyHabit(
    id: json['id'] as String,
    clientId: json['client_id'] as String,
    trainerId: json['trainer_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    frequency: HabitFrequency.fromJson(json['frequency'] as String? ?? 'DAILY'),
    isActive: (json['is_active'] as bool?) ?? true,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'trainer_id': trainerId,
    'title': title,
    'description': description,
    'frequency': frequency.toJson(),
    'is_active': isActive,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 15.2 HabitLog

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `habitId` | `String` | `habit_id` | FK → DailyHabit |
| `clientId` | `String` | `client_id` | FK → Client |
| `date` | `DateTime` | `date` | Date only |
| `isCompleted` | `bool` | `is_completed` | default `false` |
| `note` | `String?` | `note` | Text |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Unique:** `[habitId, clientId, date]`

---

## 16. Content Models

### 16.1 Resource

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `trainerId` | `String` | `trainer_id` | FK → User |
| `title` | `String` | `title` | |
| `description` | `String?` | `description` | Text |
| `fileUrl` | `String` | `file_url` | |
| `fileType` | `String` | `file_type` | `"PDF"`, `"VIDEO"`, `"LINK"` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Resource {
  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Resource({ /* all fields */ });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    id: json['id'] as String,
    trainerId: json['trainer_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    fileUrl: json['file_url'] as String,
    fileType: json['file_type'] as String,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trainer_id': trainerId,
    'title': title,
    'description': description,
    'file_url': fileUrl,
    'file_type': fileType,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 16.2 ClientResource

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `resourceId` | `String` | `resource_id` | FK → Resource |
| `clientId` | `String` | `client_id` | FK → Client |
| `createdAt` | `DateTime` | `created_at` | |

**Unique:** `[resourceId, clientId]`

---

## 17. System Models

### 17.1 Notification

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `userId` | `String` | `user_id` | FK → User |
| `message` | `String` | `message` | |
| `type` | `String` | `type` | `"milestone"`, `"system"`, `"reminder"` |
| `readStatus` | `bool` | `read_status` | default `false` |
| `metadata` | `Map<String, dynamic>?` | `metadata` | JSON |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `deletedAt` | `DateTime?` | `deleted_at` | |

```dart
class Notification {
  final String id;
  final String userId;
  final String message;
  final String type;
  final bool readStatus;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Notification({ /* all fields */ });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    message: json['message'] as String,
    type: json['type'] as String,
    readStatus: (json['read_status'] as bool?) ?? false,
    metadata: json['metadata'] as Map<String, dynamic>?,
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
    deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'message': message,
    'type': type,
    'read_status': readStatus,
    'metadata': metadata,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

### 17.2 SystemError

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `message` | `String` | `message` | Text |
| `stack` | `String?` | `stack` | Text |
| `path` | `String?` | `path` | |
| `method` | `String?` | `method` | |
| `statusCode` | `int?` | `status_code` | |
| `userId` | `String?` | `user_id` | FK → User |
| `isRead` | `bool` | `is_read` | default `false` |
| `metadata` | `Map<String, dynamic>?` | `metadata` | JSON |
| `errorType` | `String?` | `error_type` | `"Validation"`, `"Database"`, `"Network"` |
| `severity` | `String?` | `severity` | default `"error"` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

### 17.3 SystemSetting

| Field | Type | Wire | Notes |
|---|---|---|---|
| `key` | `String` | `key` | Primary key |
| `value` | `String` | `value` | Stored as string, cast manually |
| `description` | `String?` | `description` | |
| `updatedAt` | `DateTime` | `updated_at` | |

### 17.4 BlogPost

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | UUID |
| `title` | `String` | `title` | |
| `slug` | `String` | `slug` | `@unique` |
| `content` | `String` | `content` | |
| `excerpt` | `String?` | `excerpt` | |
| `coverImage` | `String?` | `cover_image` | |
| `published` | `bool` | `published` | default `false` |
| `authorId` | `String` | `author_id` | FK → User |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |
| `publishedAt` | `DateTime?` | `published_at` | |

### 17.5 SupportTicket

| Field | Type | Wire | Notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `userId` | `String` | `user_id` | FK → User |
| `category` | `SupportTicketCategory` | `category` | |
| `message` | `String` | `message` | Text |
| `appVersion` | `String?` | `app_version` | |
| `osVersion` | `String?` | `os_version` | |
| `status` | `String` | `status` | `"OPEN"`, `"IN_PROGRESS"`, `"RESOLVED"`, `"CLOSED"` |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

```dart
class SupportTicket {
  final String id;
  final String userId;
  final SupportTicketCategory category;
  final String message;
  final String? appVersion;
  final String? osVersion;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({ /* all fields */ });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    category: SupportTicketCategory.fromJson(json['category'] as String),
    message: json['message'] as String,
    appVersion: json['app_version'] as String?,
    osVersion: json['os_version'] as String?,
    status: (json['status'] as String?) ?? 'OPEN',
    createdAt: dateTimeFromJson(json['created_at'] as int),
    updatedAt: dateTimeFromJson(json['updated_at'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category': category.toJson(),
    'message': message,
    'app_version': appVersion,
    'os_version': osVersion,
    'status': status,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
```

---

## 18. Complete Quick-Reference: Field Counts

| # | Model | Section | Fields | Soft delete | Relations |
|---|---|---|---|---|---|
| 1 | `User` | 3.1 | 24 | ❌ | Profile, Client, Notification, Booking, Exercise, WorkoutProgram, Package, Assessment, CheckIn, Conversation, Event, EventBooking, SupportTicket, Recipe, DailyHabit, Resource, BlogPost, SystemError |
| 2 | `Profile` | 3.2 | 26 | ✅ | Location, Service, Testimonial, TransformationPhoto, SocialLink, ExternalLink, Benefit |
| 3 | `Location` | 4.1 | 9 | ✅ | — |
| 4 | `Service` | 4.2 | 10 | ✅ | — |
| 5 | `Testimonial` | 4.3 | 8 | ✅ | — |
| 6 | `TransformationPhoto` | 4.4 | 9 | ✅ | CheckIn |
| 7 | `SocialLink` | 4.5 | 8 | ✅ | — |
| 8 | `ExternalLink` | 4.6 | 7 | ✅ | — |
| 9 | `Benefit` | 4.7 | 10 | ✅ | — |
| 10 | `Client` | 5.1 | 20 | ✅ | ClientMeasurement, ClientProgressPhoto, ClientExerciseLog, WorkoutSession, ClientProgramAssignment, PersonalRecord, ClientPackage, AssessmentResult, CheckIn, Conversation, DailyHabit, HabitLog, ClientResource |
| 11 | `ClientMeasurement` | 5.2 | 10 | ✅ | — |
| 12 | `ClientProgressPhoto` | 5.3 | 9 | ✅ | CheckIn |
| 13 | `Exercise` | 6.1 | 12 | ✅ | ClientExerciseLog, TemplateExercise, PersonalRecord |
| 14 | `ClientExerciseLog` | 6.2 | 14 | ✅ | Client, Exercise, WorkoutSession |
| 15 | `WorkoutSession` | 6.3 | 16 | ✅ | Client, ClientExerciseLog, WorkoutTemplate, PersonalRecord, WorkoutSessionComment, ClientPackage |
| 16 | `WorkoutSessionComment` | 6.4 | 8 | ✅ | WorkoutSession, User |
| 17 | `WorkoutProgram` | 7.1 | 8 | ✅ | WorkoutTemplate, ClientProgramAssignment |
| 18 | `WorkoutTemplate` | 7.2 | 8 | ✅ | TemplateExercise, WorkoutSession |
| 19 | `TemplateExercise` | 7.3 | 16 | ✅ | Exercise |
| 20 | `ClientProgramAssignment` | 7.4 | 9 | ✅ | Client, WorkoutProgram |
| 21 | `PersonalRecord` | 8.1 | 8 | ✅ (partial) | Client, Exercise, WorkoutSession |
| 22 | `Assessment` | 9.1 | 8 | ✅ | — |
| 23 | `AssessmentResult` | 9.2 | 9 | ✅ | Assessment, Client |
| 24 | `CheckIn` | 10.1 | 17 | ❌ | Client, ClientProgressPhoto |
| 25 | `Conversation` | 11.1 | 6 | ❌ | Message |
| 26 | `Message` | 11.2 | 10 | ❌ | Conversation |
| 27 | `Booking` | 12.1 | 14 | ✅ | User |
| 28 | `Event` | 12.2 | 18 | ❌ | EventBooking |
| 29 | `EventBooking` | 12.3 | 8 | ❌ | Event, User |
| 30 | `Package` | 13.1 | 12 | ✅ | ClientPackage |
| 31 | `ClientPackage` | 13.2 | 9 | ✅ | WorkoutSession |
| 32 | `Recipe` | 14.1 | 16 | ✅ | RecipeTag, Product |
| 33 | `RecipeTag` | 14.2 | 3 | ❌ | — |
| 34 | `Product` | 14.3 | 6 | ❌ | — |
| 35 | `DailyHabit` | 15.1 | 10 | ✅ | HabitLog |
| 36 | `HabitLog` | 15.2 | 8 | ❌ | — |
| 37 | `Resource` | 16.1 | 9 | ✅ | ClientResource |
| 38 | `ClientResource` | 16.2 | 4 | ❌ | — |
| 39 | `Notification` | 17.1 | 9 | ✅ | — |
| 40 | `SystemError` | 17.2 | 12 | ❌ | User |
| 41 | `SystemSetting` | 17.3 | 4 | ❌ | — |
| 42 | `BlogPost` | 17.4 | 11 | ❌ | User |
| 43 | `SupportTicket` | 17.5 | 8 | ❌ | User |

**Total: 43 models** (30+ Prisma models plus implicit join-table representations)

---

## 19. Sync Protocol Reference

> **IMPORTANT:** The backend uses a unified pull/push sync API, NOT per-table endpoints.
> See `OFFLINE_SYNC.md` for the complete Flutter sync implementation and Drift schema.

### Sync API (Backend)

The backend at `zirofit-next` provides two endpoints for offline-first sync:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/sync/pull?last_pulled_at={timestamp}` | Pull all changes since `last_pulled_at` (Unix ms) |
| POST | `/api/sync/push` | Push local changes to server |

### Wire Format

- **Keys**: `snake_case` on the wire (converted to `camelCase` in Dart)
- **Dates**: Unix timestamps in **milliseconds** (integers, not ISO strings)
- **Deletions**: Soft deletes via `deleted_at` field (Unix ms or null)
- **Conflict resolution**: Last-write-wins (server compares `updated_at`)

### The 17 Sync Tables

The backend's `SYNC_TABLES` constant in `src/lib/sync/utils.ts` defines these 17 tables:

| # | Sync Table Name | Prisma Model | Direction | Scope |
|---|----------------|-------------|-----------|-------|
| 1 | `clients` | Client | Bidirectional | Trainer's client records |
| 2 | `profiles` | Profile | Bidirectional | Own user profile (mobile) |
| 3 | `trainer_profiles` | Profile | Bidirectional | Trainer's professional profile |
| 4 | `workout_sessions` | WorkoutSession | Bidirectional | Sessions for trainer's clients |
| 5 | `exercises` | Exercise | Download-only | System exercises + custom ones |
| 6 | `workout_templates` | WorkoutTemplate | Bidirectional | Templates from trainer's programs |
| 7 | `client_assessments` | AssessmentResult | Bidirectional | Assessment results for clients |
| 8 | `client_measurements` | ClientMeasurement | Bidirectional | Body measurements for clients |
| 9 | `client_photos` | ClientProgressPhoto | Download-only | Progress photo URLs (not binary) |
| 10 | `client_exercise_logs` | ClientExerciseLog | Bidirectional | Exercise log entries |
| 11 | `trainer_services` | Service | Bidirectional | Services on trainer's profile |
| 12 | `trainer_packages` | Package | Bidirectional | Session packages sold by trainer |
| 13 | `trainer_testimonials` | Testimonial | Bidirectional | Client testimonials |
| 14 | `trainer_programs` | WorkoutProgram | Bidirectional | Programs created by trainer |
| 15 | `calendar_events` | Booking | Bidirectional | Booked time slots |
| 16 | `notifications` | Notification | Download-only | User notifications |
| 17 | `bookings` | Booking | Bidirectional | Client booking requests |

### Sync Flow

```
1. APP START → Read lastPulledAt from local storage
2. PUSH → POST /api/sync/push { changes: { ... } }
   Send local mutations first so server has latest data
3. PULL → GET /api/sync/pull?last_pulled_at={lastPulledAt}
   Single response contains changes for ALL 17 tables:
   { changes: { clients: { created, updated, deleted }, ... }, timestamp }
4. APPLY → For each table:
   - created[] → INSERT into local Drift DB
   - updated[] → UPSERT (last-write-wins)
   - deleted[] → soft delete (set deletedAt)
5. SAVE → Store response.timestamp as new lastPulledAt
```

### Non-Synced Data

The following models are NOT part of the sync protocol. They are fetched directly via their respective API endpoints:

All models not in the 17-table list above (User, Location, TransformationPhoto, SocialLink, ExternalLink, Benefit, WorkoutSessionComment, TemplateExercise, ClientProgramAssignment, PersonalRecord, Assessment, Conversation, Message, Event, EventBooking, ClientPackage, Recipe, RecipeTag, Product, DailyHabit, HabitLog, Resource, ClientResource, SystemError, SystemSetting, BlogPost, SupportTicket, CheckIn) are NOT synced via the pull/push API. They are fetched on-demand through their dedicated API endpoints or are created/managed server-side only (e.g., PersonalRecords, SystemErrors).

### Data Flow Examples

**Online write:**
```
User action → Repository → API call → Backend
                         → Drift local DB (update)
```

**Offline write:**
```
User action → Repository → Drift local DB (save with syncStatus=PENDING)
                         → Sync Queue (store mutation)
When online: Sync Engine → Push → Pull → Update Drift
```

**Read:**
```
Screen → Provider → Repository → Drift local DB (always read from local)
If stale data, background refresh via pull on next sync cycle
```

---

## 20. JSON Serialization Pattern (Reference)

Every model follows this exact pattern:

```dart
@JsonSerializable() // if using json_serializable package, else manual:
class ModelName {
  final String id;
  // ...

  const ModelName({required this.id, /* ... */});

  factory ModelName.fromJson(Map<String, dynamic> json) => ModelName(
    id: json['id'] as String,
    stringField: json['string_field'] as String,
    nullableString: json['nullable_string'] as String?,
    intField: json['int_field'] as int,
    doubleField: (json['double_field'] as num?)?.toDouble(),
    boolField: (json['bool_field'] as bool?) ?? false,
    dateTimeField: dateTimeFromJson(json['date_time_field'] as int),
    nullableDateTime: dateTimeFromJsonOrNull(json['nullable_date_time_field'] as int?),
    enumField: SomeEnum.fromJson(json['enum_field'] as String),
    stringList: (json['string_list'] as List<dynamic>?)?.cast<String>() ?? const [],
    enumList: (json['enum_list'] as List<dynamic>?)
        ?.map((e) => SomeEnum.fromJson(e as String))
        .toList() ?? const [],
    mapField: json['map_field'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'string_field': stringField,
    'nullable_string': nullableString,
    'int_field': intField,
    'double_field': doubleField,
    'bool_field': boolField,
    'date_time_field': dateTimeToJson(dateTimeField),
    'nullable_date_time_field': dateTimeToJson(nullableDateTime),
    'enum_field': enumField.toJson(),
    'string_list': stringList,
    'enum_list': enumList.map((e) => e.toJson()).toList(),
    'map_field': mapField,
    // timestamps
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };
}
```

---

## Appendix: Shared Utility Functions

These functions are used across all models and should live in a shared utility file (e.g., `lib/core/utils/json_utils.dart`):

```dart
/// Converts a [DateTime] to a Unix millisecond timestamp (or null).
int? dateTimeToJson(DateTime? dt) => dt?.millisecondsSinceEpoch;

/// Converts a Unix millisecond timestamp to [DateTime].
DateTime dateTimeFromJson(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms);

/// Converts a nullable Unix millisecond timestamp to nullable [DateTime].
DateTime? dateTimeFromJsonOrNull(int? ms) =>
    ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

/// Safely casts a JSON list to a typed Dart list.
List<T> listFromJson<T>(List<dynamic>? json, T Function(dynamic) fromItem) =>
    json?.map(fromItem).toList() ?? [];
```

---

> **End of DATA_MODELS.md** — 43 models documented, 9 enums defined, complete JSON serialization for every field.
