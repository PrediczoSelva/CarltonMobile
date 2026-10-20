import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/locale_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _languages = <Locale, String>{
    const Locale('en'): 'englishDefault',
    const Locale('fr'): 'french',
    const Locale('ar'): 'arabic',
  };

  Future<void> _selectLanguage() async {
    final localeNotifier = getIt<LocaleNotifier>();
    final l10n = AppLocalizations.of(context)!;
    final selectedLocale = await showDialog<Locale>(
      context: context,
      builder: (context) {
        var draftLocale = localeNotifier.value;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.language),
              content: DropdownButtonFormField<Locale>(
                initialValue: draftLocale,
                decoration: InputDecoration(
                  labelText: l10n.selectLanguage,
                ),
                items: _languages.entries
                    .map(
                      (entry) => DropdownMenuItem<Locale>(
                        value: entry.key,
                        child: Text(_languageName(l10n, entry.key)),
                      ),
                    )
                    .toList(),
                onChanged: (locale) {
                  if (locale != null) {
                    setDialogState(() => draftLocale = locale);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(draftLocale),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selectedLocale == null) return;

    localeNotifier.setLocale(selectedLocale);
    await getIt<FlutterSecureStorage>().write(
      key: 'language_code',
      value: selectedLocale.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguage = _languageName(l10n, getIt<LocaleNotifier>().value);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: l10n.appearance,
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: getIt<ThemeNotifier>(),
                builder: (context, themeMode, child) {
                  return SwitchListTile(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) async {
                      final themeNotifier = getIt<ThemeNotifier>();
                      themeNotifier.toggle(value);
                      final storage = getIt<FlutterSecureStorage>();
                      await storage.write(key: 'theme_mode', value: value ? 'dark' : 'light');
                    },
                    title: Text(l10n.darkMode),
                    subtitle: Text(l10n.useDarkTheme),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.language,
                title: l10n.language,
                subtitle: selectedLanguage,
                onTap: _selectLanguage,
              ),
              _SettingsTile(
                icon: Icons.attach_money,
                title: l10n.currency,
                subtitle: '£',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.notifications,
            children: [
              SwitchListTile(
                value: true,
                onChanged: (value) {},
                title: Text(l10n.pushNotifications),
                subtitle: Text(l10n.flightDealsAndBookingUpdates),
              ),
              SwitchListTile(
                value: true,
                onChanged: (value) {},
                title: Text(l10n.emailNotifications),
                subtitle: Text(l10n.receiptsAndETickets),
              ),
              SwitchListTile(
                value: false,
                onChanged: (value) {},
                title: Text(l10n.smsNotifications),
                subtitle: Text(l10n.paymentAndBookingAlerts),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.account,
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.delete_outline,
                title: l10n.deleteAccount,
                titleColor: AppColors.error,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.version('0.1.0'),
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _languageName(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return l10n.french;
      case 'ar':
        return l10n.arabic;
      default:
        return l10n.englishDefault;
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: titleColor ?? AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.bodySmall) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textSecondary) : null,
      onTap: onTap,
    );
  }
}
