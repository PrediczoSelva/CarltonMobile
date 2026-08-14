import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MessageTile(
            avatar: 'CL',
            title: 'Carlton Leisure',
            subtitle: 'Your booking is confirmed. Have a great trip!',
            time: '2h',
          ),
          _MessageTile(
            avatar: 'FL',
            title: 'Flight Updates',
            subtitle: 'Your flight CX-453 has been delayed by 30 minutes.',
            time: '5h',
          ),
          _MessageTile(
            avatar: 'HT',
            title: 'Hotel Team',
            subtitle: 'Thank you for choosing Shangri-La Colombo.',
            time: '1d',
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String avatar;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(avatar, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnPrimary)),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: Text(time, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}
