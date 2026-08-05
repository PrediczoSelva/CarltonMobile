import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await setupDependencyInjection();

  try {
    final apiClient = getIt<ApiClient>();
    final response = await apiClient.get<dynamic>(AppConstants.paymentStripePublishableKey);
    final key = response.data is Map
        ? (response.data as Map)['publishableKey'] as String?
        : null;
    if (key != null && key.isNotEmpty) {
      Stripe.publishableKey = key;
      await Stripe.instance.applySettings();
    }
  } catch (_) {
    // Stripe will remain uninitialised; card payments will show an error until configured.
  }

  // TODO once Firebase project is created:
  // await Firebase.initializeApp();
  // await setupPushNotifications();

  runApp(const CarltonLeisureApp());
}

class CarltonLeisureApp extends StatelessWidget {
  const CarltonLeisureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Carlton Leisure',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
