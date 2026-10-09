# Carlton Leisure Mobile App

Flutter application for Carlton Leisure customer self-service. The app provides
authentication, flight search and booking, payments, wallet and loyalty,
bookings/trips, profile settings, and weather forecasts for travel locations.
Hotel and car screens are currently UI placeholders; their backend integrations
are not included in this repository.

The checked-in native project is Android. The app also contains Flutter code
that can be used with other Flutter targets after their platform projects and
native payment/notification configuration have been added.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart), tested with Flutter 3.44.7 / Dart 3.12.2 |
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

## Backend integration

| Layer | Technology |
|-------|-----------|
| Framework | .NET 10 (ASP.NET Core Web API) |
| Database | SQL Server |
| Auth | JWT via HTTP-only cookies |
| CORS | AllowFrontend policy |

The app expects the Carlton ASP.NET Core API to be running separately. The API
base URL is supplied at build time; it is not hard-coded to a production
service. Authentication uses JWTs transported in HTTP-only cookies, so the API
must allow requests from the selected client and support cookie credentials.

---

## Prerequisites

- Flutter SDK (3.3.0 or later; Flutter 3.44.7 is used for this project)
- Dart SDK (bundled with Flutter)
- Android Studio with the Android SDK and an emulator, or a physical Android
  device
- Java 21 (the Android Gradle configuration uses Java 21)
- .NET 10 SDK and SQL Server if running the backend locally

Check the local toolchain before starting:

```bash
flutter doctor
flutter devices
```

## Setup and launch

From the repository root:

```bash
flutter pub get
```

### Start the backend (required for login and booking)

Start the Carlton backend using the backend repository's documented command.
For example, from the ASP.NET Core project directory:

```bash
dotnet run
```

Use the URL printed by `dotnet run`. The examples below assume the API is
listening on `http://localhost:5193`.

### Launch on an Android emulator

List available emulators and launch one if necessary:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

The Android emulator reaches services running on the development machine via
`10.0.2.2`, not `localhost`. Start the app with:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5193/api
```

If more than one device is connected, specify the device:

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:5193/api
```

### Launch on a physical Android device

Enable Developer options and USB debugging, connect the device, then confirm
that Flutter detects it:

```bash
flutter devices
flutter run -d <android-device-id> \
  --dart-define=API_BASE_URL=http://<computer-ip>:5193/api
```

The phone and computer must be on the same network, and the backend/firewall
must allow connections from the phone. Do not use `10.0.2.2` on a physical
device.

### Run with payment configuration

Only publishable/client-side values belong in the app. Keep secret payment
credentials on the backend:

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:5193/api \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=PAYPAL_CLIENT_ID=xxx
```

Alternatively, create a local, untracked `env.json` and run:

```json
{
  "API_BASE_URL": "http://10.0.2.2:5193/api",
  "STRIPE_PUBLISHABLE_KEY": "pk_test_xxx",
  "PAYPAL_CLIENT_ID": "xxx"
}
```

```bash
flutter run -d <device-id> --dart-define-from-file=env.json
```

Add `env.json` to `.gitignore` before putting real values in it. The app
defaults to `http://10.0.2.2:5193/api`, so Android emulator development also
works with just `flutter run` when the backend uses that port.

### Test credentials

Use the seeded or provisioned credentials supplied by the backend environment.
Credentials are intentionally not documented here because they are environment
data and may differ between databases.

## Development commands

```bash
# Static analysis
flutter analyze

# Unit and integration tests
flutter test

# Live Open-Meteo integration tests only
flutter test test/weather_open_meteo_test.dart

# Generate a debug APK
flutter build apk --debug
```

The weather integration tests call the live Open-Meteo service and require
network access. The application itself uses Open-Meteo without an API key;
retain the required Open-Meteo attribution when exposing weather functionality.

## Troubleshooting

- **No device found:** run `flutter devices`, start an Android emulator with
  `flutter emulators --launch <id>`, or enable USB debugging on a phone.
- **API connection refused on an emulator:** use `10.0.2.2` instead of
  `localhost` and confirm the backend is listening on port `5193`.
- **API connection refused on a phone:** use the computer's LAN IP and verify
  both devices are on the same network.
- **Gradle/Java errors:** verify that Java 21 is selected by Android Studio or
  set it with `flutter config --jdk-dir=<path-to-jdk-21>`.
- **Payment setup errors:** provide only publishable Stripe and client-side
  PayPal values through `--dart-define`; payment secret keys must remain on the
  backend.
- **iOS/macOS plugin errors:** CocoaPods and checked-in iOS/macOS platform
  projects are not part of this repository. Android is the supported native
  target until those projects are added and configured.

---

## API Endpoints

The table uses the backend's full route notation (`/api/...`). The app's
`API_BASE_URL` already includes the `/api` prefix, so datasource paths append
routes such as `/Auth/login` and `/flights/search/all`.

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

Never commit real keys to source control. Configuration is read at build time
via `--dart-define`; see [Run with payment configuration](#run-with-payment-configuration)
for the command-line and `env.json` examples. Secret keys (Stripe secret key
and Barclays merchant credentials) must remain on the backend; the app only
holds publishable/client-side values.

---

## Roadmap

- [x] Phase 1 — project setup, theme, navigation, auth integration with .NET backend
- [x] Phase 2 — flight search + results + details
- [x] Phase 3 — booking flow + payment integration (Stripe, Card, PayPal, Barclays, Wallet)
- [x] Phase 4 — wallet & loyalty module
- [x] Phase 5 — my trips, profile, personal details, settings, messages, notifications
- [ ] Phase 6 — hotels & cars modules (UI placeholders present, backend pending)
- [ ] Phase 7 — polish, testing, performance, store prep