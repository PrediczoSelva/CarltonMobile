import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummarySection(
            title: 'Flight',
            children: [
              _SummaryRow(label: 'Flight', value: 'SriLankan Airlines UL 101'),
              _SummaryRow(label: 'Route', value: 'CMB → DXB'),
              _SummaryRow(label: 'Date', value: '20 Aug 2026'),
              _SummaryRow(label: 'Departure', value: '08:30'),
              _SummaryRow(label: 'Arrival', value: '13:45'),
            ],
          ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Passengers',
            children: [
              _SummaryRow(label: 'Lead passenger', value: 'John Doe'),
              _SummaryRow(label: 'Passport', value: 'N1234567'),
              _SummaryRow(label: 'Passengers count', value: '1 Adult'),
            ],
          ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Contact',
            children: [
              _SummaryRow(label: 'Email', value: 'john.doe@example.com'),
              _SummaryRow(label: 'Phone', value: '+94 77 123 4567'),
              _SummaryRow(label: 'Country', value: 'Sri Lanka'),
            ],
          ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Payment',
            children: [
              _SummaryRow(label: 'Base fare', value: 'LKR 85,000'),
              _SummaryRow(label: 'Taxes & fees', value: 'LKR 12,000'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Total', style: AppTextStyles.h4),
                  const Spacer(),
                  Text('LKR 97,000', style: AppTextStyles.price),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Go for Payment',
            onPressed: () => context.push('/booking/payment-method'),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.children});

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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
