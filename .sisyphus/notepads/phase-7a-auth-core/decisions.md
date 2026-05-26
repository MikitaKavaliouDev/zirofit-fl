# Phase 7-A Auth Core - Decisions

## Decision 1: Mode Callback Instead of Notification
**Option considered**: Using `NotificationCenter`-style event bus vs. callback parameter
**Chosen**: Callback parameter (`onUnauthorized(String mode)`)
**Rationale**: Simpler, no need for additional event bus/stream. The `AuthInterceptor` already had `onLogout` callback - just extended it to pass mode. Matches iOS pattern of `Notification.Name("apiUnauthorized")` being observed by the auth view model, but in Flutter's Riverpod architecture, a lambda callback is more direct.

## Decision 2: Role Detection Mapping
**Trainer roles**: trainer, coach, instructor, admin, staff, owner → 'trainer'
**Others**: → 'client' (not 'personal' as the spec mentions `.personal`)
**Rationale**: Internal auth roles use 'client', while `AppMode.personal` is a display-only preference. Using 'client' maintains consistency with the existing codebase (role switching, route guards, etc.). The AppMode enum stays as-is for UI presentation.

## Decision 3: JWT Pre-check Location
**Option considered**: In `AuthNotifier` vs. `AuthInterceptor`
**Chosen**: In `AuthInterceptor.onRequest()`
**Rationale**: Every authenticated API call goes through the interceptor. Placing the pre-check there ensures it runs for ALL API calls, not just those initiated by the auth provider. The decode logic is exposed as a public static method for reuse.

## Decision 4: Google OAuth Flow
**Chosen**: Use existing `mobile-signin` browser URL + deep link callback
**Rationale**: The server-side OAuth flow (open URL → Google consent → server exchanges tokens → redirect to `zirofitapp://auth-callback`) was already partially implemented. Just needed the bootstrap deep-link handler to properly save tokens and navigate to `AuthCallbackScreen` instead of just going to `/auth/login`.

## Decision 5: UpdatePasswordScreen vs ResetPasswordScreen
**Two screens coexist**:
- `UpdatePasswordScreen` (no current password) → for deep link flow, route `/auth/update-password`
- `ResetPasswordScreen` (token via URL param) → for email reset flow, route `/auth/reset-password?token=xxx`
**Rationale**: The bootstrap already routes email reset deep links to reset-password correctly. UpdatePasswordScreen serves as the "no current password" version for manual navigation or future use.
