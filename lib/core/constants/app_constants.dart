class AppConstants {
  AppConstants._();

  static const String appName = 'Carlton Leisure';

  // TODO: replace with real values once the client provides API access.
  // Keep actual keys out of source control - load via --dart-define or
  // a .env file that is gitignored. See README for setup.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5193/api',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String paypalClientId = String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: '',
  );

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  // Hive box names
  static const String boxRecentSearches = 'recent_searches';
  static const String boxUserPrefs = 'user_prefs';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Payment endpoints
  static const String paymentCreateFlightIntent = '/payment/create-flight-payment-intent';
  static const String paymentStripePublishableKey = '/payment/stripe-publishable-key';
}
