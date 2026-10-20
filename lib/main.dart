import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/localization/locale_notifier.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/theme_notifier.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await setupDependencyInjection();

  try {
    final apiClient = getIt<ApiClient>();
    final response =
        await apiClient.get<dynamic>(AppConstants.paymentStripePublishableKey);
    final key = response.data is Map
        ? (response.data as Map)['publishableKey'] as String?
        : null;
    final publishableKey =
        key?.isNotEmpty == true ? key! : AppConstants.stripePublishableKey;

    if (publishableKey.isNotEmpty) {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    }
  } catch (_) {
    if (AppConstants.stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      await Stripe.instance.applySettings();
    }
  }

  // TODO once Firebase project is created:
  // await Firebase.initializeApp();
  // await setupPushNotifications();

  final themeNotifier = getIt<ThemeNotifier>();
  final localeNotifier = getIt<LocaleNotifier>();
  final storage = getIt<FlutterSecureStorage>();
  final savedTheme = await storage.read(key: 'theme_mode');
  final savedLanguage = await storage.read(key: 'language_code');
  final isDark = savedTheme == 'dark';
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  if (savedLanguage == 'fr' || savedLanguage == 'ar') {
    localeNotifier.value = Locale(savedLanguage!);
  }
  AppTextStyles.setDarkMode(isDark);

  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, child) {
            return CarltonLeisureApp(
              themeMode: themeMode,
              locale: locale,
            );
          },
        );
      },
    ),
  );
}

class CarltonLeisureApp extends StatelessWidget {
  final ThemeMode themeMode;
  final Locale locale;

  const CarltonLeisureApp({
    super.key,
    required this.themeMode,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: appRouter,
      ),
    );
  }
}
