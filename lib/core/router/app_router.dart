import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/flight/presentation/screens/flight_search_screen.dart';
import '../../features/flight/presentation/screens/flight_results_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const profile = '/profile';
  static const personalDetails = '/profile/personal-details';
  static const flightSearch = '/flights/search';
  static const flightResults = '/flights/results';

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
  ],
);
