# Ziro Fit — Offline-First Sync Strategy

> **Purpose:** Complete blueprint for implementing offline-first data synchronization in the Ziro Fit Flutter app. Defines the local database schema, sync engine architecture, conflict resolution, queuing strategy, and connectivity management — all designed around the existing sync API in the `zirofit-next` backend.
>
> **Last updated:** 2026-05-01
>
> **Related docs:** `ARCHITECTURE.md` (layered architecture), `DATA_MODELS.md` (Dart data classes), `API_REFERENCE.md` (REST endpoints including sync)

---

## Table of Contents

1. [Sync Architecture Overview](#1-sync-architecture-overview)
2. [Wire Protocol](#2-wire-protocol)
3. [Local Database Design (Drift)](#3-local-database-design-drift)
4. [Sync Status Tracking](#4-sync-status-tracking)
5. [Sync Engine Design](#5-sync-engine-design)
6. [Pull Strategy](#6-pull-strategy)
7. [Push Strategy](#7-push-strategy)
8. [Offline Mutation Queue](#8-offline-mutation-queue)
9. [Conflict Resolution](#9-conflict-resolution)
10. [Connectivity Management](#10-connectivity-management)
11. [Sync Trigger Matrix](#11-sync-trigger-matrix)
12. [Initial Sync / App Bootstrap](#12-initial-sync--app-bootstrap)
13. [Sync Repository Implementation](#13-sync-repository-implementation)
14. [Sync Status UI](#14-sync-status-ui)
15. [Error Handling & Retry](#15-error-handling--retry)
16. [Non-Synced Data](#16-non-synced-data)
17. [Backend Sync API Reference](#17-backend-sync-api-reference)
18. [Testing Sync](#18-testing-sync)
19. [Implementation Checklist](#19-implementation-checklist)

---

## 1. Sync Architecture Overview

### 1.1 Goal

Users of the Ziro Fit app can **read and write data even without an internet connection**. All mutations are queued locally and synchronized with the backend when connectivity is restored. Reads always hit the local database first (offline-first), with the sync engine keeping the local copy up to date.

### 1.2 Design Decision

**Use the backend's existing sync API (pull/push) — do not build a custom sync protocol.**

The `zirofit-next` backend already has a complete sync engine with:
- `GET /api/sync/pull?last_pulled_at={timestamp}` — fetch all changes since timestamp
- `POST /api/sync/push` — push local changes to the server

The Flutter app consumes these endpoints directly. No WebSockets, no custom server logic, no WatermelonDB.

### 1.3 Key Components

| Component | Responsibility | Package / File |
|-----------|---------------|----------------|
| **SyncEngine** | Orchestrates full sync cycles (push → pull) | `data/sync/sync_engine.dart` |
| **SyncQueue** | Persistent FIFO queue of offline mutations | `data/sync/sync_queue.dart` |
| **ConnectivityManager** | Monitors network state via connectivity_plus | `data/sync/connectivity_manager.dart` |
| **ConflictResolver** | Last-write-wins logic for pull conflicts | `data/sync/conflict_resolver.dart` |
| **SyncMetadata** | Tracks last sync timestamps per table | `data/sync/sync_metadata.dart` |
| **SyncRemoteSource** | HTTP calls to pull/push endpoints | `data/datasources/remote/sync_remote_source.dart` |
| **SyncLocalSource** | Read/write access to local Drift tables | `data/datasources/local/sync_local_source.dart` |
| **SyncRepository** | Single entry point for all sync operations | `data/repositories/sync_repository.dart` |
| **AppDatabase** | Drift database with all 17+ sync table definitions | `core/database/app_database.dart` |

### 1.4 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SYNC ENGINE FLOW                                │
│                                                                         │
│  ┌──────────────┐     trigger     ┌─────────────────────────────┐      │
│  │  Connectivity ├───────────────►│        SyncEngine           │      │
│  │  Manager      │  online/offline│                             │      │
│  └──────────────┘                │  sync()                      │      │
│                                  │    ├─ pushPending()          │      │
│  ┌──────────────┐                │    │    ├─ read SyncQueue    │      │
│  │  SyncQueue   │◄───────────────┤    │    ├─ POST /sync/push   │      │
│  │  (Drift)     │  queueMutation │    │    └─ markSynced()      │      │
│  └──────────────┘                │    │                          │      │
│                                  │    └─ pull()                 │      │
│  ┌──────────────┐                │         ├─ GET /sync/pull    │      │
│  │  SyncMeta-   │◄───────────────┤         ├─ upsertLocal()     │      │
│  │  data        │  lastPulledAt  │         └─ saveTimestamp()   │      │
│  │  (Prefs)     │                └──────────┬──────────────────┘      │
│  └──────────────┘                           │                          │
│                                             │                          │
│  ┌──────────────┐            ┌──────────────▼──────────────┐           │
│  │  Drift DB    │◄───────────┤      ConflictResolver       │           │
│  │  17 Tables   │  upsert    │  (last-write-wins)          │           │
│  └──────────────┘            └─────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.5 Offline Mutation Flow

```
┌──────────┐     ┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Screen  │────►│  Repository  │────►│   Local DB       │     │  SyncQueue   │
│  (Form)  │     │              │     │  (optimistic)    │     │  (pendings)  │
└──────────┘     └──────────────┘     └──────────────────┘     └──────┬───────┘
                                                                      │
                                                          ┌───────────▼────────┐
                                                          │  Connectivity      │
                                                          │  restored → trigger│
                                                          └───────────┬────────┘
                                                                      │
                                                          ┌───────────▼────────┐
                                                          │  SyncEngine        │
                                                          │  1. pushPending()  │
                                                          │  2. pull()         │
                                                          └────────────────────┘
```

---

## 2. Wire Protocol

### 2.1 Conventions

| Domain | Format |
|--------|--------|
| Field names | **snake_case** on the wire (API JSON) |
| Dates / Timestamps | **Unix milliseconds** (`Int64`) — NOT ISO strings |
| IDs | `String` (cuid or UUID) |
| Nullable fields | Absent or `null` |
| Soft delete | `deletedAt` as Unix ms or `null` |
| Enums | PascalCase strings (e.g. `"IN_PROGRESS"`, `"PENDING"`) |
| Nested objects | Flat — no nested relations in sync payload |
| Empty arrays | `[]` (backend never omits arrays) |

### 2.2 Pull Response Shape

```json
{
  "data": {
    "changes": {
      "clients": {
        "created": [{ "id": "xxx", "name": "John", "created_at": 1700000000000, "updated_at": 1700000000000, "deleted_at": null, ... }],
        "updated": [{ ... }],
        "deleted": ["id1", "id2"]
      },
      "profiles": { "created": [], "updated": [], "deleted": [] },
      "trainer_profiles": { "created": [], "updated": [], "deleted": [] },
      "workout_sessions": { "created": [], "updated": [], "deleted": [] },
      "exercises": { "created": [], "updated": [], "deleted": [] },
      "workout_templates": { "created": [], "updated": [], "deleted": [] },
      "client_assessments": { "created": [], "updated": [], "deleted": [] },
      "client_measurements": { "created": [], "updated": [], "deleted": [] },
      "client_photos": { "created": [], "updated": [], "deleted": [] },
      "client_exercise_logs": { "created": [], "updated": [], "deleted": [] },
      "trainer_services": { "created": [], "updated": [], "deleted": [] },
      "trainer_packages": { "created": [], "updated": [], "deleted": [] },
      "trainer_testimonials": { "created": [], "updated": [], "deleted": [] },
      "trainer_programs": { "created": [], "updated": [], "deleted": [] },
      "calendar_events": { "created": [], "updated": [], "deleted": [] },
      "notifications": { "created": [], "updated": [], "deleted": [] },
      "bookings": { "created": [], "updated": [], "deleted": [] }
    },
    "timestamp": 1700000000000
  }
}
```

### 2.3 Push Request Shape

```json
{
  "changes": {
    "clients": {
      "created": [{ ... }],
      "updated": [{ ... }],
      "deleted": ["id1"]
    },
    ...
  }
}
```

### 2.4 Push Response Shape

```json
{
  "data": {
    "timestamp": 1700000000001
  }
}
```

### 2.5 Backend Data Transformation Summary

| Direction | Transformation | Backend Utility |
|-----------|---------------|-----------------|
| Pull (server → client) | `camelCase` → `snake_case` field names | `objectKeysToSnake()` |
| Pull (server → client) | `DateTime` → Unix ms integer | `convertDatesToTimestamps()` |
| Push (client → server) | `snake_case` → `camelCase` field names | `objectKeysToCamel()` |
| Push (client → server) | Unix ms integer → `DateTime` | `convertTimestampsToDates()` |

---

## 3. Local Database Design (Drift)

### 3.1 Database Conventions

All 17 sync tables mirror their Prisma counterparts and follow these rules:

- **Table name**: snake_case matching the sync wire name (e.g. `clients`, `workout_sessions`)
- **Primary key**: `id` (`TEXT`, non-nullable)
- **Timestamps**: `createdAt`, `updatedAt` as `Int64` (Unix ms, non-nullable)
- **Soft delete**: `deletedAt` as `Int64?` (Unix ms or `null`)
- **Sync status**: `syncStatus` as `Int` (0=SYNCED, 1=PENDING_CREATE, 2=PENDING_UPDATE, 3=PENDING_DELETE)
- **Nullability**: Every column that is nullable in Prisma is nullable in the Drift table
- **Booleans**: Drift `BoolColumn` — stored as integer in SQLite
- **Lists**: Stored as JSON `TEXT` columns (Drift does not natively support arrays)
- **Floats**: `RealColumn` for `double?`, `Int64Column` for `int?`

### 3.2 Sync Status Enum

```dart
enum SyncStatus {
  synced(0),
  pendingCreate(1),
  pendingUpdate(2),
  pendingDelete(3);

  final int value;
  const SyncStatus(this.value);

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere((e) => e.value == value);
  }
}
```

### 3.3 Table Definitions

Below are all 17 Drift table definitions. Each is saved as a separate file in `lib/core/database/tables/`.

```dart
// ============================================================
// lib/core/database/tables/clients_table.dart
// ============================================================
import 'package:drift/drift.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get trainerId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get status => text()();
  Int64Column get dateOfBirth => int64().nullable()();
  TextColumn get goals => text().nullable()();
  TextColumn get healthNotes => text().nullable()();
  TextColumn get emergencyContactName => text().nullable()();
  TextColumn get emergencyContactPhone => text().nullable()();
  IntColumn get checkInDay => integer().nullable()();
  IntColumn get checkInHour => integer().nullable()();
  Int64Column get dataSharingExpiresAt => int64().nullable()();
  TextColumn get sharingSettings => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/profiles_table.dart
// ============================================================
class Profiles extends Table {
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

// ============================================================
// lib/core/database/tables/trainer_profiles_table.dart
// ============================================================
/// Mirrors the profiles table but scoped to the trainer's own profile.
/// Both "profiles" and "trainer_profiles" map to the same Prisma Profile model.
/// On the client, they are stored as separate Drift tables to match the sync API.
class TrainerProfiles extends Table {
  // Same columns as Profiles
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
  TextColumn get specialties => text().withDefault(const Constant('[]'))();
  TextColumn get trainingTypes => text().withDefault(const Constant('[]'))();
  TextColumn get businessCurrency => text().withDefault(const Constant('PLN'))();
  RealColumn get averageRating => real().nullable()();
  IntColumn get completionPercentage => integer().withDefault(const Constant(0))();
  TextColumn get missingFields => text().nullable()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  TextColumn get availability => text().nullable()();
  RealColumn get minServicePrice => real().nullable()();
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

// ============================================================
// lib/core/database/tables/workout_sessions_table.dart
// ============================================================
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get name => text().nullable()();
  Int64Column get startTime => int64()();
  Int64Column? get endTime => int64().nullable()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  Int64Column? get restStartedAt => int64().nullable()();
  TextColumn get workoutTemplateId => text().nullable()();
  Int64Column? get plannedDate => int64().nullable()();
  TextColumn get clientPackageId => text().nullable()();
  BoolColumn get isTrainerLed => boolean().withDefault(const Constant(false))();
  Int64Column? get reminderTime => int64().nullable()();
  BoolColumn get trainerReminderSent => boolean().withDefault(const Constant(false))();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/exercises_table.dart
// ============================================================
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get createdById => text().nullable()();
  IntColumn get recommendedRestSeconds => integer().nullable()();
  BoolColumn get isUnilateral => boolean().withDefault(const Constant(false))();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/workout_templates_table.dart
// ============================================================
class WorkoutTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get programId => text()();
  IntColumn get order => integer().withDefault(const Constant(0))();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/client_assessments_table.dart
// ============================================================
class ClientAssessments extends Table {
  TextColumn get id => text()();
  TextColumn get assessmentId => text()();
  TextColumn get clientId => text()();
  RealColumn get value => real()();
  Int64Column get date => int64()();
  TextColumn get notes => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/client_measurements_table.dart
// ============================================================
class ClientMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  Int64Column get measurementDate => int64()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPercentage => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get customMetrics => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/client_photos_table.dart
// ============================================================
class ClientPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  Int64Column get photoDate => int64()();
  TextColumn get imagePath => text()();
  TextColumn get caption => text().nullable()();
  TextColumn get checkInId => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/client_exercise_logs_table.dart
// ============================================================
class ClientExerciseLogs extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  BoolColumn get isCompleted => boolean().nullable()();
  IntColumn get order => integer().nullable()();
  TextColumn get tempo => text().nullable()();
  TextColumn get side => text().withDefault(const Constant('BOTH'))();
  TextColumn get workoutSessionId => text()();
  TextColumn get supersetKey => text().nullable()();
  IntColumn get orderInSuperset => integer().nullable()();
  TextColumn get sets => text().nullable()(); // DEPRECATED JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/trainer_services_table.dart
// ============================================================
class TrainerServices extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get price => real().nullable()();
  TextColumn get currency => text().nullable()();
  IntColumn get duration => integer().nullable()(); // minutes

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/trainer_packages_table.dart
// ============================================================
class TrainerPackages extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  IntColumn get numberOfSessions => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get stripeProductId => text()();
  TextColumn get stripePriceId => text()();
  TextColumn get trainerId => text()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/trainer_testimonials_table.dart
// ============================================================
class TrainerTestimonials extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get clientName => text()();
  TextColumn get testimonialText => text()();
  IntColumn get rating => integer().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/trainer_programs_table.dart
// ============================================================
class TrainerPrograms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get trainerId => text().nullable()();
  TextColumn get category => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/calendar_events_table.dart
// ============================================================
class CalendarEvents extends Table {
  TextColumn get id => text()();
  Int64Column get startTime => int64()();
  Int64Column get endTime => int64()();
  TextColumn get status => text()();
  BoolColumn get dataSharingApproved => boolean().nullable().withDefault(const Constant(false))();
  Int64Column? get dataSharingApprovedAt => int64().nullable()();
  TextColumn get trainerId => text()();
  TextColumn get clientId => text().nullable()();
  TextColumn get clientName => text().nullable()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get clientNotes => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/notifications_table.dart
// ============================================================
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get message => text()();
  TextColumn get type => text()();
  BoolColumn get readStatus => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()(); // JSON

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// lib/core/database/tables/bookings_table.dart
// ============================================================
class Bookings extends Table {
  // Same schema as CalendarEvents — both map to the same Prisma Booking model.
  TextColumn get id => text()();
  Int64Column get startTime => int64()();
  Int64Column get endTime => int64()();
  TextColumn get status => text()();
  BoolColumn get dataSharingApproved => boolean().nullable().withDefault(const Constant(false))();
  Int64Column? get dataSharingApprovedAt => int64().nullable()();
  TextColumn get trainerId => text()();
  TextColumn get clientId => text().nullable()();
  TextColumn get clientName => text().nullable()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get clientNotes => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3.4 Drift Database Class

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Clients,
    Profiles,
    TrainerProfiles,
    WorkoutSessions,
    Exercises,
    WorkoutTemplates,
    ClientAssessments,
    ClientMeasurements,
    ClientPhotos,
    ClientExerciseLogs,
    TrainerServices,
    TrainerPackages,
    TrainerTestimonials,
    TrainerPrograms,
    CalendarEvents,
    Notifications,
    Bookings,
    SyncQueueItems, // defined in section 8
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    final dbPath = getApplicationDocumentsDirectory()
        .then((dir) => p.join(dir.path, 'zirofit.db'));
    // Lazy initialization handled by Drift
    return NativeDatabase(File(dbPath.toString()));
  }
}
```

### 3.5 Table-to-Model Mapping

| Sync Table Name | Drift Table Class | Prisma Model | Dart Data Class |
|----------------|-------------------|--------------|-----------------|
| `clients` | `Clients` | `Client` | `Client` |
| `profiles` | `Profiles` | `Profile` | `Profile` |
| `trainer_profiles` | `TrainerProfiles` | `Profile` | `Profile` |
| `workout_sessions` | `WorkoutSessions` | `WorkoutSession` | `WorkoutSession` |
| `exercises` | `Exercises` | `Exercise` | `Exercise` |
| `workout_templates` | `WorkoutTemplates` | `WorkoutTemplate` | `WorkoutTemplate` |
| `client_assessments` | `ClientAssessments` | `AssessmentResult` | `AssessmentResult` |
| `client_measurements` | `ClientMeasurements` | `ClientMeasurement` | `ClientMeasurement` |
| `client_photos` | `ClientPhotos` | `ClientProgressPhoto` | `ClientProgressPhoto` |
| `client_exercise_logs` | `ClientExerciseLogs` | `ClientExerciseLog` | `ClientExerciseLog` |
| `trainer_services` | `TrainerServices` | `Service` | `Service` |
| `trainer_packages` | `TrainerPackages` | `Package` | `Package` |
| `trainer_testimonials` | `TrainerTestimonials` | `Testimonial` | `Testimonial` |
| `trainer_programs` | `TrainerPrograms` | `WorkoutProgram` | `WorkoutProgram` |
| `calendar_events` | `CalendarEvents` | `Booking` | `Booking` |
| `notifications` | `Notifications` | `Notification` | `Notification` |
| `bookings` | `Bookings` | `Booking` | `Booking` |

---

## 4. Sync Status Tracking

Every synced record has a `syncStatus` integer column:

| Value | Enum | Meaning |
|-------|------|---------|
| `0` | `SYNCED` | In sync with server (last confirmed) |
| `1` | `PENDING_CREATE` | Created locally, not yet pushed to server |
| `2` | `PENDING_UPDATE` | Updated locally, not yet pushed to server |
| `3` | `PENDING_DELETE` | Deleted locally, deletion not yet pushed to server |

**Rules:**
- When a record is **pulled** from the server, `syncStatus` is always set to `SYNCED` (0).
- When a record is **created offline**, `syncStatus` is set to `PENDING_CREATE` (1).
- When a record is **updated offline**, `syncStatus` is set to `PENDING_UPDATE` (2). If it was already `PENDING_CREATE`, it stays `PENDING_CREATE` (no need to track both).
- When a record is **deleted offline**:
  - If `syncStatus` is `PENDING_CREATE` (never synced), the record is **deleted entirely from local DB** (no need to push a delete for something the server doesn't know about).
  - Otherwise, set `syncStatus` to `PENDING_DELETE` (3) and keep the record (will soft-delete on server).
- After a **successful push**, all pushed records are marked `SYNCED` (0). For `PENDING_DELETE` records, they are removed from the local DB after the server confirms the soft-delete.

---

## 5. Sync Engine Design

### 5.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        SyncEngine                               │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   PullHandler   │  │   PushHandler   │  │ ConflictResolver │ │
│  │                 │  │                 │  │                 │ │
│  │ - GET /sync/pull│  │ - read queue    │  │ - compare       │ │
│  │ - upsert to DB  │  │ - POST /push    │  │   updatedAt     │ │
│  │ - save timestamp│  │ - mark synced   │  │ - keep newer    │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                     │          │
│  ┌────────▼────────┐  ┌───────▼────────┐  ┌─────────▼───────┐  │
│  │ SyncLocalSource │  │ SyncQueue      │  │ SyncMetadata   │  │
│  │ (Drift DAO)     │  │ (Drift table)  │  │ (SharedPrefs)  │  │
│  └─────────────────┘  └────────────────┘  └─────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              ConnectivityManager                         │   │
│  │  (connectivity_plus → Stream<bool> isOnline)             │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 SyncEngine Class

```dart
// lib/data/sync/sync_engine.dart

class SyncEngine {
  final SyncRemoteSource _remote;
  final SyncLocalSource _local;
  final SyncQueue _queue;
  final SyncMetadata _metadata;
  final ConnectivityManager _connectivity;
  final ConflictResolver _conflictResolver;

  final _statusController = StreamController<SyncUiStatus>.broadcast();
  Stream<SyncUiStatus> get statusStream => _statusController.stream;
  SyncUiStatus _currentStatus = SyncUiStatus.synced;

  SyncEngine({
    required SyncRemoteSource remote,
    required SyncLocalSource local,
    required SyncQueue queue,
    required SyncMetadata metadata,
    required ConnectivityManager connectivity,
    required ConflictResolver conflictResolver,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _metadata = metadata,
       _connectivity = connectivity,
       _conflictResolver = conflictResolver {
    _setupConnectivityListener();
  }

  /// Performs a full sync cycle: push pending mutations → pull latest data.
  Future<SyncResult> sync() async {
    if (!_connectivity.isOnline) {
      return SyncResult.failure('Device is offline');
    }

    _emitStatus(SyncUiStatus.syncing);

    try {
      // Step 1: Push pending mutations
      final pushResult = await _pushPending();

      // Step 2: Pull latest data from server
      final pullResult = await _pull();

      _emitStatus(SyncUiStatus.synced);
      return SyncResult.success(
        pushed: pushResult.mutationsCount,
        pulled: pullResult.recordsCount,
        timestamp: pullResult.timestamp,
      );
    } catch (e) {
      _emitStatus(SyncUiStatus.error);
      return SyncResult.failure(e.toString());
    }
  }

  /// Push all pending mutations to the server.
  Future<PushResult> _pushPending() async {
    final pendingItems = await _queue.getAllPending();
    if (pendingItems.isEmpty) {
      return PushResult.empty();
    }

    // Group pending items into push payload format
    final changes = _buildPushPayload(pendingItems);

    final response = await _remote.push(changes);

    // Mark all pushed items as synced
    for (final item in pendingItems) {
      if (item.operation == SyncOperation.delete) {
        // For deletes, remove the record from local DB entirely
        await _local.deleteRecord(item.tableName, item.recordId);
        await _queue.remove(item.id);
      } else {
        await _local.markSynced(item.tableName, item.recordId);
        await _queue.remove(item.id);
      }
    }

    // Update metadata with server timestamp
    await _metadata.updateLastPushedAt(response.timestamp);

    return PushResult(mutationsCount: pendingItems.length);
  }

  /// Pull all changes since the last sync timestamp.
  Future<PullResult> _pull() async {
    final lastPulledAt = await _metadata.getLastPulledAt();
    final response = await _remote.pull(lastPulledAt);

    int totalRecords = 0;

    for (final entry in response.changes.entries) {
      final tableName = entry.key;
      final changes = entry.value;

      // Process created records
      for (final record in changes.created) {
        await _conflictResolver.upsertOnPull(tableName, record);
        totalRecords++;
      }

      // Process updated records (with conflict resolution)
      for (final record in changes.updated) {
        await _conflictResolver.upsertOnPull(tableName, record);
        totalRecords++;
      }

      // Process deleted records
      for (final id in changes.deleted) {
        await _local.softDeleteRecord(tableName, id);
        totalRecords++;
      }
    }

    // Save the new timestamp
    await _metadata.updateLastPulledAt(response.timestamp);

    return PullResult(recordsCount: totalRecords, timestamp: response.timestamp);
  }

  /// Queue a local mutation for future push.
  Future<void> queueMutation({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    await _queue.add(SyncQueueItem(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      data: data,
    ));

    // If online, try to push immediately
    if (_connectivity.isOnline) {
      // Delay slightly to batch rapid mutations
      Future.delayed(const Duration(seconds: 1), () => sync());
    } else {
      _emitStatus(SyncUiStatus.pending);
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        // Grace period before syncing
        Future.delayed(const Duration(seconds: 2), () {
          if (_connectivity.isOnline) {
            sync();
          }
        });
      } else {
        _emitStatus(SyncUiStatus.offline);
      }
    });
  }

  void _emitStatus(SyncUiStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}
```

### 5.3 Supporting Types

```dart
// lib/data/sync/sync_engine.dart (types)

enum SyncOperation { create, update, delete }

enum SyncUiStatus {
  synced,    // All data up to date
  syncing,   // Sync in progress
  pending,   // Offline mutations pending
  error,     // Last sync failed
  offline,   // Device is offline
}

class SyncResult {
  final bool isSuccess;
  final String? error;
  final int pushedCount;
  final int pulledCount;
  final int? timestamp;

  const SyncResult.success({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.timestamp,
  }) : isSuccess = true, error = null;

  const SyncResult.failure(this.error)
    : isSuccess = false,
      pushedCount = 0,
      pulledCount = 0,
      timestamp = null;

  static const empty = SyncResult.success();
}

class PushResult {
  final int mutationsCount;

  const PushResult({required this.mutationsCount});
  const PushResult.empty() : mutationsCount = 0;
}

class PullResult {
  final int recordsCount;
  final int timestamp;

  const PullResult({required this.recordsCount, required this.timestamp});
}
```

---

## 6. Pull Strategy

### 6.1 When to Pull

| Trigger | Behavior | Priority |
|---------|----------|----------|
| **App cold start** | `pull(lastPulledAt: 0)` for fresh install, incremental otherwise | **High** — blocks UI with loading screen |
| **App resume from background** | Incremental pull (after push if pending) | **Medium** — silent background fetch |
| **Periodic (every 5 min)** | Silent incremental pull while app is foregrounded | **Low** — debounced |
| **Pull-to-refresh** | User-initiated full push+pull | **User-initiated** — shows refresh indicator |
| **After successful push** | Always pull immediately after push to reconcile | **High** — needed for server-generated data (e.g., `createdAt`, IDs) |

### 6.2 Pull Flow

```
1. Read lastPulledAt from SharedPreferences (SyncMetadata)
2. GET /api/sync/pull?last_pulled_at={lastPulledAt}
3. For each table in response.changes:
   a. created[] → INSERT into local DB with syncStatus=SYNCED
   b. updated[] → Compare updatedAt:
        - If local.updatedAt > incoming.updatedAt → KEEP local (local is newer)
        - If incoming.updatedAt >= local.updatedAt → OVERWRITE with incoming
        - If local record doesn't exist → INSERT
   c. deleted[] → SET deletedAt = incoming deletedAt (soft delete)
4. Save response.timestamp as new lastPulledAt
5. Return PullResult with counts
```

### 6.3 Initial Sync (Fresh Install / First Launch)

```dart
Future<SyncResult> initialSync() async {
  _emitStatus(SyncUiStatus.syncing);

  try {
    // Fresh install: pull everything from the beginning of time
    final response = await _remote.pull(0);

    // Upsert all records
    for (final entry in response.changes.entries) {
      for (final record in entry.value.created) {
        await _local.upsertRecord(entry.key, record, syncStatus: SyncStatus.synced);
      }
      // updated and deleted arrays will be empty for lastPulledAt=0
    }

    await _metadata.updateLastPulledAt(response.timestamp);
    _emitStatus(SyncUiStatus.synced);

    return SyncResult.success(pulledCount: /* count all records */);
  } catch (e) {
    _emitStatus(SyncUiStatus.error);
    return SyncResult.failure(e.toString());
  }
}
```

**UX for initial sync:**
- Show a full-screen loading indicator with progress text (e.g., "Syncing your data...")
- If the user has no data, initial sync completes in <1s (most tables return empty arrays)
- System exercises and reference data are downloaded during initial sync
- On failure, show retry button — the app cannot function without initial sync completing

---

## 7. Push Strategy

### 7.1 When to Push

| Trigger | Behavior | Priority |
|---------|----------|----------|
| **Mutation while online** | Queue + immediate push (debounced 1s) | **High** |
| **Connectivity restored** | Process all queued mutations | **High** |
| **Periodic timer** | Check queue and push if non-empty | **Low** |
| **Before pull** | Always push pending before pulling | **Medium** |

### 7.2 Push Flow

```
1. Read ALL records from local DB where syncStatus != SYNCED
2. Group by tableName and operation (CREATE / UPDATE / DELETE)
3. Build the push payload:
   {
     "changes": {
       "clients": {
         "created": [...],  // records with PENDING_CREATE, full JSON
         "updated": [...],  // records with PENDING_UPDATE, full JSON
         "deleted": ["id"]  // records with PENDING_DELETE, just IDs
       },
       ...
     }
   }
4. POST /api/sync/push with the payload
5. On success (200):
   a. For PENDING_CREATE / PENDING_UPDATE → set syncStatus = SYNCED
   b. For PENDING_DELETE → DELETE record from local DB entirely
   c. Remove items from SyncQueue
   d. Update lastPushedAt = response.timestamp
   e. Trigger pull to get server-generated fields (createdAt, etc.)
6. On failure:
   a. Keep records in pending state
   b. Keep SyncQueue items (retry later)
   c. Increment retryCount on queue items
```

### 7.3 Push Payload Builder

```dart
Map<String, Map<String, dynamic>> _buildPushPayload(List<SyncQueueItem> items) {
  final changes = <String, Map<String, dynamic>>{};

  for (final item in items) {
    final table = item.tableName;
    changes.putIfAbsent(table, () => {
      'created': <Map<String, dynamic>>[],
      'updated': <Map<String, dynamic>>[],
      'deleted': <String>[],
    });

    switch (item.operation) {
      case SyncOperation.create:
        changes[table]!['created'].add(item.data);
        break;
      case SyncOperation.update:
        changes[table]!['updated'].add(item.data);
        break;
      case SyncOperation.delete:
        changes[table]!['deleted'].add(item.recordId);
        break;
    }
  }

  return changes;
}
```

---

## 8. Offline Mutation Queue

### 8.1 SyncQueue Drift Table

```dart
// lib/core/database/tables/sync_queue_table.dart
import 'package:drift/drift.dart';

class SyncQueueItems extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get data => text()(); // Full JSON payload of the record
  Int64Column get createdAt => int64()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 8.2 SyncQueue Class

```dart
// lib/data/sync/sync_queue.dart

class SyncQueue {
  final AppDatabase _db;

  SyncQueue(this._db);

  /// Add a mutation to the queue.
  Future<void> add(SyncQueueItem item) async {
    await _db.into(_db.syncQueueItems).insert(item.toCompanion());
  }

  /// Get all pending mutations ordered by creation (FIFO).
  Future<List<SyncQueueItem>> getAllPending() async {
    final rows = await _db.select(_db.syncQueueItems)
      .orderBy([(t) => OrderingTerm(expression: t.createdAt)])
      .get();
    return rows.map((row) => SyncQueueItem.fromRow(row)).toList();
  }

  /// Count pending mutations.
  Future<int> count() async {
    return _db.select(_db.syncQueueItems).get().then((rows) => rows.length);
  }

  /// Remove a processed item from the queue.
  Future<void> remove(String id) async {
    await (_db.delete(_db.syncQueueItems)
      ..where((t) => t.id.equals(id)))
      .go();
  }

  /// Clear all items (used after sync failure reset).
  Future<void> clearAll() async {
    await _db.delete(_db.syncQueueItems).go();
  }

  /// Increment retry count and save error message.
  Future<void> markFailed(String id, String error) async {
    await (_db.update(_db.syncQueueItems)
      ..where((t) => t.id.equals(id)))
      .write(const SyncQueueItemsCompanion(
        retryCount: Value(3), // Will be updated after this
        error: Value(error),
      ));
  }
}

// Supporting data class
class SyncQueueItem {
  final String id;
  final String tableName;
  final String recordId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.error,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

### 8.3 Mutation Queue Flow

```
User creates/updates/deletes data while offline
    │
    ▼
Repository writes to local Drift DB (optimistic)
    │
    ▼
Repository calls SyncEngine.queueMutation()
    │
    ▼
SyncQueue.add() writes to SyncQueueItems table
    │
    ▼
SyncEngine checks connectivity:
    ├── Online → debounce 1s, then sync() (push → pull)
    └── Offline → show "Saved offline" UI indicator
```

---

## 9. Conflict Resolution

### 9.1 Strategy: Last-Write-Wins

Both client and server use the same strategy: **compare `updatedAt` timestamps**. The record with the more recent `updatedAt` wins.

### 9.2 Server-Side (Push)

When the backend receives a push update, it checks:

```typescript
// Backend (src/lib/sync/service.ts)
const existing = await model.findUnique({ where: { id: record.id } });
if (existing && existing.updatedAt.getTime() > (data.updatedAt || 0)) {
  // Server version is newer → keep server version, discard client change
  return;
}
```

If the server version is newer, the client's change is **silently discarded** (last-write-wins). No error is returned — the client gets the correct data on the next pull.

### 9.3 Client-Side (Pull)

When the client processes incoming pull data, it uses the same logic:

```dart
// lib/data/sync/conflict_resolver.dart
class ConflictResolver {
  final SyncLocalSource _local;

  ConflictResolver(this._local);

  /// Upsert a record during pull, resolving conflicts by last-write-wins.
  Future<void> upsertOnPull(String tableName, Map<String, dynamic> incoming) async {
    final incomingUpdatedAt = incoming['updated_at'] as int;
    final localRecord = await _local.getRecord(tableName, incoming['id'] as String);

    if (localRecord == null) {
      // Record doesn't exist locally → INSERT
      await _local.upsertRecord(tableName, incoming, syncStatus: SyncStatus.synced);
      return;
    }

    // Do NOT overwrite if the local record has pending offline changes
    final localSyncStatus = localRecord['sync_status'] as int;
    if (localSyncStatus != SyncStatus.synced.value) {
      // Local has pending changes — keep local version
      return;
    }

    // Last-write-wins: compare updatedAt
    final localUpdatedAt = localRecord['updated_at'] as int;
    if (incomingUpdatedAt >= localUpdatedAt) {
      // Incoming is newer (or same) → overwrite
      await _local.upsertRecord(tableName, incoming, syncStatus: SyncStatus.synced);
    }
    // If local is newer, keep local (do nothing)
  }
}
```

### 9.4 Conflict Scenarios

| Scenario | Resolution |
|----------|-----------|
| **Client edits offline, server edits same record** | The last writer wins. If the server saves first, then the client pushes — client `updatedAt` is older (the client was offline), so server wins and client change is discarded. |
| **Client creates offline, server also creates** | Handled by idempotency: if the ID already exists on the server, the push `create` becomes an `update` (upsert). |
| **Client deletes offline, server updates same record** | The delete wins (it sets `deletedAt`). On next pull, the client sees the soft-deleted record. |
| **Client creates, no server conflict** | Normal case — record is created on server. |

### 9.5 User Notification on Conflict

For most conflicts, **no user notification is needed** — last-write-wins is silent and predictable. However, for critical data where the user's input was discarded (server won), consider:

- Logging the conflict for developer debugging
- Optionally showing a subtle toast: "Some changes were overwritten by newer server data"
- This is a **post-MVP** enhancement; start with silent resolution

---

## 10. Connectivity Management

### 10.1 ConnectivityManager Implementation

```dart
// lib/data/sync/connectivity_manager.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  final Connectivity _connectivity;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _controller = StreamController<bool>.broadcast();

  ConnectivityManager({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Current online status (synchronous check of last known state).
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Start monitoring connectivity.
  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );

    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
```

### 10.2 Network-Aware Request Pattern

```dart
/// Wrapper for repository methods that need to handle offline state.
Future<T> guardedRequest<T>({
  required Future<T> Function() onlineCall,
  required Future<T> Function() offlineFallback,
  required bool Function(T) isSuccess,
}) async {
  if (_connectivity.isOnline) {
    try {
      final result = await onlineCall();
      if (isSuccess(result)) return result;
    } catch (_) {
      // Network error — fall through to offline fallback
    }
  }
  return offlineFallback();
}
```

### 10.3 Grace Period

When connectivity is restored:
1. ConnectivityManager detects online change
2. Wait **2 seconds** (grace period — avoids rapid sync cycling on flaky connections)
3. Check again if still online
4. If yes, trigger `SyncEngine.sync()` (which does push → pull)

---

## 11. Sync Trigger Matrix

| Trigger | Action | Priority | Network Required | UI Feedback |
|---------|--------|----------|-----------------|-------------|
| **App cold start** | Full sync: push pending → pull | **High** | Yes | Loading screen with progress |
| **App resume from background** | Push pending → pull | **Medium** | Yes | Silent (check on resume) |
| **Periodic (5 min timer)** | Push pending → pull | **Low** | Yes | Silent |
| **Pull-to-refresh gesture** | Push pending → pull | **User** | Yes | Refresh indicator (spinner) |
| **Mutation while online** | Queue + push immediately → pull | **High** | Yes | Optimistic UI update |
| **Mutation while offline** | Queue locally only | **High** | No | "Saved offline" indicator |
| **Connectivity restored** | Wait 2s → push → pull | **High** | Yes | Automatic, subtle toast |
| **Push succeeds** | Pull immediately after | **High** | Yes | Continues from push |
| **Push fails (network)** | Keep queue, retry with backoff | **Medium** | No | Error indicator |
| **Push fails (server error)** | Retry 3× with backoff, then mark failed | **Medium** | Yes | Error toast |
| **Push fails (auth 401)** | Refresh token, retry once | **High** | Yes | Logout if refresh fails |
| **Initial sync on fresh install** | Full pull with `lastPulledAt=0` | **Highest** | Yes | Mandatory loading screen |

### 11.1 Periodic Sync Implementation

```dart
// In app bootstrap or SyncEngine
Timer? _periodicTimer;

void startPeriodicSync() {
  _periodicTimer?.cancel();
  _periodicTimer = Timer.periodic(
    const Duration(minutes: 5),
    (_) => sync(),
  );
}

void stopPeriodicSync() {
  _periodicTimer?.cancel();
  _periodicTimer = null;
}
```

### 11.2 App Lifecycle Integration

```dart
// In main.dart or App widget
class _ZiroFitAppState extends State<ZiroFitApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncEngineProvider).sync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

---

## 12. Initial Sync / App Bootstrap

### 12.1 Bootstrap Sequence

```
App starts
    │
    ▼
1. Initialize Drift database
    │
    ▼
2. Check auth state (stored token / Supabase session)
    ├── Not authenticated → show login screen
    └── Authenticated → continue
          │
          ▼
3. POST /api/auth/sync-user (ensure Prisma user exists)
          │
          ▼
4. Initialize ConnectivityManager
          │
          ▼
5. Check if first launch:
    ├── First launch (no lastPulledAt in prefs):
    │     └── initialSync() with lastPulledAt=0
    │           └── Show full-screen loading with "Syncing your data..."
    └── Returning user:
          └── sync() — push pending → pull incremental
                └── Silent (no loading screen)
          │
          ▼
6. Start periodic sync timer (5 min)
          │
          ▼
7. Navigate to role-appropriate home screen
```

### 12.2 Bootstrap Implementation

```dart
// lib/bootstrap.dart
class AppBootstrap {
  Future<void> initialize(Ref ref) async {
    // 1. Initialize database
    final db = ref.read(appDatabaseProvider);
    await db.initialize();

    // 2. Initialize connectivity
    final connectivity = ref.read(connectivityManagerProvider);
    await connectivity.initialize();

    // 3. Sync user (self-healing)
    try {
      await ref.read(authRemoteSourceProvider).syncUser();
    } catch (_) {
      // Non-fatal — continue even if sync-user fails
    }

    // 4. Perform initial sync
    final syncEngine = ref.read(syncEngineProvider);
    final metadata = ref.read(syncMetadataProvider);
    final hasSyncedBefore = await metadata.hasLastPulledAt();

    if (!hasSyncedBefore) {
      await syncEngine.initialSync(); // Full download, shows loading
    } else {
      // Background sync — don't block UI
      unawaited(syncEngine.sync());
    }

    // 5. Start periodic sync
    syncEngine.startPeriodicSync();
  }
}
```

---

## 13. Sync Repository Implementation

### 13.1 SyncRemoteSource

```dart
// lib/data/datasources/remote/sync_remote_source.dart
class SyncRemoteSource {
  final Dio _dio;

  SyncRemoteSource(this._dio);

  /// Pull changes since the given timestamp.
  Future<SyncPullResponse> pull(int lastPulledAt) async {
    final response = await _dio.get(
      '/api/sync/pull',
      queryParameters: {'last_pulled_at': lastPulledAt},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return SyncPullResponse.fromJson(data);
  }

  /// Push local changes to the server.
  Future<SyncPushResponse> push(Map<String, dynamic> changes) async {
    final response = await _dio.post(
      '/api/sync/push',
      data: {'changes': changes},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return SyncPushResponse.fromJson(data);
  }
}

class SyncPullResponse {
  final Map<String, TableChanges> changes;
  final int timestamp;

  SyncPullResponse({required this.changes, required this.timestamp});

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    final changesJson = json['changes'] as Map<String, dynamic>;
    final changes = <String, TableChanges>{};
    for (final entry in changesJson.entries) {
      changes[entry.key] = TableChanges.fromJson(entry.value as Map<String, dynamic>);
    }
    return SyncPullResponse(
      changes: changes,
      timestamp: json['timestamp'] as int,
    );
  }
}

class SyncPushResponse {
  final int timestamp;

  SyncPushResponse({required this.timestamp});

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    return SyncPushResponse(timestamp: json['timestamp'] as int);
  }
}

class TableChanges {
  final List<Map<String, dynamic>> created;
  final List<Map<String, dynamic>> updated;
  final List<String> deleted;

  TableChanges({
    required this.created,
    required this.updated,
    required this.deleted,
  });

  factory TableChanges.fromJson(Map<String, dynamic> json) {
    return TableChanges(
      created: (json['created'] as List).cast<Map<String, dynamic>>(),
      updated: (json['updated'] as List).cast<Map<String, dynamic>>(),
      deleted: (json['deleted'] as List).cast<String>(),
    );
  }
}
```

### 13.2 SyncLocalSource

```dart
// lib/data/datasources/local/sync_local_source.dart
class SyncLocalSource {
  final AppDatabase _db;

  SyncLocalSource(this._db);

  /// Upsert a pulled record into the local table with given sync status.
  Future<void> upsertRecord(
    String tableName,
    Map<String, dynamic> record,
    {required SyncStatus syncStatus}
  ) async {
    final dao = _getDao(tableName);
    // Build update + insert logic per table...
    // Implementation depends on Drift DAO pattern
    // Each table has a companion class for inserts/updates
  }

  /// Soft-delete a record by setting deletedAt.
  Future<void> softDeleteRecord(String tableName, String id) async {
    // UPDATE table SET deletedAt = ?, syncStatus = 0 WHERE id = ?
  }

  /// Mark a record as synced after successful push.
  Future<void> markSynced(String tableName, String id) async {
    // UPDATE table SET syncStatus = 0 WHERE id = ?
  }

  /// Get a single record by ID (returns raw map or null).
  Future<Map<String, dynamic>?> getRecord(String tableName, String id) async {
    // SELECT * FROM table WHERE id = ?
  }

  /// Delete a record entirely from local DB.
  Future<void> deleteRecord(String tableName, String id) async {
    // DELETE FROM table WHERE id = ?
  }

  /// Get all records with a pending sync status.
  Future<List<Map<String, dynamic>>> getPendingRecords(String tableName) async {
    // SELECT * FROM table WHERE syncStatus != 0
  }

  SyncDao _getDao(String tableName) {
    // Returns the appropriate DAO for the table name
    // This can be a switch statement or a map lookup
    switch (tableName) {
      case 'clients': return _db.clientsDao;
      case 'profiles': return _db.profilesDao;
      // ... all 17 tables
      default: throw ArgumentError('Unknown table: $tableName');
    }
  }
}
```

### 13.3 SyncMetadata

```dart
// lib/data/sync/sync_metadata.dart
class SyncMetadata {
  final SharedPreferences _prefs;

  static const _lastPulledAtKey = 'sync_last_pulled_at';
  static const _lastPushedAtKey = 'sync_last_pushed_at';

  SyncMetadata(this._prefs);

  Future<int> getLastPulledAt() async {
    return _prefs.getInt(_lastPulledAtKey) ?? 0;
  }

  Future<void> updateLastPulledAt(int timestamp) async {
    await _prefs.setInt(_lastPulledAtKey, timestamp);
  }

  Future<bool> hasLastPulledAt() async {
    return _prefs.containsKey(_lastPulledAtKey);
  }

  Future<int> getLastPushedAt() async {
    return _prefs.getInt(_lastPushedAtKey) ?? 0;
  }

  Future<void> updateLastPushedAt(int timestamp) async {
    await _prefs.setInt(_lastPushedAtKey, timestamp);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_lastPulledAtKey);
    await _prefs.remove(_lastPushedAtKey);
  }
}
```

### 13.4 SyncRepository

```dart
// lib/data/repositories/sync_repository.dart
class SyncRepository {
  final SyncRemoteSource _remoteSource;
  final SyncLocalSource _localSource;
  final ConnectivityManager _connectivity;
  final SyncQueue _queue;
  final SyncEngine _engine;

  SyncRepository({
    required SyncRemoteSource remoteSource,
    required SyncLocalSource localSource,
    required ConnectivityManager connectivity,
    required SyncQueue queue,
    required SyncEngine engine,
  }) : _remoteSource = remoteSource,
       _localSource = localSource,
       _connectivity = connectivity,
       _queue = queue,
       _engine = engine;

  /// Perform a full sync cycle.
  Future<SyncResult> sync() => _engine.sync();

  /// Queue an offline mutation.
  Future<void> queueMutation({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) {
    return _engine.queueMutation(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      data: data,
    );
  }

  /// Get the number of pending mutations.
  Future<int> getPendingCount() => _queue.count();

  /// Watch sync status as a stream.
  Stream<SyncUiStatus> watchSyncStatus() => _engine.statusStream;

  /// Current sync status (snapshot).
  SyncUiStatus get currentStatus => _engine._currentStatus;

  /// Whether the device is online.
  bool get isOnline => _connectivity.isOnline;

  /// Whether there are pending offline mutations.
  Future<bool> get hasPendingMutations async =>
    await _queue.count() > 0;
}
```

---

## 14. Sync Status UI

### 14.1 SyncStatus Enum (UI-facing)

```dart
// lib/features/sync/providers/sync_provider.dart

enum SyncUiStatus {
  synced,    // ✓ All data up to date
  syncing,   // ⟳ Sync in progress
  pending,   // ⚠ Offline mutations pending (waiting for connectivity)
  error,     // ✗ Last sync failed
  offline,   // ⊘ Device is offline (no connection at all)
}

// Riverpod provider
final syncStatusProvider = StreamProvider<SyncUiStatus>((ref) {
  final syncRepository = ref.watch(syncRepositoryProvider);
  return syncRepository.watchSyncStatus();
});
```

### 14.2 SyncIndicator Widget

```dart
// lib/features/sync/widgets/sync_indicator.dart

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return switch (syncStatus.valueOrNull) {
      SyncUiStatus.synced => Icon(
          Icons.cloud_done_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      SyncUiStatus.syncing => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      SyncUiStatus.pending => Badge(
          smallSize: 8,
          child: Icon(
            Icons.cloud_upload_outlined,
            color: Theme.of(context).colorScheme.tertiary,
            size: 20,
          ),
        ),
      SyncUiStatus.error => Icon(
          Icons.cloud_off,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        ),
      SyncUiStatus.offline => Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      null => const SizedBox(width: 20), // Loading
    };
  }
}
```

### 14.3 SyncStatusScreen (Detailed View)

```dart
// lib/features/sync/screens/sync_status_screen.dart

class SyncStatusScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingMutationsCountProvider);
    final connectivity = ref.watch(connectivityManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: ListView(
        children: [
          _StatusTile(
            icon: _statusIcon(syncStatus.valueOrNull),
            label: 'Connection',
            value: connectivity.isOnline ? 'Online' : 'Offline',
          ),
          _StatusTile(
            icon: Icons.queue,
            label: 'Pending Mutations',
            value: '$pendingCount',
          ),
          _StatusTile(
            icon: Icons.sync,
            label: 'Last Sync Status',
            value: syncStatus.valueOrNull?.name ?? 'Unknown',
          ),
          if (syncStatus.valueOrNull == SyncUiStatus.pending)
            TextButton.icon(
              onPressed: () => ref.read(syncRepositoryProvider).sync(),
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }
}
```

### 14.4 Riverpod Providers

```dart
// lib/features/sync/providers/sync_provider.dart

final connectivityManagerProvider = Provider<ConnectivityManager>((ref) {
  final manager = ConnectivityManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final syncMetadataProvider = Provider<SyncMetadata>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncMetadata(prefs);
});

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueue(db);
});

final syncRemoteSourceProvider = Provider<SyncRemoteSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return SyncRemoteSource(dio);
});

final syncLocalSourceProvider = Provider<SyncLocalSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncLocalSource(db);
});

final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return ConflictResolver(ref.watch(syncLocalSourceProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    remote: ref.watch(syncRemoteSourceProvider),
    local: ref.watch(syncLocalSourceProvider),
    queue: ref.watch(syncQueueProvider),
    metadata: ref.watch(syncMetadataProvider),
    connectivity: ref.watch(connectivityManagerProvider),
    conflictResolver: ref.watch(conflictResolverProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    remoteSource: ref.watch(syncRemoteSourceProvider),
    localSource: ref.watch(syncLocalSourceProvider),
    connectivity: ref.watch(connectivityManagerProvider),
    queue: ref.watch(syncQueueProvider),
    engine: ref.watch(syncEngineProvider),
  );
});

final pendingMutationsCountProvider = FutureProvider<int>((ref) {
  return ref.watch(syncRepositoryProvider).getPendingCount();
});
```

---

## 15. Error Handling & Retry

### 15.1 Error Scenarios Matrix

| Scenario | Detection | Behavior |
|----------|-----------|----------|
| **Network error on push** | `DioException` type = connection/timeout | Queue stays intact. Retry on next connectivity change or periodic timer. Current retry uses exponential backoff. |
| **Server error (500)** | Response status 500 | Retry up to **3 times** with backoff (10s, 30s, 60s). After 3 failures, mark queue items as failed and notify user. |
| **Auth error (401)** | Response status 401 | Immediately attempt token refresh. If refresh succeeds → retry request. If refresh fails → logout user. |
| **Conflict (server wins)** | Backend silently discards client update | No error. Client's change is lost — next pull returns server version. No user-facing error. |
| **Rate limit (429)** | Response status 429 | Read `Retry-After` header (or default to 60s). Wait and retry once. |
| **Validation error (422)** | Response status 422 | Log the error. This indicates a bug (client sent invalid data). Mark queue item as failed with details. |
| **Permission error (403)** | Response status 403 | Log and alert. This indicates a data access bug. Mark queue item as failed. |
| **Push succeeds partially** | Some tables succeed, others fail | The backend processes all tables in a single transaction. If any table fails, the entire push is rolled back (transactional). Retry the full push. |

### 15.2 Exponential Backoff Implementation

```dart
class RetryPolicy {
  static const _maxRetries = 3;
  static const _delays = [Duration(seconds: 10), Duration(seconds: 30), Duration(seconds: 60)];

  /// Returns the delay for the given retry attempt (0-indexed).
  static Duration delayForAttempt(int attempt) {
    if (attempt >= _delays.length) return const Duration(minutes: 5);
    return _delays[attempt];
  }

  /// Whether another retry should be attempted.
  static bool shouldRetry(int attempt) {
    return attempt < _maxRetries;
  }

  /// Calculate next retry attempt for a SyncQueue item.
  static Duration nextRetryDelay(SyncQueueItem item) {
    return delayForAttempt(item.retryCount);
  }
}
```

### 15.3 Error Logging

```dart
// In SyncEngine._pushPending()
try {
  final response = await _remote.push(changes);
  // ... handle success
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Token expired — attempt refresh
    final refreshed = await _authRepository.refreshToken();
    if (refreshed) {
      // Retry push once
      return _pushPending();
    } else {
      // Logout
      _authRepository.logout();
      return PushResult.failure('Session expired');
    }
  } else if (e.response?.statusCode == 429) {
    // Rate limited — wait and retry
    await Future.delayed(const Duration(seconds: 60));
    return _pushPending();
  } else if (_isServerError(e)) {
    // Server error — retry with backoff
    // Handled by retry interceptor
    rethrow;
  } else {
    // Network error — keep queue, retry later
    return PushResult.failure('Network error');
  }
}
```

---

## 16. Non-Synced Data

The following data is **NOT synchronized** via the sync engine. It is fetched directly from REST API endpoints and is always fresh (never cached for offline use).

| Category | Data | Reason | API Endpoint |
|----------|------|--------|-------------|
| **Dashboard analytics** | Trainer/client dashboard stats, volume charts, heatmaps, consistency scores | Recalculated each time, always needs fresh data | `GET /api/clients/[id]/dashboard`, `GET /api/client/analytics`, `GET /api/trainer/dashboard` |
| **Search results** | Trainer search, exercise search | Dynamic queries, not meaningful to cache | `GET /api/exercises`, trainer search endpoints |
| **Real-time chat** | Messages, conversations | Use Supabase Realtime (WebSocket) | Conversation endpoints (live via Realtime) |
| **AI-generated content** | AI workouts, generated programs, AI insights | Generated on-demand, stateless | `POST /api/client/ai/generate` |
| **Stripe checkout URLs** | Payment links, subscription URLs | Generated on-demand, single-use | `POST /api/payments/create-checkout` |
| **Public data** | Blog posts, public trainer profiles, public events | Read-only, cached via HTTP cache headers | `GET /api/public/*` |
| **Admin data** | User management, system errors, support tickets | Admin-only, always fresh | `GET /api/admin/*` |
| **Server-only processes** | Cron jobs, notifications sending, email | Server-side only | N/A |

### 16.1 Why These Are Not Synced

- **Dashboard analytics** are computed on the fly from aggregated data. Syncing them would mean storing pre-computed aggregations locally, which adds complexity for minimal benefit. The underlying data (workout sessions, measurements, etc.) IS synced — dashboards recompute from local data.
- **Search** queries are ephemeral by nature. Caching search results locally creates staleness issues.
- **Chat** uses Supabase Realtime for instant delivery, which is outside the sync engine. Messages are not synced — they appear in real-time.
- **AI responses** are stateless server-side generations. They are not stored in a sync table.

---

## 17. Backend Sync API Reference

### 17.1 GET /api/sync/pull

Pull all changes since the given timestamp.

**Auth:** Bearer token (authenticated user)

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `last_pulled_at` | integer | `0` | Unix timestamp in milliseconds of the last successful pull |

**Response 200:**
```json
{
  "data": {
    "changes": {
      "[table_name]": {
        "created": [/* Array of record objects */],
        "updated": [/* Array of record objects */],
        "deleted": ["id1", "id2"]
      }
    },
    "timestamp": 1700000000000
  }
}
```

**Behavior:**
- Queries all 17 sync tables in **parallel** for maximum performance
- Returns records where `createdAt >= lastPulledAt` (created), `updatedAt >= lastPulledAt AND createdAt < lastPulledAt` (updated), `deletedAt >= lastPulledAt` (deleted)
- All dates are converted to Unix ms integers
- All field names are converted to snake_case
- If a table query fails, it returns empty arrays for that table (doesn't fail the whole request)
- Timestamp returned is `Date.now()` at the server at time of processing

### 17.2 POST /api/sync/push

Push local changes to the server.

**Auth:** Bearer token (authenticated user)

**Request Body:**
```json
{
  "changes": {
    "[table_name]": {
      "created": [{/* full record */}],
      "updated": [{/* full record */}],
      "deleted": ["id1"]
    }
  }
}
```

**Response 200:**
```json
{
  "data": {
    "timestamp": 1700000000001
  }
}
```

**Behavior:**
- Processes all changes in a **single database transaction** (20s timeout)
- Applies in order: deletions → updates → creations
- **Idempotency**: If a record being created already exists by ID, it switches to update mode
- **Conflict resolution**: On update, compares `updatedAt` — if server version is newer, discards client change (last-write-wins)
- **Soft deletes**: Sets `deletedAt` on the record (does not hard-delete)
- **Permissions**: Validates create/update/delete permissions per-table before applying
- Field names are converted from snake_case (wire) to camelCase (Prisma)

### 17.3 POST /api/auth/sync-user

Ensures the authenticated Supabase user exists in the Prisma database (self-healing).

**Auth:** Bearer token

**Response 200:**
```json
{
  "data": {
    "message": "User synchronized successfully.",
    "userId": "uuid"
  }
}
```

**Behavior:**
- Called during app bootstrap to ensure the user record exists
- Also identifies the user in PostHog for analytics
- Non-fatal — the app can continue if this fails

### 17.4 Sync Tables (Complete Reference)

| # | Table Name (Wire) | Prisma Model | Scope | Permission Check |
|---|---|---|---|---|
| 1 | `clients` | `Client` | Trainer's clients | `trainerId == userId` |
| 2 | `profiles` | `Profile` | Own profile (mobile client) | `userId == userId` |
| 3 | `trainer_profiles` | `Profile` | Own profile (trainer) | `userId == userId` |
| 4 | `workout_sessions` | `WorkoutSession` | Trainer's client sessions | Via client → trainerId |
| 5 | `exercises` | `Exercise` | System + own custom | `createdById == userId OR null` |
| 6 | `workout_templates` | `WorkoutTemplate` | Trainer's programs | Via program → trainerId |
| 7 | `client_assessments` | `AssessmentResult` | Trainer's clients | Via client → trainerId |
| 8 | `client_measurements` | `ClientMeasurement` | Trainer's clients | Via client → trainerId |
| 9 | `client_photos` | `ClientProgressPhoto` | Trainer's clients | Via client → trainerId |
| 10 | `client_exercise_logs` | `ClientExerciseLog` | Trainer's clients | Via client → trainerId |
| 11 | `trainer_services` | `Service` | Own profile services | Via profile → userId |
| 12 | `trainer_packages` | `Package` | Own packages | `trainerId == userId` |
| 13 | `trainer_testimonials` | `Testimonial` | Own testimonials | Via profile → userId |
| 14 | `trainer_programs` | `WorkoutProgram` | Own programs | `trainerId == userId` |
| 15 | `calendar_events` | `Booking` | Own bookings | `trainerId == userId` |
| 16 | `notifications` | `Notification` | Own notifications | `userId == userId` |
| 17 | `bookings` | `Booking` | Own bookings | `trainerId == userId` |

> **Note:** Tables 15 (`calendar_events`) and 17 (`bookings`) both map to the Prisma `Booking` model. They are separate sync table names in the API but share the same schema on the Drift side.

---

## 18. Testing Sync

### 18.1 Unit Tests

| Test | What to Verify |
|------|---------------|
| `SyncQueue.add()` | Writes to Drift in-memory database |
| `SyncQueue.getAllPending()` | Returns items in FIFO order |
| `SyncQueue.remove()` | Removes item after processing |
| `ConflictResolver.upsertOnPull()` | Local newer → keep local; incoming newer → overwrite; pending changes → skip |
| `SyncMetadata` | Read/write from SharedPreferences |
| `_buildPushPayload()` | Correctly groups items by table and operation |
| `ConnectivityManager` | Stream emits correct online/offline events |

### 18.2 Widget Tests

| Test | What to Verify |
|------|---------------|
| `SyncIndicator` | Shows correct icon for each SyncUiStatus |
| `SyncStatusScreen` | Displays pending count, connection status |
| Offline mutation toast | Shows "Saved offline" message |

### 18.3 Integration Tests

| Test | What to Verify |
|------|---------------|
| Full pull cycle | Mock `GET /sync/pull` → records written to Drift |
| Full push cycle | Mock `POST /sync/push` → queue drained, records marked synced |
| Conflict resolution | Simulate conflicting updatedAt values |
| Offline → online transition | Queue mutations while offline, verify push on connectivity restored |

### 18.4 E2E Tests (with Mock Server)

| Test | What to Verify |
|------|---------------|
| Fresh install sync | Initial pull populates all local tables |
| Create data offline | Mutation queued, pushed when online |
| Update data offline | Mutation queued, pushed when online |
| Delete data offline | Mutation queued, record soft-deleted |
| Push then pull | After push, pull retrieves server-generated data |
| Token expiry during sync | Auth interceptor refreshes token, sync continues |

### 18.5 Testing with In-Memory Drift

```dart
// Unit test setup
final db = AppDatabase(NativeDatabase.memory());
final queue = SyncQueue(db);
final conflictResolver = ConflictResolver(SyncLocalSource(db));

// Mock HTTP
final mockDio = Dio();
mockDio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    if (options.path.contains('/sync/pull')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'data': {
          'changes': {/* mock changes */},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }},
      ));
    }
    // ... handle push
  },
));
```

---

## 19. Implementation Checklist

### Phase 1: Foundation

- [ ] Add dependencies to `pubspec.yaml`: `drift`, `sqlite3_flutter_libs`, `connectivity_plus`, `shared_preferences`, `path_provider`, `uuid`
- [ ] Create `AppDatabase` with all 17 table definitions
- [ ] Run `build_runner` to generate Drift database code
- [ ] Implement `SyncMetadata` (SharedPreferences wrapper)
- [ ] Implement `ConnectivityManager`

### Phase 2: Local Data Layer

- [ ] Implement `SyncLocalSource` with upsert/delete/query methods for all 17 tables
- [ ] Implement `SyncQueue` (Drift-backed FIFO queue)
- [ ] Implement `ConflictResolver`
- [ ] Write unit tests for `SyncQueue`, `ConflictResolver`, `SyncMetadata`

### Phase 3: Remote Data Layer

- [ ] Implement `SyncRemoteSource` (pull/push HTTP calls)
- [ ] Map incoming snake_case JSON to Drift table columns
- [ ] Map outgoing Drift rows to snake_case JSON
- [ ] Write integration tests with mock HTTP responses

### Phase 4: Sync Engine

- [ ] Implement `SyncEngine` with `sync()`, `_pushPending()`, `_pull()`
- [ ] Implement `_buildPushPayload()` — group pending mutations by table
- [ ] Implement initial sync flow (lastPulledAt=0)
- [ ] Implement periodic sync (5-minute timer)
- [ ] Implement app lifecycle sync (resume from background)
- [ ] Wire up connectivity changes to trigger sync

### Phase 5: Repository & Providers

- [ ] Implement `SyncRepository` (unified API for the rest of the app)
- [ ] Create Riverpod providers for `SyncEngine`, `SyncRepository`, `SyncStatus`
- [ ] Implement `SyncUiStatus` stream
- [ ] Create Riverpod provider for pending mutation count

### Phase 6: UI

- [ ] Implement `SyncIndicator` widget (app bar icon)
- [ ] Implement `SyncStatusScreen` (detailed sync view)
- [ ] Add loading screen for initial sync
- [ ] Add "Saved offline" toast/indicator
- [ ] Add pull-to-refresh on all list screens

### Phase 7: Repository Integration

- [ ] Integrate sync queue into all data repositories (clients, workouts, etc.)
- [ ] Repository writes go through: `local upsert` → `syncEngine.queueMutation()`
- [ ] Repository reads always come from local DB first

### Phase 8: Polish

- [ ] Implement retry with exponential backoff
- [ ] Handle 401 token refresh in sync flow
- [ ] Add error logging for sync failures
- [ ] Performance test with large datasets (1000+ records)
- [ ] Handle edge case: partial sync (some tables fail)
- [ ] Handle edge case: app killed during sync
- [ ] Write comprehensive E2E tests

---

> **Next steps:** Begin with Phase 1 — add Drift and connectivity_plus dependencies, define all 17 Drift table classes, and generate the database.
