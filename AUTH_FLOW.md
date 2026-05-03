# Ziro Fit Flutter - Authentication & Authorization Flow

## Table of Contents

1. [Auth Strategy Overview](#1-auth-strategy-overview)
2. [Email/Password Login Flow](#2-emailpassword-login-flow)
3. [Registration Flow](#3-registration-flow)
4. [OAuth Flow (Google/Apple)](#4-oauth-flow-googleapple)
5. [Token Refresh Flow](#5-token-refresh-flow)
6. [Auto-Login (App Startup)](#6-auto-login-app-startup)
7. [Sign Out Flow](#7-sign-out-flow)
8. [Auth State Management (Riverpod)](#8-auth-state-management-riverpod)
9. [Auth Interceptor (Dio)](#9-auth-interceptor-dio)
10. [Role-Based Routing](#10-role-based-routing)
11. [Deep Link Handling](#11-deep-link-handling)
12. [Security Considerations](#12-security-considerations)
13. [Auth API Client Methods](#13-auth-api-client-methods)
14. [Auth Provider Interface (Riverpod)](#14-auth-provider-interface-riverpod)
15. [Error Handling](#15-error-handling)
16. [Testing Auth (TDD)](#16-testing-auth-tdd)
17. [Implementation Checklist](#17-implementation-checklist)

---

## 1. Auth Strategy Overview

### Architecture Decision

The Ziro Fit Flutter app uses **Supabase Auth** through the zirofit-next backend API. While the `supabase_flutter` SDK is available, all authentication flows route through custom API endpoints to maintain consistency with the web application.

### Key Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Auth SDK | `supabase_flutter` | Session management, OAuth handling |
| HTTP Client | `dio` | API requests with interceptors |
| Secure Storage | `flutter_secure_storage` | Token persistence (Keychain/Keystore) |
| State Management | `riverpod` | Auth state, user profile |
| Routing | `go_router` | Role-based navigation, deep links |
| Local Auth | `local_auth` | Optional biometric lock |

### Auth Strategies

1. **Email/Password** - Traditional login with credentials
2. **OAuth (Google/Apple)** - Social login via deep link callback
3. **Registration** - Account creation with email verification

### Token Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Token Lifecycle                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Access Token (JWT)                                         │
│  ├── Lifetime: 1 hour                                       │
│  ├── Storage: flutter_secure_storage                        │
│  ├── Usage: Authorization: Bearer <token>                   │
│  └── Refresh: Automatic via interceptor                     │
│                                                             │
│  Refresh Token                                              │
│  ├── Lifetime: 30 days                                      │
│  ├── Storage: flutter_secure_storage                        │
│  ├── Usage: POST /api/auth/refresh                          │
│  └── Rotation: New refresh token on each refresh            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### API Response Format

All API responses follow a consistent format:

```json
// Success
{
  "data": { ... }
}

// Error
{
  "error": {
    "message": "Invalid credentials",
    "code": "AUTH_INVALID_CREDENTIALS",
    "details": { ... }
  }
}
```

---

## 2. Email/Password Login Flow

### Sequence Diagram

```
┌──────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   User   │     │ Login Screen │     │ AuthProvider │     │    Backend   │
└────┬─────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
     │                  │                    │                    │
     │  Enter email     │                    │                    │
     │  & password      │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  login(email,      │                    │
     │                  │       password)    │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │                    │  POST /api/auth/login
     │                  │                    │  {email, password} │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  {accessToken,     │
     │                  │                    │   refreshToken,    │
     │                  │                    │   user, role}      │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │                    │  Store tokens      │
     │                  │                    │  in secure storage │
     │                  │                    │                    │
     │                  │                    │  setSession()      │
     │                  │                    │  on Supabase       │
     │                  │                    │                    │
     │                  │                    │  GET /api/auth/me  │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  ExtendedProfile   │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │  Navigate based    │                    │
     │                  │  on role           │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │  Dashboard       │                    │                    │
     │<─────────────────│                    │                    │
```

### Implementation Details

#### Login Request

```dart
// POST /api/auth/login
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

#### Login Response

```dart
// Success Response
{
  "data": {
    "message": "Login successful.",
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid-1234",
      "email": "user@example.com",
      "email_confirmed_at": "2024-01-15T10:30:00Z"
    },
    "role": "client"
  }
}
```

#### Token Storage

```dart
// After successful login
await secureStorage.write(key: 'access_token', value: accessToken);
await secureStorage.write(key: 'refresh_token', value: refreshToken);
```

#### Session Initialization

```dart
// Initialize Supabase session with tokens
await supabase.auth.setSession(Session(
  accessToken: accessToken,
  refreshToken: refreshToken,
));
```

#### Role-Based Navigation

| Role | Destination |
|------|-------------|
| `pending` | `/onboarding` |
| `client` | `/client/dashboard` |
| `trainer` | `/trainer/dashboard` |
| `admin` | `/admin/dashboard` |

---

## 3. Registration Flow

### Sequence Diagram

```
┌──────────┐     ┌────────────────┐     ┌──────────────┐     ┌─────────────┐
│   User   │     │ Register Screen│     │ AuthProvider │     │   Backend   │
└────┬─────┘     └───────┬────────┘     └──────┬───────┘     └──────┬──────┘
     │                   │                     │                    │
     │  Fill form        │                     │                    │
     │  (name, email,    │                     │                    │
     │   password, role) │                     │                    │
     │──────────────────>│                     │                    │
     │                   │                     │                    │
     │                   │  register(...)      │                    │
     │                   │────────────────────>│                    │
     │                   │                     │                    │
     │                   │                     │  POST /api/auth/register
     │                   │                     │  {name, email,     │
     │                   │                     │   password, role}  │
     │                   │                     │───────────────────>│
     │                   │                     │                    │
     │                   │                     │  {userId,          │
     │                   │                     │   requiresSub,     │
     │                   │                     │   confirmRequired} │
     │                   │                     │<───────────────────│
     │                   │                     │                    │
     │                   │  Show success msg   │                    │
     │                   │────────────────────>│                    │
     │                   │                     │                    │
     │  "Please verify   │                     │                    │
     │   your email"     │                     │                    │
     │<──────────────────│                     │                    │
     │                   │                     │                    │
     │  Navigate to      │                     │                    │
     │  Login Screen     │                     │                    │
     │<──────────────────│                     │                    │
```

### Registration Request

```dart
// POST /api/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123",
  "role": "client",           // Optional: 'client' or 'trainer'
  "trainerId": "trainer-uuid" // Optional: for client registration
}
```

### Registration Response

```dart
// Success Response
{
  "data": {
    "userId": "uuid-5678",
    "requiresSubscription": false,
    "confirmationRequired": true
  }
}
```

### Post-Registration Flow

1. User receives success message: "Please verify your email"
2. Navigation redirects to Login Screen
3. User must click verification link in email
4. After verification, user can log in
5. First login triggers onboarding flow

### Registration Validation

| Field | Requirements |
|-------|--------------|
| name | 2-100 characters |
| email | Valid email format, unique |
| password | Min 8 chars, 1 uppercase, 1 lowercase, 1 number |
| role | 'client' or 'trainer' (default: 'client') |
| trainerId | Required if role is 'client' and registering via trainer invite |

---

## 4. OAuth Flow (Google/Apple)

### Sequence Diagram

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│   User   │     │ Login Screen │     │ AuthProvider │     │   Backend   │
└────┬─────┘     └──────┬───────┘     └──────┬───────┘     └──────┬──────┘
     │                  │                    │                    │
     │  Tap Google/     │                    │                    │
     │  Apple button    │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  signInWithOAuth   │                    │
     │                  │  ('google')        │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │                    │  GET /api/auth/mobile-signin
     │                  │                    │  ?provider=google  │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  OAuth URL         │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │  Open browser      │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │  System browser opens                │                    │
     │<─────────────────│                    │                    │
     │                  │                    │                    │
     │  User authenticates with Google/Apple                    │
     │──────────────────────────────────────────────────────────>│
     │                  │                    │                    │
     │  OAuth callback  │                    │                    │
     │  Deep link       │                    │                    │
     │<──────────────────────────────────────────────────────────│
     │                  │                    │                    │
     │  zirofitapp://auth-callback?access_token=...&refresh_token=...
     │                  │                    │                    │
     │  GoRouter catches deep link                               │
     │                  │                    │                    │
     │                  │  AuthCallbackScreen                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │                    │  Extract tokens    │
     │                  │                    │  from URL          │
     │                  │                    │                    │
     │                  │                    │  Store tokens      │
     │                  │                    │  in secure storage │
     │                  │                    │                    │
     │                  │                    │  setSession()      │
     │                  │                    │  on Supabase       │
     │                  │                    │                    │
     │                  │                    │  POST /api/auth/sync-user
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  GET /api/auth/me  │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  ExtendedProfile   │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │  Navigate based    │                    │
     │                  │  on role           │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │  Dashboard       │                    │                    │
     │<─────────────────│                    │                    │
```

### OAuth URL Construction

```dart
// GET /api/auth/mobile-signin?provider=google
// Returns: { url: "https://accounts.google.com/o/oauth2/v2/auth?..." }

final oauthUrl = Uri.parse('${baseUrl}/api/auth/mobile-signin')
    .replace(queryParameters: {'provider': provider});
```

### Deep Link Format

```
zirofitapp://auth-callback?access_token=eyJ...&refresh_token=eyJ...&user_id=uuid&role=client
```

### Deep Link Parsing

```dart
// In AuthCallbackScreen
final uri = Uri.parse(deepLinkUrl);
final accessToken = uri.queryParameters['access_token'];
final refreshToken = uri.queryParameters['refresh_token'];
final userId = uri.queryParameters['user_id'];
final role = uri.queryParameters['role'];
```

### User Sync

After OAuth login, sync user to ensure Prisma record exists:

```dart
// POST /api/auth/sync-user
// Body: { id, email, name, provider }
await apiClient.post('/api/auth/sync-user', data: {
  'id': userId,
  'email': email,
  'name': name,
  'provider': provider,
});
```

### Platform Configuration

#### Android (AndroidManifest.xml)

```xml
<activity>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="zirofitapp"
            android:host="auth-callback" />
    </intent-filter>
</activity>
```

#### iOS (Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>zirofitapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>auth-callback</string>
    </dict>
</array>
```

---

## 5. Token Refresh Flow

### Sequence Diagram

```
┌──────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   User   │     │   Dio Client │     │AuthInterceptor│    │   Backend    │
└────┬─────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
     │                  │                    │                    │
     │  API Request     │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  Attach Bearer     │                    │
     │                  │  token to header   │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │                    │  Request with      │
     │                  │                    │  expired token     │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  401 Unauthorized  │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │  onError(401)      │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │                  │                    │  Check if refresh  │
     │                  │                    │  already in progress
     │                  │                    │                    │
     │                  │                    │  Read refresh_token│
     │                  │                    │  from secure storage
     │                  │                    │                    │
     │                  │                    │  POST /api/auth/refresh
     │                  │                    │  {refreshToken}    │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  {accessToken,     │
     │                  │                    │   refreshToken,    │
     │                  │                    │   expiresAt}       │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │                    │  Update stored     │
     │                  │                    │  tokens            │
     │                  │                    │                    │
     │                  │                    │  Update Dio        │
     │                  │                    │  default headers   │
     │                  │                    │                    │
     │                  │                    │  Retry original    │
     │                  │                    │  request           │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  Success response  │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │  Response          │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │  Response        │                    │                    │
     │<─────────────────│                    │                    │
```

### Refresh Request

```dart
// POST /api/auth/refresh
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Refresh Response

```dart
// Success Response
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresAt": 1700000000,
    "user": {
      "id": "uuid-1234",
      "email": "user@example.com"
    }
  }
}
```

### Refresh Failure Handling

If refresh fails (401 on refresh endpoint):

1. Clear all stored tokens
2. Clear Supabase session
3. Clear Riverpod cache
4. Clear Drift database
5. Navigate to Login Screen
6. Show message: "Session expired. Please log in again."

### Preventing Infinite Loops

```dart
class AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;
  final _queuedRequests = <Completer<String>>[];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      
      try {
        final newToken = await _refreshToken();
        // Retry all queued requests
        for (final completer in _queuedRequests) {
          completer.complete(newToken);
        }
        _queuedRequests.clear();
        
        // Retry original request
        final retryResponse = await _retryRequest(err.requestOptions, newToken);
        handler.resolve(retryResponse);
      } catch (e) {
        // Refresh failed - logout
        await _handleRefreshFailure();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else if (err.response?.statusCode == 401 && _isRefreshing) {
      // Queue this request
      final completer = Completer<String>();
      _queuedRequests.add(completer);
      final newToken = await completer.future;
      final retryResponse = await _retryRequest(err.requestOptions, newToken);
      handler.resolve(retryResponse);
    } else {
      handler.next(err);
    }
  }
}
```

---

## 6. Auto-Login (App Startup)

### Sequence Diagram

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│   App    │     │  Bootstrap   │     │ AuthProvider │     │   Backend   │
└────┬─────┘     └──────┬───────┘     └──────┬───────┘     └──────┬──────┘
     │                  │                    │                    │
     │  App starts      │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  Check secure      │                    │
     │                  │  storage for       │                    │
     │                  │  refresh_token     │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │  Token found?      │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │                  │  YES               │                    │
     │                  │                    │                    │
     │                  │                    │  POST /api/auth/refresh
     │                  │                    │  {refreshToken}    │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  {accessToken,     │
     │                  │                    │   refreshToken,    │
     │                  │                    │   expiresAt}       │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │                    │  Store new tokens  │
     │                  │                    │                    │
     │                  │                    │  setSession()      │
     │                  │                    │  on Supabase       │
     │                  │                    │                    │
     │                  │                    │  GET /api/auth/me  │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  ExtendedProfile   │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │                    │  Navigate to       │
     │                  │                    │  correct dashboard │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │  NO                │                    │
     │                  │                    │                    │
     │                  │  Navigate to       │                    │
     │                  │  Login Screen      │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │  Login Screen    │                    │                    │
     │<─────────────────│                    │                    │
```

### Bootstrap Implementation

```dart
class Bootstrap {
  static Future<void> initialize() async {
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // Check for stored refresh token
    final secureStorage = FlutterSecureStorage();
    final refreshToken = await secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        // Attempt to refresh
        final authApiClient = AuthApiClient();
        final response = await authApiClient.refreshToken(refreshToken);
        
        // Store new tokens
        await secureStorage.write(
          key: 'access_token',
          value: response.accessToken,
        );
        await secureStorage.write(
          key: 'refresh_token',
          value: response.refreshToken,
        );

        // Initialize Supabase session
        await Supabase.instance.client.auth.setSession(Session(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ));

        // Fetch user profile
        final profile = await authApiClient.getMe();
        
        // Navigate based on role
        _navigateToDashboard(profile.role);
      } catch (e) {
        // Refresh failed - clear tokens and go to login
        await _clearAuthData();
        _navigateToLogin();
      }
    } else {
      // No stored token - go to login
      _navigateToLogin();
    }
  }

  static Future<void> _clearAuthData() async {
    final secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'access_token');
    await secureStorage.delete(key: 'refresh_token');
    await Supabase.instance.client.auth.signOut();
  }
}
```

### Navigation Logic

```dart
void _navigateToDashboard(String role) {
  final router = ref.read(routerProvider);
  
  switch (role) {
    case 'pending':
      router.go('/onboarding');
      break;
    case 'client':
      router.go('/client/dashboard');
      break;
    case 'trainer':
      router.go('/trainer/dashboard');
      break;
    case 'admin':
      router.go('/admin/dashboard');
      break;
    default:
      router.go('/auth/login');
  }
}
```

---

## 7. Sign Out Flow

### Sequence Diagram

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│   User   │     │ Profile/Menu │     │ AuthProvider │     │   Backend   │
└────┬─────┘     └──────┬───────┘     └──────┬───────┘     └──────┬──────┘
     │                  │                    │                    │
     │  Tap Sign Out    │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  Confirm?          │                    │
     │                  │<───────────────────│                    │
     │                  │                    │                    │
     │  Yes             │                    │                    │
     │─────────────────>│                    │                    │
     │                  │                    │                    │
     │                  │  signOut()         │                    │
     │                  │───────────────────>│                    │
     │                  │                    │                    │
     │                  │                    │  POST /api/auth/signout
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │                  │                    │  200 OK            │
     │                  │                    │<───────────────────│
     │                  │                    │                    │
     │                  │                    │  Clear secure      │
     │                  │                    │  storage           │
     │                  │                    │  - access_token    │
     │                  │                    │  - refresh_token   │
     │                  │                    │                    │
     │                  │                    │  Clear Supabase    │
     │                  │                    │  session           │
     │                  │                    │  supabase.auth.    │
     │                  │                    │  signOut()         │
     │                  │                    │                    │
     │                  │                    │  Clear Riverpod    │
     │                  │                    │  cache             │
     │                  │                    │  ref.invalidate    │
     │                  │                    │  (allProviders)    │
     │                  │                    │                    │
     │                  │                    │  Clear Drift       │
     │                  │                    │  database          │
     │                  │                    │  await db.deleteAll│
     │                  │                    │                    │
     │                  │                    │  Navigate to       │
     │                  │                    │  Login Screen      │
     │                  │                    │───────────────────>│
     │                  │                    │                    │
     │  Login Screen    │                    │                    │
     │<─────────────────│                    │                    │
```

### Sign Out Implementation

```dart
class AuthProvider {
  Future<void> signOut() async {
    try {
      // 1. Call backend signout
      await _apiClient.post('/api/auth/signout');
    } catch (e) {
      // Continue with local cleanup even if backend fails
    }

    // 2. Clear secure storage
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');

    // 3. Clear Supabase session
    await Supabase.instance.client.auth.signOut();

    // 4. Clear all Riverpod providers
    _ref.invalidate(allProviders);

    // 5. Clear Drift database
    await _database.clearAllData();

    // 6. Navigate to login
    _ref.read(routerProvider).go('/auth/login');
  }
}
```

### Data to Clear on Sign Out

| Data Type | Location | Clear Method |
|-----------|----------|--------------|
| Access Token | flutter_secure_storage | `delete(key: 'access_token')` |
| Refresh Token | flutter_secure_storage | `delete(key: 'refresh_token')` |
| Supabase Session | Supabase SDK | `auth.signOut()` |
| Riverpod Cache | Riverpod | `ref.invalidate(allProviders)` |
| Local Database | Drift | `db.clearAllData()` |
| Cached Images | flutter_cache_manager | `CacheManager().emptyCache()` |
| Shared Preferences | SharedPreferences | Selective clearing |

---

## 8. Auth State Management (Riverpod)

### Auth State Model

```dart
enum AuthStatus { 
  initial,      // App starting, checking auth state
  loading,      // Auth operation in progress
  authenticated, // User is logged in
  unauthenticated, // User is logged out
  error        // Auth error occurred
}

class AuthState {
  final AuthStatus status;
  final User? user;              // Supabase User
  final ExtendedProfile? profile; // From /api/auth/me
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.error,
  });

  // Convenience getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => error != null;

  // Role checks
  bool get isTrainer => profile?.role == 'trainer';
  bool get isClient => profile?.role == 'client';
  bool get isAdmin => profile?.role == 'admin';
  bool get isPending => profile?.role == 'pending';

  // Onboarding check
  bool get hasCompletedOnboarding => profile?.hasCompletedOnboarding ?? false;

  // Subscription checks
  bool get hasActiveSubscription => profile?.subscriptionStatus == 'active';
  bool get isFreeAccessMode => profile?.isFreeAccessModeEnabled ?? false;
  bool get requiresSubscription => 
      isTrainer && !hasActiveSubscription && !isFreeAccessMode;

  // Copy with
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    ExtendedProfile? profile,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}
```

### Extended Profile Model

```dart
class ExtendedProfile {
  final String id;
  final String email;
  final String name;
  final String role; // 'pending', 'client', 'trainer', 'admin'
  final String? username;
  final String? tier;
  final bool hasCompletedOnboarding;
  final String? subscriptionStatus; // 'active', 'inactive', 'cancelled'
  final String? profilePhotoPath;
  final bool isFreeAccessModeEnabled;

  ExtendedProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.username,
    this.tier,
    this.hasCompletedOnboarding = false,
    this.subscriptionStatus,
    this.profilePhotoPath,
    this.isFreeAccessModeEnabled = false,
  });

  factory ExtendedProfile.fromJson(Map<String, dynamic> json) {
    return ExtendedProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      username: json['username'],
      tier: json['tier'],
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      subscriptionStatus: json['subscriptionStatus'],
      profilePhotoPath: json['profilePhotoPath'],
      isFreeAccessModeEnabled: json['isFreeAccessModeEnabled'] ?? false,
    );
  }
}
```

### Auth Provider Implementation

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  late final AuthApiClient _apiClient;
  late final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _apiClient = _ref.read(authApiClientProvider);
    _secureStorage = _ref.read(secureStorageProvider);
  }

  // Initialize auth state on app startup
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (refreshToken != null) {
        await _refreshSession(refreshToken);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  // Email/Password Login
  Future<Result<LoginResponse>> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _apiClient.login(email, password);
      
      // Store tokens
      await _secureStorage.write(
        key: 'access_token',
        value: response.accessToken,
      );
      await _secureStorage.write(
        key: 'refresh_token',
        value: response.refreshToken,
      );

      // Initialize Supabase session
      await Supabase.instance.client.auth.setSession(Session(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      ));

      // Fetch extended profile
      final profile = await _apiClient.getMe();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
        profile: profile,
      );

      return Result.success(response);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return Result.failure(e.toString());
    }
  }

  // Refresh session
  Future<void> _refreshSession(String refreshToken) async {
    final response = await _apiClient.refreshToken(refreshToken);
    
    await _secureStorage.write(
      key: 'access_token',
      value: response.accessToken,
    );
    await _secureStorage.write(
      key: 'refresh_token',
      value: response.refreshToken,
    );

    await Supabase.instance.client.auth.setSession(Session(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    ));

    final profile = await _apiClient.getMe();

    state = AuthState(
      status: AuthStatus.authenticated,
      user: response.user,
      profile: profile,
    );
  }
}
```

### Auth Selectors

```dart
// Selectors for efficient widget rebuilds
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider.select((state) => state.status));
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state.isAuthenticated));
});

final userProfileProvider = Provider<ExtendedProfile?>((ref) {
  return ref.watch(authProvider.select((state) => state.profile));
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((state) => state.profile?.role));
});

final isTrainerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state.isTrainer));
});

final isClientProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state.isClient));
});
```

---

## 9. Auth Interceptor (Dio)

### Interceptor Implementation

```dart
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Ref _ref;
  bool _isRefreshing = false;
  final List<Completer<String>> _queuedRequests = [];

  AuthInterceptor(this._secureStorage, this._ref);

  // Paths that don't require authentication
  static const _excludedPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/refresh',
    '/api/auth/forgot-password',
    '/api/auth/mobile-signin',
    '/api/system/config',
    '/api/explore/',
    '/api/blog/',
    '/api/public/',
    '/api/events',
    '/api/contact',
    '/api/openapi',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for excluded paths
    if (_isExcludedPath(options.path)) {
      return handler.next(options);
    }

    // Attach access token
    final accessToken = await _secureStorage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Check if this is a refresh request that failed
      if (err.requestOptions.path == '/api/auth/refresh') {
        await _handleRefreshFailure();
        return handler.next(err);
      }

      // Check if refresh is already in progress
      if (_isRefreshing) {
        // Queue this request
        final completer = Completer<String>();
        _queuedRequests.add(completer);
        
        try {
          final newToken = await completer.future;
          final retryResponse = await _retryRequest(
            err.requestOptions,
            newToken,
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.next(err);
        }
      }

      // Start refresh process
      _isRefreshing = true;

      try {
        final newToken = await _refreshToken();
        
        // Complete all queued requests
        for (final completer in _queuedRequests) {
          completer.complete(newToken);
        }
        _queuedRequests.clear();

        // Retry original request
        final retryResponse = await _retryRequest(
          err.requestOptions,
          newToken,
        );
        return handler.resolve(retryResponse);
      } catch (e) {
        // Refresh failed - logout
        await _handleRefreshFailure();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }

  bool _isExcludedPath(String path) {
    return _excludedPaths.any((excluded) => path.startsWith(excluded));
  }

  Future<String> _refreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final dio = _ref.read(dioProvider);
    final response = await dio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data['data'];
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    // Update stored tokens
    await _secureStorage.write(
      key: 'access_token',
      value: newAccessToken,
    );
    await _secureStorage.write(
      key: 'refresh_token',
      value: newRefreshToken,
    );

    // Update Supabase session
    await Supabase.instance.client.auth.setSession(Session(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    ));

    return newAccessToken;
  }

  Future<Response> _retryRequest(
    RequestOptions options,
    String newToken,
  ) async {
    final dio = _ref.read(dioProvider);
    options.headers['Authorization'] = 'Bearer $newToken';
    return dio.fetch(options);
  }

  Future<void> _handleRefreshFailure() async {
    // Clear all stored data
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    
    // Clear Supabase session
    await Supabase.instance.client.auth.signOut();
    
    // Clear Riverpod state
    _ref.invalidate(authProvider);
    
    // Navigate to login
    _ref.read(routerProvider).go('/auth/login');
  }
}
```

### Dio Configuration

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(
    ref.read(secureStorageProvider),
    ref,
  ));

  // Add logging interceptor (debug only)
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Add certificate pinning (production)
  if (kReleaseMode) {
    dio.interceptors.add(CertificatePinningInterceptor(
      allowedCertificates: [
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ],
    ));
  }

  return dio;
});
```

---

## 10. Role-Based Routing

### Router Configuration

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.stream)),
    redirect: (context, state) => _handleRedirect(ref, state),
    routes: [
      // Auth routes
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

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Subscription required
      GoRoute(
        path: '/subscription-required',
        builder: (context, state) => const SubscriptionRequiredScreen(),
      ),

      // Client routes
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/dashboard',
            builder: (context, state) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: '/client/workouts',
            builder: (context, state) => const ClientWorkoutsScreen(),
          ),
          GoRoute(
            path: '/client/progress',
            builder: (context, state) => const ClientProgressScreen(),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (context, state) => const ClientProfileScreen(),
          ),
          GoRoute(
            path: '/client/more',
            builder: (context, state) => const ClientMoreScreen(),
          ),
        ],
      ),

      // Trainer routes
      ShellRoute(
        builder: (context, state, child) => TrainerShell(child: child),
        routes: [
          GoRoute(
            path: '/trainer/dashboard',
            builder: (context, state) => const TrainerDashboardScreen(),
          ),
          GoRoute(
            path: '/trainer/clients',
            builder: (context, state) => const TrainerClientsScreen(),
          ),
          GoRoute(
            path: '/trainer/calendar',
            builder: (context, state) => const TrainerCalendarScreen(),
          ),
          GoRoute(
            path: '/trainer/programs',
            builder: (context, state) => const TrainerProgramsScreen(),
          ),
          GoRoute(
            path: '/trainer/profile',
            builder: (context, state) => const TrainerProfileScreen(),
          ),
        ],
      ),

      // Admin routes
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
            path: '/admin/tickets',
            builder: (context, state) => const AdminTicketsScreen(),
          ),
        ],
      ),
    ],
  );
});
```

### Redirect Logic

```dart
String? _handleRedirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authProvider);
  final isAuthenticated = authState.isAuthenticated;
  final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
  final isOnOnboarding = state.matchedLocation == '/onboarding';

  // Not authenticated
  if (!isAuthenticated) {
    if (!isOnAuthRoute) {
      return '/auth/login';
    }
    return null;
  }

  // Authenticated but on auth route
  if (isAuthenticated && isOnAuthRoute) {
    return _getDashboardRoute(authState);
  }

  // Check onboarding
  if (authState.isPending && !isOnOnboarding) {
    return '/onboarding';
  }

  // Check subscription for trainers
  if (authState.requiresSubscription && 
      !state.matchedLocation.startsWith('/subscription-required')) {
    return '/subscription-required';
  }

  // Role-based routing
  final currentRoute = state.matchedLocation;
  final expectedPrefix = _getRoleRoutePrefix(authState);
  
  if (!currentRoute.startsWith(expectedPrefix) && 
      !isOnOnboarding &&
      !state.matchedLocation.startsWith('/subscription-required')) {
    return '$expectedPrefix/dashboard';
  }

  return null;
}

String _getDashboardRoute(AuthState authState) {
  if (authState.isPending) return '/onboarding';
  if (authState.isTrainer) return '/trainer/dashboard';
  if (authState.isClient) return '/client/dashboard';
  if (authState.isAdmin) return '/admin/dashboard';
  return '/auth/login';
}

String _getRoleRoutePrefix(AuthState authState) {
  if (authState.isTrainer) return '/trainer';
  if (authState.isClient) return '/client';
  if (authState.isAdmin) return '/admin';
  return '/auth';
}
```

### Route Guards

```dart
class AuthGuard extends GoRouterGuard {
  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);

    if (!authState.isAuthenticated) {
      return '/auth/login';
    }

    return null;
  }
}

class RoleGuard extends GoRouterGuard {
  final List<String> allowedRoles;

  RoleGuard(this.allowedRoles);

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);

    if (!authState.isAuthenticated) {
      return '/auth/login';
    }

    final userRole = authState.profile?.role;
    if (userRole == null || !allowedRoles.contains(userRole)) {
      // Redirect to appropriate dashboard
      return _getDashboardRoute(authState);
    }

    return null;
  }
}
```

---

## 11. Deep Link Handling

### Deep Link Configuration

#### Android (AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity>
            <!-- OAuth callback deep link -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="zirofitapp"
                    android:host="auth-callback" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### iOS (Info.plist)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>zirofitapp</string>
            </array>
            <key>CFBundleURLName</key>
            <string>auth-callback</string>
        </dict>
    </array>
</dict>
</plist>
```

### Deep Link Handler

```dart
class DeepLinkHandler {
  static Future<void> initialize() async {
    // Handle cold start (app was terminated)
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      await _handleDeepLink(initialLink);
    }

    // Handle warm start (app was in background)
    linkStream.listen((link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });
  }

  static Future<void> _handleDeepLink(String link) async {
    final uri = Uri.parse(link);

    // Check if it's an auth callback
    if (uri.scheme == 'zirofitapp' && uri.host == 'auth-callback') {
      await _handleAuthCallback(uri);
    }
  }

  static Future<void> _handleAuthCallback(Uri uri) async {
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final userId = uri.queryParameters['user_id'];
    final role = uri.queryParameters['role'];

    if (accessToken == null || refreshToken == null) {
      // Invalid callback - redirect to login
      GetIt.instance<Router>().go('/auth/login');
      return;
    }

    try {
      // Store tokens
      final secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: 'access_token', value: accessToken);
      await secureStorage.write(key: 'refresh_token', value: refreshToken);

      // Initialize Supabase session
      await Supabase.instance.client.auth.setSession(Session(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ));

      // Sync user to ensure Prisma record exists
      final apiClient = GetIt.instance<AuthApiClient>();
      await apiClient.syncUser(
        id: userId!,
        email: '', // Will be fetched from /api/auth/me
        name: '',  // Will be fetched from /api/auth/me
        provider: 'oauth',
      );

      // Fetch extended profile
      final profile = await apiClient.getMe();

      // Update auth state
      final container = ProviderScope.containerKey('auth');
      container.read(authProvider.notifier).setAuthenticated(profile);

      // Navigate based on role
      final router = GetIt.instance<Router>();
      switch (profile.role) {
        case 'pending':
          router.go('/onboarding');
          break;
        case 'client':
          router.go('/client/dashboard');
          break;
        case 'trainer':
          router.go('/trainer/dashboard');
          break;
        case 'admin':
          router.go('/admin/dashboard');
          break;
        default:
          router.go('/auth/login');
      }
    } catch (e) {
      // Error handling - redirect to login
      GetIt.instance<Router>().go('/auth/login');
    }
  }
}
```

### Auth Callback Screen

```dart
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    // Get the current route's query parameters
    final queryParams = GoRouterState.of(context).queryParameters;
    
    final accessToken = queryParams['access_token'];
    final refreshToken = queryParams['refresh_token'];
    final userId = queryParams['user_id'];
    final role = queryParams['role'];

    if (accessToken == null || refreshToken == null) {
      // Invalid callback
      if (mounted) {
        context.go('/auth/login');
      }
      return;
    }

    try {
      // Process the auth callback
      await ref.read(authProvider.notifier).handleOAuthCallback(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        role: role,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
        context.go('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## 12. Security Considerations

### Token Storage

```dart
// flutter_secure_storage configuration
final secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  ),
);
```

### Certificate Pinning

```dart
class CertificatePinningInterceptor extends Interceptor {
  final List<String> allowedCertificates;

  CertificatePinningInterceptor({required this.allowedCertificates});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Configure SSL certificate pinning
    (HttpClient())
      ..badCertificateCallback = (certificate, host, port) {
        final fingerprint = sha256.convert(certificate.der).toString();
        return allowedCertificates.contains(fingerprint);
      };
    
    handler.next(options);
  }
}
```

### Biometric Authentication

```dart
class BiometricAuth {
  static final _localAuth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    return await _localAuth.canCheckBiometrics;
  }

  static Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Ziro Fit',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
```

### Security Checklist

| Security Measure | Implementation | Priority |
|-----------------|----------------|----------|
| Token Storage | flutter_secure_storage (encrypted) | **Critical** |
| Certificate Pinning | Dio interceptor | **High** |
| Biometric Lock | local_auth (optional) | Medium |
| No Token Logging | Remove print statements | **Critical** |
| Session Timeout | Auto-logout after 24h | Medium |
| App Lifecycle Lock | Lock when backgrounded | Low |
| Clear Data on Sign Out | Wipe all local data | **High** |
| Secure Deep Links | Validate callback parameters | **High** |
| Rate Limiting | Backend implementation | Medium |
| Input Validation | Client-side validation | **High** |

### Session Timeout Implementation

```dart
class SessionManager {
  static const _sessionTimeout = Duration(hours: 24);
  DateTime? _lastActivity;

  void updateActivity() {
    _lastActivity = DateTime.now();
  }

  bool isSessionExpired() {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > _sessionTimeout;
  }

  Future<void> checkSession() async {
    if (isSessionExpired()) {
      // Trigger logout
      final container = ProviderScope.containerKey('auth');
      await container.read(authProvider.notifier).signOut();
    }
  }
}
```

---

## 13. Auth API Client Methods

### API Client Implementation

```dart
class AuthApiClient {
  final Dio _dio;

  AuthApiClient(this._dio);

  // POST /api/auth/login
  Future<LoginResponse> login(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(response.data['data']);
  }

  // POST /api/auth/register
  Future<RegisterResponse> register(
    String name,
    String email,
    String password, {
    String? role,
    String? trainerId,
  }) async {
    final data = {
      'name': name,
      'email': email,
      'password': password,
    };
    if (role != null) data['role'] = role;
    if (trainerId != null) data['trainerId'] = trainerId;

    final response = await _dio.post('/api/auth/register', data: data);
    return RegisterResponse.fromJson(response.data['data']);
  }

  // GET /api/auth/mobile-signin?provider=google|apple
  Uri getOAuthUrl(String provider) {
    return Uri.parse('${_dio.options.baseUrl}/api/auth/mobile-signin')
        .replace(queryParameters: {'provider': provider});
  }

  // POST /api/auth/refresh
  Future<TokenRefreshResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return TokenRefreshResponse.fromJson(response.data['data']);
  }

  // POST /api/auth/signout
  Future<void> signOut() async {
    await _dio.post('/api/auth/signout');
  }

  // GET /api/auth/me
  Future<ExtendedProfile> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return ExtendedProfile.fromJson(response.data['data']);
  }

  // POST /api/auth/sync-user
  Future<void> syncUser({
    required String id,
    required String email,
    required String name,
    required String provider,
  }) async {
    await _dio.post('/api/auth/sync-user', data: {
      'id': id,
      'email': email,
      'name': name,
      'provider': provider,
    });
  }

  // POST /api/auth/complete-onboarding
  Future<void> completeOnboarding() async {
    await _dio.post('/api/auth/complete-onboarding');
  }

  // POST /api/auth/forgot-password
  Future<void> forgotPassword(String email, {String? redirectTo}) async {
    final data = {'email': email};
    if (redirectTo != null) data['redirectTo'] = redirectTo;
    await _dio.post('/api/auth/forgot-password', data: data);
  }

  // POST /api/auth/update-password
  Future<void> updatePassword(String password) async {
    await _dio.post('/api/auth/update-password', data: {'password': password});
  }

  // POST /api/auth/resend-verification-email
  Future<void> resendVerificationEmail(String email, {String? redirect}) async {
    final data = {'email': email};
    if (redirect != null) data['redirect'] = redirect;
    await _dio.post('/api/auth/resend-verification-email', data: data);
  }
}
```

### Response Models

```dart
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final String role;
  final String? message; // Informational, e.g. "Login successful."

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.role,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: User.fromJson(json['user']),
      role: json['role'],
      message: json['message'],
    );
  }
}

class RegisterResponse {
  final String userId;
  final bool requiresSubscription;
  final bool confirmationRequired;
  final String? message; // Informational, e.g. "Registration successful. Please verify your email."

  RegisterResponse({
    required this.userId,
    required this.requiresSubscription,
    required this.confirmationRequired,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['userId'],
      requiresSubscription: json['requiresSubscription'] ?? false,
      confirmationRequired: json['confirmationRequired'] ?? true,
      message: json['message'],
    );
  }
}

class TokenRefreshResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt; // Computed from Supabase Unix-seconds timestamp
  final User user;

  TokenRefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    // expiresAt comes from Supabase as Unix SECONDS, convert to ms for Dart
    final expiresAtSeconds = json['expiresAt'] as int;
    return TokenRefreshResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtSeconds * 1000),
      user: User.fromJson(json['user']),
    );
  }
}
```

---

## 14. Auth Provider Interface (Riverpod)

### Abstract Interface

```dart
abstract class AuthProviderInterface {
  // State
  AuthState get state;
  Stream<AuthState> get stream;

  // Actions
  Future<void> initialize();
  Future<Result<LoginResponse>> login(String email, String password);
  Future<Result<RegisterResponse>> register(
    String name,
    String email,
    String password, {
    String? role,
    String? trainerId,
  });
  Future<Result<void>> signInWithOAuth(String provider);
  Future<void> signOut();
  Future<void> refreshSession();
  Future<void> forgotPassword(String email);
  Future<void> updatePassword(String password);
  Future<void> completeOnboarding();
  Future<void> resendVerificationEmail(String email);
}
```

### Result Type

```dart
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
    Success<T>(:final data) => data,
    Failure() => null,
  };

  String? get error => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}
```

### Provider Dependencies

```dart
// API Client Provider
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApiClient(dio);
});

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(AuthInterceptor(
    ref.read(secureStorageProvider),
    ref,
  ));

  return dio;
});
```

---

## 15. Error Handling

### Error Scenarios

| Scenario | Error Code | User Message | Action |
|----------|-----------|--------------|--------|
| Wrong credentials | `AUTH_INVALID_CREDENTIALS` | "Invalid email or password" | Show error on form |
| Email already registered | `AUTH_EMAIL_EXISTS` | "Email already registered" | Show error on form |
| Email not verified | `AUTH_EMAIL_NOT_VERIFIED` | "Please verify your email" | Show verification message |
| Token expired | `AUTH_TOKEN_EXPIRED` | (Silent) | Auto-refresh, retry |
| Refresh failed | `AUTH_REFRESH_FAILED` | "Session expired" | Logout, redirect to login |
| Network error | `NETWORK_ERROR` | "No internet connection" | Show retry button |
| OAuth cancelled | `OAUTH_CANCELLED` | (None) | Return to login |
| Server error | `SERVER_ERROR` | "Something went wrong" | Show generic error |
| Rate limited | `RATE_LIMITED` | "Too many attempts" | Show cooldown timer |

### Error Handling Implementation

```dart
class AuthError {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  AuthError({
    required this.message,
    this.code,
    this.details,
  });

  factory AuthError.fromApi(Map<String, dynamic> error) {
    return AuthError(
      message: error['message'] ?? 'An error occurred',
      code: error['code'],
      details: error['details'],
    );
  }

  // User-friendly messages
  String get userMessage {
    switch (code) {
      case 'AUTH_INVALID_CREDENTIALS':
        return 'Invalid email or password';
      case 'AUTH_EMAIL_EXISTS':
        return 'This email is already registered';
      case 'AUTH_EMAIL_NOT_VERIFIED':
        return 'Please verify your email before logging in';
      case 'AUTH_TOKEN_EXPIRED':
        return 'Your session has expired';
      case 'NETWORK_ERROR':
        return 'No internet connection. Please try again.';
      default:
        return message;
    }
  }
}

// Error handling in AuthNotifier
Future<Result<LoginResponse>> login(String email, String password) async {
  try {
    final response = await _apiClient.login(email, password);
    // ... success handling
    return Result.success(response);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      final error = AuthError.fromApi(e.response!.data['error']);
      return Result.failure(error.userMessage);
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      return Result.failure('Connection timeout. Please try again.');
    } else {
      return Result.failure('Network error. Please check your connection.');
    }
  } catch (e) {
    return Result.failure('An unexpected error occurred');
  }
}
```

### Error UI Components

```dart
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

---

## 16. Testing Auth (TDD)

### Test Setup

```dart
// test/helpers/test_helpers.dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAuthApiClient extends Mock implements AuthApiClient {}

// Register fallback values
class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeUri extends Fake implements Uri {}

void setUpMocks() {
  registerFallbackValue(FakeRequestOptions());
  registerFallbackValue(FakeUri());
}
```

### Auth Provider Tests

```dart
// test/auth/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockAuthApiClient mockApiClient;
  late MockSecureStorage mockSecureStorage;
  late AuthNotifier authNotifier;

  setUp(() {
    mockApiClient = MockAuthApiClient();
    mockSecureStorage = MockSecureStorage();
    authNotifier = AuthNotifier(
      apiClient: mockApiClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('login', () {
    test('successful login updates state to authenticated', () async {
      // Arrange
      final loginResponse = LoginResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: User(id: '1', email: 'test@example.com'),
        role: 'client',
      );
      final profile = ExtendedProfile(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'client',
      );

      when(() => mockApiClient.login(any(), any()))
          .thenAnswer((_) async => loginResponse);
      when(() => mockApiClient.getMe())
          .thenAnswer((_) async => profile);
      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      // Act
      final result = await authNotifier.login('test@example.com', 'password');

      // Assert
      expect(result.isSuccess, true);
      expect(authNotifier.state.status, AuthStatus.authenticated);
      expect(authNotifier.state.profile?.role, 'client');
    });

    test('failed login updates state with error', () async {
      // Arrange
      when(() => mockApiClient.login(any(), any()))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {'error': {'message': 'Invalid credentials'}},
        ),
      ));

      // Act
      final result = await authNotifier.login('test@example.com', 'wrong');

      // Assert
      expect(result.isFailure, true);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.error, isNotNull);
    });
  });

  group('signOut', () {
    test('clears all data and navigates to login', () async {
      // Arrange
      when(() => mockApiClient.signOut()).thenAnswer((_) async {});
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await authNotifier.signOut();

      // Assert
      verify(() => mockApiClient.signOut()).called(1);
      verify(() => mockSecureStorage.delete(key: 'access_token')).called(1);
      verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
    });
  });
}
```

### Auth Interceptor Tests

```dart
// test/auth/auth_interceptor_test.dart
void main() {
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;
  late AuthInterceptor authInterceptor;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    authInterceptor = AuthInterceptor(mockSecureStorage, mockRef);
  });

  group('onRequest', () {
    test('attaches Bearer token to authorized requests', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'test_token');

      final options = RequestOptions(path: '/api/auth/me');

      // Act
      await authInterceptor.onRequest(options, MockRequestInterceptorHandler());

      // Assert
      expect(options.headers['Authorization'], 'Bearer test_token');
    });

    test('skips auth for excluded paths', () async {
      // Arrange
      final options = RequestOptions(path: '/api/auth/login');

      // Act
      await authInterceptor.onRequest(options, MockRequestInterceptorHandler());

      // Assert
      expect(options.headers.containsKey('Authorization'), false);
    });
  });

  group('onError', () {
    test('refreshes token on 401 and retries request', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api/auth/me');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      when(() => mockSecureStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      // Act & Assert
      // Test the refresh flow
    });
  });
}
```

### Deep Link Tests

```dart
// test/auth/deep_link_test.dart
void main() {
  group('AuthCallbackScreen', () {
    testWidgets('handles valid OAuth callback', (tester) async {
      // Arrange
      final queryParams = {
        'access_token': 'test_access_token',
        'refresh_token': 'test_refresh_token',
        'user_id': 'test_user_id',
        'role': 'client',
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AuthCallbackScreen(),
          ),
        ),
      );

      // Assert
      // Verify tokens are stored
      // Verify navigation occurs
    });

    testWidgets('redirects to login on invalid callback', (tester) async {
      // Arrange - no tokens in query params

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AuthCallbackScreen(),
          ),
        ),
      );

      // Assert - should redirect to login
    });
  });
}
```

### Role Routing Tests

```dart
// test/auth/role_routing_test.dart
void main() {
  group('Role-based routing', () {
    test('trainer redirects to trainer dashboard', () {
      // Arrange
      final authState = AuthState(
        status: AuthStatus.authenticated,
        profile: ExtendedProfile(
          id: '1',
          email: 'trainer@example.com',
          name: 'Trainer',
          role: 'trainer',
        ),
      );

      // Act
      final redirect = handleRedirect(authState, '/auth/login');

      // Assert
      expect(redirect, '/trainer/dashboard');
    });

    test('client redirects to client dashboard', () {
      // Arrange
      final authState = AuthState(
        status: AuthStatus.authenticated,
        profile: ExtendedProfile(
          id: '1',
          email: 'client@example.com',
          name: 'Client',
          role: 'client',
        ),
      );

      // Act
      final redirect = handleRedirect(authState, '/auth/login');

      // Assert
      expect(redirect, '/client/dashboard');
    });

    test('pending user redirects to onboarding', () {
      // Arrange
      final authState = AuthState(
        status: AuthStatus.authenticated,
        profile: ExtendedProfile(
          id: '1',
          email: 'new@example.com',
          name: 'New User',
          role: 'pending',
          hasCompletedOnboarding: false,
        ),
      );

      // Act
      final redirect = handleRedirect(authState, '/client/dashboard');

      // Assert
      expect(redirect, '/onboarding');
    });
  });
}
```

---

## 17. Implementation Checklist

### Phase 1: Core Auth (Week 1)

- [ ] Set up `supabase_flutter` SDK
- [ ] Configure `flutter_secure_storage`
- [ ] Create `AuthApiClient` with all endpoints
- [ ] Implement `AuthState` model
- [ ] Create `AuthNotifier` with login/register
- [ ] Set up `AuthInterceptor` for Dio
- [ ] Implement token refresh logic
- [ ] Create login screen UI
- [ ] Create register screen UI
- [ ] Test email/password login flow

### Phase 2: OAuth & Deep Links (Week 2)

- [ ] Configure Android deep link (AndroidManifest.xml)
- [ ] Configure iOS deep link (Info.plist)
- [ ] Implement `DeepLinkHandler`
- [ ] Create `AuthCallbackScreen`
- [ ] Implement Google OAuth flow
- [ ] Implement Apple OAuth flow
- [ ] Test OAuth callback parsing
- [ ] Test user sync after OAuth

### Phase 3: Auto-Login & Session (Week 3)

- [ ] Implement bootstrap auto-login
- [ ] Create session timeout logic
- [ ] Implement app lifecycle handling
- [ ] Test token persistence
- [ ] Test session restoration
- [ ] Test refresh token rotation

### Phase 4: Routing & Navigation (Week 4)

- [ ] Configure `GoRouter` with auth routes
- [ ] Implement redirect logic
- [ ] Create role-based shell routes
- [ ] Create client dashboard shell
- [ ] Create trainer dashboard shell
- [ ] Create admin dashboard shell
- [ ] Test role-based navigation

### Phase 5: Security & Polish (Week 5)

- [ ] Implement certificate pinning
- [ ] Add biometric auth option
- [ ] Implement session timeout
- [ ] Clear data on sign out
- [ ] Add error handling UI
- [ ] Add loading states
- [ ] Test security measures

### Phase 6: Testing (Week 6)

- [ ] Write AuthProvider unit tests
- [ ] Write AuthInterceptor tests
- [ ] Write deep link tests
- [ ] Write role routing tests
- [ ] Write integration tests
- [ ] Test edge cases
- [ ] Performance testing

---

## Appendix A: Package Dependencies

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  riverpod: ^2.4.0
  go_router: ^13.0.0
  local_auth: ^2.1.0
  # OAuth handled natively by supabase_flutter — no flutter_appauth needed
  url_launcher: ^6.0.0     # For deep links
  shared_preferences: ^2.0.0

dev_dependencies:
  mocktail: ^1.0.0
  flutter_test:
    sdk: flutter
```

## Appendix B: Environment Variables

```dart
// lib/config/env.dart
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String apiUrl = String.fromEnvironment('API_URL');
  
  // Development defaults
  static const String devSupabaseUrl = 'https://your-project.supabase.co';
  static const String devSupabaseAnonKey = 'your-anon-key';
  static const String devApiUrl = 'http://localhost:3000';
}
```

## Appendix C: API Endpoints Reference

| Method | Path | Auth Required | Description |
|--------|------|---------------|-------------|
| POST | `/api/auth/login` | No | Email/password login |
| POST | `/api/auth/register` | No | Create account |
| GET | `/api/auth/mobile-signin` | No | OAuth flow init |
| POST | `/api/auth/refresh` | No | Refresh access token |
| POST | `/api/auth/signout` | Yes | Sign out |
| GET | `/api/auth/me` | Yes | Get current user |
| POST | `/api/auth/sync-user` | Yes | Sync user after OAuth |
| POST | `/api/auth/complete-onboarding` | Yes | Mark onboarding done |
| POST | `/api/auth/forgot-password` | No | Request password reset |
| POST | `/api/auth/update-password` | Yes | Update password |
| POST | `/api/auth/resend-verification-email` | No | Resend verification |

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-15  
**Author**: Ziro Fit Development Team
