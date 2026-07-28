# Auth Backend Integration Plan

## Goal
Connect the Carlton Leisure Flutter mobile app to the existing .NET / SQL Server backend so users can log in and register using the same accounts as the web application.

---

## Background

The mobile app (`carlton_leisure_app`) is a Phase 1 Flutter scaffold with UI-only auth screens (login, signup, forgot password) and a ready-made `ApiClient` (Dio) with secure token storage. The backend (`Carlton.CustomerSelfService`) is a .NET 10 Web API with JWT cookies, SQL Server, and a React/TypeScript frontend.

---

## Critical Finding: Cookie-Based Auth (Not Bearer Header)

The backend uses **HTTP-only cookies** for JWT token transmission, not the `Authorization: Bearer <token>` header. This is the single most important architectural decision for this integration.

**How it works:**
1. On `POST /api/Auth/login` or `POST /api/Auth/register`, the server sets two `Set-Cookie` headers:
   - `auth_token` — JWT access token (HttpOnly, Secure, SameSite=None,expires in 60 min)
   - `refresh_token` — opaque refresh token (HttpOnly, Secure, SameSite=None, expires in 7 days)
2. On every subsequent authenticated request, the browser (or mobile HTTP client) sends these cookies automatically.
3. The `[Authorize]` attribute reads the JWT from the `auth_token` cookie via `OnMessageReceived` in `Program.cs`.
4. On `POST /api/Auth/refresh`, the server reads `refresh_token` from the cookie, rotates it, and sets new cookies.
5. On `POST /api/Auth/logout`, the server clears both cookies.

**Impact on mobile app:**
- The existing `ApiClient` interceptor that adds `Authorization: Bearer $token` to headers is **not compatible** with this backend.
- The mobile app must use a **cookie jar** (`CookieManager` in Dio) so that cookies set by the server are automatically included in subsequent requests.
- Token storage in `flutter_secure_storage` is unnecessary for auth tokens (the server manages them via cookies), but can still be used for user preferences or non-auth data.

---

## Backend API Details

### Base URL
- **Dev/Staging**: `http://localhost:5193/api`
- **Production**: TBD (likely `https://api.carltonleisure.com`)

### Confirmed Endpoints

#### Authentication

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/api/Auth/login` | No | Login with `{Username, Password}`. `Username` = email. Sets `auth_token` + `refresh_token` cookies. Returns `{user, expiresAt, claimedBookingCount}` |
| POST | `/api/Auth/register` | No | Register with `{FirstName, LastName, Email, Password, PhoneCountryCode?, PhoneNumber?, DateOfBirth?, Nationality?}`. Sets cookies. Returns `{message, user, expiresAt, claimedBookingCount}` |
| GET | `/api/Auth/me` | Yes | Get current user. Reads JWT from `auth_token` cookie. Returns `UserDto` |
| POST | `/api/Auth/refresh` | No | Refresh tokens. Reads `refresh_token` cookie. Sets new cookies. Returns `{user, expiresAt}` |
| POST | `/api/Auth/logout` | Yes | Clear auth cookies |
| POST | `/api/Auth/password/recovery/verify` | No | Verify recovery contact `{Email, PhoneNumber}`. Returns `{verified, message}` |
| POST | `/api/Auth/password/recovery/reset` | No | Reset password `{Email, PhoneNumber, NewPassword}`. Returns `{message}` |
| POST | `/api/Auth/password/change` | Yes | Change password `{CurrentPassword, NewPassword}`. Returns `{message}` |
| POST | `/api/Auth/admin/users` | Admin role | Create staff user (Admin only) |

#### Flights

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/flights` | No | Get all flights |
| GET | `/api/flights/{id}` | No | Get flight by ID |
| POST | `/api/flights` | Admin only | Create flight |
| PUT | `/api/flights/{id}` | Admin only | Update flight |
| DELETE | `/api/flights/{id}` | Admin only | Delete flight |

#### Bookings

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/bookings` | Yes | Get bookings for current user |
| POST | `/api/bookings` | Yes | Create booking |
| PUT | `/api/bookings/{id}` | Yes | Update booking |
| DELETE | `/api/bookings/{id}` | Yes | Cancel booking |

### Request/Response DTOs

**LoginRequestDto:**
```json
{ "Username": "john.doe@carlton.com", "Password": "SecurePass1!" }
```
Note: `Username` is the email address.

**LoginResponseDto (response body):**
```json
{
  "user": { "id": 1, "username": "john.doe@carlton.com", "name": "John Doe", "role": "Customer", "createdAt": "2024-01-01T00:00:00Z" },
  "expiresAt": "2024-01-01T01:00:00Z",
  "claimedBookingCount": 0
}
```
(Tokens are in cookies, not in the response body.)

**RegisterRequestDto:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@carlton.com",
  "password": "SecurePass1!",
  "phoneCountryCode": "+61",
  "phoneNumber": "412345678",
  "dateOfBirth": "1990-01-01",
  "nationality": "Australian"
}
```
All fields except `phoneCountryCode`, `phoneNumber`, `dateOfBirth`, and `nationality` are required. Server-side validation requires: password >= 8 chars, at least one uppercase, one digit, one special character.

**UserDto (returned in responses):**
```json
{
  "id": 1,
  "username": "john.doe@carlton.com",
  "name": "John Doe",
  "role": "Customer",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**User model (backend entity):** `Id`, `Username` (email), `PasswordHash`, `Name`, `Role` (enum), `DbRoleId`, `DbRole`, `CreatedAt`, `IsActive`, `CustomerId`, `Customer`, `Profile`, `Preference`, `RefreshTokens`

**Roles (UserRole enum):** `Customer=0`, `TicketOfficer=1`, `FinanceOfficer=2`, `OperationsManager=3`, `Admin=4`, `TicketingOfficer=5`, `CustomerServiceOfficer=6`, `SalesOfficer=7`

---

## Key Design Decisions

### 1. Auth Mechanism: Cookie-Based (Matches Backend)
The mobile app uses Dio's `CookieManager` with a `CookieJar` to automatically handle session cookies. All auth tokens are managed by the server via `Set-Cookie` headers — the mobile app never reads, stores, or manually sends JWT tokens.

### 2. Signup Flow: Self-Service Registration (Option A)
New users register directly in the mobile app via `POST /api/Auth/register`. The signup screen sends `{FirstName, LastName, Email, Password, ...}` and the backend creates the account, sets cookies, and returns the user profile.

### 3. Login Field Mapping
The mobile login form currently has `email` and `password` fields. The backend expects `Username` (which IS the email). The mobile app maps the email field to `Username` in the login request body.

### 4. Register Field Mapping
The mobile signup form has `name`, `email`, `password`, `confirmPassword`. The backend expects `FirstName`, `LastName`, `Email`, `Password` (no `confirmPassword` — validated server-side). The mobile app needs to:
- Split the `name` field into `FirstName` and `LastName` (or add separate fields)
- Remove the `confirmPassword` field (server validates password strength)
- Optionally add `phoneCountryCode`, `phoneNumber`, `dateOfBirth`, `nationality` fields

---

## Implementation Steps

### Step 1: Configure Dio with Cookie Manager

**File**: `lib/core/network/api_client.dart`

- Remove the `Authorization: Bearer` header interceptor
- Add `CookieManager(CookieJar())` to Dio interceptors
- The cookie jar automatically stores `Set-Cookie` responses and sends cookies on subsequent requests
- Keep the `PrettyDioLogger` for debugging
- The `_authInterceptor()` can be simplified — no more manual token attachment or 401 refresh logic (refresh is handled by the server cookie rotation)

### Step 2: Define auth data models

**Files**: `lib/features/auth/data/models/`

- `user_model.dart` — maps `UserDto` fields (`id`, `username`, `name`, `role`, `createdAt`)
- `login_request.dart` — `{username, password}` (username = email)
- `register_request.dart` — `{firstName, lastName, email, password, phoneCountryCode?, phoneNumber?, dateOfBirth?, nationality?}`
- `login_response.dart` — `{user, expiresAt, claimedBookingCount}` (tokens are in cookies, not body)

Use `json_serializable` / `freezed` (already in `pubspec.yaml`).

### Step 3: Create auth API service

**File**: `lib/features/auth/data/datasources/auth_remote_datasource.dart`

- Wraps `ApiClient` (Dio with CookieManager) for auth endpoints
- `login(username, password)` → `POST /api/Auth/login`
- `register(RegisterRequestDto)` → `POST /api/Auth/register`
- `getCurrentUser()` → `GET /api/Auth/me`
- `refreshToken()` → `POST /api/Auth/refresh` (handled by cookie jar automatically, but this call explicitly refreshes)
- `logout()` → `POST /api/Auth/logout`
- Maps HTTP responses to data models
- Throws domain exceptions for error handling (401, 409 conflict for existing email, 429 rate limit)

### Step 4: Create auth repository

**Interface**: `lib/features/auth/domain/repositories/auth_repository.dart`

**Implementation**: `lib/features/auth/data/repositories/auth_repository_impl.dart`

- Calls `AuthRemoteDatasource` for network operations
- Stores user profile in `flutter_secure_storage` (for persistence across app restarts — cookies are in-memory only)
- Clears stored user data on logout
- Returns domain entities to the BLoC layer

### Step 5: Implement auth BLoC

**Files**:
- `lib/features/auth/domain/entities/user.dart` — domain entity
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/bloc/auth_event.dart`
- `lib/features/auth/presentation/bloc/auth_state.dart`

States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`
Events: `AuthLoginRequested`, `AuthRegisterRequested`, `AuthLogoutRequested`, `AuthCheckSessionRequested`

### Step 6: Wire DI registrations

**File**: `lib/core/di/injection.dart`

Register: `AuthRemoteDatasource`, `AuthRepository`, `AuthBloc`, `CookieJar`, `ApiClient` (with CookieManager)

### Step 7: Connect login screen to backend

**File**: `lib/features/auth/presentation/screens/login_screen.dart`

- Replace `_handleLogin` mock with `AuthBloc.add(AuthLoginRequested(email, password))`
- Map email field to `Username` in `LoginRequestDto`
- Show loading state, error snack-bar on failure, navigate to home on success
- Use `BlocBuilder` or `context.watch<AuthBloc>()` to react to state changes

### Step 8: Connect signup screen to backend

**File**: `lib/features/auth/presentation/screens/signup_screen.dart`

- Replace `_handleSignup` mock with `AuthBloc.add(AuthRegisterRequested(...))`
- Map form fields to `RegisterRequestDto`
- Split `name` into `firstName`/`lastName` or add separate name fields
- Handle validation errors from backend inline (e.g., "An account with this email already exists")
- Remove `confirmPassword` field (server validates password strength; no client-side confirm needed)

### Step 9: Connect forgot-password screen to backend

**File**: `lib/features/auth/presentation/screens/forgot_password_screen.dart`

- Step 1 → `POST /api/Auth/password/recovery/verify` with `{email, phoneNumber}`
- Step 2 → verify code (the backend uses email+phone matching, not a 6-digit code — adjust the UI accordingly)
- Step 3 → `POST /api/Auth/password/recovery/reset` with `{email, phoneNumber, newPassword}`
- Note: The backend's recovery flow is email+phone based, not a 6-digit code. The UI may need adjustment.

### Step 10: Implement splash screen session check

**File**: `lib/features/auth/presentation/screens/splash_screen.dart`

- On init, call `GET /api/Auth/me` to check if the session cookie is still valid
- If session valid → navigate to `/home`; if not → navigate to `/login`
- This replaces the current `Future.delayed` mock navigation

### Step 11: Update `ApiClient` auth interceptor

**File**: `lib/core/network/api_client.dart`

- Remove the `Authorization: Bearer` header logic from `_authInterceptor()`
- Remove the 401 auto-refresh stub (cookie-based refresh is handled by explicit `POST /api/Auth/refresh` call or automatic cookie re-issuance from the server)
- Keep the `CookieManager` in interceptors (added in Step 1)
- Keep error handling for 401 (session expired → route to login)

### Step 12: Implement logout

- Call `POST /api/Auth/logout`
- Clear session cookie from Dio's cookie jar
- Clear stored user data from `flutter_secure_storage`
- Reset `AuthBloc` to `AuthUnauthenticated`
- Navigate to `/login` and clear navigation stack

---

## Cookie Management in Dio (Flutter)

 Dio's `CookieManager` with `CookieJar` automatically:
 - Stores cookies from `Set-Cookie` response headers
 - Sends matching cookies on subsequent requests to the same domain
 - Handles cookie expiration and domain matching

 ```dart
 import 'package:dio/dio.dart';

 final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
 dio.interceptors.add(CookieManager(CookieJar()));
 ```

 When the server responds to login with:
 ```
 Set-Cookie: auth_token=<jwt>; HttpOnly; Secure; SameSite=None; Path=/; Expires=...
 Set-Cookie: refresh_token=<refresh>; HttpOnly; Secure; SameSite=None; Path=/; Expires=...
 ```
 Dio automatically stores these. Future requests to `localhost:5193` will include them.

 **Important**: `Secure` flag on cookies means they are only sent over HTTPS. For local development (HTTP), the cookies may not be set properly. The backend's `Program.cs` has `Secure = true` on cookies — in production this is correct, but for local dev the backend may need `Secure` set conditionally or the mobile app may need to connect via HTTPS to localhost (which requires a trusted cert).

 ---

 ## File Manifest (new files to create)

 ```
 lib/features/auth/data/
   models/
     user_model.dart
     login_request.dart
     register_request.dart
     login_response.dart
   datasources/
     auth_remote_datasource.dart
   repositories/
     auth_repository_impl.dart

 lib/features/auth/domain/
   entities/
     user.dart
   repositories/
     auth_repository.dart

 lib/features/auth/presentation/
   bloc/
     auth_bloc.dart
     auth_event.dart
     auth_state.dart

 Updated files:
   api_client.dart (replace Bearer interceptor with CookieManager, update error handling)
   injection.dart (register CookieJar, auth services)
   login_screen.dart (wire to AuthBloc, map to Username field)
   signup_screen.dart (wire to AuthBloc, split name field, remove confirm password)
   forgot_password_screen.dart (wire to backend recovery endpoints)
   splash_screen.dart (check session via GET /api/Auth/me)
 ```

---

## Open Questions (need resolution before implementation)

| # | Question | Status | Who can answer |
|---|----------|--------|----------------|
| 1 | Will the backend allow non-browser clients (mobile app) to receive and use cookies? Cookie spec requires `Secure` flag + `SameSite=None` which may need HTTPS for local dev | Needs backend team input | Backend team |
| 2 | Does the backend's `Secure = true` cookie flag break cookie reception over plain HTTP in local dev? | Needs backend team input | Backend team |
| 3 | What is the production base URL? (`https://api.carltonleisure.com` or different?) | TBD | Backend team |
| 4 | Does the backend's CORS policy (`AllowFrontend`) need to allow mobile app traffic? Mobile doesn't enforce CORS, but proxy/reverse proxy might | TBD | Backend team |
| 5 | Does the mobile app need HTTPS for the production base URL? | TBD | Backend team |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Cookie-based auth is fundamentally different from Bearer-header approach | The plan addresses this by using Dio's CookieManager; however, the `Secure` cookie flag may break HTTP local dev |
| `Secure` cookies don't work over plain HTTP in development | Backend team should set `Secure = false` in development, or mobile app should connect to HTTPS localhost |
| CORS policy may block requests from non-browser clients | Mobile HTTP clients don't enforce CORS; verify no proxy/reverse proxy blocks the mobile app |
| `ConfirmPassword` field in signup screen has no server-side equivalent | Remove from mobile form; server validates password strength independently |
| `Name` field in mobile signup needs to be split into `FirstName`/`LastName` | Update signup form UI to have separate first/last name fields (matching `RegisterRequestDto`) |
| Backend is in active development — endpoints may change | Pin to API version or use contract testing; design data layer to be easily adaptable |
| Forgot password flow differs (email+phone vs 6-digit code) | Align mobile UI with backend's actual recovery mechanism |

---

## Validation Steps

1. Unit test `AuthRemoteDatasource` with mock `ApiClient` (with CookieManager)
2. Unit test `AuthRepositoryImpl` with mock datasource
3. Unit test `AuthBloc` state transitions with mock repository
4. Integration test: login with valid credentials → cookies set → `GET /api/Auth/me` returns user → navigate to home
5. Integration test: login with invalid credentials → error displayed
6. Integration test: register new user → cookies set → navigate to home
7. Integration test: session expiry → navigate to login
8. Integration test: logout → cookies cleared → session reset
9. Manual test: login with existing web app credentials on a real device
10. Manual test: register new account on mobile → verify account exists in SQL Server
