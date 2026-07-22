import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Icon(Icons.confirmation_number, color: AppColors.success, size: 80),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('E-ticket', style: AppTextStyles.h3),
          ),
          const SizedBox(height: 24),
          _ConfirmationRow(label: 'PNR', value: 'ABC123'),
          _ConfirmationRow(label: 'Flight', value: 'SriLankan Airlines UL 101'),
          _ConfirmationRow(label: 'Route', value: 'CMB → DXB'),
          _ConfirmationRow(label: 'Date', value: '20 Aug 2026'),
          _ConfirmationRow(label: 'Departure', value: '08:30'),
          _ConfirmationRow(label: 'Arrival', value: '13:45'),
          _ConfirmationRow(label: 'Passenger', value: 'John Doe'),
          _ConfirmationRow(label: 'Seat', value: '12A'),
          _ConfirmationRow(label: 'Total paid', value: 'LKR 97,000'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Download e-ticket', style: AppTextStyles.button.copyWith(color: AppColors.textOnPrimary)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
