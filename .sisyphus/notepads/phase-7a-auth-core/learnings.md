# Phase 7-A Auth Core - Implementation Learnings

## Architecture Overview
- Auth uses Riverpod `StateNotifier` pattern with `AuthNotifier` + `AuthState`
- Dio interceptors handle auth: `AuthInterceptor` (tokens/401), `RetryInterceptor` (network retry)
- Dual-mode auth: trainer mode (cookie-based) and client mode (Bearer token)
- Deep links via `app_links` package with `DeepLinkService` parsing `zirofitapp://` URLs

## Key Changes Made

### 1. AuthInterceptor (`auth_interceptor.dart`)
- **Renamed `onLogout` → `onUnauthorized(String mode)`**: Now passes the failing mode ('trainer' or 'client') so the auth provider can surgically clear only that mode's tokens
- **Added JWT pre-check**: `isAccessTokenExpired()` decodes JWT payload (base64) and checks `exp` claim with 60s buffer in `onRequest` before dispatching
- **Added `decodeJwtPayload()` static method**: Publicly accessible for reuse by AuthNotifier
- **Auto-refresh**: When token is expired, `_tryPreemptiveRefresh()` runs before the request, also saves tokens under role key

### 2. ApiClient (`api_client.dart`)
- **`configure()` parameter change**: `onLogout` → `onUnauthorized(void Function(String mode)?)`

### 3. AuthNotifier (`auth_provider.dart`)
- **Role detection**: `detectRole(String)` maps trainer/coach/instructor/admin/staff/owner → 'trainer', everything else → 'client'
- **Applied in login, refreshSession, Apple Sign-In**: All role resolution paths go through `detectRole()`
- **Token migration**: `_migrateRoleTokensIfNeeded()` saves tokens under newly detected role if different from current
- **Mode-specific logout**: `logout({required String mode})` surgically clears only target mode's tokens/cookies/cache, resets state only if active mode
- **Session expired handler**: `handleUnauthorized(String)` clears failing mode's tokens and shows "Session expired. Please login again." if active mode
- **JWT decode**: Exposes `decodeJwtPayload()` delegating to `AuthInterceptor.decodeJwtPayload()`
- **Removed unused `dart:convert` import** (JWT decode lives in interceptor)

### 4. SecureStorage (`secure_storage.dart`)
- **Added `clearRoleTokens(String role)`**: Deletes only one role's access+refresh tokens

### 5. DeepLinkService (`deep_link_service.dart`)
- **Added `refreshToken` param extraction**: Auth callback now captures both `access_token` and `refresh_token`
- **Added `refreshToken` getter** to `DeepLinkRoute`

### 6. Bootstrap (`bootstrap.dart`)
- **Updated `onLogout` → `onUnauthorized` callback**: Now calls `authNotifier.handleUnauthorized(mode)` instead of `signOut()`
- **Updated `authCallback` handler**: Saves tokens to secure storage AND navigates to `/auth/callback` screen (previously just went to `/auth/login`)

### 7. Login Screen (`login_screen.dart`)
- **Button text**: "Sign in with Google" → "Continue with Google"

### 8. Forgot Password Screen (`forgot_password_screen.dart`)
- **Privacy-preserving message**: "Reset link sent!" → "Password reset email sent if the account exists."

### 9. Update Password Screen (`update_password_screen.dart`)
- **Removed current password field**: Now only requires new password + confirm (for deep link reset flow)
- **Removed unused `existingToken` variable**

### 10. Test file (`auth_interceptor_test.dart`)
- **Updated all `onLogout` → `onUnauthorized` references** (7 occurrences)
- **Callback type**: `void Function()` → `void Function(String)`

## Conventions Followed
- Kept existing Riverpod/StateNotifier pattern
- No new packages added
- Apple Sign-In functionality preserved untouched
- Multi-account auth state preserved
- All LSP diagnostics clean across changed files
- flutter analyze: 0 errors (219 pre-existing warnings/info remain)
