// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Carlton Leisure';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get useDarkTheme => 'استخدام المظهر الداكن في جميع أنحاء التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get englishDefault => 'الإنجليزية (افتراضي)';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get currency => 'العملة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get pushNotifications => 'الإشعارات الفورية';

  @override
  String get flightDealsAndBookingUpdates => 'عروض الرحلات وتحديثات الحجوزات';

  @override
  String get emailNotifications => 'إشعارات البريد الإلكتروني';

  @override
  String get receiptsAndETickets => 'الإيصالات والتذاكر الإلكترونية';

  @override
  String get smsNotifications => 'إشعارات الرسائل النصية';

  @override
  String get paymentAndBookingAlerts => 'تنبيهات الدفع والحجوزات';

  @override
  String get account => 'الحساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String version(Object version) {
    return 'الإصدار $version';
  }
}
