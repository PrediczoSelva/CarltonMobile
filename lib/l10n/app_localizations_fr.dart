// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Carlton Leisure';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get useDarkTheme =>
      'Utiliser le thème sombre dans toute l’application';

  @override
  String get language => 'Langue';

  @override
  String get englishDefault => 'Anglais (par défaut)';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'Arabe';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get currency => 'Devise';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get flightDealsAndBookingUpdates =>
      'Offres de vols et mises à jour des réservations';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get receiptsAndETickets => 'Reçus et billets électroniques';

  @override
  String get smsNotifications => 'Notifications SMS';

  @override
  String get paymentAndBookingAlerts => 'Alertes de paiement et de réservation';

  @override
  String get account => 'Compte';

  @override
  String get changePassword => 'Modifier le mot de passe';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String version(Object version) {
    return 'Version $version';
  }
}
