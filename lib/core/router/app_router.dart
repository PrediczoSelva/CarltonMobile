import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/booking_summary_screen.dart';
import '../../features/booking/presentation/screens/service_pack_selection_screen.dart';
import '../../features/booking/presentation/screens/card_payment_screen.dart';
import '../../features/booking/presentation/screens/payment_method_selection_screen.dart';
import '../../features/booking/presentation/screens/payment_processing_screen.dart';
import '../../features/booking/presentation/screens/passenger_details_screen.dart';
import '../../features/flight/presentation/bloc/flight_bloc.dart';
import '../../features/flight/presentation/screens/flight_results_screen.dart';
import '../../features/flight/presentation/screens/flight_search_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/my_trips/presentation/screens/my_trips_screen.dart';
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
  static const servicePackSelection = '/booking/service-pack';
  static const paymentMethodSelection = '/booking/payment-method';
  static const cardPayment = '/booking/payment/card';
  static const paymentProcessing = '/booking/payment/process';
  static const bookingConfirmation = '/booking/confirmation';
  static const myTrips = '/my-trips';
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
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.flightSearch,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<FlightSearchBloc>(),
            child: const FlightSearchScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.flightResults,
          builder: (context, state) => const FlightResultsScreen(),
        ),
        GoRoute(
          path: AppRoutes.myTrips,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<BookingBloc>(),
            child: const MyTripsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: AppRoutes.personalDetails,
              builder: (context, state) => const PersonalDetailsScreen(),
            ),
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
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
          path: AppRoutes.servicePackSelection,
          builder: (context, state) => const ServicePackSelectionScreen(),
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
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<BookingBloc>(),
            child: const PaymentProcessingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookingConfirmation,
          builder: (context, state) => const BookingConfirmationScreen(),
        ),
      ],
    ),
  ],
);

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.bookmark_outline, label: 'Bookings'),
    _NavItem(icon: Icons.person_outline, label: 'My account'),
  ];

  static const _routes = [
    AppRoutes.home,
    AppRoutes.flightSearch,
    AppRoutes.myTrips,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    _syncIndexFromRoute(GoRouterState.of(context).uri.toString());
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          GoRouter.of(context).go(_routes[index]);
        },
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  void _syncIndexFromRoute(String route) {
    for (var i = 0; i < _routes.length; i++) {
      if (route == _routes[i] || route.startsWith(_routes[i])) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        return;
      }
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
