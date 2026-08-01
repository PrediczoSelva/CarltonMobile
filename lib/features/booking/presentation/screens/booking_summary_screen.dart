import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late final BookingSession _session;

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
  }

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  @override
  Widget build(BuildContext context) {
    final flight = _session.selectedOutboundFlight;
    final passengers = _session.passengers;
    final currency = _session.currency ?? flight?.currency ?? 'GBP';
    final basePrice = _session.totalFlightPrice;
    final taxes = basePrice * 0.14;
    final total = basePrice + taxes;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (flight != null)
            _SummarySection(
              title: 'Flight',
              children: [
                _SummaryRow(label: 'Airline', value: '${flight.airline} ${flight.flightCode}'),
                _SummaryRow(label: 'Route', value: '${flight.origin} → ${flight.destination}'),
                _SummaryRow(label: 'Departure', value: _formatTime(flight.departureTime)),
                _SummaryRow(label: 'Arrival', value: _formatTime(flight.arrivalTime)),
                _SummaryRow(label: 'Duration', value: flight.duration),
                _SummaryRow(label: 'Stops', value: flight.stopsText),
                _SummaryRow(label: 'Aircraft', value: flight.aircraft),
              ],
            ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Passengers (${passengers.length})',
            children: [
              for (var i = 0; i < passengers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${i == 0 ? "Lead " : ""}Passenger ${i + 1}: ${passengers[i].fullName}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Contact',
            children: [
              _SummaryRow(label: 'Email', value: _session.contactEmail ?? '—'),
              _SummaryRow(label: 'Phone', value: _session.contactPhone ?? '—'),
              _SummaryRow(label: 'Country', value: _session.contactCountry ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SummarySection(
            title: 'Payment',
            children: [
              _SummaryRow(
                label: 'Base fare',
                value: '$currency ${basePrice.toStringAsFixed(0)}',
              ),
              _SummaryRow(
                label: 'Taxes & fees',
                value: '$currency ${taxes.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Total', style: AppTextStyles.h4),
                  const Spacer(),
                  Text(
                    '$currency ${total.toStringAsFixed(0)}',
                    style: AppTextStyles.price,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Go for Payment',
            onPressed: () {
              _session.totalPrice = total;
              _session.currency = currency;
              context.push('/booking/payment-method');
            },
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
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
