import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';

  // Add as each feature is built:
  // static const flightSearch = '/flights/search';
  // static const flightResults = '/flights/results';
  // static const flightDetails = '/flights/details/:id';
  // static const booking = '/booking';
  // static const payment = '/payment';
  // static const bookingConfirmation = '/booking/confirmation';
  // static const myTrips = '/my-trips';
  // static const profile = '/profile';
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
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
