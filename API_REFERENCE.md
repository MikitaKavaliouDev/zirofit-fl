# Ziro Fit API Reference

> Complete API documentation for the Ziro Fit platform. Base URL: `https://www.ziro.fit/api` (production) | `http://localhost:3321/api` (dev)

---

## Conventions

### Response Format

All endpoints return JSON with a consistent envelope:

```json
// Success
{ "data": T }

// Error
{ "error": { "message": string, "code"?: string, "details"?: any } }
```

### Authentication

| Method | Header |
|--------|--------|
| Bearer Token | `Authorization: Bearer <access_token>` |
| Cookie Fallback | Supabase `sb-*` session cookies |

### Auth Helpers

| Helper | Purpose |
|--------|---------|
| `requireUserShort(request, roles?)` | Returns `{ userId, role, username, prismaUser }`. Throws 401 if unauthenticated, 403 if wrong role. |
| `getAuthContext(request)` | Returns full `{ supabaseUser, prismaUser }` context. Self-heals Prisma records. |
| `requireRole(request, roles)` | Returns `{ prismaUser, supabaseUser }`. Throws 401/403. |
| `getOptionalUserShort(request)` | Returns user data or `null` if not authenticated (no throw). |

### Error Codes

| Code | Meaning |
|------|---------|
| `auth_missing` | No auth token provided |
| `auth_invalid_token` | Token expired or malformed |
| `auth_forbidden_role` | User lacks required role |
| `client_forbidden` | Trainer does not own this client |
| `session_not_found` | Workout session missing |
| `validation_error` | Zod validation failed |
| `email_in_use` | Email already registered |

### Roles

| Role | Description |
|------|-------------|
| `client` | End user who trains |
| `trainer` | Coach/trainer managing clients |
| `admin` | Platform administrator |
| `pending` | Post-registration, pre-onboarding |

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad request / Invalid JSON |
| 401 | Unauthenticated |
| 403 | Forbidden (wrong role) |
| 404 | Not found |
| 409 | Conflict |
| 422 | Validation error |
| 500 | Internal server error (logged to SystemError table) |

---

## AUTH

### POST /api/auth/login

Authenticates user with email/password. Returns tokens for mobile session persistence.

**Auth:** None  
**Role:** Any  

**Request Body:**
```json
{
  "email": "user@example.com",      // string, email format, required
  "password": "securePassword123"   // string, min 1 char, required
}
```

**Response 200:**
```json
{
  "data": {
    "message": "Login successful.",
    "role": "trainer",
    "user": { /* Supabase User object */ },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

**Status Codes:** 200, 400 (invalid JSON), 401 (invalid credentials), 422 (validation)

---

### POST /api/auth/register

Creates a new user account. Sends verification email. Optionally links to a trainer via `trainerId`.

**Auth:** None  
**Role:** Any  

**Request Body:**
```json
{
  "name": "John Doe",               // string, min 2 chars, optional (defaults to "New User")
  "email": "user@example.com",      // string, email format, required
  "password": "securePassword123",  // string, min 8 chars, required
  "role": "client",                 // string, optional
  "redirect": "https://...",        // string, URL, optional — redirect after email verification
  "trainerId": "uuid"               // string, optional — auto-links client to trainer
}
```

**Response 201:**
```json
{
  "data": {
    "userId": "uuid",
    "message": "Registration successful. Please verify your email.",
    "requiresSubscription": true,
    "confirmationRequired": true
  }
}
```

**Status Codes:** 201, 400 (invalid JSON), 409 (email already registered), 422 (validation), 500 (failed to send email), 502 (auth provider error)

**Notes:** When `trainerId` is provided, the user is forced to `client` role. A placeholder client record is updated or a new one created. The trainer receives a notification.

---

### GET /api/auth/mobile-signin

Initiates OAuth sign-in (Google or Apple) for mobile clients. Redirects to the identity provider.

**Auth:** None  
**Role:** Any  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `provider` | string | `"google"` | OAuth provider: `"google"` or `"apple"` |

**Response 302:** Redirects to Google/Apple OAuth URL

**Response (Error) 400:**
```json
{ "error": "error message" }
```

**Notes:** Sets a short-lived `is-mobile-auth` cookie. The callback URL is `https://www.ziro.fit/en/auth/callback?mobile=true`.

---

### POST /api/auth/signout

Signs out the current session.

**Auth:** Bearer token or session cookie  
**Role:** Any  

**Response 200:**
```json
{ "data": { "message": "Logout successful." } }
```

---

### POST /api/auth/refresh

Refreshes an expired access token using a refresh token.

**Auth:** None (uses the refresh token)  
**Role:** Any  

**Request Body:**
```json
{
  "refreshToken": "eyJ..."  // string, min 1 char, required
}
```

**Response 200:**
```json
{
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresAt": 1700000000,
    "user": { /* Supabase User object */ }
  }
}
```

**Status Codes:** 200, 400 (invalid JSON), 401 (invalid/expired refresh token), 422 (validation)

---

### GET /api/auth/me

Returns the authenticated user's profile. Used to hydrate app state after login/refresh.

**Auth:** Bearer token or session cookie  
**Role:** Any  

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "trainer",
    "username": "john_doe",
    "tier": "PRO",
    "hasCompletedOnboarding": true,
    "subscriptionStatus": "active",
    "profilePhotoPath": "https://...",
    "isFreeAccessModeEnabled": false,
    "metadata": {}
  }
}
```

**Status Codes:** 200, 401, 404 (user_not_found)

**Notes:** Supports fast-path via `x-auth-tier`, `x-auth-username`, `x-auth-email`, `x-auth-role` headers (set by middleware).

---

### POST /api/auth/forgot-password

Sends a password reset email.

**Auth:** None  
**Role:** Any  

**Request Body:**
```json
{
  "email": "user@example.com",     // string, email format, required
  "redirectTo": "https://..."      // string, URL, optional (defaults to auth callback)
}
```

**Response 200:**
```json
{ "data": { "message": "Password reset email sent if the account exists." } }
```

**Status Codes:** 200, 400 (invalid JSON, user not found), 422 (validation)

---

### POST /api/auth/update-password

Updates the password for the currently authenticated user (must be logged in via reset link).

**Auth:** Bearer token or session cookie  
**Role:** Any  

**Request Body:**
```json
{
  "password": "newSecurePassword123"  // string, min 6 chars, required
}
```

**Response 200:**
```json
{ "data": { "message": "Password updated successfully." } }
```

**Status Codes:** 200, 400 (error), 422 (validation)

---

### POST /api/auth/complete-onboarding

Marks the user's onboarding as complete.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{ "data": { "success": true } }
```

---

### POST /api/auth/sync-user

Ensures the authenticated user exists in Prisma (self-healing). Also identifies the user in PostHog.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{
  "data": {
    "message": "User synchronized successfully.",
    "userId": "uuid"
  }
}
```

---

### POST /api/auth/resend-verification-email

Resends the email verification email.

**Auth:** None  
**Role:** Any  

**Request Body:**
```json
{
  "email": "user@example.com",   // string, email format, required
  "redirect": "https://..."      // string, URL, optional
}
```

**Response 200:**
```json
{ "data": { "message": "Verification email sent successfully." } }
```

**Status Codes:** 200 (always, for security), 400 (resend_failed), 422 (validation)

---

## SYNC

### GET /api/sync/pull

Pulls all data changed since the given timestamp. Used for offline-first mobile sync.

**Auth:** Bearer token  
**Role:** Any  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `last_pulled_at` | integer | `0` | Unix timestamp (ms) of last successful pull |

**Response 200:**
```json
{
  "data": {
    "changes": {
      "clients": { "created": [...], "updated": [...], "deleted": [...] },
      "profiles": { "created": [...], "updated": [...], "deleted": [...] },
      "trainer_profiles": { "created": [...], "updated": [...], "deleted": [...] },
      "workout_sessions": { "created": [...], "updated": [...], "deleted": [...] },
      "exercises": { "created": [...], "updated": [...], "deleted": [...] }
    },
    "timestamp": 1700000000000
  }
}
```

**Synced Tables (17):** The sync protocol uses the following table names (snake_case on the wire, camelCase in local DB):
- `clients` — Trainer's client records
- `profiles` — Own user profile
- `trainer_profiles` — Trainer's professional profile
- `workout_sessions` — Workout sessions for trainer's clients
- `exercises` — System exercises + trainer's custom exercises
- `workout_templates` — Workout templates from trainer's programs
- `client_assessments` — Assessment results for trainer's clients
- `client_measurements` — Client body measurements
- `client_photos` — Client progress photos
- `client_exercise_logs` — Individual exercise log entries within sessions
- `trainer_services` — Services offered on trainer's profile
- `trainer_packages` — Session packages sold by trainer
- `trainer_testimonials` — Client testimonials on trainer's profile
- `trainer_programs` — Workout programs created by trainer
- `calendar_events` — Calendar/booked time slots (maps to Booking model)
- `notifications` — User notifications
- `bookings` — Client booking requests (maps to Booking model)

> **IMPORTANT:** See `OFFLINE_SYNC.md` for the complete local Drift database schema matching these tables exactly.

---

### POST /api/sync/push

Pushes local changes to the server. Accepts the same structure as pull `changes`.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "changes": {
    "clients": { "created": [...], "updated": [...], "deleted": [...] },
    "workout_sessions": { "created": [...], "updated": [...], "deleted": [...] }
  }
}
```

**Response 200:**
```json
{ "data": { "timestamp": 1700000000001 } }
```

**Conflict Resolution:** Server uses last-write-wins strategy — compares `updatedAt` timestamps. If server version is newer, server wins. If client is newer, client changes are applied.

**Wire Format:** Data transfers use snake_case keys. All DateTime values are Unix timestamps in milliseconds (integers). Soft deletes use `deleted_at` field.

---

## WORKOUT SESSIONS

### POST /api/workout-sessions/start

Starts a new workout session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "clientId": "uuid",             // string, optional — required for trainer starting on behalf of client
  "plannedSessionId": "uuid",     // string, optional — start a PLANNED session
  "templateId": "uuid",           // string, optional — start from a template
  "clientPackageId": "uuid"       // string, optional — associate with a client package
}
```

**Response 200:**
```json
{
  "data": {
    "session": { /* WorkoutSession object */ }
  }
}
```

**Status Codes:** 200, 400 (invalid JSON), 422 (validation)

---

### POST /api/workout-sessions/plan

Plans/schedules a workout session from a template for a future date.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "templateId": "uuid",         // string, required
  "plannedDate": "2024-01-15T10:00:00Z",  // string (ISO date), required
  "clientId": "uuid"            // string, optional — required for trainers
}
```

**Response 201:**
```json
{ "data": { "session": { /* WorkoutSession with status PLANNED */ } } }
```

**Status Codes:** 201, 403 (client_forbidden), 422 (validation)

---

### GET /api/workout-sessions/live

Gets the currently active (IN_PROGRESS) workout session for the user.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Response 200:**
```json
{
  "data": {
    "session": { /* WorkoutSession with exerciseLogs */ } | null
  }
}
```

---

### POST /api/workout-sessions/live

Upserts an exercise log entry in the active workout session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "logId": "uuid",               // string, optional — null for new log
  "workoutSessionId": "uuid",    // string, required
  "exerciseId": "uuid",          // string, required
  "reps": 10,                    // number, min 0, required
  "weight": 50.5,                // number, optional, nullable
  "order": 1,                    // number, optional (auto if omitted)
  "supersetKey": "superset_1",   // string, optional, nullable
  "orderInSuperset": 1,          // number, optional, nullable
  "isCompleted": true            // boolean, optional, nullable
}
```

**Response 200 (update) / 201 (create):**
```json
{
  "data": {
    "log": { /* ClientExerciseLog */ },
    "newRecords": [ /* any new PersonalRecord entries */ ]
  }
}
```

---

### POST /api/workout-sessions/finish

Completes a workout session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "workoutSessionId": "uuid",   // string, required
  "notes": "Great workout!"     // string, optional, nullable
}
```

**Response 200:**
```json
{ "data": { "session": { /* WorkoutSession with status COMPLETED */ } } }
```

---

### GET /api/workout-sessions/history

Returns paginated completed workout sessions.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clientId` | string | — | Filter by client (trainer role) |
| `limit` | integer | 20 | Max results (1–100) |
| `cursor` | string | — | ISO date string for cursor-based pagination |

**Response 200:**
```json
{
  "data": {
    "sessions": [ /* WorkoutSession[] */ ],
    "nextCursor": "2024-01-01T00:00:00.000Z",
    "hasMore": true
  }
}
```

---

### GET /api/workout-sessions/[id]

Gets detailed session info including exercise logs, template, and client info.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Response 200:**
```json
{
  "data": {
    "session": {
      "id": "uuid",
      "status": "COMPLETED",
      "startTime": "2024-01-01T10:00:00Z",
      "endTime": "2024-01-01T11:00:00Z",
      "notes": "string",
      "workoutTemplate": { "id": "uuid", "name": "Full Body" },
      "workoutTemplateId": "uuid",
      "client": { "id": "uuid", "name": "Client Name" },
      "exerciseLogs": [
        {
          "id": "uuid",
          "reps": 10,
          "weight": 50,
          "exercise": { "id": "uuid", "name": "Bench Press", "muscleGroup": "Chest" }
        }
      ]
    }
  }
}
```

---

### PUT /api/workout-sessions/[id]

Updates session notes.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Request Body:**
```json
{
  "notes": "Updated notes here"  // string, optional, nullable
}
```

**Response 200:**
```json
{ "data": { "session": { /* updated WorkoutSession */ } } }
```

---

### POST /api/workout-sessions/[id]/exercises

Adds exercises to an in-progress workout session. Creates placeholder logs with 0 reps.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Request Body:**
```json
{
  "exerciseIds": ["uuid1", "uuid2"]  // array of strings, min 1, required
}
```

**Response 201:**
```json
{
  "data": {
    "logs": [
      {
        "id": "uuid",
        "reps": 0,
        "weight": null,
        "order": 0,
        "exercise": { "id": "uuid", "name": "Bench Press" }
      }
    ]
  }
}
```

**Status Codes:** 201, 400 (session_not_active), 403 (unauthorized), 404 (exercises_not_found)

---

### DELETE /api/workout-sessions/[id]/exercises/[exerciseId]

Soft-deletes an exercise log from a workout session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |
| `exerciseId` | string | **Exercise Log ID** (not generic exercise ID) |

**Response 200:**
```json
{ "data": { "message": "Exercise removed successfully." } }
```

**Status Codes:** 200, 400 (session not active), 403 (unauthorized), 404

---

### GET /api/workout-sessions/[id]/summary

Returns a rich summary of a completed workout session including best set, total workouts count, and new records count.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Response 200:**
```json
{
  "data": {
    "session": { /* full WorkoutSession with exerciseLogs, template */ },
    "totalWorkouts": 25,
    "bestSet": {
      "exerciseName": "Bench Press",
      "reps": 10,
      "weight": 80
    },
    "newRecordsCount": 2
  }
}
```

---

### POST /api/workout-sessions/[id]/comments

Adds a comment to a workout session (trainer feedback).

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Request Body:**
```json
{
  "commentText": "Great form on those squats!"  // string, required
}
```

**Response 201:**
```json
{ "data": { "comment": { /* SessionComment object */ } } }
```

---

### POST /api/workout-sessions/[id]/cancel

Cancels a workout session (sets status to CANCELLED).

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Response 200:**
```json
{ "data": { "message": "Workout cancelled successfully" } }
```

---

### POST /api/workout-sessions/[id]/rest/start

Starts the rest timer for a session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Response 200:**
```json
{ "data": { "message": "Rest started." } }
```

---

### POST /api/workout-sessions/[id]/rest/end

Ends the rest timer for a session (sets `restStartedAt` to null).

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Response 200:**
```json
{ "data": { "message": "Rest ended." } }
```

---

### POST /api/workout-sessions/[id]/save-as-template

Saves a completed/in-progress workout session as a reusable template.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout session ID |

**Request Body:**
```json
{
  "templateName": "My Custom Workout"  // string, min 1 char, required
}
```

**Response 201:**
```json
{ "data": { "message": "Workout saved as template." } }
```

---

### POST /api/workout/log

Upserts an exercise log (alternative to /live POST). Supports `tempo` and `side` fields.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "logId": "uuid",               // string, optional, nullable
  "workoutSessionId": "uuid",    // string, required
  "exerciseId": "uuid",          // string, required
  "reps": 10,                    // number, min 0, required
  "weight": 50.5,                // number, min 0, optional, nullable
  "order": 1,                    // number, optional
  "isCompleted": true,           // boolean, optional, nullable
  "tempo": "2010",               // string, optional, nullable
  "side": "LEFT"                 // string, optional, nullable ("BOTH", "LEFT", "RIGHT")
}
```

**Response 200 (update) / 201 (create):**
```json
{
  "data": {
    "log": { /* ClientExerciseLog */ },
    "newRecords": [ /* PersonalRecord[] */ ]
  }
}
```

---

## WORKOUT TEMPLATES

### GET /api/workout-templates/[id]

Returns a workout template with its exercises.

**Auth:** Bearer token  
**Role:** Any  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Workout template ID |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Full Body A",
    "exercises": [
      {
        "id": "uuid",
        "order": 0,
        "exerciseId": "uuid",
        "exercise": { "id": "uuid", "name": "Bench Press" },
        "notes": "4x8-12"
      }
    ]
  }
}
```

---

## EXERCISES

### GET /api/exercises

Searches and lists exercises with full-text search and pagination. Returns system exercises + trainer's custom exercises.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `search` | string | `""` | Full-text search query |
| `limit` | integer | `20` | Items per page (1–50) |
| `page` | integer | `1` | Page number |

**Response 200:**
```json
{
  "data": {
    "exercises": [
      {
        "id": "uuid",
        "name": "Bench Press",
        "muscleGroup": "Chest",
        "equipment": "Barbell",
        "category": "Strength",
        "videoUrl": "https://...",
        "description": "Lie on bench, press bar up"
      }
    ],
    "total": 150,
    "page": 1,
    "hasMore": true
  }
}
```

---

### GET /api/exercises/find-media

Finds or generates an AI media URL for a given exercise name.

**Auth:** Bearer token  
**Role:** Any  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | — | Exercise name (required) |

**Response 200:**
```json
{
  "data": {
    "mediaUrl": "https://.../exercise_media.png"
  }
}
```

**Status Codes:** 200, 400 (name required)

---

### GET /api/exercises/sync

Syncs exercises changed since a timestamp. Supports offline sync.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `lastPulledAt` | integer | `0` | Unix timestamp (ms) |

**Response 200:**
```json
{
  "data": {
    "changes": [
      {
        "id": "uuid",
        "name": "Bench Press",
        "muscleGroup": "Chest",
        "equipment": "Barbell",
        "category": "Strength",
        "videoUrl": "https://...",
        "description": "...",
        "updatedAt": "2024-01-15T10:00:00.000Z",
        "deletedAt": null
      }
    ],
    "timestamp": 1700000000000
  }
}
```

---

## CLIENT-FACING ENDPOINTS

### GET /api/client/dashboard

Returns the client's home dashboard: profile, trainer info, upcoming sessions, recent activity, measurements.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "clientData": {
      "id": "uuid",
      "userId": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "trainer": { "id": "uuid", "name": "Trainer Name", "username": "trainer", "email": "trainer@example.com" },
      "workoutSessions": [
        {
          "id": "uuid",
          "startTime": "2024-01-15T10:00:00Z",
          "endTime": "2024-01-15T11:00:00Z",
          "status": "COMPLETED",
          "name": "Full Body A",
          "isTrainerLed": false,
          "exerciseLogs": []
        }
      ],
      "measurements": [ /* ClientMeasurement[] */ ]
    },
    "weightUnit": "KG",
    "upcomingClientSessions": [
      { "id": "uuid", "title": "Full Body B", "date": "2024-01-20T10:00:00Z", "duration": 60 }
    ],
    "lastCheckIn": "2024-01-10T10:00:00.000Z"
  }
}
```

**Status Codes:** 200, 404 (client profile not found)

---

### GET /api/client/programs

Returns all program assignments with their programs and templates.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
[
  {
    "assignmentId": "uuid",
    "startDate": "2024-01-01T00:00:00Z",
    "isActive": true,
    "program": {
      "id": "uuid",
      "name": "Beginner Program",
      "description": "...",
      "templates": [
        {
          "id": "uuid",
          "name": "Workout A",
          "order": 0,
          "_count": { "exercises": 8 }
        }
      ]
    }
  }
]
```

---

### POST /api/client/programs

Generates an AI program for the client.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "duration": "week",    // string, "week" or "month", required
  "focus": "strength"    // string, focus/goal description, required
}
```

**Response 201:**
```json
{ "data": { /* generated program result */ } }
```

---

### GET /api/client/progress

Returns progress data: weight history, body fat, volume, exercise performance stats.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "weight": [ { "date": "2024-01-01", "value": 80 } ],
    "bodyFat": [ { "date": "2024-01-01", "value": 15 } ],
    "volume": [ { "date": "2024-01-01", "value": 5000 } ],
    "exercisePerformance": [ /* stats */ ],
    "favoriteExercises": [ /* stats */ ],
    "worstPerformingExercises": [ /* stats */ ]
  }
}
```

---

### GET /api/client/habits

Returns active habits for the client.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "habits": [
      {
        "id": "uuid",
        "title": "Drink 8 glasses of water",
        "description": "...",
        "frequency": "DAILY",
        "logs": [ /* habit logs */ ]
      }
    ]
  }
}
```

---

### POST /api/client/habits/[habitId]/log

Logs a habit completion for a given date.

**Auth:** Bearer token  
**Role:** `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `habitId` | string | Habit ID |

**Request Body:**
```json
{
  "date": "2024-01-15",        // string (ISO date), required
  "isCompleted": true,         // boolean, required
  "note": "Felt great today"   // string, optional, nullable
}
```

**Response 201:**
```json
{ "data": { "log": { /* HabitLog object */ } } }
```

---

### GET /api/client/trainer

Returns the client's linked trainer info.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{
  "data": {
    "trainer": {
      "id": "uuid",
      "name": "Trainer Name",
      "email": "trainer@example.com",
      "profile": {
        "profilePhotoPath": "https://...",
        "aboutMe": "Experienced coach"
      }
    } | null
  }
}
```

---

### DELETE /api/client/trainer

Unlinks the client from their trainer.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{ "data": { "message": "Unlinked from trainer" } }
```

---

### GET /api/client/trainer/link

Checks if the client is linked to a specific trainer.

**Auth:** Bearer token  
**Role:** `client`  

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `trainerId` | string | Trainer user ID (optional if trainerUsername provided) |
| `trainerUsername` | string | Trainer username (optional if trainerId provided) |

**Response 200:**
```json
{ "data": { "isLinked": true } }
```

---

### POST /api/client/trainer/link

Sends a link request from client to trainer (creates a notification for the trainer).

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:**
```json
{
  "trainerUsername": "trainer_john"  // string, required
}
```

**Response 200:**
```json
{ "data": { "message": "Request sent to trainer." } }
```

---

### DELETE /api/client/trainer/link

Stops sharing data with the trainer (unlinks).

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{ "data": { "message": "Successfully stopped sharing data with trainer." } }
```

---

### GET /api/client/events

Returns all event bookings for the client.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "bookings": [
      {
        "id": "uuid",
        "status": "CONFIRMED",
        "event": {
          "id": "uuid",
          "title": "Yoga Workshop",
          "startTime": "2024-01-20T10:00:00Z",
          "trainer": { "name": "Trainer", "email": "trainer@test.com" }
        }
      }
    ]
  }
}
```

---

### PUT /api/client/events/[bookingId]/cancel

Cancels a client's event booking.

**Auth:** Bearer token  
**Role:** `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `bookingId` | string | Event booking ID |

**Response 200:**
```json
{ "data": { "booking": { /* updated EventBooking with status CANCELLED */ } } }
```

---

### GET /api/client/sharing

Returns the client's data sharing settings.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "expiresAt": "2025-01-15T00:00:00Z",
    "duration": "30_days",
    "settings": {
      "workouts": true,
      "measurements": true,
      "photos": true,
      "checkins": true
    }
  }
}
```

---

### PUT /api/client/sharing

Updates data sharing duration and/or settings.

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:**
```json
{
  "duration": "30_days",   // string: "30_days", "90_days", "forever", optional
  "settings": {            // object, optional
    "workouts": true,
    "measurements": true,
    "photos": false,
    "checkins": true
  }
}
```

**Response 200:**
```json
{ "data": { "success": true } }
```

---

### POST /api/client/upload

Uploads an image file (progress photo, etc.) to Supabase storage.

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `file` | File | Image file (JPEG, PNG, WebP, HEIC), max 10MB |

**Response 200:**
```json
{
  "data": {
    "imagePath": "userId/uploads/1234_uuid.jpg",
    "publicUrl": "https://..."
  }
}
```

---

### POST /api/client/ai/generate

Generates a workout plan using AI for a client.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "clientId": "uuid",           // string, required
  "content": "Build strength",  // string, required (or "userIntent" as alias)
  "trainerId": "uuid",          // string, optional
  "senderId": "uuid"            // string, optional
}
```

**Response 200:**
```json
{
  "success": true,
  "data": { /* generated workout plan */ }
}
```

---

### GET /api/client/resource-vault

Returns resources assigned to the client by their trainer.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "resources": [ /* ResourceAssignment[] */ ]
  }
}
```

---

### GET /api/client/program/active

Returns the client's active program with template progress.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "program": { "id": "uuid", "name": "Beginner Program", "description": "..." },
    "progress": {
      "completedCount": 3,
      "totalCount": 12,
      "progressPercentage": 25,
      "nextTemplateId": "uuid"
    },
    "templates": [
      { "id": "uuid", "name": "Workout A", "order": 0, "status": "COMPLETED", "exerciseCount": 8 }
    ]
  }
}
```

---

### PUT /api/client/program/active

Sets the active program for the client.

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:**
```json
{
  "programId": "uuid"  // string, required
}
```

**Response 200:**
```json
{ "data": { "success": true } }
```

---

### GET /api/client/analytics

Returns analytics data: heatmap dates, volume history, muscle distribution, recent PRs, consistency score.

**Auth:** Bearer token  
**Role:** `client`  

**Response 200:**
```json
{
  "data": {
    "heatmapDates": ["2024-01-01", "2024-01-03"],
    "volumeHistory": [ { "date": "2024-01-01", "volume": 5000 } ],
    "muscleDistribution": [ { "muscle": "Chest", "count": 12 } ],
    "recentPRs": [
      { "exercise": "Bench Press", "value": 100, "type": "weight", "date": "2024-01-15" }
    ],
    "consistency": 67
  }
}
```

---

### POST /api/client/check-in

Submits a weekly check-in with metrics and optional photos.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "weight": 80,                   // number, optional
  "waistCm": 85,                  // number, optional
  "sleepHours": 7.5,              // number, optional
  "energyLevel": 4,               // number, optional (1-5)
  "stressLevel": 3,               // number, optional (1-5)
  "hungerLevel": 3,               // number, optional (1-5)
  "digestionLevel": 4,            // number, optional (1-5)
  "nutritionCompliance": 80,      // number, optional (0-100)
  "clientNotes": "Felt strong",   // string, optional
  "photos": [                     // array, optional
    {
      "imagePath": "path/to/photo.jpg",
      "caption": "Front view",
      "date": "2024-01-15"
    }
  ]
}
```

**Response 200:**
```json
{ "data": { /* created CheckIn object */ } }
```

**Notes:** Also creates a `ClientMeasurement` entry if `weight` is provided. Sends notification to trainer.

---

## TRAINER: CLIENTS

### GET /api/clients

Lists all clients for the trainer with search and sort.

**Auth:** Bearer token  
**Role:** `trainer`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `search` | string | — | Search by name or email |
| `sortBy` | string | `"name"` | Sort field |
| `sortOrder` | string | `"asc"` | `"asc"` or `"desc"` |

**Response 200:**
```json
{
  "data": {
    "clients": [
      {
        "id": "uuid",
        "name": "John Doe",
        "email": "john@example.com",
        "status": "active",
        "avatarPath": "https://...",
        "lastCheckIn": "2024-01-10",
        "upcomingSession": "2024-01-20"
      }
    ],
    "isPremium": true
  }
}
```

---

### POST /api/clients

Creates a new client record (placeholder, no user account yet).

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "name": "John Doe",          // string, min 1 char, required
  "email": "john@example.com", // string, email, required
  "phone": "+1234567890",      // string, optional, nullable
  "status": "active"           // string: "active", "inactive", "pending" (default: "pending")
}
```

**Response 201:**
```json
{ "data": { "client": { /* created Client object */ } } }
```

**Status Codes:** 201, 402 (client_limit_reached), 409 (user_exists with email)

---

### GET /api/clients/[id]

Returns detailed client info for a trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "client": { /* Client with profile details */ } } }
```

---

### PUT /api/clients/[id]

Updates client details.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "name": "John Updated",          // string, optional
  "email": "newemail@example.com",  // string, email, optional
  "phone": "+1234567890",           // string, optional, nullable
  "status": "active",               // string, optional
  "checkInDay": 1,                  // number (0=Sun..6=Sat), optional, nullable
  "checkInHour": 9                  // number (0-23), optional, nullable
}
```

**Response 200:**
```json
{ "data": { "client": { /* updated Client */ } } }
```

---

### DELETE /api/clients/[id]

Soft-deletes a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "message": "Client deleted." } }
```

---

### GET /api/clients/[id]/dashboard

Returns the trainer's view of a client's dashboard data.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{
  "data": {
    "client": { /* Client details */ },
    "recentSessions": [ /* WorkoutSession[] */ ],
    "measurements": [ /* ClientMeasurement[] */ ],
    "checkIns": [ /* CheckIn[] */ ],
    "habits": [ /* Habit[] */ ],
    "recentPRs": [ /* PersonalRecord[] */ ],
    "progressPhotos": [ /* ClientProgressPhoto[] */ ]
  }
}
```

---

### GET /api/clients/[id]/assessments

Lists assessment results for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "assessmentResults": [ /* AssessmentResult[] */ ] } }
```

---

### POST /api/clients/[id]/assessments

Creates a new assessment result for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "assessmentId": "uuid",       // string, required
  "value": 80.5,                // number, required
  "date": "2024-01-15",         // string (ISO date), optional
  "notes": "Improved flexibility" // string, optional
}
```

**Response 201:**
```json
{ "data": { "assessmentResult": { /* created AssessmentResult */ } } }
```

---

### PUT /api/clients/[id]/assessments/[resultId]

Updates an assessment result.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `resultId` | string | Assessment result ID |

**Response 200:**
```json
{ "data": { "assessmentResult": { /* updated */ } } }
```

---

### DELETE /api/clients/[id]/assessments/[resultId]

Deletes an assessment result.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `resultId` | string | Assessment result ID |

**Response 200:**
```json
{ "data": { "assessmentResult": { /* deleted */ } } }
```

---

### GET /api/clients/[id]/measurements

Lists measurements for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "measurements": [ /* ClientMeasurement[] */ ] } }
```

---

### POST /api/clients/[id]/measurements

Creates a measurement record for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "measurementDate": "2024-01-15",  // string, ISO date, required
  "weightKg": 80,                    // number, optional
  "bodyFatPercentage": 15,           // number, optional
  "chestCm": 100,                    // number, optional
  "waistCm": 85,                     // number, optional
  "hipCm": 95,                       // number, optional
  "leftArmCm": 35,                   // number, optional
  "rightArmCm": 35,                  // number, optional
  "leftThighCm": 55,                 // number, optional
  "rightThighCm": 55,                // number, optional
  "notes": "Good progress"           // string, optional
}
```

**Response 201:**
```json
{ "data": { "measurement": { /* created ClientMeasurement */ } } }
```

---

### PUT /api/clients/[id]/measurements/[measurementId]

Updates a measurement.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `measurementId` | string | Measurement ID |

**Response 200:**
```json
{ "data": { "measurement": { /* updated */ } } }
```

---

### DELETE /api/clients/[id]/measurements/[measurementId]

Deletes a measurement.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `measurementId` | string | Measurement ID |

**Response 200:**
```json
{ "data": { "measurement": { /* deleted */ } } }
```

---

### GET /api/clients/[id]/photos

Lists progress photos for a client (paginated).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | `30` | Items per page |
| `offset` | integer | `0` | Offset |

**Response 200:**
```json
{
  "data": {
    "photos": [ /* ClientProgressPhoto[] */ ],
    "totalCount": 50,
    "limit": 30,
    "offset": 0
  }
}
```

---

### POST /api/clients/[id]/photos

Uploads a progress photo for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `photo` | File | Image file (max 2MB) |
| `photoDate` | string | ISO date string |
| `caption` | string | Optional caption |

**Response 201:**
```json
{ "data": { "progressPhoto": { /* created record with publicUrl */ } } }
```

---

### DELETE /api/clients/[id]/photos/[photoId]

Deletes a progress photo.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `photoId` | string | Photo ID |

**Response 200:**
```json
{ "data": { "photo": { /* deleted photo */ } } }
```

---

### POST /api/clients/[id]/exercise-logs

Creates an exercise log for a client (trainer enters data manually).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "sessionId": "uuid",             // string, required
  "exerciseId": "uuid",            // string, required
  "reps": 10,                      // number, required
  "weight": 50.5,                  // number, optional
  "notes": "Felt heavy"            // string, optional
}
```

**Response 201:**
```json
{ "data": { "newLog": { /* created ClientExerciseLog */ } } }
```

---

### GET /api/clients/[id]/sessions

Lists workout sessions for a client (paginated).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | `50` | Items per page (1–100) |
| `offset` | integer | `0` | Offset |

**Response 200:**
```json
{
  "data": {
    "sessions": [ /* WorkoutSession[] */ ],
    "totalCount": 100,
    "limit": 50,
    "offset": 0
  }
}
```

---

### PUT /api/clients/[id]/sessions/[sessionId]

Updates a log entry for a session (trainer edits session details).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `sessionId` | string | Session ID |

**Request Body:**
```json
{
  "sessionDate": "2024-01-15T10:00:00Z",  // string (ISO), required
  "durationMinutes": 60,                    // number, positive, required
  "activitySummary": "Full body workout",   // string, required
  "sessionNotes": "Client felt strong"      // string, optional, nullable
}
```

**Response 200:**
```json
{ "data": { "updatedSession": { /* updated WorkoutSession */ } } }
```

---

### DELETE /api/clients/[id]/sessions/[sessionId]

Deletes a workout session log entry.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |
| `sessionId` | string | Session ID |

**Response 200:**
```json
{ "data": { "deletedId": "uuid" } }
```

---

### GET /api/clients/[id]/session/active

Gets the active session for a client (trainer view).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "session": { /* active WorkoutSession */ } | null } }
```

---

### GET /api/clients/[id]/program/active

Returns the active program for a client (trainer view).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{
  "data": {
    "program": { "id": "uuid", "name": "Beginner Program" },
    "progress": { "completedCount": 3, "totalCount": 12, "progressPercentage": 25, "nextTemplateId": "uuid" },
    "templates": [ /* Template[] with status */ ]
  }
}
```

---

### POST /api/clients/[id]/insights

Generates AI insights for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ /* AI-generated insights object */ }
```

---

### POST /api/clients/[id]/avatar

Uploads a client's avatar image.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `file` | File | Image (JPEG, PNG, WebP, GIF, HEIC), max 5MB |

**Response 200:**
```json
{ "data": { "avatarUrl": "https://..." } }
```

---

### DELETE /api/clients/[id]/avatar

Removes a client's avatar.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "message": "Avatar removed." } }
```

---

### GET /api/clients/[id]/packages

Lists packages assigned to/purchased by a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "packages": [ /* ClientPackage[] */ ] } }
```

---

### POST /api/clients/invite

Invites a new client by email. Creates a placeholder client record and sends an invitation email.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "name": "John Doe",           // string, min 1 char, required
  "email": "john@example.com",  // string, email, required
  "phone": "+1234567890"        // string, optional, nullable
}
```

**Response 201:**
```json
{
  "data": {
    "message": "Invitation sent",
    "client": { /* placeholder Client */ }
  }
}
```

**Status Codes:** 201, 402 (limit_reached), 409 (already_linked, user_exists)

---

### POST /api/clients/request-link

Sends a connection request from a trainer to an existing Ziro Fit user by email.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "email": "client@example.com"  // string, required
}
```

**Response 200:**
```json
{ "data": { "message": "Connection request sent." } }
```

---

## TRAINER: CALENDAR

### GET /api/trainer/calendar

Returns unified calendar events (workout sessions + bookings) for a date range.

**Auth:** Bearer token  
**Role:** `trainer`  

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `startDate` | string (ISO) | Required, start of range |
| `endDate` | string (ISO) | Required, end of range |

**Response 200:**
```json
{
  "data": {
    "events": [
      {
        "id": "uuid",
        "title": "Session with John",
        "startTime": "2024-01-15T10:00:00Z",
        "endTime": "2024-01-15T11:00:00Z",
        "type": "workout_session",
        "clientId": "uuid",
        "clientName": "John Doe",
        "status": "PLANNED"
      }
    ]
  }
}
```

---

### POST /api/trainer/calendar

Creates planned workout sessions (single or recurring).

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "clientId": "uuid",                              // string, required
  "startTime": "2024-01-15T10:00:00Z",             // string (ISO), required
  "endTime": "2024-01-15T11:00:00Z",               // string (ISO), required
  "notes": "Focus on form",                         // string, optional, nullable
  "templateId": "uuid",                             // string, optional, nullable
  "repeats": true,                                  // boolean, optional
  "repeatWeeks": 4,                                 // number (0-12), optional
  "repeatDays": [1, 3],                             // number[] (0=Sun..6=Sat), optional
  "clientStartDay": 1                               // number (0-6), optional
}
```

**Response 201:**
```json
{ "data": { "message": "4 session(s) planned successfully." } }
```

**Notes:** Checks for booking conflicts. Creates notifications for clients.

---

### PUT /api/trainer/calendar/[sessionId]

Updates a planned session (reschedule).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `sessionId` | string | Session ID |

**Request Body:**
```json
{
  "startTime": "2024-01-16T10:00:00Z",   // string (ISO), required
  "endTime": "2024-01-16T11:00:00Z",     // string (ISO), required
  "notes": "Rescheduled",                 // string, optional
  "templateId": "uuid"                    // string, optional
}
```

**Response 200:**
```json
{ "data": { "updatedSession": { /* updated WorkoutSession */ } } }
```

---

### DELETE /api/trainer/calendar/[sessionId]

Deletes a planned session.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `sessionId` | string | Session ID |

**Response 200:**
```json
{ "data": { "deletedId": "uuid" } }
```

---

### POST /api/trainer/calendar/sessions/[sessionId]/remind

Sends a reminder notification to the client for a planned session.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `sessionId` | string | Session ID |

**Response 200:**
```json
{ "data": { "message": "Reminder sent." } }
```

---

### GET /api/trainer/calendar/clients-summary

Lightweight endpoint returning client identity data for calendar rendering. Returns which clients have sessions on which dates.

**Auth:** Bearer token  
**Role:** `trainer`  

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `startDate` | string (ISO) | Required |
| `endDate` | string (ISO) | Required |

**Response 200:**
```json
{
  "data": {
    "summary": [
      {
        "date": "2024-01-15T00:00:00.000Z",
        "clientId": "uuid",
        "clientFirstName": "John",
        "clientLastName": "Doe",
        "clientAvatarUrl": "https://..."
      }
    ]
  }
}
```

---

## TRAINER: CHECK-INS

### GET /api/trainer/check-ins

Lists check-ins filtered by status.

**Auth:** Bearer token  
**Role:** `trainer`, `admin`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `status` | string | `"SUBMITTED"` | `"SUBMITTED"` or `"REVIEWED"` |

**Response 200:**
```json
{
  "data": [
    {
      "id": "uuid",
      "clientId": "uuid",
      "clientName": "John Doe",
      "date": "2024-01-15T10:00:00Z",
      "status": "SUBMITTED",
      "weight": 80,
      "photos": [ /* CheckInPhoto[] */ ]
    }
  ]
}
```

---

### GET /api/trainer/check-ins/[id]

Returns a single check-in with trends (last 4 previous check-ins).

**Auth:** Bearer token  
**Role:** `trainer`, `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Check-in ID |

**Response 200:**
```json
{
  "data": {
    "current": { /* full CheckIn with client, photos, reviewedBy */ },
    "previous": { /* previous CheckIn or null */ },
    "history": [ /* last 4 check-ins in chronological order */ ]
  }
}
```

---

### DELETE /api/trainer/check-ins/[id]

Deletes a check-in.

**Auth:** Bearer token  
**Role:** `trainer`, `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Check-in ID |

**Response 200:**
```json
{ "data": { "message": "Check-in deleted successfully." } }
```

---

### PATCH /api/trainer/check-ins/[id]/review

Submits a trainer's review/response for a check-in.

**Auth:** Bearer token  
**Role:** `trainer`, `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Check-in ID |

**Request Body:**
```json
{
  "trainerResponse": "Great progress! Let's increase the weight next week."  // string, required
}
```

**Response 200:**
```json
{ "data": { /* updated CheckIn with REVIEWED status */ } }
```

---

### GET /api/trainer/check-ins/pending

Returns all pending (SUBMITTED) check-ins for the trainer's clients.

**Auth:** Bearer token  
**Role:** `trainer`, `admin`  

**Response 200:**
```json
{ "data": [ /* CheckIn[] with client and photos */ ] }
```

---

## TRAINER: PROGRAMS / TEMPLATES

### GET /api/trainer/programs

Lists programs and templates. Supports lightweight mode for calendar exercise picker.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `lightweight` | boolean | `false` | If true, returns only templates (for calendar picker) |

**Response 200 (trainer, full):**
```json
{
  "data": {
    "programs": [
      {
        "id": "uuid",
        "name": "Beginner Program",
        "description": "...",
        "templates": [
          { "id": "uuid", "name": "Workout A", "order": 0, "exerciseCount": 8 }
        ]
      }
    ]
  }
}
```

**Response 200 (lightweight):**
```json
{
  "data": {
    "templates": [
      { "id": "uuid", "name": "Workout A" }
    ]
  }
}
```

---

### POST /api/trainer/programs

Creates a new workout program.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Request Body:**
```json
{
  "name": "My Program",         // string, min 1 char, required
  "description": "Description"  // string, optional, nullable
}
```

**Response 201:**
```json
{ "data": { "program": { /* created WorkoutProgram */ } } }
```

---

### POST /api/trainer/programs/templates

Creates a new workout template within a program.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Request Body:**
```json
{
  "name": "Workout A",           // string, min 1 char, required
  "description": "Description", // string, optional, nullable
  "programId": "uuid"            // string, required
}
```

**Response 201:**
```json
{ "data": { "template": { /* created WorkoutTemplate */ } } }
```

---

### GET /api/trainer/programs/templates

Lists templates for calendar use (trainer) or client-facing view (client gets trainer + system templates).

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Response 200 (trainer):**
```json
{ "data": { "templates": [ { "id": "uuid", "name": "Full Body" } ] } }
```

**Response 200 (client):**
```json
{
  "data": {
    "templates": [
      { "id": "uuid", "name": "Full Body", "source": "trainer" },
      { "id": "uuid", "name": "System Workout", "source": "system" }
    ]
  }
}
```

---

### POST /api/trainer/programs/templates/[templateId]/exercises

Adds an exercise to a template.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `templateId` | string | Template ID |

**Request Body:**
```json
{
  "exerciseId": "uuid",           // string, required
  "targetReps": "8-12",           // string, optional, nullable
  "targetSets": 4,                // number, min 1, optional, nullable
  "durationSeconds": 60,          // number, optional, nullable
  "tempo": "2010",                // string, optional, nullable
  "enableRpe": true,              // boolean, optional, nullable
  "notes": "Keep core tight",     // string, optional, nullable
  "supersetGroupId": "group1",    // string, optional, nullable
  "supersetOrder": 1              // number, optional, nullable
}
```

**Response 201:**
```json
{ "data": { "templateExercise": { /* created TemplateExercise */ } } }
```

---

### DELETE /api/trainer/programs/templates/[templateId]/exercises/[exerciseStepId]

Removes an exercise step from a template.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `templateId` | string | Template ID |
| `exerciseStepId` | string | Template exercise step ID |

**Response 200:**
```json
{ "data": { "message": "Exercise step deleted successfully" } }
```

---

### POST /api/trainer/programs/templates/[templateId]/copy

Copies a system template to the user's own library.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `templateId` | string | System template ID to copy |

**Response 201:**
```json
{ "data": { "newTemplate": { /* copied template */ }, "newProgram": { /* created program */ } } }
```

---

### POST /api/trainer/programs/templates/[templateId]/rest

Adds a rest step to a template.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `templateId` | string | Template ID |

**Request Body:**
```json
{
  "durationSeconds": 90  // number, positive integer, required
}
```

**Response 201:**
```json
{ "data": { "restStep": { /* created TemplateRestStep */ } } }
```

---

## TRAINER: RECIPES

### GET /api/trainer/recipes

Lists all recipes for the trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

**Response 200:**
```json
{ "data": { "recipes": [ /* Recipe[] */ ] } }
```

---

### POST /api/trainer/recipes

Creates a new recipe.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "name": "Protein Pancakes",          // string, min 1, required
  "description": "Fluffy and tasty",   // string, optional
  "instructions": "Mix and cook...",   // string, optional
  "proteinG": 30,                      // number, optional
  "carbsG": 40,                        // number, optional
  "fatG": 10,                          // number, optional
  "calories": 350,                     // number, optional
  "difficulty": "easy",                // string, optional
  "prepTime": 10,                      // number (min), optional
  "cookTime": 15,                      // number (min), optional
  "isPublished": true,                 // boolean, optional
  "tags": [{ "name": "breakfast" }],   // array, optional
  "products": [{                       // array, optional
    "name": "Whey Protein",
    "brand": "Brand X",
    "amount": "1 scoop",
    "isRecommended": true
  }]
}
```

**Response 201:**
```json
{ "data": { "recipe": { /* created Recipe */ } } }
```

---

### GET /api/trainer/recipes/[id]

Gets a single recipe.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Recipe ID |

**Response 200:**
```json
{ "data": { "recipe": { /* Recipe with tags and products */ } } }
```

---

### PUT /api/trainer/recipes/[id]

Updates a recipe.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Recipe ID |

**Request Body:** Same shape as create, all fields optional.

**Response 200:**
```json
{ "data": { "recipe": { /* updated Recipe */ } } }
```

---

### DELETE /api/trainer/recipes/[id]

Deletes a recipe.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Recipe ID |

**Response 200:**
```json
{ "data": { "message": "Recipe deleted." } }
```

---

## TRAINER: ASSESSMENTS

### GET /api/trainer/assessments

Lists all assessments (system + custom) for the trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

**Response 200:**
```json
{
  "data": {
    "assessments": [
      { "id": "uuid", "name": "Sit & Reach", "description": "...", "unit": "cm", "trainerId": null },
      { "id": "uuid", "name": "My Custom Test", "description": "...", "unit": "kg", "trainerId": "uuid" }
    ]
  }
}
```

---

### POST /api/trainer/assessments

Creates a custom assessment.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "name": "My Custom Test",   // string, min 2 chars, required
  "description": "How to...", // string, optional
  "unit": "cm"                // string, min 1 char, required (e.g. kg, cm, %)
}
```

**Response 201:**
```json
{ "data": { "assessment": { /* created Assessment */ } } }
```

**Status Codes:** 201, 409 (name already exists)

---

## TRAINER: EVENTS

### GET /api/trainer/events

Lists all events created by the trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

**Response 200:**
```json
{ "data": { "events": [ /* Event[] */ ] } }
```

---

### POST /api/trainer/events

Creates a new event.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "title": "Yoga Workshop",                      // string, min 1, required
  "startTime": "2024-02-01T10:00:00.000Z",       // string (ISO datetime), required
  "endTime": "2024-02-01T12:00:00.000Z",         // string (ISO datetime), required
  "price": 29.99,                                 // number, min 0, required
  "capacity": 20,                                  // number, min 1, required
  "locationName": "Central Park",                 // string, min 1, required (Stripe compliance)
  "address": "123 Main St, NY",                   // string, min 1, required (Stripe compliance)
  "city": "New York",                              // string, optional
  "description": "A relaxing yoga session",       // string, optional
  "latitude": 40.7128,                             // number, optional, nullable
  "longitude": -74.006,                            // number, optional, nullable
  "imageUrl": "https://...",                       // string, optional, nullable
  "category": "yoga"                               // string, optional
}
```

**Response 201:**
```json
{ "data": { "event": { /* created Event */ } } }
```

---

### PUT /api/trainer/events/[id]

Updates an event.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Request Body:** Same shape as create, all fields optional.

**Response 200:**
```json
{ "data": { "event": { /* updated Event */ } } }
```

---

### DELETE /api/trainer/events/[id]

Deletes an event.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Response 200:**
```json
{ "data": { "message": "Event deleted" } }
```

---

### POST /api/trainer/events/upload

Uploads an event image.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `file` | File | Image (JPEG, PNG, WebP, HEIC), max 10MB |

**Response 200:**
```json
{
  "data": {
    "imagePath": "userId/events/1234_uuid.jpg",
    "publicUrl": "https://..."
  }
}
```

---

## TRAINER: LINK REQUESTS

### POST /api/trainer/link-requests/[notificationId]/accept

Accepts a client's link request. Transfers data from self-managed to trainer-managed client record.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `notificationId` | string | Notification ID of the link request |

**Response 200:**
```json
{ "data": { "message": "Client linked successfully." } }
```

---

### POST /api/trainer/link-requests/[notificationId]/decline

Declines a client's link request.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `notificationId` | string | Notification ID of the link request |

**Response 200:**
```json
{ "data": { "message": "Request declined." } }
```

---

## TRAINER: CLIENTS (ASSIGN PROGRAM / HABITS)

### POST /api/trainer/clients/[id]/assign-program

Assigns a program to a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "programId": "uuid"  // string, required
}
```

**Response 201:**
```json
{ "data": { "assignment": { /* ClientProgramAssignment */ } } }
```

---

### GET /api/trainer/clients/[id]/habits

Lists habits for a client (trainer view).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Response 200:**
```json
{ "data": { "habits": [ /* Habit[] with logs */ ] } }
```

---

### POST /api/trainer/clients/[id]/habits

Creates a habit for a client.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Client ID |

**Request Body:**
```json
{
  "title": "Drink water",       // string, min 1, required
  "description": "8 glasses",   // string, optional, nullable
  "frequency": "DAILY"          // string: "DAILY" or "WEEKLY", optional
}
```

**Response 201:**
```json
{ "data": { "habit": { /* created Habit */ } } }
```

---

## BOOKINGS

### GET /api/bookings

Lists all bookings for a trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

**Response 200:**
```json
{ "data": [ /* Booking[] */ ] }
```

---

### POST /api/bookings

Creates a new booking request (client books a session with a trainer). Implicitly links the client to the trainer if not already linked.

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:**
```json
{
  "trainerId": "uuid",                          // string, required
  "startTime": "2024-02-01T10:00:00.000Z",      // string (ISO datetime), required
  "endTime": "2024-02-01T11:00:00.000Z",        // string (ISO datetime), required
  "clientNotes": "Looking forward to it"         // string, optional
}
```

**Response 201:**
```json
{ "data": { "booking": { /* created Booking with status PENDING */ } } }
```

**Status Codes:** 201, 403 (forbidden_role), 409 (time conflict), 422 (validation)

---

### PUT /api/bookings/[bookingId]/confirm

Confirms a booking request (trainer accepts).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `bookingId` | string | Booking ID |

**Request Body:**
```json
{
  "dataSharingApproved": true  // boolean, optional (auto-enables sharing if true)
}
```

**Response 200:**
```json
{ "data": { "booking": { /* updated Booking with status CONFIRMED */ } } }
```

**Notes:** If `dataSharingApproved` is true, enables all sharing settings and sets sharing expiry to 1 year.

---

### PUT /api/bookings/[bookingId]/decline

Declines a booking request (trainer rejects).

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `bookingId` | string | Booking ID |

**Response 200:**
```json
{ "data": { "booking": { /* updated Booking with status CANCELLED */ } } }
```

---

## PUBLIC EVENTS

### GET /api/events

Lists published events with pagination and filters.

**Auth:** None  
**Role:** Public  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page number |
| `limit` | integer | `10` | Items per page |
| `search` | string | — | Text search |
| `category` | string | — | Category filter |
| `isFree` | boolean | — | Filter free/paid events |
| `sortBy` | string | `"date_asc"` | Sort order |
| `lat` | number | — | Latitude for proximity |
| `lon` | number | — | Longitude for proximity |

**Response 200:**
```json
{
  "data": {
    "events": [ /* Event[] */ ],
    "pagination": { "page": 1, "limit": 10, "hasMore": true }
  }
}
```

---

### GET /api/events/[id]

Returns detailed event info. Optionally passes user context for checking booking status.

**Auth:** None (optional auth)  
**Role:** Public (or any authenticated)  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Response 200:**
```json
{ "data": { "event": { /* full Event with trainer info */ } } }
```

---

### POST /api/events/[id]/join

Joins a free event as a participant.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Response 200:**
```json
{ "data": { "booking": { /* created EventBooking */ } } }
```

---

## NOTIFICATIONS

### GET /api/notifications

Returns the last 50 notifications for the authenticated user, newest first.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Response 200:**
```json
{
  "data": {
    "notifications": [
      {
        "id": "uuid",
        "type": "session_reminder",
        "message": "Your workout starts in 1 hour",
        "readStatus": false,
        "createdAt": "2024-01-15T10:00:00Z",
        "metadata": {}
      }
    ]
  }
}
```

---

### PUT /api/notifications/[id]

Marks a notification as read.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Notification ID |

**Response 200:**
```json
{ "data": { "notification": { /* updated with readStatus: true */ } } }
```

---

## PROFILE

### GET /api/profile/me

Returns the full profile for the current user.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{
  "data": {
    "profile": {
      "id": "uuid",
      "userId": "uuid",
      "aboutMe": "...",
      "philosophy": "...",
      "methodology": "...",
      "branding": "...",
      "profilePhotoPath": "https://...",
      "externalLinks": [ /* ExternalLink[] */ ],
      "services": [ /* Service[] */ ],
      "packages": [ /* Package[] */ ],
      "testimonials": [ /* Testimonial[] */ ],
      "availability": [ /* Availability[] */ ],
      "customDomain": "trainer.example.com",
      "domainVerified": true
    }
  }
}
```

---

### GET /api/profile/me/text-content

Returns text content fields (aboutMe, philosophy, methodology, branding) for the profile.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Response 200:**
```json
{
  "data": {
    "textContents": {
      "aboutMe": "I'm a certified trainer...",
      "philosophy": "Consistency over perfection...",
      "methodology": "Progressive overload...",
      "branding": "Bold and energetic..."
    }
  }
}
```

---

### PUT /api/profile/me/text-content

Updates a single text content field.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Request Body:**
```json
{
  "fieldName": "aboutMe",   // string: "aboutMe", "philosophy", "methodology", or "branding"
  "content": "New content"  // string, required
}
```

**Response 200:**
```json
{ "data": { "message": "Content updated successfully." } }
```

---

### GET /api/profile/me/external-links

Lists all external links for the trainer profile.

**Auth:** Bearer token  
**Role:** `trainer`  

**Response 200:**
```json
{ "data": { "links": [ { "id": "uuid", "label": "Instagram", "linkUrl": "https://instagram.com/..." } ] } }
```

---

### POST /api/profile/me/external-links

Creates a new external link.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "label": "YouTube",                // string, min 1, required
  "linkUrl": "https://youtube.com/..."  // string, valid URL, required
}
```

**Response 201:**
```json
{ "data": { "newLink": { /* created ExternalLink */ } } }
```

---

### PUT /api/profile/me/external-links/[linkId]

Updates an external link.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `linkId` | string | External link ID |

**Request Body:**
```json
{
  "label": "New Label",
  "linkUrl": "https://newurl.com"
}
```

**Response 200:**
```json
{ "data": { "updatedLink": { /* updated */ } } }
```

---

### DELETE /api/profile/me/external-links/[linkId]

Deletes an external link.

**Auth:** Bearer token  
**Role:** `trainer`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `linkId` | string | External link ID |

**Response 200:**
```json
{ "data": { "deletedId": "uuid" } }
```

---

## EXPLORE (Public)

### GET /api/explore/featured

Returns featured/explore content: top trainers, events, etc.

**Auth:** None  
**Role:** Public  

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `cityId` | string | Optional city filter |
| `lat` | number | Optional latitude for proximity |
| `lng` / `long` | number | Optional longitude for proximity |

**Response 200:**
```json
{
  "data": {
    "featuredTrainers": [ /* Trainer[] */ ],
    "featuredEvents": [ /* Event[] */ ]
  }
}
```

---

### GET /api/explore/events

Returns paginated explore events.

**Auth:** None  
**Role:** Public  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page |
| `limit` | integer | `20` | Limit |
| `cityId` | string | — | City filter |
| `categoryId` | string | — | Category filter |
| `startDate` | string (ISO) | — | Start date filter |
| `lat` | number | — | Latitude |
| `lng` / `long` | number | — | Longitude |

**Response 200:**
```json
{ "data": { "events": [ /* Event[] */ ], "total": 100 } }
```

---

### GET /api/explore/metadata

Returns explore metadata (cities, categories) for search filters.

**Auth:** None  
**Role:** Public  
**Cache:** Revalidates every 3600 seconds (1 hour)

**Response 200:**
```json
{
  "data": {
    "cities": [ { "id": "uuid", "name": "New York", "slug": "new-york" } ],
    "categories": [ { "id": "uuid", "name": "Yoga", "slug": "yoga" } ]
  }
}
```

---

## MOBILE

### GET /api/mobile/home

Returns the mobile home dashboard data. Client gets minimal response; trainer gets quick stats + upcoming sessions.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Response 200 (trainer):**
```json
{
  "data": {
    "user": { "name": "Trainer", "avatarUrl": "https://...", "username": "trainer" },
    "upcoming": [
      { "id": "uuid", "clientName": "John Doe", "startTime": "2024-01-15T10:00:00Z", "workoutName": "Full Body" }
    ],
    "stats": {
      "pendingBookings": 2,
      "pendingCheckIns": 5,
      "activeClients": 12,
      "revenue": 1500
    }
  }
}
```

**Response 200 (client):**
```json
{
  "data": {
    "user": { "name": "Client", "avatarUrl": null, "username": null },
    "upcoming": [],
    "stats": { "pendingBookings": 0, "pendingCheckIns": 0, "activeClients": 0, "revenue": 0 }
  }
}
```

---

### GET /api/mobile/pricing

Returns pricing plans for the mobile subscription screen.

**Auth:** None  
**Role:** Public  

**Response 200:**
```json
{
  "data": {
    "plans": [
      { "id": "PRO", "name": "Pro", "price": 29, "currency": "EUR", "interval": "month", "priceId": "price_xxx" }
    ],
    "isFreeMode": false
  }
}
```

---

### POST /api/mobile/ai-coach/generate

Generates an AI program from a client's goal.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "clientId": "uuid",            // string, required
  "selectedGoal": "Build muscle", // string, required
  "metrics": {}                   // object, optional
}
```

**Response 200:**
```json
{ "data": { "success": true, "programId": "uuid" } }
```

---

### POST /api/mobile/ai-coach/refine

Refines an AI coach goal based on user input.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "user_input": "I want to focus more on my legs"  // string, required
}
```

**Response 200:**
```json
{ "data": { /* refined goal data */ } }
```

---

## AI TRAINER

### GET /api/ai-trainer/session

Gets the current AI trainer session status.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Response 200:**
```json
{
  "data": {
    "session": { /* active WorkoutSession or null */ },
    "status": {
      "currentExercise": "Bench Press",
      "setNumber": 2,
      "totalSets": 4,
      "restTimer": 45
    } | "no_session"
  }
}
```

---

### POST /api/ai-trainer/session

Sends an action to the AI trainer.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:**
```json
{
  "action": "start",          // string: "start", "next", "rest_end", "status"
  "templateId": "uuid",       // string, optional (for "start")
  "clientId": "uuid"          // string, optional
}
```

**Response 200:**
```json
{
  "data": {
    "session": { /* session object */ },
    "coachResponse": "Next exercise: Dumbbell Rows. 3 sets of 10 reps.",
    "audioBase64": "//uQx...",   // base64-encoded audio
    "nextInstruction": "rest"
  }
}
```

---

### POST /api/ai-trainer/voice

Processes voice input during an AI trainer session.

**Auth:** Bearer token  
**Role:** `client`, `trainer`  

**Request Body:** `application/json` or `multipart/form-data`
```json
// JSON:
{ "audioBase64": "base64-encoded-audio-data" }

// FormData:
// field "audio": audio file (webm, etc.)
```

**Response 200:**
```json
{
  "data": {
    "action": "log_set",
    "transcript": "10 reps at 50kg",
    "parsed": { "reps": 10, "weight": 50 },
    "updatedLog": { /* ClientExerciseLog */ },
    "newPRs": [],
    "coachResponse": "Great set! Ready for the next one?",
    "audioBase64": "//uQx...",
    "nextInstruction": "rest"
  }
}
```

---

## CHAT

### GET /api/chat

Gets conversation messages between a client and trainer/AI coach.

**Auth:** Bearer token  
**Role:** Any  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `clientId` | string | — | Client ID (required) |
| `trainerId` | string | AI Trainer ID | Trainer ID |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "conversationId": "uuid",
    "messages": [
      { "id": "uuid", "senderId": "uuid", "content": "Hello!", "createdAt": "2024-01-15T10:00:00Z" }
    ]
  }
}
```

---

### POST /api/chat

Sends a message in a conversation.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "clientId": "uuid",            // string, required
  "content": "How was my form?",  // string, required
  "senderId": "uuid",            // string, optional
  "trainerId": "uuid",           // string, optional (defaults to AI Trainer)
  "mediaUrl": "https://...",     // string, optional
  "mediaType": "image"           // string, optional
}
```

**Response 200:**
```json
{
  "success": true,
  "data": { /* created Message object */ }
}
```

---

## CHECKOUT

### POST /api/checkout/session

Creates a Stripe Checkout session for a package purchase or event ticket.

**Auth:** Bearer token  
**Role:** `client`  

**Request Body:**
```json
{
  "type": "PACKAGE_SALE",          // string: "PACKAGE_SALE" or "EVENT_TICKET", optional (default: PACKAGE_SALE)
  "packageId": "uuid",            // string, optional (for package purchases)
  "eventId": "uuid",              // string, optional (for event tickets)
  "id": "uuid",                   // string, optional (generic fallback)
  "isMobile": true                // boolean, optional
}
```

**Response 200:**
```json
{ "data": { "url": "https://checkout.stripe.com/..." } }
```

---

## WEBHOOKS

### POST /api/webhooks/stripe

Stripe webhook handler for subscription lifecycle events.

**Auth:** Valid Stripe signature (Stripe-Signature header)  
**Role:** Public (Stripe)  

**Response 200:**
```json
{ "received": true }
```

**Events handled:**
| Event | Handler |
|-------|---------|
| `checkout.session.completed` | `handleCheckoutSessionCompleted` |
| `customer.subscription.created` | `handleSubscriptionUpdated` |
| `customer.subscription.updated` | `handleSubscriptionUpdated` |
| `customer.subscription.deleted` | `handleSubscriptionDeleted` |

---

## BILLING

### GET /api/billing/subscription

Returns the user's current subscription info.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{
  "data": {
    "tier": "PRO",
    "subscriptionStatus": "active",
    "tierName": "Pro",
    "tierId": "PRO",
    "stripeCancelAtPeriodEnd": false,
    "stripeCurrentPeriodEnd": 1700000000,
    "stripeCancelAt": null,
    "trialEndsAt": "2024-02-15T00:00:00Z",
    "freeMode": false
  }
}
```

---

### POST /api/billing/subscription

Creates a new Stripe checkout session for subscription purchase/tier change, or modifies an existing subscription.

**Auth:** Bearer token  
**Role:** Any  

**Request Body (subscribe to new tier):**
```json
{
  "tierId": "PRO"   // string, required
}
```

**Response 200:**
```json
{ "data": { "url": "https://checkout.stripe.com/..." } }
```

---

### PATCH /api/billing/subscription

Updates an existing subscription (cancel, resume, change tier).

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "action": "cancel",       // string: "cancel", "resume", or "change_tier"
  "tierId": "ELITE"         // string, required for "change_tier"
}
```

**Response 200:**
```json
{ "data": { "success": true } }
```

**For change_tier with proration invoice:**
```json
{ "data": { "url": "https://..." } }
```

---

### POST /api/billing/portal

Creates a Stripe Billing Portal session for subscription management.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{ "data": { "url": "https://billing.stripe.com/..." } }
```

---

### POST /api/billing/subscribe-new

Creates a checkout session for a new subscription with a 30-day trial.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{ "data": { "url": "https://checkout.stripe.com/..." } }
```

---

## USER

### DELETE /api/user/delete

Permanently deletes the authenticated user's account and all associated data.

**Auth:** Bearer token  
**Role:** Any  

**Response 200:**
```json
{ "data": { "message": "Account deleted successfully." } }
```

---

## ADMIN

### GET /api/admin/stats

Returns platform-wide statistics.

**Auth:** Bearer token  
**Role:** `admin`  

**Response 200:**
```json
{
  "totalUsers": 1500,
  "trainers": 200,
  "clients": 1200,
  "admins": 5,
  "isFreeMode": false,
  "isCustomDomains": true
}
```

---

### GET /api/admin/events

Lists all pending events requiring moderation.

**Auth:** Bearer token  
**Role:** `admin`  

**Response 200:**
```json
{ "data": { "events": [ /* Event[] needing moderation */ ] } }
```

---

### GET /api/admin/events/[id]

Gets a single event's moderation details.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Response 200:**
```json
{ "data": { "event": { /* full Event details */ } } }
```

---

### PATCH /api/admin/events/[id]

Approves or rejects an event.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Event ID |

**Request Body:**
```json
{
  "action": "approve",            // string: "approve" or "reject", required
  "rejectionReason": "Spam"       // string, required for "reject"
}
```

**Response 200:**
```json
{ "data": { "event": { /* updated Event */ } } }
```

---

### POST /api/admin/upload

Uploads a file for blog posts or other admin purposes.

**Auth:** Bearer token  
**Role:** `admin`  

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `file` | File | Any file |

**Response 200:**
```json
{ "data": { "imagePath": "admin/blog/uuid.jpg", "publicUrl": "https://..." } }
```

---

### GET /api/admin/blog

Lists all blog posts (including unpublished).

**Auth:** Bearer token  
**Role:** `admin`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page |
| `pageSize` | integer | `10` | Items per page (1–100) |

**Response 200:**
```json
{
  "data": {
    "posts": [
      {
        "id": "uuid", "slug": "my-post", "title": "My Post",
        "excerpt": "...", "coverImage": "https://...",
        "published": true, "publishedAt": "2024-01-15T10:00:00Z",
        "createdAt": "2024-01-15T10:00:00Z",
        "author": { "id": "uuid", "name": "Admin" }
      }
    ],
    "total": 50, "page": 1, "pageSize": 10
  }
}
```

---

### POST /api/admin/blog

Creates a new blog post.

**Auth:** Bearer token  
**Role:** `admin`  

**Request Body:**
```json
{
  "title": "My Post",                 // string, min 1, required
  "slug": "my-post",                  // string, min 1, required (unique)
  "content": "# Hello World\n\nPost body...",  // string, min 1, required
  "excerpt": "A short summary",       // string, optional
  "coverImage": "https://...",        // string, optional
  "published": false                  // boolean, optional (default: false)
}
```

**Response 201:**
```json
{ "data": { "post": { /* created BlogPost */ } } }
```

**Status Codes:** 201, 409 (slug_conflict)

---

### GET /api/admin/blog/[id]

Gets a blog post by ID.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Post ID |

**Response 200:**
```json
{ "data": { "post": { /* full BlogPost */ } } }
```

---

### PUT /api/admin/blog/[id]

Updates a blog post.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Post ID |

**Request Body:** Same fields as create, all optional.

**Response 200:**
```json
{ "data": { "post": { /* updated BlogPost */ } } }
```

---

### DELETE /api/admin/blog/[id]

Deletes a blog post.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Post ID |

**Response 200:**
```json
{ "data": { "message": "Blog post deleted." } }
```

---

### GET /api/admin/tickets

Lists support tickets with pagination and filters.

**Auth:** Bearer token  
**Role:** `admin`  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page |
| `limit` | integer | `20` | Items per page |
| `status` | string | — | Filter by status |
| `category` | string | — | Filter by category |

**Response 200:**
```json
{ "data": { "tickets": [ /* SupportTicket[] */ ], "total": 100, "page": 1, "limit": 20 } }
```

---

### PATCH /api/admin/tickets/[id]

Updates a support ticket's status.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Ticket ID |

**Request Body:**
```json
{
  "status": "resolved"  // string, required
}
```

**Response 200:**
```json
{ "data": { "ticket": { /* updated SupportTicket */ } } }
```

---

### DELETE /api/admin/tickets/[id]

Deletes a support ticket.

**Auth:** Bearer token  
**Role:** `admin`  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `id` | string | Ticket ID |

**Response 200:**
```json
{ "data": { "success": true } }
```

---

## BLOG (Public)

### GET /api/blog

Lists published blog posts with pagination.

**Auth:** None  
**Role:** Public  

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page |
| `pageSize` | integer | `10` | Items per page (1–100) |

**Response 200:**
```json
{
  "data": {
    "posts": [
      {
        "id": "uuid", "slug": "my-post", "title": "My Post",
        "excerpt": "...", "coverImage": "https://...",
        "publishedAt": "2024-01-15T10:00:00Z",
        "author": { "name": "Admin" }
      }
    ],
    "total": 50, "page": 1, "pageSize": 10
  }
}
```

---

### GET /api/blog/[slug]

Returns a single published blog post by slug.

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `slug` | string | Post slug |

**Response 200:**
```json
{ "data": { "post": { /* full BlogPost with content */ } } }
```

---

## CONTACT

### POST /api/contact

Submits a contact form inquiry to a trainer.

**Auth:** None  
**Role:** Public  

**Request Body:**
```json
{
  "name": "John Doe",                   // string, min 1, required
  "email": "john@example.com",          // string, email, required
  "message": "I'd like to book a session...",  // string, min 10, required
  "trainerEmail": "trainer@example.com",  // string, email, required
  "trainerName": "Trainer Name"          // string, min 1, required
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Your message has been sent successfully!"
}
```

**Status Codes:** 200, 400 (validation errors)

---

## SYSTEM CONFIG

### GET /api/system/config

Returns public feature flags.

**Auth:** None  
**Role:** Public  

**Response 200:**
```json
{
  "customDomains": true,
  "freeMode": false
}
```

---

## CUSTOM DOMAINS

### POST /api/domain/add

Adds a custom domain for the trainer's profile page. Adds to Vercel project and saves to DB.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "domain": "trainer.example.com"  // string, valid domain pattern, required
}
```

**Response 200:**
```json
{ "data": { /* Vercel API response */ } }
```

---

### POST /api/domain/verify

Verifies a custom domain's DNS configuration.

**Auth:** Bearer token  
**Role:** `trainer`  

**Request Body:**
```json
{
  "domain": "trainer.example.com"  // string, required
}
```

**Response 200:**
```json
{ "data": { "verified": true, /* Vercel API response */ } }
```

---

## PUBLIC / TRAINERS

### GET /api/trainers/[username]

Returns the full aggregated public profile for a trainer.

**Auth:** None (optional auth for link check)  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username |

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "name": "Trainer Name",
    "email": "trainer@example.com",
    "username": "trainer",
    "profile": {
      "aboutMe": "...",
      "philosophy": "...",
      "profilePhotoPath": "https://...",
      "externalLinks": [],
      "testimonials": [],
      "packages": [],
      "services": [],
      "availability": [],
      "isLinked": false
    }
  }
}
```

---

### GET /api/trainers/[username]/public

Lightweight public trainer data for trainer landing pages. Includes `isLinked` for authenticated clients.

**Auth:** None (optional auth)  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username or ID |

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "name": "Trainer Name",
    "profile": { "isLinked": false, /* ... */ }
  }
}
```

---

### GET /api/trainers/[username]/testimonials

Returns public testimonials for a trainer.

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username |

**Response 200:**
```json
{ "data": { "testimonials": [ /* Testimonial[] */ ] } }
```

---

### GET /api/trainers/[username]/schedule

Returns a trainer's public availability schedule.

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username |

**Response 200:**
```json
{ "data": { /* schedule data */ } }
```

---

### GET /api/trainers/[username]/packages

Returns a trainer's public packages.

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username |

**Response 200:**
```json
{ "data": { "packages": [ /* Package[] */ ] } }
```

---

### GET /api/trainers/[username]/transformation-photos

Returns a trainer's public transformation photos.

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `username` | string | Trainer username |

**Response 200:**
```json
{ "data": { "photos": [ /* TransformationPhoto[] */ ] } }
```

---

### GET /api/trainers

Lists trainers (search/discovery).

**Auth:** None  
**Role:** Public  

**Query Parameters:** (not analyzed in detail — custom implementation)

---

### GET /api/trainers/specialties

Returns available trainer specialties for filtering.

**Auth:** None  
**Role:** Public  

---

### GET /api/public/workout-summary/[sessionId]

Returns a publicly shared workout summary (for social sharing).

**Auth:** None  
**Role:** Public  

**Path Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `sessionId` | string | Workout session ID |

**Response 200:**
```json
{ "data": { "session": { /* WorkoutSession summary */ } } }
```

---

### GET /api/openapi

Returns the OpenAPI specification JSON file.

**Auth:** None  
**Role:** Public  
**Cache:** 5 minutes

**Response 200:**
```json
{ /* Full OpenAPI document */ }
```

---

## DASHBOARD

### GET /api/dashboard

Returns the trainer's dashboard data (stats, recent activity, etc.).

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

**Response 200 (trainer):**
```json
{
  "data": {
    "user": { /* Supabase User */ },
    "upcomingSessions": [ /* WorkoutSession[] */ ],
    "pendingCheckIns": 5,
    "pendingBookings": 3,
    "activeClients": 12,
    "revenue": 1500,
    "recentActivity": [ /* recent events */ ]
  }
}
```

**Response 200 (client):**
```json
{
  "data": { "message": "Authenticated as client. Fetch specific dashboard endpoints for data." }
}
```

---

### GET /api/dashboard/summary

Lightweight dashboard summary endpoint.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

---

### GET /api/dashboard/insights

Dashboard insights data endpoint.

**Auth:** Bearer token  
**Role:** `trainer`, `client`  

---

## ONBOARDING

### POST /api/onboarding/complete

Completes the onboarding flow. Accepts multipart form with role, name, bio, location, and optional avatar.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `role` | string | `"client"` or `"trainer"`, required |
| `name` | string | Full name, required |
| `location` | string | Optional location |
| `bio` | string | Optional bio |
| `avatar` | File | Image (JPEG, PNG, WebP, GIF, HEIC), max 5MB, optional |

**Response 200:**
```json
{
  "data": {
    "user": { /* updated User with profile */ }
  }
}
```

---

## SUPPORT / FEEDBACK

### POST /api/support/feedback

Submits a support ticket / feedback.

**Auth:** Bearer token  
**Role:** Any  

**Request Body:**
```json
{
  "category": "bug",           // string, required
  "subject": "App crashes",    // string, required
  "message": "When I tap...",  // string, required
  "attachments": []            // array, optional
}
```

**Response 201:**
```json
{ "data": { "success": true, "message": "Feedback received" } }
```

---

## CRON

### GET /api/cron/check-in-reminder

Cron-triggered endpoint that sends check-in reminders to active clients.

**Auth:** Requires `Authorization: Bearer <CRON_SECRET>` header  
**Role:** Cron  

**Response 200:**
```json
{ "success": true, "count": 25 }
```

---

### GET /api/cron/trial-reminders

Cron-triggered endpoint that sends trial expiration reminder emails (5, 3, and 1 day before expiry).

**Auth:** Requires `Authorization: Bearer <CRON_SECRET>` header  
**Role:** Cron  

**Response 200:**
```json
{
  "success": true,
  "processed": [
    { "userId": "uuid", "stage": "day25", "status": "sent" }
  ]
}
```

---

## TRAINER: ADDITIONAL ENDPOINTS

### POST /api/trainer/clients/[id]/habits/[habitId]

Update or manage a specific habit for a client.

---

### GET /api/trainer/workout-templates

Lists workout templates available to the trainer.

**Auth:** Bearer token  
**Role:** `trainer`  

---

### GET /api/trainer/session-creation-data

Returns data needed for the session creation UI (clients, templates, etc.).

**Auth:** Bearer token  
**Role:** `trainer`  

---

### GET /api/trainer/settings

Returns trainer-specific settings.

**Auth:** Bearer token  
**Role:** `trainer`  

---

### GET/POST/PUT/DELETE /api/trainer/resource-vault

CRUD for trainer's resource vault. Includes assign/unassign sub-routes for client assignments.

---

## PROFILE SUB-ROUTES

These are sub-resources under `/api/profile/me/*` for managing specific profile sections:

| Method | Endpoint | Description | Role |
|--------|----------|-------------|------|
| GET/PUT | `/api/profile/me/text-content` | Get/update text fields | trainer, client |
| GET/POST | `/api/profile/me/external-links` | List/create external links | trainer |
| PUT/DELETE | `/api/profile/me/external-links/[linkId]` | Update/delete a link | trainer |
| POST/DELETE | `/api/profile/me/avatar` | Upload/remove avatar | any |
| GET | `/api/profile/me/assessments` | List assessments | trainer |
| GET | `/api/profile/me/availability` | Get availability | trainer |
| CRUD | `/api/profile/me/benefits` | Manage benefits | trainer |
| PUT | `/api/profile/me/benefits/order` | Reorder benefits | trainer |
| GET | `/api/profile/me/billing` | Get billing info | trainer |
| GET/PUT | `/api/profile/me/branding` | Get/update branding | trainer |
| GET/PUT | `/api/profile/me/core-info` | Get/update core info | trainer |
| CRUD | `/api/profile/me/exercises` | Manage custom exercises | trainer |
| GET/POST | `/api/profile/me/packages` | List/create packages | trainer |
| PUT/DELETE | `/api/profile/me/packages/[packageId]` | Update/delete a package | trainer |
| POST | `/api/profile/me/push-token` | Register push notification token | any |
| CRUD | `/api/profile/me/services` | Manage services | trainer |
| CRUD | `/api/profile/me/social-links` | Manage social links | trainer |
| CRUD | `/api/profile/me/testimonials` | Manage testimonials | trainer |
| CRUD | `/api/profile/me/transformation-photos` | Manage transformation photos | trainer |

---

## CLIENT SUB-ROUTES

Additional client-facing endpoints:

| Method | Endpoint | Description | Role |
|--------|----------|-------------|------|
| GET | `/api/client/check-ins` | List check-ins | client |
| GET/DELETE | `/api/client/check-ins/[id]` | Get/delete check-in | client |
| GET | `/api/client/check-in/config` | Get check-in configuration | client |
| GET | `/api/client/statistics` | Get statistics | client |
| GET | `/api/client/stats/exercise` | Get per-exercise stats | client |

---

## BILLING PLAN SUMMARY

| Tier ID | Name | Price (EUR/mo) |
|---------|------|-----------------|
| `PRO` | Pro | 29 |
| `ELITE` | Elite | Higher tier |
| `FREE` | Free | 0 (limited features) |

---

*End of API Reference. This document covers 120+ endpoints organized by domain.*

*Last updated: 2026-05-01*
