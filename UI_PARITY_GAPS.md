# UI Parity Gaps: Flutter vs Next.js

**Generated:** 2026-05-15
**Next.js App:** `V:\zirofit-next`
**Flutter App:** `V:\zirofit-fl`

## Summary

The Flutter app covers ~80% of Next.js functionality by screens/routes.  
The gaps are primarily **advanced interaction patterns** (AI-coached workouts, drag-drop builders) and **admin-specific features** not present in the Flutter app.

## Feature Comparison

### Trainer Dashboard

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Quick stats (revenue, clients, bookings) | ✅ | ✅ | Both use `/api/mobile/home` |
| Upcoming sessions list | ✅ | ✅ | Both show next 3 |
| Recent activity feed | ⚠️ | ✅ | Flutter parses field but backend doesn't return it yet |
| Onboarding checklist | ❌ | ✅ | `OnboardingDashboard` / `FirstDollarOnboarding` in Next.js — not implemented in Flutter |
| Quick-add session | ✅ | ✅ | Both have FAB |
| Notification bell | ✅ | ✅ | Both navigate to notifications |
| Client activity feed | ❌ | ✅ | `EstablishedTrainerDashboard` in Next.js shows client activity |
| Performance charts | ✅ | ✅ | Via `/api/dashboard/summary` |

### Client Dashboard

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Greeting + date header | ✅ | ✅ | Both show user name |
| Active program widget | ✅ | ✅ | Both fetch from `/api/client/program/active` |
| Daily habits widget | ✅ | ✅ | Both fetch from `/api/client/habits` |
| Trainer profile card | ✅ | ✅ | Shows linked trainer info |
| Upcoming sessions | ✅ | ✅ | Both use `/api/client/dashboard` |
| Quick actions (Workout, Check-in, AI Coach) | ⚠️ | ✅ | Flutter has these as nav items, Next.js shows as Quick Action cards |
| Weight quick-log | ✅ | ❌ | Flutter has this, Next.js doesn't |
| Daily targets | ✅ | ❌ | Flutter has this, Next.js doesn't |
| Education overlay (first-time) | ✅ | ❌ | Flutter has this, Next.js might not need it |

### Workout Tracking

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Start workout from template | ✅ | ✅ | Both use `POST /api/workout-sessions/start` |
| Exercise logging (sets/reps/weight) | ✅ | ✅ | Both support full logging |
| Rest timer | ✅ | ✅ | Flutter has richer rest timer UI |
| Workout history | ✅ | ✅ | Both paginated |
| Workout summary | ✅ | ✅ | Both show PRs, totals |
| AI-coached live workout (voice) | ❌ | ✅ | **Critical gap** — Next.js has voice-based AI coaching with `speech-to-text` + `Gemini` |
| Program creation (trainer) | ✅ | ✅ | Both have program builder |
| Drag-drop exercise ordering | ⚠️ | ✅ | Flutter has basic reorder, Next.js has drag-drop with `sortablejs` |
| Superset grouping | ✅ | ✅ | Both support supersets |
| RPE picker | ✅ | ❌ | Flutter has this, Next.js doesn't |
| Plate calculator | ✅ | ❌ | Flutter has this, Next.js doesn't |
| Voice input for logging | ✅ | ❌ | Flutter has voice logging (not AI-coached) |

### Client Management

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Client list with search | ✅ | ✅ | Both use `/api/clients` |
| Client detail (tabs) | ✅ | ✅ | Overview, Programs, Sessions, Measurements, Photos |
| Client invite | ✅ | ✅ | Both use `/api/clients/invite` |
| Client measurements | ✅ | ✅ | Both use `/api/clients/{id}/measurements` |
| Client progress photos | ✅ | ✅ | Both use `/api/clients/{id}/photos` |
| Client assessment results | ✅ | ✅ | Both use `/api/clients/{id}/assessments` |
| Client insights (AI) | ❌ | ✅ | Next.js has Gemini-powered client insights |
| Client package management | ✅ | ✅ | Both use `/api/clients/{id}/packages` |
| Program assignment | ✅ | ✅ | Both use `/api/trainer/clients/{id}/assign-program` |
| Sharing requests management | ❌ | ✅ | Next.js has `/dashboard/sharing-requests` |
| Live session monitoring (trainer) | ❌ | ✅ | Next.js has `/clients/{clientId}/live` for real-time workout monitoring |

### Programs / Templates

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Program list | ✅ | ✅ | Both use `/api/trainer/programs` |
| Create program | ✅ | ✅ | Basic CRUD |
| Create template | ✅ | ✅ | Both support exercise steps + rest steps |
| Drag-drop exercise ordering | ⚠️ | ✅ | Next.js uses `sortablejs`, Flutter uses basic reorder |
| Exercise detail modal | ✅ | ✅ | Both show exercise info |
| System template library | ✅ | ✅ | Both copy system templates to personal library |
| AI-generated programs | ✅ | ✅ | Both use `/api/mobile/ai-coach/generate` |

### Progress & Analytics

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Workout heatmap | ✅ | ✅ | Both show activity calendar |
| Volume progression chart | ✅ | ✅ | fl_chart in Flutter, Chart.js in Next.js |
| Muscle focus distribution | ✅ | ✅ | Both show muscle group volume |
| Personal records list | ✅ | ✅ | Both show recent PRs |
| Consistency score | ✅ | ✅ | Both calculate workout consistency |
| Weight history chart | ✅ | ✅ | Both show weight progression |
| Fitness goals | ✅ | ✅ | Both support goal tracking |
| Exercise statistics (e1rm/volume) | ✅ | ✅ | Both use `/api/client/stats/exercise` |
| Goal setting wizard | ⚠️ | ✅ | Next.js has richer goal-setting UI |
| Movement detail | ✅ | ✅ | Both show per-exercise stats |

### Explore / Discovery

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Featured trainers | ✅ | ✅ | Both use `/api/explore/featured` |
| Featured events | ✅ | ✅ | Both show events |
| Browse by category | ✅ | ✅ | Both have category filter chips |
| City picker / location filter | ✅ | ✅ | Both filter by city |
| Trainer search | ✅ | ✅ | Both use `/api/trainers` |
| Trainer map | ✅ | ✅ | Flutter uses Flutter Map, Next.js uses Leaflet |
| Public trainer profile | ✅ | ✅ | Both show services, packages, reviews |
| Trainer filters (rating, price) | ✅ | ✅ | Both have filter sheets |

### Chat

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Conversation list | ✅ | ✅ | Both fetch from `/api/chat` |
| Send/receive messages | ✅ | ✅ | Both use `/api/chat` POST/GET |
| Media attachments | ❌ | ✅ | Next.js supports image/video in chat (form check videos) |
| System messages | ✅ | ✅ | Both support workout session context |

### Notifications

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Notification list | ✅ | ✅ | Both use `/api/notifications` |
| Mark read | ✅ | ✅ | Both use `PUT /api/notifications/{id}` |
| Accept/decline link requests | ✅ | ✅ | Both handle trainer-client link requests |
| Notification routing | ✅ | ❌ | **Fixed in Wave 2** — role-aware notifications |
| Push notifications (FCM) | ✅ | ❌ | Flutter has push notifications, Next.js web doesn't need FCM |

### Profile Management (Trainer)

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Edit basic info | ✅ | ✅ | Both use `PUT /api/profile/me/core-info` |
| Edit about me | ✅ | ✅ | Both use `/api/profile/me/text-content` |
| Edit philosophy/methodology | ✅ | ✅ | Both |
| Banner/avatar upload | ✅ | ✅ | Both use FormData multipart upload |
| Services CRUD | ✅ | ✅ | Both use `/api/profile/me/services` |
| Packages CRUD | ✅ | ✅ | Both use `/api/profile/me/packages` |
| Testimonials CRUD | ✅ | ✅ | Both use `/api/profile/me/testimonials` |
| Transformation photos | ✅ | ✅ | Both use `/api/profile/me/transformation-photos` |
| Social links CRUD | ✅ | ✅ | Both use `/api/profile/me/social-links` |
| External links CRUD | ✅ | ✅ | Both use `/api/profile/me/external-links` |
| Availability settings | ✅ | ✅ | Both use `/api/trainer/availability` |
| Check-in settings | ✅ | ✅ | Both use `/api/trainer/settings` |
| Benefits editor | ✅ | ✅ | Both use `/api/profile/me/benefits` |
| Complex multi-section editor | ⚠️ | ✅ | Next.js has sidebar with 18 sections, Flutter has individual screens |
| Storefront visibility | ✅ | ✅ | Both use `/api/trainer/storefront/visibility` |
| Custom domain | ✅ | ✅ | Both use `/api/domain/add` |

### Events

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Event list | ✅ | ✅ | Both use `/api/events` |
| Create event | ✅ | ✅ | Both use `POST /api/trainer/events` |
| Edit event | ✅ | ✅ | Both use `PUT /api/trainer/events/{id}` |
| Event detail | ✅ | ✅ | Both use `GET /api/events/{id}` |
| Join event | ✅ | ✅ | Both use `POST /api/events/{id}/join` |
| Event moderation (admin) | ✅ | ✅ | Both use `/api/admin/events` |
| Event map (Leaflet) | ❌ | ✅ | Next.js has Leaflet map on event detail |

### Bookings

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Booking list | ✅ | ✅ | Both use `/api/bookings` |
| Confirm/decline booking | ✅ | ✅ | Both use `PUT /api/bookings/{id}/confirm\|decline` |
| Create booking (client) | ✅ | ✅ | Both use `POST /api/bookings` |
| Working hours | ✅ | ✅ | Both manage availability |
| Client booking window | ✅ | ✅ | Both let clients see available slots |

### Billing

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Subscription status | ✅ | ✅ | Both use `/api/billing/subscription` |
| Stripe connect onboarding | ✅ | ✅ | Both use `/api/billing/stripe-onboarding` |
| Payout history | ✅ | ✅ | Both use `/api/billing/payouts` |
| Revenue overview | ✅ | ✅ | Both use `/api/billing/revenue` |
| Checkout session | ✅ | ✅ | Both use `/api/checkout/session` |
| Billing portal | ✅ | ✅ | Both use `/api/billing/portal` |
| Subscribe-new (trial) | ❌ | ✅ | Next.js has dedicated `subscribe-new` endpoint |

### Admin Panel

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Dashboard stats | ✅ | ✅ | Both use `/api/admin/stats` |
| Event moderation | ✅ | ✅ | Both approve/reject events |
| Blog management | ⚠️ | ✅ | Flutter has list + create; Next.js has full CRUD with edit |
| Ticket management | ✅ | ✅ | Both view/manage support tickets |
| User management | ❌ | ✅ | **Missing** — Next.js has `/admin/users` with profile view |
| Error logs | ❌ | ✅ | **Missing** — Next.js has `/admin/errors` with pagination |
| Feature toggles | ❌ | ✅ | Next.js has `isFreeMode`, `isCustomDomains` toggles |
| Blog post editing | ❌ | ✅ | Next.js has edit form with pre-filled data |

### Auth / Onboarding

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Login (email) | ✅ | ✅ | Both use `POST /api/auth/login` |
| Register | ✅ | ✅ | Both use `POST /api/auth/register` |
| OAuth (Google, Apple) | ✅ | ✅ | Both support OAuth via mobile-signin |
| Forgot password | ✅ | ✅ | Both use `POST /api/auth/forgot-password` |
| Update password | ✅ | ✅ | Both use `POST /api/auth/update-password` |
| Onboarding wizard (8-step) | ✅ | ✅ | Both have multi-step onboarding |
| Role selection | ✅ | ✅ | Both have role selection |
| Email verification | ✅ | ✅ | Both have verification screen |
| Account switching | ✅ | ❌ | **Flutter only** — trainer/client mode switch |

### Public Pages

| Feature | Flutter | Next.js | Notes |
|---------|---------|---------|-------|
| Public trainer profile | ✅ | ✅ | Both show full profile |
| Public event list | ✅ | ✅ | Both show events |
| Blog list | ⚠️ | ✅ | Flutter has blog screens but no GoRouter route for blog |
| Blog post detail | ⚠️ | ✅ | Same as above |
| Pricing page | ❌ | ✅ | Next.js has `/pricing` — Flutter doesn't have this public page |
| Contact page | ❌ | ✅ | Next.js has `/contact` — Flutter has contact form in settings |
| Help page | ❌ | ✅ | Next.js has `/help` with tutorial search |
| API docs | ❌ | ✅ | Next.js has `/docs` with SwaggerUI |
| Home/landing | ❌ | ✅ | Not needed in mobile app |

## Critical Gaps (Should Fix)

| # | Gap | Impact | Effort |
|---|-----|--------|--------|
| 1 | **AI-coached live workout (voice)** | ❌ Missing entirely from Flutter | High — requires voice SDK + AI integration |
| 2 | **Admin: user management** | ❌ No user list/detail | Low — simple list + detail screen |
| 3 | **Admin: error logs** | ❌ No error browsing | Low — list + detail screen |
| 4 | **Admin: feature toggles** | ❌ No flag management | Low — simple toggle UI |
| 5 | **Trainer: sharing requests** | ❌ No sharing request management | Low — new screen |
| 6 | **Trainer: live session monitoring** | ❌ Can't monitor client's active workout | Medium — real-time sync needed |
| 7 | **Trainer: onboarding checklist** | ❌ No profile completion prompt | Low — checklist widget |
| 8 | **Public: pricing page** | ❌ No pricing display | Low — static page |
| 9 | **Chat: media attachments** | ❌ No image/video in messages | Medium — multipart upload |

## Minor Gaps (Nice to Have)

| # | Gap | Notes |
|---|-----|-------|
| 1 | Blog routes not registered | Screens exist, GoRouter routes missing (low priority) |
| 2 | Drag-drop exercise ordering | Next.js has richer drag-drop with sortablejs |
| 3 | AI client insights | Next.js has Gemini-powered insights |
| 4 | Subscribe-new trial flow | Next.js has dedicated trial subscription |
| 5 | Event map (Leaflet) | Next.js has Leaflet, Flutter can use google_maps_flutter |
| 6 | Client's AI coach goal wizard | Next.js has richer wizard |

**Total: 9 critical gaps, 6 minor gaps out of ~120 features compared.**
