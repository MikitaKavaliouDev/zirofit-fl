# Ziro Fit Flutter — Test-Driven Development Plan

> **Purpose:** Defines the complete Test-Driven Development (TDD) approach for building the Ziro Fit Flutter app — an offline-first fitness business management platform with 120+ API endpoints, 30+ data models, Riverpod state management, Drift SQLite, Dio networking, and Supabase auth.
>
> **Last updated:** 2026-05-01
>
> **Related docs:** `ARCHITECTURE.md`, `DATA_MODELS.md`, `API_REFERENCE.md`, `AUTH_FLOW.md`, `OFFLINE_SYNC.md`, `FEATURE_COVERAGE.md`

---

## Table of Contents

1. [TDD Philosophy for this Project](#1-tdd-philosophy-for-this-project)
2. [Testing Pyramid](#2-testing-pyramid)
3. [Coverage Targets](#3-coverage-targets)
4. [Test Organization](#4-test-organization)
5. [TDD Workflow by Feature](#5-tdd-workflow-by-feature)
6. [Testing Infrastructure](#6-testing-infrastructure)
7. [Testing Patterns](#7-testing-patterns)
8. [Test Data Management](#8-test-data-management)
9. [Continuous Integration](#9-continuous-integration)
10. [Flaky Test Management](#10-flaky-test-management)
11. [Test Naming Conventions](#11-test-naming-conventions)
12. [Per-Feature Test Plan Summary](#12-per-feature-test-plan-summary)
13. [Testing Tools & Dependencies](#13-testing-tools--dependencies)

---

## 1. TDD Philosophy for this Project

### The Red-Green-Refactor Cycle

Every feature in Ziro Fit follows the classic TDD cycle, adapted for Flutter's widget-based architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    TDD CYCLE                                 │
│                                                             │
│  1. RED    Write a failing test that defines expected       │
│            behavior before writing any implementation code  │
│                                                             │
│  2. GREEN  Write the minimum code required to make the      │
│            test pass. No optimization, no refactoring.      │
│                                                             │
│  3. REFACTOR  Clean up the code while keeping tests green.  │
│               Remove duplication, improve naming, extract   │
│               shared logic.                                 │
│                                                             │
│  4. COMMIT  Run full test suite, commit all green.          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Adaptation for This Project

Given the scale of Ziro Fit (30+ models, 120+ endpoints), TDD is applied at **two granularities**:

**Micro-cycle (minutes):**
- Write a single model test → implement `fromJson`/`toJson` → pass → refactor
- Write a single service test → implement one endpoint → pass → refactor

**Macro-cycle (hours/days):**
- Phase A: All model tests → all model classes (foundation)
- Phase A: All service tests → all service classes (API layer)
- Phase A: All repository tests → all repository classes (data orchestration)
- Phase B: All provider tests → all provider classes (state management)
- Phase B: All widget tests → all screen/widget classes (UI layer)

### Key Principle: Test Behavior, Not Implementation

Tests validate **what** the code does, not **how**. This means:
- Repository tests mock remote/local sources and verify data flow, not SQL queries
- Provider tests verify state transitions (loading → data → error), not internal notifier implementation
- Widget tests verify rendered widgets and user interaction outcomes, not widget tree internals

### Commit Discipline

```
Every commit must:
  ✓ Have all tests passing (flutter test)
  ✓ Pass flutter analyze --fatal-infos
  ✓ Be a logical unit of work (one model, one service, one feature)
  ✓ Follow conventional commit format

Commit message format:
  test(model): add User model round-trip tests
  feat(model): implement User with fromJson/toJson
  test(service): add AuthApiService login tests
  feat(service): implement AuthApiService login endpoint
  test(repo): add AuthRepository login tests
  feat(repo): implement AuthRepository with offline-first pattern
```

---

## 2. Testing Pyramid

```
                    ╱╲
                   ╱  ╲
                  ╱    ╲        E2E Tests (5-10%)
                 ╱      ╲       Playwright / integration_test
                ╱────────╲
               ╱          ╲     Widget Tests (20-30%)
              ╱            ╲    per feature/screen
             ╱──────────────╲
            ╱                ╲   Unit Tests (60-70%)
           ╱                  ╲  models, repos, providers,
          ╱                    ╲ services, sync engine, utils
         ╱──────────────────────╲
```

### Distribution Rationale for Ziro Fit

| Layer | Percentage | Why |
|-------|-----------|-----|
| **Unit tests** | 60-70% | 30+ models with round-trip serialization, 120+ endpoints across services, 20+ repositories, sync engine, auth flow, utility functions — all individually testable |
| **Widget tests** | 20-30% | ~40+ screens across 24 feature groups, reusable shared widgets, state-dependent rendering (loading/error/empty/data) |
| **Integration tests** | 5-10% | Critical user journeys: login → dashboard, start → track → finish workout, offline → online sync, client CRUD flow |
| **E2E tests** | 5-10% | Full role-based scenarios: trainer journey, client journey, admin moderation, offline sync |

---

## 3. Coverage Targets

| Layer | Target | Notes |
|-------|--------|-------|
| **Data Models (fromJson/toJson)** | 95%+ | Round-trip tests for all 43 models. Cover null fields, edge cases, list serialization, enum serialization. |
| **Enums (fromJson/toJson)** | 100% | Every enum value tested for both directions. |
| **API Client / Dio Interceptors** | 90%+ | Auth interceptor (token injection, 401 refresh, queued requests), retry interceptor (exponential backoff), sync interceptor (offline queue). |
| **Auth Service / Repository** | 90%+ | Login, register, OAuth, refresh, token storage, auto-login, sign out, error handling. |
| **Remote Data Sources** | 85%+ | Each endpoint tested: correct HTTP method, URL, headers, body format, response parsing, error handling. |
| **Local Data Sources (Drift)** | 85%+ | Each CRUD operation tested with in-memory database. |
| **Repositories** | 85%+ | Mock API + mock DB → verify correct data flow: cache-first, remote-fallback, offline-fallback, mutation queuing. |
| **Sync Engine** | 90%+ | Pull, push, queue management, conflict resolution, connectivity handling, retry logic, metadata tracking. |
| **Providers (Riverpod)** | 80%+ | State transitions (initial → loading → data/error), parameterized family providers, dependent providers. |
| **Use Cases** | 80%+ | Business logic validation: form validation, data transformation, authorization checks. |
| **Screens** | 50%+ | Render verification for: loading state, data state, error state, empty state. Interaction testing for critical actions. |
| **Shared Widgets** | 60%+ | Reusable widgets tested with different states and configurations. |
| **Integration Tests** | 5 flows | Auth flow, workout flow, sync flow, client management flow, booking flow. |
| **E2E Tests** | 5 scenarios | Trainer journey, client journey, offline sync, admin moderation, AI coach. |

### Enforcement

- **Pre-commit hook** enforces coverage for new files in `test/` — any new `lib/` file must have a corresponding `test/` file.
- **PR gate:** Coverage must not decrease below current threshold.
- **Phase gates:** Each implementation phase (1-5) has minimum coverage must-pass criteria.

---

## 4. Test Organization

```
test/
├── unit/
│   ├── models/                   # fromJson/toJson round-trip tests (one per model)
│   │   ├── user_test.dart        # User + ExtendedProfile
│   │   ├── profile_test.dart     # Profile + sub-models (Location, Service, Testimonial, etc.)
│   │   ├── client_test.dart      # Client + ClientMeasurement + ClientProgressPhoto
│   │   ├── workout_session_test.dart
│   │   ├── exercise_test.dart    # Exercise + ClientExerciseLog
│   │   ├── workout_program_test.dart  # WorkoutProgram + WorkoutTemplate + TemplateExercise
│   │   ├── booking_test.dart     # Booking + Event + EventBooking
│   │   ├── check_in_test.dart
│   │   ├── message_test.dart     # Conversation + Message
│   │   ├── notification_test.dart
│   │   ├── payment_test.dart     # Package + ClientPackage
│   │   ├── habit_test.dart       # DailyHabit + HabitLog
│   │   ├── nutrition_test.dart   # Recipe + RecipeTag + Product
│   │   ├── resource_test.dart    # Resource + ClientResource
│   │   ├── assessment_test.dart  # Assessment + AssessmentResult
│   │   ├── personal_record_test.dart
│   │   ├── blog_post_test.dart
│   │   ├── support_ticket_test.dart
│   │   └── system_setting_test.dart
│   │
│   ├── enums/                    # Enum serialization tests
│   │   └── all_enums_test.dart   # Exercises all 9 enums in one file
│   │
│   ├── services/                 # Service tests (co-located pattern)
│   │   ├── auth/
│   │   │   ├── auth_api_service_test.dart
│   │   │   └── auth_local_service_test.dart
│   │   ├── sync/
│   │   │   ├── sync_remote_source_test.dart
│   │   │   └── sync_local_source_test.dart
│   │   ├── client/
│   │   │   ├── client_remote_source_test.dart
│   │   │   └── client_local_source_test.dart
│   │   ├── workout/
│   │   │   ├── workout_remote_source_test.dart
│   │   │   └── workout_local_source_test.dart
│   │   ├── profile/
│   │   │   ├── profile_remote_source_test.dart
│   │   │   └── profile_local_source_test.dart
│   │   ├── booking/
│   │   │   ├── booking_remote_source_test.dart
│   │   │   └── booking_local_source_test.dart
│   │   ├── checkin/
│   │   │   ├── checkin_remote_source_test.dart
│   │   │   └── checkin_local_source_test.dart
│   │   ├── notification/
│   │   │   └── notification_remote_source_test.dart
│   │   ├── exercise/
│   │   │   └── exercise_remote_source_test.dart
│   │   ├── calendar/
│   │   │   └── calendar_remote_source_test.dart
│   │   ├── explore/
│   │   │   └── explore_remote_source_test.dart
│   │   ├── chat/
│   │   │   └── chat_remote_source_test.dart
│   │   ├── billing/
│   │   │   └── billing_remote_source_test.dart
│   │   ├── admin/
│   │   │   └── admin_remote_source_test.dart
│   │   └── misc/
│   │       ├── nutrition_remote_source_test.dart
│   │       ├── habit_remote_source_test.dart
│   │       └── resource_remote_source_test.dart
│   │
│   ├── repositories/             # Repository tests with mocked sources
│   │   ├── auth_repository_test.dart
│   │   ├── sync_repository_test.dart
│   │   ├── client_repository_test.dart
│   │   ├── workout_repository_test.dart
│   │   ├── profile_repository_test.dart
│   │   ├── booking_repository_test.dart
│   │   ├── checkin_repository_test.dart
│   │   ├── exercise_repository_test.dart
│   │   ├── notification_repository_test.dart
│   │   ├── calendar_repository_test.dart
│   │   ├── chat_repository_test.dart
│   │   ├── explore_repository_test.dart
│   │   ├── billing_repository_test.dart
│   │   ├── nutrition_repository_test.dart
│   │   ├── habit_repository_test.dart
│   │   └── resource_repository_test.dart
│   │
│   ├── providers/                # Provider/notifier tests (Riverpod)
│   │   ├── auth/
│   │   │   ├── auth_provider_test.dart
│   │   │   └── auth_state_test.dart
│   │   ├── sync/
│   │   │   ├── sync_status_provider_test.dart
│   │   │   └── pending_mutations_provider_test.dart
│   │   ├── dashboard/
│   │   │   ├── trainer_dashboard_provider_test.dart
│   │   │   └── client_dashboard_provider_test.dart
│   │   ├── client/
│   │   │   ├── client_list_provider_test.dart
│   │   │   └── client_detail_provider_test.dart
│   │   ├── workout/
│   │   │   ├── active_workout_provider_test.dart
│   │   │   └── workout_history_provider_test.dart
│   │   ├── profile/
│   │   │   └── profile_provider_test.dart
│   │   ├── booking/
│   │   │   └── booking_provider_test.dart
│   │   ├── checkin/
│   │   │   └── checkin_provider_test.dart
│   │   ├── notification/
│   │   │   └── notification_provider_test.dart
│   │   ├── exercise/
│   │   │   └── exercise_list_provider_test.dart
│   │   ├── calendar/
│   │   │   └── calendar_provider_test.dart
│   │   ├── chat/
│   │   │   └── chat_provider_test.dart
│   │   └── billing/
│   │       └── billing_provider_test.dart
│   │
│   ├── sync/                     # Sync engine unit tests
│   │   ├── sync_engine_test.dart
│   │   ├── sync_queue_test.dart
│   │   ├── conflict_resolver_test.dart
│   │   ├── connectivity_manager_test.dart
│   │   ├── sync_metadata_test.dart
│   │   ├── sync_pull_test.dart
│   │   └── sync_push_test.dart
│   │
│   ├── usecases/                 # Use case tests
│   │   ├── auth/
│   │   │   ├── login_usecase_test.dart
│   │   │   ├── register_usecase_test.dart
│   │   │   └── oauth_login_usecase_test.dart
│   │   ├── workout/
│   │   │   ├── start_workout_usecase_test.dart
│   │   │   ├── finish_workout_usecase_test.dart
│   │   │   └── log_exercise_usecase_test.dart
│   │   ├── client/
│   │   │   ├── create_client_usecase_test.dart
│   │   │   └── get_clients_usecase_test.dart
│   │   └── booking/
│   │       └── create_booking_usecase_test.dart
│   │
│   └── utils/                    # Utility tests
│       ├── date_time_utils_test.dart
│       ├── validators_test.dart
│       ├── api_constants_test.dart
│       ├── enum_utils_test.dart
│       ├── json_utils_test.dart
│       └── result_test.dart
│
├── widget/
│   ├── auth/
│   │   ├── login_screen_test.dart
│   │   ├── register_screen_test.dart
│   │   ├── forgot_password_screen_test.dart
│   │   ├── auth_callback_screen_test.dart
│   │   └── login_form_test.dart
│   ├── dashboard/
│   │   ├── trainer_dashboard_screen_test.dart
│   │   ├── client_dashboard_screen_test.dart
│   │   └── stats_card_test.dart
│   ├── workout/
│   │   ├── active_workout_screen_test.dart
│   │   ├── workout_history_screen_test.dart
│   │   ├── workout_summary_screen_test.dart
│   │   ├── exercise_detail_screen_test.dart
│   │   └── exercise_set_row_test.dart
│   ├── clients/
│   │   ├── client_list_screen_test.dart
│   │   ├── client_detail_screen_test.dart
│   │   ├── add_client_screen_test.dart
│   │   └── client_card_test.dart
│   ├── profile/
│   │   ├── trainer_profile_screen_test.dart
│   │   ├── edit_profile_screen_test.dart
│   │   ├── services_screen_test.dart
│   │   └── packages_screen_test.dart
│   ├── programs/
│   │   ├── programs_list_screen_test.dart
│   │   ├── program_detail_screen_test.dart
│   │   └── template_detail_screen_test.dart
│   ├── calendar/
│   │   └── calendar_screen_test.dart
│   ├── checkin/
│   │   ├── checkin_list_screen_test.dart
│   │   ├── checkin_detail_screen_test.dart
│   │   └── submit_checkin_screen_test.dart
│   ├── bookings/
│   │   ├── booking_list_screen_test.dart
│   │   └── create_booking_screen_test.dart
│   ├── notifications/
│   │   └── notification_screen_test.dart
│   ├── chat/
│   │   ├── conversations_list_screen_test.dart
│   │   └── chat_screen_test.dart
│   ├── explore/
│   │   ├── explore_screen_test.dart
│   │   └── public_trainer_profile_screen_test.dart
│   ├── events/
│   │   ├── events_list_screen_test.dart
│   │   └── create_event_screen_test.dart
│   ├── habits/
│   │   └── habits_screen_test.dart
│   ├── nutrition/
│   │   └── recipes_list_screen_test.dart
│   ├── admin/
│   │   ├── admin_dashboard_screen_test.dart
│   │   └── admin_events_screen_test.dart
│   ├── sync/
│   │   ├── sync_status_screen_test.dart
│   │   └── sync_indicator_test.dart
│   └── shared/
│       ├── error_view_test.dart
│       ├── loading_indicator_test.dart
│       ├── empty_state_test.dart
│       ├── primary_button_test.dart
│       └── avatar_widget_test.dart
│
├── integration/
│   ├── auth_flow_test.dart             # Login → Dashboard navigation
│   ├── auth_register_flow_test.dart    # Register → Verify → Login
│   ├── workout_flow_test.dart          # Start → Log → Finish → History
│   ├── sync_flow_test.dart             # Offline mutation → Online sync
│   ├── client_flow_test.dart           # Create → Edit → Measurements → View
│   ├── booking_flow_test.dart          # Book → Confirm → Cancel
│   ├── checkin_flow_test.dart          # Submit → Review → Trends
│   └── navigation_flow_test.dart       # Role-based routing: trainer vs client
│
├── e2e/
│   ├── auth_flows_test.dart            # Login, register, OAuth, sign out
│   ├── trainer_journey_test.dart       # Full trainer workflow
│   ├── client_journey_test.dart        # Full client workflow
│   ├── offline_sync_test.dart          # Create/edit offline → sync online
│   └── admin_moderation_test.dart      # Event approval, blog CRUD, tickets
│
├── fixtures/                           # Shared test data
│   ├── user_fixture.dart
│   ├── client_fixture.dart
│   ├── workout_fixture.dart
│   ├── booking_fixture.dart
│   ├── sync_payload_fixtures.dart
│   └── index.dart                      # Barrel export
│
├── helpers/                            # Test utilities
│   ├── pump_app.dart                   # Wraps widget in ProviderScope + MaterialApp
│   ├── mock_providers.dart             # Pre-built provider overrides
│   ├── test_database.dart              # In-memory Drift database factory
│   └── test_router.dart                # Minimal GoRouter for tests
│
└── quarantine.txt                      # Known-flaky tests list
```

---

## 5. TDD Workflow by Feature

For each feature, the TDD cycle follows a consistent **two-phase** approach:

### Phase A: Model & Service Tests (Foundation Layer)

```
Step 1 ─── Write Model Test (fromJson/toJson round-trip)
                 ↓
Step 2 ─── Write Model Class
                 ↓
Step 3 ─── Write API Service Test (mock HTTP, verify request/response)
                 ↓
Step 4 ─── Write API Service Class
                 ↓
Step 5 ─── Write Local Service Test (mock Drift, verify CRUD)
                 ↓
Step 6 ─── Write Local Service Class
                 ↓
Step 7 ─── Write Repository Test (mock sources, verify data flow)
                 ↓
Step 8 ─── Write Repository Class
```

### Phase B: State & UI Tests (Presentation Layer)

```
Step 9  ─── Write Provider Test (state transitions)
                  ↓
Step 10 ─── Write Provider Class
                  ↓
Step 11 ─── Write Screen/Widget Test (render, loading, error, empty)
                  ↓
Step 12 ─── Write Screen/Widget Class
                  ↓
Step 13 ─── Write Integration Test (full flow)
                  ↓
Step 14 ─── Write E2E Test (if critical flow)
```

### Feature Implementation Checklist

For each feature module (from `ARCHITECTURE.md`):

```
[ ] Data models (if not already in data/models/)
[ ] Remote data source (API calls with Dio)
[ ] Local data source (Drift queries)
[ ] Repository (with Result type, offline-first read/write)
[ ] Use cases (if complex business logic)
[ ] Providers (Riverpod with code generation)
[ ] Screens (with AsyncValue.when — loading/error/data)
[ ] Widgets (reusable components)
[ ] Unit tests (models, data sources, repositories)
[ ] Widget tests (screens)
[ ] Integration tests (full flow)
```

---

## 6. Testing Infrastructure

### 6.1 Mocking Strategy

| Dependency | Mocking Approach | Tool |
|-----------|-----------------|------|
| **HTTP (Dio)** | Dio `MockAdapter` — intercept requests, return canned responses | `dio` built-in interceptor mocking |
| **Database (Drift)** | `NativeDatabase.memory()` — in-memory SQLite per test | Drift's built-in memory option |
| **Supabase Auth** | Mock `GoTrueClient` via `mocktail` — control session state | `mocktail` |
| **Connectivity** | `MockStreamController<bool>` — emit online/offline on demand | `dart:async` |
| **Secure Storage** | In-memory `FakeSecureStorage` implementing `FlutterSecureStorage` interface | Custom fake |
| **SharedPreferences** | `SharedPreferences.setMockInitialValues({})` — in-memory prefs | `shared_preferences` test support |
| **Riverpod** | `ProviderContainer` with `overrides` — inject mock dependencies | Riverpod's testing utilities |
| **GoRouter** | Direct `GoRouter` instantiation with simplified route config for test | `go_router` |

### 6.2 Dio MockAdapter Pattern

```dart
// test/helpers/mock_dio.dart
Dio createMockDio(Map<String, MockResponse> responses) {
  final dio = Dio();
  dio.httpClientAdapter = MockAdapter(
    requestCallback: (options) async {
      final key = '${options.method} ${options.path}';
      final mock = responses[key];
      if (mock != null) {
        return ResponseBody.fromString(
          jsonEncode(mock.body),
          mock.statusCode,
          headers: {
            'content-type': ['application/json'],
          },
        );
      }
      throw DioException(
        requestOptions: options,
        error: 'No mock for $key',
      );
    },
  );
  return dio;
}

class MockResponse {
  final int statusCode;
  final Map<String, dynamic> body;
  const MockResponse(this.statusCode, this.body);
}
```

### 6.3 In-Memory Drift Database

```dart
// test/helpers/test_database.dart
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

// Usage in setUp:
late AppDatabase db;
setUp(() {
  db = createTestDatabase();
});
tearDown(() => db.close());
```

### 6.4 Fake Secure Storage

```dart
// test/helpers/fake_secure_storage.dart
class FakeSecureStorage implements Fake, FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<bool> containsKey({required String key}) async => _store.containsKey(key);
}
```

### 6.5 Widget Test Helper

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    GoRouter? router,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: router ?? createTestRouter(),
          title: 'Ziro Fit Test',
        ),
      ),
    );
  }
}

// test/helpers/test_router.dart
GoRouter createTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/auth/login', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/trainer/dashboard', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/client/dashboard', builder: (_, __) => const SizedBox()),
      // Add minimal routes as needed by the test
    ],
  );
}
```

### 6.6 Riverpod Provider Override Pattern

```dart
// test/helpers/mock_providers.dart
ProviderContainer createProviderContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

// Usage:
final container = createProviderContainer(overrides: [
  authRepositoryProvider.overrideWithValue(mockRepo),
  apiClientProvider.overrideWithValue(mockDio),
]);
```

---

## 7. Testing Patterns

### Pattern 1: Model Round-Trip Test

Every model gets the same pattern:

```dart
void main() {
  group('User model', () {
    test('fromJson/toJson round-trip matches fixture', () {
      final json = testUserJson;
      final user = User.fromJson(json);
      expect(user.toJson(), equals(json));
    });

    test('fromJson handles all null fields', () {
      final json = {
        'id': 'test-id',
        'name': 'Test',
        'email': 'test@test.com',
        'role': 'trainer',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
        // All optional fields are absent
      };
      final user = User.fromJson(json);
      expect(user.username, isNull);
      expect(user.emailVerifiedAt, isNull);
      expect(user.tier, UserTier.starter); // default
      expect(user.hasCompletedOnboarding, false); // default
    });

    test('copyWith preserves unchanged fields', () {
      final user = UserFactory.create();
      final modified = user.copyWith(name: 'New Name');
      expect(modified.name, 'New Name');
      expect(modified.id, user.id); // Unchanged
      expect(modified.email, user.email); // Unchanged
    });

    test('equality works correctly', () {
      final user1 = UserFactory.create();
      final user2 = UserFactory.create();
      expect(user1, equals(user2));
    });

    test('hashCode is consistent', () {
      final user = UserFactory.create();
      expect(user.hashCode, equals(user.hashCode));
    });
  });
}
```

### Pattern 2: Enum Serialization Test

```dart
void main() {
  group('WorkoutSessionStatus enum', () {
    test('all values serialize and deserialize', () {
      for (final value in WorkoutSessionStatus.values) {
        final json = value.toJson();        // Dart value → wire string
        final restored = WorkoutSessionStatus.fromJson(json); // wire string → Dart value
        expect(restored, value);
      }
    });

    test('fromJson handles API wire format', () {
      expect(WorkoutSessionStatus.fromJson('PLANNED'), WorkoutSessionStatus.planned);
      expect(WorkoutSessionStatus.fromJson('IN_PROGRESS'), WorkoutSessionStatus.inProgress);
      expect(WorkoutSessionStatus.fromJson('COMPLETED'), WorkoutSessionStatus.completed);
    });

    test('toJson produces API wire format', () {
      expect(WorkoutSessionStatus.planned.toJson(), 'PLANNED');
      expect(WorkoutSessionStatus.inProgress.toJson(), 'IN_PROGRESS');
      expect(WorkoutSessionStatus.completed.toJson(), 'COMPLETED');
    });
  });
}
```

### Pattern 3: Remote Data Source Test (Dio MockAdapter)

```dart
void main() {
  late Dio dio;
  late MockAdapter mockAdapter;
  late AuthRemoteSource remoteSource;

  setUp(() {
    dio = Dio();
    mockAdapter = MockAdapter();
    dio.httpClientAdapter = mockAdapter;
    remoteSource = AuthRemoteSource(dio);
  });

  group('login', () {
    test('sends correct request and parses response', () async {
      mockAdapter.onPost(
        '/api/auth/login',
        (request) async {
          final body = jsonDecode(request.data) as Map<String, dynamic>;
          expect(body['email'], 'user@test.com');
          expect(body['password'], 'password123');

          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'accessToken': 'test-token',
                'refreshToken': 'test-refresh',
                'user': {'id': 'user-1', 'email': 'user@test.com'},
                'role': 'trainer',
              },
            }),
            200,
            headers: {'content-type': ['application/json']},
          );
        },
      );

      final response = await remoteSource.login('user@test.com', 'password123');

      expect(response.accessToken, 'test-token');
      expect(response.role, 'trainer');
    });

    test('throws on 401 error', () async {
      mockAdapter.onPost(
        '/api/auth/login',
        (request) async => ResponseBody.fromString(
          jsonEncode({'error': {'message': 'Invalid credentials'}}),
          401,
          headers: {'content-type': ['application/json']},
        ),
      );

      expect(
        () => remoteSource.login('bad@user.com', 'wrong'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
```

### Pattern 4: Local Data Source Test (In-Memory Drift)

```dart
void main() {
  late AppDatabase db;
  late ClientLocalSource localSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    localSource = ClientLocalSource(db);
  });

  tearDown(() => db.close());

  group('saveClient / getClient', () {
    test('saves and retrieves a client', () async {
      await localSource.saveClient(testClient);

      final retrieved = await localSource.getClient(testClient.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, testClient.name);
      expect(retrieved!.email, testClient.email);
    });

    test('returns null for non-existent client', () async {
      final retrieved = await localSource.getClient('non-existent');
      expect(retrieved, isNull);
    });

    test('getAllClients returns only active clients', () async {
      await localSource.saveClient(testClient);
      await localSource.saveClient(testClient2);
      await localSource.softDeleteClient(testClient.id);

      final clients = await localSource.getAllClients();
      expect(clients.length, 1); // Only testClient2
      expect(clients.first.id, testClient2.id);
    });
  });

  group('softDeleteClient', () {
    test('sets deletedAt on the client', () async {
      await localSource.saveClient(testClient);
      await localSource.softDeleteClient(testClient.id);

      final deleted = await localSource.getClient(testClient.id);
      expect(deleted!.deletedAt, isNotNull);
    });
  });
}
```

### Pattern 5: Repository Test (Offline-First Data Flow)

```dart
void main() {
  late MockClientRemoteSource mockRemote;
  late MockClientLocalSource mockLocal;
  late ClientRepository repository;

  setUp(() {
    mockRemote = MockClientRemoteSource();
    mockLocal = MockClientLocalSource();
    repository = ClientRepository(
      remoteSource: mockRemote,
      localSource: mockLocal,
    );
  });

  group('getClient', () {
    test('returns cached client from local source when available', () async {
      when(() => mockLocal.getClient('1'))
          .thenAnswer((_) async => testClient);

      final result = await repository.getClient('1');

      expect(result.isSuccess, true);
      expect(result.data!.id, testClient.id);
      verifyNever(() => mockRemote.getClient(any()));
    });

    test('fetches from remote on cache miss and caches result', () async {
      when(() => mockLocal.getClient('1'))
          .thenAnswer((_) async => null);
      when(() => mockRemote.getClient('1'))
          .thenAnswer((_) async => testClient);
      when(() => mockLocal.saveClient(any()))
          .thenAnswer((_) async {});

      final result = await repository.getClient('1');

      expect(result.isSuccess, true);
      expect(result.data!.id, testClient.id);
      verify(() => mockLocal.saveClient(testClient)).called(1);
    });

    test('returns failure on remote error when cache miss', () async {
      when(() => mockLocal.getClient('1'))
          .thenAnswer((_) async => null);
      when(() => mockRemote.getClient('1'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            message: 'Network error',
          ));

      final result = await repository.getClient('1');

      expect(result.isFailure, true);
    });
  });

  group('createClient', () {
    test('creates via remote, saves locally, queues sync', () async {
      when(() => mockRemote.createClient(any()))
          .thenAnswer((_) async => createdClient);
      when(() => mockLocal.saveClient(any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.queueMutation(any()))
          .thenAnswer((_) async {});

      final result = await repository.createClient(newClientData);

      expect(result.isSuccess, true);
      verify(() => mockLocal.saveClient(createdClient)).called(1);
      verify(() => mockLocal.queueMutation(any())).called(1);
    });

    test('saves locally and queues when offline', () async {
      when(() => mockRemote.createClient(any()))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ));
      when(() => mockLocal.saveClient(any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.queueMutation(any()))
          .thenAnswer((_) async {});

      final result = await repository.createClient(newClientData);

      expect(result.isSuccess, true); // Optimistic
      verify(() => mockLocal.saveClient(any())).called(1);
      verify(() => mockLocal.queueMutation(any())).called(1);
    });
  });
}
```

### Pattern 6: Provider Test (Riverpod State Transitions)

```dart
void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  group('AuthNotifier', () {
    test('initial state is unauthenticated', () {
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('transitions to authenticated on successful login', () async {
      when(() => mockRepo.login('e@e.com', 'pass'))
          .thenAnswer((_) async => Result.success(LoginResponse(
            accessToken: 'token',
            refreshToken: 'refresh',
            user: testUser,
          )));

      await container.read(authProvider.notifier).login('e@e.com', 'pass');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, testUser);
    });

    test('stays unauthenticated on failed login with error message', () async {
      when(() => mockRepo.login('bad@e.com', 'wrong'))
          .thenAnswer((_) async => Result.failure(
            AppError.auth('Invalid credentials')));

      await container.read(authProvider.notifier).login('bad@e.com', 'wrong');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, contains('Invalid credentials'));
    });

    test('transitions to loading during login', () async {
      when(() => mockRepo.login(any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Result.success(LoginResponse(...));
      });

      final future = container.read(authProvider.notifier).login('e@e.com', 'pass');

      // Check loading state immediately
      final loadingState = container.read(authProvider);
      expect(loadingState.status, AuthStatus.loading);

      await future;
    });
  });
}
```

### Pattern 7: Widget Test (Screen with Mocked Providers)

```dart
void main() {
  testWidgets('LoginScreen renders form fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('LoginScreen shows error on invalid credentials', (tester) async {
    final mockNotifier = MockAuthNotifier();
    when(() => mockNotifier.state)
        .thenReturn(AuthState(status: AuthStatus.error, error: 'Invalid credentials'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('LoginScreen shows loading indicator during auth', (tester) async {
    final mockNotifier = MockAuthNotifier();
    when(() => mockNotifier.state)
        .thenReturn(AuthState(status: AuthStatus.loading));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LoginScreen navigates to register on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => FakeAuthNotifier())],
        child: MaterialApp.router(
          routerConfig: createTestRouter(initialLocation: '/auth/login'),
        ),
      ),
    );

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
```

### Pattern 8: Sync Engine Test

```dart
void main() {
  late SyncEngine syncEngine;
  late MockSyncRemoteSource mockRemote;
  late MockSyncLocalSource mockLocal;
  late MockSyncQueue mockQueue;
  late MockSyncMetadata mockMetadata;
  late MockConnectivityManager mockConnectivity;
  late MockConflictResolver mockResolver;

  setUp(() {
    mockRemote = MockSyncRemoteSource();
    mockLocal = MockSyncLocalSource();
    mockQueue = MockSyncQueue();
    mockMetadata = MockSyncMetadata();
    mockConnectivity = MockConnectivityManager();
    mockResolver = MockConflictResolver();

    syncEngine = SyncEngine(
      remote: mockRemote,
      local: mockLocal,
      queue: mockQueue,
      metadata: mockMetadata,
      connectivity: mockConnectivity,
      conflictResolver: mockResolver,
    );
  });

  group('sync', () {
    test('skips sync when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final result = await syncEngine.sync();

      expect(result.isSuccess, false);
      expect(result.error, contains('offline'));
      verifyNever(() => mockRemote.pull(any()));
      verifyNever(() => mockRemote.push(any()));
    });

    test('push then pull on successful sync', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockQueue.getAllPending())
          .thenAnswer((_) async => [pendingMutation]);
      when(() => mockRemote.push(any()))
          .thenAnswer((_) async => SyncPushResponse(timestamp: 2000));
      when(() => mockRemote.pull(1000))
          .thenAnswer((_) async => pullResponse);
      when(() => mockLocal.upsertRecord(any(), any(), syncStatus: any(named: 'syncStatus')))
          .thenAnswer((_) async {});
      when(() => mockMetadata.getLastPulledAt())
          .thenAnswer((_) async => 1000);

      final result = await syncEngine.sync();

      expect(result.isSuccess, true);
      expect(result.pushedCount, greaterThan(0));
      expect(result.pulledCount, greaterThan(0));
      verify(() => mockRemote.push(any())).called(1);
      verify(() => mockRemote.pull(any())).called(1);
    });
  });

  group('queueMutation', () {
    test('queues and triggers immediate sync when online', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockQueue.add(any())).thenAnswer((_) async {});

      await syncEngine.queueMutation(
        tableName: 'clients',
        recordId: 'client-1',
        operation: SyncOperation.create,
        data: {'name': 'New Client'},
      );

      verify(() => mockQueue.add(any())).called(1);
      // verify sync() was called (with delay)
    });

    test('queues without sync when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockQueue.add(any())).thenAnswer((_) async {});

      await syncEngine.queueMutation(
        tableName: 'clients',
        recordId: 'client-1',
        operation: SyncOperation.create,
        data: {'name': 'New Client'},
      );

      verify(() => mockQueue.add(any())).called(1);
      verifyNever(() => mockRemote.push(any()));
    });
  });
}
```

### Pattern 9: Conflict Resolver Test

```dart
void main() {
  late ConflictResolver resolver;
  late MockSyncLocalSource mockLocal;

  setUp(() {
    mockLocal = MockSyncLocalSource();
    resolver = ConflictResolver(mockLocal);
  });

  group('upsertOnPull', () {
    test('inserts when no local record exists', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => null);

      await resolver.upsertOnPull('clients', incomingClient);

      verify(() => mockLocal.upsertRecord('clients', incomingClient, syncStatus: SyncStatus.synced)).called(1);
    });

    test('skips when local has pending changes', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {'sync_status': SyncStatus.pendingUpdate.value});

      await resolver.upsertOnPull('clients', incomingClient);

      verifyNever(() => mockLocal.upsertRecord(any(), any(), syncStatus: any(named: 'syncStatus')));
    });

    test('overwrites when incoming is newer', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {
            'updated_at': 1000,
            'sync_status': SyncStatus.synced.value,
          });

      await resolver.upsertOnPull('clients', {'id': 'c-1', 'updated_at': 2000});

      verify(() => mockLocal.upsertRecord('clients', {'id': 'c-1', 'updated_at': 2000}, syncStatus: SyncStatus.synced)).called(1);
    });

    test('keeps local when local is newer', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {
            'updated_at': 3000,
            'sync_status': SyncStatus.synced.value,
          });

      await resolver.upsertOnPull('clients', {'id': 'c-1', 'updated_at': 2000});

      verifyNever(() => mockLocal.upsertRecord(any(), any(), syncStatus: any(named: 'syncStatus')));
    });
  });
}
```

### Pattern 10: Integration Test (Full Flow)

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete auth flow: register → login → dashboard', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Start on login screen
    expect(find.text('Sign In'), findsOneWidget);

    // Navigate to register
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Fill registration form
    await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@zirofit.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'Password123!');
    await tester.tap(find.text('Trainer')); // role selection
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('Please verify your email'), findsOneWidget);

    // Navigate back to login
    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    // Login with registered credentials
    await tester.enterText(find.byKey(const Key('email_field')), 'test@zirofit.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'Password123!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify trainer dashboard is shown
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(TrainerShell), findsOneWidget);
  });
}
```

---

## 8. Test Data Management

### 8.1 Factory Pattern

One factory class per model in `test/fixtures/`:

```dart
// test/fixtures/user_fixture.dart
class UserFactory {
  static User create({
    String id = 'test-user-id',
    String name = 'Test Trainer',
    String email = 'trainer@zirofit.test',
    String role = 'trainer',
    UserTier tier = UserTier.pro,
    bool hasCompletedOnboarding = true,
    WeightUnit weightUnit = WeightUnit.kg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      tier: tier,
      hasCompletedOnboarding: hasCompletedOnboarding,
      weightUnit: weightUnit,
      defaultCheckInDay: 0,
      defaultCheckInHour: 9,
      pushTokens: const [],
      stripeCancelAtPeriodEnd: false,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  static Map<String, dynamic> toJson(User user) => user.toJson();

  static String get authToken => 'test-jwt-token.eyJzdWIiOiJ0ZXN0In0.test-signature';
  static String get refreshToken => 'test-refresh-token';
}
```

### 8.2 Seed Data

Pre-defined test data sets for integration tests:

```dart
// test/fixtures/index.dart
final testUser = UserFactory.create();
final testClient = ClientFactory.create(
  id: 'test-client-id',
  trainerId: testUser.id,
  name: 'Test Client',
);
final testWorkoutSession = WorkoutSessionFactory.create(
  id: 'test-session-id',
  clientId: testClient.id,
);

// Convenience bundles for integration tests
final seedData = SeedData(
  user: testUser,
  clients: [testClient],
  sessions: [testWorkoutSession],
);
```

### 8.3 Test Tokens

Fixed JWT tokens for auth tests that don't require real Supabase validation:

```dart
class TestTokens {
  static const String validAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJ0ZXN0LXVzZXItaWQiLCJyb2xlIjoidHJhaW5lciIsImV4cCI6OTk5OTk5OTk5OX0.'
      'test-signature';

  static const String expiredAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJ0ZXN0LXVzZXItaWQiLCJyb2xlIjoidHJhaW5lciIsImV4cCI6MTB9.'
      'test-signature';
}
```

### 8.4 Sync Payload Fixtures

```dart
// test/fixtures/sync_payload_fixtures.dart
final pullResponseJson = {
  'data': {
    'changes': {
      'clients': {
        'created': [
          {'id': 'client-1', 'name': 'John', 'trainer_id': 'trainer-1', 'created_at': 1700000000000, 'updated_at': 1700000000000, 'deleted_at': null},
        ],
        'updated': [],
        'deleted': [],
      },
      'workout_sessions': {
        'created': [],
        'updated': [],
        'deleted': ['session-deleted-1'],
      },
    },
    'timestamp': 1700000001000,
  },
};

final pushRequestJson = {
  'changes': {
    'clients': {
      'created': [{'id': 'local-client-1', 'name': 'Offline Created', ...}],
      'updated': [],
      'deleted': [],
    },
  },
};
```

### 8.5 Cleanup Rules

```
┌──────────────────────────────────────────────────────────────────┐
│                    TEST CLEANUP RULES                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  • Each test gets its own in-memory Drift DB (isolated)         │
│  • ProviderContainer is disposed in tearDown                    │
│  • SharedPreferences is reset between tests                     │
│  • FakeSecureStorage is fresh per test                           │
│  • Timer and Stream subscriptions are cancelled in tearDown     │
│  • Dio MockAdapter is reset between tests                       │
│  • No state leaks between tests                                  │
│                                                                  │
│  tearDown() template:                                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ tearDown(() {                                         │       │
│  │   container.dispose();   // Riverpod cleanup          │       │
│  │   db.close();             // Drift cleanup            │       │
│  │   mockAdapter.dispose(); // Dio mock cleanup          │       │
│  │   reset(mockRepo);       // mocktail reset            │       │
│  │ });                                                   │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 9. Continuous Integration

### 9.1 Pre-Commit Hook

```yaml
# .githooks/pre-commit
#!/bin/sh
echo "Running pre-commit checks..."

# 1. Analyze changed files
flutter analyze --fatal-infos
if [ $? -ne 0 ]; then
  echo "❌ Flutter analyze failed. Fix issues before committing."
  exit 1
fi

# 2. Run tests on changed packages
flutter test --coverage
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Fix issues before committing."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
```

### 9.2 GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test & Coverage

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run unit + widget tests
        run: flutter test --coverage --machine > test-report.json

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
          flags: unittests

  integration:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
      - name: Install dependencies
        run: flutter pub get
      - name: Run integration tests
        run: flutter test integration_test/ --retry=1

  e2e:
    runs-on: ubuntu-latest
    needs: integration
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
      - name: Install dependencies
        run: flutter pub get
      - name: Run E2E tests
        run: flutter test e2e/
```

### 9.3 Test Selection Strategy

| Event | Test Run | Coverage Upload |
|-------|----------|----------------|
| **Push to feature branch** | Unit + Widget | Yes |
| **PR to develop** | Unit + Widget + Integration | Yes |
| **PR to main** | Unit + Widget + Integration + E2E | Yes |
| **Nightly** | Full suite + golden tests | Yes (historical) |
| **Release tag** | Full suite + performance benchmarks | Yes |

### 9.4 Coverage Gates

| Phase | Minimum Coverage | Failing PR? |
|-------|-----------------|-------------|
| Phase 1 (Foundation) | 60% | No (informational) |
| Phase 2 (Core Features) | 70% | Yes |
| Phase 3 (Enhanced Features) | 75% | Yes |
| Phase 4 (Extended Features) | 75% | Yes |
| Phase 5 (Advanced) | 70% | Yes |
| Release | 80% | Yes (blocking) |

---

## 10. Flaky Test Management

### 10.1 Retry Strategy

| Test Type | Retries | Mechanism |
|-----------|---------|-----------|
| **Unit tests** | 0 | Must be deterministic |
| **Widget tests** | 3 | `flutter test --test-randomize-ordering-seed=auto` run 3× |
| **Integration tests** | 1 | `--retry=1` flag |
| **E2E tests** | 2 | Custom retry wrapper |

### 10.2 Widget Test Retry Pattern

```dart
// test/helpers/retry.dart
Future<void> retryWidgetTest(
  WidgetTester tester,
  Future<void> Function() testBody, {
  int maxRetries = 3,
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await testBody();
      return; // Success
    } on TestFailure catch (e) {
      if (attempt == maxRetries) rethrow;
      print('⚠️ Test attempt $attempt failed, retrying...');
      await tester.binding.reset();
    }
  }
}
```

### 10.3 Quarantine List

```dart
// test/quarantine.txt
# Known-flaky tests — moved here while being fixed
# Format: file_path | issue | date_quarantined
#
# test/widget/workout/active_workout_screen_test.dart | Rest timer race condition | 2026-04-28
# test/integration/sync_flow_test.dart | Mock server timing issue | 2026-04-29
```

### 10.4 Flaky Test Detection

- Tests that fail >10% of CI runs are flagged for quarantine
- A GitHub issue is created automatically for each quarantined test
- Quarantined tests are excluded from CI but run nightly for monitoring
- Tests are un-quarantined only after passing 10 consecutive nightly runs

---

## 11. Test Naming Conventions

### 11.1 File Naming

```
Unit tests:     {class_name}_test.dart
Widget tests:   {screen_name}_test.dart
Integration:    {flow_name}_test.dart
E2E tests:      {scenario_name}_test.dart
Fixtures:       {domain}_fixture.dart  (or {model}_fixture.dart)
Helpers:        {utility}_helper.dart
```

### 11.2 Test Description Format

```
Unit tests:     'ModelName methodName: description'
                'AuthRepository login: returns user on success'
                'ClientLocalSource saveClient: persists and retrieves by ID'
                'ConflictResolver upsertOnPull: overwrites when incoming is newer'

Widget tests:   'ScreenName: description'
                'LoginScreen: shows error on invalid credentials'
                'ActiveWorkoutScreen: displays exercise list'
                'SyncIndicator: shows syncing spinner when syncing'

Integration:    'FlowName: description'
                'AuthFlow: user can login and see dashboard'
                'WorkoutFlow: start session, log exercise, finish, view in history'

E2E:            'Role Journey: description'
                'Trainer Journey: login, view clients, start workout, finish'
```

### 11.3 Group Naming

```dart
group('User model', () { ... });
group('AuthRepository', () {
  group('login', () { ... });
  group('register', () { ... });
  group('logout', () { ... });
});
group('LoginScreen', () { ... });
```

---

## 12. Per-Feature Test Plan Summary

### Legend

| Column | Meaning |
|--------|---------|
| **Model Tests** | Number of model round-trip tests needed |
| **Service Tests** | Remote + local data source tests |
| **Repo Tests** | Repository-level integration tests |
| **Provider Tests** | Riverpod state transition tests |
| **Widget Tests** | Screen and reusable widget tests |
| **Integration** | Full-flow integration tests |
| **E2E** | End-to-end scenario tests |
| **Sync** | Is this feature offline-synced? |

### P0 — Launch Critical Features

| Feature | Model Tests | Service Tests | Repo Tests | Provider Tests | Widget Tests | Integration | E2E | Sync |
|---------|-------------|---------------|------------|----------------|--------------|-------------|-----|------|
| **1. Auth & Onboarding** | | | | | | | | |
| Email/Password Login | User | 2 | 1 | 1 | 2 | — | ✓ | Live |
| Email/Password Registration | User | 2 | 1 | 1 | 2 | ✓ | ✓ | Live |
| OAuth (Google/Apple) | — | 1 | 1 | 1 | 1 | ✓ | — | Live |
| Token Refresh | — | 2 | 1 | 1 | — | ✓ | — | Live |
| Auto-Login (Session Restore) | — | 2 | 2 | 2 | — | ✓ | ✓ | Live |
| Forgot/Update Password | — | 2 | 1 | — | 1 | ✓ | — | Live |
| Sign Out | — | 1 | 1 | 1 | — | ✓ | — | Live |
| Complete Onboarding | — | 1 | 1 | 1 | 1 | — | — | Live |
| **2. Dashboard** | | | | | | | | |
| Trainer Dashboard | — | 1 | 1 | 1 | 2 | ✓ | — | Partial |
| Client Dashboard | — | 1 | 1 | 1 | 2 | ✓ | — | Partial |
| Dashboard Insights | — | 1 | 1 | — | — | — | — | Live |
| Mobile Home | — | 1 | 1 | — | 1 | — | — | Partial |
| **3. Workout Management** | | | | | | | | |
| Start Workout | — | 1 | 1 | — | — | ✓ | — | Full |
| Live Workout Tracking | WorkoutSession, ClientExerciseLog | 2 | 2 | 1 | 2 | ✓ | ✓ | Full |
| Exercise Logging | — | 2 | 1 | 1 | 1 | ✓ | — | Full |
| Rest Timer | — | 1 | 1 | — | 1 | — | — | Full |
| Finish/Cancel Workout | — | 2 | 1 | — | 1 | ✓ | — | Full |
| Plan/Schedule Workouts | — | 1 | 1 | — | 1 | — | — | Full |
| Workout History & Detail | — | 1 | 1 | 1 | 2 | ✓ | — | Full |
| Workout Summary | — | 1 | — | — | 1 | — | — | Full |
| Session Comments | WorkoutSessionComment | 1 | 1 | — | — | — | — | Full |
| Save as Template | — | 1 | 1 | — | — | — | — | Full |
| **4. Client Management** | | | | | | | | |
| Client List | Client | 1 | 1 | 1 | 2 | ✓ | — | Full |
| Client Detail | — | 1 | 1 | 1 | 2 | — | — | Full |
| Create/Update/Delete | — | 3 | 2 | — | 1 | ✓ | ✓ | Full |
| Client Dashboard | — | 1 | 1 | — | 1 | — | — | Full |
| Client Measurements | ClientMeasurement | 4 | 2 | — | 1 | — | — | Full |
| Client Progress Photos | ClientProgressPhoto | 3 | 1 | — | 1 | — | — | Full |
| Client Assessments | Assessment, AssessmentResult | 4 | 2 | — | 1 | — | — | Full |
| Client Exercise Logs | — | 1 | — | — | — | — | — | Full |
| Client Sessions | — | 3 | — | — | — | — | — | Full |
| Client Invite/Link | — | 2 | 1 | — | 1 | — | — | Live |
| Client Avatar | — | 2 | — | — | — | — | — | Full |
| Client Sharing | — | 2 | 1 | — | 1 | — | — | Full |
| Client Analytics | — | 1 | 1 | — | 1 | — | — | Full |
| **5. Trainer Profile** | | | | | | | | |
| Profile Core Info | Profile | 1 | 1 | — | 2 | — | — | Full |
| Profile Photo | — | 1 | — | — | — | — | — | Full |
| Text Content | — | 1 | 1 | — | — | — | — | Full |
| Branding | — | 1 | 1 | — | — | — | — | Full |
| Services CRUD | Service | 3 | 1 | — | 1 | — | — | Full |
| Packages CRUD | Package, ClientPackage | 3 | 1 | — | 1 | — | — | Full |
| Testimonials CRUD | Testimonial | 3 | 1 | — | 1 | — | — | Full |
| Benefits CRUD | Benefit | 3 | 1 | — | 1 | — | — | Full |
| Social/External Links | SocialLink, ExternalLink | 3 | 1 | — | 1 | — | — | Full |
| Transformation Photos | TransformationPhoto | 3 | 1 | — | 1 | — | — | Full |
| Custom Exercises | Exercise | 3 | 1 | — | — | — | — | Full |
| Availability | — | 1 | 1 | — | 1 | — | — | Full |
| Other Profile sub-models | Location | — | — | — | — | — | — | Full |

### P1 — Important Features

| Feature | Model Tests | Service Tests | Repo Tests | Provider Tests | Widget Tests | Integration | E2E | Sync |
|---------|-------------|---------------|------------|----------------|--------------|-------------|-----|------|
| **6. Programs & Templates** | WorkoutProgram, WorkoutTemplate, TemplateExercise, ClientProgramAssignment | 8 | 3 | 1 | 4 | — | — | Full |
| **7. Exercise Library** | Exercise | 3 | 1 | 1 | 2 | — | — | Full |
| **8. Calendar & Scheduling** | — | 5 | 2 | 1 | 2 | ✓ | — | Partial |
| **9. Check-Ins** | CheckIn | 5 | 2 | 1 | 3 | ✓ | — | Full |
| **10. Bookings** | Booking | 4 | 2 | 1 | 2 | ✓ | — | Partial |
| **11. Public Events** | Event, EventBooking | 5 | 2 | — | 3 | — | — | Live |
| **12. Notifications** | Notification | 3 | 1 | 1 | 1 | — | — | Partial |
| **13. Chat** | Conversation, Message | 2 | 1 | 1 | 2 | — | — | Partial |
| **20. Trainer Settings** | — | 2 | — | — | 1 | — | — | Partial |
| **22. System/Config** | SystemSetting | 1 | — | — | — | — | — | Live |
| **23. Offline Sync** | — | 2 | 1 | 1 | 2 | ✓ | ✓ | N/A |

### P2 — Nice-to-Have Features

| Feature | Model Tests | Service Tests | Repo Tests | Provider Tests | Widget Tests | Integration | E2E | Sync |
|---------|-------------|---------------|------------|----------------|--------------|-------------|-----|------|
| **14. Billing & Packages** | — | 4 | 1 | 1 | 2 | — | — | Live |
| **15. Nutrition** | Recipe, RecipeTag, Product | 5 | 1 | — | 1 | — | — | Partial |
| **16. Habits** | DailyHabit, HabitLog | 3 | 1 | — | 1 | — | — | Full |
| **17. Resource Vault** | Resource, ClientResource | 3 | 1 | — | 1 | — | — | Partial |
| **18. Explore/Social** | — | 7 | 2 | — | 2 | — | — | Live |
| **24. Miscellaneous** | BlogPost, SupportTicket | 6 | 2 | — | 2 | — | — | Live |

### P3 — Future Features

| Feature | Model Tests | Service Tests | Repo Tests | Provider Tests | Widget Tests | Integration | E2E | Sync |
|---------|-------------|---------------|------------|----------------|--------------|-------------|-----|------|
| **19. AI Features** | — | 4 | — | — | 2 | — | — | Live |
| **21. Admin Panel** | — | 7 | — | — | 3 | — | — | Live |

### Test Count Summary

| Priority | Model Tests | Service Tests | Repo Tests | Provider Tests | Widget Tests | Integration | E2E | Total |
|----------|-------------|---------------|------------|----------------|--------------|-------------|-----|-------|
| **P0** | ~12 | ~65 | ~38 | ~16 | ~32 | ~8 | ~4 | ~175 |
| **P1** | ~6 | ~40 | ~16 | ~7 | ~20 | ~4 | ~2 | ~95 |
| **P2** | ~4 | ~28 | ~7 | ~1 | ~9 | — | — | ~49 |
| **P3** | — | ~11 | — | — | ~5 | — | — | ~16 |
| **Sync (cross-cutting)** | — | ~8 | ~4 | ~2 | ~2 | ~1 | ~1 | ~18 |
| **Utils (cross-cutting)** | — | — | — | — | — | — | — | ~7 |
| **Shared Widgets** | — | — | — | — | ~5 | — | — | ~5 |
| **Total** | **~22** | **~152** | **~65** | **~26** | **~73** | **~13** | **~7** | **~365** |

---

## 13. Testing Tools & Dependencies

### 13.1 dev_dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Mocking
  mocktail: ^1.0.0            # Preferred for Dart 3 — no code generation needed
  
  # Test utilities
  fake_async: ^1.3.0          # Deterministic timer control in tests
  golden_toolkit: ^0.15.0    # Golden file tests for visual regression
  
  # HTTP mocking
  # Dio MockAdapter is built into dio — no extra dependency needed
  
  # Code generation
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.16.0
  
  # Linting & analysis
  very_good_analysis: ^5.0.0  # Strict lint rules
  
  # Coverage
  # flutter test --coverage generates lcov.info natively
  
  # Faker for test data
  faker: ^2.1.0               # Generate realistic test data
```

### 13.2 Tool Justification

| Tool | Purpose |
|------|---------|
| **mocktail** | Mock classes without code generation. Preferred over mockito for Dart 3 compatibility. Used for Dio responses, Drift DAOs, connectivity streams, secure storage. |
| **fake_async** | Control `Timer`, `Future.delayed`, and `Stopwatch` deterministically in tests. Essential for sync engine timing tests, rest timer tests, debounced operations. |
| **golden_toolkit** | Visual regression testing for widgets. Compare screenshots against baselines. Used for critical screens: login, dashboard, workout. |
| **Dio MockAdapter** | Built into Dio. No extra dependency. Intercept HTTP requests at the adapter level — works without a real server. |
| **Drift NativeDatabase.memory()** | Built into Drift. In-memory SQLite for tests. Fast, isolated, no file system interaction. |
| **faker** | Generate realistic names, emails, phone numbers, addresses for test fixtures. Avoids hardcoded test data duplication. |
| **very_good_analysis** | Strict lint rules that catch common issues before tests run. Enforces consistent code style. |

### 13.3 Test Runner Configuration

```yaml
# flutter_test configuration in pubspec.yaml
flutter:
  uses-material-design: true

# .flutter-plugins-dependencies (auto-generated)

# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    require_trailing_commas: false
    lines_longer_than_80_chars: false
```

### 13.4 Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/models/user_test.dart

# Run widget tests only
flutter test test/widget/

# Run integration tests
flutter test integration_test/

# Run with retries
flutter test --retry=3

# Run with random order to detect leaky tests
flutter test --test-randomize-ordering-seed=42

# Generate HTML coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 13.5 VS Code Test Configuration

```json
// .vscode/settings.json
{
  "dart.runInDebug": true,
  "flutterTestDirectory": "test/",
  "files.exclude": {
    "**/*.g.dart": true,
    "**/*.freezed.dart": true
  }
}
```

---

## Appendix A: First-Test Checklist for New Features

When starting TDD on a new feature, follow this checklist:

```
[ ] 1. Identify the primary model(s) from DATA_MODELS.md
[ ] 2. Write model test (round-trip, null handling, equality)
[ ] 3. Write model class (fromJson/toJson, copyWith, ==, hashCode)
[ ] 4. Write remote source test (mock HTTP, verify request/response)
[ ] 5. Write remote source class (Dio calls + response parsing)
[ ] 6. Write local source test (mock Drift, verify CRUD)
[ ] 7. Write local source class (Drift DAO calls)
[ ] 8. Write repository test (mock both sources, verify offline-first)
[ ] 9. Write repository class (Result type, try local → remote → cache)
[ ] 10. Write use case test (if complex business logic)
[ ] 11. Write use case class (if needed)
[ ] 12. Write provider test (state transitions)
[ ] 13. Write provider class (Riverpod notifier)
[ ] 14. Write widget test (loading/error/data states)
[ ] 15. Write screen/widget class (AsyncValue.when pattern)
[ ] 16. All green → commit
[ ] 17. Integration test (full flow with mocked backend)
[ ] 18. E2E test (if critical flow)
```

## Appendix B: Common Testing Gotchas

| Gotcha | Solution |
|--------|----------|
| **Drift database not closed** | Always call `db.close()` in `tearDown` |
| **ProviderContainer leaks** | Always call `container.dispose()` in `tearDown` |
| **Dio MockAdapter state leak** | Create fresh Dio + MockAdapter in `setUp` |
| **Stream subscription not cancelled** | Use `ref.onDispose()` in providers, close in `tearDown` |
| **SharedPreferences state leak** | Call `SharedPreferences.setMockInitialValues({})` in `setUp` |
| **Timer not completed in test** | Use `fake_async` or `tester.pump(Duration(...))` |
| **Async gaps in widget tests** | Use `tester.pumpAndSettle()` after state-changing actions |
| **Empty cup (Drift test)** | Insert test data before query tests |
| **GoRouter redirect in tests** | Use a minimal test router config without redirects |
| **Golden file mismatch on CI** | Use `--update-goldens` on CI to regenerate |

---

> **Document Version:** 1.0.0
> **Last Updated:** 2026-05-01
> **Estimated Total Tests:** ~365 (22 model, 152 service, 65 repo, 26 provider, 73 widget, 13 integration, 7 E2E, 7 utils)
> **Target Coverage:** 80%+ overall
