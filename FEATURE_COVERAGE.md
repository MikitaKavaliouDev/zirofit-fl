# Ziro Fit — Feature Coverage Map

> **Purpose:** Complete mapping of all 120+ zirofit-next backend API endpoints to Flutter mobile features with priority tiers, dependencies, sync support, and implementation phasing.
>
> **Last updated:** 2026-05-01
>
> **Backend:** zirofit-next (Next.js 16 App Router, Supabase Auth, Prisma/PostgreSQL)
> **Frontend:** zirofit-fl (Flutter 3.22+, Riverpod, Drift, Dio)
>
> **Related docs:** `ARCHITECTURE.md`, `DATA_MODELS.md`, `AUTH_FLOW.md`, `API_REFERENCE.md`

---

## Table of Contents

1. [Priority Classification](#1-priority-classification)
2. [Feature Dependency Graph](#2-feature-dependency-graph)
3. [Feature Group Inventory (24 Groups)](#3-feature-group-inventory-24-groups)
   - Group 1: Auth & Onboarding (P0)
   - Group 2: Dashboard (P0)
   - Group 3: Workout Management (P0)
   - Group 4: Client Management (P0)
   - Group 5: Trainer Profile (P0)
   - Group 6: Programs & Templates (P1)
   - Group 7: Exercise Library (P1)
   - Group 8: Calendar & Scheduling (P1)
   - Group 9: Check-Ins (P1)
   - Group 10: Bookings (P1)
   - Group 11: Public Events (P1)
   - Group 12: Notifications (P1)
   - Group 13: Chat (P1)
   - Group 14: Billing & Packages (P2)
   - Group 15: Nutrition (P2)
   - Group 16: Habits (P2)
   - Group 17: Resource Vault (P2)
   - Group 18: Social/Explore (P2)
   - Group 19: AI Features (P3)
   - Group 20: Trainer Settings (P1)
   - Group 21: Admin Panel (P3)
   - Group 22: System/Config (P1)
   - Group 23: Offline Sync (P1)
   - Group 24: Miscellaneous (P2)
4. [Implementation Phases](#4-implementation-phases)
5. [Coverage Matrix](#5-coverage-matrix)
6. [Endpoint Inventory (120+ endpoints)](#6-endpoint-inventory)

---

## 1. Priority Classification

### Priority Tiers

| Tier | Label | Definition | Target Release |
|------|-------|------------|----------------|
| **P0** | Launch Critical | Must ship in v1.0. Core functionality without which the app is unusable. | v1.0 |
| **P1** | Important | Should ship in v1.0 if possible. Major features expected by users. | v1.0 (stretch) |
| **P2** | Nice to Have | Can wait for v1.1. Enhancement features that add value but aren't critical. | v1.1 |
| **P3** | Future | For v2.0+ consideration. Advanced features, admin tools, experimental. | v2.0+ |

### Effort Estimation

| Effort | Range | Example |
|--------|-------|---------|
| **XS** | < 2 days | Single screen, one API call |
| **S** | 2–5 days | Feature with 2–3 screens, simple CRUD |
| **M** | 1–2 weeks | Multi-screen feature, complex state, several endpoints |
| **L** | 2–4 weeks | Major domain with 10+ endpoints, offline sync, complex UI |
| **XL** | 4–8 weeks | Cross-cutting feature spanning multiple domains |

### Sync Support Classification

| Sync Type | Description |
|-----------|-------------|
| **Fully Synced** | All data available offline. Pull/push supported. |
| **Partially Synced** | Core data available offline. Some operations require network. |
| **Live Only** | Requires network connectivity. No offline support. |

---

## 2. Feature Dependency Graph

```
AUTH & ONBOARDING (P0)
    │
    ├──► OFFLINE SYNC (P1) ──► Everything (foundation for offline-first)
    │
    ├──► DASHBOARD (P0) ──► Trainer Dashboard / Client Dashboard
    │
    ├──► WORKOUT MANAGEMENT (P0) ──► EXERCISE LIBRARY (P1) ──► PROGRAMS & TEMPLATES (P1)
    │                                    │
    │                                    └──► CALENDAR & SCHEDULING (P1) ──► BOOKINGS (P1)
    │                                                                          │
    │                                                                          └──► NOTIFICATIONS (P1)
    │
    ├──► CLIENT MANAGEMENT (P0) ──► MEASUREMENTS ──► PHOTOS ──► ASSESSMENTS
    │       │                           │
    │       │                           └──► EXERCISE LOGS ──► SESSIONS
    │       │
    │       ├──► CHECK-INS (P1) ──► HABITS (P2) ──► NUTRITION (P2) ──► RESOURCE VAULT (P2)
    │       │
    │       └──► CHAT (P1)
    │
    ├──► TRAINER PROFILE (P0) ──► SERVICES ──► PACKAGES ──► TESTIMONIALS ──► BENEFITS
    │       │
    │       ├──► SOCIAL/EXPLORE (P2) ──► EVENTS (P1)
    │       │
    │       ├──► TRAINER SETTINGS (P1)
    │       │
    │       └──► BILLING & PACKAGES (P2) ──► STRIPE ──► SUBSCRIPTION
    │
    ├──► AI FEATURES (P3) ──► AI COACH ──► AI INSIGHTS ──► AI VOICE
    │
    └──► ADMIN PANEL (P3) ──► USERS ──► EVENTS ──► BLOG ──► TICKETS
```

### Dependency Rules

1. **Auth & Onboarding** — No dependencies except Supabase SDK. All features depend on this.
2. **Offline Sync** — Depends on Auth. Foundation for all offline-first behavior.
3. **Dashboard** — Depends on Auth. Consumes data from most other features.
4. **Workout Management** — Depends on Exercises, Templates. Used by Client Management.
5. **Client Management** — Depends on Auth. Feeds into Check-Ins, Habits, Chat.
6. **Trainer Profile** — Standalone CRUD. Feeds into Social/Explore.
7. **Calendar & Scheduling** — Depends on Client Management + Templates.
8. **Check-Ins** — Depends on Client Management.
9. **Billing** — Depends on Trainer Profile (packages) + Stripe.

---

## 3. Feature Group Inventory (24 Groups)

---

### Group 1: Auth & Onboarding (P0)

**Priority:** P0 — Launch Critical
**Role:** `public`, `pending`, `client`, `trainer`, `admin`
**Effort:** L (2–3 weeks)
**Sync:** Live only (auth tokens stored securely)
**Dependencies:** None (foundation layer)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 1.1 | Email/Password Login | `POST /api/auth/login` | S | Live | LoginScreen |
| 1.2 | Email/Password Registration | `POST /api/auth/register` | S | Live | RegisterScreen |
| 1.3 | OAuth (Google/Apple) | `GET /api/auth/mobile-signin` | M | Live | LoginScreen, AuthCallbackScreen |
| 1.4 | Token Refresh | `POST /api/auth/refresh` | S | Live | (interceptor) |
| 1.5 | Auto-Login (Session Restore) | `POST /api/auth/refresh` + `GET /api/auth/me` | M | Live | SplashScreen |
| 1.6 | Forgot Password | `POST /api/auth/forgot-password` | XS | Live | ForgotPasswordScreen |
| 1.7 | Update Password | `POST /api/auth/update-password` | XS | Live | UpdatePasswordScreen |
| 1.8 | Sign Out | `POST /api/auth/signout` | XS | Live | (menu) |
| 1.9 | Get Current User | `GET /api/auth/me` | S | Live | (all authenticated screens) |
| 1.10 | Sync User | `POST /api/auth/sync-user` | XS | Live | (post-OAuth) |
| 1.11 | Resend Verification Email | `POST /api/auth/resend-verification-email` | XS | Live | VerifyEmailScreen |
| 1.12 | Complete Onboarding | `POST /api/auth/complete-onboarding` | S | Live | OnboardingScreen |
| 1.13 | Role Selection & Profile Setup | `POST /api/onboarding/complete` | M | Live | OnboardingScreen |

#### Endpoints Consumed (13)

- `POST /api/auth/login` — Email/password authentication
- `POST /api/auth/register` — Account creation
- `GET /api/auth/mobile-signin` — OAuth redirect URL
- `POST /api/auth/refresh` — Token refresh
- `POST /api/auth/signout` — Session termination
- `GET /api/auth/me` — Current user profile
- `POST /api/auth/sync-user` — Prisma user sync (self-healing)
- `POST /api/auth/forgot-password` — Password reset email
- `POST /api/auth/update-password` — Password change
- `POST /api/auth/resend-verification-email` — Email verification resend
- `POST /api/auth/complete-onboarding` — Onboarding completion flag
- `POST /api/onboarding/complete` — Full onboarding form (multipart)
- `PUT /api/clients/[id]` — Client profile updates (name, email, phone, status, etc.)
- `GET/PUT /api/profile/me/text-content` — Trainer profile text content updates

#### Implementation Notes

- Use `supabase_flutter` SDK alongside custom API for token management
- `flutter_secure_storage` for token persistence (Keychain/Keystore)
- Auth interceptor on Dio handles 401 → refresh → retry
- Deep link handling for OAuth callback (`zirofitapp://auth-callback?...`)
- Onboarding is a multi-step flow: role selection → profile → (trainer) specialties → complete
- `POST /api/onboarding/complete` replaces the simple `complete-onboarding` for full setups

---

### Group 2: Dashboard (P0)

**Priority:** P0 — Launch Critical
**Role:** `trainer`, `client`
**Effort:** M (1–2 weeks)
**Sync:** Partially synced (can show cached data)
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 2.1 | Trainer Dashboard | `GET /api/dashboard`, `GET /api/mobile/home` | M | Partial | TrainerDashboardScreen |
| 2.2 | Client Dashboard | `GET /api/client/dashboard` | M | Partial | ClientDashboardScreen |
| 2.3 | Dashboard Insights | `GET /api/dashboard/insights` | S | Live | TrainerDashboardScreen |
| 2.4 | Dashboard Summary | `GET /api/dashboard/summary` | S | Live | (widget) |
| 2.5 | Mobile Home | `GET /api/mobile/home` | M | Partial | HomeScreen |

#### Endpoints Consumed (5)

- `GET /api/dashboard` — Full trainer dashboard (upcoming, pending, revenue)
- `GET /api/dashboard/insights` — Analytics dashboard data
- `GET /api/dashboard/summary` — Lightweight dashboard summary
- `GET /api/client/dashboard` — Client home (trainer info, recent sessions, measurements)
- `GET /api/mobile/home` — Mobile-optimized home (role-based response)

#### Implementation Notes

- Trainer dashboard shows: pending check-ins count, pending bookings count, active clients, revenue, upcoming sessions, recent activity
- Client dashboard shows: linked trainer info, upcoming workouts, last check-in, recent sessions, measurements snapshot
- Pull-to-refresh triggers full re-fetch
- Offline falls back to cached dashboard snapshot
- Mobile home endpoint returns role-appropriate data in one call

---

### Group 3: Workout Management (P0)

**Priority:** P0 — Launch Critical
**Role:** `client`, `trainer`
**Effort:** XL (4–6 weeks)
**Sync:** Fully synced (core offline-first feature)
**Dependencies:** Exercise Library (Group 7), Programs & Templates (Group 6)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 3.1 | Start Workout | `POST /api/workout-sessions/start` | M | Full | ActiveWorkoutScreen |
| 3.2 | Live Workout Tracking | `POST /api/workout-sessions/live`, `POST /api/workout/log` | L | Full | ActiveWorkoutScreen |
| 3.3 | Exercise Logging | `POST /api/workout-sessions/live`, `POST /api/workout/log` | M | Full | ExerciseDetailScreen |
| 3.4 | Rest Timer | `POST /api/workout-sessions/[id]/rest/start`, `.../rest/end` | S | Full | ActiveWorkoutScreen (widget) |
| 3.5 | Finish Workout | `POST /api/workout-sessions/finish` | S | Full | WorkoutSummaryScreen |
| 3.6 | Cancel Workout | `POST /api/workout-sessions/[id]/cancel` | XS | Full | ActiveWorkoutScreen |
| 3.7 | Plan/Schedule Workouts | `POST /api/workout-sessions/plan` | M | Full | PlanWorkoutScreen |
| 3.8 | Workout History | `GET /api/workout-sessions/history` | M | Full | WorkoutHistoryScreen |
| 3.9 | Workout Detail | `GET /api/workout-sessions/[id]` | S | Full | WorkoutDetailScreen |
| 3.10 | Workout Summary | `GET /api/workout-sessions/[id]/summary` | S | Full | WorkoutSummaryScreen |
| 3.11 | Session Comments | `POST /api/workout-sessions/[id]/comments` | S | Full | WorkoutDetailScreen |
| 3.12 | Save as Template | `POST /api/workout-sessions/[id]/save-as-template` | S | Full | WorkoutSummaryScreen |
| 3.13 | Add/Remove Exercises | `POST/DELETE /api/workout-sessions/[id]/exercises/...` | M | Full | ActiveWorkoutScreen |

#### Endpoints Consumed (17)

- `POST /api/workout-sessions/start` — Start from template, booking, or ad-hoc
- `POST /api/workout-sessions/live` (GET + POST) — Get active session / upsert exercise log
- `POST /api/workout/log` — Alternative log endpoint (supports tempo, side)
- `POST /api/workout-sessions/finish` — Complete a session
- `POST /api/workout-sessions/plan` — Schedule future session
- `GET /api/workout-sessions/history` — Paginated completed sessions
- `GET /api/workout-sessions/[id]` — Session detail
- `PUT /api/workout-sessions/[id]` — Update session notes
- `POST /api/workout-sessions/[id]/exercises` — Add exercises to active session
- `DELETE /api/workout-sessions/[id]/exercises/[exerciseId]` — Remove exercise log
- `POST /api/workout-sessions/[id]/comments` — Add trainer feedback
- `POST /api/workout-sessions/[id]/cancel` — Cancel in-progress/planned
- `POST /api/workout-sessions/[id]/rest/start` — Start rest timer
- `POST /api/workout-sessions/[id]/rest/end` — End rest timer
- `POST /api/workout-sessions/[id]/save-as-template` — Create template from session
- `GET /api/workout-sessions/[id]/summary` — Best set, PRs, totals
- `GET /api/public/workout-summary/[sessionId]` — Public shareable summary

#### Implementation Notes

- **Core offline-first feature** — Must work without internet
- Exercise logs support: reps, weight, tempo, side (LEFT/RIGHT/BOTH), supersets (key + order)
- Personal Records are auto-detected on the backend and returned in live/log responses
- Rest timer persists on server (`restStartedAt`), survives app restart
- Sessions can be started from: template, planned session, booking, or ad-hoc (no template)
- History uses cursor-based pagination (`cursor` = ISO date string)
- Session comments are trainer-to-client feedback on completed sessions
- Public workout summary enables social sharing (P2 enhancement)

---

### Group 4: Client Management (P0)

**Priority:** P0 — Launch Critical
**Role:** `trainer`
**Effort:** XL (4–5 weeks)
**Sync:** Fully synced
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 4.1 | Client List | `GET /api/clients` | M | Full | ClientsListScreen |
| 4.2 | Client Detail | `GET /api/clients/[id]` | S | Full | ClientDetailScreen |
| 4.3 | Create/Update/Delete Client | `POST /api/clients`, `PUT/DELETE /api/clients/[id]` | M | Full | AddClientScreen |
| 4.4 | Client Dashboard | `GET /api/clients/[id]/dashboard` | M | Full | ClientDashboardScreen |
| 4.5 | Client Measurements | `GET/POST/PUT/DELETE /api/clients/[id]/measurements` | M | Full | MeasurementsScreen |
| 4.6 | Client Progress Photos | `GET/POST/DELETE /api/clients/[id]/photos` | M | Full | ProgressPhotosScreen |
| 4.7 | Client Assessments | `GET/POST /api/clients/[id]/assessments`, `PUT/DELETE .../[resultId]` | M | Full | AssessmentsScreen |
| 4.8 | Client Exercise Logs | `POST /api/clients/[id]/exercise-logs` | S | Full | ExerciseLogScreen |
| 4.9 | Client Sessions | `GET /api/clients/[id]/sessions` | S | Full | ClientSessionsScreen |
| 4.10 | Active Session View | `GET /api/clients/[id]/session/active` | S | Full | ClientActiveSessionScreen |
| 4.11 | Active Program View | `GET /api/clients/[id]/program/active` | S | Full | ClientProgramScreen |
| 4.12 | Client Invite | `POST /api/clients/invite` | S | Live | InviteClientScreen |
| 4.13 | Client Link Request | `POST /api/clients/request-link` | S | Live | LinkClientScreen |
| 4.14 | Client Avatar | `POST/DELETE /api/clients/[id]/avatar` | S | Full | ClientDetailScreen |
| 4.15 | Client Insights (AI) | `POST /api/clients/[id]/insights` | S | Live | ClientInsightsScreen |
| 4.16 | Client Packages | `GET /api/clients/[id]/packages` | S | Full | ClientPackagesScreen |
| 4.17 | Client Sharing | `GET/PUT /api/client/sharing` | S | Full | SharingSettingsScreen |
| 4.18 | Upload Photo | `POST /api/client/upload` | S | Live | (image picker) |
| 4.19 | Client Statistics | `GET /api/client/statistics` | S | Full | ClientStatsScreen |
| 4.20 | Client Analytics | `GET /api/client/analytics` | M | Full | ClientAnalyticsScreen |

#### Endpoints Consumed (24+)

- `GET /api/clients` — List with search (`search`, `sortBy`, `sortOrder`)
- `POST /api/clients` — Create placeholder client
- `GET /api/clients/[id]` — Client detail
- `PUT /api/clients/[id]` — Update client
- `DELETE /api/clients/[id]` — Soft-delete client
- `GET /api/clients/[id]/dashboard` — Trainer view of client dashboard
- `GET /api/clients/[id]/measurements` — List measurements
- `POST /api/clients/[id]/measurements` — Create measurement
- `PUT /api/clients/[id]/measurements/[measurementId]` — Update measurement
- `DELETE /api/clients/[id]/measurements/[measurementId]` — Delete measurement
- `GET /api/clients/[id]/photos` — List progress photos (paginated)
- `POST /api/clients/[id]/photos` — Upload progress photo (multipart)
- `DELETE /api/clients/[id]/photos/[photoId]` — Delete photo
- `GET /api/clients/[id]/assessments` — List assessment results
- `POST /api/clients/[id]/assessments` — Create assessment result
- `PUT /api/clients/[id]/assessments/[resultId]` — Update result
- `DELETE /api/clients/[id]/assessments/[resultId]` — Delete result
- `POST /api/clients/[id]/exercise-logs` — Create exercise log (trainer enters)
- `GET /api/clients/[id]/sessions` — List sessions (paginated)
- `PUT /api/clients/[id]/sessions/[sessionId]` — Update session
- `DELETE /api/clients/[id]/sessions/[sessionId]` — Delete session
- `GET /api/clients/[id]/session/active` — Get active session
- `GET /api/clients/[id]/program/active` — Get active program + progress
- `POST /api/clients/[id]/insights` — Generate AI insights
- `POST /api/clients/[id]/avatar` — Upload avatar (multipart)
- `DELETE /api/clients/[id]/avatar` — Remove avatar
- `GET /api/clients/[id]/packages` — List client packages
- `POST /api/clients/invite` — Invite client by email
- `POST /api/clients/request-link` — Request link to existing user
- `GET /api/client/sharing` — Get sharing settings
- `PUT /api/client/sharing` — Update sharing settings
- `POST /api/client/upload` — Upload image file
- `GET /api/client/statistics` — Client statistics
- `GET /api/client/analytics` — Heatmap, volume history, muscle distribution, PRs, consistency

#### Implementation Notes

- Client list supports search, sorting by name/email/status/checkIn
- Client statuses: `active`, `inactive`, `lead`, `pending`
- Measurements track: weight, body fat %, chest/waist/hip/arm/thigh circumferences
- Progress photos use multipart upload, stored in Supabase storage
- Assessments are custom tests defined by trainer (sit & reach, flexibility, etc.)
- Client invite sends email with registration link containing trainerId
- Link request connects to existing Ziro Fit users
- Analytics endpoint provides heatmap dates, volume history, muscle distribution, recent PRs, consistency score

---

### Group 5: Trainer Profile (P0)

**Priority:** P0 — Launch Critical
**Role:** `trainer`
**Effort:** L (2–3 weeks)
**Sync:** Partially synced
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 5.1 | Profile Core Info | `GET/PUT /api/profile/me/core-info` | S | Full | EditProfileScreen |
| 5.2 | Profile Photo | `POST/DELETE /api/profile/me/avatar` | S | Full | EditProfileScreen |
| 5.3 | Text Content (about, philosophy, etc.) | `GET/PUT /api/profile/me/text-content` | S | Full | EditProfileScreen |
| 5.4 | Branding | `GET/PUT /api/profile/me/branding` | S | Full | EditProfileScreen |
| 5.5 | Services CRUD | `GET/POST /api/profile/me/services`, `PUT/DELETE .../[serviceId]` | M | Full | ServicesScreen |
| 5.6 | Packages CRUD | `GET/POST /api/profile/me/packages`, `PUT/DELETE .../[packageId]` | M | Full | PackagesScreen |
| 5.7 | Testimonials CRUD | `GET/POST /api/profile/me/testimonials`, `PUT/DELETE .../[testimonialId]` | M | Full | TestimonialsScreen |
| 5.8 | Benefits CRUD | `GET/POST /api/profile/me/benefits`, `PUT/DELETE .../[benefitId]` | M | Full | BenefitsScreen |
| 5.9 | Benefit Reorder | `PUT /api/profile/me/benefits/order` | S | Full | BenefitsScreen |
| 5.10 | Social Links CRUD | `GET/POST /api/profile/me/social-links`, `PUT/DELETE .../[linkId]` | S | Full | SocialLinksScreen |
| 5.11 | External Links CRUD | `GET/POST /api/profile/me/external-links`, `PUT/DELETE .../[linkId]` | S | Full | ExternalLinksScreen |
| 5.12 | Transformation Photos CRUD | `GET/POST /api/profile/me/transformation-photos`, `DELETE .../[photoId]` | M | Full | TransformationPhotosScreen |
| 5.13 | Availability Settings | `GET /api/profile/me/availability` | M | Full | AvailabilityScreen |
| 5.14 | Custom Exercises | `GET/POST /api/profile/me/exercises`, `PUT/DELETE .../[exerciseId]` | S | Full | CustomExercisesScreen |
| 5.15 | Full Profile | `GET /api/profile/me` | S | Full | ProfileScreen |
| 5.16 | Completion Score | Derived from `profile.completionPercentage` | XS | Full | ProfileScreen (indicator) |

#### Endpoints Consumed (20+)

- `GET /api/profile/me` — Full profile with all sub-resources
- `GET/PUT /api/profile/me/core-info` — Name, phone, location, specialties
- `POST/DELETE /api/profile/me/avatar` — Profile photo management
- `GET/PUT /api/profile/me/text-content` — About, philosophy, methodology, branding
- `GET/PUT /api/profile/me/branding` — Branding content
- `GET/POST /api/profile/me/services` — List/create services
- `PUT/DELETE /api/profile/me/services/[serviceId]` — Update/delete service
- `GET/POST /api/profile/me/packages` — List/create packages
- `PUT/DELETE /api/profile/me/packages/[packageId]` — Update/delete package
- `GET/POST /api/profile/me/testimonials` — List/create testimonials
- `PUT/DELETE /api/profile/me/testimonials/[testimonialId]` — Update/delete testimonial
- `GET/POST /api/profile/me/benefits` — List/create benefits
- `PUT/DELETE /api/profile/me/benefits/[benefitId]` — Update/delete benefit
- `PUT /api/profile/me/benefits/order` — Reorder benefits
- `GET/POST /api/profile/me/social-links` — List/create social links
- `PUT/DELETE /api/profile/me/social-links/[linkId]` — Update/delete
- `GET/POST /api/profile/me/external-links` — List/create external links
- `PUT/DELETE /api/profile/me/external-links/[linkId]` — Update/delete
- `GET/POST /api/profile/me/transformation-photos` — List/create photos
- `DELETE /api/profile/me/transformation-photos/[photoId]` — Delete photo
- `GET /api/profile/me/availability` — Get availability schedule
- `GET/POST /api/profile/me/exercises` — List/create custom exercises
- `PUT/DELETE /api/profile/me/exercises/[exerciseId]` — Update/delete

#### Implementation Notes

- Profile completion percentage calculated server-side via `missingFields`
- Services have: title, description, price, currency, duration (minutes)
- Packages group services into bundles with pricing
- Testimonials: client name, text, rating (1–5)
- Social links typed by platform (Instagram, YouTube, TikTok, etc.)
- External links are custom URL + label
- Availability is JSON map: `{"mon": ["09:00-17:00"], "tue": [...]}`
- Transformation photos are before/after style with caption and client name
- Benefits have icon, title, description, and sortable order
- Custom exercises are trainer-specific, supplement the system exercise library

---

### Group 6: Programs & Templates (P1)

**Priority:** P1 — Important
**Role:** `trainer`, `client`
**Effort:** L (2–3 weeks)
**Sync:** Fully synced
**Dependencies:** Exercise Library (Group 7)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 6.1 | Program List | `GET /api/trainer/programs` | M | Full | ProgramsListScreen |
| 6.2 | Create Program | `POST /api/trainer/programs` | S | Full | CreateProgramScreen |
| 6.3 | Template Detail | `GET /api/workout-templates/[id]` | S | Full | TemplateDetailScreen |
| 6.4 | Template CRUD | `POST /api/trainer/programs/templates`, `GET ...` | M | Full | TemplateDetailScreen |
| 6.5 | Template Exercises | `POST/DELETE /api/trainer/programs/templates/[id]/exercises/...` | M | Full | TemplateExerciseScreen |
| 6.6 | Template Rest Steps | `POST /api/trainer/programs/templates/[id]/rest` | S | Full | TemplateExerciseScreen |
| 6.7 | Copy System Template | `POST /api/trainer/programs/templates/[id]/copy` | S | Full | TemplateLibraryScreen |
| 6.8 | Client Programs | `GET /api/client/programs` | S | Full | ClientProgramsScreen |
| 6.9 | Assign Program to Client | `POST /api/trainer/clients/[id]/assign-program` | S | Full | AssignProgramScreen |
| 6.10 | Active Program (Client) | `GET /api/client/program/active`, `PUT ...` | S | Full | ActiveProgramScreen |
| 6.11 | AI Program Generation | `POST /api/client/programs` | M | Live | AIGenerateProgramScreen |

#### Endpoints Consumed (12+)

- `GET /api/trainer/programs` — List programs + templates (supports `lightweight` mode)
- `POST /api/trainer/programs` — Create program
- `GET /api/workout-templates/[id]` — Template with exercises
- `GET /api/trainer/programs/templates` — List templates
- `POST /api/trainer/programs/templates` — Create template
- `POST /api/trainer/programs/templates/[templateId]/exercises` — Add exercise
- `DELETE /api/trainer/programs/templates/[templateId]/exercises/[exerciseStepId]` — Remove exercise
- `POST /api/trainer/programs/templates/[templateId]/rest` — Add rest step
- `POST /api/trainer/programs/templates/[templateId]/copy` — Copy system template
- `POST /api/trainer/clients/[id]/assign-program` — Assign to client
- `GET /api/client/programs` — Client's program assignments
- `POST /api/client/programs` — AI generate program
- `GET /api/client/program/active` — Client active program + progress
- `PUT /api/client/program/active` — Set active program

#### Implementation Notes

- Programs contain templates, templates contain exercises + rest steps
- Template exercises support: target reps (string like "8-12"), target RIR, tempo, RPE toggle, superset groups
- Superset groups use `supersetGroupId` (e.g., "A1", "B1") and `supersetOrder`
- Lightweight mode returns only templates (for calendar picker)
- Copy system template creates a personal copy the trainer can modify
- AI program generation creates a program based on duration and focus
- Client program progress tracks: completed count, total count, percentage, next template

---

### Group 7: Exercise Library (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Fully synced
**Dependencies:** None (standalone)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 7.1 | Exercise List | `GET /api/exercises` | M | Full | ExerciseLibraryScreen |
| 7.2 | Exercise Search | `GET /api/exercises?search=...` | S | Full | ExerciseLibraryScreen |
| 7.3 | Exercise Media | `GET /api/exercises/find-media` | S | Live | ExerciseDetailScreen |
| 7.4 | Exercise Sync | `GET /api/exercises/sync` | S | Full | (sync engine) |

#### Endpoints Consumed (3)

- `GET /api/exercises` — Paginated search (`search`, `limit`, `page`)
- `GET /api/exercises/find-media` — AI-generated/found media URL by exercise name
- `GET /api/exercises/sync` — Changed exercises since timestamp (offline sync)

#### Implementation Notes

- System exercises + trainer's custom exercises merged in results
- Fields: name, muscleGroup, equipment, category, videoUrl, description
- Full-text search across name, muscle group, equipment
- Paginated with `page` + `hasMore`
- Exercise sync supports offline-first: pull changes since `lastPulledAt`
- Exercise media uses AI generation for exercise illustrations
- Custom exercises can be created via profile/me/exercises endpoints

---

### Group 8: Calendar & Scheduling (P1)

**Priority:** P1 — Important
**Role:** `trainer`
**Effort:** L (2–3 weeks)
**Sync:** Partially synced
**Dependencies:** Client Management (Group 4), Programs & Templates (Group 6)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 8.1 | Calendar View | `GET /api/trainer/calendar` | L | Partial | CalendarScreen |
| 8.2 | Create Planned Session | `POST /api/trainer/calendar` | M | Partial | CreateSessionScreen |
| 8.3 | Update/Delete Planned Session | `PUT/DELETE /api/trainer/calendar/[sessionId]` | S | Partial | EditSessionScreen |
| 8.4 | Send Reminder | `POST /api/trainer/calendar/sessions/[sessionId]/remind` | XS | Live | CalendarScreen (action) |
| 8.5 | Clients Summary | `GET /api/trainer/calendar/clients-summary` | S | Partial | CalendarScreen (sidebar) |
| 8.6 | Session Creation Data | `GET /api/trainer/session-creation-data` | S | Live | CreateSessionScreen |

#### Endpoints Consumed (6)

- `GET /api/trainer/calendar` — Unified calendar (`startDate`, `endDate`)
- `POST /api/trainer/calendar` — Create planned sessions (with recurrence)
- `PUT /api/trainer/calendar/[sessionId]` — Reschedule planned session
- `DELETE /api/trainer/calendar/[sessionId]` — Delete planned session
- `POST /api/trainer/calendar/sessions/[sessionId]/remind` — Send reminder notification
- `GET /api/trainer/calendar/clients-summary` — Client identity data for calendar dates
- `GET /api/trainer/session-creation-data` — Clients + templates for session creation form

#### Implementation Notes

- Calendar returns unified view: workout sessions + bookings
- Recurrence: `repeats`, `repeatWeeks`, `repeatDays[]`, `clientStartDay`
- Conflict detection for overlapping sessions
- Clients summary returns which clients have sessions on which dates (lightweight)
- Session creation data preloads clients list + templates for the form

---

### Group 9: Check-Ins (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Fully synced
**Dependencies:** Client Management (Group 4)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 9.1 | Submit Check-In (Client) | `POST /api/client/check-in` | M | Full | SubmitCheckInScreen |
| 9.2 | Client Check-Ins List | `GET /api/client/check-ins` | S | Full | ClientCheckInsScreen |
| 9.3 | Check-In Config | `GET /api/client/check-in/config` | S | Full | SubmitCheckInScreen |
| 9.4 | Trainer Check-Ins List | `GET /api/trainer/check-ins` | M | Full | CheckInsListScreen |
| 9.5 | Pending Check-Ins | `GET /api/trainer/check-ins/pending` | S | Full | CheckInsListScreen (tab) |
| 9.6 | Check-In Detail with Trends | `GET /api/trainer/check-ins/[id]` | M | Full | CheckInDetailScreen |
| 9.7 | Review Check-In | `PATCH /api/trainer/check-ins/[id]/review` | S | Full | CheckInDetailScreen |
| 9.8 | Delete Check-In | `DELETE /api/trainer/check-ins/[id]` | XS | Full | CheckInDetailScreen |

#### Endpoints Consumed (8)

- `POST /api/client/check-in` — Submit check-in with metrics + optional photos
- `GET /api/client/check-ins` — List client's check-ins
- `GET /api/client/check-ins/[id]` — Get/delete client's check-in
- `GET /api/client/check-in/config` — Get check-in configuration
- `GET /api/trainer/check-ins` — Filtered by status (`SUBMITTED`/`REVIEWED`)
- `GET /api/trainer/check-ins/pending` — All pending check-ins
- `GET /api/trainer/check-ins/[id]` — Detail with trends (last 4 check-ins)
- `PATCH /api/trainer/check-ins/[id]/review` — Submit trainer response
- `DELETE /api/trainer/check-ins/[id]` — Delete check-in

#### Implementation Notes

- Check-in metrics: weight, waist, sleep hours, energy/stress/hunger/digestion levels (1-5/1-10), nutrition compliance
- Optional progress photos attached to check-in
- Auto-creates ClientMeasurement entry when weight provided
- Trainer review transitions status from `SUBMITTED` to `REVIEWED`
- Trends show last 4 check-ins for comparison
- Pending endpoint is shortcut for trainer's un-reviewed check-ins
- Check-in reminders sent via cron (server-side), but Flutter should show badge

---

### Group 10: Bookings (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Partially synced
**Dependencies:** Calendar & Scheduling (Group 8), Notifications (Group 12)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 10.1 | Create Booking (Client) | `POST /api/bookings` | M | Live | CreateBookingScreen |
| 10.2 | Booking List (Trainer) | `GET /api/bookings` | S | Partial | BookingsListScreen |
| 10.3 | Confirm Booking | `PUT /api/bookings/[bookingId]/confirm` | S | Live | BookingDetailScreen |
| 10.4 | Decline Booking | `PUT /api/bookings/[bookingId]/decline` | XS | Live | BookingDetailScreen |
| 10.5 | Client Event Bookings | `GET /api/client/events` | S | Partial | ClientEventsScreen |
| 10.6 | Cancel Event Booking | `PUT /api/client/events/[bookingId]/cancel` | XS | Live | ClientEventsScreen |

#### Endpoints Consumed (6)

- `GET /api/bookings` — List all bookings (trainer)
- `POST /api/bookings` — Create booking request (client)
- `PUT /api/bookings/[bookingId]/confirm` — Accept booking
- `PUT /api/bookings/[bookingId]/decline` — Reject booking
- `GET /api/client/events` — Client's event bookings
- `PUT /api/client/events/[bookingId]/cancel` — Cancel event booking

#### Implementation Notes

- Booking automatically links client to trainer if not already linked
- Time conflict detection on creation
- `dataSharingApproved` flag on confirm enables sharing settings
- Client can cancel their own bookings
- Bookings appear in trainer's calendar view

---

### Group 11: Public Events (P1)

**Priority:** P1 — Important
**Role:** `public`, `client`, `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Live only (public data)
**Dependencies:** None (standalone)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 11.1 | Events List | `GET /api/events` | M | Live | EventsListScreen |
| 11.2 | Event Detail | `GET /api/events/[id]` | S | Live | EventDetailScreen |
| 11.3 | Join Free Event | `POST /api/events/[id]/join` | S | Live | EventDetailScreen |
| 11.4 | Create Event (Trainer) | `POST /api/trainer/events` | M | Live | CreateEventScreen |
| 11.5 | Edit/Delete Event (Trainer) | `PUT/DELETE /api/trainer/events/[id]` | S | Live | EditEventScreen |
| 11.6 | Trainer Events List | `GET /api/trainer/events` | S | Live | TrainerEventsScreen |
| 11.7 | Upload Event Image | `POST /api/trainer/events/upload` | S | Live | CreateEventScreen |

#### Endpoints Consumed (7)

- `GET /api/events` — Public event listing (paginated, filterable)
- `GET /api/events/[id]` — Event detail (optional auth for booking status)
- `POST /api/events/[id]/join` — Join free event
- `GET /api/trainer/events` — Trainer's own events
- `POST /api/trainer/events` — Create event
- `PUT /api/trainer/events/[id]` — Update event
- `DELETE /api/trainer/events/[id]` — Delete event
- `POST /api/trainer/events/upload` — Upload event image (multipart)

#### Implementation Notes

- Events have: title, description, start/end time, location, price, capacity, category, image
- Filters: search, category, isFree, sortBy, lat/lon proximity
- Event requires admin approval (status: PENDING → APPROVED)
- Paid events use Stripe checkout (via checkout endpoint)
- Trainer events list shows their created events with enrollment counts

---

### Group 12: Notifications (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** S (3–5 days)
**Sync:** Partially synced
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 12.1 | Notification List | `GET /api/notifications` | S | Partial | NotificationsScreen |
| 12.2 | Mark Read | `PUT /api/notifications/[id]` | XS | Live | NotificationsScreen |
| 12.3 | Push Token Registration | `POST /api/profile/me/push-token` | S | Live | (background) |
| 12.4 | Push Notifications | FCM integration | M | Live | (system) |

#### Endpoints Consumed (3)

- `GET /api/notifications` — Last 50 notifications (newest first)
- `PUT /api/notifications/[id]` — Mark as read
- `POST /api/profile/me/push-token` — Register FCM push token

#### Implementation Notes

- Notifications types: session reminders, check-in reminders, booking requests, link requests, system
- Notification has: type, message, readStatus, createdAt, metadata
- Push tokens stored on user record for server-side FCM dispatch
- Badge count derived from unread notifications
- Pull-to-refresh fetches latest notifications

---

### Group 13: Chat (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Partially synced
**Dependencies:** Client Management (Group 4)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 13.1 | Conversation List | (derived from clients list) | S | Partial | ConversationsListScreen |
| 13.2 | Message History | `GET /api/chat` | M | Partial | ChatScreen |
| 13.3 | Send Message | `POST /api/chat` | M | Partial | ChatScreen |
| 13.4 | Media in Chat | `POST /api/chat` (mediaUrl) | S | Live | ChatScreen |
| 13.5 | AI Coach Chat | `GET/POST /api/chat` (AI trainer ID) | M | Live | AIChatScreen |

#### Endpoints Consumed (2)

- `GET /api/chat` — Get conversation messages (`clientId`, `trainerId`)
- `POST /api/chat` — Send message (`clientId`, `content`, `senderId`, `trainerId`, `mediaUrl`, `mediaType`)

#### Implementation Notes

- Chat is between trainer and client (one conversation per pair)
- AI coach is a special trainer ID for AI-powered chat
- Messages support: text, image, video (mediaUrl + mediaType)
- System messages for workout completions, etc.
- Read receipts tracked server-side
- No real-time socket — uses polling or pull-to-refresh for new messages

---

### Group 14: Billing & Packages (P2)

**Priority:** P2 — Nice to Have
**Role:** `trainer`, `client`, `admin`
**Effort:** M (1–2 weeks)
**Sync:** Live only (payment processing)
**Dependencies:** Trainer Profile — Packages (Group 5.6), Stripe integration

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 14.1 | Package Management (Trainer) | (see Group 5.6) | S | Full | PackagesScreen |
| 14.2 | Client Package Tracking | `GET /api/clients/[id]/packages` | S | Full | ClientPackagesScreen |
| 14.3 | Stripe Checkout | `POST /api/checkout/session` | M | Live | CheckoutScreen |
| 14.4 | Subscription Status | `GET /api/billing/subscription` | S | Live | SubscriptionScreen |
| 14.5 | Subscribe New | `POST /api/billing/subscribe-new` | S | Live | SubscriptionScreen |
| 14.6 | Subscription Management | `POST/PATCH /api/billing/subscription` | S | Live | SubscriptionScreen |
| 14.7 | Billing Portal | `POST /api/billing/portal` | XS | Live | SubscriptionScreen |
| 14.8 | Stripe Webhook Handler | `POST /api/webhooks/stripe` | — | — | (server-side) |

#### Endpoints Consumed (6+)

- `GET /api/clients/[id]/packages` — Client's assigned/purchased packages
- `POST /api/checkout/session` — Create Stripe checkout session
- `GET /api/billing/subscription` — Current subscription info
- `POST /api/billing/subscription` — Subscribe to new tier
- `PATCH /api/billing/subscription` — Cancel/resume/change tier
- `POST /api/billing/subscribe-new` — New subscription with trial
- `POST /api/billing/portal` — Stripe billing portal URL

#### Implementation Notes

- Checkout types: `PACKAGE_SALE`, `EVENT_TICKET`
- Subscription tiers: STARTER (free), PRO (€29/mo), ELITE (higher tier)
- Trial period: 30 days for new subscriptions
- Stripe Connect for trainer payouts
- Billing portal for invoice history, payment method management
- Webhook handles: checkout.session.completed, subscription created/updated/deleted

---

### Group 15: Nutrition (P2)

**Priority:** P2 — Nice to Have
**Role:** `trainer`
**Effort:** M (1–2 weeks)
**Sync:** Partially synced
**Dependencies:** None (standalone)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 15.1 | Recipe List | `GET /api/trainer/recipes` | S | Partial | RecipesListScreen |
| 15.2 | Recipe Detail | `GET /api/trainer/recipes/[id]` | S | Partial | RecipeDetailScreen |
| 15.3 | Create Recipe | `POST /api/trainer/recipes` | S | Partial | CreateRecipeScreen |
| 15.4 | Update Recipe | `PUT /api/trainer/recipes/[id]` | S | Partial | EditRecipeScreen |
| 15.5 | Delete Recipe | `DELETE /api/trainer/recipes/[id]` | XS | Partial | RecipesListScreen |

#### Endpoints Consumed (5)

- `GET /api/trainer/recipes` — List recipes
- `POST /api/trainer/recipes` — Create recipe (with tags + products)
- `GET /api/trainer/recipes/[id]` — Recipe detail
- `PUT /api/trainer/recipes/[id]` — Update recipe
- `DELETE /api/trainer/recipes/[id]` — Delete recipe

#### Implementation Notes

- Recipe fields: name, description, instructions, macros (protein, carbs, fat), calories
- Difficulty levels, prep time, cook time
- Tags for categorization (breakfast, lunch, dinner, snack)
- Products with brand, amount, recommended flag
- Recipes are trainer-owned, not client-facing in v1 (client view is P3)

---

### Group 16: Habits (P2)

**Priority:** P2 — Nice to Have
**Role:** `client`, `trainer`
**Effort:** S (3–5 days)
**Sync:** Fully synced
**Dependencies:** Client Management (Group 4), Check-Ins (Group 9)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 16.1 | Client Habit List | `GET /api/client/habits` | S | Full | HabitsScreen |
| 16.2 | Log Habit | `POST /api/client/habits/[habitId]/log` | S | Full | HabitsScreen |
| 16.3 | Trainer View Client Habits | `GET /api/trainer/clients/[id]/habits` | S | Full | ClientHabitsScreen |
| 16.4 | Assign Habit (Trainer) | `POST /api/trainer/clients/[id]/habits` | S | Full | AssignHabitScreen |

#### Endpoints Consumed (4)

- `GET /api/client/habits` — Client's active habits with logs
- `POST /api/client/habits/[habitId]/log` — Log completion (`date`, `isCompleted`, `note`)
- `GET /api/trainer/clients/[id]/habits` — Trainer view of client habits
- `POST /api/trainer/clients/[id]/habits` — Create habit for client

#### Implementation Notes

- Habit fields: title, description, frequency (DAILY/WEEKLY)
- Log entries: date, isCompleted, optional note
- Habits are assigned by trainer to client
- Client logs completion daily/weekly
- Progress tracked via log count over time

---

### Group 17: Resource Vault (P2)

**Priority:** P2 — Nice to Have
**Role:** `trainer`, `client`
**Effort:** S (3–5 days)
**Sync:** Partially synced
**Dependencies:** Client Management (Group 4)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 17.1 | Resource List (Trainer) | `GET /api/trainer/resource-vault` | S | Partial | ResourceVaultScreen |
| 17.2 | Resource CRUD | Trainer resource-vault endpoints | M | Partial | ResourceVaultScreen |
| 17.3 | Client Resources | `GET /api/client/resource-vault` | S | Partial | ClientResourcesScreen |
| 17.4 | Assign Resources | Trainer resource-vault assign endpoints | S | Live | ResourceAssignmentScreen |

#### Endpoints Consumed (4+)

- `GET /api/trainer/resource-vault` — List trainer's resources
- Trainer resource-vault CRUD endpoints
- `POST /api/trainer/resource-vault/[id]/assign` — Assign to client
- `GET /api/client/resource-vault` — Client's assigned resources

#### Implementation Notes

- Resources are files, documents, PDFs, videos shared by trainer
- Trainer uploads resources, assigns to specific clients
- Client sees only assigned resources
- Resources stored in Supabase storage

---

### Group 18: Social/Explore (P2)

**Priority:** P2 — Nice to Have
**Role:** `public`, `client`
**Effort:** M (1–2 weeks)
**Sync:** Live only (public discovery)
**Dependencies:** Trainer Profile (Group 5)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 18.1 | Trainer Search/Discovery | `GET /api/trainers` | S | Live | ExploreScreen |
| 18.2 | Trainer Public Profile | `GET /api/trainers/[username]` | M | Live | PublicTrainerProfileScreen |
| 18.3 | Public Trainer (Lightweight) | `GET /api/trainers/[username]/public` | S | Live | PublicTrainerProfileScreen |
| 18.4 | Trainer Specialties | `GET /api/trainers/specialties` | S | Live | ExploreScreen (filter) |
| 18.5 | Trainer Schedule (Public) | `GET /api/trainers/[username]/schedule` | S | Live | PublicTrainerProfileScreen |
| 18.6 | Trainer Packages (Public) | `GET /api/trainers/[username]/packages` | S | Live | PublicTrainerProfileScreen |
| 18.7 | Trainer Testimonials (Public) | `GET /api/trainers/[username]/testimonials` | S | Live | PublicTrainerProfileScreen |
| 18.8 | Trainer Transformation Photos | `GET /api/trainers/[username]/transformation-photos` | S | Live | PublicTrainerProfileScreen |
| 18.9 | Explore Featured | `GET /api/explore/featured` | S | Live | ExploreScreen |
| 18.10 | Explore Events | `GET /api/explore/events` | S | Live | ExploreScreen (events tab) |
| 18.11 | Explore Metadata | `GET /api/explore/metadata` | S | Live | ExploreScreen (filters) |

#### Endpoints Consumed (11)

- `GET /api/trainers` — Search trainers
- `GET /api/trainers/[username]` — Full public profile
- `GET /api/trainers/[username]/public` — Lightweight public profile
- `GET /api/trainers/specialties` — Specialties list for filtering
- `GET /api/trainers/[username]/schedule` — Public availability
- `GET /api/trainers/[username]/packages` — Public packages
- `GET /api/trainers/[username]/testimonials` — Public testimonials
- `GET /api/trainers/[username]/transformation-photos` — Public transformation photos
- `GET /api/explore/featured` — Featured trainers + events
- `GET /api/explore/events` — Explore events (paginated)
- `GET /api/explore/metadata` — Cities + categories for filters

#### Implementation Notes

- Explore is public (no auth required for most endpoints)
- Optional auth provides `isLinked` status for logged-in clients
- Featured endpoint returns curated trainers and events
- Metadata endpoint provides city/category filter options (cached 1 hour)
- Trainer public profile aggregates: about, philosophy, services, packages, testimonials, availability, links
- `isLinked` field tells client if they're already connected

---

### Group 19: AI Features (P3)

**Priority:** P3 — Future
**Role:** `client`, `trainer`
**Effort:** L (3–4 weeks)
**Sync:** Live only (AI processing)
**Dependencies:** Workout Management (Group 3), Exercise Library (Group 7)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 19.1 | AI Coach Session | `GET/POST /api/ai-trainer/session` | L | Live | AICoachScreen |
| 19.2 | AI Voice Trainer | `POST /api/ai-trainer/voice` | L | Live | AICoachScreen (voice mode) |
| 19.3 | AI Workout Generation | `POST /api/client/ai/generate` | M | Live | AIGenerateScreen |
| 19.4 | AI Client Insights | `POST /api/clients/[id]/insights` | S | Live | ClientInsightsScreen |
| 19.5 | AI Coach Generate (Mobile) | `POST /api/mobile/ai-coach/generate` | M | Live | AICoachSetupScreen |
| 19.6 | AI Coach Refine | `POST /api/mobile/ai-coach/refine` | S | Live | AICoachSetupScreen |

#### Endpoints Consumed (6)

- `GET /api/ai-trainer/session` — Get AI trainer session status
- `POST /api/ai-trainer/session` — Send action (start, next, rest_end, status)
- `POST /api/ai-trainer/voice` — Process voice input (audio base64 or file)
- `POST /api/client/ai/generate` — Generate AI workout plan
- `POST /api/mobile/ai-coach/generate` — AI program from goal
- `POST /api/mobile/ai-coach/refine` — Refine AI coach goal

#### Implementation Notes

- AI trainer coaches through workouts: announces next exercise, tracks sets, manages rest
- Voice input processed server-side: speech-to-text → action parsing → response with audio
- AI workout generation creates personalized programs based on goals and metrics
- AI client insights analyze performance trends and suggest improvements
- AI coach responses include text + optional audio (base64-encoded)
- All AI features are real-time and require network connectivity

---

### Group 20: Trainer Settings (P1)

**Priority:** P1 — Important
**Role:** `trainer`
**Effort:** S (3–5 days)
**Sync:** Partially synced
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 20.1 | Settings View | `GET /api/trainer/settings` | S | Partial | SettingsScreen |
| 20.2 | Check-In Defaults | Part of settings/user profile | S | Full | SettingsScreen |
| 20.3 | Weight Unit | Part of user profile (`weightUnit`) | XS | Full | SettingsScreen |
| 20.4 | Push Token Management | `POST /api/profile/me/push-token` | XS | Live | SettingsScreen |
| 20.5 | Payment Setup (Stripe Connect) | `GET /api/profile/me/billing` | S | Live | PaymentSetupScreen |

#### Endpoints Consumed (3)

- `GET /api/trainer/settings` — Trainer-specific settings
- `POST /api/profile/me/push-token` — Register FCM token
- `GET /api/profile/me/billing` — Billing/stripe connect info

#### Implementation Notes

- Trainer settings include: check-in defaults (day + hour), notification preferences
- Weight unit (KG/LB) stored on user record, used across all measurement displays
- Stripe Connect account ID for payouts
- Settings are minimal — most configuration is part of trainer profile

---

### Group 21: Admin Panel (P3)

**Priority:** P3 — Future
**Role:** `admin`
**Effort:** L (3–4 weeks)
**Sync:** Live only
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 21.1 | Platform Stats | `GET /api/admin/stats` | S | Live | AdminDashboardScreen |
| 21.2 | Event Moderation | `GET /api/admin/events`, `GET/PATCH /api/admin/events/[id]` | M | Live | AdminEventsScreen |
| 21.3 | Blog CRUD | `GET/POST /api/admin/blog`, `GET/PUT/DELETE /api/admin/blog/[id]` | M | Live | AdminBlogScreen |
| 21.4 | Support Tickets | `GET /api/admin/tickets`, `PATCH/DELETE /api/admin/tickets/[id]` | M | Live | AdminSupportScreen |
| 21.5 | Admin Upload | `POST /api/admin/upload` | S | Live | AdminUploadScreen |

#### Endpoints Consumed (11)

- `GET /api/admin/stats` — Platform statistics
- `GET /api/admin/events` — Pending events list
- `GET /api/admin/events/[id]` — Event moderation detail
- `PATCH /api/admin/events/[id]` — Approve/reject event
- `GET /api/admin/blog` — All blog posts (paginated)
- `POST /api/admin/blog` — Create blog post
- `GET /api/admin/blog/[id]` — Get post
- `PUT /api/admin/blog/[id]` — Update post
- `DELETE /api/admin/blog/[id]` — Delete post
- `GET /api/admin/tickets` — Support tickets (paginated, filterable)
- `PATCH /api/admin/tickets/[id]` — Update ticket status
- `DELETE /api/admin/tickets/[id]` — Delete ticket
- `POST /api/admin/upload` — Upload file

#### Implementation Notes

- Admin panel is P3 — will be built in v2.0+
- Mobile-first admin UI for quick moderation on-the-go
- Blog supports markdown content with cover images
- Event moderation: approve or reject with rejection reason
- Support ticket categories: bug_report, feature_request, general_support
- Stats show: total users, trainers, clients, admins, feature flags

---

### Group 22: System/Config (P1)

**Priority:** P1 — Important
**Role:** `public`
**Effort:** XS (1 day)
**Sync:** Live only
**Dependencies:** None

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 22.1 | Feature Flags | `GET /api/system/config` | XS | Live | App Startup |

#### Endpoints Consumed (1)

- `GET /api/system/config` — Public feature flags

#### Implementation Notes

- Called at app startup to determine available features
- Flags: `customDomains` (bool), `freeMode` (bool)
- Cached for session duration
- Controls visibility of certain UI elements

---

### Group 23: Offline Sync (P1)

**Priority:** P1 — Important
**Role:** `client`, `trainer`
**Effort:** L (2–3 weeks for engine)
**Sync:** N/A (the sync mechanism itself)
**Dependencies:** Auth & Onboarding (Group 1)

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 23.1 | Pull Sync | `GET /api/sync/pull` | L | — | (engine) |
| 23.2 | Push Sync | `POST /api/sync/push` | L | — | (engine) |
| 23.3 | Sync Status UI | — | S | — | SyncIndicator (widget) |
| 23.4 | Conflict Resolution | — | M | — | (engine) |

#### Endpoints Consumed (2)

- `GET /api/sync/pull` — Pull changes since `last_pulled_at` timestamp
- `POST /api/sync/push` — Push local changes (created/updated/deleted)

#### Synced Tables (Backend Sync Protocol — 17 tables)

| Sync Table Name | Prisma Model | Direction | Scope |
|----------------|-------------|-----------|-------|
| `clients` | Client | Bidirectional | Trainer's client records |
| `profiles` | Profile | Bidirectional | Own user profile (used by mobile) |
| `trainer_profiles` | Profile | Bidirectional | Trainer's professional profile |
| `workout_sessions` | WorkoutSession | Bidirectional | Sessions for trainer's clients |
| `exercises` | Exercise | Download-only | System exercises + custom trainer exercises |
| `workout_templates` | WorkoutTemplate | Bidirectional | Templates from trainer's programs |
| `client_assessments` | AssessmentResult | Bidirectional | Assessment results for clients |
| `client_measurements` | ClientMeasurement | Bidirectional | Body measurements for clients |
| `client_photos` | ClientProgressPhoto | Download-only | Progress photos (URLs, not binary) |
| `client_exercise_logs` | ClientExerciseLog | Bidirectional | Exercise log entries within sessions |
| `trainer_services` | Service | Bidirectional | Services on trainer's profile |
| `trainer_packages` | Package | Bidirectional | Session packages sold by trainer |
| `trainer_testimonials` | Testimonial | Bidirectional | Client testimonials |
| `trainer_programs` | WorkoutProgram | Bidirectional | Programs created by trainer |
| `calendar_events` | Booking | Bidirectional | Booked time slots |
| `notifications` | Notification | Download-only | User notifications |
| `bookings` | Booking | Bidirectional | Client booking requests |

**Wire Format:** All sync data uses snake_case keys. DateTime values are Unix ms integers. Soft deletes use `deleted_at`. See `OFFLINE_SYNC.md` for complete Drift schema.

#### Implementation Notes

- Sync engine runs: on app start, every 5 minutes while active, on pull-to-refresh
- Push queue: FIFO queue of offline mutations, flushed when online
- Conflict resolution: last-write-wins based on `updatedAt` timestamp
- Connectivity detection via `connectivity_plus`
- Sync status shown via StreamProvider (idle, syncing, error, lastSynced)
- Detailed sync architecture in `OFFLINE_SYNC.md` (see separate document)

---

### Group 24: Miscellaneous (P2)

**Priority:** P2 — Nice to Have
**Role:** various
**Effort:** S–M (1–2 weeks total)
**Sync:** Various

#### Features

| # | Feature | Endpoints | Effort | Sync | Key Screens |
|---|---------|-----------|--------|------|-------------|
| 24.1 | Contact Form | `POST /api/contact` | XS | Live | ContactScreen |
| 24.2 | Support Tickets | `POST /api/support/feedback` | S | Live | SupportScreen |
| 24.3 | Account Deletion | `DELETE /api/user/delete` | S | Live | AccountSettingsScreen |
| 24.4 | Custom Domains | `POST /api/domain/add`, `POST /api/domain/verify` | S | Live | DomainSettingsScreen |
| 24.5 | Blog (Public) | `GET /api/blog`, `GET /api/blog/[slug]` | M | Live | BlogListScreen, BlogPostScreen |
| 24.6 | Public Workout Summary | `GET /api/public/workout-summary/[sessionId]` | XS | Live | SharedWorkoutScreen |
| 24.7 | OpenAPI Spec | `GET /api/openapi` | — | — | (developer tool) |
| 24.8 | Pricing Plans | `GET /api/mobile/pricing` | S | Live | PricingScreen |
| 24.9 | Trainer Link Requests | `POST /api/trainer/link-requests/[id]/accept\|decline` | S | Live | LinkRequestsScreen |
| 24.10 | Client-Trainer Unlink | `DELETE /api/client/trainer`, `DELETE /api/client/trainer/link` | XS | Live | MyTrainerScreen |
| 24.11 | Client-Trainer Link Check | `GET /api/client/trainer/link` | XS | Live | MyTrainerScreen |
| 24.12 | Trainer Profile (General) | `GET /api/trainer/profile` | S | Full | TrainerProfileScreen |
| 24.13 | Trainer Clients (General) | `GET /api/trainer/clients` | S | Full | ClientsListScreen |

#### Endpoints Consumed (16+)

- `POST /api/contact` — Contact form submission (public)
- `POST /api/support/feedback` — Support ticket creation
- `DELETE /api/user/delete` — Account deletion
- `POST /api/domain/add` — Add custom domain to Vercel
- `POST /api/domain/verify` — Verify DNS configuration
- `GET /api/blog` — Published blog posts (paginated)
- `GET /api/blog/[slug]` — Single blog post
- `GET /api/public/workout-summary/[sessionId]` — Shared workout
- `GET /api/mobile/pricing` — Pricing plans
- `POST /api/trainer/link-requests/[notificationId]/accept` — Accept link request
- `POST /api/trainer/link-requests/[notificationId]/decline` — Decline link request
- `GET /api/client/trainer` — Get linked trainer
- `DELETE /api/client/trainer` — Unlink from trainer
- `GET /api/client/trainer/link` — Check link status
- `POST /api/client/trainer/link` — Send link request
- `DELETE /api/client/trainer/link` — Stop sharing with trainer

---

## 4. Implementation Phases

### Phase 1 (Weeks 1–3): Foundation — P0

**Goal:** Core infrastructure + Auth

| Week | Tasks | Deliverables |
|------|-------|-------------|
| 1 | Project scaffold, CI pipeline, architecture setup | `lib/` structure, `core/` layer, Dio setup, Drift setup |
| 1 | Data models (30+ Prisma → Dart), JSON serialization | All model files in `data/models/` |
| 2 | Auth system: login, register, OAuth, token refresh, auto-login | Auth screens, auth provider, auth interceptor |
| 2 | Secure storage, session restore, role-based routing | GoRouter with guards, auth state management |
| 3 | Offline sync engine (pull/push, local DB, queue) | Sync engine, Drift tables, pull/push data sources |
| 3 | Navigation shell (trainer + client + admin) | ShellRoute setup, bottom nav, role guards |

**Key files created:**
- `core/network/`, `core/database/`, `core/router/`, `core/theme/`
- `data/models/` (all models), `data/sync/` (engine)
- `features/auth/` (all screens + providers)

### Phase 2 (Weeks 4–7): Core Features — P0

**Goal:** Main user-facing features

| Week | Tasks | Deliverables |
|------|-------|-------------|
| 4 | Dashboard (trainer + client) | Dashboards, stats cards, upcoming list |
| 4 | Exercise Library | Exercise list/search, media view, sync |
| 5 | Workout Management (start, track, rest timer, finish) | Active workout screen, exercise logging |
| 5 | Workout history + summary | History list, summary screen, PR display |
| 6 | Client Management (list, detail, CRUD) | Client list, detail, add/edit screens |
| 6 | Client measurements + progress photos | Measurement charts, photo gallery |
| 7 | Trainer Profile (core info, services, packages) | Profile screen, edit screens |
| 7 | Check-Ins (submit + review) | Check-in form, review screen, trends |

### Phase 3 (Weeks 8–11): Enhanced Features — P1

**Goal:** Secondary but important features

| Week | Tasks | Deliverables |
|------|-------|-------------|
| 8 | Programs & Templates (CRUD) | Program list, template editor, exercise assignment |
| 8 | Template library + copy system | Template browser, copy flow |
| 9 | Calendar & Scheduling | Calendar view, create planned session, recurrence |
| 9 | Bookings (create, confirm, decline) | Booking screens, booking management |
| 10 | Notifications (list, mark read, push) | Notification screen, push setup |
| 10 | Chat (conversations, messages) | Chat screen, message list |
| 11 | Events (public + create, manage) | Event list/detail, create/edit event |
| 11 | Trainer Settings | Settings screen, check-in defaults |

### Phase 4 (Weeks 12–14): Extended Features — P2

**Goal:** Value-add features

| Week | Tasks | Deliverables |
|------|-------|-------------|
| 12 | Nutrition (recipes CRUD) | Recipe list, create/edit recipe |
| 12 | Habits (assign + log) | Habit list, log screen |
| 13 | Resource Vault | Resource list, upload, assignment |
| 13 | Social/Explore | Explore screen, public trainer profiles |
| 14 | Billing & Packages | Package management, checkout flow |
| 14 | Blog & Content | Blog list, post screen |
| 14 | System Config | Feature flag integration |

### Phase 5 (Weeks 15–16): Advanced Features — P3

**Goal:** Cutting-edge + admin

| Week | Tasks | Deliverables |
|------|-------|-------------|
| 15 | AI Coach (session + voice) | AI coach screen, voice mode |
| 15 | AI Workout Generation | AI program generator screen |
| 16 | Admin Panel | Admin dashboard, event moderation, blog CRUD, tickets |
| 16 | Polish & Performance | Animation, caching, error handling, accessibility |

---

## 5. Coverage Matrix

### Complete Feature-to-Endpoint Mapping

| # | Feature | Priority | Endpoints Count | Sync | Depends On | Effort | Phase |
|---|---------|----------|-----------------|------|------------|--------|-------|
| 1.1 | Email/Password Login | P0 | 1 | Live | — | S | 1 |
| 1.2 | Email/Password Registration | P0 | 1 | Live | — | S | 1 |
| 1.3 | OAuth (Google/Apple) | P0 | 1 | Live | — | M | 1 |
| 1.4 | Token Refresh | P0 | 1 | Live | — | S | 1 |
| 1.5 | Auto-Login (Session Restore) | P0 | 2 | Live | 1.4 | M | 1 |
| 1.6 | Forgot Password | P0 | 1 | Live | — | XS | 1 |
| 1.7 | Update Password | P0 | 1 | Live | — | XS | 1 |
| 1.8 | Sign Out | P0 | 1 | Live | — | XS | 1 |
| 1.9 | Get Current User | P0 | 1 | Live | 1.4 | S | 1 |
| 1.10 | Sync User | P0 | 1 | Live | 1.3 | XS | 1 |
| 1.11 | Resend Verification Email | P0 | 1 | Live | — | XS | 1 |
| 1.12 | Complete Onboarding | P0 | 1 | Live | — | S | 1 |
| 1.13 | Role Selection & Profile Setup | P0 | 1 | Live | 1.2 | M | 1 |
| 2.1 | Trainer Dashboard | P0 | 1 | Partial | 1, 4, 5 | M | 2 |
| 2.2 | Client Dashboard | P0 | 1 | Partial | 1 | M | 2 |
| 2.3 | Dashboard Insights | P0 | 1 | Live | 1, 4 | S | 2 |
| 2.4 | Dashboard Summary | P0 | 1 | Live | 1 | S | 2 |
| 2.5 | Mobile Home | P0 | 1 | Partial | 1 | M | 2 |
| 3.1 | Start Workout | P0 | 1 | Full | 7, 6 | M | 2 |
| 3.2 | Live Workout Tracking | P0 | 2 | Full | 3.1 | L | 2 |
| 3.3 | Exercise Logging | P0 | 2 | Full | 3.2 | M | 2 |
| 3.4 | Rest Timer | P0 | 2 | Full | 3.2 | S | 2 |
| 3.5 | Finish Workout | P0 | 1 | Full | 3.2 | S | 2 |
| 3.6 | Cancel Workout | P0 | 1 | Full | 3.1 | XS | 2 |
| 3.7 | Plan/Schedule Workouts | P0 | 1 | Full | 7, 6 | M | 2 |
| 3.8 | Workout History | P0 | 1 | Full | 3.5 | M | 2 |
| 3.9 | Workout Detail | P0 | 2 | Full | 3.8 | S | 2 |
| 3.10 | Workout Summary | P0 | 1 | Full | 3.5 | S | 2 |
| 3.11 | Session Comments | P0 | 1 | Full | 3.9 | S | 3 |
| 3.12 | Save as Template | P0 | 1 | Full | 3.5, 6 | S | 3 |
| 3.13 | Add/Remove Exercises | P0 | 2 | Full | 3.2, 7 | M | 2 |
| 4.1 | Client List | P0 | 1 | Full | 1 | M | 2 |
| 4.2 | Client Detail | P0 | 1 | Full | 4.1 | S | 2 |
| 4.3 | Create/Update/Delete Client | P0 | 3 | Full | 1 | M | 2 |
| 4.4 | Client Dashboard | P0 | 1 | Full | 4.1 | M | 2 |
| 4.5 | Client Measurements | P0 | 4 | Full | 4.2 | M | 2 |
| 4.6 | Client Progress Photos | P0 | 3 | Full | 4.2 | M | 2 |
| 4.7 | Client Assessments | P0 | 4 | Full | 4.2 | M | 3 |
| 4.8 | Client Exercise Logs | P0 | 1 | Full | 4.2, 3 | S | 2 |
| 4.9 | Client Sessions | P0 | 3 | Full | 4.2 | S | 2 |
| 4.10 | Active Session View | P0 | 1 | Full | 4.2, 3 | S | 2 |
| 4.11 | Active Program View | P0 | 1 | Full | 4.2, 6 | S | 3 |
| 4.12 | Client Invite | P0 | 1 | Live | 1 | S | 2 |
| 4.13 | Client Link Request | P0 | 1 | Live | 1 | S | 2 |
| 4.14 | Client Avatar | P0 | 2 | Full | 4.2 | S | 2 |
| 4.15 | Client Insights (AI) | P3 | 1 | Live | 4.2 | S | 5 |
| 4.16 | Client Packages | P1 | 1 | Full | 4.2, 14 | S | 4 |
| 4.17 | Client Sharing | P1 | 2 | Full | 4.2 | S | 3 |
| 4.18 | Upload Photo | P0 | 1 | Live | 1 | S | 2 |
| 4.19 | Client Statistics | P1 | 1 | Full | 4.2 | S | 3 |
| 4.20 | Client Analytics | P1 | 1 | Full | 4.2 | M | 3 |
| 5.1 | Profile Core Info | P0 | 1 | Full | 1 | S | 2 |
| 5.2 | Profile Photo | P0 | 1 | Full | 1 | S | 2 |
| 5.3 | Text Content | P0 | 2 | Full | 1 | S | 2 |
| 5.4 | Branding | P1 | 1 | Full | 1 | S | 3 |
| 5.5 | Services CRUD | P0 | 3 | Full | 1 | M | 2 |
| 5.6 | Packages CRUD | P0 | 3 | Full | 1 | M | 2 |
| 5.7 | Testimonials CRUD | P0 | 3 | Full | 1 | M | 2 |
| 5.8 | Benefits CRUD | P1 | 3 | Full | 1 | M | 3 |
| 5.9 | Benefit Reorder | P1 | 1 | Full | 5.8 | S | 3 |
| 5.10 | Social Links CRUD | P1 | 3 | Full | 1 | S | 3 |
| 5.11 | External Links CRUD | P1 | 3 | Full | 1 | S | 3 |
| 5.12 | Transformation Photos | P1 | 3 | Full | 1 | M | 3 |
| 5.13 | Availability | P1 | 1 | Full | 1 | M | 3 |
| 5.14 | Custom Exercises | P2 | 3 | Full | 1, 7 | S | 4 |
| 5.15 | Full Profile | P0 | 1 | Full | 1 | S | 2 |
| 5.16 | Completion Score | P0 | 0 | Full | 5.x | XS | 2 |
| 6.1 | Program List | P1 | 1 | Full | 7 | M | 3 |
| 6.2 | Create Program | P1 | 1 | Full | 7 | S | 3 |
| 6.3 | Template Detail | P1 | 1 | Full | 6.1 | S | 3 |
| 6.4 | Template CRUD | P1 | 2 | Full | 6.1 | M | 3 |
| 6.5 | Template Exercises | P1 | 2 | Full | 6.3, 7 | M | 3 |
| 6.6 | Template Rest Steps | P1 | 1 | Full | 6.3 | S | 3 |
| 6.7 | Copy System Template | P1 | 1 | Full | 6.3 | S | 3 |
| 6.8 | Client Programs | P1 | 1 | Full | 4, 6.1 | S | 3 |
| 6.9 | Assign Program | P1 | 1 | Live | 4, 6 | S | 3 |
| 6.10 | Active Program (Client) | P1 | 2 | Full | 4, 6.8 | S | 3 |
| 6.11 | AI Program Generation | P3 | 1 | Live | 7 | M | 5 |
| 7.1 | Exercise List | P1 | 1 | Full | — | M | 2 |
| 7.2 | Exercise Search | P1 | 0 | Full | 7.1 | S | 2 |
| 7.3 | Exercise Media | P1 | 1 | Live | 7.1 | S | 2 |
| 7.4 | Exercise Sync | P1 | 1 | Full | 23 | S | 2 |
| 8.1 | Calendar View | P1 | 1 | Partial | 4, 6 | L | 3 |
| 8.2 | Create Planned Session | P1 | 1 | Partial | 4, 6 | M | 3 |
| 8.3 | Update/Delete Session | P1 | 2 | Partial | 8.1 | S | 3 |
| 8.4 | Send Reminder | P1 | 1 | Live | 8.1 | XS | 3 |
| 8.5 | Clients Summary | P1 | 1 | Partial | 8.1 | S | 3 |
| 8.6 | Session Creation Data | P1 | 1 | Live | 8.1 | S | 3 |
| 9.1 | Submit Check-In | P1 | 1 | Full | 4 | M | 2 |
| 9.2 | Client Check-Ins List | P1 | 1 | Full | 4 | S | 2 |
| 9.3 | Check-In Config | P1 | 1 | Full | 9.1 | S | 2 |
| 9.4 | Trainer Check-Ins List | P1 | 1 | Full | 4 | M | 2 |
| 9.5 | Pending Check-Ins | P1 | 1 | Full | 9.4 | S | 2 |
| 9.6 | Check-In Detail with Trends | P1 | 1 | Full | 9.4 | M | 3 |
| 9.7 | Review Check-In | P1 | 1 | Full | 9.6 | S | 3 |
| 9.8 | Delete Check-In | P1 | 1 | Full | 9.6 | XS | 3 |
| 10.1 | Create Booking | P1 | 1 | Live | 8, 12 | M | 3 |
| 10.2 | Booking List | P1 | 1 | Partial | 10.1 | S | 3 |
| 10.3 | Confirm Booking | P1 | 1 | Live | 10.2 | S | 3 |
| 10.4 | Decline Booking | P1 | 1 | Live | 10.2 | XS | 3 |
| 10.5 | Client Event Bookings | P1 | 1 | Partial | 4 | S | 3 |
| 10.6 | Cancel Event Booking | P1 | 1 | Live | 10.5 | XS | 3 |
| 11.1 | Events List | P1 | 1 | Live | — | M | 3 |
| 11.2 | Event Detail | P1 | 1 | Live | 11.1 | S | 3 |
| 11.3 | Join Free Event | P1 | 1 | Live | 11.2, 1 | S | 3 |
| 11.4 | Create Event | P1 | 1 | Live | 1 | M | 3 |
| 11.5 | Edit/Delete Event | P1 | 2 | Live | 11.4 | S | 3 |
| 11.6 | Trainer Events List | P1 | 1 | Live | 1 | S | 3 |
| 11.7 | Upload Event Image | P1 | 1 | Live | 11.4 | S | 3 |
| 12.1 | Notification List | P1 | 1 | Partial | 1 | S | 3 |
| 12.2 | Mark Read | P1 | 1 | Live | 12.1 | XS | 3 |
| 12.3 | Push Token Registration | P1 | 1 | Live | 1 | S | 3 |
| 12.4 | Push Notifications | P1 | 0 | Live | 12.3 | M | 3 |
| 13.1 | Conversation List | P1 | 0 | Partial | 4 | S | 3 |
| 13.2 | Message History | P1 | 1 | Partial | 13.1 | M | 3 |
| 13.3 | Send Message | P1 | 1 | Partial | 13.2 | M | 3 |
| 13.4 | Media in Chat | P1 | 0 | Live | 13.3 | S | 3 |
| 13.5 | AI Coach Chat | P3 | 1 | Live | 13.2 | M | 5 |
| 14.1 | Package Management | P2 | 0 | Full | 5.6 | S | 4 |
| 14.2 | Client Package Tracking | P2 | 1 | Full | 4, 14.1 | S | 4 |
| 14.3 | Stripe Checkout | P2 | 1 | Live | 14.1 | M | 4 |
| 14.4 | Subscription Status | P2 | 1 | Live | 1 | S | 4 |
| 14.5 | Subscribe New | P2 | 1 | Live | 1 | S | 4 |
| 14.6 | Subscription Management | P2 | 2 | Live | 1 | S | 4 |
| 14.7 | Billing Portal | P2 | 1 | Live | 1 | XS | 4 |
| 15.1 | Recipe List | P2 | 1 | Partial | — | S | 4 |
| 15.2 | Recipe Detail | P2 | 1 | Partial | 15.1 | S | 4 |
| 15.3 | Create Recipe | P2 | 1 | Partial | — | S | 4 |
| 15.4 | Update Recipe | P2 | 1 | Partial | 15.3 | S | 4 |
| 15.5 | Delete Recipe | P2 | 1 | Partial | 15.1 | XS | 4 |
| 16.1 | Client Habit List | P2 | 1 | Full | 4 | S | 4 |
| 16.2 | Log Habit | P2 | 1 | Full | 16.1 | S | 4 |
| 16.3 | Trainer View Client Habits | P2 | 1 | Full | 4 | S | 4 |
| 16.4 | Assign Habit | P2 | 1 | Full | 4 | S | 4 |
| 17.1 | Resource List (Trainer) | P2 | 1 | Partial | 1 | S | 4 |
| 17.2 | Resource CRUD | P2 | 3 | Partial | 1 | M | 4 |
| 17.3 | Client Resources | P2 | 1 | Partial | 4 | S | 4 |
| 17.4 | Assign Resources | P2 | 1 | Live | 4, 17.1 | S | 4 |
| 18.1 | Trainer Search | P2 | 1 | Live | — | S | 4 |
| 18.2 | Trainer Public Profile | P2 | 1 | Live | 5 | M | 4 |
| 18.3 | Public Trainer (Lightweight) | P2 | 1 | Live | 18.2 | S | 4 |
| 18.4 | Trainer Specialties | P2 | 1 | Live | — | S | 4 |
| 18.5 | Trainer Schedule (Public) | P2 | 1 | Live | 5.13 | S | 4 |
| 18.6 | Trainer Packages (Public) | P2 | 1 | Live | 5.6 | S | 4 |
| 18.7 | Trainer Testimonials | P2 | 1 | Live | 5.7 | S | 4 |
| 18.8 | Trainer Transformation Photos | P2 | 1 | Live | 5.12 | S | 4 |
| 18.9 | Explore Featured | P2 | 1 | Live | — | S | 4 |
| 18.10 | Explore Events | P2 | 1 | Live | 11 | S | 4 |
| 18.11 | Explore Metadata | P2 | 1 | Live | — | S | 4 |
| 19.1 | AI Coach Session | P3 | 2 | Live | 3, 7 | L | 5 |
| 19.2 | AI Voice Trainer | P3 | 1 | Live | 19.1 | L | 5 |
| 19.3 | AI Workout Generation | P3 | 1 | Live | 7 | M | 5 |
| 19.4 | AI Client Insights | P3 | 1 | Live | 4 | S | 5 |
| 19.5 | AI Coach Generate | P3 | 1 | Live | 7 | M | 5 |
| 19.6 | AI Coach Refine | P3 | 1 | Live | 19.5 | S | 5 |
| 20.1 | Settings View | P1 | 1 | Partial | 1 | S | 3 |
| 20.2 | Check-In Defaults | P1 | 0 | Full | 1 | S | 3 |
| 20.3 | Weight Unit | P1 | 0 | Full | 1 | XS | 3 |
| 20.4 | Push Token | P1 | 1 | Live | 1 | XS | 3 |
| 20.5 | Payment Setup | P1 | 1 | Live | 1 | S | 4 |
| 21.1 | Platform Stats | P3 | 1 | Live | 1 | S | 5 |
| 21.2 | Event Moderation | P3 | 3 | Live | 1 | M | 5 |
| 21.3 | Blog CRUD | P3 | 5 | Live | 1 | M | 5 |
| 21.4 | Support Tickets | P3 | 3 | Live | 1 | M | 5 |
| 21.5 | Admin Upload | P3 | 1 | Live | 1 | S | 5 |
| 22.1 | Feature Flags | P1 | 1 | Live | — | XS | 1 |
| 23.1 | Pull Sync | P1 | 1 | — | 1 | L | 1 |
| 23.2 | Push Sync | P1 | 1 | — | 1 | L | 1 |
| 23.3 | Sync Status UI | P1 | 0 | — | 23.1 | S | 1 |
| 23.4 | Conflict Resolution | P1 | 0 | — | 23.1 | M | 1 |
| 24.1 | Contact Form | P2 | 1 | Live | — | XS | 4 |
| 24.2 | Support Tickets | P2 | 1 | Live | 1 | S | 4 |
| 24.3 | Account Deletion | P2 | 1 | Live | 1 | S | 4 |
| 24.4 | Custom Domains | P2 | 2 | Live | 5 | S | 4 |
| 24.5 | Blog (Public) | P2 | 2 | Live | — | M | 4 |
| 24.6 | Public Workout Summary | P2 | 1 | Live | 3 | XS | 4 |
| 24.7 | Pricing Plans | P2 | 1 | Live | — | S | 4 |
| 24.8 | Link Requests | P2 | 2 | Live | 4 | S | 3 |
| 24.9 | Client-Trainer Link/Unlink | P2 | 4 | Live | 1 | S | 3 |

### Priority Distribution

| Priority | Feature Count | Endpoints | % of Total |
|----------|--------------|-----------|------------|
| **P0** | 40 | ~50 | 39% |
| **P1** | 48 | ~45 | 35% |
| **P2** | 33 | ~30 | 23% |
| **P3** | 10 | ~8 | 6% |
| **Total** | ~131 | ~133 | 100% |

### Sync Coverage

| Sync Type | Feature Count | % |
|-----------|--------------|---|
| Fully Synced | 56 | 43% |
| Partially Synced | 18 | 14% |
| Live Only | 57 | 43% |

---

## 6. Endpoint Inventory

### Complete Endpoint List (133 endpoints across 33 groups)

| # | Method | Endpoint | Feature Group | Role | Priority |
|---|--------|----------|---------------|------|----------|
| 1 | POST | `/api/auth/login` | 1. Auth | Public | P0 |
| 2 | POST | `/api/auth/register` | 1. Auth | Public | P0 |
| 3 | GET | `/api/auth/mobile-signin` | 1. Auth | Public | P0 |
| 4 | POST | `/api/auth/refresh` | 1. Auth | Public | P0 |
| 5 | POST | `/api/auth/signout` | 1. Auth | Any | P0 |
| 6 | GET | `/api/auth/me` | 1. Auth | Any | P0 |
| 7 | POST | `/api/auth/sync-user` | 1. Auth | Any | P0 |
| 8 | POST | `/api/auth/forgot-password` | 1. Auth | Public | P0 |
| 9 | POST | `/api/auth/update-password` | 1. Auth | Any | P0 |
| 10 | POST | `/api/auth/resend-verification-email` | 1. Auth | Public | P0 |
| 11 | POST | `/api/auth/complete-onboarding` | 1. Auth | Any | P0 |
| 12 | POST | `/api/onboarding/complete` | 1. Auth | Any | P0 |
| 13 | GET | `/api/sync/pull` | 23. Sync | Any | P1 |
| 14 | POST | `/api/sync/push` | 23. Sync | Any | P1 |
| 15 | POST | `/api/workout-sessions/start` | 3. Workout | client, trainer | P0 |
| 16 | GET | `/api/workout-sessions/live` | 3. Workout | client, trainer | P0 |
| 17 | POST | `/api/workout-sessions/live` | 3. Workout | client, trainer | P0 |
| 18 | POST | `/api/workout-sessions/finish` | 3. Workout | client, trainer | P0 |
| 19 | POST | `/api/workout-sessions/plan` | 3. Workout | client, trainer | P0 |
| 20 | GET | `/api/workout-sessions/history` | 3. Workout | client, trainer | P0 |
| 21 | GET | `/api/workout-sessions/[id]` | 3. Workout | client, trainer | P0 |
| 22 | PUT | `/api/workout-sessions/[id]` | 3. Workout | client, trainer | P0 |
| 23 | POST | `/api/workout-sessions/[id]/exercises` | 3. Workout | client, trainer | P0 |
| 24 | DELETE | `/api/workout-sessions/[id]/exercises/[exerciseId]` | 3. Workout | client, trainer | P0 |
| 25 | POST | `/api/workout-sessions/[id]/comments` | 3. Workout | client, trainer | P0 |
| 26 | POST | `/api/workout-sessions/[id]/cancel` | 3. Workout | client, trainer | P0 |
| 27 | POST | `/api/workout-sessions/[id]/rest/start` | 3. Workout | client, trainer | P0 |
| 28 | POST | `/api/workout-sessions/[id]/rest/end` | 3. Workout | client, trainer | P0 |
| 29 | POST | `/api/workout-sessions/[id]/save-as-template` | 3. Workout | client, trainer | P0 |
| 30 | GET | `/api/workout-sessions/[id]/summary` | 3. Workout | client, trainer | P0 |
| 31 | POST | `/api/workout/log` | 3. Workout | client, trainer | P0 |
| 32 | GET | `/api/workout-templates/[id]` | 6. Programs | Any | P1 |
| 33 | GET | `/api/exercises` | 7. Exercises | client, trainer | P1 |
| 34 | GET | `/api/exercises/find-media` | 7. Exercises | Any | P1 |
| 35 | GET | `/api/exercises/sync` | 7. Exercises | client, trainer | P1 |
| 36 | GET | `/api/client/dashboard` | 2. Dashboard | client | P0 |
| 37 | GET | `/api/client/programs` | 6. Programs | Any | P1 |
| 38 | POST | `/api/client/programs` | 19. AI | Any | P3 |
| 39 | GET | `/api/client/progress` | 4. Clients | client | P1 |
| 40 | GET | `/api/client/habits` | 16. Habits | client | P2 |
| 41 | POST | `/api/client/habits/[habitId]/log` | 16. Habits | client | P2 |
| 42 | GET | `/api/client/trainer` | 24. Misc | Any | P2 |
| 43 | DELETE | `/api/client/trainer` | 24. Misc | Any | P2 |
| 44 | GET | `/api/client/trainer/link` | 24. Misc | client | P2 |
| 45 | POST | `/api/client/trainer/link` | 24. Misc | client | P2 |
| 46 | DELETE | `/api/client/trainer/link` | 24. Misc | client | P2 |
| 47 | GET | `/api/client/events` | 10. Bookings | client | P1 |
| 48 | PUT | `/api/client/events/[bookingId]/cancel` | 10. Bookings | client | P1 |
| 49 | GET | `/api/client/sharing` | 4. Clients | client | P1 |
| 50 | PUT | `/api/client/sharing` | 4. Clients | client | P1 |
| 51 | POST | `/api/client/upload` | 4. Clients | client | P0 |
| 52 | POST | `/api/client/ai/generate` | 19. AI | Any | P3 |
| 53 | GET | `/api/client/resource-vault` | 17. Resources | client | P2 |
| 54 | GET | `/api/client/program/active` | 6. Programs | client | P1 |
| 55 | PUT | `/api/client/program/active` | 6. Programs | client | P1 |
| 56 | GET | `/api/client/analytics` | 4. Clients | client | P1 |
| 57 | POST | `/api/client/check-in` | 9. Check-Ins | Any | P1 |
| 58 | GET | `/api/client/check-ins` | 9. Check-Ins | client | P1 |
| 59 | GET | `/api/client/check-ins/[id]` | 9. Check-Ins | client | P1 |
| 60 | DELETE | `/api/client/check-ins/[id]` | 9. Check-Ins | client | P1 |
| 61 | GET | `/api/client/check-in/config` | 9. Check-Ins | client | P1 |
| 62 | GET | `/api/client/statistics` | 4. Clients | client | P1 |
| 63 | GET | `/api/client/stats/exercise` | 4. Clients | client | P1 |
| 64 | GET | `/api/clients` | 4. Clients | trainer | P0 |
| 65 | POST | `/api/clients` | 4. Clients | trainer | P0 |
| 66 | GET | `/api/clients/[id]` | 4. Clients | trainer | P0 |
| 67 | PUT | `/api/clients/[id]` | 4. Clients | trainer | P0 |
| 68 | DELETE | `/api/clients/[id]` | 4. Clients | trainer | P0 |
| 69 | GET | `/api/clients/[id]/dashboard` | 4. Clients | trainer | P0 |
| 70 | GET | `/api/clients/[id]/assessments` | 4. Clients | trainer | P0 |
| 71 | POST | `/api/clients/[id]/assessments` | 4. Clients | trainer | P0 |
| 72 | PUT | `/api/clients/[id]/assessments/[resultId]` | 4. Clients | trainer | P0 |
| 73 | DELETE | `/api/clients/[id]/assessments/[resultId]` | 4. Clients | trainer | P0 |
| 74 | GET | `/api/clients/[id]/measurements` | 4. Clients | trainer | P0 |
| 75 | POST | `/api/clients/[id]/measurements` | 4. Clients | trainer | P0 |
| 76 | PUT | `/api/clients/[id]/measurements/[measurementId]` | 4. Clients | trainer | P0 |
| 77 | DELETE | `/api/clients/[id]/measurements/[measurementId]` | 4. Clients | trainer | P0 |
| 78 | GET | `/api/clients/[id]/photos` | 4. Clients | trainer | P0 |
| 79 | POST | `/api/clients/[id]/photos` | 4. Clients | trainer | P0 |
| 80 | DELETE | `/api/clients/[id]/photos/[photoId]` | 4. Clients | trainer | P0 |
| 81 | POST | `/api/clients/[id]/exercise-logs` | 4. Clients | trainer | P0 |
| 82 | GET | `/api/clients/[id]/sessions` | 4. Clients | trainer | P0 |
| 83 | PUT | `/api/clients/[id]/sessions/[sessionId]` | 4. Clients | trainer | P0 |
| 84 | DELETE | `/api/clients/[id]/sessions/[sessionId]` | 4. Clients | trainer | P0 |
| 85 | GET | `/api/clients/[id]/session/active` | 4. Clients | trainer | P0 |
| 86 | GET | `/api/clients/[id]/program/active` | 4. Clients | trainer | P1 |
| 87 | POST | `/api/clients/[id]/insights` | 19. AI | trainer | P3 |
| 88 | POST | `/api/clients/[id]/avatar` | 4. Clients | trainer | P0 |
| 89 | DELETE | `/api/clients/[id]/avatar` | 4. Clients | trainer | P0 |
| 90 | GET | `/api/clients/[id]/packages` | 14. Billing | trainer | P2 |
| 91 | POST | `/api/clients/invite` | 4. Clients | trainer | P0 |
| 92 | POST | `/api/clients/request-link` | 4. Clients | trainer | P0 |
| 93 | GET | `/api/trainer/calendar` | 8. Calendar | trainer | P1 |
| 94 | POST | `/api/trainer/calendar` | 8. Calendar | trainer | P1 |
| 95 | PUT | `/api/trainer/calendar/[sessionId]` | 8. Calendar | trainer | P1 |
| 96 | DELETE | `/api/trainer/calendar/[sessionId]` | 8. Calendar | trainer | P1 |
| 97 | POST | `/api/trainer/calendar/sessions/[sessionId]/remind` | 8. Calendar | trainer | P1 |
| 98 | GET | `/api/trainer/calendar/clients-summary` | 8. Calendar | trainer | P1 |
| 99 | GET | `/api/trainer/check-ins` | 9. Check-Ins | trainer, admin | P1 |
| 100 | GET | `/api/trainer/check-ins/[id]` | 9. Check-Ins | trainer, admin | P1 |
| 101 | DELETE | `/api/trainer/check-ins/[id]` | 9. Check-Ins | trainer, admin | P1 |
| 102 | PATCH | `/api/trainer/check-ins/[id]/review` | 9. Check-Ins | trainer, admin | P1 |
| 103 | GET | `/api/trainer/check-ins/pending` | 9. Check-Ins | trainer, admin | P1 |
| 104 | GET | `/api/trainer/programs` | 6. Programs | trainer, client | P1 |
| 105 | POST | `/api/trainer/programs` | 6. Programs | trainer, client | P1 |
| 106 | GET | `/api/trainer/programs/templates` | 6. Programs | trainer, client | P1 |
| 107 | POST | `/api/trainer/programs/templates` | 6. Programs | trainer, client | P1 |
| 108 | POST | `/api/trainer/programs/templates/[templateId]/exercises` | 6. Programs | trainer, client | P1 |
| 109 | DELETE | `/api/trainer/programs/templates/[templateId]/exercises/[exerciseStepId]` | 6. Programs | trainer, client | P1 |
| 110 | POST | `/api/trainer/programs/templates/[templateId]/copy` | 6. Programs | trainer, client | P1 |
| 111 | POST | `/api/trainer/programs/templates/[templateId]/rest` | 6. Programs | trainer, client | P1 |
| 112 | GET | `/api/trainer/recipes` | 15. Nutrition | trainer | P2 |
| 113 | POST | `/api/trainer/recipes` | 15. Nutrition | trainer | P2 |
| 114 | GET | `/api/trainer/recipes/[id]` | 15. Nutrition | trainer | P2 |
| 115 | PUT | `/api/trainer/recipes/[id]` | 15. Nutrition | trainer | P2 |
| 116 | DELETE | `/api/trainer/recipes/[id]` | 15. Nutrition | trainer | P2 |
| 117 | GET | `/api/trainer/assessments` | 4. Clients | trainer | P0 |
| 118 | POST | `/api/trainer/assessments` | 4. Clients | trainer | P0 |
| 119 | GET | `/api/trainer/events` | 11. Events | trainer | P1 |
| 120 | POST | `/api/trainer/events` | 11. Events | trainer | P1 |
| 121 | PUT | `/api/trainer/events/[id]` | 11. Events | trainer | P1 |
| 122 | DELETE | `/api/trainer/events/[id]` | 11. Events | trainer | P1 |
| 123 | POST | `/api/trainer/events/upload` | 11. Events | trainer | P1 |
| 124 | GET | `/api/trainer/session-creation-data` | 8. Calendar | trainer | P1 |
| 125 | GET | `/api/trainer/profile` | 5. Profile | trainer | P0 |
| 126 | GET | `/api/trainer/clients` | 4. Clients | trainer | P0 |
| 127 | GET | `/api/trainer/workout-templates` | 6. Programs | trainer | P1 |
| 128 | GET | `/api/trainer/resource-vault` | 17. Resources | trainer | P2 |
| 129 | POST | `/api/trainer/resource-vault/[id]/assign` | 17. Resources | trainer | P2 |
| 130 | GET | `/api/trainer/settings` | 20. Settings | trainer | P1 |
| 131 | POST | `/api/trainer/link-requests/[notificationId]/accept` | 24. Misc | trainer | P2 |
| 132 | POST | `/api/trainer/link-requests/[notificationId]/decline` | 24. Misc | trainer | P2 |
| 133 | POST | `/api/trainer/clients/[id]/assign-program` | 6. Programs | trainer | P1 |
| 134 | GET | `/api/trainer/clients/[id]/habits` | 16. Habits | trainer | P2 |
| 135 | POST | `/api/trainer/clients/[id]/habits` | 16. Habits | trainer | P2 |
| 136 | POST | `/api/trainer/clients/[id]/habits/[habitId]` | 16. Habits | trainer | P2 |
| 137 | GET | `/api/profile/me` | 5. Profile | Any | P0 |
| 138 | GET | `/api/profile/me/core-info` | 5. Profile | trainer | P0 |
| 139 | PUT | `/api/profile/me/core-info` | 5. Profile | trainer | P0 |
| 140 | GET | `/api/profile/me/text-content` | 5. Profile | trainer, client | P0 |
| 141 | PUT | `/api/profile/me/text-content` | 5. Profile | trainer, client | P0 |
| 142 | POST | `/api/profile/me/avatar` | 5. Profile | any | P0 |
| 143 | DELETE | `/api/profile/me/avatar` | 5. Profile | any | P0 |
| 144 | GET | `/api/profile/me/services` | 5. Profile | trainer | P0 |
| 145 | POST | `/api/profile/me/services` | 5. Profile | trainer | P0 |
| 146 | PUT | `/api/profile/me/services/[serviceId]` | 5. Profile | trainer | P0 |
| 147 | DELETE | `/api/profile/me/services/[serviceId]` | 5. Profile | trainer | P0 |
| 148 | GET | `/api/profile/me/packages` | 5. Profile | trainer | P0 |
| 149 | POST | `/api/profile/me/packages` | 5. Profile | trainer | P0 |
| 150 | PUT | `/api/profile/me/packages/[packageId]` | 5. Profile | trainer | P0 |
| 151 | DELETE | `/api/profile/me/packages/[packageId]` | 5. Profile | trainer | P0 |
| 152 | GET | `/api/profile/me/testimonials` | 5. Profile | trainer | P0 |
| 153 | POST | `/api/profile/me/testimonials` | 5. Profile | trainer | P0 |
| 154 | PUT | `/api/profile/me/testimonials/[testimonialId]` | 5. Profile | trainer | P0 |
| 155 | DELETE | `/api/profile/me/testimonials/[testimonialId]` | 5. Profile | trainer | P0 |
| 156 | GET | `/api/profile/me/benefits` | 5. Profile | trainer | P1 |
| 157 | POST | `/api/profile/me/benefits` | 5. Profile | trainer | P1 |
| 158 | PUT | `/api/profile/me/benefits/[benefitId]` | 5. Profile | trainer | P1 |
| 159 | DELETE | `/api/profile/me/benefits/[benefitId]` | 5. Profile | trainer | P1 |
| 160 | PUT | `/api/profile/me/benefits/order` | 5. Profile | trainer | P1 |
| 161 | GET | `/api/profile/me/social-links` | 5. Profile | trainer | P1 |
| 162 | POST | `/api/profile/me/social-links` | 5. Profile | trainer | P1 |
| 163 | PUT | `/api/profile/me/social-links/[linkId]` | 5. Profile | trainer | P1 |
| 164 | DELETE | `/api/profile/me/social-links/[linkId]` | 5. Profile | trainer | P1 |
| 165 | GET | `/api/profile/me/external-links` | 5. Profile | trainer | P1 |
| 166 | POST | `/api/profile/me/external-links` | 5. Profile | trainer | P1 |
| 167 | PUT | `/api/profile/me/external-links/[linkId]` | 5. Profile | trainer | P1 |
| 168 | DELETE | `/api/profile/me/external-links/[linkId]` | 5. Profile | trainer | P1 |
| 169 | GET | `/api/profile/me/transformation-photos` | 5. Profile | trainer | P1 |
| 170 | POST | `/api/profile/me/transformation-photos` | 5. Profile | trainer | P1 |
| 171 | DELETE | `/api/profile/me/transformation-photos/[photoId]` | 5. Profile | trainer | P1 |
| 172 | GET | `/api/profile/me/availability` | 5. Profile | trainer | P1 |
| 173 | GET | `/api/profile/me/assessments` | 4. Clients | trainer | P0 |
| 174 | GET | `/api/profile/me/billing` | 20. Settings | trainer | P1 |
| 175 | GET | `/api/profile/me/branding` | 5. Profile | trainer | P1 |
| 176 | PUT | `/api/profile/me/branding` | 5. Profile | trainer | P1 |
| 177 | GET | `/api/profile/me/exercises` | 5. Profile | trainer | P2 |
| 178 | POST | `/api/profile/me/exercises` | 5. Profile | trainer | P2 |
| 179 | PUT | `/api/profile/me/exercises/[exerciseId]` | 5. Profile | trainer | P2 |
| 180 | DELETE | `/api/profile/me/exercises/[exerciseId]` | 5. Profile | trainer | P2 |
| 181 | POST | `/api/profile/me/push-token` | 12. Notifications | any | P1 |
| 182 | GET | `/api/bookings` | 10. Bookings | trainer | P1 |
| 183 | POST | `/api/bookings` | 10. Bookings | client | P1 |
| 184 | PUT | `/api/bookings/[bookingId]/confirm` | 10. Bookings | trainer | P1 |
| 185 | PUT | `/api/bookings/[bookingId]/decline` | 10. Bookings | trainer | P1 |
| 186 | GET | `/api/dashboard` | 2. Dashboard | trainer, client | P0 |
| 187 | GET | `/api/dashboard/summary` | 2. Dashboard | trainer, client | P0 |
| 188 | GET | `/api/dashboard/insights` | 2. Dashboard | trainer, client | P0 |
| 189 | GET | `/api/notifications` | 12. Notifications | client, trainer | P1 |
| 190 | PUT | `/api/notifications/[id]` | 12. Notifications | client, trainer | P1 |
| 191 | GET | `/api/events` | 11. Events | Public | P1 |
| 192 | GET | `/api/events/[id]` | 11. Events | Public (opt auth) | P1 |
| 193 | POST | `/api/events/[id]/join` | 11. Events | client, trainer | P1 |
| 194 | GET | `/api/explore/featured` | 18. Explore | Public | P2 |
| 195 | GET | `/api/explore/events` | 18. Explore | Public | P2 |
| 196 | GET | `/api/explore/metadata` | 18. Explore | Public | P2 |
| 197 | GET | `/api/trainers` | 18. Explore | Public | P2 |
| 198 | GET | `/api/trainers/specialties` | 18. Explore | Public | P2 |
| 199 | GET | `/api/trainers/[username]` | 18. Explore | Public (opt auth) | P2 |
| 200 | GET | `/api/trainers/[username]/public` | 18. Explore | Public (opt auth) | P2 |
| 201 | GET | `/api/trainers/[username]/testimonials` | 18. Explore | Public | P2 |
| 202 | GET | `/api/trainers/[username]/schedule` | 18. Explore | Public | P2 |
| 203 | GET | `/api/trainers/[username]/packages` | 18. Explore | Public | P2 |
| 204 | GET | `/api/trainers/[username]/transformation-photos` | 18. Explore | Public | P2 |
| 205 | GET | `/api/public/workout-summary/[sessionId]` | 24. Misc | Public | P2 |
| 206 | GET | `/api/mobile/home` | 2. Dashboard | trainer, client | P0 |
| 207 | GET | `/api/mobile/pricing` | 24. Misc | Public | P2 |
| 208 | POST | `/api/mobile/ai-coach/generate` | 19. AI | Any | P3 |
| 209 | POST | `/api/mobile/ai-coach/refine` | 19. AI | Any | P3 |
| 210 | GET | `/api/ai-trainer/session` | 19. AI | client, trainer | P3 |
| 211 | POST | `/api/ai-trainer/session` | 19. AI | client, trainer | P3 |
| 212 | POST | `/api/ai-trainer/voice` | 19. AI | client, trainer | P3 |
| 213 | GET | `/api/chat` | 13. Chat | Any | P1 |
| 214 | POST | `/api/chat` | 13. Chat | Any | P1 |
| 215 | POST | `/api/checkout/session` | 14. Billing | client | P2 |
| 216 | GET | `/api/billing/subscription` | 14. Billing | any | P2 |
| 217 | POST | `/api/billing/subscription` | 14. Billing | any | P2 |
| 218 | PATCH | `/api/billing/subscription` | 14. Billing | any | P2 |
| 219 | POST | `/api/billing/portal` | 14. Billing | any | P2 |
| 220 | POST | `/api/billing/subscribe-new` | 14. Billing | any | P2 |
| 221 | POST | `/api/webhooks/stripe` | 14. Billing | Stripe | P2 |
| 222 | DELETE | `/api/user/delete` | 24. Misc | any | P2 |
| 223 | GET | `/api/admin/stats` | 21. Admin | admin | P3 |
| 224 | GET | `/api/admin/events` | 21. Admin | admin | P3 |
| 225 | GET | `/api/admin/events/[id]` | 21. Admin | admin | P3 |
| 226 | PATCH | `/api/admin/events/[id]` | 21. Admin | admin | P3 |
| 227 | GET | `/api/admin/blog` | 21. Admin | admin | P3 |
| 228 | POST | `/api/admin/blog` | 21. Admin | admin | P3 |
| 229 | GET | `/api/admin/blog/[id]` | 21. Admin | admin | P3 |
| 230 | PUT | `/api/admin/blog/[id]` | 21. Admin | admin | P3 |
| 231 | DELETE | `/api/admin/blog/[id]` | 21. Admin | admin | P3 |
| 232 | GET | `/api/admin/tickets` | 21. Admin | admin | P3 |
| 233 | PATCH | `/api/admin/tickets/[id]` | 21. Admin | admin | P3 |
| 234 | DELETE | `/api/admin/tickets/[id]` | 21. Admin | admin | P3 |
| 235 | POST | `/api/admin/upload` | 21. Admin | admin | P3 |
| 236 | GET | `/api/blog` | 24. Misc | Public | P2 |
| 237 | GET | `/api/blog/[slug]` | 24. Misc | Public | P2 |
| 238 | POST | `/api/contact` | 24. Misc | Public | P2 |
| 239 | POST | `/api/support/feedback` | 24. Misc | Any | P2 |
| 240 | GET | `/api/system/config` | 22. Config | Public | P1 |
| 241 | POST | `/api/domain/add` | 24. Misc | trainer | P2 |
| 242 | POST | `/api/domain/verify` | 24. Misc | trainer | P2 |
| 243 | GET | `/api/openapi` | 24. Misc | Public | — |
| 244 | GET | `/api/cron/check-in-reminder` | — | Cron | — |
| 245 | GET | `/api/cron/trial-reminders` | — | Cron | — |

> **Note:** Server-side only endpoints (webhooks, cron) are included for completeness but do not require Flutter implementation.

---

## Appendix: Architecture Decision Records

### ADR-1: Offline-First Approach

**Decision:** All P0 and P1 features that involve user-generated data (workouts, measurements, check-ins) will be fully synced for offline access.

**Rationale:** Fitness apps are frequently used in gyms with poor connectivity. Users expect to start, track, and finish workouts without internet.

**Impact:** Increases Phase 1 effort by ~2 weeks for sync engine, but reduces risk of poor offline experience.

### ADR-2: Role-Based Feature Exposure

**Decision:** Features are gated by user role at both API level (backend enforces) and UI level (Flutter routes guard).

**Rationale:** Clear separation between trainer and client experiences. Shared features (workouts, check-ins) appear in both roles but with different UI.

**Impact:** Routes are organized by role shell (trainer, client, admin) with shared feature widgets extracted to `shared/`.

### ADR-3: Progressive Enhancement

**Decision:** P2 and P3 features are implemented as independent feature modules with no hard dependencies on each other.

**Rationale:** Allows parallel development and incremental delivery without blocking the critical path.

**Impact:** Feature modules can be developed by different team members simultaneously.

---

*End of Feature Coverage Map. Covers 245 endpoints (120+ unique) mapped to ~131 features across 24 groups, organized into 5 implementation phases over 16 weeks.*
