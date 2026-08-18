import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Appearance',
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
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use dark theme across the app'),
                  );
                },
              ),
              const _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: null,
              ),
              const _SettingsTile(
                icon: Icons.attach_money,
                title: 'Currency',
                subtitle: 'GBP',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                value: true,
                onChanged: (value) {},
                title: const Text('Push notifications'),
                subtitle: const Text('Flight deals and booking updates'),
              ),
              SwitchListTile(
                value: true,
                onChanged: (value) {},
                title: const Text('Email notifications'),
                subtitle: const Text('Receipts and e-tickets'),
              ),
              SwitchListTile(
                value: false,
                onChanged: (value) {},
                title: const Text('SMS notifications'),
                subtitle: const Text('Payment and booking alerts'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Account',
            children: [
              const _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: null,
              ),
              const _SettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete account',
                titleColor: AppColors.error,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Version 0.1.0',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
