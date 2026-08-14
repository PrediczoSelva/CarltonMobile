import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../booking/domain/entities/booking_session.dart';

class ServicePackSelectionScreen extends StatefulWidget {
  const ServicePackSelectionScreen({super.key});

  @override
  State<ServicePackSelectionScreen> createState() =>
      _ServicePackSelectionScreenState();
}

class _ServicePackSelectionScreenState
    extends State<ServicePackSelectionScreen> {
  late final BookingSession _session;
  String _selectedKey = 'free';

  @override
  void initState() {
    super.initState();
    _session = getIt<BookingSession>();
  }

  @override
  Widget build(BuildContext context) {
    final flight = _session.selectedOutboundFlight;
    final passengers = _session.passengers;
    final currency = _session.currency ?? flight?.currency ?? 'GBP';
    final baseTotal = _session.totalPrice ?? _session.totalFlightPrice;

    final packs = {
      'free': ServicePack(
          key: 'free', title: 'Free', price: 0.0, subtitle: 'Basic support'),
      'bronze': ServicePack(
          key: 'bronze',
          title: 'Bronze',
          price: 19.99,
          subtitle: 'Airline failure protection'),
      'silver': ServicePack(
          key: 'silver',
          title: 'Silver',
          price: 39.99,
          subtitle: 'Failure protection · Speedy refund'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Service Pack')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (flight != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Flight', style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    Text('${flight.origin} → ${flight.destination}',
                        style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 6),
                    Text(
                        '${flight.airline} · ${flight.flightCode}',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Traveller Information', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  for (var i = 0; i < passengers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                          '${i == 0 ? "Lead " : ""}Passenger ${i + 1}: ${passengers[i].fullName}',
                          style: AppTextStyles.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Choose Your Service Pack', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          for (var key in packs.keys)
            _ServicePackCard(
              pack: packs[key]!,
              selected: _selectedKey == key,
              onTap: () => setState(() => _selectedKey = key),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Summary', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Base total', style: AppTextStyles.bodySmall),
                      const Spacer(),
                      Text('$currency ${baseTotal.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Service pack', style: AppTextStyles.bodySmall),
                      const Spacer(),
                      Text(
                          '$currency ${packs[_selectedKey]!.price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Total', style: AppTextStyles.h4),
                      const Spacer(),
                      Text(
                          '$currency ${(baseTotal + packs[_selectedKey]!.price).toStringAsFixed(2)}',
                          style: AppTextStyles.price),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Go for Payment',
            onPressed: () {
              final pack = packs[_selectedKey]!;
              _session.totalPrice =
                  (_session.totalPrice ?? _session.totalFlightPrice) +
                      pack.price;
              _session.currency = currency;
              context.push('/booking/payment-method');
            },
          ),
        ],
      ),
    );
  }
}

class ServicePack {
  final String key;
  final String title;
  final double price;
  final String subtitle;

  ServicePack(
      {required this.key,
      required this.title,
      required this.price,
      required this.subtitle});
}

class _ServicePackCard extends StatelessWidget {
  const _ServicePackCard(
      {required this.pack, required this.selected, required this.onTap});

  final ServicePack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: selected ? Colors.blue : Colors.transparent, width: 1.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                         Text(pack.title, style: AppTextStyles.h4),
                        const SizedBox(width: 8),
                        if (pack.price == 0.0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Text('RECOMMENDED',
                                style: TextStyle(fontSize: 10)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(pack.subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      pack.price == 0.0
                          ? 'Free'
                          : '£${pack.price.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 8),
                  Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? Colors.blue : Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
