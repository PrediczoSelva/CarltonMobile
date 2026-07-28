# Carlton Leisure — Mobile Application

Flutter mobile app for Carlton Leisure flight, hotel, and car booking. Phase 1 includes full auth integration with the existing .NET backend, project structure, theme, navigation, and DI. Booking/payment/hotels/cars modules are built out in later phases.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State management | flutter_bloc + equatable |
| Navigation | go_router |
| Dependency injection | get_it + injectable |
| HTTP client | Dio with cookie-based session management |
| Local storage | flutter_secure_storage (user data cache) |
| Serialization | json_serializable + freezed |
| UI | Flutter Material 3 + custom theme |

## Backend

| Layer | Technology |
|-------|-----------|
| Framework | .NET 10 (ASP.NET Core Web API) |
| Database | SQL Server |
| Auth | JWT via HTTP-only cookies |
| CORS | AllowFrontend policy |

The backend repository is at:
`/Users/sajaniprabhashika/Documents/Onedata 4/Carlton/backend/Carlton.CustomerSelfService`

---

## Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK (bundled with Flutter)
- Android emulator or physical Android device
- .NET 10 SDK (for backend)
- SQL Server (for backend)

## Setup

### 1. Get dependencies

```bash
flutter pub get
```

### 2. Start the backend

Navigate to the backend project and run it:

```bash
cd "/Users/sajaniprabhashika/Documents/Onedata 4/Carlton/backend/Carlton.CustomerSelfService/Carlton.CustomerSelfService"
dotnet run
```

The backend starts on `http://localhost:5193` in Development mode. Wait for `Now listening on: http://localhost:5193` in the terminal.

### 3. Run the mobile app

For emulator development (Android emulator connects to host Mac via `10.0.2.2`):

```bash
cd /Users/sajaniprabhashika/Documents/carlton_leisure_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5193/api
```

For local machine testing (Flutter on web or device with host access):

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5193/api
```

For production:

```bash
flutter run --dart-define=API_BASE_URL=https://api.carltonleisure.com/api
```

### 4. Test credentials

Use seeded test accounts from the SQL Server database. The backend seeds default users on first run. Use `customer1` / `customer123` or existing database credentials.

---

## API Endpoints

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/Auth/login` | User login (returns JWT cookies) |
| GET | `/api/Auth/me` | Get current user (requires auth cookie) |
| POST | `/api/Auth/register` | Self-service registration |
| POST | `/api/Auth/refresh` | Refresh auth cookies |
| POST | `/api/Auth/logout` | Clear auth cookies |
| POST | `/api/Auth/admin/users` | Create staff user (Admin only) |
| POST | `/api/Auth/password/recovery/verify` | Verify recovery contact |
| POST | `/api/Auth/password/recovery/reset` | Reset password |
| POST | `/api/Auth/password/change` | Change password (requires auth) |

### Flights

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/flights` | Get all flights |
| GET | `/api/flights/{id}` | Get flight by ID |
| POST | `/api/flights` | Create flight (Admin only) |
| PUT | `/api/flights/{id}` | Update flight (Admin only) |
| DELETE | `/api/flights/{id}` | Delete flight (Admin only) |

### Bookings

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/bookings` | Get user bookings |
| POST | `/api/bookings` | Create booking |
| PUT | `/api/bookings/{id}` | Update booking |
| DELETE | `/api/bookings/{id}` | Cancel booking |

## Project Structure

```
lib/
  core/
    network/
      api_client.dart           Dio client with cookie-based session management
    constants/
      app_constants.dart        API base URL, timeouts, secure storage keys
    di/
      injection.dart            get_it service locator + DI setup
    router/
      app_router.dart           go_router configuration
    theme/
      app_theme.dart            AppTheme with light/dark
      app_colors.dart           Color constants
      app_text_styles.dart      Typography constants
    utils/                      Helpers, formatters (add as needed)
  features/
    auth/
      data/
        models/                 LoginRequest, RegisterRequest, LoginResponse, UserModel
        datasources/
          auth_remote_datasource.dart           Abstract auth API interface
          auth_remote_datasource_impl.dart      Dio-based auth API implementation
        repositories/
          auth_repository_impl.dart             Auth repo implementation
      domain/
        entities/
          user.dart                 User domain entity
        repositories/
          auth_repository.dart      Abstract auth repo interface
      presentation/
        bloc/
          auth_bloc.dart            Auth BLoC (login, register, logout, session check)
          auth_event.dart           Auth events
          auth_state.dart           Auth states
        screens/
          splash_screen.dart        Splash → checks session → routes to login/home
          login_screen.dart         Email + password login
          signup_screen.dart        Name, email, password registration
          forgot_password_screen.dart  Password recovery flow
    home/
      presentation/
        screens/
          home_screen.dart          Tab shell for flights/hotels/cars
    flight_search/              (empty — phase 2)
    flight_results/             (empty — phase 2)
    booking/                    (empty — phase 3)
    payment/                    (empty — phase 3)
    hotels/                     (empty — phase 4)
    cars/                       (empty — phase 4)
    profile/
      presentation/
        screens/
          profile_screen.dart     User profile with logout
          settings_screen.dart    App settings (appearance, notifications, account)
    my_trips/                   (empty — phase 5)
  shared/
    widgets/
      primary_button.dart         Reusable primary button widget
```

Each feature follows the clean architecture pattern: `data/` (API + local models), `domain/` (entities, repository interfaces), `presentation/` (screens, BLoC).

## Auth Architecture

The app uses **cookie-based JWT authentication** matching the backend's approach:

1. User submits credentials on the login screen
2. `AuthBloc` dispatches `AuthLoginRequested`
3. `AuthRemoteDatasourceImpl` sends `POST /api/Auth/login` via Dio
4. Backend validates credentials against SQL Server, sets `auth_token` + `refresh_token` cookies
5. Dio's cookie interceptor automatically stores cookies from `Set-Cookie` response headers
6. On subsequent requests, cookies are automatically included in the `Cookie` request header
7. User profile is cached in `flutter_secure_storage` for persistence across app restarts
8. Splash screen checks for cached user data to determine initial route

## Handling API keys and secrets

Never commit real keys to source control. Configuration values are read at build time via `--dart-define` with safe empty/placeholder defaults in `app_constants.dart`.

Run with your real values:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:5193/api \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=PAYPAL_CLIENT_ID=xxx
```

Or use an env file:

```bash
flutter run --dart-define-from-file=env.json
```

Add `env.json` to `.gitignore`.

**Secret keys (Stripe secret key, Barclays merchant credentials) must never live in the app** — they belong on your backend. The app only holds *publishable*/*client* keys.

## Roadmap

- [x] Phase 1 — project setup, theme, navigation, auth integration with .NET backend
- [ ] Phase 2 — flight search + results + details
- [ ] Phase 3 — booking flow + payment integration (Stripe/Card/Barclays/PayPal)
- [ ] Phase 4 — hotels & cars modules
- [ ] Phase 5 — profile, trips history, push notifications
- [ ] Phase 6 — polish, testing, performance, store prep
