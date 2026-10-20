// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Carlton Leisure';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get useDarkTheme => 'Use dark theme across the app';

  @override
  String get language => 'Language';

  @override
  String get englishDefault => 'English (Default)';

  @override
  String get french => 'French';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get currency => 'Currency';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get flightDealsAndBookingUpdates => 'Flight deals and booking updates';

  @override
  String get emailNotifications => 'Email notifications';

  @override
  String get receiptsAndETickets => 'Receipts and e-tickets';

  @override
  String get smsNotifications => 'SMS notifications';

  @override
  String get paymentAndBookingAlerts => 'Payment and booking alerts';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change password';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String version(Object version) {
    return 'Version $version';
  }
}
