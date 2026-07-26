import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/booking_summary_screen.dart';
import '../../features/booking/presentation/screens/card_payment_screen.dart';
import '../../features/booking/presentation/screens/payment_method_selection_screen.dart';
import '../../features/booking/presentation/screens/payment_processing_screen.dart';
import '../../features/booking/presentation/screens/passenger_details_screen.dart';
import '../../features/flight/presentation/screens/flight_search_screen.dart';
import '../../features/flight/presentation/screens/flight_results_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const signup = '/signup';
  static const home = '/home';
  static const profile = '/profile';
  static const personalDetails = '/profile/personal-details';
  static const settings = '/profile/settings';
  static const flightSearch = '/flights/search';
  static const flightResults = '/flights/results';
  static const passengerDetails = '/booking/passenger-details';
  static const bookingSummary = '/booking/summary';
  static const paymentMethodSelection = '/booking/payment-method';
  static const cardPayment = '/booking/payment/card';
  static const paymentProcessing = '/booking/payment/process';
  static const bookingConfirmation = '/booking/confirmation';

  // Add as each feature is built:
  // static const flightSearch = '/flights/search';
  // static const flightResults = '/flights/results';
  // static const flightDetails = '/flights/details/:id';
  // static const booking = '/booking';
  // static const payment = '/payment';
  // static const bookingConfirmation = '/booking/confirmation';
  // static const myTrips = '/my-trips';
  // static const profileSettings = '/profile/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.personalDetails,
      builder: (context, state) => const PersonalDetailsScreen(),
    ),
    GoRoute(
      path: AppRoutes.flightSearch,
      builder: (context, state) => const FlightSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.flightResults,
      builder: (context, state) => const FlightResultsScreen(),
    ),
    GoRoute(
      path: AppRoutes.passengerDetails,
      builder: (context, state) => const PassengerDetailsScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookingSummary,
      builder: (context, state) => const BookingSummaryScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentMethodSelection,
      builder: (context, state) => const PaymentMethodSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.cardPayment,
      builder: (context, state) => const CardPaymentScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentProcessing,
      builder: (context, state) => const PaymentProcessingScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookingConfirmation,
      builder: (context, state) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
