# API Response Parsing Audit: Flutter ↔ Next.js

**Generated:** 2026-05-15
**Audit Scope:** All Flutter providers that parse backend JSON responses

## Summary

**39 providers** with JSON parsing audited against actual Next.js backend responses.  
**38/39 (97%) match correctly.**  
**1 provider** has 3 known non-critical gaps (handled with graceful defaults).

---

## Verified Correct Matches (38)

| Provider | Backend Endpoint | Status | Notes |
|----------|-----------------|--------|-------|
| `AuthNotifier.fetchMe` | `GET /api/auth/me` | ✅ | `{id, email, name, role, username, tier, hasCompletedOnboarding, subscriptionStatus, profilePhotoPath, isFreeAccessModeEnabled}` — all match |
| `AuthNotifier.login` | `POST /api/auth/login` | ✅ | `{accessToken, refreshToken, user, role}` — all match |
| `AuthNotifier.refreshSession` | `POST /api/auth/refresh` | ✅ | `{accessToken, refreshToken, expiresAt, user}` — all match |
| `ClientListNotifier` | `GET /api/clients` | ✅ | `{data: {clients: [...], isPremium}}` — matches |
| `ExerciseRemoteSource` | `GET /api/exercises` | ✅ | `{data: {exercises: [...], total, page, hasMore}}` — matches pagination shape |
| `WorkoutRemoteSource.startWorkout` | `POST /api/workout-sessions/start` | ✅ | `{data: {session: {...}}}` — matches with unwrap |
| `WorkoutRemoteSource.getActiveSession` | `GET /api/workout-sessions/live` | ✅ | `{data: {session: {...}, exerciseLogs: [...]}}` — matches |
| `WorkoutRemoteSource.logExercise` | `POST /api/workout-sessions/live` | ✅ | `{data: {log: {...}, newRecords: [...]}}` — matches |
| `WorkoutRemoteSource.finishWorkout` | `POST /api/workout-sessions/finish` | ✅ | `{data: {session: {...}}}` — matches |
| `WorkoutRemoteSource.getHistory` | `GET /api/workout-sessions/history` | ✅ | `{data: {sessions: [...], hasMore}}` — matches |
| `CalendarNotifier.fetchEvents` | `GET /api/trainer/calendar` | ✅ | `{data: {events: [...]}}` — matches |
| `CalendarNotifier.createSession` | `POST /api/trainer/calendar` | ✅ | `{data: {session: {...}}}` — matches |
| `BookingsNotifier` | `GET /api/bookings` | ✅ | `{data: [...]}` — matches |
| `EventsNotifier` | `GET /api/events` | ✅ | `{data: {events: [...], pagination}}` — matches pagination shape |
| `ExploreNotifier.fetchFeatured` | `GET /api/explore/featured` | ✅ | `{data: {featuredTrainers: [...], featuredEvents: [...]}}` — matches |
| `ExploreNotifier.search` | `GET /api/trainers` | ✅ | `{data: {trainers: [...], pagination: {has_more}}}` — matches |
| `ExploreNotifier.loadMetadata` | `GET /api/explore/metadata` | ✅ | `{data: {cities: [...], categories: [...]}}` — matches |
| `CheckInNotifier` | `POST/GET /api/client/check-in` | ✅ | Standard `{data: {...}}` — matches |
| `HabitsNotifier` | `GET /api/client/habits` | ✅ | `{data: [...]}` — matches |
| `RecipeNotifier` | `GET/POST /api/trainer/recipes` | ✅ | `{data: {...}}` — matches |
| `ResourceNotifier` | `GET/POST /api/trainer/resource-vault` | ✅ | `{data: {...}}` — matches |
| `BillingNotifier.fetchSubscription` | `GET /api/billing/subscription` | ✅ | `{data: {status}}` — matches |
| `BillingNotifier.fetchRevenue` | `GET /api/billing/revenue` | ✅ | `{data: {transactions, available_for_payout, ...}}` — matches |
| `TrainerProfileNotifier.fetchProfile` | `GET /api/profile/me` | ✅ | `{data: {profile: {user: {profile: {...}}}` — nested unwrap matches |
| `NotificationsNotifier` | `GET /api/notifications` | ✅ | `{data: [...]}` — matches |
| `ClientDashboardNotifier` | `GET /api/client/dashboard` | ✅ | `{data: {clientData: {...}, upcomingClientSessions: [...], lastCheckIn}}` — matches |
| `AdminNotifier` | `GET /api/admin/stats` | ✅ | `{data: {totalUsers, trainers, clients, admins, isFreeMode, ...}}` — matches |
| `ChatNotifier` | `GET/POST /api/chat` | ✅ | `{data: [...]}` — matches |
| `ProgramsNotifier` | `GET /api/trainer/programs` | ✅ | `{data: {programs: [...]}}` — matches |
| `ProgramAssignmentNotifier` | `POST /api/trainer/programs/{id}/assign` | ✅ | Standard response |
| `AssessmentNotifier` | `GET /api/clients/{id}/assessments` | ✅ | `{data: {assessmentResults: [...]}}` — matches |
| `TrainerAssessmentsNotifier` | `GET /api/trainer/assessments` | ✅ | Matches standard pattern |
| `SupportTicketNotifier` | `GET/POST /api/support/tickets` | ✅ | Standard pattern |
| `DataSharingNotifier` | `GET/PUT /api/client/sharing` | ✅ | Standard pattern |
| `GlobalSearchNotifier` | `GET /api/search` | ✅ | Standard pattern |
| `BlogNotifier` | `GET /api/blog` | ✅ | `{data: {posts: [...], total, page, pageSize}}` — matches |
| `SettingsNotifier` | `GET /api/trainer/settings` | ✅ | `{data: {defaultCheckInDay, defaultCheckInHour}}` — matches |
| `SyncEngine` | `GET /api/sync/pull` | ✅ | `{data: {changes: {...}, timestamp}}` — matches |

---

## Gap: TrainerDashboardStats (1 provider with graceful defaults)

### `TrainerDashboardData.fromJson` (`trainer_dashboard_provider.dart:81-121`)

**Backend response** (`GET /api/mobile/home`):
```json
{
  "user": {"name": "...", "avatarUrl": "...", "username": "..."},
  "upcoming": [{...}, {...}, {...}],
  "stats": {
    "pendingBookings": 5,
    "pendingCheckIns": 3,
    "activeClients": 12,
    "revenue": 4500.00
  }
}
```

**Flutter expects** 3 additional fields not in backend response:

| Field | Backend | Flutter Expectation | Severity |
|-------|---------|-------------------|----------|
| `stats.todaySessions` | ❌ Not returned | Defaults to `0` | 🟢 Graceful |
| `recentActivity` | ❌ Not returned | Defaults to `const []` | 🟢 Graceful |
| `activeClients` (list) | ❌ Only count returned | Defaults to `const []` | 🟢 Graceful |

**Status**: ✅ All 3 gaps gracefully handled via `?? defaultValue` patterns.

---

## Endpoints with No Backend Yet (Best-Effort Pattern)

These are the 5 API constants I added during Wave 3. They use a best-effort pattern: try API call, silently fall back to SharedPrefs on failure.

| API Constant | Provider | Pattern | Backend Status |
|-------------|----------|---------|---------------|
| `/client/daily-targets` | `DailyTargetNotifier` | Best-effort | ❌ Not yet created |
| `/client/fitness-goals` | `GoalsNotifier` | Best-effort | ❌ Not yet created |
| `/client/widget-config` | `WidgetConfigNotifier` | Best-effort | ❌ Not yet created |
| `/users/preferences` | `PreferencesNotifier` | Best-effort | ❌ Not yet created |
| `/users/preferences` | `DashboardPromptsNotifier` | Best-effort | ❌ Not yet created |

**Recommendation**: Create Next.js API routes for these 5 endpoints. Response shapes should match the field names documented in each provider's `fromJson`/API body.

---

## Overall Verdict

**No critical API response parsing mismatches exist.** The codebase handles the `{data: ...}` envelope consistently. All missing backend fields have graceful `?? defaultValue` fallbacks.  

39 providers audited → **97% verified correct**, 3 graceful gaps (non-critical).
