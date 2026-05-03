# Ziro Fit Flutter — Testing Strategy

> **Purpose:** Comprehensive testing infrastructure blueprint for the Ziro Fit Flutter app — an offline-first fitness business management platform. Defines mocking infrastructure, test data factories, CI pipeline, coverage gates, and quality enforcement for every layer of the application.
>
> **Last updated:** 2026-05-01
>
> **Related docs:** `TDD_PLAN.md` (test-driven development plan), `ARCHITECTURE.md` (app architecture), `DATA_MODELS.md` (Dart data models), `API_REFERENCE.md` (REST endpoints), `AUTH_FLOW.md` (auth implementation), `OFFLINE_SYNC.md` (sync strategy), `FEATURE_COVERAGE.md` (feature mapping)

---

## Table of Contents

1. [Testing Philosophy & Pyramid](#1-testing-philosophy--pyramid)
2. [Mocking Infrastructure](#2-mocking-infrastructure)
3. [Database Mocking (Drift In-Memory)](#3-database-mocking-drift-in-memory)
4. [Auth Mocking](#4-auth-mocking)
5. [Secure Storage & Connectivity Mocking](#5-secure-storage--connectivity-mocking)
6. [Test Data Factories & Fixtures](#6-test-data-factories--fixtures)
7. [Test Helpers & Utilities](#7-test-helpers--utilities)
8. [Provider Override Architecture](#8-provider-override-architecture)
9. [CI/CD Pipeline (GitHub Actions)](#9-cicd-pipeline-github-actions)
10. [Coverage Minimum Thresholds](#10-coverage-minimum-thresholds)
11. [Golden File Testing](#11-golden-file-testing)
12. [Performance Testing](#12-performance-testing)
13. [Integration Test Patterns](#13-integration-test-patterns)
14. [End-to-End Test Patterns](#14-end-to-end-test-patterns)
15. [Sync Engine Testing](#15-sync-engine-testing)
16. [Regression Test Strategy](#16-regression-test-strategy)
17. [Testing Configuration](#17-testing-configuration)
18. [Test Runners & Scripts](#18-test-runners--scripts)
19. [Test Lifecycle Best Practices](#19-test-lifecycle-best-practices)
20. [Accessibility Testing](#20-accessibility-testing)
21. [Flaky Test Management](#21-flaky-test-management)
22. [Test Status Dashboard](#22-test-status-dashboard)
23. [Package & Build Configuration](#23-package--build-configuration)
24. [Appendix: Test Count Summary](#24-appendix-test-count-summary)

---

## 1. Testing Philosophy & Pyramid

### 1.1 TDD Cycle Applied

Every feature follows the three-phase TDD cycle adapted for Flutter's layered architecture:

```
+-----------------------------------------------------------+
|                    TDD CYCLE                               |
|                                                           |
|  1. RED    Write a failing test that defines expected     |
|            behavior before writing any implementation     |
|                                                           |
|  2. GREEN  Write the minimum code required to make the    |
|            test pass. No optimization, no refactoring.    |
|                                                           |
|  3. REFACTOR  Clean up the code while keeping tests green.|
|               Remove duplication, improve naming, extract |
|               shared logic.                               |
|                                                           |
|  4. COMMIT  Run full test suite, commit all green.        |
|                                                           |
+-----------------------------------------------------------+
```

### 1.2 Testing Pyramid

```
                    /\
                   /  \
                  /    \        E2E Tests (5-10%)
                 /      \       integration_test / real device
                /--------\
               /          \     Widget Tests (20-30%)
              /            \    per feature/screen
             /--------------\
            /                \   Unit Tests (60-70%)
           /                  \  models, repos, providers,
          /                    \ services, sync engine, utils
         /----------------------\
```

**Distribution rationale for Ziro Fit:**

| Layer | Percentage | Why |
|-------|-----------|-----|
| **Unit tests** | 60-70% | 30+ models with round-trip serialization, 120+ endpoints across 24 data sources, 20+ repositories, sync engine (7 modules), auth interceptors, utility functions |
| **Widget tests** | 20-30% | ~40+ screens across 24 feature groups, 15+ reusable shared widgets, state-dependent rendering (loading/error/empty/data) |
| **Integration tests** | 5-10% | 8 critical user journeys: login to dashboard, start-to-finish workout, offline-to-online sync, client CRUD, booking flow, check-in flow, register flow, navigation |
| **E2E tests** | 5-10% | 5 full role-based scenarios: trainer journey, client journey, offline sync, admin moderation, auth flows |

### 1.3 Test Behavior, Not Implementation

Tests validate **what** the code does, not **how**:

- **Repository tests** mock remote/local sources and verify data flow (not SQL queries)
- **Provider tests** verify state transitions (initial to loading to data to error), not internal notifier implementation
- **Widget tests** verify rendered widgets and user interaction outcomes, not widget tree internals
- **Sync engine tests** verify push/pull orchestration, not network call internals

---

## 2. Mocking Infrastructure

### 2.1 HTTP Mocking (Dio MockAdapter)

The Dio `MockAdapter` intercepts HTTP requests at the adapter level -- no real server required. Every test creates a fresh `Dio` + `MockAdapter` in `setUp`.

```dart
// test/helpers/mock_api_client.dart
import 'package:dio/dio.dart';

class MockApiClient {
  late final Dio dio;
  late final MockAdapter mockAdapter;

  MockApiClient() {
    dio = Dio(BaseOptions(baseUrl: 'https://www.ziro.fit/api'));
    mockAdapter = MockAdapter();
    dio.httpClientAdapter = mockAdapter;
  }

  /// Mock a POST request with optional body matching.
  void mockPost(
    String path, {
    required int statusCode,
    Map<String, dynamic>? body,
    Map<String, dynamic>? response,
  }) {
    mockAdapter.onPost(path, (server) {
      return server.reply(
        statusCode,
        response ?? {'data': body},
        delay: const Duration(milliseconds: 10),
      );
    }, data: body);
  }

  /// Mock a GET request.
  void mockGet(
    String path, {
    required int statusCode,
    Map<String, dynamic>? response,
  }) {
    mockAdapter.onGet(path, (server) {
      return server.reply(statusCode, response ?? {'data': {}});
    });
  }

  /// Mock a PUT request.
  void mockPut(
    String path, {
    required int statusCode,
    Map<String, dynamic>? body,
    Map<String, dynamic>? response,
  }) {
    mockAdapter.onPut(path, (server) {
      return server.reply(statusCode, response ?? {'data': body});
    }, data: body);
  }

  /// Mock a DELETE request.
  void mockDelete(
    String path, {
    required int statusCode,
    Map<String, dynamic>? response,
  }) {
    mockAdapter.onDelete(path, (server) {
      return server.reply(statusCode, response ?? {'data': {}});
    });
  }

  /// Mock an error response.
  void mockError(
    String path,
    int statusCode,
    String message, {
    String method = 'GET',
  }) {
    switch (method) {
      case 'GET':
        mockAdapter.onGet(path, (server) {
          return server.reply(statusCode, {
            'error': {'message': message},
          });
        });
        break;
      case 'POST':
        mockAdapter.onPost(path, (server) {
          return server.reply(statusCode, {
            'error': {'message': message},
          });
        });
        break;
    }
  }

  /// Verify that a specific request was made.
  int requestCount(String method, String path) {
    return mockAdapter.requestCount(method, path);
  }

  void dispose() {
    mockAdapter.dispose();
  }
}
```

### 2.2 Dio MockAdapter -- Granular Pattern

For tests that need to verify request details inline:

```dart
// test/helpers/mock_dio.dart
import 'package:dio/dio.dart';

class MockResponse {
  final int statusCode;
  final Map<String, dynamic> body;
  const MockResponse(this.statusCode, this.body);
}

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
          headers: {'content-type': ['application/json']},
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
```

### 2.3 Mocking Strategy Reference

| Dependency | Mocking Approach | Tool | Scope |
|-----------|-----------------|------|-------|
| **HTTP (Dio)** | Dio `MockAdapter` -- intercept requests, return canned responses | `dio` built-in | Per test |
| **Database (Drift)** | `NativeDatabase.memory()` -- in-memory SQLite per test | Drift built-in | Per test |
| **Supabase Auth** | Mock `GoTrueClient` via `mocktail` -- control session state | `mocktail` | Per test |
| **Connectivity** | `StreamController<bool>` -- emit online/offline on demand | `dart:async` | Per test |
| **Secure Storage** | `FakeSecureStorage` implementing `FlutterSecureStorage` | Custom fake | Per test |
| **SharedPreferences** | `SharedPreferences.setMockInitialValues({})` -- in-memory | shared_preferences | Per suite |
| **Riverpod** | `ProviderContainer` with `overrides` -- inject mock deps | Riverpod testing | Per test |
| **GoRouter** | Direct instantiation with minimal route config | `go_router` | Per test |
| **Image Picker** | Mock `ImagePicker` via `mocktail` | `mocktail` | Per test |
| **Local Auth** | Mock `LocalAuthentication` via `mocktail` | `mocktail` | Per test |

---

## 3. Database Mocking (Drift In-Memory)

Every test that requires database access gets a fresh in-memory SQLite instance. This is fast, isolated, and requires no file system interaction.

```dart
// test/helpers/test_database.dart
import 'package:drift/native.dart';
import 'package:zirofit/core/database/app_database.dart';

/// Creates an in-memory Drift database for testing.
/// Call in setUp() and close in tearDown().
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

/// Pre-seeded test database with standard fixture data.
Future<AppDatabase> createSeededTestDatabase() async {
  final db = AppDatabase(NativeDatabase.memory());

  await db.batch((batch) {
    // Insert seed data using row companions
    // batch.insert(db.clients, ClientsCompanion(
    //   id: Value('test-client-id'),
    //   name: Value('Test Client'),
    // ));
  });

  return db;
}
```

### 3.1 Usage Pattern in Tests

```dart
// test/unit/repositories/client_repository_test.dart
void main() {
  late AppDatabase db;
  late ClientLocalSource localSource;

  setUp(() {
    db = createTestDatabase();
    localSource = ClientLocalSource(db);
  });

  tearDown(() async {
    await db.close();
  });

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

    test('getAllClients returns only active (non-deleted) clients', () async {
      await localSource.saveClient(testClient);
      await localSource.saveClient(testClient2);
      await localSource.softDeleteClient(testClient.id);

      final clients = await localSource.getAllClients();
      expect(clients.length, 1);
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

---

## 4. Auth Mocking

Auth is the most cross-cutting dependency. We provide three levels of mock:

### 4.1 Mock Supabase Client

```dart
// test/helpers/mock_auth.dart
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

/// Creates a mock Supabase session for testing.
MockUser createMockUser({
  String id = 'test-user-id',
  String email = 'trainer@zirofit.test',
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  return user;
}
```

### 4.2 Fake Auth Notifier for Widget Tests

```dart
// test/helpers/fake_auth_notifier.dart
import 'package:zirofit/features/auth/providers/auth_state.dart';
import 'package:zirofit/data/models/user.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> {
  FakeAuthNotifier() : super(const AuthState.initial());

  void setInitial() => state = const AuthState.initial();
  void setLoading() => state = const AuthState.loading();
  void setAuthenticated(User user) {
    state = AuthState.authenticated(user);
  }
  void setUnauthenticated() => state = const AuthState.unauthenticated();
  void setError(String message) => state = AuthState.error(message);
}
```

### 4.3 Auth Provider Override for Each Auth State

```dart
// test/helpers/auth_overrides.dart
/// Pre-built provider overrides for each auth state.
/// Use in widget tests to control the auth state without real API calls.

final unauthenticatedOverride = authProvider.overrideWith((ref) {
  final notifier = FakeAuthNotifier();
  notifier.setUnauthenticated();
  return notifier;
});

final authenticatedTrainerOverride = authProvider.overrideWith((ref) {
  final notifier = FakeAuthNotifier();
  notifier.setAuthenticated(UserFactory.createTrainer());
  return notifier;
});

final authenticatedClientOverride = authProvider.overrideWith((ref) {
  final notifier = FakeAuthNotifier();
  notifier.setAuthenticated(UserFactory.createClient());
  return notifier;
});

final loadingOverride = authProvider.overrideWith((ref) {
  final notifier = FakeAuthNotifier();
  notifier.setLoading();
  return notifier;
});

final errorOverride = authProvider.overrideWith((ref) {
  final notifier = FakeAuthNotifier();
  notifier.setError('Authentication failed');
  return notifier;
});
```

---

## 5. Secure Storage & Connectivity Mocking

### 5.1 Fake Secure Storage

```dart
// test/helpers/fake_secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeSecureStorage implements FlutterSecureStorage {
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
  Future<bool> containsKey({required String key}) async =>
      _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.from(_store);
}
```

### 5.2 Fake Connectivity

```dart
// test/helpers/fake_connectivity.dart
import 'dart:async';

/// A controllable connectivity mock that simulates online/offline transitions.
class FakeConnectivity implements Connectivity {
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() => _controller.close();
}
```

### 5.3 SharedPreferences Mocking

```dart
// In setUp:
setUp(() {
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': true,
    'last_sync_timestamp': 1700000000000,
  });
});
```

---

## 6. Test Data Factories & Fixtures

### 6.1 Fixture Organization

```
test/fixtures/
+-- auth/
|   +-- login_response.json            # Full login API response
|   +-- register_response.json         # Full register API response
|   +-- refresh_response.json          # Token refresh response
|   +-- me_response.json               # GET /api/auth/me response
|   +-- user_profile.json              # ExtendedProfile fixture
+-- workout/
|   +-- workout_session.json           # WorkoutSession fixture
|   +-- exercise_log.json              # ClientExerciseLog fixture
|   +-- workout_history.json           # Paginated history response
|   +-- workout_summary.json           # Session summary response
|   +-- rest_timer.json                # Rest timer response
+-- client/
|   +-- client_list.json               # GET /api/clients response
|   +-- client_detail.json             # GET /api/clients/[id] response
|   +-- client_dashboard.json          # Client dashboard response
|   +-- measurement.json               # ClientMeasurement fixture
|   +-- measurements_list.json         # List of measurements
|   +-- progress_photo.json            # ClientProgressPhoto fixture
+-- trainer/
|   +-- trainer_profile.json           # Full profile response
|   +-- services.json                  # Services list fixture
|   +-- packages.json                  # Packages list fixture
|   +-- testimonials.json              # Testimonials list fixture
|   +-- benefits.json                  # Benefits list fixture
|   +-- availability.json              # Availability fixture
+-- sync/
|   +-- pull_response.json             # Full pull response (all tables)
|   +-- push_response.json             # Push success response
|   +-- initial_pull_response.json     # Fresh install pull response
+-- common/
    +-- paginated_response.json        # Paginated list envelope
    +-- error_response.json            # Standard error envelope
    +-- success_response.json          # Standard success envelope
```

### 6.2 Factory Classes

Every model in `DATA_MODELS.md` gets a factory class. Factories provide:
- A `create()` method with named parameters and sensible defaults
- A `json()` method for API response simulation
- Pre-built constants for common test scenarios

```dart
// test/fixtures/factories/user_factory.dart
import 'package:zirofit/data/models/user.dart';

class UserFactory {
  static const String defaultId = 'test-user-id-0000';
  static const String defaultName = 'Test Trainer';
  static const String defaultEmail = 'trainer@zirofit.test';

  /// Create a trainer user with sensible defaults.
  static User createTrainer({
    String id = defaultId,
    String name = defaultName,
    String email = defaultEmail,
    String role = 'trainer',
    UserTier tier = UserTier.pro,
    bool hasCompletedOnboarding = true,
    String? subscriptionStatus = 'active',
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      tier: tier,
      hasCompletedOnboarding: hasCompletedOnboarding,
      subscriptionStatus: subscriptionStatus,
      defaultCheckInDay: 0,
      defaultCheckInHour: 9,
      weightUnit: WeightUnit.kg,
      pushTokens: const [],
      stripeCancelAtPeriodEnd: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Create a client user.
  static User createClient({
    String id = 'test-client-user-id',
    String name = 'Test Client',
    String email = 'client@zirofit.test',
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      role: 'client',
      tier: UserTier.starter,
      hasCompletedOnboarding: true,
      defaultCheckInDay: 0,
      defaultCheckInHour: 9,
      weightUnit: WeightUnit.kg,
      pushTokens: const [],
      stripeCancelAtPeriodEnd: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Full JSON representation for API responses.
  static Map<String, dynamic> json({
    String id = defaultId,
    String name = defaultName,
    String email = defaultEmail,
    String role = 'trainer',
    String tier = 'PRO',
    bool hasCompletedOnboarding = true,
    String? subscriptionStatus = 'active',
  }) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'tier': tier,
      'has_completed_onboarding': hasCompletedOnboarding,
      'subscription_status': subscriptionStatus,
      'default_check_in_day': 0,
      'default_check_in_hour': 9,
      'weight_unit': 'KG',
      'push_tokens': <String>[],
      'stripe_cancel_at_period_end': false,
      'created_at': 1704067200000,
      'updated_at': 1704067200000,
    };
  }

  /// Test JWT tokens for auth tests.
  static String get validAccessToken =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJ0ZXN0LXVzZXItaWQiLCJyb2xlIjoidHJhaW5lciIsImV4cCI6OTk5OTk5OTk5OX0.'
      'test-signature';

  static String get validRefreshToken =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJ0ZXN0LXVzZXItaWQiLCJleHAiOjk5OTk5OTk5OTl9.'
      'test-refresh-signature';
}
```

### 6.3 Factory Pattern for All Core Models

```dart
// test/fixtures/factories/client_factory.dart
class ClientFactory {
  static Client create({
    String id = 'test-client-id-0001',
    String? trainerId = 'test-user-id-0000',
    String name = 'John Doe',
    String? email = 'john@example.com',
    String status = 'active',
  }) {
    return Client(
      id: id,
      trainerId: trainerId,
      name: name,
      email: email,
      status: status,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  static Map<String, dynamic> json({
    String id = 'test-client-id-0001',
    String? trainerId = 'test-user-id-0000',
    String name = 'John Doe',
    String? email = 'john@example.com',
    String status = 'active',
  }) {
    return {
      'id': id,
      'trainer_id': trainerId,
      'name': name,
      'email': email,
      'status': status,
      'created_at': 1704067200000,
      'updated_at': 1704067200000,
    };
  }
}

// test/fixtures/factories/workout_session_factory.dart
class WorkoutSessionFactory {
  static WorkoutSession create({
    String id = 'test-session-id-0001',
    String clientId = 'test-client-id-0001',
    String status = 'IN_PROGRESS',
    DateTime? startTime,
  }) {
    return WorkoutSession(
      id: id,
      clientId: clientId,
      status: WorkoutSessionStatus.fromJson(status),
      startTime: startTime ?? DateTime(2024, 1, 15, 10, 0),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );
  }

  static Map<String, dynamic> json({
    String id = 'test-session-id-0001',
    String clientId = 'test-client-id-0001',
    String status = 'IN_PROGRESS',
    int? startTime,
  }) {
    return {
      'id': id,
      'client_id': clientId,
      'status': status,
      'start_time': startTime ?? 1705312800000,
      'created_at': 1705312800000,
      'updated_at': 1705312800000,
    };
  }
}

// Factories for all remaining models follow the same pattern:
// ExerciseFactory, ClientMeasurementFactory, ClientProgressPhotoFactory,
// CheckInFactory, BookingFactory, EventFactory, MessageFactory,
// ConversationFactory, WorkoutProgramFactory, WorkoutTemplateFactory,
// TemplateExerciseFactory, PersonalRecordFactory, AssessmentFactory,
// AssessmentResultFactory, NotificationFactory, PackageFactory,
// RecipeFactory, DailyHabitFactory, HabitLogFactory,
// ResourceFactory, BlogPostFactory, SupportTicketFactory
```

### 6.4 Seed Data Bundle

```dart
// test/fixtures/seed_data.dart
/// Pre-configured seed data bundles for integration tests.
/// Each bundle represents a realistic app state.

class SeedData {
  final User user;
  final List<Client> clients;
  final List<WorkoutSession> sessions;
  final List<ClientMeasurement> measurements;

  const SeedData({
    required this.user,
    this.clients = const [],
    this.sessions = const [],
    this.measurements = const [],
  });

  static final standardTrainer = SeedData(
    user: UserFactory.createTrainer(),
    clients: [
      ClientFactory.create(name: 'Alice Smith'),
      ClientFactory.create(
        id: 'test-client-id-0002',
        name: 'Bob Jones',
      ),
      ClientFactory.create(
        id: 'test-client-id-0003',
        name: 'Carol Williams',
        status: 'inactive',
      ),
    ],
    sessions: [
      WorkoutSessionFactory.create(clientId: 'test-client-id-0001'),
      WorkoutSessionFactory.create(
        id: 'test-session-id-0002',
        clientId: 'test-client-id-0002',
        status: 'COMPLETED',
      ),
    ],
  );

  static final emptyTrainer = SeedData(
    user: UserFactory.createTrainer(),
  );
}
```

---

## 7. Test Helpers & Utilities

### 7.1 Provider Container Setup

```dart
// test/helpers/provider_utils.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates a ProviderContainer with optional overrides.
/// The container is automatically disposed in addTearDown.
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      // Default mocks for all tests
      secureStorageProvider.overrideWith((ref) => FakeSecureStorage()),
      connectivityProvider.overrideWith((ref) => FakeConnectivity()),
      ...overrides,
    ],
  );

  // Auto-dispose in tearDown
  addTearDown(() => container.dispose());

  return container;
}
```

### 7.2 Widget Test Pumping

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Extension on WidgetTester for consistent app pumping.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    GoRouter? router,
    Locale? locale,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: router ?? createTestRouter(),
          locale: locale ?? const Locale('en'),
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

/// Minimal GoRouter for tests -- avoids real redirects.
GoRouter createTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/auth/login', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/auth/register', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/trainer/dashboard',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(
        path: '/client/dashboard',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(
        path: '/trainer/clients',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(
        path: '/trainer/clients/:id',
        builder: (_, __) => const SizedBox(),
      ),
    ],
  );
}
```

### 7.3 Async Test Utilities

```dart
// test/helpers/async_utils.dart
import 'package:fake_async/fake_async.dart';

/// Runs a test with controlled fake async time.
/// Use for timer-dependent code (rest timer, sync intervals, debounced ops).
void withFakeAsync(FakeAsync Function(FakeAsync fakeAsync) body) {
  fakeAsync((async) {
    body(async);
    async.flushMicrotasks();
  });
}

/// Waits for a specific number of microtask cycles.
Future<void> flushMicrotasks() async {
  await Future<void>.value();
  await Future<void>.value();
  await Future<void>.value();
}
```

### 7.4 Widget Finder Utilities

```dart
// test/helpers/finders.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension FinderUtils on WidgetTester {
  /// Find a TextFormField by its label text.
  Finder findTextFieldByLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  /// Find an ElevatedButton by its child text.
  Finder findButtonByText(String text) {
    return find.ancestor(
      of: find.text(text),
      matching: find.byType(ElevatedButton),
    );
  }

  /// Enter text into a form field and trigger validation.
  Future<void> enterTextAndValidate(Finder finder, String text) async {
    await enterText(finder, text);
    await pump(const Duration(milliseconds: 100));
  }
}
```

### 7.5 Widget Test Retry Helper

```dart
// test/helpers/retry.dart
import 'package:flutter_test/flutter_test.dart';

/// Retry a widget test body on failure (for flaky animations/transitions).
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
      await tester.binding.reset();
    }
  }
}
```

---

## 8. Provider Override Architecture

### 8.1 Centralized Override Map

```dart
// test/helpers/overrides.dart
/// Central registry of all provider overrides for test scenarios.
/// Each scenario provides mocked dependencies for a specific test context.

class TestOverrides {
  /// Overrides for a fully mocked auth flow test.
  static List<Override> forAuthFlow({required MockApiClient apiClient}) {
    return [
      apiClientProvider.overrideWithValue(apiClient.dio),
      secureStorageProvider.overrideWith((ref) => FakeSecureStorage()),
    ];
  }

  /// Overrides for a widget test requiring an authenticated trainer.
  static List<Override> forAuthenticatedTrainer({
    MockApiClient? apiClient,
    AppDatabase? database,
  }) {
    return [
      if (apiClient != null)
        apiClientProvider.overrideWithValue(apiClient.dio),
      if (database != null)
        databaseProvider.overrideWithValue(database),
      authProvider.overrideWith((ref) {
        final notifier = FakeAuthNotifier();
        notifier.setAuthenticated(UserFactory.createTrainer());
        return notifier;
      }),
      secureStorageProvider.overrideWith((ref) => FakeSecureStorage()),
    ];
  }

  /// Overrides for a sync engine test.
  static List<Override> forSyncTest({
    required SyncRemoteSource remoteSource,
    required SyncLocalSource localSource,
    required ConnectivityManager connectivity,
  }) {
    return [
      syncRemoteSourceProvider.overrideWithValue(remoteSource),
      syncLocalSourceProvider.overrideWithValue(localSource),
      connectivityManagerProvider.overrideWithValue(connectivity),
    ];
  }

  /// Overrides for an offline-first data flow test.
  static List<Override> forOfflineDataFlow({
    required MockApiClient apiClient,
    required AppDatabase database,
  }) {
    return [
      apiClientProvider.overrideWithValue(apiClient.dio),
      databaseProvider.overrideWithValue(database),
      connectivityProvider.overrideWith((ref) {
        final conn = FakeConnectivity();
        conn.setOnline(false);
        return conn;
      }),
    ];
  }
}
```

### 8.2 Provider Dependency Injection Graph for Tests

```
test container
    |
    +-- secureStorageProvider --> FakeSecureStorage
    +-- connectivityProvider --> FakeConnectivity
    +-- apiClientProvider --> MockApiClient.dio
    +-- databaseProvider --> AppDatabase (in-memory)
    |
    +-- authProvider --> FakeAuthNotifier (pre-configured state)
    +-- syncEngineProvider --> SyncEngine with mocked sources
    +-- routerProvider --> GoRouter (minimal routes, no redirects)
```

### 8.3 Override Resolution Order

When multiple overrides target the same provider, the **last override wins**. The `createTestContainer` and `pumpApp` helpers always apply default overrides first, then user-supplied overrides, ensuring caller overrides take priority.

```
Default overrides (applied first):
  - secureStorageProvider -> FakeSecureStorage
  - connectivityProvider -> FakeConnectivity

User overrides (applied second, wins):
  - authProvider -> FakeAuthNotifier(trainer)
  - apiClientProvider -> MockApiClient
```

---

## 9. CI/CD Pipeline (GitHub Actions)

### 9.1 Full CI Workflow

```yaml
# .github/workflows/ci.yml
name: Ziro Fit CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run dart analyzer
        run: flutter analyze --fatal-infos

      - name: Check formatting
        run: dart format --set-exit-if-changed lib/ test/

  unit_tests:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests with coverage
        run: flutter test --coverage --coverage-path=lcov-unit.info test/unit/

      - name: Upload unit coverage
        uses: codecov/codecov-action@v4
        with:
          file: lcov-unit.info
          flags: unit
          fail_ci_if_error: false

  widget_tests:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run widget tests
        run: flutter test --coverage --coverage-path=lcov-widget.info test/widget/

      - name: Upload widget coverage
        uses: codecov/codecov-action@v4
        with:
          file: lcov-widget.info
          flags: widget
          fail_ci_if_error: false

  integration_tests:
    runs-on: ubuntu-latest
    needs: [unit_tests, widget_tests]
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run integration tests
        run: flutter test test/integration/ --retry=1

  e2e_tests:
    runs-on: ubuntu-latest
    needs: integration_tests
    if: github.ref == 'refs/heads/main' || github.event_name == 'release'
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run E2E tests on emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          target: google_apis
          arch: x86_64
          script: flutter test integration_test/ --retry=2

  coverage_gate:
    runs-on: ubuntu-latest
    needs: [unit_tests, widget_tests]
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'

      - name: Install dependencies
        run: flutter pub get

      - name: Generate combined coverage
        run: flutter test --coverage

      - name: Check coverage threshold
        uses: verygoodopensource/very_good_coverage@v2
        with:
          path: ./coverage/lcov.info
          min_coverage: 80
```

### 9.2 Test Selection Strategy

| Event | Test Run | Coverage Upload | Gate |
|-------|----------|----------------|------|
| **Push to feature branch** | Unit + Widget | Yes | Informational |
| **PR to develop** | Unit + Widget + Integration | Yes | 70% min |
| **PR to main** | Unit + Widget + Integration + E2E | Yes | 80% min |
| **Nightly** | Full suite + golden + performance | Yes (historical) | Report only |
| **Release tag** | Full suite + benchmarks | Yes | 80% min, blocking |

### 9.3 Pre-commit Hook

```yaml
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky"

echo "Running pre-commit checks..."

# Stage-only dart analysis
STAGED_DART=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$' || true)
if [ -n "$STAGED_DART" ]; then
  echo "$STAGED_DART" | xargs flutter analyze --fatal-infos
  if [ $? -ne 0 ]; then
    echo "FAILURE: Flutter analyze failed on staged files."
    exit 1
  fi
fi

# Run tests for changed packages
flutter test --coverage
if [ $? -ne 0 ]; then
  echo "FAILURE: Tests failed."
  exit 1
fi

echo "SUCCESS: Pre-commit checks passed!"
```

---

## 10. Coverage Minimum Thresholds

### 10.1 Phased Coverage Targets

| Phase | Models | Services | Providers | Widgets | Integration | E2E |
|-------|--------|----------|-----------|---------|-------------|-----|
| Phase 1 (Foundation) | 90% | 80% | 70% | - | - | - |
| Phase 2 (Core P0) | 95% | 85% | 80% | 50% | 2 flows | 1 flow |
| Phase 3 (Enhanced P1) | 95% | 90% | 85% | 60% | 5 flows | 3 flows |
| Phase 4 (Extended P2) | 95% | 90% | 85% | 65% | 8 flows | 5 flows |
| Phase 5 (Advanced P3) | 95% | 90% | 85% | 70% | 10 flows | 8 flows |

### 10.2 Layer-Specific Targets

| Layer | Target | Measurement Method |
|-------|--------|-------------------|
| **Data Models (fromJson/toJson)** | 95%+ | Line coverage on model files |
| **Enums (fromJson/toJson)** | 100% | Line coverage on enum files |
| **API Client / Dio Interceptors** | 90%+ | Branch coverage on interceptor logic |
| **Auth Service / Repository** | 90%+ | Line + branch coverage |
| **Remote Data Sources** | 85%+ | Line coverage per source file |
| **Local Data Sources (Drift)** | 85%+ | Line coverage per DAO file |
| **Repositories** | 85%+ | Branch coverage (offline/online paths) |
| **Sync Engine** | 90%+ | Line + branch (push, pull, conflict) |
| **Providers (Riverpod)** | 80%+ | Line coverage (state transitions) |
| **Use Cases** | 80%+ | Line coverage (business logic) |
| **Screens** | 50%+ | Line coverage (loading/error/data states) |
| **Shared Widgets** | 60%+ | Line coverage per widget |
| **Integration Tests** | 5 flows | Count of passing flow tests |
| **E2E Tests** | 5 scenarios | Count of passing scenario tests |

### 10.3 Enforcement Rules

- **Pre-commit hook**: Enforces that any new `lib/` file has a corresponding `test/` file
- **PR gate**: Coverage must not decrease below current threshold for the active phase
- **Phase gates**: Each implementation phase has minimum coverage must-pass criteria
- **Release gate**: 80% overall coverage is blocking for release

---

## 11. Golden File Testing

For visual consistency, use golden file tests for critical screens. Golden tests run:
- On every PR via CI (Linux-only, headless)
- Updated on-demand via `--update-goldens` flag
- Compared against platform-specific baselines (Linux for CI, macOS for dev)

### 11.1 Golden File Test Targets

| Screen | Purpose | Elements to Verify |
|--------|---------|--------------------|
| **Login Screen** | Form layout, button positions | Email field, password field, sign-in button, OAuth buttons |
| **Register Screen** | Registration form layout | Name, email, password fields, role selection |
| **Trainer Dashboard** | Card layouts, chart placeholders | Stats cards, upcoming sessions list, quick actions |
| **Client List** | List item rendering | Avatar, name, status badge, search bar |
| **Client Detail** | Profile layout | Header, measurement chart, action buttons |
| **Active Workout** | Exercise log layout | Exercise list, set rows, rest timer, progress |
| **Workout Summary** | Results display | Stats, best set, PR indicators |
| **Profile Page** | Section layout | Photo, text sections, services, testimonials |

### 11.2 Golden Test Pattern

```dart
// test/widget/auth/login_screen_golden_test.dart
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('LoginScreen golden tests', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [unauthenticatedOverride],
    );

    await screenMatchesGolden(tester, 'goldens/login_screen');
  });
}
```

### 11.3 Golden File Workflow

```bash
# Generate/update golden files locally
flutter test --update-goldens

# Run golden tests only
flutter test --tags=golden

# Compare specific golden
flutter test test/widget/auth/login_screen_golden_test.dart
```

---

## 12. Performance Testing

### 12.1 Widget Build Count

Verify no unnecessary rebuilds using `tester.binding.setSurfaceSize` and the `RebuildCountUtils`:

```dart
// test/performance/build_count_test.dart
void main() {
  testWidgets('Dashboard does not rebuild unnecessarily', (tester) async {
    // Track build count using a rebuild logger
    final buildCount = ValueNotifier<int>(0);

    await tester.pumpApp(
      Builder(
        builder: (context) {
          buildCount.value++;
          return const TrainerDashboardScreen();
        },
      ),
      overrides: [authenticatedTrainerOverride],
    );

    // Initial build
    expect(buildCount.value, 1);

    // Simulate data update that should NOT rebuild the whole screen
    await tester.pump(const Duration(seconds: 1));
    expect(buildCount.value, 1); // No rebuild
  });
}
```

### 12.2 Memory Leak Detection

Use the `leak_tracker` package for memory leak detection in integration tests:

```dart
// test/integration/memory_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no memory leaks after full navigation flow', (tester) async {
    // Run through all main screens
    await tester.pumpAndSettle();

    // Navigate: Login -> Dashboard -> Clients -> Detail -> Workout -> History
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    // ... full navigation flow ...

    // Verify no leaked objects
    await expectLater(LeakChecker(), hasNoLeaks);
  });
}
```

### 12.3 Database Query Performance

Track Drift query counts in integration tests:

```dart
// test/performance/db_query_count_test.dart
void main() {
  test('sync pull processes all tables efficiently', () async {
    final db = createTestDatabase();

    // Enable query logging
    db.executor = LoggingExecutor(db.executor, (sql, params) {
      // Track queries
    });

    // ... test sync pull ...

    await db.close();
  });
}
```

### 12.4 Scroll Performance

For long lists (client list, workout history), verify smooth scrolling:

```dart
testWidgets('client list scrolls without jank', (tester) async {
  await tester.pumpApp(
    const ClientsListScreen(),
    overrides: [authenticatedTrainerOverride],
  );

  // Scroll through the entire list
  await tester.scrollUntilVisible(
    find.text('Last item'),
    200.0,
    scrollable: find.byType(Scrollable).first,
  );

  // Verify frames rendered
  expect(tester.binding.transientCallbackCount, lessThan(100));
});
```

---

## 13. Integration Test Patterns

### 13.1 Integration Test Setup

```dart
// test/integration/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;
  late MockApiClient mockApiClient;

  setUp(() async {
    database = createTestDatabase();
    mockApiClient = MockApiClient();
    container = createTestContainer(
      overrides: TestOverrides.forAuthFlow(apiClient: mockApiClient)
        ..addAll([
          databaseProvider.overrideWithValue(database),
        ]),
    );
  });

  tearDown(() async {
    await container.dispose();
    await database.close();
  });

  // ... test cases ...
}
```

### 13.2 Auth Flow Integration Test

```dart
testWidgets('user can login from login screen', (tester) async {
  // Mock API login endpoint
  mockApiClient.mockPost(
    '/api/auth/login',
    statusCode: 200,
    body: {'email': 'test@test.com', 'password': 'password'},
    response: {
      'data': {
        'accessToken': UserFactory.validAccessToken,
        'refreshToken': UserFactory.validRefreshToken,
        'user': UserFactory.json(role: 'trainer'),
        'role': 'trainer',
      },
    },
  );

  // Mock GET /api/auth/me
  mockApiClient.mockGet(
    '/api/auth/me',
    statusCode: 200,
    response: {
      'data': UserFactory.json(role: 'trainer'),
    },
  );

  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      apiClientProvider.overrideWithValue(mockApiClient.dio),
      databaseProvider.overrideWithValue(database),
      secureStorageProvider.overrideWith((ref) => FakeSecureStorage()),
    ],
  );

  // Fill and submit login form
  await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  // Verify navigation to trainer dashboard
  expect(find.text('Dashboard'), findsOneWidget);
});
```

### 13.3 Workout Flow Integration Test

```dart
testWidgets('start workout, log exercise, finish, view in history',
    (tester) async {
  // Mock: get active session (none active)
  mockApiClient.mockGet(
    '/api/workout-sessions/live',
    statusCode: 200,
    response: {'data': {'session': null}},
  );

  // Mock: start workout
  mockApiClient.mockPost(
    '/api/workout-sessions/start',
    statusCode: 200,
    body: {'templateId': 'template-1'},
    response: {
      'data': {
        'session': WorkoutSessionFactory.json(status: 'IN_PROGRESS'),
      },
    },
  );

  // Navigate to workout screen
  await tester.pumpApp(
    const ActiveWorkoutScreen(),
    overrides: [
      apiClientProvider.overrideWithValue(mockApiClient.dio),
      ...authenticatedClientOverride,
    ],
  );

  await tester.pumpAndSettle();

  // Start workout from template
  await tester.tap(find.text('Start Workout'));
  await tester.pumpAndSettle();

  // Verify workout is active
  expect(find.byType(ExerciseSetRow), findsWidgets);
});
```

### 13.4 Offline Sync Integration Test

```dart
testWidgets('offline mutation is queued and synced when online',
    (tester) async {
  // Start offline
  final connectivity = FakeConnectivity();
  connectivity.setOnline(false);

  // Add client offline
  mockApiClient.mockPost(
    '/api/clients',
    statusCode: 201,
    body: {'name': 'Offline Client'},
    response: {
      'data': ClientFactory.json(
        id: 'local-client-id',
        name: 'Offline Client',
      ),
    },
  );

  await tester.pumpApp(
    const AddClientScreen(),
    overrides: [
      apiClientProvider.overrideWithValue(mockApiClient.dio),
      databaseProvider.overrideWithValue(database),
      connectivityProvider.overrideWithValue(connectivity),
      ...authenticatedTrainerOverride,
    ],
  );

  // Fill and submit client form
  await tester.enterText(find.byType(TextFormField), 'Offline Client');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify saved locally (offline indicator)
  expect(find.text('Saved offline'), findsOneWidget);

  // Go online -- verify sync happens
  connectivity.setOnline(true);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Verify synced indicator
  expect(find.text('Synced'), findsOneWidget);
});
```

---

## 14. End-to-End Test Patterns

### 14.1 E2E Test Infrastructure

```dart
// test/e2e/utils/e2e_setup.dart
import 'package:integration_test/integration_test.dart';

/// Base class for E2E test suites.
abstract class E2ETestBase {
  late final IntegrationTestWidgetsFlutterBinding binding;

  Future<void> setUp() async {
    binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }

  Future<void> tearDown() async {
    // Clean up app state
  }

  /// Login helper for E2E tests
  Future<void> loginAsTrainer(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'e2e-trainer@zirofit.test',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'E2ePassword123!',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }
}
```

### 14.2 Trainer Journey

```dart
// test/e2e/trainer_journey_test.dart
void main() {
  final e2e = E2ETestBase();

  setUp(() => e2e.setUp());
  tearDown(() => e2e.tearDown());

  testWidgets('Trainer Journey: login, dashboard, clients, workout',
      (tester) async {
    // --- Step 1: Launch app and login ---
    app.main();
    await tester.pumpAndSettle();

    await e2e.loginAsTrainer(tester);

    // Verify trainer dashboard loaded
    expect(find.text('Trainer Dashboard'), findsOneWidget);
    expect(find.byType(StatsCard), findsWidgets);

    // --- Step 2: View clients list ---
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(find.text('Client List'), findsOneWidget);

    // --- Step 3: Open a client detail ---
    await tester.tap(find.byType(ClientCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Client Dashboard'), findsOneWidget);

    // --- Step 4: Logout ---
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    // Verify returned to login screen
    expect(find.text('Sign In'), findsOneWidget);
  });
}
```

### 14.3 Offline Sync E2E

```dart
// test/e2e/offline_sync_test.dart
testWidgets('create and sync data offline', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Login
  await e2e.loginAsTrainer(tester);

  // Go offline (airplane mode / disable network)
  // Note: This requires platform-specific setup

  // Add a new client while offline
  await tester.tap(find.text('Add Client'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('name_field')), 'E2E Offline Client');
  await tester.enterText(find.byKey(const Key('email_field')), 'offline@test.com');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify offline indicator
  expect(find.byType(SyncIndicator), findsOneWidget);

  // Reconnect network
  // Note: platform-specific re-enable

  // Wait for sync
  await tester.pumpAndSettle(const Duration(seconds: 10));

  // Verify sync complete
  expect(find.text('Synced'), findsOneWidget);
});
```

---

## 15. Sync Engine Testing

### 15.1 Sync Engine Unit Tests

```dart
// test/unit/sync/sync_engine_test.dart
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
          .thenAnswer((_) async =>
              SyncPushResponse(timestamp: 2000));
      when(() => mockRemote.pull(1000))
          .thenAnswer((_) async => pullResponse);
      when(() => mockLocal.upsertRecord(
            any(), any(),
            syncStatus: any(named: 'syncStatus'),
          )).thenAnswer((_) async {});
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

### 15.2 Conflict Resolver Tests

```dart
// test/unit/sync/conflict_resolver_test.dart
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

      verify(() => mockLocal.upsertRecord(
        'clients', incomingClient,
        syncStatus: SyncStatus.synced,
      )).called(1);
    });

    test('skips when local has pending changes', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {
            'sync_status': SyncStatus.pendingUpdate.value,
          });

      await resolver.upsertOnPull('clients', incomingClient);

      verifyNever(() => mockLocal.upsertRecord(
        any(), any(), syncStatus: any(named: 'syncStatus'),
      ));
    });

    test('overwrites when incoming is newer', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {
            'updated_at': 1000,
            'sync_status': SyncStatus.synced.value,
          });

      await resolver.upsertOnPull('clients', {
        'id': 'c-1',
        'updated_at': 2000,
      });

      verify(() => mockLocal.upsertRecord(
        'clients', {'id': 'c-1', 'updated_at': 2000},
        syncStatus: SyncStatus.synced,
      )).called(1);
    });

    test('keeps local when local is newer', () async {
      when(() => mockLocal.getRecord('clients', 'c-1'))
          .thenAnswer((_) async => {
            'updated_at': 3000,
            'sync_status': SyncStatus.synced.value,
          });

      await resolver.upsertOnPull('clients', {
        'id': 'c-1',
        'updated_at': 2000,
      });

      verifyNever(() => mockLocal.upsertRecord(
        any(), any(), syncStatus: any(named: 'syncStatus'),
      ));
    });
  });
}
```

### 15.3 Sync Queue Tests

```dart
// test/unit/sync/sync_queue_test.dart
void main() {
  late AppDatabase db;
  late SyncQueue queue;

  setUp(() {
    db = createTestDatabase();
    queue = SyncQueue(db);
  });

  tearDown(() => db.close());

  group('SyncQueue', () {
    test('adds and retrieves pending items in FIFO order', () async {
      await queue.add(item1);
      await queue.add(item2);

      final pending = await queue.getAllPending();

      expect(pending.length, 2);
      expect(pending[0].id, item1.id);
      expect(pending[1].id, item2.id);
    });

    test('removes processed items', () async {
      await queue.add(item1);
      await queue.remove(item1.id);

      final pending = await queue.getAllPending();
      expect(pending, isEmpty);
    });

    test('counts pending mutations', () async {
      await queue.add(item1);
      await queue.add(item2);

      expect(await queue.count(), 2);
    });

    test('clearAll removes all items', () async {
      await queue.add(item1);
      await queue.add(item2);
      await queue.clearAll();

      expect(await queue.count(), 0);
    });
  });
}
```

---

## 16. Regression Test Strategy

### 16.1 Pre-release Checklist

Before every release, execute the following manual regression checklist:

1. **Login flow**: Login with trainer credentials, login with client credentials, login with invalid credentials shows error, OAuth login flow
2. **Dashboard**: Trainer dashboard loads stats correctly, client dashboard shows upcoming sessions, pull-to-refresh works
3. **Client management**: Create new client, edit client fields, soft-delete client, view client detail with measurements
4. **Workout flow**: Start workout from template, log exercise with reps/weight, rest timer starts/stops, finish workout with notes, view workout in history
5. **Offline sync**: Enable airplane mode, create client offline, log exercise offline, disable airplane mode, verify sync completes
6. **Profile editing**: Update profile photo, add/remove services, reorder benefits, update availability
7. **Chat**: Open conversation, send message, receive message indicator
8. **Navigation**: Bottom nav switching, role guards (client cannot access trainer routes), deep link handling
9. **Settings**: Update weight unit, toggle notification preferences, view subscription status

### 16.2 Automated Regression CI

- CI runs full test suite on every PR to `main`
- Nightly runs include golden tests and performance benchmarks
- Release builds run full suite + E2E on real device farm

### 16.3 Critical Flows for Smoke Testing

```dart
/// Smoke test: Login to Dashboard to Logout
testWidgets('smoke: login flow', (tester) async { ... });

/// Smoke test: Start Workout to Log Exercise to Finish to History
testWidgets('smoke: workout flow', (tester) async { ... });

/// Smoke test: Add Client, Take Measurement, Upload Photo, View Progress
testWidgets('smoke: client management flow', (tester) async { ... });

/// Smoke test: Go Offline, Add Data, Go Online, Verify Sync
testWidgets('smoke: offline sync flow', (tester) async { ... });

/// Smoke test: Full Booking Flow, Event Flow, Notification Flow
testWidgets('smoke: booking and events flow', (tester) async { ... });
```

---

## 17. Testing Configuration

### 17.1 Shared Test Configuration

```yaml
# test/.test_config.yaml
# Shared test configuration for all test files
api:
  base_url: 'https://www.ziro.fit/api'
  timeout_ms: 5000

auth:
  test_token: 'eyJ0ZXN0LXRva2VuLWZvci1hdXRoLXRlc3RzLW9ubHk'
  test_refresh_token: 'eyJ0ZXN0LXJlZnJlc2gtdG9rZW4tZm9yLWF1dGgtdGVzdHM'

fixtures:
  path: 'test/fixtures/'

database:
  in_memory: true
  migration_mode: 'none'

goldens:
  path: 'test/goldens/'
  update_on_ci: false

timeouts:
  unit_test: 5000       # ms
  widget_test: 15000    # ms
  integration_test: 60000  # ms
  e2e_test: 120000      # ms
```

### 17.2 Test Environment Variables

```dart
// test/helpers/env.dart
class TestEnv {
  static String get apiBaseUrl =>
      const String.fromEnvironment(
        'TEST_API_BASE_URL',
        defaultValue: 'https://www.ziro.fit/api',
      );

  static int get testTimeoutMs =>
      int.fromEnvironment('TEST_TIMEOUT_MS', defaultValue: 5000);

  static bool get useInMemoryDb =>
      const bool.fromEnvironment(
        'TEST_USE_IN_MEMORY_DB',
        defaultValue: true,
      );

  static bool get updateGoldens =>
      const bool.fromEnvironment(
        'UPDATE_GOLDENS',
        defaultValue: false,
      );
}
```

---

## 18. Test Runners & Scripts

### 18.1 Common Commands

```bash
# Run all tests (unit + widget + integration)
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run specific test file
flutter test test/unit/models/user_test.dart

# Run by category
flutter test test/unit/          # Unit tests only
flutter test test/widget/        # Widget tests only
flutter test test/integration/   # Integration tests only
flutter test test/e2e/           # E2E tests only

# Run with retries
flutter test --retry=3

# Run with random order (detect leaky tests)
flutter test --test-randomize-ordering-seed=42

# Run tests matching a pattern
flutter test --name "login"

# Run golden tests
flutter test --update-goldens    # Update golden files
flutter test --tags=golden       # Run golden tests only

# Watch mode for TDD
flutter test --watch

# Generate HTML coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 18.2 CI-Specific Scripts

```bash
# Full CI run
scripts/ci.sh

# Coverage check
scripts/check-coverage.sh

# Pre-commit check
scripts/pre-commit.sh
```

### 18.3 VS Code Test Configuration

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

## 19. Test Lifecycle Best Practices

### 19.1 Per-File Setup/Teardown

```dart
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    db = createTestDatabase();
    container = createTestContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApiClient.dio),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    await container.dispose();
    await db.close();
    mockApiClient.dispose();
  });
}
```

### 19.2 Rules Checklist

1. **Each test file**: `setUp` creates fresh isolated state, `tearDown` cleans up
2. **Each test case**: Tests ONE behavior, has ONE assertion if possible
3. **Test doubles**: Prefer mocks for services, fakes for storage/DB
4. **Real implementations**: Use real validators, real model parsing in service tests
5. **Dependency injection**: All services must be injectable for testing
6. **Time-dependent tests**: Use `fake_async` package for timer-dependent code (rest timer, sync intervals)
7. **Random data**: Use fixed seeds for deterministic tests
8. **No shared state**: Never use `static` or `global` state that persists between tests
9. **Clean up streams**: Close all StreamControllers in `tearDown`
10. **Test isolation**: Each test starts with a clean `ProviderContainer`, fresh `Drift` DB, fresh `MockAdapter`

### 19.3 Common Pitfalls

| Gotcha | Solution |
|--------|----------|
| **Drift database not closed** | Always call `db.close()` in `tearDown` |
| **ProviderContainer leaks** | Always call `container.dispose()` in `tearDown` |
| **Dio MockAdapter state leak** | Create fresh Dio + MockAdapter in `setUp` |
| **Stream subscription not cancelled** | Use `ref.onDispose()` in providers, close in `tearDown` |
| **SharedPreferences state leak** | Call `setMockInitialValues({})` in `setUp` |
| **Timer not completed in test** | Use `fake_async` or `tester.pump(Duration(...))` |
| **Async gaps in widget tests** | Use `tester.pumpAndSettle()` after state-changing actions |
| **Empty cup (Drift test)** | Insert test data before query tests |
| **GoRouter redirect in tests** | Use a minimal test router config without redirects |
| **Golden file mismatch on CI** | Use `--update-goldens` on CI to regenerate |

---

## 20. Accessibility Testing

### 20.1 Semantic Structure Tests

```dart
// test/widget/auth/login_screen_accessibility_test.dart
void main() {
  testWidgets('LoginScreen meets accessibility guidelines', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [unauthenticatedOverride],
    );

    // Check semantics tree
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(labeledTapTargetGuideline));

    // Check for semantic labels
    expect(
      find.bySemanticsLabel('Email address'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Password'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Sign In'),
      findsOneWidget,
    );
  });

  testWidgets('all interactive elements have semantic labels', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [unauthenticatedOverride],
    );

    // Verify all tappable elements have labels
    final semanticLabels = find.bySemanticsLabel;
    expect(semanticLabels, findsAtLeast(3));
  });
}
```

### 20.2 Accessibility Checklist

| Requirement | Verification |
|-------------|-------------|
| All tappable targets >= 48x48dp | `androidTapTargetGuideline` |
| All interactive elements have labels | `labeledTapTargetGuideline` |
| Contrast ratio >= 4.5:1 for text | Manual verification with contrast checker |
| Screen reader order follows visual order | `SemanticsDebugger` overlay |
| Error messages are announced | `find.bySemanticsLabel('Error message')` |

---

## 21. Flaky Test Management

### 21.1 Retry Strategy

| Test Type | Retries | Mechanism |
|-----------|---------|-----------|
| **Unit tests** | 0 | Must be deterministic |
| **Widget tests** | 3 | `--test-randomize-ordering-seed=auto` run 3x |
| **Integration tests** | 1 | `--retry=1` flag |
| **E2E tests** | 2 | Custom retry wrapper |

### 21.2 Quarantine Process

Tests that fail more than 10% of CI runs are flagged for quarantine:

1. Test is moved to `test/quarantine/` directory
2. A GitHub issue is created with failure details and CI logs
3. Quarantined tests are excluded from standard CI but run nightly
4. Tests are un-quarantined only after passing 10 consecutive nightly runs

```dart
// test/quarantine.txt
# Known-flaky tests -- moved here while being fixed
# Format: file_path | issue | date_quarantined
#
# test/widget/workout/active_workout_screen_test.dart | Rest timer race condition | 2026-04-28
# test/integration/sync_flow_test.dart | Mock server timing issue | 2026-04-29
```

### 21.3 Widget Test Retry Wrapper

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
      return;
    } on TestFailure {
      if (attempt == maxRetries) rethrow;
      await tester.binding.reset();
      // Re-create widget tree
    }
  }
}
```

---

## 22. Test Status Dashboard

### 22.1 Dashboard Metrics

Track the following metrics per CI run:

| Metric | Source | Target |
|--------|--------|--------|
| **Total tests** | `flutter test --machine` | ~365 |
| **Pass rate** | CI JUnit report | > 99% |
| **Coverage** | `lcov.info` | > 80% |
| **Flaky rate** | CI retry logs | < 1% |
| **Build time** | CI workflow duration | < 15 min |
| **Test time** | `flutter test --machine` | < 10 min |

### 22.2 Dashboard File

```json
// test/test_dashboard.json (generated by CI)
{
  "run_id": "12345",
  "timestamp": "2026-05-01T10:00:00Z",
  "summary": {
    "total": 365,
    "passed": 362,
    "failed": 2,
    "skipped": 1,
    "pass_rate": 99.18
  },
  "coverage": {
    "lines": 82.3,
    "branches": 78.1,
    "functions": 85.7
  },
  "by_category": {
    "unit": {"total": 250, "passed": 249, "coverage": 85.2},
    "widget": {"total": 85, "passed": 84, "coverage": 62.1},
    "integration": {"total": 20, "passed": 20, "coverage": null},
    "e2e": {"total": 10, "passed": 9, "coverage": null}
  },
  "flaky_tests": [
    "test/widget/workout/active_workout_screen_test.dart"
  ],
  "performance": {
    "total_duration_seconds": 420,
    "slowest_test": "test/e2e/trainer_journey_test.dart (45s)"
  }
}
```

---

## 23. Package & Build Configuration

### 23.1 dev_dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Mocking
  mocktail: ^1.0.0            # Preferred for Dart 3 -- no code generation

  # Test utilities
  fake_async: ^1.3.0          # Deterministic timer control in tests
  golden_toolkit: ^0.15.0     # Golden file tests for visual regression

  # Code generation (used by main code, needed for build_runner in CI)
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.16.0

  # Linting & analysis
  very_good_analysis: ^5.0.0  # Strict lint rules

  # Faker for test data
  faker: ^2.1.0               # Generate realistic test data

  # Performance testing
  leak_tracker: ^10.0.0       # Memory leak detection in tests

  # Coverage (native --coverage flag, no extra dep)
  # flutter test --coverage generates lcov.info natively
```

### 23.2 analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    require_trailing_commas: false
    lines_longer_than_80_chars: false
```

### 23.3 Tool Justification

| Tool | Purpose |
|------|---------|
| **mocktail** | Mock classes without code generation. Preferred over mockito for Dart 3 compatibility. Used for Dio responses, Drift DAOs, connectivity streams, secure storage. |
| **fake_async** | Control `Timer`, `Future.delayed`, and `Stopwatch` deterministically. Essential for sync engine timing, rest timer, debounced operations. |
| **golden_toolkit** | Visual regression testing for widgets. Compare screenshots against baselines for critical screens. |
| **Dio MockAdapter** | Built into Dio. No extra dependency. Intercept HTTP requests at the adapter level. |
| **Drift NativeDatabase.memory()** | Built into Drift. In-memory SQLite for tests. Fast, isolated, no file system interaction. |
| **faker** | Generate realistic names, emails, phone numbers, addresses for test fixtures. Avoids hardcoded test data. |
| **very_good_analysis** | Strict lint rules that catch common issues before tests run. |

---

## 24. Appendix: Test Count Summary

### 24.1 Estimated Test Count by Priority

| Priority | Model | Service | Repo | Provider | Widget | Integration | E2E | Total |
|----------|-------|---------|------|----------|--------|-------------|-----|-------|
| **P0** | ~12 | ~65 | ~38 | ~16 | ~32 | ~8 | ~4 | ~175 |
| **P1** | ~6 | ~40 | ~16 | ~7 | ~20 | ~4 | ~2 | ~95 |
| **P2** | ~4 | ~28 | ~7 | ~1 | ~9 | -- | -- | ~49 |
| **P3** | -- | ~11 | -- | -- | ~5 | -- | -- | ~16 |
| **Sync** | -- | ~8 | ~4 | ~2 | ~2 | ~1 | ~1 | ~18 |
| **Utils** | -- | -- | -- | -- | -- | -- | -- | ~7 |
| **Shared** | -- | -- | -- | -- | ~5 | -- | -- | ~5 |
| **Total** | **~22** | **~152** | **~65** | **~26** | **~73** | **~13** | **~7** | **~365** |

### 24.2 Test Files by Category

| Category | File Count | Test Count |
|----------|-----------|------------|
| Models (unit) | 18 files | ~90 tests (5 per model) |
| Enums (unit) | 1 file | ~27 tests (3 per enum) |
| Services (unit) | 38 files | ~152 tests (4 per service) |
| Repositories (unit) | 16 files | ~65 tests (4 per repository) |
| Providers (unit) | 14 files | ~26 tests (2 per provider) |
| Sync (unit) | 7 files | ~28 tests (4 per module) |
| Use Cases (unit) | 6 files | ~12 tests (2 per use case) |
| Utils (unit) | 6 files | ~18 tests (3 per utility) |
| Screens (widget) | 32 files | ~64 tests (2 per screen) |
| Shared Widgets (widget) | 5 files | ~10 tests (2 per widget) |
| Integration | 8 files | ~13 tests (1-2 per flow) |
| E2E | 5 files | ~7 tests (1-2 per scenario) |

---

> **Document Version:** 1.0.0
> **Last Updated:** 2026-05-01
> **Estimated Total Tests:** ~365 (22 model, 152 service, 65 repo, 26 provider, 73 widget, 13 integration, 7 E2E, 7 utils)
> **Target Coverage:** 80%+ overall
> **Related Documents:** `TDD_PLAN.md`, `ARCHITECTURE.md`, `DATA_MODELS.md`, `API_REFERENCE.md`, `AUTH_FLOW.md`, `OFFLINE_SYNC.md`, `FEATURE_COVERAGE.md`
