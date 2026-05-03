# Ziro Fit — Flutter App Architecture

> **Purpose:** Comprehensive architectural blueprint for the Ziro Fit Flutter mobile application — an offline-first fitness business management platform for personal trainers and their clients.
>
> **Last updated:** 2026-05-01
>
> **Related docs:** `DATA_MODELS.md` (30+ Prisma models → Dart), `OFFLINE_SYNC.md` (sync engine design), `TDD_PLAN.md` (testing strategy)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [Layered Architecture](#4-layered-architecture)
5. [Data Flow](#5-data-flow)
6. [State Management (Riverpod)](#6-state-management-riverpod)
7. [Navigation (GoRouter)](#7-navigation-gorouter)
8. [Network Layer (Dio)](#8-network-layer-dio)
9. [Database Layer (Drift)](#9-database-layer-drift)
10. [Sync Engine](#10-sync-engine)
11. [Authentication](#11-authentication)
12. [Error Handling Strategy](#12-error-handling-strategy)
13. [Testing Architecture](#13-testing-architecture)
14. [Feature Modules Reference](#14-feature-modules-reference)
15. [Conventions](#15-conventions)
16. [Dependencies](#16-dependencies)
17. [Diagrams](#17-diagrams)
18. [Implementation Roadmap](#18-implementation-roadmap)

---

## 1. Overview

### 1.1 Product Vision

Ziro Fit is a **mobile-first fitness business management platform** that empowers personal trainers to manage their clients, create workout programs, track progress, schedule sessions, and process payments — all from a single app. Clients receive personalized workout plans, can log sessions, track measurements, and communicate with their trainer.

### 1.2 Key Requirements

| Requirement | Implementation |
|---|---|
| **Offline-first** | Drift (SQLite) local database + sync engine with pull/push API |
| **100% backend coverage** | All 120+ REST endpoints accessible via Flutter app |
| **TDD approach** | Unit → Widget → Integration → E2E tests per feature |
| **Auth reuse** | Supabase Flutter SDK mirrors backend's Supabase Auth |
| **Role-based UI** | Trainer, Client, Admin, Public routes |
| **Real-time sync** | Pull on start, periodic (5 min), pull-to-refresh; push via write-ahead queue |

### 1.3 Backend Context

The Flutter app consumes the `zirofit-next` backend:

- **Framework:** Next.js 16 App Router
- **Auth:** Supabase Auth (JWT, refresh tokens, Google/Apple OAuth)
- **Database:** PostgreSQL via Prisma ORM (30+ models)
- **API:** REST with Route Handlers (120+ endpoints)
- **Sync:** Existing pull/push endpoints for offline-first
- **Payments:** Stripe Connect for trainer payouts
- **Analytics:** PostHog
- **Email:** Resend

---

## 2. Tech Stack

### 2.1 Core Technologies

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Framework** | Flutter | 3.22+ | Cross-platform mobile (iOS/Android) |
| **Language** | Dart | 3.4+ | Type-safe, null-safe |
| **State Management** | Riverpod | 2.5+ | Reactive state with code generation |
| **Navigation** | GoRouter | 14.0+ | Declarative routing with guards |
| **Local Database** | Drift | 2.16+ | Type-safe SQLite ORM |
| **Network** | Dio | 5.4+ | HTTP client with interceptors |
| **Auth** | supabase_flutter | 2.3+ | Supabase Auth SDK |
| **Secure Storage** | flutter_secure_storage | 9.0+ | Token storage (Keychain/Keystore) |
| **Connectivity** | connectivity_plus | 6.0+ | Online/offline detection |
| **Code Gen** | build_runner, freezed, json_serializable | Latest | Immutable models, JSON serialization |

### 2.2 UI Libraries

| Library | Purpose |
|---|---|
| `cached_network_image` | Image caching with placeholders |
| `shimmer` | Loading skeleton effects |
| `fl_chart` | Charts for progress tracking |
| `image_picker` | Camera/gallery for progress photos |
| `intl` | Date/number formatting, i18n |
| `flutter_svg` | SVG rendering for icons/illustrations |

### 2.3 Dev Tools

| Tool | Purpose |
|---|---|
| `mocktail` / `mockito` | Mocking for unit/widget tests |
| `integration_test` | Full app integration tests |
| `drift_dev` | Drift code generation |
| `riverpod_generator` | Riverpod code generation |
| `freezed` | Immutable model code generation |
| `json_serializable` | JSON serialization code generation |

---

## 3. Project Structure

### 3.1 Feature-First Organization

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # App widget with providers, router
├── bootstrap.dart                     # Initialization (DB, auth, sync)
│
├── core/
│   ├── network/
│   │   ├── api_client.dart            # Dio singleton instance
│   │   ├── auth_interceptor.dart      # Bearer token injection + refresh
│   │   ├── retry_interceptor.dart     # Exponential backoff on failure
│   │   ├── sync_interceptor.dart      # Queue offline mutations
│   │   └── network_info.dart          # Connectivity wrapper
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── app_database.g.dart        # Generated Drift code
│   │   ├── tables/                    # Table definitions
│   │   │   ├── users_table.dart
│   │   │   ├── clients_table.dart
│   │   │   ├── workouts_table.dart
│   │   │   └── ... (17+ sync tables)
│   │   └── migrations/
│   │       ├── schema.dart            # Schema version management
│   │       └── v1_initial.dart        # Initial schema
│   ├── router/
│   │   ├── app_router.dart            # GoRouter configuration
│   │   ├── route_constants.dart       # Route path strings
│   │   └── guards/
│   │       ├── auth_guard.dart        # Redirect if not authenticated
│   │       └── role_guard.dart        # Redirect based on role
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData definition
│   │   ├── app_colors.dart            # Color constants
│   │   ├── app_text_styles.dart       # Typography
│   │   └── app_dimensions.dart        # Spacing, border radius
│   ├── utils/
│   │   ├── date_time_utils.dart       # Unix ms ↔ DateTime converters
│   │   ├── image_utils.dart           # Supabase storage URL builders
│   │   ├── validators.dart            # Form validators (email, password)
│   │   ├── logger.dart                # Dev logging with levels
│   │   └── enum_utils.dart            # Enum serialization helpers
│   └── constants/
│       ├── api_constants.dart         # Base URLs, timeouts, endpoints
│       ├── app_constants.dart         # Feature flags, limits
│       └── storage_keys.dart          # SharedPreferences/SecureStorage keys
│
├── data/
│   ├── models/                        # Data models (from DATA_MODELS.md)
│   │   ├── user.dart
│   │   ├── profile.dart
│   │   ├── client.dart
│   │   ├── workout_session.dart
│   │   ├── exercise.dart
│   │   ├── booking.dart
│   │   ├── message.dart
│   │   └── ... (30+ model files)
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── auth_remote_source.dart
│   │   │   ├── user_remote_source.dart
│   │   │   ├── client_remote_source.dart
│   │   │   ├── workout_remote_source.dart
│   │   │   ├── booking_remote_source.dart
│   │   │   ├── sync_remote_source.dart
│   │   │   └── ... (per domain)
│   │   └── local/
│   │       ├── auth_local_source.dart
│   │       ├── user_local_source.dart
│   │       ├── client_local_source.dart
│   │       ├── workout_local_source.dart
│   │       ├── sync_local_source.dart
│   │       └── ... (per domain)
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── client_repository.dart
│   │   ├── workout_repository.dart
│   │   ├── booking_repository.dart
│   │   ├── sync_repository.dart
│   │   └── ... (per domain)
│   └── sync/
│       ├── sync_engine.dart           # Orchestrates pull/push cycles
│       ├── sync_queue.dart            # Offline mutation queue (FIFO)
│       ├── conflict_resolver.dart     # Last-write-wins resolution
│       ├── connectivity_manager.dart  # Online/offline state stream
│       └── sync_metadata.dart         # Last sync timestamps per table
│
├── domain/
│   ├── entities/                      # Business entities (thin wrappers or same as models)
│   │   ├── auth_entity.dart
│   │   ├── user_entity.dart
│   │   └── ... (optional, if business logic differs from data models)
│   ├── usecases/
│   │   ├── auth/
│   │   │   ├── login_usecase.dart
│   │   │   ├── register_usecase.dart
│   │   │   ├── refresh_token_usecase.dart
│   │   │   ├── logout_usecase.dart
│   │   │   └── oauth_login_usecase.dart
│   │   ├── workout/
│   │   │   ├── start_workout_usecase.dart
│   │   │   ├── finish_workout_usecase.dart
│   │   │   ├── get_active_session_usecase.dart
│   │   │   ├── log_exercise_usecase.dart
│   │   │   └── get_workout_history_usecase.dart
│   │   ├── client/
│   │   │   ├── get_clients_usecase.dart
│   │   │   ├── create_client_usecase.dart
│   │   │   ├── update_client_usecase.dart
│   │   │   └── get_client_measurements_usecase.dart
│   │   ├── booking/
│   │   │   ├── create_booking_usecase.dart
│   │   │   ├── update_booking_status_usecase.dart
│   │   │   └── get_bookings_usecase.dart
│   │   └── ... (per feature)
│   └── repositories/                  # Abstract repository interfaces
│       ├── auth_repository_interface.dart
│       ├── user_repository_interface.dart
│       ├── client_repository_interface.dart
│       ├── workout_repository_interface.dart
│       ├── booking_repository_interface.dart
│       └── ... (per feature)
│
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart      # AuthNotifier (StateNotifier<AuthState>)
│   │   │   └── auth_state.dart        # AuthState sealed class
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── widgets/
│   │       ├── login_form.dart
│   │       ├── register_form.dart
│   │       └── oauth_buttons.dart
│   │
│   ├── dashboard/
│   │   ├── providers/
│   │   │   ├── trainer_dashboard_provider.dart
│   │   │   └── client_dashboard_provider.dart
│   │   ├── screens/
│   │   │   ├── trainer_dashboard_screen.dart
│   │   │   └── client_dashboard_screen.dart
│   │   └── widgets/
│   │       ├── stats_card.dart
│   │       ├── upcoming_sessions_list.dart
│   │       └── quick_actions_grid.dart
│   │
│   ├── workout/
│   │   ├── providers/
│   │   │   ├── active_workout_provider.dart
│   │   │   ├── workout_history_provider.dart
│   │   │   └── exercise_log_provider.dart
│   │   ├── screens/
│   │   │   ├── active_workout_screen.dart
│   │   │   ├── workout_history_screen.dart
│   │   │   ├── workout_summary_screen.dart
│   │   │   └── exercise_detail_screen.dart
│   │   └── widgets/
│   │       ├── exercise_set_row.dart
│   │       ├── rest_timer.dart
│   │       └── workout_progress_indicator.dart
│   │
│   ├── clients/
│   │   ├── providers/
│   │   │   ├── clients_list_provider.dart
│   │   │   └── client_detail_provider.dart
│   │   ├── screens/
│   │   │   ├── clients_list_screen.dart
│   │   │   ├── client_detail_screen.dart
│   │   │   └── add_client_screen.dart
│   │   └── widgets/
│   │       ├── client_card.dart
│   │       └── client_measurements_chart.dart
│   │
│   ├── trainer/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── trainer_profile_screen.dart
│   │   │   └── edit_trainer_profile_screen.dart
│   │   └── widgets/
│   │
│   ├── profile/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   └── widgets/
│   │
│   ├── programs/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── programs_list_screen.dart
│   │   │   ├── program_detail_screen.dart
│   │   │   └── create_program_screen.dart
│   │   └── widgets/
│   │
│   ├── checkin/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── checkin_list_screen.dart
│   │   │   ├── checkin_detail_screen.dart
│   │   │   └── submit_checkin_screen.dart
│   │   └── widgets/
│   │
│   ├── calendar/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   └── calendar_screen.dart
│   │   └── widgets/
│   │
│   ├── chat/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── conversations_list_screen.dart
│   │   │   └── chat_screen.dart
│   │   └── widgets/
│   │
│   ├── notifications/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── explore/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── events/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── nutrition/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── habits/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── resources/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── billing/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── settings/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │
│   ├── admin/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   └── sync/
│       ├── providers/
│       │   └── sync_provider.dart      # SyncNotifier (StreamProvider)
│       ├── screens/
│       │   └── sync_status_screen.dart
│       └── widgets/
│           └── sync_indicator.dart
│
├── shared/
│   ├── widgets/
│   │   ├── app_scaffold.dart           # App bar + bottom nav wrapper
│   │   ├── loading_indicator.dart      # Centered spinner
│   │   ├── error_view.dart             # Error display with retry
│   │   ├── empty_state.dart            # No data placeholder
│   │   ├── avatar_widget.dart          # User/client avatar
│   │   ├── primary_button.dart         # Styled elevated button
│   │   ├── text_field.dart             # Styled text input
│   │   ├── bottom_sheet.dart           # Reusable bottom sheet
│   │   └── confirmation_dialog.dart    # Yes/no dialog
│   ├── extensions/
│   │   ├── string_extensions.dart      # String helpers
│   │   ├── date_extensions.dart        # DateTime formatting
│   │   ├── context_extensions.dart     # MediaQuery, Theme shortcuts
│   │   └── async_extensions.dart       # AsyncValue helpers
│   └── l10n/
│       ├── app_en.arb                  # English strings
│       └── app_pl.arb                  # Polish strings
│
└── test/                               # Mirrors lib/ structure
    ├── unit/
    │   ├── models/
    │   ├── repositories/
    │   ├── usecases/
    │   └── providers/
    ├── widget/
    │   └── features/
    │       ├── auth/
    │       ├── workout/
    │       └── ...
    ├── integration/
    │   ├── auth_flow_test.dart
    │   ├── workout_flow_test.dart
    │   └── ...
    └── e2e/
        ├── trainer_journey_test.dart
        └── client_journey_test.dart
```

### 3.2 Directory Responsibilities

| Directory | Responsibility |
|---|---|
| `core/` | Cross-cutting concerns: network, database, routing, theme, utilities |
| `data/` | Data layer: models, data sources (remote/local), repositories, sync engine |
| `domain/` | Business logic: use cases, repository interfaces, entities |
| `features/` | UI layer: screens, widgets, providers organized by feature |
| `shared/` | Reusable widgets, extensions, localization |
| `test/` | All tests mirroring lib/ structure |

---

## 4. Layered Architecture

### 4.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Screens     │  │  Widgets    │  │  Providers (Riverpod)   │ │
│  │  (Stateless/ │  │  (Reusable) │  │  - StateNotifier        │ │
│  │   Stateful)  │  │             │  │  - FutureProvider       │ │
│  │             │  │             │  │  - StreamProvider        │ │
│  └──────┬──────┘  └─────────────┘  └───────────┬─────────────┘ │
│         │                                       │               │
├─────────┼───────────────────────────────────────┼───────────────┤
│         │           DOMAIN LAYER                │               │
│         │  ┌─────────────────────────────────┐  │               │
│         └─►│         Use Cases                │◄─┘               │
│            │  (Business Logic Orchestration)  │                  │
│            └──────────────┬──────────────────┘                  │
│                           │                                     │
│            ┌──────────────▼──────────────────┐                  │
│            │   Repository Interfaces          │                  │
│            │   (Abstract Contracts)           │                  │
│            └──────────────┬──────────────────┘                  │
│                           │                                     │
├───────────────────────────┼─────────────────────────────────────┤
│                     DATA LAYER                                  │
│            ┌──────────────▼──────────────────┐                  │
│            │      Repository Implementations  │                  │
│            └──────────────┬──────────────────┘                  │
│                           │                                     │
│         ┌─────────────────┼─────────────────┐                   │
│         ▼                 ▼                 ▼                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐     │
│  │   Remote     │  │   Local     │  │    Sync Engine      │     │
│  │ Data Source  │  │ Data Source │  │  - Queue            │     │
│  │  (Dio API)   │  │  (Drift)   │  │  - Conflict Resolve │     │
│  └─────────────┘  └─────────────┘  │  - Connectivity     │     │
│                                     └─────────────────────┘     │
├─────────────────────────────────────────────────────────────────┤
│                       CORE LAYER                                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ Network │ │Database │ │ Router  │ │  Theme  │ │  Utils  │  │
│  │  (Dio)  │ │ (Drift) │ │(GoRoute)│ │         │ │         │  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Layer Responsibilities

| Layer | Responsibility | Dependencies |
|---|---|---|
| **Presentation** | UI rendering, user interaction, state exposure via providers | Domain |
| **Domain** | Business rules, use case orchestration, repository contracts | None (pure Dart) |
| **Data** | Data fetching/caching, repository implementations, sync | Core, Domain |
| **Core** | Infrastructure: HTTP, DB, routing, theming, utilities | None |

### 4.3 Dependency Rules

```
Presentation → Domain ← Data
                    ↑
                   Core
```

- **Presentation** depends on **Domain** (use cases, repository interfaces)
- **Data** depends on **Domain** (implements repository interfaces) and **Core** (Dio, Drift)
- **Domain** depends on **nothing** (pure business logic)
- **Core** depends on **nothing** (infrastructure utilities)

---

## 5. Data Flow

### 5.1 Online Read Flow

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Screen  │────►│ Provider │────►│  Repository  │────►│RemoteSource  │
│          │     │(FutureP) │     │              │     │  (Dio API)   │
└──────────┘     └──────────┘     └──────┬───────┘     └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │   Backend    │
                                         │              │   (REST)     │
                                         │              └──────────────┘
                                         │
                                         │ Cache miss or stale
                                         ▼
                                  ┌──────────────┐
                                  │ LocalSource  │
                                  │  (Drift DB)  │
                                  └──────────────┘
```

**Flow:**
1. Screen watches a `FutureProvider` via `ref.watch()`
2. Provider calls `Repository.getX()`
3. Repository checks `LocalSource` first (if cache valid)
4. If stale/missing, calls `RemoteSource.getX()` → API → Backend
5. On success, updates `LocalSource` (cache), returns data
6. Provider emits `AsyncValue.data`, Screen rebuilds

### 5.2 Offline Read Flow

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Screen  │────►│ Provider │────►│  Repository  │────►│ LocalSource  │
│          │     │(FutureP) │     │              │     │  (Drift DB)  │
└──────────┘     └──────────┘     └──────────────┘     └──────────────┘
```

**Flow:**
1. Same as online read, but `ConnectivityManager.isOnline == false`
2. Repository skips `RemoteSource`, reads directly from `LocalSource`
3. Returns cached data (may be stale, but available)

### 5.3 Online Mutation Flow

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Screen  │────►│ Provider │────►│  Repository  │────►│RemoteSource  │
│(Form)    │     │(Notifier)│     │              │     │  (Dio POST)  │
└──────────┘     └──────────┘     └──────┬───────┘     └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │   Backend    │
                                         │              └──────┬───────┘
                                         │                     │
                                         │ Success             │
                                         ▼                     ▼
                                  ┌──────────────┐     ┌──────────────┐
                                  │ LocalSource  │     │  Response    │
                                  │ (Update DB)  │     │  (Created)   │
                                  └──────────────┘     └──────────────┘
```

**Flow:**
1. Screen calls `ref.read(provider.notifier).createX(data)`
2. Notifier calls `Repository.createX(data)`
3. Repository calls `RemoteSource.createX(data)` → API → Backend
4. On success, updates `LocalSource` with response
5. Notifier updates state, Screen rebuilds

### 5.4 Offline Mutation Flow

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Screen  │────►│ Provider │────►│  Repository  │────►│ LocalSource  │
│(Form)    │     │(Notifier)│     │              │     │ (Insert/Upd) │
└──────────┘     └──────────┘     └──────┬───────┘     └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │ SyncQueue    │
                                         │              │ (Pending)    │
                                         │              └──────┬───────┘
                                         │                     │
                                         │                     │ When online
                                         │                     ▼
                                         │              ┌──────────────┐
                                         │              │ SyncEngine   │
                                         │              │ (Push Queue) │
                                         │              └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │ RemoteSource │
                                         │              │  (Dio POST)  │
                                         │              └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │   Backend    │
                                         │              └──────┬───────┘
                                         │                     │
                                         │              ┌──────▼───────┐
                                         │              │ Pull Response│
                                         │              │ (Update DB)  │
                                         │              └──────────────┘
                                         ▼
                                  ┌──────────────┐
                                  │ UI Updated   │
                                  │ (Optimistic) │
                                  └──────────────┘
```

**Flow:**
1. Screen calls `ref.read(provider.notifier).createX(data)`
2. Notifier calls `Repository.createX(data)`
3. Repository inserts into `LocalSource` immediately (optimistic update)
4. Repository adds mutation to `SyncQueue` (pending push)
5. UI updates immediately (user sees change)
6. When connectivity restored, `SyncEngine` flushes queue
7. `SyncEngine` calls `RemoteSource.createX(data)` for each queued mutation
8. On success, marks mutation as synced; on failure, retries with backoff
9. After push, `SyncEngine` pulls latest data to reconcile

---

## 6. State Management (Riverpod)

### 6.1 Provider Types Used

| Provider Type | Use Case | Example |
|---|---|---|
| `StateNotifierProvider` | Complex state with multiple actions | `authProvider`, `activeWorkoutProvider` |
| `FutureProvider` | Async data fetching | `clientByIdProvider(clientId)` |
| `FutureProvider.family` | Parameterized async data | `workoutHistoryProvider(userId)` |
| `StreamProvider` | Real-time data | `syncStatusProvider`, `chatMessagesProvider` |
| `StateProvider` | Simple state (form fields, toggles) | `loginEmailProvider`, `filterProvider` |
| `Provider` | Derived/computed state | `isTrainerProvider`, `activeClientsCountProvider` |

### 6.2 Code Generation

All providers use `@riverpod` annotation for type-safe, generated code:

```dart
// lib/features/auth/providers/auth_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Initialize: check stored token, validate session
    return const AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }
}
```

### 6.3 Auth State (Sealed Class)

```dart
// lib/features/auth/providers/auth_state.dart

sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
```

### 6.4 Data Provider Patterns

**Single Entity by ID:**
```dart
@riverpod
Future<Client> clientById(ClientByIdRef ref, String clientId) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.getClient(clientId);
}
```

**List of Entities:**
```dart
@riverpod
Future<List<Client>> clientsList(ClientsListRef ref) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.getClients();
}
```

**Stream for Real-time:**
```dart
@riverpod
Stream<SyncStatus> syncStatus(SyncStatusRef ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.statusStream;
}
```

### 6.5 Provider Dependency Graph

```
authProvider
    │
    ├──► userProfileProvider (depends on authProvider)
    │
    ├──► isTrainerProvider (depends on userProfileProvider)
    │
    ├──► clientsListProvider (depends on authProvider + isTrainerProvider)
    │       │
    │       └──► clientByIdProvider (depends on clientsListProvider)
    │
    ├──► workoutHistoryProvider (depends on authProvider)
    │       │
    │       └──► activeWorkoutProvider (depends on workoutHistoryProvider)
    │
    └──► syncEngineProvider (depends on authProvider)
            │
            └──► syncStatusProvider (depends on syncEngineProvider)
```

---

## 7. Navigation (GoRouter)

### 7.1 Route Structure

```dart
// lib/core/router/app_router.dart

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authState.stream),
    redirect: (context, state) {
      // Auth guard: redirect to /auth/login if not authenticated
      final isAuthenticated = authState.valueOrNull is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/';

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),

      // Trainer shell routes
      ShellRoute(
        builder: (context, state, child) => TrainerShell(child: child),
        routes: [
          GoRoute(
            path: '/trainer/dashboard',
            builder: (context, state) => const TrainerDashboardScreen(),
          ),
          GoRoute(
            path: '/trainer/clients',
            builder: (context, state) => const ClientsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ClientDetailScreen(
                  clientId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'workout',
                    builder: (context, state) => ClientWorkoutScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/trainer/programs',
            builder: (context, state) => const ProgramsListScreen(),
          ),
          GoRoute(
            path: '/trainer/profile',
            builder: (context, state) => const TrainerProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditTrainerProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/events',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: '/trainer/check-ins',
            builder: (context, state) => const CheckInsListScreen(),
          ),
          GoRoute(
            path: '/trainer/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Client shell routes
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/dashboard',
            builder: (context, state) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: '/client/programs',
            builder: (context, state) => const ClientProgramsScreen(),
          ),
          GoRoute(
            path: '/client/workout',
            builder: (context, state) => const ClientWorkoutScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const WorkoutHistoryScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => WorkoutSummaryScreen(
                  sessionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/client/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/client/trainer',
            builder: (context, state) => const MyTrainerScreen(),
          ),
          GoRoute(
            path: '/client/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/client/events',
            builder: (context, state) => const ClientEventsScreen(),
          ),
          GoRoute(
            path: '/client/check-in',
            builder: (context, state) => const SubmitCheckInScreen(),
          ),
        ],
      ),

      // Admin shell routes
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (context, state) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '/admin/blog',
            builder: (context, state) => const AdminBlogScreen(),
          ),
          GoRoute(
            path: '/admin/support',
            builder: (context, state) => const AdminSupportScreen(),
          ),
        ],
      ),

      // Public routes (no auth required)
      GoRoute(
        path: '/public/trainers',
        builder: (context, state) => const PublicTrainersScreen(),
        routes: [
          GoRoute(
            path: ':username',
            builder: (context, state) => PublicTrainerProfileScreen(
              username: state.pathParameters['username']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/public/events',
        builder: (context, state) => const PublicEventsScreen(),
      ),
      GoRoute(
        path: '/public/blog',
        builder: (context, state) => const PublicBlogScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) => BlogPostScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
    ],
  );
});
```

### 7.2 Role-Based Routing

```dart
// lib/core/router/guards/role_guard.dart

String? roleGuard(BuildContext context, GoRouterState state, User user) {
  final location = state.matchedLocation;
  final isTrainer = user.role == 'trainer';
  final isClient = user.role == 'client';
  final isAdmin = user.role == 'admin';

  // Redirect to appropriate dashboard based on role
  if (location == '/') {
    if (isTrainer) return '/trainer/dashboard';
    if (isClient) return '/client/dashboard';
    if (isAdmin) return '/admin/dashboard';
  }

  // Prevent trainers from accessing client routes
  if (location.startsWith('/client') && !isClient) {
    return '/trainer/dashboard';
  }

  // Prevent clients from accessing trainer routes
  if (location.startsWith('/trainer') && !isTrainer) {
    return '/client/dashboard';
  }

  // Prevent non-admins from accessing admin routes
  if (location.startsWith('/admin') && !isAdmin) {
    return '/';
  }

  return null;
}
```

### 7.3 Bottom Navigation Shell

```dart
// lib/features/dashboard/widgets/trainer_shell.dart

class TrainerShell extends StatelessWidget {
  final Widget child;

  const TrainerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) {
          final routes = [
            '/trainer/dashboard',
            '/trainer/clients',
            '/trainer/calendar',
            '/trainer/programs',
            '/trainer/profile',
          ];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/trainer/dashboard')) return 0;
    if (location.startsWith('/trainer/clients')) return 1;
    if (location.startsWith('/trainer/calendar')) return 2;
    if (location.startsWith('/trainer/programs')) return 3;
    if (location.startsWith('/trainer/profile')) return 4;
    return 0;
  }
}
```

---

## 8. Network Layer (Dio)

### 8.1 API Client Singleton

```dart
// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';
import '../constants/api_constants.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // Base configuration
  dio.options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  // Interceptors (order matters: auth → retry → logging)
  dio.interceptors.addAll([
    ref.read(authInterceptorProvider),
    ref.read(retryInterceptorProvider),
    if (kDebugMode) LogInterceptor(responseBody: true),
  ]);

  return dio;
});
```

### 8.2 Auth Interceptor

```dart
// lib/core/network/auth_interceptor.dart

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._ref, this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // Attach Bearer token
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired — attempt refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry original request with new token
        final retryResponse = await _retry(err.requestOptions);
        return handler.resolve(retryResponse);
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      await _secureStorage.write(key: 'access_token', value: data['access_token']);
      await _secureStorage.write(key: 'refresh_token', value: data['refresh_token']);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retry(RequestOptions options) async {
    final dio = Dio();
    final token = await _secureStorage.read(key: 'access_token');
    options.headers['Authorization'] = 'Bearer $token';
    return dio.fetch(options);
  }

  bool _isPublicEndpoint(String path) {
    // Paths are relative to base URL (e.g. /auth/login → https://www.ziro.fit/api/auth/login)
    return path == '/auth/login' ||
        path == '/auth/register' ||
        path == '/auth/refresh' ||
        path == '/auth/forgot-password' ||
        path == '/auth/mobile-signin' ||
        path == '/system/config' ||
        path.startsWith('/explore/') ||
        path.startsWith('/blog/') ||
        path.startsWith('/public/') ||
        path.startsWith('/events') ||
        path == '/contact' ||
        path == '/openapi';
  }
}
```

### 8.3 Retry Interceptor

```dart
// lib/core/network/retry_interceptor.dart

class RetryInterceptor extends Interceptor {
  static const _maxRetries = 3;
  static const _retryDelays = [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    // Only retry on network errors (not 4xx/5xx)
    if (retryCount < _maxRetries && _shouldRetry(err)) {
      await Future.delayed(_retryDelays[retryCount]);

      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {
        // Fall through to next handler
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
```

### 8.4 API Constants

```dart
// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.ziro.fit/api',
  );

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Auth (matches backend POST /api/auth/* endpoints)
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String signout = '/auth/signout';        // POST /api/auth/signout
  static const String forgotPassword = '/auth/forgot-password';
  static const String updatePassword = '/auth/update-password';
  static const String me = '/auth/me';                  // GET /api/auth/me
  static const String syncUser = '/auth/sync-user';

  // Clients (trainer manages clients)
  static const String clients = '/clients';
  static const String clientDetail = '/clients/{id}';
  static const String clientMeasurements = '/clients/{id}/measurements';
  static const String clientPhotos = '/clients/{id}/photos';
  static const String clientAssessments = '/clients/{id}/assessments';
  static const String clientSessions = '/clients/{id}/sessions';
  static const String clientDashboard = '/clients/{id}/dashboard';

  // Workout Sessions
  static const String workoutSessions = '/workout-sessions';
  static const String workoutStart = '/workout-sessions/start';
  static const String workoutFinish = '/workout-sessions/finish';
  static const String workoutLive = '/workout-sessions/live';
  static const String workoutHistory = '/workout-sessions/history';
  static const String workoutSessionDetail = '/workout-sessions/{id}';
  static const String workoutSessionComments = '/workout-sessions/{id}/comments';

  // Exercises
  static const String exercises = '/exercises';

  // Client-facing
  static const String clientDashboard = '/client/dashboard';
  static const String clientPrograms = '/client/programs';
  static const String clientProgress = '/client/progress';
  static const String clientHabits = '/client/habits';
  static const String clientCheckIn = '/client/check-in';
  static const String clientTrainer = '/client/trainer';

  // Trainer
  static const String trainerCalendar = '/trainer/calendar';
  static const String trainerCheckIns = '/trainer/check-ins';
  static const String trainerPrograms = '/trainer/programs';
  static const String trainerRecipes = '/trainer/recipes';
  static const String trainerEvents = '/trainer/events';
  static const String trainerAssessments = '/trainer/assessments';

  // Profile
  static const String profileMe = '/profile/me';
  static const String profileTextContent = '/profile/me/text-content';
  static const String profileServices = '/profile/me/services';
  static const String profilePackages = '/profile/me/packages';
  static const String profileTestimonials = '/profile/me/testimonials';

  // Bookings & Events
  static const String bookings = '/bookings';
  static const String events = '/events';

  // Notifications
  static const String notifications = '/notifications';

  // Sync
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';

  // Public
  static const String exploreFeatured = '/explore/featured';
  static const String exploreEvents = '/explore/events';
  static const String publicTrainers = '/public/trainers';
  static const String blog = '/blog';
}
```

---

## 9. Database Layer (Drift)

### 9.1 Database Definition

```dart
// lib/core/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/users_table.dart';
import 'tables/clients_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/exercises_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  // Local-only tables (populated from GET /api/auth/me, NOT via sync engine)
  Users,

  // Sync tables mirroring backend's 17-table sync protocol.
  // See OFFLINE_SYNC.md for complete table definitions.
  Clients,
  WorkoutSessions,
  Exercises,
  ClientExerciseLogs,
  Bookings,
  SyncQueue,
  // ... remaining sync tables (profiles, workout_templates, etc.)
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle schema migrations here
          if (from < 2) {
            // Example: m.addColumn(clients, clients.newColumn);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zirofit.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### 9.2 Table Definitions

```dart
// lib/core/database/tables/users_table.dart

import 'package:drift/drift.dart';

/// NOTE: All timestamp columns use Int64 (Unix ms) to match
/// the backend sync wire format. Use the dateTimeFromJson/dateTimeToJson
/// helpers for conversion. All synced tables include a syncStatus column
/// for tracking pending mutations (0=SYNCED, 1=PENDING_CREATE,
/// 2=PENDING_UPDATE, 3=PENDING_DELETE).
/// See OFFLINE_SYNC.md for complete table definitions matching ALL 17 sync tables.

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get username => text().nullable()();
  TextColumn get role => text()();
  Int64Column get emailVerifiedAt => int64().nullable()();
  IntColumn get defaultCheckInDay => integer().withDefault(const Constant(0))();
  IntColumn get defaultCheckInHour => integer().withDefault(const Constant(9))();
  TextColumn get tier => text().withDefault(const Constant('STARTER'))();
  TextColumn get subscriptionStatus => text().nullable()();
  Int64Column get trialEndsAt => int64().nullable()();
  BoolColumn get hasCompletedOnboarding => boolean().withDefault(const Constant(false))();
  TextColumn get stripeCustomerId => text().nullable()();
  TextColumn get stripeSubscriptionId => text().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('KG'))();
  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/core/database/tables/clients_table.dart

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get trainerId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  Int64Column get dateOfBirth => int64().nullable()();
  TextColumn get goals => text().nullable()();
  TextColumn get healthNotes => text().nullable()();
  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/core/database/tables/sync_queue_table.dart

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON string
  Int64Column get createdAt => int64()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
```

### 9.3 CRUD Helpers (Generated)

Drift generates type-safe CRUD methods:

```dart
// Generated code (app_database.g.dart)

// Select all clients for a trainer
Future<List<Client>> getClientsByTrainer(String trainerId) {
  return (select(clients)
        ..where((c) => c.trainerId.equals(trainerId))
        ..where((c) => c.deletedAt.isNull()))
      .get();
}

// Insert client
Future<int> insertClient(Companion<Client> client) {
  return into(clients).insert(client);
}

// Update client
Future<bool> updateClient(String id, Companions<Client> updates) {
  return (update(clients)..where((c) => c.id.equals(id))).write(updates);
}

// Soft delete client
Future<int> softDeleteClient(String id) {
  return (update(clients)..where((c) => c.id.equals(id))).write(
    ClientsCompanion(deletedAt: Value(DateTime.now())),
  );
}
```

### 9.4 Sync Metadata

All synced tables include (matching backend wire format):
- `createdAt` (Int64) — Unix ms timestamp of record creation
- `updatedAt` (Int64) — Unix ms timestamp of last modification
- `deletedAt` (Int64?) — Unix ms timestamp of soft delete (null = active)
- `syncStatus` (Int) — Pending mutation tracker: 0=SYNCED, 1=PENDING_CREATE, 2=PENDING_UPDATE, 3=PENDING_DELETE

These are used by the sync engine to:
- Pull only records modified after last sync timestamp (single API call)
- Detect conflicts (local `updatedAt` vs remote `updatedAt`)
- Handle soft deletes (sync `deletedAt` to backend)
- Track offline mutations (syncStatus for pending create/update/delete)

**IMPORTANT:** All timestamp columns use `Int64Column` (not `DateTimeColumn`) to match the backend's Unix ms wire format. See OFFLINE_SYNC.md for the complete Drift schema covering all 17 sync tables.

---

## 10. Sync Engine

### 10.1 Overview

The sync engine enables offline-first functionality by:
1. **Pulling** data from the backend on app start and periodically
2. **Pushing** local mutations (queued offline) when connectivity returns
3. **Resolving conflicts** using last-write-wins (matching backend behavior)

### 10.2 Sync Engine Implementation

```dart
// lib/data/sync/sync_engine.dart

class SyncEngine {
  final SyncRemoteSource _remoteSource;
  final SyncLocalSource _localSource;
  final SyncQueue _syncQueue;
  final ConnectivityManager _connectivityManager;

  SyncEngine({
    required SyncRemoteSource remoteSource,
    required SyncLocalSource localSource,
    required SyncQueue syncQueue,
    required ConnectivityManager connectivityManager,
  })  : _remoteSource = remoteSource,
        _localSource = localSource,
        _syncQueue = syncQueue,
        _connectivityManager = connectivityManager;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Full sync: push pending mutations first, THEN pull all changes.
  /// Push-before-pull ensures server gets client changes before
  /// generating new data (e.g. IDs, timestamps) that must be pulled back.
  Future<void> sync() async {
    if (!_connectivityManager.isOnline) {
      _statusController.add(SyncStatus.offline);
      return;
    }

    try {
      _statusController.add(SyncStatus.syncing);

      // 1. Push pending mutations to backend first
      await _push();

      // 2. Pull all changes from backend (returns ALL 17 tables at once)
      await _pull();

      _statusController.add(SyncStatus.synced);
    } catch (e) {
      _statusController.add(SyncStatus.error(e.toString()));
    }
  }

  /// Pull: single API call returns changes for ALL 17 sync tables.
  /// Backend endpoint: GET /api/sync/pull?last_pulled_at={timestamp}
  Future<void> _pull() async {
    final lastPulledAt = await _localSource.getLastPulledAt();
    final response = await _remoteSource.pull(lastPulledAt);

    // response.changes contains all tables: clients, profiles,
    // trainer_profiles, workout_sessions, exercises, workout_templates,
    // client_assessments, client_measurements, client_photos,
    // client_exercise_logs, trainer_services, trainer_packages,
    // trainer_testimonials, trainer_programs, calendar_events,
    // notifications, bookings
    for (final entry in response.changes.entries) {
      final tableName = entry.key;
      final changes = entry.value;

      // Apply created records
      for (final record in changes.created) {
        await _localSource.upsertRecord(tableName, record);
      }
      // Apply updated records (last-write-wins)
      for (final record in changes.updated) {
        await _localSource.upsertRecord(tableName, record);
      }
      // Apply soft deletions
      for (final id in changes.deleted) {
        await _localSource.softDeleteRecord(tableName, id);
      }
    }

    // Store the server timestamp for next pull
    await _localSource.setLastPulledAt(response.timestamp);
  }

  /// Push: send ALL pending mutations in a single batch.
  /// Backend endpoint: POST /api/sync/push
  Future<void> _push() async {
    final changes = await _localSource.collectPendingChanges();

    if (changes.isEmpty) return;

    await _remoteSource.push(changes);

    // Mark all pushed records as synced
    await _localSource.markAllSynced();
  }

  /// Queue a local mutation for later push
  Future<void> queueMutation({
    required String tableName,
    required String recordId,
    required String operation, // 'create', 'update', 'delete'
    required Map<String, dynamic> payload,
  }) async {
    await _syncQueue.add(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      payload: payload,
    );
  }
}
```

### 10.3 Sync Queue

```dart
// lib/data/sync/sync_queue.dart

class SyncQueue {
  final AppDatabase _db;

  SyncQueue(this._db);

  Future<void> add({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          tableName: tableName,
          recordId: recordId,
          operation: operation,
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
        ));
  }

  Future<List<SyncQueueData>> getPending() async {
    return (_db.select(_db.syncQueue)
          ..where((m) => m.synced.equals(false))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
  }

  Future<void> markSynced(int id) async {
    await (_db.update(_db.syncQueue)..where((m) => m.id.equals(id)))
        .write(const SyncQueueCompanion(synced: Value(true)));
  }

  Future<void> incrementRetry(int id) async {
    final current = await (_db.select(_db.syncQueue)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();

    if (current != null) {
      await (_db.update(_db.syncQueue)..where((m) => m.id.equals(id)))
        .write(SyncQueueCompanion(retryCount: Value(current.retryCount + 1)));
    }
  }

  Future<void> markFailed(int id, String error) async {
    // Optionally store error for debugging
    await markSynced(id); // Mark as synced to stop retrying
  }
}
```

### 10.4 Connectivity Manager

```dart
// lib/data/sync/connectivity_manager.dart

class ConnectivityManager {
  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();

  ConnectivityManager(this._connectivity) {
    _connectivity.onConnectivityChanged.listen((status) {
      final isOnline = status != ConnectivityResult.none;
      _controller.add(isOnline);
    });
  }

  Stream<bool> get connectivityStream => _controller.stream;

  bool get isOnline => _isOnline;

  bool _isOnline = true;

  Future<void> checkConnectivity() async {
    final status = await _connectivity.checkConnectivity();
    _isOnline = status != ConnectivityResult.none;
  }
}
```

### 10.5 Sync Triggers

| Trigger | Behavior |
|---|---|
| **App start** | Full sync (pull + push) |
| **Periodic** | Every 5 minutes (pull only) |
| **Pull-to-refresh** | Full sync on user gesture |
| **Connectivity restored** | Push pending mutations, then pull |
| **After mutation** | Queue mutation, attempt immediate push if online |

---

## 11. Authentication

### 11.1 Auth Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Login Form │────►│  AuthRepo   │────►│  Supabase   │────►│   Backend   │
│  (Email/    │     │  .login()   │     │  Auth SDK   │     │  /auth/login│
│   Password) │     │             │     │             │     │             │
└─────────────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
                           │                    │                    │
                           │                    │                    │
                           │              ┌─────▼──────┐            │
                           │              │ JWT Access │            │
                           │              │ + Refresh  │            │
                           │              │ Tokens     │            │
                           │              └─────┬──────┘            │
                           │                    │                    │
                           │              ┌─────▼──────┐            │
                           │              │  Secure    │            │
                           │              │  Storage   │            │
                           │              └────────────┘            │
                           │                                        │
                           │              ┌─────────────┐           │
                           └─────────────►│  Fetch User │◄──────────┘
                                          │  Profile    │
                                          └──────┬──────┘
                                                 │
                                          ┌──────▼──────┐
                                          │  AuthState  │
                                          │ .authenticated│
                                          └─────────────┘
```

### 11.2 Auth Repository

```dart
// lib/data/repositories/auth_repository.dart

class AuthRepository implements AuthRepositoryInterface {
  final AuthRemoteSource _remoteSource;
  final AuthLocalSource _localSource;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    required AuthRemoteSource remoteSource,
    required AuthLocalSource localSource,
    required FlutterSecureStorage secureStorage,
  })  : _remoteSource = remoteSource,
        _localSource = localSource,
        _secureStorage = secureStorage;

  @override
  Future<User> login(String email, String password) async {
    // 1. Call backend login endpoint
    final response = await _remoteSource.login(email, password);

    // 2. Store tokens securely
    await _secureStorage.write(key: 'access_token', value: response.accessToken);
    await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);

    // 3. Store user locally
    await _localSource.saveUser(response.user);

    return response.user;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String? role,
    required String? trainerId,
  }) async {
    // POST /api/auth/register returns { userId, requiresSubscription, confirmationRequired }
    // No tokens are returned — registration is email verification only.
    // User must log in after verifying their email.
    await _remoteSource.register(
      name: name,
      email: email,
      password: password,
      role: role,
      trainerId: trainerId,
    );
    // Navigate to login screen with "Please verify your email" message
  }

  @override
  Future<User?> getCurrentUser() async {
    // Try local first
    final localUser = await _localSource.getUser();
    if (localUser != null) return localUser;

    // Try to refresh session
    final token = await _secureStorage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final user = await _remoteSource.getCurrentUser();
      await _localSource.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _remoteSource.logout();
    await _secureStorage.deleteAll();
    await _localSource.clearUser();
  }

  @override
  Future<void> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _remoteSource.refreshToken(refreshToken);

    await _secureStorage.write(key: 'access_token', value: response.accessToken);
    await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);
  }

  @override
  Future<User> oauthLogin(OAuthProvider provider) async {
    // Use supabase_flutter for OAuth
    final response = await Supabase.instance.client.auth.signInWithOAuth(
      provider.toSupabaseProvider(),
    );

    // After OAuth callback, fetch user from backend
    final user = await _remoteSource.getCurrentUser();
    await _localSource.saveUser(user);

    return user;
  }
}
```

### 11.3 Token Refresh Strategy

| Scenario | Action |
|---|---|
| **401 response** | AuthInterceptor catches, calls `/auth/refresh`, retries request |
| **Refresh fails** | Clear tokens, redirect to `/auth/login` |
| **App start** | Validate stored token, refresh if expired |
| **Token expiry** | Proactive refresh 5 minutes before expiry |

---

## 12. Error Handling Strategy

### 12.1 Repository Level (Result Type)

```dart
// lib/core/utils/result.dart

sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppError error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  AppError? get error => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Error types
sealed class AppError {
  const AppError();

  const factory AppError.network(String message) = NetworkError;
  const factory AppError.server(int statusCode, String message) = ServerError;
  const factory AppError.auth(String message) = AuthError;
  const factory AppError.local(String message) = LocalError;
  const factory AppError.unknown(String message) = UnknownError;
}
```

### 12.2 Repository Usage

```dart
// Example: ClientRepository.getClient()

@override
Future<Result<Client>> getClient(String clientId) async {
  try {
    // Try local first
    final localClient = await _localSource.getClient(clientId);
    if (localClient != null) {
      return Result.success(localClient);
    }

    // Fetch from remote
    final remoteClient = await _remoteSource.getClient(clientId);
    await _localSource.saveClient(remoteClient);

    return Result.success(remoteClient);
  } on DioException catch (e) {
    return Result.failure(AppError.network(e.message ?? 'Network error'));
  } catch (e) {
    return Result.failure(AppError.unknown(e.toString()));
  }
}
```

### 12.3 Provider Level (AsyncValue)

```dart
// Provider wraps repository calls in AsyncValue

@riverpod
Future<Client> clientById(ClientByIdRef ref, String clientId) async {
  final repository = ref.watch(clientRepositoryProvider);
  final result = await repository.getClient(clientId);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}
```

### 12.4 UI Level

```dart
// Screen watches provider, handles AsyncValue states

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Client Detail')),
      body: clientAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientByIdProvider(clientId)),
        ),
        data: (client) => ClientDetailContent(client: client),
      ),
    );
  }
}
```

### 12.5 Error Handling Summary

| Layer | Mechanism | Example |
|---|---|---|
| **Repository** | `Result<T>` type | `Result.success(user)` or `Result.failure(AppError.network(...))` |
| **Provider** | `AsyncValue<T>` | `AsyncValue.data(user)`, `AsyncValue.error(...)`, `AsyncValue.loading()` |
| **UI** | `.when()` pattern | `loading:`, `error:`, `data:` callbacks |
| **Sync** | Retry queue | Failed mutations retry with exponential backoff |

---

## 13. Testing Architecture

### 13.1 Testing Pyramid

```
                    ┌─────────────┐
                    │     E2E     │  (Full app + backend)
                    │   5-10%     │
                    ├─────────────┤
                  ┌─┤ Integration │  (Full flows, real DB)
                  │ │   15-20%    │
                  │ ├─────────────┤
                ┌─┤ │   Widget    │  (Screens with mocked providers)
                │ │ │   30-40%    │
                │ │ ├─────────────┤
              ┌─┤ │ │    Unit     │  (Models, repos, use cases)
              │ │ │ │   40-50%    │
              │ │ │ └─────────────┘
              └─┴─┴─────────────────
```

### 13.2 Unit Tests

```dart
// test/unit/models/user_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit/data/models/user.dart';

void main() {
  group('User', () {
    test('fromJson creates valid User', () {
      final json = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'trainer',
        'tier': 'PRO',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'John Doe');
      expect(user.tier, UserTier.pro);
    });

    test('toJson produces correct wire format', () {
      final user = User(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'trainer',
        tier: UserTier.pro,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['tier'], 'PRO');
      expect(json['created_at'], 1700000000000);
    });
  });
}

// test/unit/repositories/client_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit/data/repositories/client_repository.dart';
import 'package:zirofit/data/datasources/remote/client_remote_source.dart';
import 'package:zirofit/data/datasources/local/client_local_source.dart';

class MockRemoteSource extends Mock implements ClientRemoteSource {}
class MockLocalSource extends Mock implements ClientLocalSource {}

void main() {
  late ClientRepository repository;
  late MockRemoteSource remoteSource;
  late MockLocalSource localSource;

  setUp(() {
    remoteSource = MockRemoteSource();
    localSource = MockLocalSource();
    repository = ClientRepository(
      remoteSource: remoteSource,
      localSource: localSource,
    );
  });

  group('getClient', () {
    test('returns cached client when available', () async {
      // Arrange
      final cachedClient = Client(id: '1', name: 'Cached', ...);
      when(() => localSource.getClient('1')).thenAnswer((_) async => cachedClient);

      // Act
      final result = await repository.getClient('1');

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.name, 'Cached');
      verifyNever(() => remoteSource.getClient(any()));
    });

    test('fetches from remote when cache miss', () async {
      // Arrange
      when(() => localSource.getClient('1')).thenAnswer((_) async => null);
      final remoteClient = Client(id: '1', name: 'Remote', ...);
      when(() => remoteSource.getClient('1')).thenAnswer((_) async => remoteClient);
      when(() => localSource.saveClient(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.getClient('1');

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.name, 'Remote');
      verify(() => localSource.saveClient(remoteClient)).called(1);
    });
  });
}
```

### 13.3 Widget Tests

```dart
// test/widget/features/auth/login_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit/features/auth/screens/login_screen.dart';
import 'package:zirofit/features/auth/providers/auth_provider.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  testWidgets('Login screen shows form fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(2)); // Email + Password
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login button triggers auth provider', (tester) async {
    // ... test form submission
  });
}
```

### 13.4 Integration Tests

```dart
// test/integration/auth_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zirofit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    // Enter password
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    // Tap login
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Verify dashboard is shown
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

### 13.5 E2E Tests

```dart
// test/e2e/trainer_journey_test.dart

// Full journey: Login → View Clients → Start Workout → Log Exercise → Finish
// Requires backend running (test environment)
```

---

## 14. Feature Modules Reference

### 14.1 Module Pattern

Every feature module follows this structure:

```
features/{name}/
├── providers/
│   └── {name}_provider.dart         # Riverpod providers
├── screens/
│   └── {name}_screen.dart           # Full-screen views
└── widgets/
    └── {name}_widget.dart           # Reusable widgets
```

### 14.2 Feature List

| Feature | Role | Description |
|---|---|---|
| **auth** | All | Login, register, forgot password, OAuth |
| **dashboard** | Trainer, Client | Role-specific home screens with stats |
| **workout** | Client, Trainer | Active workout, history, exercise logging |
| **clients** | Trainer | Client list, detail, measurements, progress |
| **trainer** | Trainer | Profile management, services, branding |
| **profile** | All | User profile, settings, account |
| **programs** | Trainer | Workout programs, templates, assignments |
| **checkin** | Client, Trainer | Weekly check-ins, responses |
| **calendar** | Trainer | Bookings, availability, schedule |
| **chat** | All | Conversations, messaging |
| **notifications** | All | Push notifications, in-app alerts |
| **explore** | Public | Discover trainers, view profiles |
| **events** | All | Event listing, booking, management |
| **nutrition** | Client | Meal plans, recipes, tracking |
| **habits** | Client | Daily habit tracking |
| **resources** | Trainer | Client resources, documents |
| **billing** | Trainer, Client | Subscriptions, payments, invoices |
| **settings** | All | App settings, preferences |
| **admin** | Admin | User management, moderation, analytics |
| **sync** | All | Sync status, manual sync trigger |

### 14.3 Feature Implementation Checklist

For each feature, implement:

- [ ] Data models (if not in DATA_MODELS.md)
- [ ] Remote data source (API calls)
- [ ] Local data source (Drift queries)
- [ ] Repository (with Result type)
- [ ] Repository interface (domain layer)
- [ ] Use cases (if complex business logic)
- [ ] Providers (Riverpod with code gen)
- [ ] Screens (with AsyncValue.when)
- [ ] Widgets (reusable components)
- [ ] Unit tests (models, repository, use cases)
- [ ] Widget tests (screens)
- [ ] Integration tests (full flow)

---

## 15. Conventions

### 15.1 File Naming

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `login_screen.dart`, `auth_provider.dart` |
| Classes | `PascalCase` | `LoginScreen`, `AuthProvider` |
| Variables/Methods | `camelCase` | `userEmail`, `fetchClients()` |
| Constants | `camelCase` | `baseUrl`, `maxRetries` |
| Providers | `{noun}_provider.dart` | `auth_provider.dart` |
| Tests | `{name}_test.dart` | `login_screen_test.dart` |

### 15.2 Import Order

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Package imports (alphabetical)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. Relative imports (project files)
import '../core/network/api_client.dart';
import 'auth_state.dart';
```

### 15.3 Code Organization

- **One class per file** (except small helper classes or tightly coupled types)
- **Use `const` constructors** where possible
- **All models have `fromJson`/`toJson`**
- **All enums have `fromJson`/`toJson`**
- **Prefer composition over inheritance**
- **Use sealed classes for state** (AuthState, SyncStatus)
- **Use extension methods** for utility functions on existing types

### 15.4 Async/Await

- Always use `async/await` over `.then()`
- Handle errors with `try/catch` or `Result` type
- Use `Future.wait()` for parallel async operations
- Use `Stream` for real-time data (chat, sync status)

### 15.5 Null Safety

- Non-nullable by default
- Use `?` for nullable types
- Use `late` sparingly (only when initialization is deferred)
- Use `??` and `?.` for null-safe operations
- Use `required` keyword for required parameters

---

## 16. Dependencies

### 16.1 pubspec.yaml

```yaml
name: zirofit
description: Offline-first fitness business management app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Network
  dio: ^5.4.0

  # Database
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0

  # Auth
  supabase_flutter: ^2.3.0
  flutter_secure_storage: ^9.0.0

  # Sync & Connectivity
  connectivity_plus: ^6.0.0

  # Code Generation (runtime)
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  fl_chart: ^0.68.0
  image_picker: ^1.0.0
  flutter_svg: ^2.0.0
  intl: ^0.19.0

  # Utils
  path_provider: ^2.1.0
  package_info_plus: ^8.0.0
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Code Generation (build-time)
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.16.0

  # Testing
  mocktail: ^1.0.0
  faker: ^2.1.0
```

### 16.2 Dependency Justification

| Dependency | Why |
|---|---|
| `flutter_riverpod` | Reactive state management, dependency injection, code generation |
| `go_router` | Declarative routing, guards, deep linking, shell routes |
| `dio` | HTTP client with interceptors, retry, auth token injection |
| `drift` | Type-safe SQLite ORM, migrations, code generation |
| `supabase_flutter` | Supabase Auth SDK (mirrors backend auth) |
| `flutter_secure_storage` | Secure token storage (iOS Keychain, Android Keystore) |
| `connectivity_plus` | Online/offline detection for sync engine |
| `freezed` | Immutable data classes with pattern matching |
| `json_serializable` | JSON serialization code generation |
| `cached_network_image` | Image caching with placeholders |
| `fl_chart` | Charts for progress tracking |
| `intl` | Date/number formatting, i18n support |

---

## 17. Diagrams

### 17.1 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────┐                                                               │
│  │  SCREEN  │                                                               │
│  └────┬─────┘                                                               │
│       │                                                                     │
│       │ watch()                                                             │
│       ▼                                                                     │
│  ┌──────────┐                                                               │
│  │ PROVIDER │  (Riverpod: FutureProvider / StateNotifierProvider)           │
│  └────┬─────┘                                                               │
│       │                                                                     │
│       │ call                                                                │
│       ▼                                                                     │
│  ┌──────────┐                                                               │
│  │REPOSITORY│  (implements RepositoryInterface)                             │
│  └────┬─────┘                                                               │
│       │                                                                     │
│       ├──────────────────────┬──────────────────────┐                       │
│       │                      │                      │                       │
│       │ Online               │ Offline              │                       │
│       ▼                      ▼                      │                       │
│  ┌──────────┐           ┌──────────┐                │                       │
│  │  REMOTE  │           │  LOCAL   │                │                       │
│  │DATASOURCE│           │DATASOURCE│                │                       │
│  │  (Dio)   │           │ (Drift)  │                │                       │
│  └────┬─────┘           └──────────┘                │                       │
│       │                                             │                       │
│       │ HTTP                                        │                       │
│       ▼                                             │                       │
│  ┌──────────┐                                       │                       │
│  │ BACKEND  │                                       │                       │
│  │  (REST)  │                                       │                       │
│  └──────────┘                                       │                       │
│                                                     │                       │
│  ┌──────────────────────────────────────────────────┘                       │
│  │  MUTATION (create/update/delete)                                        │
│  │                                                                          │
│  │  ┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐    │
│  │  │  LOCAL   │─────►│   SYNC   │─────►│  REMOTE  │─────►│ BACKEND  │    │
│  │  │  (Drift) │      │  QUEUE   │      │DATASOURCE│      │  (REST)  │    │
│  │  └──────────┘      └──────────┘      └──────────┘      └──────────┘    │
│  │       │                  │                                                   │
│  │       │ Optimistic       │ When online                                      │
│  │       ▼                  ▼                                                   │
│  │  ┌──────────┐      ┌──────────┐                                            │
│  │  │   UI     │      │   SYNC   │                                            │
│  │  │ UPDATED  │      │  ENGINE  │                                            │
│  │  └──────────┘      └──────────┘                                            │
│  └───────────────────────────────────────────────────────────────────────────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 17.2 Navigation Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NAVIGATION STRUCTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌──────────┐                                   │
│                              │   ROOT   │                                   │
│                              │    /     │                                   │
│                              └────┬─────┘                                   │
│                                   │                                         │
│                    ┌──────────────┼──────────────┐                          │
│                    │              │              │                          │
│                    ▼              ▼              ▼                          │
│             ┌──────────┐   ┌──────────┐   ┌──────────┐                     │
│             │   AUTH   │   │  PUBLIC  │   │  AUTHED  │                     │
│             │  GATE    │   │  ROUTES  │   │  ROUTES  │                     │
│             └────┬─────┘   └────┬─────┘   └────┬─────┘                     │
│                  │              │              │                            │
│    ┌─────────────┼──────┐      │    ┌─────────┼─────────┐                  │
│    │             │      │      │    │         │         │                  │
│    ▼             ▼      ▼      │    ▼         ▼         ▼                  │
│ ┌──────┐  ┌──────┐ ┌──────┐   │ ┌──────┐ ┌──────┐ ┌──────┐               │
│ │/login│  │/reg  │ │/forgot│  │ │TRAINR│ │CLIENT│ │ADMIN │               │
│ └──────┘  └──────┘ └──────┘   │ │SHELL │ │SHELL │ │SHELL │               │
│                                │ └──┬───┘ └──┬───┘ └──┬───┘               │
│                                │    │        │        │                    │
│                                │    ▼        ▼        ▼                    │
│                                │ ┌──────┐ ┌──────┐ ┌──────┐               │
│                                │ │/dash │ │/dash │ │/dash │               │
│                                │ │/clnts│ │/prog │ │/users│               │
│                                │ │/cal  │ │/wrkot│ │/evnts│               │
│                                │ │/prof │ │/habts│ │/blog │               │
│                                │ └──────┘ └──────┘ └──────┘               │
│                                │                                            │
│                                ▼                                            │
│                             ┌──────┐                                        │
│                             │/train│                                        │
│                             │ers   │                                        │
│                             │/:user│                                        │
│                             └──────┘                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 17.3 Provider Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PROVIDER DEPENDENCY GRAPH                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ┌──────────────────┐                                │
│                         │   authProvider   │                                │
│                         │ (StateNotifier)  │                                │
│                         └────────┬─────────┘                                │
│                                  │                                          │
│              ┌───────────────────┼───────────────────┐                      │
│              │                   │                   │                      │
│              ▼                   ▼                   ▼                      │
│   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐           │
│   │ userProfilePvd   │ │ isTrainerPvd     │ │ syncEnginePvd    │           │
│   │ (FutureProvider) │ │ (Provider)       │ │ (Provider)       │           │
│   └────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘           │
│            │                    │                    │                      │
│            │                    │                    │                      │
│            ▼                    ▼                    ▼                      │
│   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐           │
│   │ clientsListPvd   │ │ trainerDashPvd   │ │ syncStatusPvd    │           │
│   │ (FutureProvider) │ │ (FutureProvider) │ │ (StreamProvider) │           │
│   └────────┬─────────┘ └──────────────────┘ └──────────────────┘           │
│            │                                                                │
│            │                                                                │
│            ▼                                                                │
│   ┌──────────────────┐                                                      │
│   │ clientByIdPvd    │                                                      │
│   │ (FutureProvider  │                                                      │
│   │  .family)        │                                                      │
│   └──────────────────┘                                                      │
│                                                                             │
│   ┌──────────────────┐                                                      │
│   │ workoutHistPvd   │                                                      │
│   │ (FutureProvider) │                                                      │
│   └────────┬─────────┘                                                      │
│            │                                                                │
│            ▼                                                                │
│   ┌──────────────────┐                                                      │
│   │ activeWorkoutPvd │                                                      │
│   │ (StateNotifier)  │                                                      │
│   └──────────────────┘                                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 18. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)

- [ ] Project setup (Flutter, dependencies, linting)
- [ ] Core layer: API client, Drift database, router, theme
- [ ] Auth feature: login, register, token refresh
- [ ] Basic navigation with role-based routing
- [ ] Unit tests for models and auth repository

### Phase 2: Core Features (Week 3-5)

- [ ] Dashboard (trainer + client)
- [ ] Client management (list, detail, measurements)
- [ ] Workout engine (sessions, exercise logging)
- [ ] Sync engine (pull/push, queue, connectivity)
- [ ] Widget tests for all screens

### Phase 3: Advanced Features (Week 6-8)

- [ ] Programs & templates
- [ ] Calendar & bookings
- [ ] Check-ins
- [ ] Chat/messaging
- [ ] Integration tests for full flows

### Phase 4: Polish & Launch (Week 9-10)

- [ ] Notifications
- [ ] Billing/Stripe
- [ ] Admin panel
- [ ] E2E tests
- [ ] Performance optimization
- [ ] App store submission

---

## Appendix A: Key Design Decisions

| Decision | Rationale |
|---|---|
| **Riverpod over BLoC** | Better code generation, simpler dependency injection, more flexible |
| **Drift over Hive/Isar** | Relational data (30+ models with relations), SQL queries, migrations |
| **Feature-first over layer-first** | Better cohesion, easier to find related code, scalable |
| **Result type over exceptions** | Explicit error handling, no hidden control flow |
| **Sealed classes for state** | Exhaustive pattern matching, type safety |
| **Optimistic updates** | Better UX, immediate feedback, sync in background |
| **Last-write-wins conflicts** | Matches backend behavior, simpler than CRDT |

## Appendix B: Glossary

| Term | Definition |
|---|---|
| **Sync Engine** | System that orchestrates pull/push of data between local DB and backend |
| **Sync Queue** | FIFO queue of pending mutations (create/update/delete) to be pushed |
| **Optimistic Update** | Update UI immediately before server confirmation |
| **Soft Delete** | Mark record as deleted (set `deletedAt`) instead of removing |
| **Last-Write-Wins** | Conflict resolution where most recent `updatedAt` wins |
| **Offline-First** | App works fully offline, syncs when connectivity available |

---

**Document Version:** 1.0.0
**Last Updated:** 2026-05-01
**Author:** Ziro Fit Engineering Team
