import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfile(context, state.user);
          }
          return const Center(child: Text('No user data available'));
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserEntity user) {
    final initials = _getInitials(user.name);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          child: Text(
            initials,
            style: AppTextStyles.h2.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.name, style: AppTextStyles.h3, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(user.username, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(user.role, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _ProfileTile(icon: Icons.person_outline, label: 'Personal details', onTap: () => context.push('/profile/personal-details')),
        _ProfileTile(icon: Icons.favorite_border, label: 'Saved preferences', onTap: () {}),
        _ProfileTile(icon: Icons.card_giftcard_outlined, label: 'My trips', onTap: () {}),
        _ProfileTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/profile/settings')),
        _ProfileTile(icon: Icons.help_outline, label: 'Help & support', onTap: () {}),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
            context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
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
