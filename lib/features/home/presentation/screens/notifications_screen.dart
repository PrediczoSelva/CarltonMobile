import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationTile(
            icon: Icons.flight_takeoff,
            title: 'Flight departure reminder',
            subtitle: 'Your flight to London departs tomorrow at 10:30 AM.',
            time: '2h',
          ),
          _NotificationTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Booking confirmed',
            subtitle: 'Your hotel booking at Cinnamon Grand is confirmed.',
            time: '1d',
          ),
          _NotificationTile(
            icon: Icons.local_offer_outlined,
            title: 'Special offer',
            subtitle: 'Get 20% off on your next flight booking.',
            time: '2d',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: Text(time, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}
