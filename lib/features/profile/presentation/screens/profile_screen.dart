import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            child: Text(
              'JD',
              style: AppTextStyles.h2.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Text('John Doe', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('john.doe@example.com', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _ProfileTile(icon: Icons.person_outline, label: 'Personal details', onTap: () => context.push('/profile/personal-details')),
          _ProfileTile(icon: Icons.favorite_border, label: 'Saved preferences', onTap: () {}),
          _ProfileTile(icon: Icons.card_giftcard_outlined, label: 'My trips', onTap: () {}),
          _ProfileTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/profile/settings')),
          _ProfileTile(icon: Icons.help_outline, label: 'Help & support', onTap: () {}),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
