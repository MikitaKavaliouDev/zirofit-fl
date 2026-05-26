# iOS → Flutter Full Parity Analysis

**Generated:** 2026-05-26
**iOS App:** `V:\Ziro-Fit`
**Flutter App:** `V:\zirofit-fl`
**Scope:** Complete reverse-engineering comparison of all flows, UI, API, navigation, bottom sheets, tabs, routes.

---

## Table of Contents

1. [Architecture Comparison](#1-architecture-comparison)
2. [Navigation & Routing](#2-navigation--routing)
3. [Tab Bar & Mode System](#3-tab-bar--mode-system)
4. [Feature-by-Feature Parity Matrix](#4-feature-by-feature-parity-matrix)
5. [UI Components & Widgets Parity](#5-ui-components--widgets-parity)
6. [Bottom Sheets & Modals](#6-bottom-sheets--modals)
7. [API Endpoint Parity](#7-api-endpoint-parity)
8. [Data Models Comparison](#8-data-models-comparison)
9. [Managers & Services](#9-managers--services)
10. [Workout Flow Deep Dive](#10-workout-flow-deep-dive)
11. [Critical Gaps (iOS has, Flutter doesn't)](#11-critical-gaps)
12. [Minor Gaps & Nuances](#12-minor-gaps--nuances)
13. [Recommended Migration Order](#13-recommended-migration-order)

---

## 1. Architecture Comparison

| Dimension | iOS (SwiftUI) | Flutter |
|---|---|---|
| **Pattern** | MVVM (ObservableObject + @Published) | Riverpod (providers + code generation) |
| **Navigation** | Custom MainTabView + opacity-based tab switching via AppState.selectedTab | GoRouter with ShellRoute for role-based shells |
| **State Container** | AppState @Published ObservableObject + UserDefaults @AppStorage | Riverpod providers + SharedPreferences |
| **API Client** | Singleton APIService with URLSession, auto-refresh, multi-mode tokens | Dio (presumably) with interceptors |
| **Caching** | CacheManager (custom, UserDefaults/File-based) | Drift local DB (offline-first) |
| **Auth** | Supabase tokens in KeychainHelper + custom refresh | supabase_flutter SDK + flutter_secure_storage |
| **Multi-Account** | Dual token slots (trainer/personal) in Keychain, dual URLSession isolation | Single auth — role-based routing |
| **Deep Links** | NotificationCenter-based dispatch (auth, stripe, events) | GoRouter deep link handling |
| **Models** | Manual Codable with multi-key fallback decoding | Freezed @freezed + json_serializable |
| **Theme** | ThemeManager + Color.theme extensions | AppTheme light/dark ThemeData |
| **Language** | LanguageManager with Localizable.xcstrings | Flutter intl/localization |
| **Workout State** | WorkoutManager (global @MainActor class), RestTimerManager, WorkoutTimer | Providers: active_workout_provider, rest_timer_manager_provider, workout_timer_provider |
| **Sync** | SyncManager (network monitoring + sync) | data/sync/ offline sync engine + Drift |

### Key Architectural Differences

1. **iOS uses NSNotificationCenter for cross-component communication** (session finish → dashboard refresh, mode switch → workout reset). Flutter should use Riverpod ref.invalidate or event buses.

2. **iOS AppState is a centralized global state holder** with role + tab + feature flags. Flutter distributes this across providers.

3. **iOS has dual-account support** (trainer + personal tokens stored simultaneously, switch with AppState.currentMode). Flutter has single auth with role redirect.

4. **iOS pre-fetches data on login** (dashboard, clients, calendar, programs, analytics). Flutter should implement equivalent background pre-fetching.

---

## 2. Navigation & Routing

### iOS Navigation (MainTabView)

```
ContentView (Root)
├── SplashScreen (authViewModel.isRestoringSession)
├── LoginView (!authenticated)
├── OnboardingView (role == "pending")
└── MainTabView (authenticated)
    ├── (Trainer Mode)
    │   ├── CalendarView (tab: calendar)
    │   ├── TrainerProgramsView (tab: programs)
    │   ├── DashboardView (tab: home) [default]
    │   ├── ClientsView (tab: clients)
    │   └── MoreView (tab: more)
    ├── (Personal Mode)
    │   ├── PersonalExploreView (tab: programs)
    │   ├── WorkoutHistoryView (tab: clients)
    │   ├── PersonalHomeView (tab: home) [default]
    │   ├── PersonalAnalyticsView (tab: analytics)
    │   └── MoreView (tab: more)
    ├── WorkoutMiniPlayer (overlay when minimized)
    └── WorkoutSessionView (full screen when active)
```

iOS uses **opacity-based view stacking** within MainTabView — all views are pre-rendered, only toggled via `opacity` + `allowsHitTesting`. Tab switching is instant. NavigationView/NavigationStack used within each tab for push navigation.

### Flutter Navigation (GoRouter)

```
GoRouter
├── /auth/* (public)
│   ├── /auth/login
│   ├── /auth/register
│   ├── /auth/forgot-password
│   ├── /auth/callback
│   ├── /auth/email-verification
│   ├── /auth/update-password
│   └── /auth/reset-password
├── /onboarding
│   └── /onboarding/education
├── /trainer/* (ShellRoute → ZiroShell)
│   ├── /trainer/dashboard [default]
│   ├── /trainer/clients → /invite, /:id → /sessions, /live-session, /analytics
│   ├── /trainer/calendar
│   ├── /trainer/bookings
│   ├── /trainer/check-ins
│   ├── /trainer/programs → /create, /create-template, /:id
│   ├── /trainer/exercises → /custom
│   ├── /trainer/notifications
│   ├── /trainer/sharing-requests
│   ├── /trainer/revenue
│   ├── /trainer/chat → /:conversationId
│   ├── /trainer/profile → /services, /packages, /testimonials, etc.
│   ├── /trainer/assessments
│   ├── /trainer/recipes → /create, /:id
│   ├── /trainer/resources → /create
│   ├── /trainer/settings → /payouts
│   └── /trainer/more
├── /client/* (ShellRoute → ZiroShell)
│   ├── /client/dashboard [default]
│   ├── /client/daily-targets
│   ├── /client/workout → /history
│   ├── /client/progress
│   ├── /client/events/:id
│   ├── /client/check-in → /history
│   ├── /client/notifications
│   ├── /client/settings
│   ├── /client/programs → /create, /active, /:id, /templates/:templateId
│   ├── /client/explore → /discovery, /map
│   ├── /client/chat → /:conversationId
│   ├── /client/bookings/:trainerId
│   ├── /client/trainer
│   └── /client/more
├── /admin/* (ShellRoute → AdminShell)
│   ├── /admin/dashboard
│   ├── /admin/events
│   ├── /admin/blog
│   ├── /admin/tickets
│   ├── /admin/users
│   ├── /admin/errors
│   └── /admin/feature-toggles
├── /standalone routes
│   ├── /exercises
│   ├── /ai-coach
│   ├── /delete-account
│   ├── /settings/* (multiple sub-routes)
│   ├── /events/:id
│   ├── /workout/:id
│   ├── /movement/:exerciseName
│   ├── /chat → /:conversationId
│   ├── /notifications
│   ├── /blog → /:slug
│   ├── /whats-new
│   └── /public-trainer/:id
```

### Navigation Discrepancies

| iOS Flow | Flutter Status | Notes |
|---|---|---|
| Tab-based instant switching (opacity stack) | ✅ ZiroShell with bottom nav | Different mechanism — Flutter uses GoRouter ShellRoute which rebuilds |
| Push nav within tabs (NavigationStack) | ✅ GoRouter sub-routes | Equivalent |
| Deep links (auth, stripe, events) | ✅ Auth callback route, needs stripe/event handling | Flutter has /auth/callback but needs stripe/event deep links |
| WorkoutMiniPlayer overlay (tab bar visible) | ✅ Workout mini player implemented in workout | Need to verify it overlays properly |
| WorkoutSessionView full-screen (tab bar hidden) | ✅ EnhancedActiveWorkoutScreen | Flutter has this |
| Sheet-based login when switching to unauthenticated mode | ❌ Not implemented | iOS shows LoginView as .sheet when switching modes |
| What's New auto-present on version change | ✅ Via GoRouter redirect | Implemented in Flutter router |
| Pop-to-root on tab re-tap (NotificationCenter "PopToRoot") | ❌ Not implemented | iOS posts notification, Flutter needs equivalent |
| Cross-mode notification alerts | ❌ Not implemented | iOS has showCrossModeAlert in AppState |

---

## 3. Tab Bar & Mode System

### iOS Tab Configuration

**Trainer tabs:** Calendar, Programs, Home (center), Clients, More
**Personal tabs:** Explore, Workouts, Home (center), Analytics, More

| Aspect | iOS (CustomTabBar) | Flutter (ZiroShell) |
|---|---|---|
| **Trainer tabs** | calendar, programs, home, clients, more | ✅ Dashboard, Programs, Clients, etc. via config |
| **Personal tabs** | programs(explore), clients(workouts), home, analytics, more | ✅ Similar structure |
| **Tab icons** | SF Symbols per role | ✅ Custom icons |
| **Mode selector** | Drag up/down on tab bar + tap to expand | ❌ Missing — AppMode toggle in CustomAppModeScreen |
| **Mode switch animation** | Spring animation + gradient border flash | ❌ No animation |
| **Notification badge** | Unread count per tab (home tab) | ✅ Likely in ZiroShell |
| **Admin role** | Not in tab bar (admin tab doesn't exist) | ✅ AdminShell with separate nav |
| **Swipe-to-change-mode** | Drag gesture with 40% threshold | ❌ Not implemented |
| **Custom mode enable/disable** | @AppStorage isCustomModeEnabled toggle in More | ✅ In CustomAppModeScreen (needs verification) |

### Critical Gap: Mode Selector & Swipe
iOS has a rich mode selector that:
- Expands from tab bar on drag-up or tap
- Shows Professional/Personal cards with icons and notification counts
- Supports long-swipe toggle (40% screen threshold)
- Has spring animations and gradient border flash
- Is togglable via "Custom App Mode" in More

Flutter has a `CustomAppModeScreen` but the actual **mode selector UI** and **swipe gesture** on the tab bar are missing.

---

## 4. Feature-by-Feature Parity Matrix

### 4.1 Auth & Onboarding

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Email login | ✅ LoginView | ✅ LoginScreen | Same API |
| Email signup | ✅ SignupView | ✅ RegisterScreen | Same API |
| Google OAuth | ✅ GoogleSignInHelper | ✅ Auth callback | Flutter uses supabase_flutter |
| Apple OAuth | ✅ AppleSignInHelper | ✅ | Flutter uses sign_in_with_apple |
| Forgot password | ✅ ForgotPasswordView | ✅ ForgotPasswordScreen | Same API |
| Update password | ✅ UpdatePasswordView | ✅ UpdatePasswordScreen | Same API |
| Email verification screen | ✅ (showEmailConfirmation) | ✅ EmailVerificationScreen | Both poll |
| Verification polling | ✅ Timer 5s | ✅ Needs verification | |
| Resend verification | ✅ | ✅ | Same API |
| Deep link auth | ✅ handleAuthDeepLink | ✅ AuthCallbackScreen | |
| Magic link login | ✅ via deep link tokens | ✅ | |
| Onboarding wizard | ✅ OnboardingView (8-step) | ✅ OnboardingScreen | Both multi-step |
| Educational onboarding | ✅ EducationalOnboardingView | ✅ | Flutter has it |
| Role selection | ✅ During onboarding | ✅ During onboarding | |
| Account switching (modes) | ✅ AppState.currentMode | ✅ CustomAppModeScreen | Flutter mode switch is in settings, not bottom nav |
| Delete account | ✅ | ✅ DeleteAccountScreen | Registered in router |
| Password reset flow | ✅ showUpdatePasswordSheet | ✅ ResetPasswordScreen | |

### 4.2 Dashboard

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Trainer Dashboard | ✅ DashboardView | ✅ TrainerDashboardScreen | Both use /api/mobile/home |
| Quick stats (clients, revenue, bookings, check-ins) | ✅ | ✅ | Same fields |
| Upcoming sessions | ✅ | ✅ | Next 3 |
| Dashboard insights | ✅ fetchInsights | ✅ | |
| Mobile home | ✅ fetchMobileHome | ✅ | Same endpoint |
| Client Dashboard | ✅ ClientHomeViewModel → PersonalHomeView | ✅ ClientDashboardScreen | |
| Active program widget | ✅ ActiveProgramWidget | ✅ | Flutter has it |
| Active routine widget | ✅ ActiveRoutineWidget | ❌ Not implemented | iOS-specific widget |
| Daily habits widget | ✅ | ✅ | |
| Trainer profile card | ✅ | ✅ MyTrainerScreen | |
| Quick actions | ✅ (start workout, check-in, AI coach) | ✅ | Bottom nav items |
| Weight quick-log | ✅ from PersonalHomeView | ✅ | Flutter has it |
| Daily targets | ✅ DailyTargetCard | ✅ DailyTargetScreen | |
| Coach banner | ✅ dismissable banner | ❌ Missing | iOS has "Find a Coach" CTA banner |
| Check-in banner | ✅ dismissable banner | ❌ Missing | |
| Onboarding checklist | ❌ (trainer) | ❌ | Missing in both v Next.js |
| Education overlay (first-time) | ✅ EducationalOnboardingView | ✅ EducationalOnboardingScreen | |

### 4.3 Workout Tracking

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Start workout from template | ✅ WorkoutManager.startSession | ✅ EnhancedActiveWorkoutScreen | Same flow |
| Start from booking | ✅ | ✅ | |
| Start ad-hoc | ✅ | ✅ | |
| Exercise logging (sets/reps/weight) | ✅ WorkoutSetRow | ✅ EnhancedWorkoutSetRow | |
| Superset support | ✅ | ✅ SupersetGroupIndicator | |
| RPE picker | ✅ RPEPickerOverlay | ✅ RPEPickerOverlay | Flutter has it |
| Plate calculator | ✅ PlateCalculatorOverlay | ✅ PlateCalculatorOverlay | |
| Rest timer | ✅ RestTimerSheet + RestTimerProgressBar | ✅ RestTimerSheet + RestTimerProgressBar | |
| Voice input for logging | ✅ VoiceLogManager → VoiceInputOverlay | ✅ VoiceInputOverlay + VoiceCorrectionPicker | |
| Voice feedback (TTS) | ✅ VoiceFeedbackManager | ✅ VoiceFeedbackService | |
| YouTube exercise videos | ✅ YouTubePlayerView | ✅ YoutubeSheetView | |
| Workout timer | ✅ WorkoutTimer (1s) | ✅ WorkoutTimerProvider | |
| Finish workout | ✅ FinishWorkoutAlert | ✅ FinishWorkoutDialog | |
| Cancel workout | ✅ | ✅ | |
| Workout summary | ✅ (in WorkoutSessionView) | ✅ WorkoutSummaryScreen | |
| Save as template | ✅ | ✅ SaveTemplateDialog | |
| Session comments | ✅ | ✅ | |
| Workout history | ✅ WorkoutHistoryView | ✅ WorkoutHistoryScreen | |
| Workout calendar sheet | ✅ WorkoutCalendarSheet | ✅ WorkoutCalendarSheet | |
| Live Activities (iOS) | ✅ LiveActivityManager | ✅ LiveActivityService | iOS only feature |
| Sync workout indicator | ✅ "Syncing workout..." overlay | ❌ Missing | iOS shows overlay during sync |
| Long session warning (4h) | ✅ Alert at 2h/4h | ❌ Missing | |
| Active session conflict | ✅ Resume/End alert | ❌ Missing | iOS checks for existing session on start |
| Workout mini player | ✅ WorkoutMiniPlayer (overlay) | ✅ WorkoutMiniPlayer | Flutter has equivalent |
| AI-coached workout (voice) | ❌ Missing from iOS too | ❌ Missing | Not in either mobile app |
| Audio cue for announcements | ✅ VoiceCoachManager | ❌ Missing | iOS has TTS coach |
| Numeric keyboard | ✅ WorkoutNumericKeyboard | ✅ WorkoutNumericKeyboard | |

### 4.4 Client Management (Trainer)

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Client list | ✅ ClientsView | ✅ ClientListScreen | |
| Client search | ✅ | ✅ | |
| Client detail (tabs) | ✅ ClientDetailView | ✅ ClientDetailScreen | |
| Programs tab | ✅ | ✅ | |
| Sessions tab | ✅ ClientHistoryView | ✅ ClientHistoryScreen | |
| Measurements | ✅ MeasurementsView | ✅ (in client detail) | |
| Progress photos | ✅ | ✅ | |
| Assessments | ✅ AssessmentsView | ✅ TrainerAssessmentsScreen | |
| Exercise logs | ✅ | ✅ | |
| Client invite | ✅ InviteClientView | ✅ InviteClientScreen | |
| Link request | ✅ | ✅ | |
| Client packages | ✅ ClientPackagesView | ✅ | |
| Client analytics | ✅ TrainerClientAnalyticsView | ✅ ClientAnalyticsScreen | |
| Live session monitor | ✅ | ✅ LiveSessionMonitorScreen | Flutter has route |
| Sharing requests | ❌ | ✅ SharingRequestsScreen | Flutter has, iOS doesn't |
| Client insights (AI) | ❌ | ❌ | Missing in both mobile |
| Add client | ✅ AddClientView | ✅ Part of ClientListScreen | |

### 4.5 Trainer Profile

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Profile core info | ✅ ProfileSettingsView | ✅ TrainerProfileScreen | |
| Avatar/banner upload | ✅ | ✅ | |
| About/text content | ✅ | ✅ EditProfileTextScreen | |
| Services CRUD | ✅ | ✅ TrainerServicesScreen | |
| Packages CRUD | ✅ PackageManagementView | ✅ TrainerPackagesScreen | |
| Testimonials CRUD | ✅ | ✅ TrainerTestimonialsScreen | |
| Benefits CRUD | ✅ | ✅ | |
| Social links | ✅ | ✅ TrainerSocialLinksScreen | |
| External links | ✅ | ✅ TrainerExternalLinksScreen | |
| Transformation photos | ✅ | ✅ TrainerTransformationPhotosScreen | |
| Custom exercises | ✅ CustomExercisesView | ✅ CustomExercisesScreen | |
| Availability | ✅ WorkingHoursView | ✅ | |
| Assessments | ✅ AssessmentsView | ✅ TrainerAssessmentsScreen | |
| Storefront settings | ✅ StorefrontSettingsView | ✅ StorefrontSettingsScreen | |
| Trainer subscription | ✅ TrainerSubscriptionView | ✅ SubscriptionSettingsScreen | |
| Payouts | ✅ PayoutsView | ✅ PayoutsSettingsScreen | |
| Revenue | ✅ RevenueView | ✅ RevenueScreen | |
| Marketplace manager | ✅ MarketplaceManagerView | ✅ (via More) | |
| QR Code (Business Card) | ✅ QRCodeGenerator | ❌ Missing | iOS generates trainer QR code |
| Profile completion score | ✅ via completionPercentage | ✅ | |
| Branding | ✅ uploadBranding | ✅ | |

### 4.6 Programs & Templates

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Program list | ✅ TrainerProgramsView | ✅ ProgramsListScreen | |
| Create program | ✅ CreateProgramView | ✅ CreateProgramScreen | |
| Program detail | ✅ ProgramDetailView | ✅ ProgramDetailScreen | |
| Template list | ✅ (in ProgramsView) | ✅ | |
| Template detail | ✅ TemplateDetailView | ✅ (in router) | |
| Create template | ✅ CreateTemplateView | ✅ CreateTemplateScreen | |
| Exercise editor | ✅ ExerciseEditorCardView | ✅ (in CreateTemplateScreen) | |
| Rest steps | ✅ | ✅ | |
| Superset groups | ✅ | ✅ | |
| Copy system template | ✅ | ✅ | |
| AI program generation | ✅ | ✅ ClientCreateProgramScreen | |
| Assign program | ✅ | ✅ | |
| Active program view (client) | ✅ ActiveProgramWidget | ✅ ClientActiveProgramScreen | |
| Visual timeline builder | ✅ VisualTimelineBoardView + VisualTimelineBuilderView | ❌ Missing | iOS has drag-drop timeline for programs |
| Template picker | ✅ TemplatePickerView | ✅ | For calendar session creation |
| Program builder choice | ✅ ProgramBuilderChoiceView (Standard vs Visual) | ❌ Missing | iOS offers choice between builders |
| Template library | ✅ | ✅ | |

### 4.7 Calendar & Scheduling

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Calendar view | ✅ CalendarView | ✅ CalendarScreen | |
| Create planned session | ✅ | ✅ | |
| Update/delete session | ✅ | ✅ | |
| Send reminder | ✅ | ✅ | |
| Clients summary sidebar | ✅ (in CalendarView) | ❌ Missing | iOS shows client list sidebar |
| Session creation data | ✅ (clients + templates) | ✅ | |
| Recurrence | ✅ | ✅ | |
| Conflict detection | ✅ | ✅ | |
| Calendar filters | ✅ CalendarFiltersView | ✅ | |
| Calendar date strip | ✅ CalendarDateStrip | ✅ | |
| Apple Calendar sync | ✅ AppleCalendarManager | ❌ Not applicable | Platform-specific |

### 4.8 Check-Ins

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Submit check-in (client) | ✅ ClientCheckInView (3-step wizard) | ✅ CheckInScreen | |
| Step 1: Metrics | ✅ weight, waist, sleep, energy, stress, hunger, digestion | ✅ | |
| Step 2: Nutrition | ✅ nutrition compliance | ✅ | |
| Step 3: Photos | ✅ progress photos | ✅ | |
| Check-in history (client) | ✅ CheckInHistoryView | ✅ CheckInHistoryScreen | |
| Check-in config | ✅ | ✅ | |
| Trainer check-ins list | ✅ CheckInsView | ✅ TrainerCheckInsScreen | |
| Pending tab | ✅ | ✅ | |
| Check-in detail | ✅ CheckInDetailView | ✅ (needs verification) | |
| Review check-in | ✅ (response text + feedback) | ✅ | |
| Trends (last 4) | ✅ | ✅ | |

### 4.9 Explore / Discovery (Client)

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Explore screen | ✅ PersonalExploreView | ✅ ExploreScreen | |
| Featured trainers | ✅ | ✅ | |
| Featured events | ✅ | ✅ | |
| Browse by category | ✅ | ✅ | |
| Location filter / City picker | ✅ | ✅ | |
| Trainer search | ✅ TrainerDiscoveryView | ✅ TrainerDiscoveryScreen | |
| Trainer map | ✅ TrainerMapView | ✅ TrainerMapScreen | |
| Public trainer profile | ✅ PublicTrainerProfileView | ✅ PublicTrainerProfileScreen | |
| Trainer filters (rating, price) | ✅ | ✅ | |
| Trainer packages (public) | ✅ | ✅ | |
| Trainer testimonials (public) | ✅ | ✅ | |
| Trainer social links | ✅ | ✅ | |
| Trainer transformation photos | ✅ | ✅ | |
| Marketplace | ✅ MarketplaceView (list/map toggle) | ❌ Missing | iOS has a combined event/trainer marketplace |
| Event detail | ✅ EventDetailView | ✅ ClientEventDetailScreen | |
| Events list | ✅ EventsListView | ✅ (in ExploreScreen) | |
| Join free event | ✅ | ✅ | |
| Purchase event ticket | ✅ | ✅ | |
| Event map (map view) | ✅ MapKit in Marketplace | ❌ Missing | iOS shows map for events |
| Trainer finding onboarding | ✅ TrainerFindingOnboardingView | ❌ Missing | iOS has a flow for first-time client trainer search |
| Empty states | ✅ ExploreEmptyEventsView, ExploreEmptyTrainersView | ✅ | |

### 4.10 Bookings

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Create booking (client) | ✅ ClientBookingView | ✅ ClientBookingScreen | |
| Booking list (trainer) | ✅ BookingManagementView | ✅ BookingManagementScreen | |
| Confirm booking | ✅ | ✅ | |
| Decline booking | ✅ | ✅ | |
| Booking window | ✅ BookingWindowView | ✅ | |
| Client event bookings | ✅ | ✅ | |
| Cancel booking | ✅ | ✅ | |
| Working hours | ✅ WorkingHoursView | ✅ | |

### 4.11 Chat

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Conversation list | ✅ (derived from clients) | ✅ ConversationsListScreen | |
| Message history | ✅ | ✅ ChatScreen | |
| Send message | ✅ | ✅ | |
| Media in chat | ❌ | ❌ | Missing in both mobile |
| AI coach chat | ❌ | ❌ | Missing in both mobile |
| System messages | ✅ | ✅ | |
| Image/video in chat | ❌ | ❌ | Not implemented |

### 4.12 Notifications

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Notification list | ✅ NotificationsView | ✅ NotificationsScreen | |
| Mark read | ✅ | ✅ | |
| Push token registration | ✅ | ✅ | |
| Accept/decline link requests | ✅ | ✅ | |
| Notification routing | ✅ (role-aware) | ✅ | |
| Badge count | ✅ on tab bar | ✅ | |
| Cross-mode notifications | ✅ showCrossModeAlert | ❌ Missing | |

### 4.13 More / Settings

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Profile card | ✅ (avatar + name + email + PRO/PERSONAL badge) | ✅ | |
| QR Code (trainer) | ✅ TrainerQRCodeView | ❌ Missing | |
| Appearance | ✅ AppearanceSettingsView | ✅ AppearanceSettingsScreen | |
| AI Coach Settings / Voice | ✅ VoiceSettingsView | ✅ VoiceCoachSettingsScreen | |
| Language | ✅ | ✅ LanguageSettingsScreen | |
| Notifications | ✅ NotificationSettingsView | ✅ NotificationSettingsScreen | |
| Permissions | ✅ PermissionsSettingsView | ✅ PermissionsSettingsScreen | |
| Data & Privacy | ✅ DataPrivacyView | ✅ DataSharingScreen + PrivacySecuritySettingsScreen | |
| My Packages (client) | ✅ ClientPackagesView | ✅ | |
| Purchase History | ✅ TransactionHistoryView | ❌ Missing | |
| Storefront Settings (trainer) | ✅ StorefrontSettingsView | ✅ StorefrontSettingsScreen | |
| Subscription & Billing | ✅ TrainerSubscriptionView | ✅ SubscriptionSettingsScreen | |
| Payouts (trainer) | ✅ PayoutsView | ✅ PayoutsSettingsScreen | |
| Custom Exercises | ✅ CustomExercisesView | ✅ CustomExercisesScreen | |
| Assessments (trainer) | ✅ AssessmentsView | ✅ TrainerAssessmentsScreen | |
| Contact Support | ✅ ContactFormView | ✅ ContactSupportScreen | |
| What's New | ✅ WhatsNewView | ✅ WhatsNewScreen | |
| Getting Started Guide | ✅ EducationalOnboardingView | ✅ (in settings) | |
| Terms of Service | ✅ Link | ✅ | |
| Privacy Policy | ✅ Link | ✅ | |
| Sign Out | ✅ | ✅ | |
| Custom App Mode | ✅ ToggleRow | ✅ CustomAppModeScreen | |
| Daily Exercise Targets (experimental) | ✅ ToggleRow | ✅ | |
| Voice Feedback (experimental) | ✅ ToggleRow | ✅ | |
| Personal Routines (experimental) | ✅ ToggleRow | ❌ Missing | |
| Dashboard Prompts | ✅ DashboardPromptsView | ✅ DashboardPromptsScreen | |
| Acknowledgements | ❌ | ✅ AcknowledgementsScreen | Flutter has extra |
| Experimental features | ✅ (in MoreView) | ✅ ExperimentalFeaturesScreen | |

### 4.14 Nutrition

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Recipe list | ❌ | ✅ RecipesListScreen | Flutter has, iOS doesn't |
| Recipe detail | ❌ | ✅ RecipeDetailScreen | |
| Create recipe | ❌ | ✅ CreateRecipeScreen | |

### 4.15 Resources

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Resource vault | ❌ | ✅ ResourceVaultScreen | Flutter has, iOS doesn't |
| Create resource | ❌ | ✅ CreateResourceScreen | |

### 4.16 Habits

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Habit list | ✅ (on client dashboard) | ✅ (habits feature) | |
| Log habit | ✅ | ✅ | |
| Trainer view | ✅ | ✅ | |
| Assign habit | ✅ | ✅ | |

### 4.17 Blog

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Blog list | ❌ | ✅ BlogListScreen | Flutter has, iOS doesn't |
| Blog post | ❌ | ✅ BlogPostScreen | |

### 4.18 Admin Panel

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Dashboard stats | ❌ | ✅ AdminDashboardScreen | Flutter has full admin |
| Event moderation | ❌ | ✅ AdminEventsScreen | |
| Blog management | ❌ | ✅ AdminBlogScreen | |
| Support tickets | ❌ | ✅ AdminTicketsScreen | |
| User management | ❌ | ✅ AdminUsersScreen | |
| Error logs | ❌ | ✅ AdminErrorLogsScreen | |
| Feature toggles | ❌ | ✅ AdminFeatureTogglesScreen | |

### 4.19 Extra iOS-Only Features

| Feature | iOS | Flutter | Notes |
|---|---|---|---|
| Live Activities (iOS lock screen) | ✅ | ❌ Platform-specific | Watch/companion |
| Share extension / widgets | ✅ | ❌ Platform-specific | iOS widgets |
| Apple Calendar sync | ✅ | ❌ Platform-specific | |
| Siri integration | ✅ | ❌ Platform-specific | |
| Visual Timeline Builder | ✅ | ❌ Not implemented | Drag-drop program building |
| Trainer Finding Onboarding | ✅ | ❌ Not implemented | First-time coach search flow |
| Purchase History screen | ✅ TransactionHistoryView | ❌ Not implemented | |
| QR Code Business Card | ✅ TrainerQRCodeView | ❌ Not implemented | |
| Event Marketplace (List/Map) | ✅ MarketplaceView | ❌ Not implemented | |

---

## 5. UI Components & Widgets Parity

### Shared Components

| Component | iOS | Flutter | Status |
|---|---|---|---|
| ZiroHeader (floating glass header) | ✅ ZiroHeader | ✅ (in shared/widgets/) | Equivalent |
| ZiroSheetHeader | ✅ ZiroSheetHeader | ✅ | |
| ZiroDismissButton | ✅ ZiroDismissButton | ✅ | |
| CustomTabBar | ✅ CustomTabBar | ✅ ZiroShell bottom nav | Different implementation |
| CalendarDateStrip | ✅ CalendarDateStrip | ✅ | |
| CalendarFiltersView | ✅ CalendarFiltersView | ✅ | |
| CachedAsyncImage | ✅ CachedAsyncImage | ✅ cached_network_image | |
| ErrorState | ✅ ErrorState | ✅ | |
| ListSkeleton | ✅ ListSkeleton | ✅ Shimmer | |
| DashboardSkeleton | ✅ DashboardSkeleton | ✅ | |
| CalendarSkeleton | ✅ CalendarSkeleton | ✅ | |
| AnalyticsWidgetSkeleton | ✅ AnalyticsWidgetSkeleton | ✅ | |
| ActiveProgramWidget | ✅ ActiveProgramWidget | ✅ | |
| ActiveRoutineWidget | ✅ ActiveRoutineWidget | ❌ Not implemented | |
| WorkoutMiniPlayer | ✅ WorkoutMiniPlayer | ✅ WorkoutMiniPlayer | |
| RestTimerSheet | ✅ RestTimerSheet | ✅ RestTimerSheet | |
| RestTimerProgressBar | ✅ RestTimerProgressBar | ✅ RestTimerProgressBar | |
| RPEPickerOverlay | ✅ RPEPickerOverlay | ✅ RPEPickerOverlay | |
| PlateCalculatorOverlay | ✅ PlateCalculatorOverlay | ✅ PlateCalculatorOverlay | |
| WorkoutNumericKeyboard | ✅ WorkoutNumericKeyboard | ✅ WorkoutNumericKeyboard | |
| WorkoutSetRow | ✅ WorkoutSetRow | ✅ WorkoutSetRow | |
| BlinkingCursor | ✅ BlinkingCursor | ✅ BlinkingCursor | |
| SafeEmptySessionView | ✅ SafeEmptySessionView | ✅ SafeEmptySessionView | |
| ImagePicker | ✅ ImagePicker | ✅ image_picker | |
| GIFImage | ✅ GIFImage | ✅ | |
| YouTubePlayerView | ✅ YouTubePlayerView | ✅ YoutubeSheetView | |
| SwipeView | ✅ SwipeView | ❌ Not implemented | iOS custom swipe widget |
| FlowLayout | ✅ FlowLayout | ✅ Wrap widget | |
| InteractiveBarChart | ✅ InteractiveBarChart | ✅ fl_chart | |
| InteractiveLineChart | ✅ InteractiveLineChart | ✅ fl_chart | |
| InteractiveDonutChart | ✅ InteractiveDonutChart | ✅ fl_chart | |
| HeatMapWidget | ✅ HeatMapWidget | ✅ | |
| GoalWidget | ✅ GoalWidget | ✅ | |
| RecoveryWidget | ✅ RecoveryWidget | ✅ | |
| PerformanceSummaryWidget | ✅ PerformanceSummaryWidget | ✅ | |
| MembershipCardView | ✅ MembershipCardView | ✅ | |
| CreditStatusWidget | ✅ CreditStatusWidget | ✅ | |
| DailyTargetCard | ✅ DailyTargetCard | ✅ | |
| LinkedTrainerCard | ✅ LinkedTrainerCard | ✅ | |
| FitnessGoalPlaceholder | ✅ FitnessGoalPlaceholder | ✅ | |
| GlobalSearchView | ✅ GlobalSearchView | ✅ | |
| FloatingMapButton | ✅ FloatingMapButton | ✅ | |
| BlurView | ✅ BlurView | ✅ BackdropFilter | |
| AppSafariView | ✅ AppSafariView | ✅ url_launcher + WebView | |
| SheetBackgroundModifier | ✅ SheetBackgroundModifier | ✅ | |
| RoundedCorner | ✅ RoundedCorner | ✅ ClipRRect | |
| SessionCard | ✅ SessionCard | ✅ | |
| ExerciseRow | ✅ ExerciseRow | ✅ | |
| ExerciseSelectionView | ✅ ExerciseSelectionView | ✅ ExerciseSelectionView | |
| RecentWorkoutRow | ✅ RecentWorkoutRow | ✅ | |
| FinishWorkoutAlert | ✅ FinishWorkoutAlert | ✅ FinishWorkoutDialog | |
| QuickAddSessionView | ✅ QuickAddSessionView | ✅ | |

### Missing iOS Components in Flutter

| Component | Purpose | Impact |
|---|---|---|
| ActiveRoutineWidget | Shows current routine progress on client dashboard | Low — cosmetic |
| SwipeView | Custom swipe gesture container | Low — can use Flutter's Dismissible |
| BlurView | Ultra-thin material effect | Low — BackdropFilter available |
| AnalyticsWidgetContainer | Widget management on analytics screen | Low — Flutter has similar |
| PublicProfileOfferingsView | Services/packages on public profile | Medium — might be missing |

---

## 6. Bottom Sheets & Modals

| Sheet / Modal | iOS | Flutter | Status |
|---|---|---|---|
| Add Measurement Sheet | ✅ AddMeasurementSheet | ✅ | |
| Rest Timer Sheet | ✅ RestTimerSheet | ✅ RestTimerSheet | |
| Workout Calendar Sheet | ✅ WorkoutCalendarSheet | ✅ WorkoutCalendarSheet | |
| Contact Form | ✅ ContactFormView (.sheet) | ✅ ContactSupportScreen | |
| Login sheet (mode switch) | ✅ LoginView as .sheet | ❌ Not implemented | |
| QR Code sheet | ✅ TrainerQRCodeView | ❌ Not implemented | |
| Educational Onboarding (fullScreenCover) | ✅ EducationalOnboardingView | ✅ | |
| What's New sheet | ✅ WhatsNewView | ✅ WhatsNewScreen | Route instead of sheet |
| Marketplace Manager sheet | ✅ MarketplaceManagerView | ✅ (in More) | |
| Set Input Sheet | ✅ (inline in WorkoutSessionView) | ✅ SetInputSheet | |
| Exercise Info Sheet | ✅ | ✅ ExerciseInfoSheet | |
| Voice Input Overlay | ✅ VoiceInputOverlay | ✅ VoiceInputOverlay | |
| Voice Coach Overlay | ✅ (VoiceCoachManager) | ✅ VoiceCoachOverlay | |
| RPE Picker Overlay | ✅ RPEPickerOverlay | ✅ RPEPickerOverlay | |
| Plate Calculator Overlay | ✅ PlateCalculatorOverlay | ✅ PlateCalculatorOverlay | |
| Finish Workout Alert | ✅ FinishWorkoutAlert | ✅ FinishWorkoutDialog | |
| Event Detail Sheet | ✅ EventDetailView | ✅ | Could be sheet or route |
| Voice Settings Sheet | ✅ VoiceSettingsView | ✅ VoiceCoachSettingsScreen | |
| Workout Sheet Overlay | ✅ (all workout controls) | ✅ WorkoutSheetOverlay | |
| Save Template Dialog | ✅ | ✅ SaveTemplateDialog | |

---

## 7. API Endpoint Parity

### 7.1 Auth Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| POST /api/auth/login | ✅ | ✅ | |
| POST /api/auth/register | ✅ | ✅ | |
| GET /api/auth/mobile-signin | ✅ | ✅ | OAuth |
| POST /api/auth/refresh | ✅ | ✅ | Token refresh |
| POST /api/auth/signout | ✅ | ✅ | |
| GET /api/auth/me | ✅ | ✅ | |
| POST /api/auth/sync-user | ✅ | ✅ | |
| POST /api/auth/forgot-password | ✅ | ✅ | |
| POST /api/auth/update-password | ✅ | ✅ | |
| POST /api/auth/complete-onboarding | ✅ | ✅ | |
| POST /api/auth/resend-verification-email | ✅ | ✅ | |
| POST /api/onboarding/complete | ✅ | ✅ | |

### 7.2 Dashboard Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/dashboard | ✅ fetchDashboard | ✅ | |
| GET /api/mobile/home | ✅ fetchMobileHome | ✅ | |
| GET /api/dashboard/insights | ✅ fetchInsights | ✅ | |
| GET /api/dashboard/summary | ❌ Not in iOS | ✅ | |
| GET /api/client/dashboard | ✅ fetchClientDashboard | ✅ | |
| GET /api/client/habits | ✅ | ✅ | |

### 7.3 Workout Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| POST /api/workout-sessions/start | ✅ | ✅ | |
| GET /api/workout-sessions/live | ✅ | ✅ | |
| POST /api/workout-sessions/live | ✅ | ✅ | Upsert exercise log |
| POST /api/workout/log | ✅ | ✅ | |
| POST /api/workout-sessions/finish | ✅ | ✅ | |
| POST /api/workout-sessions/plan | ✅ | ✅ | |
| GET /api/workout-sessions/history | ✅ | ✅ | |
| GET /api/workout-sessions/[id] | ✅ fetchSession | ✅ | |
| PUT /api/workout-sessions/[id] | ✅ updateSessionNotes | ✅ | |
| POST /api/workout-sessions/[id]/exercises | ✅ addExerciseToSession | ✅ | |
| DELETE /api/workout-sessions/[id]/exercises/[id] | ✅ deleteSessionExerciseLog | ✅ | |
| POST /api/workout-sessions/[id]/comments | ✅ | ✅ | |
| POST /api/workout-sessions/[id]/cancel | ✅ cancelWorkout | ✅ | |
| POST /api/workout-sessions/[id]/rest/start | ✅ startRest | ✅ | |
| POST /api/workout-sessions/[id]/rest/end | ✅ endRest | ✅ | |
| POST /api/workout-sessions/[id]/save-as-template | ✅ | ✅ | |
| GET /api/workout-sessions/[id]/summary | ✅ fetchWorkoutSummary | ✅ | |
| POST /api/workout-sessions/[id]/media | ✅ uploadSessionMedia | ✅ | |

### 7.4 Client Management Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/clients | ✅ | ✅ | |
| POST /api/clients | ✅ createClient | ✅ | |
| GET /api/clients/[id] | ✅ | ✅ | |
| PUT /api/clients/[id] | ✅ | ✅ | |
| DELETE /api/clients/[id] | ✅ | ✅ | |
| GET /api/clients/[id]/dashboard | ✅ | ✅ | |
| GET /api/clients/[id]/measurements | ✅ | ✅ | |
| POST /api/clients/[id]/measurements | ✅ | ✅ | |
| PUT /api/clients/[id]/measurements/[id] | ✅ | ✅ | |
| DELETE /api/clients/[id]/measurements/[id] | ✅ | ✅ | |
| GET /api/clients/[id]/photos | ✅ | ✅ | |
| POST /api/clients/[id]/photos | ✅ | ✅ | |
| DELETE /api/clients/[id]/photos/[id] | ✅ | ✅ | |
| POST /api/clients/[id]/assessments | ✅ | ✅ | |
| GET /api/clients/[id]/assessments | ✅ | ✅ | |
| PUT /api/clients/[id]/assessments/[id] | ✅ | ✅ | |
| DELETE /api/clients/[id]/assessments/[id] | ✅ | ✅ | |
| POST /api/clients/[id]/exercise-logs | ✅ | ✅ | |
| GET /api/clients/[id]/sessions | ✅ fetchWorkouts(clientId) | ✅ | |
| GET /api/clients/[id]/session/active | ✅ | ✅ | |
| GET /api/clients/[id]/program/active | ✅ fetchClientActiveProgram | ✅ | |
| POST /api/clients/[id]/insights | ❌ Not in iOS | ✅ | Flutter has AI insights |
| GET /api/clients/[id]/packages | ✅ fetchClientPackages | ✅ | |
| POST /api/clients/invite | ✅ | ✅ | |
| POST /api/clients/request-link | ✅ requestClientConnection | ✅ | |
| PUT /api/clients/[id]/avatar | ✅ | ✅ | |
| DELETE /api/clients/[id]/avatar | ✅ | ✅ | |

### 7.5 Programs & Templates Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/trainer/programs | ✅ fetchPrograms | ✅ | |
| POST /api/trainer/programs | ✅ createProgram | ✅ | |
| GET /api/workout-templates/[id] | ✅ | ✅ | |
| GET /api/trainer/programs/templates | ✅ fetchWorkoutTemplates | ✅ | |
| POST /api/trainer/programs/templates | ✅ createWorkoutTemplate | ✅ | |
| POST /api/trainer/programs/templates/[id]/exercises | ✅ addExerciseToTemplate | ✅ | |
| DELETE .../exercises/[stepId] | ✅ deleteTemplateExercise | ✅ | |
| POST .../templates/[id]/rest | ✅ addRestStepToTemplate | ✅ | |
| POST .../templates/[id]/copy | ✅ | ✅ | |
| POST /api/trainer/clients/[id]/assign-program | ✅ assignProgramToClient | ✅ | |
| GET /api/client/programs | ✅ | ✅ | |
| POST /api/client/programs | ✅ | ✅ | AI generate |
| GET /api/client/program/active | ✅ fetchActiveProgram | ✅ | |
| PUT /api/client/program/active | ✅ | ✅ | |
| DELETE /api/trainer/programs/[id] | ✅ deleteProgram | ✅ | |
| PUT .../templates/[id]/steps/[stepId] | ✅ updateTemplateStep | ✅ | |

### 7.6 Trainer Profile Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/profile/me | ✅ | ✅ | |
| PUT /api/profile/me/core-info | ✅ updateCoreInfo | ✅ | |
| POST /api/profile/me/avatar | ✅ uploadProfileAvatar | ✅ | |
| DELETE /api/profile/me/avatar | ✅ | ✅ | |
| PUT /api/profile/me/text-content | ✅ updateProfileText | ✅ | |
| PUT /api/profile/me/branding | ✅ uploadBranding | ✅ | |
| CRUD /api/profile/me/services | ✅ | ✅ | |
| CRUD /api/profile/me/packages | ✅ | ✅ | |
| CRUD /api/profile/me/testimonials | ✅ | ✅ | |
| CRUD /api/profile/me/benefits | ✅ | ✅ | |
| PUT /api/profile/me/benefits/order | ✅ | ✅ | |
| CRUD /api/profile/me/social-links | ✅ | ✅ | |
| CRUD /api/profile/me/external-links | ✅ | ✅ | |
| CRUD /api/profile/me/transformation-photos | ✅ | ✅ | |
| GET /api/profile/me/availability | ✅ | ✅ | |
| CRUD /api/profile/me/exercises | ✅ | ✅ | Custom exercises |

### 7.7 Calendar Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/trainer/calendar | ✅ fetchCalendar | ✅ | |
| POST /api/trainer/calendar | ✅ createEvent | ✅ | |
| PUT /api/trainer/calendar/[id] | ✅ updateEvent | ✅ | |
| DELETE /api/trainer/calendar/[id] | ✅ deleteEvent | ✅ | |
| POST .../sessions/[id]/remind | ✅ | ✅ | |
| GET .../calendar/clients-summary | ✅ fetchClientsSummary | ✅ | |
| GET .../session-creation-data | ✅ | ✅ | |

### 7.8 Check-In Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| POST /api/client/check-in | ✅ submitCheckIn | ✅ | |
| GET /api/client/check-ins | ✅ fetchClientCheckIns | ✅ | |
| GET /api/client/check-in/config | ✅ | ✅ | |
| GET /api/trainer/check-ins | ✅ fetchCheckIns | ✅ | |
| GET /api/trainer/check-ins/pending | ✅ | ✅ | |
| GET /api/trainer/check-ins/[id] | ✅ fetchCheckInDetails | ✅ | |
| PATCH /api/trainer/check-ins/[id]/review | ✅ reviewCheckIn | ✅ | |
| DELETE /api/trainer/check-ins/[id] | ✅ deleteCheckIn | ✅ | |

### 7.9 Explore Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/trainers | ✅ searchTrainers | ✅ | |
| GET /api/trainers/[username] | ✅ getTrainerPublicProfile | ✅ | |
| GET /api/trainers/specialties | ✅ | ✅ | |
| GET /api/trainers/[username]/schedule | ✅ fetchTrainerSchedule | ✅ | |
| GET /api/trainers/[username]/packages | ✅ | ✅ | |
| GET /api/trainers/[username]/testimonials | ✅ | ✅ | |
| GET /api/trainers/[username]/transformation-photos | ✅ | ✅ | |
| GET /api/explore/featured | ✅ fetchExploreFeatured | ✅ | |
| GET /api/explore/events | ✅ fetchExploreEvents | ✅ | |
| GET /api/explore/metadata | ✅ fetchExploreMetadata | ✅ | |
| GET /api/events | ✅ | ✅ | |

### 7.10 Bookings Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/bookings | ✅ | ✅ | |
| POST /api/bookings | ✅ createBooking | ✅ | |
| PUT /api/bookings/[id]/confirm | ✅ confirmBooking | ✅ | |
| PUT /api/bookings/[id]/decline | ✅ declineBooking | ✅ | |

### 7.11 Chat Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/chat | ✅ | ✅ | |
| POST /api/chat | ✅ | ✅ | |

### 7.12 Notifications Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/notifications | ✅ fetchNotifications | ✅ | |
| PUT /api/notifications/[id] | ✅ markNotificationRead | ✅ | |
| POST /api/profile/me/push-token | ✅ | ✅ | |

### 7.13 Billing Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/billing/subscription | ✅ | ✅ | |
| POST /api/billing/subscription | ✅ | ✅ | |
| PATCH /api/billing/subscription | ✅ | ✅ | |
| POST /api/billing/subscribe-new | ❌ | ❌ | Missing in both |
| POST /api/billing/portal | ✅ | ✅ | |
| POST /api/checkout/session | ✅ createCheckoutSession | ✅ | |
| GET /api/billing/revenue | ✅ fetchRevenueData | ✅ | |
| GET /api/billing/payouts | ✅ | ✅ | |
| GET /api/billing/stripe-onboarding | ✅ fetchStripeOnboardingUrl | ✅ | |

### 7.14 Voice / AI Endpoints

| Endpoint | iOS | Flutter | Notes |
|---|---|---|---|
| GET /api/ai-trainer/session | ❌ | ❌ | Missing in both |
| POST /api/ai-trainer/session | ❌ | ❌ | Missing in both |
| POST /api/ai-trainer/voice | ❌ | ❌ | Missing in both |
| POST /api/client/ai/generate | ❌ | ❌ | Missing in both |
| POST /api/mobile/ai-coach/generate | ✅ | ✅ | Flutter has |
| POST /api/mobile/ai-coach/refine | ✅ | ✅ | |

### Differences Summary

- **iOS has no admin endpoints** — Flutter admin panel is unique to Flutter
- **iOS has no recipe endpoints** — Flutter nutrition is unique to Flutter
- **iOS has no resource vault endpoints** — Flutter resources are unique
- **iOS has no blog endpoints** — Flutter blog is unique
- **iOS has no client insights endpoint** — Flutter has POST /api/clients/[id]/insights
- **iOS has no subscription sharing requests** — Flutter has /api/client/sharing endpoints
- **iOS has no exercise sync endpoint** — Flutter uses sync engine
- **iOS has no checkout session for events** — uses Stripe separately

---

## 8. Data Models Comparison

| iOS Model | Flutter Equivalent | Status |
|---|---|---|
| User | User (profile.dart) / AuthState | ✅ |
| ApiWorkoutSession | WorkoutSession | ✅ |
| ClientExerciseLog | ExerciseLog | ✅ |
| Exercise | Exercise | ✅ |
| WorkoutTemplate | WorkoutTemplate | ✅ |
| WorkoutProgram | WorkoutProgram | ✅ |
| Client | Client | ✅ |
| CheckIn | CheckInSubmission | ✅ |
| CalendarEvent | CalendarEvent | ✅ |
| CalendarEventItem | CalendarEvent | ✅ |
| DashboardModels | DashboardData | ✅ |
| TrainerPublicProfile | Profile / TrainerProfile | ✅ |
| NotificationModel | Notification | ✅ |
| RevenueModels | RevenueData | ✅ |
| AnalyticsModels | AnalyticsData | ✅ |
| BookingModels | Booking | ✅ |
| ExploreModels | ExploreData | ✅ |
| FitnessGoal | FitnessGoal | ✅ |
| DailyTarget | DailyTarget | ✅ |
| TimelineModels | (programs feature) | Partial |
| TrainerAssessment | TrainerAssessment | ✅ |
| TrainerContentModels | TrainerContent | ✅ |
| VoiceSettingsModel | VoiceSettings | ✅ |
| AppMode | AppMode (enum) | ✅ |
| AppTab | (ZiroShell tab config) | ✅ |

### Model Pattern Differences

- **iOS uses flexible Codable** with multi-key fallback (e.g., `id` or `_id`, `volume` or `totalVolume`)
- **Flutter uses @freezed + @JsonSerializable** with strict key mapping
- **iOS handles date parsing** with a custom ISO8601 decoder with multiple format fallbacks
- **Flutter uses DateTime** with standard JSON parsing
- **iOS decodes both wrapper {data: T} and direct T** responses — Flutter likely uses wrapper-only

---

## 9. Managers & Services

### iOS Managers vs Flutter Equivalents

| iOS Manager | Flutter Equivalent | Status |
|---|---|---|
| AppState | Multiple providers + SharedPreferences | ✅ Partial |
| WorkoutManager | Various workout providers | ✅ |
| RestTimerManager | RestTimerManagerProvider | ✅ |
| WorkoutTimer | WorkoutTimerProvider | ✅ |
| SyncManager | data/sync/ sync engine | ✅ |
| CacheManager | Drift local DB | ✅ |
| VoiceCoachManager | VoiceCoachProvider | ✅ |
| VoiceFeedbackManager | VoiceFeedbackService | ✅ |
| VoiceLogManager | VoiceLogService | ✅ |
| NotificationManager | Notification providers | ✅ |
| LiveActivityManager | LiveActivityService | ✅ |
| HapticManager | HapticFeedback (Flutter) | ✅ |
| LocationManager | geolocator package | ✅ |
| DailyTargetManager | DailyTarget providers | ✅ |
| AppleCalendarManager | N/A (iOS-only) | N/A |
| SubscriptionManager | Subscription provider | ✅ |
| AppleSignInHelper | sign_in_with_apple | ✅ |
| GoogleSignInHelper | google_sign_in | ✅ |
| KeychainHelper | flutter_secure_storage | ✅ |
| ThemeManager | AppTheme | ✅ |
| LanguageManager | Flutter localization | ✅ |
| StripeConnectManager | Stripe SDK | ✅ |

### Key Difference: iOS AppState

iOS `AppState` is a centralized observable holder for:
- `currentMode` (trainer/personal)
- `selectedTab`
- `isModeSelectorExpanded`
- Feature flags: `isCustomModeEnabled`, `isDailyTargetsEnabled`, `isVoiceLogEnabled`, `isVoiceFeedbackEnabled`, `isRoutinesEnabled`
- Version tracking: `lastSeenVersion`, `shouldShowWhatsNew`
- Deep link data: `calendarDeepLinkDate`, `calendarDeepLinkEventId`
- Cross-mode notification: `showCrossModeAlert`, `pendingNotificationMode`
- Onboarding filters: `initialTrainerFilters`

Flutter distributes these across:
- `AuthProvider` for auth/mode
- `PreferencesProvider` for feature flags
- Router for whats-new
- Individual providers for the rest

### iOS Prefetch Strategy (on login)

On login, iOS prefetches in background:
1. **Trainer mode**: dashboard, clients, programs, templates, calendar (5-month range), clients summary
2. **Personal mode**: dashboard, active program, analytics (30 days), workout history (20 items), exercises (100 items)

Flutter should implement similar prefetch to ensure instant loading.

---

## 10. Workout Flow Deep Dive

### iOS Workout Flow (WorkoutManager)

```
1. START WORKOUT
   │
   ├── From Template (TemplatePickerView → startSession(templateId:))
   ├── From Booking (booking → startSession(bookingId:))
   ├── From Calendar (planned session → startSession(eventId:))
   ├── From Quick Add (QuickAddSessionView)
   └── Ad-hoc (no template → select exercises)
       │
       ├── [CHECK] Existing active session? → Conflict Alert (Resume/End/Cancel)
       └── [CHECK] Network → start syncing + POST /api/workout-sessions/start
           │
           ├── Success → session started, timer begins
           └── Offline → create local session, queue for sync

2. ACTIVE SESSION
   │
   ├── WorkoutSessionView (full screen, tab bar hidden)
   │   ├── WorkoutSessionHeader (timer, exercise name, progress)
   │   ├── WorkoutSessionContent (exercise list with swipe-to-complete)
   │   │   ├── WorkoutExerciseCard (current exercise card)
   │   │   ├── WorkoutSetRow (per set input: reps, weight, RPE, side)
   │   │   ├── RPEPickerOverlay (tap RPE → overlay)
   │   │   ├── PlateCalculatorOverlay (tap plate → calculator)
   │   │   ├── WorkoutNumericKeyboard (for weight/reps)
   │   │   └── Superset grouping
   │   ├── WorkoutSessionControls (add exercise, finish, cancel)
   │   ├── RestTimerSheet (auto-start after set)
   │   └── YouTubePlayerView (exercise demo)
   │
   ├── Minimize → WorkoutMiniPlayer overlay (tab bar visible)
   ├── Tap mini player → restore full screen
   │
   └── Voice Input
       ├── VoiceLogManager (tap mic → speak → parse → fill set)
       └── VoiceFeedbackManager (TTS confirmation)

3. FINISH / CANCEL
   │
   ├── Finish → FinishWorkoutAlert → POST finish → Summary
   │   ├── POST rest/end (if rest active)
   │   └── POST finish + notes
   │
   ├── Cancel → POST cancel → discard
   │
   └── Auto-sync → "Syncing workout..." overlay → POST logs
```

### Flutter Workout Flow

The Flutter workout feature has 56 files — significantly more than any other feature module. It has equivalent components for almost every iOS piece including the mini player, rest timer, RPE picker, plate calculator, voice input, numeric keyboard, YouTube viewer, and all set logging.

**Missing from Flutter's workout flow:**
1. Active session conflict detection (existing session check on start)
2. Long session warning (2h/4h)
3. Auto-end session at 4h
4. "Syncing workout..." indicator overlay
5. Swipe-to-complete exercises (iOS uses swipe gesture on exercise cards)
6. Voice coach announcements (TTS for exercise transitions — iOS has VoiceCoachManager)
7. Live Activities (iOS lock screen — platform-specific)

---

## 11. Critical Gaps

### Gap 1: Mode Selector & Swipe Gesture
**iOS has**: Rich mode selector that expands from tab bar with drag-up, tap, and swipe-to-change gestures. Shows Professional/Personal cards with notification badges.
**Flutter has**: CustomAppModeScreen in settings (not accessible from tab bar).
**Impact**: Medium — users can't quickly switch between trainer/personal mode.

### Gap 2: Visual Timeline Builder (Programs)
**iOS has**: `VisualTimelineBoardView` + `VisualTimelineBuilderView` for drag-drop program creation with visual timeline.
**Flutter has**: Standard form-based program creation.
**Impact**: Medium — iOS has a more visual approach for program building.

### Gap 3: Trainer QR Code (Digital Business Card)
**iOS has**: QR code generated from username/ID, sharable to let clients scan to see profile.
**Flutter has**: Not implemented.
**Impact**: Low — marketing feature.

### Gap 4: Purchase/Transaction History
**iOS has**: `TransactionHistoryView` showing purchase history with records.
**Flutter has**: Not implemented in UI (though endpoint exists).
**Impact**: Low — client-facing feature.

### Gap 5: Event Marketplace (List/Map Toggle)
**iOS has**: `MarketplaceView` with list/map toggle for browsing events + trainers.
**Flutter has**: Separate ExploreScreen (list) + TrainerMapScreen (map) — no combined view.
**Impact**: Low — cosmetic difference.

### Gap 6: Trainer Finding Onboarding Flow
**iOS has**: `TrainerFindingOnboardingView` for first-time users to find a coach.
**Flutter has**: No equivalent first-time flow.
**Impact**: Medium — affects new user experience.

### Gap 7: Active Session Conflict Handling
**iOS has**: Alert with "Resume", "End & Start New", "Cancel" when starting a workout with existing active session.
**Flutter has**: No conflict check.
**Impact**: Medium — data integrity issue if users start multiple sessions.

### Gap 8: Cross-Mode Notification Alerts
**iOS has**: `showCrossModeAlert` + `pendingNotificationMode` in AppState to alert when notifications arrive for the other role.
**Flutter has**: No equivalent.
**Impact**: Low — convenience feature.

### Gap 9: Live Activities (iOS Lock Screen)
**iOS has**: `LiveActivityManager` + `SharedWorkoutAttributes` for iOS lock screen workout tracking.
**Flutter has**: `LiveActivityService` configured but iOS-only via platform channels.
**Impact**: Low — platform-specific feature.

---

## 12. Minor Gaps & Nuances

| # | Gap | iOS Details | Flutter Notes |
|---|-----|-------------|---------------|
| 1 | Coach banner (client dashboard) | Dismissable "Find a Coach" CTA | Missing |
| 2 | Check-in banner (client dashboard) | Dismissable check-in prompt | Missing |
| 3 | ActiveRoutineWidget | Shows routine progress on dashboard | Missing |
| 4 | Pop-to-root on tab re-tap | NotificationCenter "PopToRoot" notification | Not implemented |
| 5 | Mode switch gradient animation | Gradient border flash on tab bar | Not implemented |
| 6 | Sheet-based re-login on mode switch | LoginView as .sheet for unauthenticated mode | Not implemented |
| 7 | SwipeView for dismissable cards | Custom swipe-to-dismiss | Uses Dismissible |
| 8 | Long session warning (2h/4h) | Alerts at 2h warning, 4h auto-end | Not implemented |
| 9 | Syncing indicator | "Syncing workout..." overlay | Not implemented |
| 10 | Personal Routines experimental | ToggleRow in MoreView | Not in Flutter |
| 11 | Audio coach cues | TTS for exercise transitions | Missing from voice_coach |
| 12 | Clients Summary sidebar (calendar) | Shows which clients have sessions on dates | Missing |
| 13 | Program Builder Choice | "Standard" vs "Visual Timeline" choice | Flutter only has standard |
| 14 | ProPaywallView | Pro membership paywall/prompt | Not in iOS either (free beta) |

---

## 13. Recommended Migration Order

### Phase 1 (Immediate — 1-2 days)
1. **Mode Selector + Swipe Gesture** on tab bar — replicate iOS CustomTabBar's mode expansion and swipe
2. **Active Session Conflict** detection — check for existing session before starting

### Phase 2 (Short-term — 1 week)
3. **Trainer Finding Onboarding** for new personal users
4. **Coach Banner + Check-in Banner** on client dashboard
5. **Visual Timeline Builder** for program creation
6. **Purchase/Transaction History** screen

### Phase 3 (Medium-term — 2 weeks)
7. **Event Marketplace** with combined list/map view
8. **QR Code Business Card** for trainers
9. **Cross-mode notification alerting**
10. **Pop-to-root** on tab re-tap

### Phase 4 (Long-term — 4+ weeks)
11. **AI-Coached Live Workout** (voice-based with speech-to-text + Gemini)
12. **Audio Cue / Voice Coach** for workout transitions
13. **Live Activities** (iOS lock screen)
14. **Long session handling** (2h/4h warnings)

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total iOS view files | 100+ |
| Total iOS ViewModels | 27 |
| Total iOS Managers/Services | 22 |
| Total iOS API endpoint files | 12 |
| Total iOS Models | 23 |
| Total Flutter feature modules | 29 |
| Total Flutter routed screens | 80+ |
| Feature parity (iOS → Flutter) | ~85% |
| Features Flutter has (iOS missing) | Admin panel, Nutrition, Resources, Blog, Sharing Requests, Admin users/errors/toggles |
| Features iOS has (Flutter missing) | Visual Timeline Builder, QR Code, Event Marketplace, Transaction History, Trainer Finding Onboarding, Mode Selector swipe |
| API endpoint parity | ~95% (shared backend) |
| UI component parity | ~90% |
| **Critical gaps to fix** | **9** |
| **Minor gaps to fix** | **14** |
