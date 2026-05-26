# iOS → Flutter 99% Parity Plan

**Scope:** Address all 23 identified gaps to bring the Flutter app to feature parity with the iOS app
**Verification Date:** 2026-05-26
**Status:** ✅ 6 items already done, ⚠️ 4 partial, ❌ 9 missing, ➕ 4 extra gaps found
**Total Effort:** ~18-22 days

---

## ✅ VERIFIED: Already Implemented (6 items — NO ACTION)

These 6 gaps are already present in the Flutter codebase and require no work:

| # | Gap | File Evidence |
|---|-----|---------------|
| 1 | **Mode Selector Swipe Gesture** — horizontal swipe (40% threshold), vertical swipe (40px), tap-to-expand mode overlay with haptics | `lib/features/dashboard/widgets/ziro_tab_bar.dart` |
| 2 | **Active Session Conflict Detection** — Resume/End&Start/Cancel dialog when starting workout with existing session | `lib/features/workout/screens/enhanced_active_workout_screen.dart` (line ~645) |
| 3 | **Coach/Check-in Banners** — Dismissable "Find a Coach" + check-in CTA on client dashboard | `lib/features/dashboard/screens/client_dashboard_screen.dart` |
| 4 | **Mode Switch Gradient Animation** — Animated border glow on mode change (0.1s fade-in, 0.7s hold, 0.8s fade-out) | `lib/features/dashboard/widgets/ziro_tab_bar.dart` |
| 5 | **Long Session Warnings** — 2h warning banner, 4h auto-end with callbacks | `lib/features/workout/providers/workout_timer_provider.dart` |
| 6 | **Personal Routines Experimental Toggle** — `isRoutinesEnabled` in PreferencesProvider | `lib/features/settings/providers/preferences_provider.dart` |

---

## ⚠️ PARTIAL: Already Started (4 items)

### P1. Pop-to-Root on Tab Re-Tap
**Current:** Double-tap detected (500ms window in `ZiroTabBar._onTabTap`) but calls `context.go(route)` instead of popping the navigator stack
**Goal:** On double-tap of active tab, pop all GoRouter pages to the tab root
**Effort:** 2h
**Files:** `lib/features/dashboard/widgets/ziro_tab_bar.dart`, `lib/features/dashboard/widgets/ziro_shell.dart`
**Pattern:** iOS posts `Notification.Name("PopToRoot")` — Flutter should use `context.popUntilRoot()` or call `GoRouter.of(context).go(currentRoute)`
**Success:** Double-tap home tab from deep sub-route → returns to tab root screen

### P2. QR Code Business Card Screen
**Current:** `QrCodeGenerator` widget exists at `lib/features/clients/widgets/qr_code_generator.dart` but no screen/sheet wires it up for trainer profile
**Goal:** Add QR Code screen/sheet for trainers encoding `https://ziro.fit/trainer/{username}`
**Effort:** 4h
**Files:** `lib/features/trainer/screens/trainer_qr_code_screen.dart` (new), wired from `MoreView` / trainer profile
**Pattern:** iOS `TrainerQRCodeView` with username → QR code generation
**Success:** Trainer can tap "Digital Business Card" in More → sees QR code → can be scanned to open public profile

### P3. Syncing Workout Overlay
**Current:** Inline "Saving..." text in `workout_session_header.dart` — no full-screen overlay like iOS
**Goal:** Add semi-transparent full-screen overlay with spinner + "Syncing workout..." when `isSyncingWorkout` is true
**Effort:** 3h
**Files:** Modify `enhanced_active_workout_screen.dart` to conditionally show overlay at `zIndex: 100`, reuse existing `isSyncingWorkout` from `ActiveWorkoutState`
**Pattern:** iOS `ZStack` with `ProgressView` + "Syncing workout..." + shadow + `zIndex(100)`
**Success:** When slow network, overlay appears during sync, disappears when complete

### P4. Audio Coach Transition Cues
**Current:** `VoiceFeedbackService` announces PRs, rest timer, workout complete — but NOT exercise transitions
**Goal:** When exercise changes (next exercise starts), speak exercise name + target via TTS
**Effort:** 4h
**Files:** `lib/features/workout/services/voice_feedback_service.dart` + `lib/features/workout/providers/active_workout_provider.dart`
**Pattern:** iOS `VoiceCoachManager` announces "Next up: [exercise name]. [reps] reps at [weight]"
**Success:** During workout, when advancing to next exercise, audio cue plays with exercise details

---

## ❌ NOT IMPLEMENTED: Full Build (13 items)

---

## PHASE 1: Quick Wins (3 tasks — ~3 days)

### 1.1 Stripe/Event Deep Links (1 day)
**Goal:** Handle `zirofitapp://stripe-return` and `zirofitapp://events` deep links in GoRouter
**Effort:** 4h
**Files:** `lib/core/router/app_router.dart`
**Requires:** Register deep link handling + map to existing or new screens
**Success:** Opening Stripe return URL → navigates to billing/payouts screen; opening event URL → navigates to event detail

### 1.2 Purchase/Transaction History Screen (1 day)
**Goal:** New screen showing transaction/purchase history list
**Effort:** 6h
**Files:** 
- `lib/features/billing/screens/transaction_history_screen.dart` (new)
- Register route in `app_router.dart` under `/client/transactions` and `/trainer/transactions`
- Wire into More/Settings menu
**Endpoint:** `GET /api/clients/[id]/packages` or similar — verify backend has purchase history endpoint
**Pattern:** iOS `TransactionHistoryView` shows records with date, amount, description
**Success:** Screen displays paginated purchase history, navigable from More

### 1.3 Clients Summary Sidebar on Calendar (1.5 days)
**Goal:** Add collapsible sidebar/list showing which clients have sessions on calendar date
**Effort:** 8h
**Files:** 
- `lib/features/calendar/screens/calendar_screen.dart` — add sidebar panel
- `lib/features/calendar/providers/calendar_provider.dart` — may need to load clients summary data
**Endpoint:** `GET /api/trainer/calendar/clients-summary`
**Pattern:** iOS shows client list for selected date(s) in CalendarView
**Success:** Tapping a calendar date shows which clients have sessions booked that day

---

## PHASE 2: New User Flows (2 tasks — ~4 days)

### 2.1 Sheet-Based Re-Login on Mode Switch (2 days)
**Goal:** When switching to a mode that isn't authenticated, show login sheet instead of redirecting fully; preserve ability to return to previous mode
**Effort:** 10h
**Files:**
- `lib/features/dashboard/widgets/ziro_shell.dart` — intercept mode switch
- `lib/features/dashboard/widgets/ziro_tab_bar.dart` — handle auth gate
- `lib/features/auth/screens/login_screen.dart` — adapt for sheet presentation
- New provider or modify `auth_provider.dart` for dual-auth-aware mode switch
**Important:** Flutter does NOT have iOS's dual-token storage. Must decide: (a) show login sheet, re-auth, switch OR (b) block switch with "Please login in [other mode] first"
**Success:** Trainer in trainer mode taps personal mode → not authenticated → login sheet appears → logs in → seamlessly switches

### 2.2 Trainer Finding Onboarding Flow (2 days)
**Goal:** New guided flow for client users who haven't found a trainer yet — similar to iOS `TrainerFindingOnboardingView`
**Effort:** 10h
**Files:**
- `lib/features/explore/screens/trainer_finding_onboarding_screen.dart` (new)
- Register route in `app_router.dart` as `/onboarding/find-trainer`
- Trigger on first login for client users without linked trainer
**Pattern:** iOS walks through: (1) "Find a trainer" intro, (2) Browse specialties, (3) Location, (4) Browse results
**Success:** First-time client user without trainer sees onboarding → selects specialty/location → shown matching trainers

---

## PHASE 3: Calendar + Notifications (2 tasks — ~3 days)

### 3.1 Cross-Mode Notification Alerts (1.5 days)
**Goal:** When notification arrives for a different role than current mode, show alert with "Switch to X mode" action
**Effort:** 8h
**Files:**
- `lib/features/notifications/providers/notifications_provider.dart` — detect role mismatch
- `lib/features/dashboard/widgets/ziro_shell.dart` — show alert dialog with switch action
- New model/helper for notification → mode mapping
**Pattern:** iOS `AppState.showCrossModeAlert` + `pendingNotificationMode`
**Success:** Client in personal mode receives trainer notification → alert "Switch to Professional mode to view?" → tap → switches

### 3.2 Event Map View (1.5 days)
**Goal:** Add map view for events (separate from existing trainer map)
**Effort:** 8h
**Files:**
- `lib/features/events/screens/event_map_screen.dart` (new)
- Register route or integrate with `event_detail_screen.dart`
- Use `flutter_map` with OpenStreetMap tiles (matching existing pattern)
**Pattern:** iOS `MarketplaceView` has map toggle with event pins
**Success:** Events screen has map/list toggle → map shows event pins → tap pin shows event info

---

## PHASE 4: Widgets & Polish (3 tasks — ~2.5 days)

### 4.1 ActiveRoutineWidget (1 day)
**Goal:** Dashboard widget showing current routine progress on client home
**Effort:** 5h
**Files:**
- `lib/features/dashboard/widgets/active_routine_widget.dart` (new)
- Integrate into `client_dashboard_screen.dart`
**Pattern:** iOS `ActiveRoutineWidget` shows template name, exercise progress, next exercise
**Success:** Client dashboard shows routine card when active routine exists

### 4.2 Swipe-to-Complete Exercises (1 day)
**Goal:** Allow swipe gesture on exercise cards to mark sets complete (matching iOS WorkoutExerciseCard + swipe interaction)
**Effort:** 5h
**Files:**
- `lib/features/workout/widgets/enhanced_exercise_list_builder.dart` — add `Dismissible` or custom swipe
- `lib/features/workout/widgets/enhanced_workout_set_row.dart` — swipe action
**Pattern:** iOS swipes right on set row to mark complete
**Success:** Swipe right on exercise set → set marked complete with animation

### 4.3 Program Builder Choice (0.5 day)
**Goal:** When creating a program, show choice between "Standard" (existing) and "Visual Timeline" (new)
**Effort:** 3h
**Files:**
- `lib/features/programs/screens/program_builder_choice_screen.dart` (new)
- Wire from `ProgramsListScreen` + `CreateProgramScreen`
- Only show when Visual Timeline Builder exists (Phase 7)
**Pattern:** iOS `ProgramBuilderChoiceView` with two cards
**Success:** Trainer taps "Create Program" → sees two builder options → picks one

---

## PHASE 5: Event Marketplace (1 task — ~3 days)

### 5.1 Event Marketplace (Combined List/Map)
**Goal:** Combined events + featured trainers view with list/map toggle
**Effort:** 14h
**Files:**
- `lib/features/explore/screens/marketplace_screen.dart` (new)
- `lib/features/explore/widgets/marketplace_list_view.dart` (new)
- `lib/features/explore/widgets/marketplace_map_view.dart` (new)
- Register route as `/client/marketplace`
**Important Constraints:**
- Split into sub-tasks: (a) List view first, (b) Map view second
- Map needs clustering for 100+ pins
- Data source: `/api/explore/featured` + `/api/events`
**Success:** Combined view with list/map toggle, filters, search

---

## PHASE 6: Login Prefetch (1 task — ~2 days)

### 6.1 Prefetch Strategy on Login
**Goal:** On login, prefetch dashboard, clients, programs, calendar, analytics data in background for instant loading
**Effort:** 10h
**Files:**
- New service: `lib/core/services/login_prefetch_service.dart`
- Hook into `auth_provider.dart` after successful login
- Create Riverpod `FutureProvider` for each dataset, call them in parallel
**Important:**
- Don't block UI — fire and forget
- Handle partial failures gracefully
- Match iOS prefetch: Trainer → dashboard + clients + programs + templates + calendar (5mo) + clients summary; Personal → dashboard + active program + analytics (30d) + history (20) + exercises (100)
**Success:** After login, app loads instantly because data is already cached

---

## PHASE 7: Visual Timeline Builder — HIGH EFFORT (3 sub-tasks — ~6 days)

### 7.1 Visual Timeline — Data Model + State (2 days)
**Goal:** Data models for timeline structure + state management
**Effort:** 10h
**Files:**
- `lib/features/programs/models/timeline_models.dart` — `TimelineWeek`, `TimelineDay`, `TimelineSlot`
- `lib/features/programs/providers/timeline_builder_provider.dart` — state management
**Success:** Timeline data model stores weeks/days/slots, supports add/remove/reorder

### 7.2 Visual Timeline — Drag-Drop Week View (2.5 days)
**Goal:** Drag-and-drop week/day view showing program structure
**Effort:** 14h
**Files:**
- `lib/features/programs/screens/visual_timeline_builder_screen.dart` (new)
- Use `reorderable` or `drag_and_drop_lists` package
- Horizontal week scroll + vertical day rows + exercise assignment
**Important:** 
- Must support: add week, add day, assign template to day, reorder weeks/days
- Exercise library integration for template creation
**Success:** Full drag-drop timeline builder with week/day/template management

### 7.3 Visual Timeline — API Integration (1.5 days)
**Goal:** Save timeline structure to existing program/template API endpoints
**Effort:** 8h
**Files:**
- Existing `programs_remote_source.dart` — add timeline-specific API calls
- Adapt existing `POST /api/trainer/programs` to accept timeline data
**Success:** Building a timeline saves as a standard program with week-based template structure

---

## SUMMARY

| Phase | Tasks | Effort | Dependencies | Priority |
|-------|-------|--------|--------------|----------|
| ✅ Already Done | 6 items | 0 | None | — |
| ⚠️ Partial | 4 items | 13h | None | **IMMEDIATE** |
| Phase 1: Quick Wins | 3 tasks | 18h | None | **P0** |
| Phase 2: New User Flows | 2 tasks | 20h | None | **P0** |
| Phase 3: Calendar + Notifications | 2 tasks | 16h | None | **P1** |
| Phase 4: Widgets & Polish | 3 tasks | 13h | Phase 5 (choice depends on builder) | **P1** |
| Phase 5: Event Marketplace | 1 task | 14h | None | **P2** |
| Phase 6: Login Prefetch | 1 task | 10h | None | **P2** |
| Phase 7: Visual Timeline Builder | 3 sub-tasks | 32h | Phase 4.3 (choice) | **P3** |

**Total remaining effort:** ~108h (~18 days at 6h/day) for all 23 gaps
**Target 99% parity:** Phases 1-4 (12 gaps, ~62h = ~10 days) covers the highest-impact gaps
**Nice-to-have (95%→99%):** Phases 5-7 (5 gaps, ~56h = ~9 days)

### Items NOT in plan (platform-specific, 100% unattainable):
- Live Activities (iOS lock screen) — needs native plugin
- Apple Calendar sync — iOS-only API
- Siri integration — iOS-only
- Share extension / iOS widgets — platform-specific

---

## FILE CHANGE SUMMARY

### New Files (13)
```
lib/features/trainer/screens/trainer_qr_code_screen.dart
lib/features/billing/screens/transaction_history_screen.dart
lib/features/explore/screens/trainer_finding_onboarding_screen.dart
lib/features/events/screens/event_map_screen.dart
lib/features/dashboard/widgets/active_routine_widget.dart
lib/features/programs/screens/program_builder_choice_screen.dart
lib/features/explore/screens/marketplace_screen.dart
lib/features/explore/widgets/marketplace_list_view.dart
lib/features/explore/widgets/marketplace_map_view.dart
lib/core/services/login_prefetch_service.dart
lib/features/programs/models/timeline_models.dart
lib/features/programs/providers/timeline_builder_provider.dart
lib/features/programs/screens/visual_timeline_builder_screen.dart
```

### Modified Files (18+)
```
lib/core/router/app_router.dart
lib/features/dashboard/widgets/ziro_shell.dart
lib/features/dashboard/widgets/ziro_tab_bar.dart
lib/features/dashboard/screens/client_dashboard_screen.dart
lib/features/workout/screens/enhanced_active_workout_screen.dart
lib/features/workout/services/voice_feedback_service.dart
lib/features/workout/providers/active_workout_provider.dart
lib/features/workout/widgets/enhanced_exercise_list_builder.dart
lib/features/workout/widgets/enhanced_workout_set_row.dart
lib/features/calendar/screens/calendar_screen.dart
lib/features/calendar/providers/calendar_provider.dart
lib/features/notifications/providers/notifications_provider.dart
lib/features/auth/providers/auth_provider.dart
lib/features/auth/screens/login_screen.dart
lib/features/trainer/screens/more_screen.dart (or equivalent)
lib/features/programs/screens/programs_list_screen.dart
lib/features/programs/screens/create_program_screen.dart
lib/core/network/api_client.dart (or existing remote source)
```

---

## ACCEPTANCE CRITERIA

### Partial Fixes
- **Pop-to-root:** `flutter test` asserting double-tap on active tab pops navigator stack
- **QR Code:** `QrImageView` renders with `https://ziro.fit/trainer/{username}` as data
- **Syncing overlay:** Setting `isSyncingWorkout=true` shows overlay, `false` hides
- **Audio cues:** Mock `VoiceFeedbackService.speak()` and verify called on exercise index change

### Phase 1
- **Deep links:** Opening `zirofitapp://stripe-return` → navigates to billing screen
- **Purchase history:** Screen shows >0 records from API call
- **Clients summary:** Calendar date tap reveals client names

### Phase 2
- **Re-login sheet:** Unauthenticated mode switch → login sheet appears → auth → mode switches
- **Trainer finding:** First-time client sees onboarding → completes → navigated to trainer discovery

### Phase 3
- **Cross-mode notifications:** Notification with mismatched role → alert with switch action → tap switches mode
- **Event map:** Map shows event pins → tap → event detail

### Phase 4
- **ActiveRoutineWidget:** Renders on dashboard when routine active
- **Swipe-to-complete:** Swipe right → set marked complete
- **Builder choice:** Two option cards → each navigates to correct builder

### Phase 5
- **Marketplace:** List shows events + trainers → toggle shows map → filters work

### Phase 6
- **Prefetch:** After login, dashboard/provider loads from cache within 100ms

### Phase 7
- **Timeline builder:** Create weeks → drag-drop → assign exercises → save → load saved timeline

---

## RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Visual Timeline Builder scope creep | High | High | Split into 3 sub-tasks, define exact data model upfront |
| Event Marketplace performance (map clustering) | Medium | Medium | Build list first, map second; use flutter_map cluster plugin |
| Dual-token re-login architecture | Medium | High | Decide auth strategy before implementing; option A (login sheet) preferred |
| Backend missing purchase history endpoint | Medium | High | Verify API exists first; may need to create or use existing client packages endpoint |
| Prefetch conflicting with lazy-loading patterns | Low | Medium | Prefetch writes to provider cache; don't override user-initiated refreshes |

---

## EXECUTION ORDER (Recommended)

```
WEEK 1:
  Mon: P1 (Pop-to-root) + P2 (QR Code) + P3 (Syncing overlay)
  Tue: P4 (Audio cues) + 1.1 (Deep links)
  Wed: 1.2 (Purchase history) + 1.3 (Clients summary start)
  Thu: 1.3 (finish) + 2.1 (Re-login sheet start)
  Fri: 2.1 (finish)

WEEK 2:
  Mon: 2.2 (Trainer finding onboarding)
  Tue: 3.1 (Cross-mode notifications) + 3.2 (Event map)
  Wed: 4.1 (ActiveRoutineWidget) + 4.2 (Swipe-to-complete)
  Thu: 6.1 (Prefetch) — start
  Fri: 6.1 (finish) + 4.3 (Builder choice — if Phase 7 exists)

WEEK 3:
  Mon: 5.1 (Event Marketplace list)
  Tue: 5.1 (Event Marketplace map + toggle)
  Wed: 7.1 (Timeline data model + state)
  Thu: 7.2 (Timeline drag-drop view)
  Fri: 7.2 (continue) + 7.3 (API integration)
```
