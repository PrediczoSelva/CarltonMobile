import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class HotelConfirmationScreen extends StatelessWidget {
  const HotelConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<BookingSession>();
    final guest = session.hotelLeadGuest;
    final criteria = session.hotelSearchCriteria;
    final offer = session.selectedHotelOffer;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 18),
          Center(
              child: Text('Your hotel is reserved!', style: AppTextStyles.h2)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'A confirmation has been prepared for your stay.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          _section('Booking details', [
            _row('Reference', session.hotelBookingReference ?? '—'),
            _row('Hotel', session.hotelName ?? '—'),
            _row('Room', offer?.roomName ?? '—'),
            if (criteria != null)
              _row(
                'Stay',
                '${_date(criteria.checkIn)} - ${_date(criteria.checkOut)}',
              ),
            _row('Rooms', '${session.hotelRoomQuantity}'),
            _row('Total paid',
                '£${(session.totalPrice ?? 0).toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 16),
          _section('Lead guest', [
            _row(
                'Name',
                '${guest['title'] ?? ''} ${guest['firstName'] ?? ''} ${guest['lastName'] ?? ''}'
                    .trim()),
            _row('Email', guest['email'] ?? '—'),
            _row('Phone', guest['phone'] ?? '—'),
            _row('Emergency contact', session.hotelEmergencyContact ?? '—'),
          ]),
          const SizedBox(height: 16),
          _section('Payment', [
            _row('Method', _paymentMethod(session.paymentMethod)),
            if (session.hotelPaymentLast4 != null)
              _row('Card', '•••• ${session.hotelPaymentLast4}'),
          ]),
          const SizedBox(height: 24),
          PrimaryButton(
              label: 'Back to home', onPressed: () => context.go('/home')),
        ],
      ),
    );
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _paymentMethod(String? method) {
    switch (method) {
      case 'paypal':
        return 'PayPal';
      case 'wallet':
        return 'Carlton Wallet';
      default:
        return 'Card';
    }
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h4),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
