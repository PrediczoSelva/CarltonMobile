import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Carlton Leisure'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme across the app'**
  String get useDarkTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @englishDefault.
  ///
  /// In en, this message translates to:
  /// **'English (Default)'**
  String get englishDefault;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @flightDealsAndBookingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Flight deals and booking updates'**
  String get flightDealsAndBookingUpdates;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get emailNotifications;

  /// No description provided for @receiptsAndETickets.
  ///
  /// In en, this message translates to:
  /// **'Receipts and e-tickets'**
  String get receiptsAndETickets;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications'**
  String get smsNotifications;

  /// No description provided for @paymentAndBookingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Payment and booking alerts'**
  String get paymentAndBookingAlerts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(Object version);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @noUserData.
  ///
  /// In en, this message translates to:
  /// **'No user data available'**
  String get noUserData;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @savedPreferences.
  ///
  /// In en, this message translates to:
  /// **'Saved preferences'**
  String get savedPreferences;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @leisurePlan.
  ///
  /// In en, this message translates to:
  /// **'Leisure Plan'**
  String get leisurePlan;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications at the moment.'**
  String get noNotifications;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToManageBookings.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your bookings'**
  String get signInToManageBookings;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseFillEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both email and password'**
  String get pleaseFillEmailPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @trendingDestinations.
  ///
  /// In en, this message translates to:
  /// **'Trending destinations'**
  String get trendingDestinations;

  /// No description provided for @promotionalUpdates.
  ///
  /// In en, this message translates to:
  /// **'Promotional updates'**
  String get promotionalUpdates;

  /// No description provided for @weatherAtYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Weather at your location'**
  String get weatherAtYourLocation;

  /// No description provided for @suggestedHotels.
  ///
  /// In en, this message translates to:
  /// **'Suggested hotels'**
  String get suggestedHotels;

  /// No description provided for @suggestedCars.
  ///
  /// In en, this message translates to:
  /// **'Suggested cars'**
  String get suggestedCars;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @availableFlights.
  ///
  /// In en, this message translates to:
  /// **'Available flights'**
  String get availableFlights;

  /// No description provided for @flightsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} flights'**
  String flightsCount(Object count);

  /// No description provided for @noFlightsFound.
  ///
  /// In en, this message translates to:
  /// **'No flights found'**
  String get noFlightsFound;

  /// No description provided for @modifySearch.
  ///
  /// In en, this message translates to:
  /// **'Modify search'**
  String get modifySearch;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round Trip'**
  String get roundTrip;

  /// No description provided for @oneWay.
  ///
  /// In en, this message translates to:
  /// **'One Way'**
  String get oneWay;

  /// No description provided for @multiCity.
  ///
  /// In en, this message translates to:
  /// **'Multi-City'**
  String get multiCity;

  /// No description provided for @flightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight {number}'**
  String flightNumber(Object number);

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @departureDate.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get departureDate;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return date'**
  String get returnDate;

  /// No description provided for @removeFlight.
  ///
  /// In en, this message translates to:
  /// **'Remove flight'**
  String get removeFlight;

  /// No description provided for @addAnotherFlight.
  ///
  /// In en, this message translates to:
  /// **'Add another flight'**
  String get addAnotherFlight;

  /// No description provided for @addNewTraveller.
  ///
  /// In en, this message translates to:
  /// **'Add New Traveller'**
  String get addNewTraveller;

  /// No description provided for @selectTraveller.
  ///
  /// In en, this message translates to:
  /// **'Select traveller'**
  String get selectTraveller;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @selectRelationship.
  ///
  /// In en, this message translates to:
  /// **'Select relationship'**
  String get selectRelationship;

  /// No description provided for @passengerType.
  ///
  /// In en, this message translates to:
  /// **'Passenger Type'**
  String get passengerType;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get selectType;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @passportDetails.
  ///
  /// In en, this message translates to:
  /// **'Passport Details'**
  String get passportDetails;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get passportNumber;

  /// No description provided for @issueNumber.
  ///
  /// In en, this message translates to:
  /// **'Issue Number'**
  String get issueNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @optionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional Details'**
  String get optionalDetails;

  /// No description provided for @frequencyFlyerNumber.
  ///
  /// In en, this message translates to:
  /// **'Frequent Flyer No'**
  String get frequencyFlyerNumber;

  /// No description provided for @knownTravellerNumber.
  ///
  /// In en, this message translates to:
  /// **'Known Traveller No'**
  String get knownTravellerNumber;

  /// No description provided for @specialRequirement.
  ///
  /// In en, this message translates to:
  /// **'Special Requirement'**
  String get specialRequirement;

  /// No description provided for @addPassenger.
  ///
  /// In en, this message translates to:
  /// **'Add passenger'**
  String get addPassenger;

  /// No description provided for @cabinClass.
  ///
  /// In en, this message translates to:
  /// **'Cabin Class'**
  String get cabinClass;

  /// No description provided for @economy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get economy;

  /// No description provided for @premiumEconomy.
  ///
  /// In en, this message translates to:
  /// **'Premium Economy'**
  String get premiumEconomy;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get first;

  /// No description provided for @noFlightsForSearch.
  ///
  /// In en, this message translates to:
  /// **'No flights found for your search.'**
  String get noFlightsForSearch;

  /// No description provided for @pleaseCompleteCityPair.
  ///
  /// In en, this message translates to:
  /// **'Please complete every city pair'**
  String get pleaseCompleteCityPair;

  /// No description provided for @pleaseFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get pleaseFillRequired;

  /// No description provided for @pleaseSelectReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a return date'**
  String get pleaseSelectReturnDate;

  /// No description provided for @enterLocationWeather.
  ///
  /// In en, this message translates to:
  /// **'Enter a location to check the weather'**
  String get enterLocationWeather;

  /// No description provided for @forecastUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not find a forecast for \"{place}\"'**
  String forecastUnavailable(Object place);

  /// No description provided for @hotelResults.
  ///
  /// In en, this message translates to:
  /// **'Hotel results'**
  String get hotelResults;

  /// No description provided for @carResults.
  ///
  /// In en, this message translates to:
  /// **'Car results'**
  String get carResults;

  /// No description provided for @cruiseResults.
  ///
  /// In en, this message translates to:
  /// **'Cruise results'**
  String get cruiseResults;

  /// No description provided for @itemsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String itemsFound(Object count);

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @priceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get priceLowHigh;

  /// No description provided for @priceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get priceHighLow;

  /// No description provided for @lowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get lowestPrice;

  /// No description provided for @highestPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get highestPrice;

  /// No description provided for @guestRating.
  ///
  /// In en, this message translates to:
  /// **'Guest rating'**
  String get guestRating;

  /// No description provided for @bestRated.
  ///
  /// In en, this message translates to:
  /// **'Best rated'**
  String get bestRated;

  /// No description provided for @freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get freeCancellation;

  /// No description provided for @fourPlusStars.
  ///
  /// In en, this message translates to:
  /// **'4+ stars'**
  String get fourPlusStars;

  /// No description provided for @allInclusive.
  ///
  /// In en, this message translates to:
  /// **'All-inclusive'**
  String get allInclusive;

  /// No description provided for @noHotelsFound.
  ///
  /// In en, this message translates to:
  /// **'No hotels found'**
  String get noHotelsFound;

  /// No description provided for @noCarsFound.
  ///
  /// In en, this message translates to:
  /// **'No cars found'**
  String get noCarsFound;

  /// No description provided for @noCruisesFound.
  ///
  /// In en, this message translates to:
  /// **'No cruises found'**
  String get noCruisesFound;

  /// No description provided for @tryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing your dates or filters.'**
  String get tryChangingFilters;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @viewCabinsDetails.
  ///
  /// In en, this message translates to:
  /// **'View cabins & details'**
  String get viewCabinsDetails;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @modifySearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Modify search'**
  String get modifySearchTooltip;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @searchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search flights'**
  String get searchFlights;

  /// No description provided for @suggestedFlights.
  ///
  /// In en, this message translates to:
  /// **'Suggested flights'**
  String get suggestedFlights;

  /// No description provided for @suggestedCruises.
  ///
  /// In en, this message translates to:
  /// **'Suggested cruises'**
  String get suggestedCruises;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get bookingSummary;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @passengerDetails.
  ///
  /// In en, this message translates to:
  /// **'Passenger details'**
  String get passengerDetails;

  /// No description provided for @chooseServicePack.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Service Pack'**
  String get chooseServicePack;

  /// No description provided for @myWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWalletTitle;

  /// No description provided for @topUpWallet.
  ///
  /// In en, this message translates to:
  /// **'Top Up Wallet'**
  String get topUpWallet;

  /// No description provided for @redeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get redeemPoints;

  /// No description provided for @checkWeather.
  ///
  /// In en, this message translates to:
  /// **'Check weather'**
  String get checkWeather;

  /// No description provided for @weatherLookupDescription.
  ///
  /// In en, this message translates to:
  /// **'Look up the forecast for any destination before you book.'**
  String get weatherLookupDescription;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
