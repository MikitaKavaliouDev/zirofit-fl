# Full iOS Parity Plan — Flutter Gap Implementation

**Goal**: Match Flutter app 100% to iOS — every feature, screen, API call, modal, and UI pattern.
**Constraint**: `flutter analyze` must pass with zero errors.

---

## Phase 0: Foundation — Auth Critical (5 items, ~30% dependency block)

These are pre-requisites. Auth affects every authenticated feature.

### P0-A: Native Apple Sign In
- **Gap**: Web-based OAuth → native `ASAuthorizationAppleIDProvider`
- **Files**: `auth_provider.dart`, new `apple_sign_in_helper.dart`
- **Work**: Replace `signInWithOAuth('apple')` with `sign_in_with_apple` package, nonce/SHA256 generation, native credential handling
- **Verification**: Apple SSO works without browser redirect

### P0-B: Multi-Account Auth State
- **Gap**: UI-only mode switch → true dual-account with separate sessions
- **Files**: `auth_provider.dart`, `mode_switch_provider.dart`, `secure_storage.dart`
- **Work**: Add `trainerUser`/`clientUser` in-memory caches, surgical logout per role, separate token refresh per mode
- **Verification**: Can keep both roles logged in simultaneously, switch without re-auth

### P0-C: Password Reset Deep Link
- **Gap**: No deep link handling → `next=update-password` flow
- **Files**: `deep_link_service.dart`, `update_password_screen.dart`
- **Work**: Parse `update-password` param, add token-authenticated update screen (no current password required)
- **Verification**: Click password reset email link → update password without typing current password

### P0-D: Cookie-Based Trainer Auth
- **Gap**: No cookie support → hybrid cookie/token for trainer mode
- **Files**: `auth_interceptor.dart`, `secure_storage.dart`, `api_client.dart`
- **Work**: Add `httpShouldHandleCookies` equivalent, cookie extraction/storage, cookie clearing on logout
- **Verification**: Trainer mode uses cookies, client mode uses tokens, logout clears cookies

### P0-E: Onboarding Avatar Upload
- **Gap**: JSON-only → multipart form-data with image
- **Files**: `auth_provider.dart`, `onboarding_screen.dart`
- **Work**: Add image picker to onboarding, change `completeOnboarding` to multipart upload
- **Verification**: Onboarding avatar appears in profile after completion

---

## Phase 1: Navigation & Shell (5 items, blocks all screen-pattern work)

### P1-A: Tab Count Alignment
- **Gap**: 6 tabs vs iOS 5 tabs
- **Files**: `ziro_tab_bar.dart`, `ziro_shell.dart`, `app_router.dart`
- **Work**: Decide alignment direction (merge Settings into More-like menu, or keep 6). Implement chosen approach.
- **Verification**: Tab count matches iOS per role

### P1-B: Tab Bar Badge Counts
- **Gap**: No unread notification badges on tabs
- **Files**: `ziro_tab_bar.dart`, `ziro_tab_item.dart`, notification providers
- **Work**: Wire unread count stream to tab items, render badge overlay
- **Verification**: Badge appears with unread notifications, clears on view

### P1-C: Workout Conflict Alert
- **Gap**: No ongoing session detection
- **Files**: `active_workout_provider.dart`, workout overlay screens
- **Work**: Add session conflict detection (check for active session before starting new), show resume/new/cancel dialog
- **Verification**: Starting workout while one active shows conflict dialog

### P1-D: Pop-to-Root on Tab Double-Tap
- **Gap**: `onDoubleTapTab` stub exists but no implementation
- **Files**: `ziro_shell.dart`, `app_router.dart`
- **Work**: Wire double-tap callback to navigate to tab root route via GoRouter
- **Verification**: Double-tap tab pops to root navigation

### P1-E: What's New on App Launch
- **Gap**: No version-based release notes
- **Files**: New `whats_new_screen.dart`, shell entry point
- **Work**: Create `WhatsNewScreen`, version tracking in SharedPreferences, show on app launch after update
- **Verification**: App shows release notes after update

---

## Phase 2: Client Management (8 items)

### P2-A: Client Detail — Active Program Display + Cancel
- **Gap**: Missing program progress card
- **Files**: `client_detail_screen.dart`, new `active_program_widget.dart`
- **Work**: Add program widget showing progress bar, cancel program button with destructive confirmation
- **Verification**: Client with program sees progress, can cancel

### P2-B: Client Detail — Active Package Display
- **Gap**: Missing package card with sessions remaining
- **Files**: `client_detail_screen.dart`
- **Work**: Add package card with sessions remaining count, start session button
- **Verification**: Client with package sees remaining sessions

### P2-C: Client Detail — Request Check-in Button
- **Gap**: Missing check-in request action
- **Files**: `client_detail_screen.dart`
- **Work**: Add "Request Check-in" button with success/error handling
- **Verification**: Tapping sends check-in request notification

### P2-D: Client Detail — Stats/Streak Summary
- **Gap**: No quick stats (workouts count, streak, last session)
- **Files**: `client_detail_screen.dart`
- **Work**: Add computed stats section above activity
- **Verification**: Stats display with real data

### P2-E: Client Analytics Trainer View
- **Gap**: No trainer-facing analytics screen
- **Files**: New `trainer_client_analytics_screen.dart`, provider, router route
- **Work**: Build screen using existing `ClientAnalytics`/`ClientProgress` models: volume chart, muscle distribution, PRs, heatmap, date range picker
- **Verification**: Trainer sees full analytics for any client

### P2-F: QR Code In-Person Add Client
- **Gap**: No QR scan flow
- **Files**: New QR generation/scanner, `add_client_sheet.dart`
- **Work**: Generate QR with trainer profile URL, add scan screen, handle deep link connection
- **Verification**: Scanning QR connects client to trainer

### P2-G: Phone Invite + Caloric Intake + Missing Body Parts
- **Gap**: Email-only invite, missing measurement types
- **Files**: `invite_client_screen.dart`, `measurements_screen.dart`, `measurement_constants.dart`
- **Work**: Add phone field to invite, add caloric intake type, add upper/lower abs body parts
- **Verification**: Phone invite works, new measurement types appear

### P2-H: Weight Validation on Measurement Entry
- **Gap**: No smart warnings for unusual weight changes
- **Files**: `add_measurement_sheet.dart`
- **Work**: Compare to last entry, show confirmation dialog for >2kg change, hard warning for >5kg
- **Verification**: Entering extreme weight shows appropriate warning

### P2-I: Client List Polish (Section Headers + Skeleton)
- **Gap**: Flat list, spinner loading
- **Files**: `client_list_screen.dart`
- **Work**: Add pending/active section headers, replace spinner with skeleton shimmer
- **Verification**: List shows sections with skeleton during load

---

## Phase 3: Progress & Analytics (7 items)

### P3-A: Date Range Picker on Analytics
- **Gap**: Hardcoded 30 days
- **Files**: `progress_screen.dart`, `analytics_widget_config.dart`
- **Work**: Add segmented period selector (7D/30D/3M/6M/1Y/ALL), wire to API calls
- **Verification**: Changing period reloads all widget data

### P3-B: Trend Badges on Widget Containers
- **Gap**: Trend data not passed to containers
- **Files**: `progress_screen.dart`, `analytics_widget_container.dart`
- **Work**: Compute and pass `volumeTrend`/`consistencyTrend`/`frequencyTrend` to `AnalyticsWidgetContainer`
- **Verification**: Widget cards show green/red trend badges

### P3-C: Auto-Refresh on Events
- **Gap**: No reactive refresh after workout/check-in
- **Files**: `progress_screen.dart`
- **Work**: Add event bus listener (workout complete, check-in submitted) → refresh analytics
- **Verification**: Completing workout auto-refreshes analytics screen

### P3-D: Multi-Goal Display in Widget
- **Gap**: Only shows first goal
- **Files**: `progress_screen.dart`, `fitness_goal_card.dart`
- **Work**: Render all active goals inside goal widget with progress bars
- **Verification**: Multiple goals all visible with progress

### P3-E: Circular Consistency Gauge
- **Gap**: Linear bar → circular gauge (optional)
- **Files**: `consistency_card.dart`
- **Work**: Add circular gauge as alternative display mode
- **Verification**: Consistency displays as circular ring

### P3-F: Body Fat Display from Check-in Data
- **Gap**: Body fat exists in model, not rendered
- **Files**: Analytics widgets
- **Work**: Render `ClientProgress.bodyFat` in weight chart or dedicated widget
- **Verification**: Body fat appears in analytics

### P3-G: Accurate Trend Calculation
- **Gap**: Half-split fallback with hardcoded 0.1
- **Files**: `progress_screen.dart`
- **Work**: Implement period-over-period trend calculation (current vs previous period, not half-split)
- **Verification**: Trends reflect actual data changes

---

## Phase 4: Trainer Profile & Branding (7 items)

### P4-A: Schedule Tab in Public Profile
- **Gap**: No availability display for clients
- **Files**: `public_trainer_profile_screen.dart`
- **Work**: Add 5th tab rendering working hours (day selector + time slot chips)
- **Verification**: Client sees trainer's weekly availability

### P4-B: Custom Program Request Flow
- **Gap**: No 3-step wizard
- **Files**: New `custom_program_request_screen.dart`, provider
- **Work**: Build 3-step wizard (goals → duration → confirm), API integration
- **Verification**: Client can submit custom program request

### P4-C: External Links in Public Profile
- **Gap**: Social links only, external links hidden
- **Files**: `public_trainer_profile_screen.dart`
- **Work**: Add external links section to About tab
- **Verification**: External links appear in public profile

### P4-D: Phone + Specialties in Profile Settings
- **Gap**: Missing phone field, specialties not exposed
- **Files**: `profile_settings_screen.dart`, `edit_profile_text_screen.dart`, `TextContent` model
- **Work**: Add phone TextField, add chip-based specialties editor
- **Verification**: Phone and specialties editable and persisted

### P4-E: Edit Testimonials + Client Name in Transformation Photos
- **Gap**: No edit for testimonials, missing client name field in photos
- **Files**: `trainer_testimonials_screen.dart`, `trainer_transformation_photos_screen.dart`
- **Work**: Add edit testimonial dialog, add clientName field to photo upload
- **Verification**: Testimonials editable, photos have client name

### P4-F: Stripe/Payouts in Storefront + Revenue Screen
- **Gap**: Missing Stripe connection status, revenue analytics
- **Files**: `storefront_settings_screen.dart`, new `revenue_screen.dart`
- **Work**: Add Stripe connection card with status, build revenue screen
- **Verification**: Stripe status visible, revenue data loads

---

## Phase 5: Shared Widget Infrastructure (6 items)

### P5-A: Standalone ZiroAvatar
- **Gap**: Avatar logic embedded in parent widgets
- **Files**: New `ziro_avatar.dart` in shared/widgets, refactor consumers
- **Work**: Extract avatar widget with network image, initials fallback, deterministic color, configurable sizes
- **Verification**: All avatar usages consistent, no code duplication

### P5-B: PrimaryButton / PremiumButton
- **Gap**: Reliance on theme defaults, no dedicated button classes
- **Files**: New button widgets in shared/widgets
- **Work**: Create `PrimaryButton`, `SecondaryButton`, `PremiumButton` matching iOS style
- **Verification**: Buttons match iOS visual design

### P5-C: Badge Widget
- **Gap**: No reusable badge/pill
- **Files**: New `badge.dart` in shared/widgets
- **Work**: Create generic badge with color variants, supports status/trend/session-type
- **Verification**: Badges render with correct colors in all contexts

### P5-D: MetricCard
- **Gap**: No reusable metric display card
- **Files**: New `metric_card.dart` in shared/widgets
- **Work**: Create card with icon + value + unit + trend arrow/percentage
- **Verification**: Metric card renders in analytics and dashboard contexts

### P5-E: DashboardSkeleton + AnalyticsWidgetContainer
- **Gap**: Missing composite skeleton, analytics wrapper
- **Files**: New skeleton and container widgets
- **Work**: Build dashboard composite skeleton, generic widget container with menu
- **Verification**: Loading states match iOS, widget containers have consistent chrome

### P5-F: EmptyStateView + SessionCard
- **Gap**: Missing standalone empty state and session card
- **Files**: New widgets in shared/widgets and features/calendar respectively
- **Work**: Extract empty state from ZiroDataView, build session card with status strip + badges
- **Verification**: Empty states consistent, session cards render correctly

---

## Phase 6: Sync & Core (5 items)

### P6-A: Ghost Session Recovery
- **Gap**: No session recovery on app restart
- **Files**: `active_workout_provider.dart`, app initialization flow
- **Work**: Add `checkForActiveSession()` on app start, scan calendar/DB for in-progress sessions
- **Verification**: Restarting app during active session shows resume prompt

### P6-B: Custom Exercise Creation with Temp IDs
- **Gap**: No additive exercise flow
- **Files**: Exercise builder flow, sync engine
- **Work**: Implement local temp ID → server create → ID swap pattern
- **Verification**: Custom exercises created offline sync correctly

### P6-C: Self-Healing in Sync Engine
- **Gap**: Queue can stall on orphaned items
- **Files**: `sync_engine.dart`
- **Work**: Add 404 handling to discard orphaned items, add max-retry threshold with auto-discard
- **Verification**: Stalled queue items auto-resolve after max retries

### P6-D: Image Caching
- **Gap**: No in-memory image cache
- **Files**: `cached_async_image.dart` or new `image_cache_manager.dart`
- **Work**: Add in-memory image cache (NSCache equivalent) with size limits
- **Verification**: Images load from cache on second render

### P6-E: Schema Migrations
- **Gap**: Schema version 1, no migrations
- **Files**: `app_database.dart`
- **Work**: Add Drift migration infrastructure (migration versioning, `_migrationSteps`)
- **Verification**: Schema version bumps run migrations correctly

---

## Phase 7: Auth Polish + Remaining Low Priority (14 items)

### P7-A through P7-N (batch):
- Google Sign In embedded session
- Onboarding language selection step
- Trainer service radius + MapKit
- "Session expired" user messaging
- Privacy-preserving forgot password text
- Flexible role detection (coach/instructor/staff/owner)
- JWT expiry pre-check
- Mode-specific server logout
- Pro status auto-management
- Contact support form in settings
- Workout session reset on mode switch
- Syncing overlay during save
- Client list caching
- Client list optimistic add

---

## Dependency Graph

```
Phase 0 (Auth) ──────► Phase 7 (Auth Polish)
       │
       ▼
Phase 1 (Navigation) ──► All screen work (Phases 2,3,4)
       │
       ├─────► Phase 2 (Client Management)
       ├─────► Phase 3 (Progress & Analytics)
       └─────► Phase 4 (Trainer Profile)
       
Phase 5 (Shared Widgets) ──► Enables Phase 2,3,4 polish

Phase 6 (Sync) ──► Independent, can run parallel to 1-5

Phase 7 (Polish) ──► After Phase 0 completes
```

## Parallel Execution Model

| Wave | Phase(s) | Parallel Groups | Est. Effort |
|------|---------|----------------|-------------|
| 1 | P0-A, P0-B | Auth critical (serial dependency: multi-account depends on apple sign-in) | 3-4 days |
| 2 | P0-C, P0-D, P0-E | Can run parallel (no cross-dependency) | 2-3 days |
| 3 | P1-A through P1-E | P1-B depends on P1-A; rest parallel | 2-3 days |
| 4 | P2-A through P2-D, P6-A, P6-B | P2-A/P2-B shared screen; P6 independent | 3-4 days |
| 5 | P2-E, P2-F, P2-G, P5-A, P5-B | All independent | 3-4 days |
| 6 | P3-A through P3-D, P4-A, P4-B, P5-C | All independent | 3-4 days |
| 7 | P3-E through P3-G, P4-C, P4-D, P5-D | All independent | 2-3 days |
| 8 | P4-E, P4-F, P5-E, P5-F, P6-C, P6-D | All independent | 2-3 days |
| 9 | P6-E, P7-A through P7-N | Low priority batch | 3-5 days |

**Total estimated effort**: 25-35 days (parallelized across subagents)
**Dependency risk**: Phase 0 must complete before any downstream work is meaningful

## Verification Gate

Every item must pass:
1. `flutter analyze` — zero errors
2. Manual comparison against iOS reference
3. `lsp_diagnostics` clean on all changed files

## Files Most Impacted (High Touch)
- `auth_provider.dart` — 5+ modifications
- `client_detail_screen.dart` — 4 modifications
- `progress_screen.dart` — 3 modifications
- `ziro_shell.dart` / `ziro_tab_bar.dart` — 2 modifications
- `public_trainer_profile_screen.dart` — 2 modifications
- `account_storage.dart` — 2 modifications
- `app_router.dart` — 2 modifications
- New files: ~15-20 across all phases
