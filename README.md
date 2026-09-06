# Carlton Leisure — Mobile Application

Flutter mobile app for Carlton Leisure flight, hotel, car, and cruise booking. It integrates with the existing .NET backend via cookie-based JWT authentication and supports a multi-step booking flow with Stripe, PayPal, Barclays Card, and wallet payments. Flight search, booking, payment, wallet, and profile features are all implemented.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State management | flutter_bloc + equatable |
| Navigation | go_router (ShellRoute + nested routes) |
| Dependency injection | get_it (manual registration, no code-gen) |
| HTTP client | Dio with custom cookie interceptor |
| Session management | In-memory cookie jar + flutter_secure_storage |
| Local storage | Hive (box caching) + flutter_secure_storage (user data cache) |
| Serialization | Manual `fromJson`/`toJson` |
| Forms & validation | flutter_form_builder + form_builder_validators |
| UI | Flutter Material 3, Google Fonts (Inter), custom theme (light/dark) |
| Internationalisation | intl (date formatting) |
| Caching / images | cached_network_image, shimmer, flutter_svg |
| Payments | flutter_stripe, flutter_paypal_payment, webview_flutter |
| Push notifications | firebase_core, firebase_messaging, flutter_local_notifications |
| PDF & file handling | pdf, path_provider, open_filex |

## Backend

| Layer | Technology |
|-------|-----------|
| Framework | .NET 10 (ASP.NET Core Web API) |
| Database | SQL Server |
| Auth | JWT via HTTP-only cookies |
| CORS | AllowFrontend policy |

The backend repository lives at your workstation under the Carlton backend directory, e.g.:
```
/Users/sajaniprabhashika/Documents/Onedata 4/Carlton/backend/Carlton.CustomerSelfService
```

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

All endpoints are relative to the `API_BASE_URL` (default `http://10.0.2.2:5193/api`).

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/Auth/login` | User login (sets auth + refresh cookies) |
| POST | `/api/Auth/register` | Self-service registration |
| POST | `/api/Auth/refresh` | Refresh auth cookies |
| POST | `/api/Auth/logout` | Clear auth cookies |

### Flights

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/flights/search/all` | Search flights (body: `from`, `to`, `date`, `adults`, `tripType`, `cabinClass`) |
| GET | `/api/flights` | Get all catalog flights |
| GET | `/api/flights/{id}` | Get flight by ID |

### Bookings

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/bookings` | Create booking (authenticated) |
| POST | `/api/bookings/guest` | Create booking (guest) |
| GET | `/api/bookings` | Get user bookings |
| GET | `/api/bookings/{id}` | Get booking by ID |
| DELETE | `/api/bookings/{id}` | Cancel booking |
| PUT | `/api/bookings/{id}/finalize-payment` | Finalize payment for a booking |
| GET | `/api/bookings/{id}/e-ticket-status` | Check e-ticket status |
| GET | `/api/bookings/{id}/e-ticket` | Download e-ticket |

### Travel Providers (integrated via bookings)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/bookings/atlas/verify` | Verify Atlas offer |
| POST | `/api/bookings/atlas/book` | Book via Atlas (authenticated) |
| POST | `/api/bookings/atlas/guest/book` | Book via Atlas (guest) |
| POST | `/api/bookings/amadeus/verify` | Verify Amadeus offer |
| POST | `/api/bookings/amadeus/book` | Book via Amadeus (authenticated) |
| POST | `/api/bookings/amadeus/guest/book` | Book via Amadeus (guest) |
| POST | `/api/travelport/verify` | Verify Travelport fare |
| POST | `/api/travelport/book` | Book via Travelport (authenticated) |
| POST | `/api/travelport/guest/book` | Book via Travelport (guest) |

### Payments

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payment/create-flight-payment-intent` | Create Stripe payment intent for a flight booking |
| GET | `/api/payment/stripe-publishable-key` | Fetch Stripe publishable key at runtime |

### Wallet & Loyalty

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/wallet/summary` | Get wallet balance + loyalty points |
| GET | `/api/wallet/transactions` | Get transaction history |
| POST | `/api/wallet/topup/payment-intent` | Create top-up payment intent |
| POST | `/api/wallet/topup/confirm` | Confirm top-up |
| GET | `/api/loyalty/config` | Get loyalty redemption config |
| POST | `/api/wallet/redeem` | Redeem loyalty points |

---

## Project Structure

```
lib/
  main.dart                            App entry point, Stripe init, theme setup
  core/
    network/
      api_client.dart                  Dio client with cookie interceptor + logging
    constants/
      app_constants.dart               API base URL, timeouts, storage keys, endpoints
    di/
      injection.dart                   get_it service locator + DI setup
    router/
      app_router.dart                  go_router configuration (shell + nested routes)
    theme/
      app_theme.dart                   Light/dark ThemeData
      app_colors.dart                  Brand palette (blue primary, yellow accent)
      app_text_styles.dart             Typography (Google Fonts Inter)
      theme_notifier.dart              ThemeMode ValueNotifier for runtime switching
    utils/
      country_code_mapper.dart         Country code ↔ dial code mapping
  features/
    auth/
      data/
        models/                        LoginRequest, RegisterRequest, LoginResponse, UserModel
        datasources/
          auth_remote_datasource.dart           Abstract auth API interface
          auth_remote_datasource_impl.dart      Dio-based auth API implementation
        repositories/
          auth_repository_impl.dart             Auth repo implementation
      domain/
        entities/
          user.dart                             User domain entity
        repositories/
          auth_repository.dart                  Abstract auth repo interface
      presentation/
        bloc/
          auth_bloc.dart                        Auth BLoC (login, register, logout, session check)
          auth_event.dart                       Auth events
          auth_state.dart                       Auth states
        screens/
          splash_screen.dart                    Splash → checks session → routes to login/home
          login_screen.dart                     Email + password login
          signup_screen.dart                    Name, email, password, phone, DOB, nationality
          forgot_password_screen.dart           Password recovery flow
    home/
      presentation/
        screens/
          home_screen.dart                     Tab shell (Flights/Hotels/Cars/Cruise) with search + suggestions
          messages_screen.dart                 Messaging inbox
          notifications_screen.dart           Notifications feed
    flight/
      domain/
        entities/
          flight.dart                           Flight model with multi-provider JSON parsing
          flight_search_criteria.dart           Search criteria (origin, destination, dates, passengers)
        repositories/
          flight_repository.dart                Abstract flight repo interface
      data/
        datasources/
          flight_remote_datasource.dart         Abstract flight API interface
          flight_remote_datasource_impl.dart    Dio-based flight API (with 5-min cache)
        repositories/
          flight_repository_impl.dart           Flight repo implementation
      presentation/
        bloc/
          flight_bloc.dart                      FlightSearchBloc
          flight_event.dart
          flight_state.dart
        screens/
          flight_search_screen.dart             Flight search form
          flight_results_screen.dart            Flight results list + selection
    booking/
      domain/
        entities/
          booking.dart                          Booking + flight + passengers
          booking_session.dart                  Shared session singleton across booking flow
          passenger.dart                        Passenger with passport/travel details
        repositories/
          booking_repository.dart               Abstract booking repo (Atlas, Amadeus, Travelport)
      data/
        datasources/
          booking_remote_datasource.dart        Abstract booking API interface
          booking_remote_datasource_impl.dart   Dio-based booking API (3 providers)
        models/                                 BookingModel, BookingRequest, verify responses, e-ticket
        repositories/
          booking_repository_impl.dart          Booking repo implementation
      presentation/
        bloc/
          booking_bloc.dart                     Booking BLoC (create, list, cancel, 3 providers)
          booking_event.dart
          booking_state.dart
        screens/
          passenger_details_screen.dart         Passenger info entry
          booking_summary_screen.dart           Review flight + price before payment
          service_pack_selection_screen.dart    Ancillary service packs
          payment_method_selection_screen.dart  Choose payment method
          card_payment_screen.dart              Credit/debit card payment
          wallet_payment_screen.dart            Pay from wallet balance
          paypal_payment_screen.dart            PayPal checkout
          barclays_payment_screen.dart          Barclays card payment
          payment_processing_screen.dart        Payment processing status
          booking_confirmation_screen.dart      Booking confirmation + e-ticket
        utils/
          e_ticket_pdf_generator.dart           E-ticket PDF generation
    payment/
      domain/
        entities/
          payment_intent.dart                   Stripe payment intent wrapper
        repositories/
          payment_repository.dart               Abstract payment repo interface
      data/
        datasources/
          payment_remote_datasource.dart          Abstract payment API interface
          payment_remote_datasource_impl.dart     Dio-based payment API
        repositories/
          payment_repository_impl.dart            Payment repo implementation
    wallet/
      domain/
        entities/
          wallet_balance.dart                   Balance + loyalty points + tier
          wallet_transaction.dart               Transaction with type enum
        repositories/
          wallet_repository.dart                Abstract wallet repo interface
      data/
        datasources/
          wallet_remote_datasource.dart           Abstract wallet API interface
          wallet_remote_datasource_impl.dart      Dio-based wallet API
        models/                                 WalletBalanceModel, WalletTransactionModel
        repositories/
          wallet_repository_impl.dart            Wallet repo implementation
      presentation/
        bloc/
          wallet_bloc.dart                      Wallet BLoC
          wallet_event.dart
          wallet_state.dart
        screens/
          wallet_screen.dart                    Wallet balance + transactions
          top_up_screen.dart                    Top up wallet via Stripe
          top_up_modal.dart                     Top up modal sheet
          redeem_screen.dart                    Loyalty points redemption
    my_trips/
      presentation/
        screens/
          my_trips_screen.dart                  User's booked trips history
    profile/
      presentation/
        screens/
          profile_screen.dart                  User profile overview
          personal_details_screen.dart         Edit personal info
          settings_screen.dart                 Appearance, notifications, account
  shared/
    widgets/
      primary_button.dart                       Reusable primary button widget
```

Each feature follows the clean architecture pattern: `data/` (API models, datasources, repository implementations), `domain/` (entities, repository interfaces), `presentation/` (screens, BLoC).

## Navigation

The app uses `go_router` with a `ShellRoute` that wraps the main tabs (Home, Search, Bookings, My Account) in a `MainShell` with a `BottomNavigationBar`. Auth screens (splash, login, signup, forgot password) are top-level routes. The booking flow uses a shared `BookingSession` singleton to pass data across screens:

```
Flight Search → Flight Results → Passenger Details → Booking Summary
  → Service Pack → Payment Method → [Card | Wallet | PayPal | Barclays]
  → Payment Processing → Booking Confirmation
```

Profile screen nests child routes: `/profile/personal-details`, `/profile/settings`, `/profile/wallet`.

## Auth Architecture

The app uses **cookie-based JWT authentication** matching the backend's approach:

1. User submits credentials on the login screen
2. `AuthBloc` dispatches `AuthLoginRequested`
3. `AuthRemoteDatasourceImpl` sends `POST /api/Auth/login` via Dio
4. Backend validates credentials against SQL Server, sets auth + refresh token cookies
5. `ApiClient`'s custom cookie interceptor automatically captures cookies from `Set-Cookie` response headers into an in-memory cookie jar
6. On subsequent requests, cookies are automatically attached to the `Cookie` request header
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

---

## Roadmap

- [x] Phase 1 — project setup, theme, navigation, auth integration with .NET backend
- [x] Phase 2 — flight search + results + details
- [x] Phase 3 — booking flow + payment integration (Stripe, Card, PayPal, Barclays, Wallet)
- [x] Phase 4 — wallet & loyalty module
- [x] Phase 5 — my trips, profile, personal details, settings, messages, notifications
- [ ] Phase 6 — hotels & cars modules (UI placeholders present, backend pending)
- [ ] Phase 7 — polish, testing, performance, store prep