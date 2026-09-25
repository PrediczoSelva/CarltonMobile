import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/domain/entities/schedule_change.dart';
import '../../../booking/domain/repositories/booking_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ScheduleChangeNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final repo = getIt<BookingRepository>();
      final changes = await repo.getScheduleChanges();

      final bookings = await repo.getUserBookings();
      final bookingMap = {for (final b in bookings) b.id: b};

      final notifications = changes.map((change) {
        final booking = bookingMap[change.bookingId];
        return ScheduleChangeNotification(
          change: change,
          booking: booking,
        );
      }).toList();

      // --- MOCK DATA: Simulate a schedule change notification for preview ---
      // Remove this block when the real API is available.
      if (notifications.isEmpty && bookings.isNotEmpty) {
        final mockBooking = bookings.firstWhere(
          (b) => !b.status.toLowerCase().contains('cancel'),
          orElse: () => bookings.first,
        );
        notifications.add(ScheduleChangeNotification(
          change: ScheduleChange(
            bookingId: mockBooking.id,
            pnr: mockBooking.pnr,
            reason: 'Flight delayed due to bad weather',
            originalDepartureTime: mockBooking.flight.departureTime,
            originalArrivalTime: mockBooking.flight.arrivalTime,
            newDepartureTime:
                mockBooking.flight.departureTime.add(const Duration(hours: 3)),
            newArrivalTime:
                mockBooking.flight.arrivalTime.add(const Duration(hours: 3)),
            newFlightCode: mockBooking.flight.flightCode,
            newAirline: mockBooking.flight.airline,
            oldFlightCode: mockBooking.flight.flightCode,
            oldAirline: mockBooking.flight.airline,
            priceChange: 0.0,
            currency: 'GBP',
            message: '',
            createdAt: DateTime.now(),
            accepted: false,
          ),
          booking: mockBooking,
        ));
      }
      // --- END MOCK DATA ---

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications at the moment.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _NotificationTile(
                      icon: Icons.warning_amber_outlined,
                      iconColor: AppColors.warning,
                      title: 'Schedule Change',
                      subtitle: notification.change.reason.isNotEmpty
                          ? notification.change.reason
                          : 'Your flight schedule has been changed by the airline.',
                      time: DateFormat('dd MMM, HH:mm')
                          .format(notification.change.createdAt),
                      onTap: () {
                        if (notification.booking != null) {
                          context.push(AppRoutes.scheduleChange,
                              extra: notification.booking!);
                        }
                      },
                      unread: !notification.change.accepted,
                    );
                  },
                ),
    );
  }
}

class ScheduleChangeNotification {
  ScheduleChangeNotification({required this.change, this.booking});

  final ScheduleChange change;
  final Booking? booking;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.onTap,
    this.unread = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback? onTap;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: unread ? AppColors.warning.withOpacity(0.05) : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: Text(time,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}
