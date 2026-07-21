# Carlton Leisure — Mobile Application

Phase 1 scaffold: project structure, theme, navigation skeleton, DI, and a
placeholder auth flow. Booking/payment/hotels/cars folders exist but are
empty — they get built out in later phases.

## Getting started

```bash
flutter pub get
flutter run
```

If a dependency version conflicts with your installed Flutter SDK, run
`flutter pub upgrade --major-versions` and re-check `pubspec.yaml`.

## Handling API keys and secrets (important)

Never commit real keys to source control. This scaffold reads them at build
time via `--dart-define`, with safe empty/placeholder defaults in
`lib/core/constants/app_constants.dart`.

Run with your real values like this:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://staging-api.carltonleisure.com/v1 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=PAYPAL_CLIENT_ID=xxx
```

For day-to-day dev, put these in a `--dart-define-from-file=env.json` file
(add `env.json` to `.gitignore`):

```json
{
  "API_BASE_URL": "https://staging-api.carltonleisure.com/v1",
  "STRIPE_PUBLISHABLE_KEY": "pk_test_xxx",
  "PAYPAL_CLIENT_ID": "xxx"
}
```

```bash
flutter run --dart-define-from-file=env.json
```

**Secret keys (Stripe secret key, Barclays merchant credentials) must never
live in the app at all** — they belong on your backend, which the app calls
over HTTPS. The app only ever holds *publishable*/*client* keys.

## Payment methods — what to expect from each

| Method | What lives in the app | What lives on the backend |
|---|---|---|
| Stripe | Publishable key, `flutter_stripe` SDK for card entry / Payment Sheet | Secret key, PaymentIntent creation, webhooks |
| Card payments (direct) | Tokenised card form only, never raw PAN storage | PCI-compliant processor integration |
| Barclays (ePDQ/Smartpay-style gateways) | Redirect/hosted-fields integration per their SDK docs | Merchant ID, shared secret, transaction API |
| PayPal | Client ID, `flutter_paypal_payment` or PayPal REST checkout flow | Client secret, order capture |

Once Carlton Leisure's backend/payments team confirms which Barclays
product they use (ePDQ, Smartpay, or Barclaycard Payments), we'll add the
specific SDK — Barclays doesn't have a single standard Flutter package, so
this is usually a WebView-based hosted checkout or a custom REST integration.

## Push notifications

Firebase Cloud Messaging is wired into `pubspec.yaml`
(`firebase_core`, `firebase_messaging`, `flutter_local_notifications`) but
not yet initialized in `main.dart` — that needs:

1. A Firebase project (ask if Carlton Leisure already has one, e.g. tied to
   the website's analytics stack, or we create a new one).
2. `flutterfire configure` run against that project to generate
   `firebase_options.dart`.
3. iOS: APNs key uploaded to Firebase console.
4. Then uncomment the `Firebase.initializeApp()` call in `main.dart`.

Good candidates for notifications: price drop alerts on saved searches,
booking confirmations, check-in reminders, flight status/gate changes.

## Project structure

```
lib/
  core/
    theme/       app_colors.dart, app_text_styles.dart, app_theme.dart
    constants/   app_constants.dart
    network/     api_client.dart (Dio + auth interceptor)
    di/          injection.dart (get_it service locator)
    router/      app_router.dart (go_router)
    utils/       validators, formatters (add as needed)
  features/
    auth/        splash + login screens (placeholder)
    home/        tab shell for flights/hotels/cars (placeholder)
    flight_search/    (empty — phase 2)
    flight_results/   (empty — phase 2)
    booking/          (empty — phase 3)
    payment/          (empty — phase 3)
    hotels/           (empty — phase 4)
    cars/             (empty — phase 4)
    profile/          (empty — phase 5)
    my_trips/         (empty — phase 5)
  shared/
    widgets/     primary_button.dart (add more as patterns emerge)
```

Each feature folder follows `data/` (API + local models),
`domain/` (entities, use cases), `presentation/` (screens, widgets, bloc).

## Roadmap

- [x] Phase 1 — project setup, theme, navigation skeleton, auth placeholder
- [x] Phase 2 — flight search + results + details
- [ ] Phase 3 — booking flow + payment integration (Stripe/Card/Barclays/PayPal)
- [ ] Phase 4 — hotels & cars modules
- [ ] Phase 5 — profile, trips history, push notifications
- [ ] Phase 6 — polish, testing, performance, store prep
